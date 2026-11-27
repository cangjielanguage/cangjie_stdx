/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.net.http

import std.net.*
import std.io.*
import std.collection.{ArrayList, HashMap}
import std.sync.{Monitor, AtomicUInt32, AtomicInt64, AtomicBool, SyncCounter}
import std.convert.Parsable
import std.time.MonoTime
import stdx.net.tls.common.TlsConnection
import stdx.crypto.common.Certificate
import stdx.log.{Logger, LogLevel}
import stdx.encoding.url.URL

class Stream {
    var _server: ?HttpServer2

    // will be set when received the whole headers of request
    var engineConn: ?HttpEngineConn2 = None

    var streamId: UInt32
    var status: Status = Idle

    // if the stream is reset by peer
    let isRst = AtomicBool(false)

    // store DATA frames, represent request body
    let dataBBQ = ClosableBlockingQueue<DataFrame>(Int64.Max)

    // set true when there is only CONTINUATION frames to be read/write on this stream
    var waitContinuationToPurge = false

    // flow control
    // remoteWindow on stream level may be negative, when being adjusted according SettingsInitialWindowSize in SETTINGS frame
    // we didn't provide method to set settings frame when server serving, so localWindow will never be negative, and never exceeds UInt32.Max
    var remoteWindow: AtomicInt64
    var localWindow: AtomicUInt32
    let windowMonitor = Monitor()

    // queuePriority is 7 - urgency, cause in SPMCLevelQueue, bigger number means higher level
    // urgency falls in 0 ~ 7, 0 means highest level, the default value is 3
    var queuePriority = MAX_URGENCY - DEFAULT_URGENCY

    // timeout
    // will be started when read the first HEADERS frame on stream, and be canceled once finishing receiving the headers of request
    var readHeaderTimer = HttpTimer.empty
    // will be started when read the first HEADERS frame on stream, and be canceled once finishing receiving the whole request, including headers, body and trailer
    var readTimer = HttpTimer.empty
    // will be started when started to write headers of response, and be canceled once the whole response has been written to tls connection
    var writeTimer = HttpTimer.empty

    // the value content-length field should be the same as the body size
    var reqContentLength: Int64 = -1
    var receivedBodySize = 0

    var requestFields = ArrayList<(String, String)>(0)

    let ctx = HttpContext(HttpRequest(), HttpResponseBuilder())

    let isRstCounted = AtomicBool(false)

    /********************************************* new stream *********************************************/
    init(server: HttpServer2, id: UInt32) {
        this.streamId = id
        this._server = server
        this.remoteWindow = AtomicInt64(Int64(server.remoteSettings[SettingsInitialWindowSize.code]))
        this.localWindow = AtomicUInt32(server.localSettings[SettingsInitialWindowSize.code])
    }

    init() {
        this.streamId = 0
        this._server = None
        this.remoteWindow = AtomicInt64(0)
        this.localWindow = AtomicUInt32(0)
    }

    mut prop server: HttpServer2 {
        get() {
            _server ?? throw HttpException("Server in stream is None.")
        }
        set(v) {
            _server = v
        }
    }

    func reset(server: HttpServer2, id: UInt32): Unit {
        this._server = server
        this.streamId = id
        this.status = Idle
        this.waitContinuationToPurge = false
        this.dataBBQ.reset()
        this.localWindow.store(server.localSettings[SettingsInitialWindowSize.code])
        this.remoteWindow.store(Int64(server.remoteSettings[SettingsInitialWindowSize.code]))
        this.engineConn?.reset(this)
        this.readHeaderTimer = HttpTimer.empty
        this.readTimer = HttpTimer.empty
        this.writeTimer = HttpTimer.empty
        this.reqContentLength = -1
        this.receivedBodySize = 0
        this.ctx.reset()
        this.isRst.store(false)
        this.isRstCounted.store(false)
    }

    func startReadTimer(): Unit {
        if (server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(server.logger,
                "[Stream#startReadTimer] set read header timer, readHeaderTimeout = ${server.readHeaderTimeout}")
        }
        let connId = ThreadContext.connId
        readHeaderTimer = HttpTimer(
            start: server.readHeaderTimeout,
            task: {
                =>
                    ThreadContext.connId = connId // set connection id for logger
                    close(ProtocolError, "read request headers timeout on stream ${streamId}")
                    ThreadContext.connId = None // clear connection id
            }
        )
        if (server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(server.logger,
                "[Stream#startReadTimer] set read header timer, readTimeout = ${server.readTimeout}")
        }
        readTimer = HttpTimer(
            start: server.readTimeout,
            task: {
                =>
                    ThreadContext.connId = connId // set connection id for logger
                    close(ProtocolError, "read request timeout on stream ${streamId}")
                    ThreadContext.connId = None // clear connection id
            }
        )
    }

    /********************************************* pre process / status machine *********************************************/
    func preProcess(frame: Frame): Unit {
        match (frame) {
            case f: DataFrame => onDataRead(f)
            case f: FieldsFrame => onFieldsRead(f)
            case f: WindowUpdateFrame => onWindowUpdateRead(f)
            case f: RstStreamFrame => onRSTRead(f)
            case _: ContinuationFrame => throw HttpConnectionException(ProtocolError,
                "Unexpected CONTINUATION frame on stream '${streamId}'.")
            case _ => () // ignore or throw HttpStreamException?
        }
    }

