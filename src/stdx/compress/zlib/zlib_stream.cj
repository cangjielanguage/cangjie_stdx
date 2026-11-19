/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

/**
 * @file
 *
 * Define CompressInputStream/CompressOutputStream/DevompressInputStream/DecompressOutputStream class
 */
package stdx.compress.zlib

import std.io.{InputStream, OutputStream}

/*
 * Maximum length of the input/output buffer for a single compression/decompression is the max of UInt32
 */
const MAX_BUFFER_LENGTH_IN: Int64 = 0xFFFF_FFFF
const MAX_BUFFER_LENGTH_OUT: Int64 = 0xFFFF_FFFF
const MAX_DECOMPRESSION_RATIO: Int64 = 1000
const MIN_OUTPUT_BYTES_FOR_RATIO_CHECK: Int64 = 8 * 1024 * 1024

func min(a: Int64, b: Int64): Int64 {
    if (a > b) {
        b
    } else {
        a
    }
}

/**
 * Implement an input stream for compressing data from other input streams.
 */
public class CompressInputStream <: InputStream {
    /* Internal Compressor */
    private var deflater: Deflate

    /* Input stream to be compressed */
    private var inputStream: InputStream

    /* Buffer for storing uncompressed data read from inputStream */
    private var inBuf: Array<Byte>

    /* Flag Whether the data has been read */
    private var readStarted: Bool

    /* End flag of reading inputStream */
    private var readEnd: Bool

    /* Flag whether the current class is closed */
    private var closed: Bool

    private var inBufCursor: Int64

    var inBufEnd: Int64

    /**
     * Create a input stream for compressing data from inputStream.
     *
     * @parm inputStream Input stream to be compressed
     * @parm wrap Compressed data wrapper type to be compressed
     * @parm compressLevel The compression level
     * @parm bufLen Buffer size for storing data read from inputStream
     *
     * @throws ZlibException if bufLen <= 0 or failed to malloc memory for zlib stream,
     * or failed to init encode resource.
     */
    public init(
        inputStream: InputStream,
        wrap!: WrapType = DeflateFormat,
        compressLevel!: CompressLevel = DefaultCompression,
        bufLen!: Int64 = 512
    ) {
        inBuf = getBufByLen(bufLen)
        inBufCursor = 0
        inBufEnd = 0
        deflater = Deflate(wrap: wrap, level: compressLevel, wbits: DefaultWindowBits, mlevel: DefaultMemoryLevel,
            strategy: DefaultStrategy)
        this.inputStream = inputStream
        readStarted = false
        readEnd = false
        closed = false
    }

    /**
     * Reads data from inputStream and compresses it to outBuf.
     *
     * @parm outBuf Buffer for storing compressed data
     * @return Int64 The actual number of compressed data in outBuf
     * @return Int64(0) The bound inputStream has been compressed or the stream has been closed
     *
     * @throws ZlibException if outBuf is empty or failed to encode stream.
     */
    public func read(outBuf: Array<Byte>): Int64 {
        if (deflater.isFinished() || closed || (!readStarted && readEnd)) {
            return 0
        }
        if (outBuf.isEmpty()) {
            throw ZlibException("Buffer for compressed data cannot be empty.")
        }
        var outBufCursor = 0
        while (outBufCursor < outBuf.size && !deflater.isFinished()) {
            if (deflater.needsInput()) {
                if (!getInput()) {
                    if (!readStarted) {
                        return outBufCursor
                    }
                } else {
                    var singleInLen = min(inBufEnd - inBufCursor, MAX_BUFFER_LENGTH_IN)
                    deflater.addInputBytes(inBuf.slice(inBufCursor, singleInLen), singleInLen)
                    inBufCursor += singleInLen
                }
            }
            var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
            var produced = if (readEnd) {
                deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), Finish)
            } else {
                deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
            }
            if (readEnd && produced == 0) {
                break
            }
            outBufCursor += produced
        }
        outBufCursor
    }

    private func getInput(): Bool {
        if (inBufEnd != inBufCursor) {
            return true
        }

        if (readEnd) {
            return false
        }

        var readRet = inputStream.read(inBuf)
        if (readRet <= 0) {
            readEnd = true
            if (!readStarted) {
                return false
            }
            inBufCursor = 0
            inBufEnd = 0
            return true
        }

        readStarted = true
        inBufCursor = 0
        inBufEnd = readRet
        return true
    }

    /**
     * Closes this stream and release internal compressor resourecs.
     *
     * @throws ZlibException if failed to release compression resources.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        deflater.deflateEnd()
        closed = true
    }
}

/**
 * Implement an output stream for compressing data into other output streams.
 */
