/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.net.http

import std.io.*
import std.net.*
import stdx.log.*

/**
 * BufferedReader - Used to represent the conn(e.g. a tcp socket connection) message
 */
class BufferedReader {
    let buf = Array<Byte>(READ_CHUNK_SIZE, repeat: 0)
    let socket: StreamingSocket

    // starting point for reading data out from this BufferedReader
    var curRead: Int64 = 0
    // starting point for writing data into this BufferedReader
    var curWrite: Int64 = 0

    var _logger: ?Logger = None

    init(socket: StreamingSocket) {
        this.socket = socket
    }

    mut prop logger: Logger {
        get() {
            _logger ?? throw HttpException("Logger is not set for BufferedReader.")
        }
        set(v) {
            _logger = v
        }
    }

    // boundary of both reading and writing out from or into this BufferedReader
    prop end: Int64 {
        get() {
            return buf.size
        }
    }

    prop remainingData: Int64 {
        get() {
            return curWrite - curRead
        }
    }

    prop remainingCap: Int64 {
        get() {
            return end - curWrite
        }
    }

    func fill(): Int64 {
        let readBytes = getWriteBuffer() |> socket.read
        if (readBytes == 0) {
            if (logger.enabled(LogLevel.TRACE)) {
                httpLogTrace(logger, "[BufferedReader#fill] prepare to close socket")
            }
            socket.close() // make sure the socket is closed
            throw ConnectionException("Socket is closed.")
        }
        curWrite += readBytes
        return readBytes
    }

    private func getWriteBuffer(): Array<Byte> {
        if (curRead > 0 && curRead == curWrite) { // data has been read
            reset()
        }
        return buf.slice(curWrite, remainingCap)
    }

    func tryReadLine(): Str {
        if (remainingData <= 0) { // no data to read
            return Str.empty
        }

        let beg = curRead
        while (curRead < curWrite && buf[curRead] != LF) {
            curRead++
        }
        if (curRead < curWrite) { // got `b`
            curRead++ // read `b`
        }
        return Str(buf[beg..curRead])
    }

    func read(buf: Array<Byte>): Int64 {
        if (remainingData <= 0) { // no data to read
            return 0
        }
        let beg = curRead
        let len = min(buf.size, curWrite - beg)
        this.buf.copyTo(buf, beg, 0, len)
        curRead = beg + len
        return len
    }

    func reset(): Unit {
        curRead = 0
        curWrite = 0
    }
}

class BufferedWriter {
    let socket: StreamingSocket
    let buf = Array<Byte>(WRITE_CHUNK_SIZE, repeat: 0)
    var curWrite = 0

    var _logger: ?Logger = None

    init(socket: StreamingSocket) {
        this.socket = socket
    }

    mut prop logger: Logger {
        get() {
            _logger ?? throw HttpException("Logger is not set for BufferedWriter.")
        }
        set(v) {
            _logger = v
        }
    }

    func write(data: Array<Byte>): Unit {
        if ((WRITE_CHUNK_SIZE - curWrite) < data.size) {
            flush()
            socket.write(data)
            return
        }
        data.copyTo(buf, 0, curWrite, data.size)
        curWrite += data.size
        if (curWrite == WRITE_CHUNK_SIZE) {
            flush()
        }
    }

    func write(b: UInt8): Unit {
        buf[curWrite] = b
        curWrite++
        if (curWrite == WRITE_CHUNK_SIZE) {
            flush()
        }
    }

    @OverflowWrapping
    func writeUInt16(num: UInt16): Unit {
        if (num < 255) {
            write(0)
            write(UInt8(num))
            return
        }
        write(UInt8(num >> 8))
        write(UInt8(num))
    }

    @OverflowWrapping
    func writeUInt32(num: UInt32): Unit {
        if (num < 255) {
            write(0)
            write(0)
            write(0)
            write(UInt8(num))
            return
        }
        write(UInt8(num >> 24))
        write(UInt8(num >> 16))
        write(UInt8(num >> 8))
        write(UInt8(num))
    }

    // payLoadLength takes only 3 bytes
    @OverflowWrapping
    func writePayloadLen(num: UInt32): Unit {
        if (num < 255) {
            write(0)
            write(0)
            write(UInt8(num))
            return
        }
        write(UInt8(num >> 16))
        write(UInt8(num >> 8))
        write(UInt8(num))
    }

    func flush(): Unit {
        socket.write(buf[..curWrite])
        curWrite = 0
    }
}

/**
 * BufferedConn - The built-in chunk is used to cache the conn message, reducing syscalls to read faster.
 */