    private func onDataRead(frame: DataFrame): Unit {
        if (localWindow.load() < frame.payloadLen) {
            throw HttpStreamException(FlowControlError,
                "Payload length of data frame exceeds window on stream '${streamId}'.")
        }

        receivedBodySize += frame.data.size
        if (reqContentLength >= 0) {
            if (receivedBodySize > reqContentLength) {
                throw HttpStreamException(ProtocolError, "Body size exceeds content-length '${reqContentLength}'.")
            }
        }

        match (status) {
            case Open =>
                if (frame.streamEnd) {
                    readTimer.cancel()
                    if (server.logger.enabled(LogLevel.DEBUG)) {
                        httpLogDebug(server.logger,
                            "[Stream#onDataRead] cancel read timer after read body on stream ${streamId}")
                    }
                    status = HalfClosedRemote
                }
            case HalfClosedLocal =>
                if (frame.streamEnd) {
                    readTimer.cancel()
                    status = Closed
                    if (server.logger.enabled(LogLevel.DEBUG)) {
                        httpLogDebug(server.logger,
                            "[Stream#onDataRead] cancel read timer after read body on stream ${streamId}")
                        httpLogDebug(server.logger,
                            "[Stream#onDataRead] purge stream when read data with streamEnd on stream ${streamId}")
                    }
                    purgeStream() //status should be set to Closed when purge?
                }
            case _ => throw HttpStreamException(StreamClosed,
                "Received data frame on stream '${streamId}', status is '${status}'.")
        }
        if (!dataBBQ.enqueue(frame)) {
            server.windowUpdateOnDataConsumed(frame.payloadLen)
        }

        if (frame.streamEnd) {
            dataEnd()
        }

        if (frame.payloadLen > 0) {
            localWindow.fetchSub(frame.payloadLen)
            sendWindowUpdateOnStream()
        }
    }

    private func sendWindowUpdateOnStream(): Unit {
        let remain = localWindow.load()
        if (server.flowThreshold < remain) {
            return
        }
        let initial = server.localSettings[SettingsInitialWindowSize.code]
        if (!localWindow.compareAndSwap(remain, initial)) {
            return
        }
        let windowFrame = WindowUpdateFrame(streamId, initial - remain)
        if (!server.responseQueue.send(windowFrame, CONTROL_PRIORITY) && server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(server.logger, "[Stream#onDataRead] connection closed, write WINDOW_UPDATE frame failed")
        }
    }

    private func onFieldsRead(frame: FieldsFrame): Unit {
        match (status) {
            case Idle => //headers
                status = if (frame.streamEnd) {
                    dataEnd()
                    HalfClosedRemote
                } else {
                    Open
                }
                processHeaders(frame)
            case Open => //trailers
                if (!frame.streamEnd) {
                    throw HttpStreamException(ProtocolError, "Received trailers without streamEnd flag.")
                }
                processTrailers(frame)
                dataEnd()
                status = HalfClosedRemote
            case HalfClosedLocal => //trailers
                if (!frame.streamEnd) {
                    throw HttpStreamException(ProtocolError, "Received trailers without streamEnd flag.")
                }
                processTrailers(frame)
                dataEnd()
                status = Closed
                if (server.logger.enabled(LogLevel.DEBUG)) {
                    httpLogDebug(server.logger,
                        "[Stream#onFieldsRead] purge stream when read headers with headerEnd on stream ${streamId}")
                }
                purgeStream()
            case _ => throw HttpStreamException(StreamClosed,
                "Received headers and continuation frame on stream '${streamId}', status is '${status}'.")
        }
    }

    private func onWindowUpdateRead(frame: WindowUpdateFrame): Unit {
        match (status) {
            case Idle => throw HttpConnectionException(ProtocolError, "Received window update frame on idle stream.")
            case _ => ()
        }
        remoteWindow.fetchAdd(Int64(frame.increment))
        if (remoteWindow.load() > Int64(MAX_WINDOW)) {
            throw HttpStreamException(FlowControlError,
                "WINDOW_UPDATE frame causes remote window on stream '${streamId}' to exceed 2^31-1.")
        }
        windowMonitor.lock()
        windowMonitor.notifyAll()
        windowMonitor.unlock()
    }

    private func rstErrorDesciption(errorCode: UInt32): (String, String) {
        match (errorCode) {
            case 0x1 => ("PROTOCOL_ERROR", "Protocol error detected.")
            case 0x2 => ("INTERNAL_ERROR", "Implementation fault.")
            case 0x3 => ("FLOW_CONTROL_ERROR", "Flow-control limits exceeded.")
            case 0x4 => ("SETTINGS_TIMEOUT", "Settings not acknowledged.")
            case 0x5 => ("STREAM_CLOSED", "Frame received for closed stream.")
            case 0x6 => ("FRAME_SIZE_ERROR", "Frame size incorrect.")
            case 0x7 => ("REFUSED_STREAM", "Stream not processed.")
            case 0x8 => ("CANCEL", "Stream cancelled.")
            case 0x9 => ("COMPRESSION_ERROR", "Compression state not updated.")
            case 0xa => ("CONNECT_ERROR", "TCP connection error for CONNECT method.")
            case 0xb => ("ENHANCE_YOUR_CALM", "Processing capacity exceeded.")
            case 0xc => ("INADEQUATE_SECURITY", "Negotiated TLS parameters not acceptable.")
            case 0xd => ("HTTP_1_1_REQUIRED", "Use HTTP/1.1 for the request.")
            case _ => ("UNKNOWN_ERROR", "Unknown error.")
        }
    }

    private func onRSTRead(frame: RstStreamFrame): Unit {
        let (errorName, errorDescription) = rstErrorDesciption(frame.errorCode)
        httpLogWarn(server.logger,
            "[Stream#onRSTRead] stream received rst frame, stream id: ${streamId}, errorCode: ${errorName}(${frame.errorCode}): ${errorDescription}")
        if (status == Idle) {
            throw HttpConnectionException(ProtocolError, "Received rst frame on idle stream.")
        }
        purgeStream(rstCount: false)
        status = Closed
        cancelAllTimers()
        server.addRstStreamCnt(frame)
        this.isRst.store(true)
        dataBBQ.close()
    }

    /*
     * Construct engineConn to process request and response.
     *
     * @throws HpackException, if decode failed
     */
    private func processHeaders(frame: FieldsFrame): Unit {
        readHeaderTimer.cancel()
        if (server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(server.logger,
                "[Stream#processHeaders] cancel read header timer when received headers on stream ${streamId}")
        }
        if (frame.streamEnd) {
            readTimer.cancel()
            if (server.logger.enabled(LogLevel.DEBUG)) {
                httpLogDebug(server.logger,
                    "[Stream#processHeaders] cancel read timer when received headers on stream ${streamId}")
            }
        }

        if (engineConn.isNone()) {
            let engine = HttpEngineConn2(this)
            engine.readTimeout = server.readTimeout
            engine.writeTimeout = server.writeTimeout
            engine.readHeaderTimeout = server.readHeaderTimeout
            engine.maxRequestHeaderSize = server.maxRequestHeaderSize
            engine.maxRequestBodySize = server.maxRequestBodySize
            engine.request = ctx.request

            engineConn = engine
            ctx.httpConn = engine
        }

        requestFields = frame.fields

        if (!server.requestQueue.send(this, queuePriority)) {
            if (server.logger.enabled(LogLevel.DEBUG)) {
                httpLogDebug(server.logger,
                    "[Stream#processHeaders] connection closed, discard request on stream ${streamId}")
            }
        }
    }