public class CompressOutputStream <: OutputStream {
    /* Internal Compressor */
    private var deflater: Deflate

    /* Output stream for writing compressed data */
    private var outputStream: OutputStream

    /* Buffer for storing compressed data */
    private var outBuf: Array<Byte>

    /* Cursor for outBuf */
    private var outBufCursor: Int64

    /* Flag whether writing has started */
    private var writeStarted: Bool

    /* Flag whether the current class is closed */
    private var closed: Bool

    /**
     * Create a output stream for compressing data into outputStream.
     *
     * @parm outputStream Output stream of compressed data to be written
     * @parm wrap Compressed data wrapper type to be compressed
     * @parm compressLevel The compression level
     * @parm bufLen Buffer size for storing compressed data to be written
     *
     * @throws ZlibException if bufLen <= 0 or failed to malloc memory for zlib stream,
     * or failed to init encode resource.
     */
    public init(
        outputStream: OutputStream,
        wrap!: WrapType = DeflateFormat,
        compressLevel!: CompressLevel = DefaultCompression,
        bufLen!: Int64 = 512
    ) {
        outBuf = getBufByLen(bufLen)
        outBufCursor = 0
        deflater = Deflate(wrap: wrap, level: compressLevel, wbits: DefaultWindowBits, mlevel: DefaultMemoryLevel,
            strategy: DefaultStrategy)
        this.outputStream = outputStream
        writeStarted = false
        closed = false
    }

    /**
     * Compresses inBuf data and writes to output stream.
     *
     * @parm inBuf Buffer for storing data to be compressed
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    public func write(inBuf: Array<Byte>): Unit {
        if (deflater.isFinished() || closed) {
            throw ZlibException("CompressOutputStream is closed.")
        }
        if (inBuf.size == 0) {
            return
        }
        writeStarted = true
        var inBufCursor = 0
        var singleInLen = min(inBuf.size, MAX_BUFFER_LENGTH_IN)
        while (singleInLen > 0) {
            deflater.addInputBytes(inBuf.slice(inBufCursor, singleInLen), singleInLen)
            inBufCursor += singleInLen
            while (!deflater.needsInput()) {
                if (outBufCursor == outBuf.size) {
                    flushOutBuf()
                }
                var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
                outBufCursor += deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
            }
            singleInLen = min(inBuf.size - inBufCursor, MAX_BUFFER_LENGTH_IN)
        }
    }

    /**
     * Closes this stream and release internal compressor resources.
     *
     * @throws ZlibException if the CompressOutputStream is closed, or failed to encode stream,
     * or failed to release compression resources.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        try {
            if (writeStarted) {
                finishDeflate()
            }
        } finally {
            deflater.deflateEnd()
            closed = true
        }
    }

    /**
     * Flushes compressed data from the internal buffer and writes to the bound output stream.
     * Then refreshes the bound output stream.
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    public func flush(): Unit {
        flushOutBuf()
        outputStream.flush()
    }

    private func finishDeflate(): Unit {
        while (!deflater.isFinished()) {
            if (outBufCursor == outBuf.size) {
                flushOutBuf()
            }
            var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
            outBufCursor += deflater.deflate(outBuf.slice(outBufCursor, singleOutLen), Finish)
        }
        flush()
    }

    /**
     * Write outBuf to the bound output stream.
     *
     * @throws ZlibException if the CompressOutputStream is closed or failed to encode stream.
     */
    private func flushOutBuf(): Unit {
        outputStream.write(outBuf.slice(0, outBufCursor))
        outBufCursor = 0
    }
}

/**
 * Implement an input stream for decompressing data from other input streams.
 */
public class DecompressInputStream <: InputStream {
    /* Internal Compressor */
    private var inflater: Inflate

    /* Input stream to be compressed */
    private var inputStream: InputStream

    /* Buffer for storing data read from inputStream */
    private var inBuf: Array<Byte>

    /* Flag Whether the data has been read */
    private var readStarted: Bool

    /* End flag of reading inputStream */
    private var readEnd: Bool

    /* Flag whether the current class is closed */
    private var closed: Bool

    private var inBufCursor: Int64

    private var inBufEnd: Int64

    private var totalInputBytes: Int64 = 0

    private var totalOutputBytes: Int64 = 0

