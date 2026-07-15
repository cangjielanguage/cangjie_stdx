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
 * This is a class library that implements the function of decompressing data.
 * Provides stream decompression interfaces.
 */
package stdx.compress.zlib

/**
 * This class Inflate implements the decompressing function.
 */
class Inflate {
    public var zlibStreamCPtr: CPointer<ZlibStream>

    private var inBuf: Array<UInt8> = Array<UInt8>()

    private var inBufOffset: Int64 = 0

    private var availIn: Int64 = 0

    private var finished: Bool = false

    /**
     * initialize Inflate based on decompression parameters.
     *
     * @param wrap Compressed data outer wrapper type, the default value is DeflateFormat.
     * @param wbits Number of Window Bits, the default value is DefaultWindowBits.
     *
     * @throws ZlibException if failed to malloc memory for zlib stream or failed to init decode resource.
     */
    init(wrap!: WrapType = DeflateFormat, wbits!: WindowBits = DefaultWindowBits) {
        zlibStreamCPtr = unsafe { CJ_CreateZlibStream() }
        if (zlibStreamCPtr.isNull()) {
            throw ZlibException("Failed malloc in C code!")
        }
        let wbitsValue: Int32 = getWinBitsValue(wrap, wbits)
        let ret = unsafe { CJ_ZlibStreamDecodeInit(zlibStreamCPtr, wbitsValue) }
        if (ret != ZLIB_OK) {
            unsafe { CJ_FreeZlibStream(zlibStreamCPtr) }
            zlibStreamCPtr = CPointer<ZlibStream>()
            throw ZlibException(ret)
        }
    }

    ~init() {
        if (!zlibStreamCPtr.isNull()) {
            unsafe {
                CJ_ZlibStreamDecodeFini(zlibStreamCPtr)
                CJ_FreeZlibStream(zlibStreamCPtr)
            }
            zlibStreamCPtr = CPointer<ZlibStream>()
        }
    }

    /**
     * Add input buffer
     *
     * @param inBuf Set inBuf as new input buffer.
     * @param availIn Number of bytes of available data in the input buffer.
     */
    func addInputBytes(inBuf: Array<UInt8>, availIn: Int64): Unit {
        this.inBuf = inBuf
        this.inBufOffset = 0
        this.availIn = availIn
    }

    /**
     * Decompressing data.
     *
     * @param outBuf Output buffer for storing decompressed data.
     * @param flush The operation of flushing stored data to a specified area.
     * @return Int64 Returns the size of decompressed data in the output stream buffer.
     *
     * @throws ZlibException if failed to decode stream.
     */
    func inflate(outBuf: Array<UInt8>, flush: FlushType): Int64 {
        unsafe {
            let nextIn: CPointerHandle<UInt8> = acquireArrayRawData(this.inBuf)
            CJ_SetInput(nextIn.pointer + inBufOffset, UInt32(availIn), zlibStreamCPtr)

            let outBufSize: Int64 = outBuf.size
            let nextOut: CPointerHandle<UInt8> = acquireArrayRawData(outBuf)
            CJ_SetOutput(nextOut.pointer, UInt32(outBufSize), zlibStreamCPtr)

            var ret: Int32 = CJ_ZlibStreamDecode(zlibStreamCPtr, getFlushValue(flush))
            releaseArrayRawData(nextIn)
            releaseArrayRawData(nextOut)

            if (ret != ZLIB_OK && ret != ZLIB_STREAM_END) {
                throw ZlibException(ret)
            }
            let zlibStream: ZlibStream = zlibStreamCPtr.read()
            let nextAvailIn: Int64 = Int64(zlibStream.availIn)
            inBufOffset += availIn - nextAvailIn
            availIn = nextAvailIn
            finished = ret == ZLIB_STREAM_END
            return outBufSize - Int64(zlibStream.availOut)
        }
    }

    /**
     * Determine whether to set the input buffer.
     *
     * @return true The input buffer needs to be set.
     * @return false The input buffer does not need to be set.
     */
    func needsInput(): Bool {
        return !finished && availIn == 0
    }

    /**
     * Determine whether decompression is complete.
     *
     * @return true The decompression is complete.
     * @return false The decompression is not complete.
     */
    func isFinished(): Bool {
        return finished
    }

    /**
     * Close Inflate and release decompression resources.
     *
     * @throws ZlibException if failed to release decompressed resources.
     */
    func inflateEnd(): Unit {
        if (zlibStreamCPtr.isNull()) {
            return
        }
        unsafe {
            var ret = CJ_ZlibStreamDecodeFini(zlibStreamCPtr)
            CJ_FreeZlibStream(zlibStreamCPtr)
            zlibStreamCPtr = CPointer<ZlibStream>()
            if (ret != ZLIB_OK) {
                throw ZlibException(ret)
            }
        }
    }
}