    private func processTrailers(frame: FieldsFrame): Unit {
        readHeaderTimer.cancel()
        readTimer.cancel()
        if (server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(
                server.logger,
                "[Stream#processHeaders] cancel read header timer and read timer when received trailers on stream ${streamId}"
            )
        }
        engineConn?.checkAndSetReqTrailer(frame.fields) // throw HttpStreamException, if check fails
    }

    private func dataEnd(): Unit {
        dataBBQ.close()
        if (reqContentLength >= 0) {
            if (receivedBodySize < reqContentLength) {
                throw HttpStreamException(ProtocolError, "Body size is less than content-length '${reqContentLength}'.")
            }
        }
    }

    /********************************************* handle *********************************************/
    func handle(): Unit {
        engineConn?.constructRequest(requestFields)

        let engine = engineConn ?? throw HttpException("Internal error: engineConn in stream is None.")
        if (let Some(expectBody) <- (ctx.request.body as HttpExpectBodyProviderH2)) {
            expectBody.context = ctx
        }
        let handler = if (ctx.request.url.path == ASTERISK && ctx.request.method == "OPTIONS") {
            OptionsHandler()
        } else {
            server.distributor.distribute(ctx.request.url.path)
        }

        try {
            let handlerStartTime = MonoTime.now()
            handler.handle(ctx)
            let handlerEndTime = MonoTime.now()
            if (server.logger.enabled(LogLevel.DEBUG)) {
                let duration = handlerEndTime - handlerStartTime
                httpLogDebug(
                    server.logger,
                    "[Stream#handle] Handler for request ${ctx.request.method} ${ctx.request.url} on stream ${streamId} took ${duration.toMilliseconds()} ms."
                )
            }
        } catch (e: Exception) { // exceptions from user code or check/write response failed and user hasn't catch, return 500 response.
            httpLogWarn(server.logger, "[Stream#handle] handle failed, ${e}")
            cleanDataQueue()
            // headers haven't been sent, send response with status code STATUS_INTERNAL_SERVER_ERROR
            if (!ctx.responseFlushedByUser && !ctx.upgraded) {
                // Do not send the exception message to the client, it may contain sensitive information.
                // Keep consistent with the HTTP/1.1 server, which returns a generic error message.
                ctx.responseBuilder.status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR).body("Internal Server Error")
                engine.writeResponse(ctx) // throw HttpException, if responseQueue is closed, log and return
                return
            }
            throw e
        }
        cleanDataQueue()
        if (!engine.connect || !ctx.upgraded) {
            engine.writeResponse(ctx) // throw HttpException/IllegalArgumentException, if response invalid
        } else {
            // if upgraded, user should call close in handler, who will send an empty DATA with streamEnd set.
            // An extra close is called to ensure the stream is close
            engine.close()
        }
    }

    func cleanDataQueue() {
        if (!dataBBQ.isClosed()) {
            dataBBQ.close()
        }
        while (let Some(frame) <- dataBBQ.dequeue()) {
            // release window
            server.windowUpdateOnDataConsumed(frame.payloadLen)
        }
    }

    /********************************************* post process / status machine *********************************************/
    func postProcess(frame: Frame): Unit {
        match (frame) {
            case frame: DataFrame => onDataWrite(frame)
            case frame: FieldsFrame => onFieldsWrite(frame)
            case _: WindowUpdateFrame => () //nothing to do
            case _: RstStreamFrame => onRstWrite()
            case _ => throw HttpStreamException(ProtocolError, "Unexpected frame to write.") //never come here
        }
    }

    private func onDataWrite(frame: DataFrame): Unit {
        match (status) {
            case Open =>
                if (frame.streamEnd) {
                    status = HalfClosedLocal
                    if (server.logger.enabled(LogLevel.DEBUG)) {
                        httpLogDebug(server.logger,
                            "[Stream#onDataWrite] write data with streamEnd on open stream ${streamId}")
                    }
                    close(NoError, "write response end, close stream ${streamId}")
                }
            case HalfClosedRemote =>
                if (frame.streamEnd) {
                    status = Closed
                    if (server.logger.enabled(LogLevel.DEBUG)) {
                        httpLogDebug(server.logger,
                            "[Stream#onDataWrite] purge stream when write data with streamEnd on stream ${streamId}")
                    }
                    purgeStream()
                }
            case _ => throw HttpStreamException(ProtocolError, "Write data frame on '${status}' stream.")
        }
    }

    private func onFieldsWrite(frame: FieldsFrame): Unit {
        if (frame.pushId == 0) {
            onHeadersFieldsWrite(frame)
        } else {
            onPushFieldsWrite()
        }
    }

    private func onHeadersFieldsWrite(frame: FieldsFrame): Unit {
        match (status) {
            case Open => // headers / trailers / 100-continue
                if (frame.streamEnd) {
                    status = HalfClosedLocal
                    close(NoError, "write response end, close stream ${streamId}")
                }
            case HalfClosedRemote => // headers / trailers / 100-continue
                if (frame.streamEnd) {
                    status = Closed
                    if (server.logger.enabled(LogLevel.DEBUG)) {
                        httpLogDebug(
                            server.logger,
                            "[Stream#onHeadersFieldsWrite] purge stream when write headers with streamEnd on stream ${streamId}"
                        )
                    }
                    purgeStream()
                }
            case ReservedLocal => // push response headers
                status = HalfClosedRemote
            case _ => throw HttpStreamException(ProtocolError, "Write headers frame on '${status}' stream.")
        }
    }

    private func onPushFieldsWrite(): Unit {
        match (status) {
            case Open | HalfClosedRemote => ()
            case _ => throw HttpStreamException(ProtocolError, "Write push promise on '${status}' stream.")
        }
    }

    private func onRstWrite(): Unit {
        purgeStream()
        dataBBQ.close()
    }

    func isClosed(): Bool {
        return status == Closed
    }

    /********************************************* closing *********************************************/
    // cjlint-ignore -start !G.OTH.03
    /*
     * According to https://www.rfc-editor.org/rfc/rfc9113.html#rfc.section.5.4.2,
     * if frames on this stream are received in a round-trip, they should be processed minimally.
     * We will send global WINDOW_UPDATE, if received DATA. Other frames will be ignored.
     */
    // cjlint-ignore -end
    func close(h2Error: H2Error, message: String, slow!: Bool = false): Unit {
        if (h2Error.code != NoError.code) {
            httpLogWarn(server.logger, "[Stream#close] stream ${streamId}: ${message}")
        }

        // received rst and status has already been set to Closed
        if (isClosed()) {
            purgeStream(purge: false, rstCount: !slow)
            return
        }

        status = Closed
        cancelAllTimers()
        dataBBQ.close()

        let id = streamId
        spawn {
            if (slow) {
                sleep(Duration.second * 5)
            }

            let rstFrame = RstStreamFrame(id, h2Error.code)
            if (!server.responseQueue.send(rstFrame, CONTROL_PRIORITY)) {
                if (server.logger.enabled(LogLevel.DEBUG)) {
                    httpLogDebug(server.logger,
                        "[Stream#close] stream ${streamId}: connection closed, write rst failed.")
                }
            }
        }
    }

    private func purgeStream(purge!: Bool = true, rstCount!: Bool = true): Unit {
        windowMonitor.lock()
        windowMonitor.notifyAll()
        windowMonitor.unlock()

        var needCount = rstCount
        if (rstCount) {
            if (!isRstCounted.compareAndSwap(false, true)) {
                needCount = false
            }
        }
        server.purgeStream(this, purge, needCount)
        return
    }

    func cancelAllTimers(): Unit {
        readHeaderTimer.cancel()
        readTimer.cancel()
        writeTimer.cancel()
        readHeaderTimer = HttpTimer.empty
        readTimer = HttpTimer.empty
        writeTimer = HttpTimer.empty
        if (server.logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(server.logger, "[Stream#cancelAllTimers] cancel all timer on stream ${streamId}")
        }
    }
}