    /**
     * Create a input stream for decompressing data from inputStream.
     *
     * @parm inputStream Input stream to be decompressed
     * @parm wrap Compressed data wrapper type to be decompressed
     * @parm bufLen Buffer size for storing data read from inputStream
     *
     * @throws ZlibException if bufLen <= 0 or failed to malloc memory for zlib stream,
     * or failed to init decode resource.
     */
    public init(inputStream: InputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512) {
        inBuf = getBufByLen(bufLen)
        inBufCursor = 0
        inBufEnd = 0
        inflater = Inflate(wrap: wrap)
        this.inputStream = inputStream
        readStarted = false
        readEnd = false
        closed = false
    }

    /**
     * Reads data from inputStream and decompresses it to outBuf.
     *
     * @parm outBuf Buffer for storing decompressed data
     * @return Int64 The actual number of decompressed data in outBuf
     * @return Int64(0) The bound inputStream has been decompressed or the stream has been closed
     *
     * @throws ZlibException if outBuf is empty, failed to decode stream,
     * or the compressed data ends before the decompression is finished.
     */
    public func read(outBuf: Array<Byte>): Int64 {
        if (inflater.isFinished() || closed || (!readStarted && readEnd)) {
            return 0
        }
        if (outBuf.isEmpty()) {
            throw ZlibException("Buffer for decompressed data cannot be empty.")
        }
        var outBufCursor = 0
        while (outBufCursor < outBuf.size && !inflater.isFinished()) {
            if (inflater.needsInput()) {
                if (!getInput()) {
                    if (!readStarted) {
                        return outBufCursor
                    }
                } else {
                    var singleInLen = min(inBufEnd - inBufCursor, MAX_BUFFER_LENGTH_IN)
                    inflater.addInputBytes(inBuf.slice(inBufCursor, singleInLen), singleInLen)
                    inBufCursor += singleInLen
                }
            }
            var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
            let produced = inflater.inflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
            onOutputProduced(produced)
            if (readEnd && produced == 0) {
                break
            }
            outBufCursor += produced
        }
        return outBufCursor
    }

    private func getInput(): Bool {
        var readRet = 0
        if (inBufEnd == inBufCursor) {
            if (readEnd) {
                return false
            }
            readRet = inputStream.read(inBuf)
            if (readRet <= 0) {
                readEnd = true
                if (!readStarted) {
                    return false
                }
                inBufCursor = 0
                inBufEnd = 0
                return true
            } else {
                totalInputBytes += readRet
            }
            readStarted = true
            inBufCursor = 0
            inBufEnd = readRet
        }
        return true
    }

    /**
     * Closes this stream and release internal decompressor resourecs.
     *
     * @throws ZlibException if failed to release decompressed resources.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        inflater.inflateEnd()
        closed = true
    }

    private func onOutputProduced(produced: Int64): Unit {
        if (produced <= 0) {
            return
        }
        totalOutputBytes += produced
        enforceDecompressionRatio()
    }

    private func enforceDecompressionRatio(): Unit {
        if (totalOutputBytes < MIN_OUTPUT_BYTES_FOR_RATIO_CHECK || totalInputBytes <= 0) {
            return
        }
        if (totalOutputBytes / totalInputBytes > MAX_DECOMPRESSION_RATIO) {
            throw ZlibException("Decompressed output exceeds safety compression ratio: '${MAX_DECOMPRESSION_RATIO}':1.")
        }
    }
}

/**
 * Implement an output stream for decompressing data to other output streams.
 */
public class DecompressOutputStream <: OutputStream {
    /* Internal Compressor */
    private var inflater: Inflate

    /* Output stream for writing decompressed data */
    private var outputStream: OutputStream

    /* Buffer for storing decompressed data */
    private var outBuf: Array<Byte>

    /* Cursor for outBuf */
    private var outBufCursor: Int64

    /* Flag whether writing has started */
    private var writeStarted: Bool

    /* Flag whether the current class is closed */
    private var closed: Bool

    /* Flag whether an error has been reported by write() */
    private var errorOccurred: Bool

    private var totalInputBytes: Int64 = 0

    private var totalOutputBytes: Int64 = 0

    /**
     * @throws ZlibException if bufLen <= 0 or failed to malloc memory for zlib stream,
     * or failed to init decode resource.
     */
    public init(outputStream: OutputStream, wrap!: WrapType = DeflateFormat, bufLen!: Int64 = 512) {
        outBuf = getBufByLen(bufLen)
        outBufCursor = 0
        inflater = Inflate(wrap: wrap)
        this.outputStream = outputStream
        writeStarted = false
        closed = false
        errorOccurred = false
    }