class BufferedConn <: StreamingSocket {
    let socket: StreamingSocket
    let bufferedReader: BufferedReader
    let bufferedWriter: BufferedWriter

    var _logger: ?Logger = None

    init(socket: StreamingSocket) {
        this.socket = socket
        this.bufferedReader = BufferedReader(socket)
        this.bufferedWriter = BufferedWriter(socket)
    }

    mut prop logger: Logger {
        get() {
            _logger ?? throw HttpException("Logger is not set for BufferedConn.")
        }
        set(v) {
            _logger = v
            bufferedReader.logger = v
            bufferedWriter.logger = v
        }
    }

    // strictCrlf: reject bare-LF (LF without CR) line terminators, e.g. for
    // the server-side request parsing to prevent header smuggling
    func readLine(strictCrlf!: Bool = false): Str {
        if (bufferedReader.remainingData == 0) {
            fill() // lazy to read the first chunk
        }

        var line = bufferedReader.tryReadLine() // the size of line must less than MAX_LINE_SIZE
        if (line.size > MAX_LINE_SIZE) {
            throw HttpException("ReadLine size ${line.size} exceeds limit ${MAX_LINE_SIZE}.")
        }
        if (line.endWith(LF)) {
            checkLineTerminator(line, strictCrlf)
            return line.removeLast(LF).removeLast(CR)
        }

        var sb = StringBuilder()
        sb.append(line)

        do {
            fill() // need more data

            line = bufferedReader.tryReadLine()
            sb.append(line)

            if (sb.size > MAX_LINE_SIZE) {
                throw HttpException("ReadLine size ${sb.size} exceeds limit ${MAX_LINE_SIZE}.")
            }
        } while (!line.endWith(LF)) // read to r'\n'

        let fullLine = Str(sb.toString())
        checkLineTerminator(fullLine, strictCrlf)
        return fullLine.removeLast(LF).removeLast(CR)
    }

    // A field line must be terminated by CRLF; a bare LF is a classic request
    // smuggling primitive, so the request direction rejects it with 400.
    // RFC 9112 2.2, RFC 9110 5.1
    /// Throws: HttpStatusException, when strictCrlf is enabled and the line
    /// terminator is a bare LF (RFC 9112 2.2).
    func checkLineTerminator(line: Str, strictCrlf: Bool): Unit {
        if (strictCrlf && !line.removeLast(LF).endWith(CR)) {
            throw HttpStatusException(HttpStatusCode.STATUS_BAD_REQUEST,
                "Invalid line: bare LF is not allowed as a line terminator.")
        }
    }

    // read util the buf is full
    func readFull(buf: Array<Byte>): Int64 {
        var readLen = 0
        var len = bufferedReader.read(buf[readLen..buf.size])
        readLen += len
        while (readLen < buf.size) {
            // read from socket
            len = socket.read(buf[readLen..buf.size])
            if (len == 0) {
                throw ConnectionException("Socket is closed.")
            }
            readLen += len
        }
        return readLen
    }

    func fill() {
        if (bufferedReader.remainingCap == 0) {
            bufferedReader.reset()
        }
        bufferedReader.fill()
    }

    public func read(buffer: Array<Byte>): Int64 {
        // need more data
        if (bufferedReader.remainingData == 0) {
            fill()
        }
        return bufferedReader.read(buffer)
    }

    func read(buffer: Array<Byte>, maxLen: Int64): Int64 {
        // need more data
        if (bufferedReader.remainingData == 0) {
            fill()
        }
        let readSize = min(buffer.size, maxLen)
        return bufferedReader.read(buffer[..readSize])
    }

    func write(data: String) {
        write(unsafe { data.rawData() })
    }

    public func write(buffer: Array<Byte>): Unit {
        if (buffer.size > 0) {
            socket.write(buffer)
        }
    }

    public func close(): Unit {
        if (logger.enabled(LogLevel.TRACE)) {
            httpLogTrace(logger, "[BufferedConn#close] prepare to close socket")
        }
        socket.close()
    }

    public func isClosed(): Bool {
        return socket.isClosed()
    }

    public override prop remoteAddress: SocketAddress {
        get() {
            socket.remoteAddress
        }
    }

    public override prop localAddress: SocketAddress {
        get() {
            socket.localAddress
        }
    }

    public override mut prop readTimeout: ?Duration {
        get() {
            socket.readTimeout
        }
        set(timeout) {
            socket.readTimeout = timeout
        }
    }

    public override mut prop writeTimeout: ?Duration {
        get() {
            socket.writeTimeout
        }
        set(timeout) {
            socket.writeTimeout = timeout
        }
    }

    public override func toString(): String {
        "BufferedConn(${socket.toString()})"
    }
}