class HttpEngineConn2 <: HttpEngineConn & InputStream {
    let stream: Stream
    var responseQueue: SPMCLevelQueue<Frame>
    var maxFrameSize: UInt32
    let logger: Logger
    let dataBBQ: ClosableBlockingQueue<DataFrame>
    var streamId: UInt32

    let quit = AtomicBool(false)

    var request = HttpRequest.empty //request received on this stream, will be set when finished receiving headers

    // data frame, which has not been read to end
    var dataFrameRemained: ?DataFrame = None
    var dataFrameIndex = 0

    var requestAuthority = "" // for check host, value of host in headers should be the same with value of pseudoHeader :authority

    // flow control
    let windowMonitor: Monitor

    // websocket
    var upgrade: ?String = None
    var connect = false
    // whether response with streamEnd has been sent on stream
    var responded = false
    // in case trailer processed before headers, forbidden fields will still
    // be dropped once the trailer is merged (checkTrailer runs unconditionally)
    // use SyncCounter to ensure header processed first
    var headerSyncCounter = SyncCounter(1)

    let arrayPool: ?ArrayPool

    init(stream: Stream) {
        this.stream = stream
        this.responseQueue = stream.server.responseQueue
        this.maxFrameSize = stream.server.remoteSettings[SettingsMaxFrameSize.code]
        this.dataBBQ = stream.dataBBQ
        this.logger = stream.server.logger
        this.streamId = stream.streamId
        this.windowMonitor = stream.windowMonitor
        this.arrayPool = stream.server.arrayPool
    }

    // stream has not been replaced, but server might not be the same one
    func reset(resetedStream: Stream) {
        this.responseQueue = resetedStream.server.responseQueue
        this.maxFrameSize = resetedStream.server.remoteSettings[SettingsMaxFrameSize.code]
        this.streamId = resetedStream.streamId
        this.quit.store(false)
        this.dataFrameRemained = None
        this.dataFrameIndex = 0
        this.requestAuthority = ""
        this.upgrade = None
        this.connect = false
        this.responded = false
        this.headerSyncCounter = SyncCounter(1)
    }

    public prop clientCertificate: ?Array<Certificate> {
        get() {
            let bufferedConn = stream.server.conn
            return match (bufferedConn.socket) {
                case tlsConn: TlsConnection => tlsConn.handshakeResult?.peerCertificate ?? None
                case _ => None
            }
        }
    }

    prop enablePush: Bool {
        get() {
            return stream.server.remoteSettings[SettingsEnablePush.code] == 1
        }
    }

    public func isClosed(): Bool {
        return stream.isClosed()
    }

    public func getSocket(): StreamingSocket {
        stream.writeTimer.cancel()
        return StreamingSocket2(this)
    }

    /********************************************* construct request *********************************************/
    /*
     * read headers and construct the request object
     *
     * @throws HttpStreamException, if the request head is malformed: pseudo headers
     *     not found, duplicated or invalid, or a regular header is invalid.
     */
    func constructRequest(fields: FieldsList): Unit {
        try {
            var pseudoHeadersNum = 0
            for ((name, _) in fields) {
                if (name.startsWith(":")) {
                    pseudoHeadersNum++
                } else {
                    break
                }
            }
            if (pseudoHeadersNum == 0) {
                throw HttpStreamException(ProtocolError, "Malformed request: pseudo headers not found.")
            }
            checkAndSetPseudoHeaders(fields[..pseudoHeadersNum])
            if (pseudoHeadersNum < fields.size) {
                checkAndSetRequestHeaders(fields[pseudoHeadersNum..])
            }
        } finally {
            // the connection read thread parks on headerSyncCounter.waitUntilZero()
            // when trailers arrive; every exit path of header validation must release
            // it, otherwise the whole connection would be wedged forever
            headerSyncCounter.dec()
        }

        if (request._headers.isSome() && expected100Continue(request.headers)) { // cjlint-ignore !G.EXP.03
            request._body = HttpExpectBodyProviderH2(this)
        } else {
            request._body = this
        }
        request._bodySize = sizeOf(request._body)
        request._remoteAddr = stream.server.remoteAddress
    }