    /**
     * Decompresses inBuf data and writes to output stream.
     *
     * @parm inBuf Buffer for storing data to be decompressed
     *
     * @throws ZlibException if the DecompressOutputStream is closed or failed to decode stream.
     */
    public func write(inBuf: Array<Byte>): Unit {
        if (inflater.isFinished() || closed) {
            throw ZlibException("DecompressOutputStream is closed.")
        }
        if (inBuf.size == 0) {
            return
        }
        writeStarted = true
        var inBufCursor = 0
        var singleInLen = min(inBuf.size, MAX_BUFFER_LENGTH_IN)
        while (singleInLen > 0) {
            totalInputBytes += singleInLen
            inflater.addInputBytes(inBuf.slice(inBufCursor, singleInLen), singleInLen)
            inBufCursor += singleInLen
            while (!inflater.needsInput() && !inflater.isFinished()) {
                if (outBufCursor == outBuf.size) {
                    flushOutBuf()
                }
                var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
                var produced: Int64 = 0
                try {
                    produced = inflater.inflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
                } catch (e: ZlibException) {
                    errorOccurred = true
                    throw e
                }
                onOutputProduced(produced)
                outBufCursor += produced
            }
            singleInLen = min(inBuf.size - inBufCursor, MAX_BUFFER_LENGTH_IN)
        }
    }

    /**
     * Flushes decompressed data from the internal buffer and writes to the bound output stream.
     * Then refreshes the bound output stream.
     *
     * @throws ZlibException if the DecompressOutputStream is closed or failed to decode stream.
     */
    public func flush(): Unit {
        flushOutBuf()
        outputStream.flush()
    }

    /**
     * Closes this stream and release internal decompressor resourecs.
     *
     * @throws ZlibException if the compressed data ends before the decompression
     * is finished, the DecompressOutputStream failed to decode stream,
     * or failed to release decompressed resources.
     */
    public func close(): Unit {
        if (closed) {
            return
        }
        try {
            if (writeStarted) {
                finishInflate()
            }
            if (!errorOccurred && !inflater.isFinished()) {
                if (writeStarted) {
                    throw ZlibException("Unexpected end of compressed data: input exhausted (total ${totalInputBytes} bytes) but decompression is not finished.")
                }
                throw ZlibException("Unexpected end of compressed data: no input data was written.")
            }
        } finally {
            inflater.inflateEnd()
            closed = true
        }
    }

    /**
     * Consumes the remaining buffered data to finish the decompression and
     * flushes decompressed data to the bound output stream.
     *
     * @throws ZlibException if the compressed data ends before the decompression
     * is finished, or failed to decode stream.
     */
    private func finishInflate(): Unit {
        while (!inflater.isFinished()) {
            if (outBufCursor == outBuf.size) {
                flushOutBuf()
            }
            var singleOutLen = min(outBuf.size - outBufCursor, MAX_BUFFER_LENGTH_OUT)
            let produced = inflater.inflate(outBuf.slice(outBufCursor, singleOutLen), NoFlush)
            onOutputProduced(produced)
            // No progress while input is exhausted and the stream is not finished: compressed data is incomplete
            if (produced == 0) {
                throw ZlibException("Unexpected end of compressed data: inflate produced no bytes (${totalOutputBytes} bytes generated so far), decompression is not finished.")
            }
            outBufCursor += produced
        }
        flush()
    }

    /**
     * Write outBuf to the bound output stream.
     *
     * @throws ZlibException if the DecompressOutputStream is closed or failed to decode stream.
     */
    private func flushOutBuf(): Unit {
        outputStream.write(outBuf.slice(0, outBufCursor))
        outBufCursor = 0
    }

    private func onOutputProduced(produced: Int64): Unit {
        if (produced <= 0) {
            return
        }
        totalOutputBytes += produced
        enforceDecompressionRatio()
    }

    private func enforceDecompressionRatio(): Unit {
        if (totalOutputBytes < MIN_OUTPUT_BYTES_FOR_RATIO_CHECK || totalInputBytes <= 0) {
            return
        }
        if (totalOutputBytes / totalInputBytes > MAX_DECOMPRESSION_RATIO) {
            throw ZlibException("Decompressed output exceeds safety compression ratio: '${MAX_DECOMPRESSION_RATIO}':1.")
        }
    }
}