    // cjlint-ignore -start !G.OTH.03
    /* see https://www.rfc-editor.org/rfc/rfc9113.html#HttpRequest */
    // cjlint-ignore -end
    private func checkAndSetPseudoHeaders(pseudoHeaders: ArrayList<(String, String)>): Unit {
        var method: String = String.empty
        var scheme: String = String.empty
        var authority: String = String.empty
        var path: String = String.empty
        for ((name, value) in pseudoHeaders) {
            match (name) {
                case ":method" =>
                    if (!method.isEmpty()) {
                        throw HttpStreamException(ProtocolError, "Pseudo header '${name}' is set more than once.")
                    } else {
                        method = value
                    }
                    request._method = value //may throw, method should be tokens
                case ":scheme" =>
                    if (!scheme.isEmpty()) {
                        throw HttpStreamException(ProtocolError, "Pseudo header '${name}' is set more than once.")
                    } else {
                        scheme = value
                    }
                    if (value != "https") {
                        throw HttpStreamException(ProtocolError,
                            "Malformed request: scheme of HTTP/2 request must be 'https'.")
                    }
                case ":authority" =>
                    if (!authority.isEmpty()) {
                        throw HttpStreamException(ProtocolError, "Pseudo header '${name}' is set more than once.")
                    } else {
                        authority = value
                    }
                    requestAuthority = value
                case ":path" =>
                    if (value.isEmpty()) {
                        throw HttpStreamException(ProtocolError,
                            "Malformed request: value of pseudo header ':path' cannot be empty.")
                    }
                    if (!path.isEmpty()) {
                        throw HttpStreamException(ProtocolError, "Pseudo header '${name}' is set more than once.")
                    } else {
                        path = value
                    }
                    request._url = URL.parse(value)
                case ":protocol" =>
                    if (stream.server.localSettings[SettingsEnableConnectProtocol.code] == 0) {
                        throw HttpStreamException(
                            ProtocolError,
                            "Malformed request: extended CONNECT protocol is disabled."
                        )
                    }
                    if (!h2UpgradeProtocols.contains(value)) {
                        throw HttpStreamException(ProtocolError,
                            "Malformed request: ':protocol' value '${value}' is invalid: allowed values are 'HTTP', 'TLS', 'WebSocket', 'Websocket', 'h2c', 'connect-udp', 'connect-ip'.")
                    }
                    upgrade = value
                case _ => throw HttpStreamException(ProtocolError,
                    "Malformed request: invalid pseudo header name '${name}'.")
            }
        }
        // must contain ":method"
        if (method.isEmpty()) {
            throw HttpStreamException(ProtocolError,
                "Malformed request: pseudoHeaders missing required field ':method'.")
        }
        // must contain ":scheme" and ":path", unless method is connect
        if (method == "CONNECT") {
            connect = true
            if (upgrade.isNone()) {
                return
            }
        }
        if (scheme.isEmpty()) {
            throw HttpStreamException(ProtocolError,
                "Malformed request: pseudoHeaders missing required field ':scheme'.")
        }
        if (path.isEmpty()) {
            throw HttpStreamException(ProtocolError, "Malformed request: pseudoHeaders missing required field ':path'.")
        }
    }

    private func checkAndSetRequestHeaders(toCheck: ArrayList<(String, String)>): Unit {
        for ((name, value) in toCheck) {
            if (name.startsWith(":")) {
                throw HttpStreamException(ProtocolError,
                    "Malformed request: HTTP/2 pseudoHeaders '${name}' appears after headers.")
            }

            if (name.hasUpper()) {
                throw HttpStreamException(ProtocolError, "Malformed request: HTTP/2 headers are not lowercase.")
            }

            // should not contain connection, proxy-connection, keep-alive, transfer-encoding, upgrade
            if (H2_EXCLUDE_HEADERS.contains(name)) {
                throw HttpStreamException(ProtocolError, "Malformed request: HTTP/2 headers cannot contain '${name}'.")
            }

            // TE header field can exist, value of TE MUST NOT contain any value other than "trailers"
            // te: trailers means client allow server to send trailers
            if (name == "te" && value != "trailers") {
                throw HttpStreamException(ProtocolError,
                    "Malformed request: TE header field value '${value}' is invalid: only 'trailers' is allowed.")
            }

            // if :authority is set, value of Host must be the same with value of :authority
            if (name == "host") {
                if (!requestAuthority.isEmpty() && requestAuthority != value) {
                    throw HttpStreamException(ProtocolError,
                        "Malformed request: value of ':authority' and 'host' must be the same.")
                }
            }

            if (name == "priority") {
                let urgency = parsePriority(value)
                stream.queuePriority = MAX_URGENCY - urgency
                if (logger.enabled(LogLevel.DEBUG)) {
                    httpLogDebug(
                        logger,
                        "[Stream#checkAndSetRequestHeaders] stream ${stream.streamId}, set queuePriority = ${stream.queuePriority}"
                    )
                }
            }

            if (name == "trailer") {
                if (!Str(value).splitAllMatch(SYMBOL_COMMA, {v => !trailerNameForbidden(v.trim())})) {
                    throw HttpStreamException(ProtocolError, "Malformed request: invalid trailer value in header.")
                }
            }

            // set header to request
            // will check, name should be tokens, value should be vchar/SP/HTAB
            try {
                request.headers.add(name, value) // may throw HttpException
            } catch (e: HttpException) {
                throw HttpStreamException(ProtocolError, "Malformed request: ${e.message}")
            }
        }

        try {
            if (let Some(headers) <- request._headers) {
                stream.reqContentLength = checkCl(headers) ?? -1
                checkContentLength()
            }
        } catch (e: HttpException) {
            throw HttpStreamException(ProtocolError, "Malformed request: ${e.message}")
        }
    }

    private func checkContentLength() {
        if (stream.reqContentLength >= 0 && stream.receivedBodySize > stream.reqContentLength) {
            throw HttpStreamException(ProtocolError, "Body size exceeds content-length '${stream.reqContentLength}'.")
        }
    }

    /**
     * throw HttpStreamException, if trailer invalid
     */
    func checkAndSetReqTrailer(fields: FieldsList): Unit {
        let trailers = request.trailers
        try {
            for ((k, v) in fields) {
                trailers.add(k, v) // throw HttpException, if k or v contain invalid elements
            }
            // forbidden fields are always dropped, regardless of any "Trailer"
            // declaration (RFC 9110 6.5.1); checkTrailer does not depend on the
            // request headers, so it is called unconditionally
            headerSyncCounter.waitUntilZero()
            checkTrailer(request)
        } catch (e: HttpException) {
            throw HttpStreamException(ProtocolError, "Invalid trailer field: ${e.message}")
        }
    }

    public func read(buf: Array<UInt8>): Int64 {
        var frameIndex = 0
        var readLen = 0
        var frameOp: ?DataFrame = None

        if (dataFrameRemained.isSome()) {
            frameOp = dataFrameRemained
            frameIndex = dataFrameIndex
            dataFrameRemained = None
        } else {
            frameOp = dataBBQ.dequeue()
            // update window
            stream.server.windowUpdateOnDataConsumed(frameOp?.payloadLen ?? 0)
        }

        // dataBBQ has been closed && dataBBQ is empty
        // will return 0, 1. finished receiving body, 2. connection closed with some error, 3. stream closed with some error
        if (let Some(frame) <- frameOp) {
            var singleReadLen = min(buf.size, frame.size - frameIndex)
            frame.data.copyTo(buf, frameIndex, 0, singleReadLen)
            frameIndex += singleReadLen
            readLen += singleReadLen
            if (frameIndex < frame.size) {
                dataFrameRemained = frame
                dataFrameIndex = frameIndex
            } else {
                frame.recyclePayload(arrayPool)
            }
        }
        return readLen
    }

    /********************************************* write response *********************************************/
    /*
     * Write a response, including headers, [body], [trailer].
     */
    func writeResponse(responseBuilder: HttpResponseBuilder): Unit {
        if (stream.isClosed()) {
            throw HttpException("Stream '${streamId}' is closed.")
        }

        let status = responseBuilder._status ?? HttpStatusCode.STATUS_OK

        if (status == HttpStatusCode.STATUS_CONTINUE) {
            httpLogWarn(logger, "[Stream#writeResponse] status of final response should not be 100")
            writeResponse(
                HttpResponseBuilder()
                    .status(HttpStatusCode.STATUS_INTERNAL_SERVER_ERROR)
                    .body("Internal Server Error: invalid status code"))
            return
        }

        checkAndSetCl(responseBuilder, request.method == "HEAD")

        if (request.method == "HEAD" || status / 100 == 1 || status == HttpStatusCode.STATUS_NO_CONTENT || status == HttpStatusCode
            .STATUS_NOT_MODIFIED) {
            responseBuilder._body = HttpEmptyBody.INSTANCE
        }

        let bodySize = sizeOf(responseBuilder._body) ?? -1
        let hasTrailer: Bool = !responseBuilder.trailers.isEmpty()

        match ((bodySize != 0, hasTrailer)) {
            case (true, true) =>
                checkTrailer(responseBuilder)
                writeHeader(status, responseBuilder.headers, streamEnd: false)
                writeBody(responseBuilder._body, streamEnd: false)
                writeTrailer(responseBuilder.trailers)
            case (true, false) =>
                writeHeader(status, responseBuilder.headers, streamEnd: false)
                writeBody(responseBuilder._body, streamEnd: true)
            case (false, true) =>
                checkTrailer(responseBuilder)
                writeHeader(status, responseBuilder.headers, streamEnd: false)
                writeTrailer(responseBuilder.trailers)
            case (false, false) => writeHeader(status, responseBuilder.headers, streamEnd: true)
        }
    }

    public func writeResponse(ctx: HttpContext): Unit {
        if (stream.isClosed()) {
            throw HttpException("Stream '${streamId}' is closed.")
        }
        let responseBuilder = ctx.responseBuilder
        synchronized(ctx.writerMtx) {
            if (ctx.upgraded) {
                return
            }
            ctx.responded = true
            if (ctx.responseFlushedByUser) { //headers and part of body has been sent
                checkTrailer(responseBuilder) //throw HttpException if a field name is not allowed in trailers
                if (responseBuilder.trailers.isEmpty()) {
                    writeEmptyDataFrame()
                    return
                }
                writeTrailer(responseBuilder.trailers)
                return
            }
            writeResponse(responseBuilder)
        }
    }

    public func writeResponseByWriter(ctx: HttpContext, bodyData: Array<UInt8>): Unit {
        if (stream.isClosed()) {
            throw HttpException("Stream '${streamId}' is closed.")
        }
        if (!ctx.responseFlushedByUser) {
            ctx.responseFlushedByUser = true
            let status = ctx.responseBuilder._status ?? HttpStatusCode.STATUS_OK
            if (request.method == "HEAD" || status / 100 == 1 || status == 204 || status == 304) {
                throw HttpException("Invalid body: body is not empty for status '${status}'.")
            }
            writeHeader(status, ctx.responseBuilder.headers, streamEnd: false)
        }
        writeBody(bodyData, streamEnd: false)
    }

    public func writeUpgradeResponse(ctx: HttpContext): Unit {
        if (stream.isClosed()) {
            throw HttpException("Stream '${streamId}' is closed.")
        }
        if (ctx.request.method != "CONNECT") {
            throw HttpException("Cannot build tunnel: request method is not CONNECT.")
        }
        // in http/2, response to CONNECT request must have status 2XX, and should not contain header field "content-length"
        // cjlint-ignore -start !G.OTH.03
        // ref: https://www.rfc-editor.org/rfc/rfc9113.html#CONNECT
        // cjlint-ignore -end
        let status = ctx.responseBuilder._status ?? HttpStatusCode.STATUS_OK
        if (status / 100 != 2) {
            throw HttpException("Response to CONNECT request has invalid status: expected 2XX, got '${status}'.")
        }
        ctx.responseBuilder.headers.del("content-length")
        writeHeader(status, ctx.responseBuilder.headers, streamEnd: false)
    }

    private func writeBody(body: InputStream, streamEnd!: Bool): Unit {
        if (let Some(rb) <- (body as HttpRawBody)) {
            writeBody(rb.rawBody, streamEnd: streamEnd)
            return
        }
        let readBufWrapperOp = arrayPool?.get(Int64(maxFrameSize))
        let readBuf = readBufWrapperOp?.data ?? Array<UInt8>(Int64(maxFrameSize), repeat: 0) // cjlint-ignore !G.EXP.03
        var readLen = body.read(readBuf) //may throw exceptions from user code
        while (readLen > 0) { // if readLen < 0?
            writeBody(readBuf[..readLen], streamEnd: false) // split according stream remoteWindow
            readLen = body.read(readBuf)
        }
        if (let Some(readBufWrapper) <- readBufWrapperOp) {
            if (readBufWrapper.size == 0) {
                throw Exception("Read buffer size is 0, but raw size is '${readBufWrapper.rawSize}'.")
            }
            arrayPool?.put(readBufWrapper)
        }
        if (streamEnd) {
            writeEmptyDataFrame()
        }
    }

    func writeBody(bodyData: Array<UInt8>, streamEnd!: Bool): Unit {
        var bodyIndex = 0
        while (bodyIndex < bodyData.size) {
            if (stream.isClosed()) {
                throw HttpException("Cannot write body: connection is closed.")
            }
            waitIfWindowNegative()
            let remainLen = bodyData.size - bodyIndex
            let permitLen = min(Int64(maxFrameSize), stream.remoteWindow.load())
            let (frame, writeLen) = if (remainLen <= permitLen) {
                let cache = arrayPool?.get(remainLen) ?? ArrayWrapper(remainLen) // cjlint-ignore !G.EXP.03
                bodyData.copyTo(cache.data, bodyIndex, 0, remainLen)
                let f = DataFrame(stream.streamId, cache, remainLen, last: streamEnd)
                bodyIndex = bodyData.size
                (f, remainLen)
            } else {
                let cache = arrayPool?.get(permitLen) ?? ArrayWrapper(permitLen) // cjlint-ignore !G.EXP.03
                bodyData.copyTo(cache.data, bodyIndex, 0, permitLen)
                let f = DataFrame(stream.streamId, cache, permitLen)
                bodyIndex += permitLen
                (f, permitLen)
            }
            if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
                // to handler or stream.handle, which will log the exception and go on
                throw HttpException("Cannot write body: connection is closed.")
            }
            stream.remoteWindow.fetchSub(writeLen)
        }
    }

    private func waitIfWindowNegative(): Unit {
        while (stream.remoteWindow.load() <= 0 && !quit.load()) {
            if (stream.isClosed()) {
                throw HttpException("Stream is closed while waiting for window update on stream '${stream.streamId}'.") // to handler or stream.handle, which will log the exception and go on
            }
            if (logger.enabled(LogLevel.DEBUG)) {
                httpLogDebug(
                    stream.server.logger,
                    "[Stream#waitIfWindowNegative] server stream ${stream.streamId} wait for window_update, current window is negative: ${stream.remoteWindow.load()}"
                )
            }
            windowMonitor.lock()
            windowMonitor.wait(timeout: Duration.millisecond * 10)
            windowMonitor.unlock()
        }
    }

    /*
     * Write an empty data frame with streamEnd
     */
    func writeEmptyDataFrame(): Unit {
        let frame = DataFrame(stream.streamId, Array<UInt8>(), 0, last: true)
        if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
            throw HttpException("Cannot write body: connection is closed.")
        }
    }

    /*
     * Func writeResponse and class HttpExpectBodyProviderH2 will call it
     *
     * @throws HttpException, if headers invalid
     */
    func writeHeader(status: UInt16, header: HttpHeaders, streamEnd!: Bool = false): Unit {
        // start writeTimer
        if (logger.enabled(LogLevel.DEBUG)) {
            httpLogDebug(logger, "[Stream#writeHeader] set write timer, writeTimeout = ${writeTimeout}")
        }
        stream.writeTimer = HttpTimer(start: writeTimeout, task: {
            => stream.close(ProtocolError, "write response timeout on stream ${stream.streamId}")
        })

        let fields = FieldsList()
        let statusString = STATUS_STRING.get(status) ?? status.toString()
        fields.add((":status", statusString))

        checkAndSetResponseHeaders(fields, header)
        let frame = FieldsFrame(stream.streamId, fields, last: streamEnd)
        if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
            throw HttpException("Cannot write header: connection is closed.")
        }
    }

    func write100ContinueHeader(): Unit {
        let fields = FieldsList([(":status", "100")])
        let frame = FieldsFrame(stream.streamId, fields, last: false)
        if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
            throw HttpException("Cannot write header: connection is closed.")
        }
    }

    func writePush(path: String, method: String, header: HttpHeaders): Unit {
        if (isPushStream(stream.streamId)) {
            httpLogWarn(logger, "[Stream#writePush] should not call server push on push stream")
            return
        }
        let pushStream = stream.server.createPushStream()

        let fields = FieldsList()
        if (method.isEmpty()) {
            fields.add((":method", "GET"))
        } else {
            fields.add((":method", method))
        }
        fields.add((":scheme", "https"))
        if (!requestAuthority.isEmpty()) {
            fields.add((":authority", requestAuthority))
        }
        fields.add((":path", path))
        checkAndSetResponseHeaders(fields, header)

        let engine = HttpEngineConn2(pushStream)
        engine.readTimeout = pushStream.server.readTimeout
        engine.writeTimeout = pushStream.server.writeTimeout
        engine.readHeaderTimeout = pushStream.server.readHeaderTimeout
        engine.maxRequestHeaderSize = pushStream.server.maxRequestHeaderSize
        engine.maxRequestBodySize = pushStream.server.maxRequestBodySize
        engine.request = pushStream.ctx.request

        pushStream.engineConn = engine
        pushStream.ctx.httpConn = engine
        pushStream.requestFields = fields

        let frame = FieldsFrame(stream.streamId, fields, pushId: pushStream.streamId)
        if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
            throw HttpException("Cannot send push request: connection is closed.")
        }

        pushStream.status = ReservedLocal

        if (let Some(vs) <- header.getInternal("priority")) {
            pushStream.queuePriority = MAX_URGENCY - parsePriority(vs.toString())
        }

        if (!stream.server.requestQueue.send(pushStream, pushStream.queuePriority)) {
            throw HttpException("Cannot send push request: connection is closed.")
        }
    }

    private func checkAndSetResponseHeaders(fields: FieldsList, headers: HttpHeaders): Unit {
        // add date field
        let dateArr: Array<Byte> = "xxx, xx xxx xxxxxxxxxxxxxxxxxxxxxx xx:xx:xx GMT".toArray() //47 byte
        let dateStr = getRFC1123String(dateArr)
        fields.add(("date", dateStr.toString()))

        for ((k, vs) in headers.map) {
            if (H2_EXCLUDE_HEADERS.contains(k.toString())) {
                continue
            }
            if (k == Str("date")) {
                continue
            }
            if (k == Str("trailer")) {
                checkTrailerInHeader(headers, false) //throw Exception if vs contains valid element, which is excluded by trailer
            }
            if (k == Str("set-cookie")) {
                for (v in vs) {
                    fields.add((k.toString(), v))
                }
                continue
            }
            fields.add((k.toString(), vs.toString()))
        }
    }

    private func writeTrailer(trailer: HttpHeaders): Unit {
        let fields = FieldsList()
        for ((k, v) in trailer.map) {
            fields.add((k.toString(), v.toString()))
        }
        let frame = FieldsFrame(stream.streamId, fields, last: true)
        if (!responseQueue.send(frame, MESSAGE_PRIORITY)) {
            throw HttpException("Cannot write trailer: connection is closed.")
        }
    }

    /********************************************* close *********************************************/
    /*
     * For websocket to call.
     * Send an empty DATA with streamEnd set instead of RST_STREAM, because RST_STREAM has privilege, it may discard previous DATA.
     */
    func close(): Unit {
        if (quit.load()) {
            return
        }
        responseQueue.send(ConnectRstStreamFrame(RstStreamFrame(stream.streamId, NoError.code)), MESSAGE_PRIORITY)
        quit.store(true)
    }
}

class WebSocketConn2 <: WebSocketConn {
    var streamingSocket: StreamingSocket2
    var closed = false

    WebSocketConn2(let engine: HttpEngineConn2) {
        streamingSocket = StreamingSocket2(engine)
    }

    public func readRaw(byteArray: Array<UInt8>): Int64 {
        var len: Int64 = 0
        while (len < byteArray.size) {
            let singleReadLen = streamingSocket.read(byteArray[len..])
            if (singleReadLen == 0) {
                break
            }
            len += singleReadLen
        }
        return len
    }

    public func writeRaw(byteArray: Array<UInt8>): Unit {
        streamingSocket.write(byteArray)
    }

    public func close(): Unit {
        engine.close()
    }
}

class StreamingSocket2 <: StreamingSocket {
    var closed = false

    StreamingSocket2(let engine: HttpEngineConn2) {}

    public prop localAddress: SocketAddress {
        get() {
            return engine.stream.server.conn.socket.localAddress
        }
    }

    public prop remoteAddress: SocketAddress {
        get() {
            return engine.stream.server.conn.remoteAddress
        }
    }

    public mut prop readTimeout: ?Duration {
        get() {
            return None
        }
        set(_) {
            throw HttpException("Cannot set timeout on HTTP/2 stream.")
        }
    }

    public mut prop writeTimeout: ?Duration {
        get() {
            return None
        }
        set(_) {
            throw HttpException("Cannot set timeout on HTTP/2 stream.")
        }
    }

    public func read(byteArray: Array<Byte>): Int64 {
        engine.read(byteArray)
    }

    public func write(byteArray: Array<UInt8>): Unit {
        engine.writeBody(byteArray, streamEnd: false)
    }

    public func isClosed(): Bool {
        return closed
    }

    public func close(): Unit {
        engine.close()
    }

    public func toString(): String {
        throw HttpException("StreamingSocket instance upgraded from HTTP/2 stream does not support toString().")
    }
}

func putOrThrow(map: HashMap<String, String>, name: String, value: String): Unit {
    if (map.contains(name)) {
        throw HttpStreamException(ProtocolError, "Pseudo header '${name}' is set more than once.")
    } else {
        map.add(name, value)
    }
}

func containsOrThrow(headers: HashMap<String, String>, name: String): Unit {
    if (!headers.contains(name)) {
        throw HttpStreamException(ProtocolError, "Malformed request: pseudoHeaders missing required field '${name}'.")
    }
}

func parsePriority(value: String): Int64 {
    var urgency = 3

    let pMap = HashMap<String, String>()
    let pArr = value.split(",")
    for (p in pArr) {
        let kv = p.split("=")
        if (kv.size == 2) {
            pMap.add(kv[0].trimAscii(), kv[1].trimAscii())
        } else if (kv.size == 1) {
            pMap.add(kv[0].trimAscii(), "")
        }
    }
    if (let Some(u) <- pMap.get("u")) {
        try {
            let parsed = Int64.parse(u) //may throw IllegalArgumentException
            // RFC 9218: the urgency parameter must be an integer in 0..7; any
            // out-of-range value is invalid and treated as absent (default 3),
            // otherwise `MAX_URGENCY - urgency` below may overflow
            if (parsed >= 0 && parsed <= MAX_URGENCY) {
                urgency = parsed
            }
        } catch (e: IllegalArgumentException) {}
    }

    return urgency
}

func checkAndSetCl(responseBuilder: HttpResponseBuilder, setCl: Bool): Unit {
    match ((checkCl(responseBuilder.headers), sizeOf(responseBuilder._body), setCl)) {
        case (Some(cl), Some(bs), false) =>
            if (cl != bs) {
                throw HttpException("Content-length and body length do not match.")
            }
        case (None, Some(bs), true) => responseBuilder.headers.add("content-length", "${bs}")
        case _ => ()
    }
}

class HttpExpectBodyProviderH2 <: InputStream {
    var respondedContinue: Bool = false
    var context: ?HttpContext = None

    HttpExpectBodyProviderH2(let conn: HttpEngineConn2) {}

    public func read(buf: Array<Byte>): Int64 {
        let ctx = context ?? throw HttpException("Internal error: context in body provider is None.")
        synchronized(ctx.writerMtx) {
            if (!respondedContinue && !ctx.responseFlushedByUser && !ctx.upgraded && !ctx.responded) {
                conn.write100ContinueHeader()
                respondedContinue = true
            }
        }
        return conn.read(buf)
    }
}
