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
 * This is a class library that implements compression functions.
 * Provides streaming compression interfaces such as deflateInit, deflate, deflateEnd, deflateBound, setGzipHeader, and setDictionary.
 */
package stdx.compress.zlib

@When[os == "Windows" || arch == "arm"]
@C
struct ZlibStream {
    var nextIn: CPointer<UInt8>
    var availIn: UInt32
    var totalIn: UInt32
    var nextOut: CPointer<UInt8>
    var availOut: UInt32
    var totalOut: UInt32
    init(
        nextIn!: CPointer<UInt8>,
        availIn!: UInt32,
        totalIn!: UInt32,
        nextOut!: CPointer<UInt8>,
        availOut!: UInt32,
        totalOut!: UInt32
    ) {
        this.nextIn = nextIn
        this.availIn = availIn
        this.totalIn = totalIn
        this.nextOut = nextOut
        this.availOut = availOut
        this.totalOut = totalOut
    }
}

@When[os != "Windows" && arch != "arm"]
@C
struct ZlibStream {
    var nextIn: CPointer<UInt8>
    var availIn: UInt32
    var totalIn: UInt64
    var nextOut: CPointer<UInt8>
    var availOut: UInt32
    var totalOut: UInt64
    init(
        nextIn!: CPointer<UInt8>,
        availIn!: UInt32,
        totalIn!: UInt64,
        nextOut!: CPointer<UInt8>,
        availOut!: UInt32,
        totalOut!: UInt64
    ) {
        this.nextIn = nextIn
        this.availIn = availIn
        this.totalIn = totalIn
        this.nextOut = nextOut
        this.availOut = availOut
        this.totalOut = totalOut
    }
}

@FastNative
foreign func CJ_CreateZlibStream(): CPointer<ZlibStream>

@FastNative
foreign func CJ_SetInput(nextIn: CPointer<UInt8>, availIn: UInt32, zlibStream: CPointer<ZlibStream>): Unit

@FastNative
foreign func CJ_SetOutput(nextOut: CPointer<UInt8>, availOut: UInt32, zlibStream: CPointer<ZlibStream>): Unit

@FastNative
foreign func CJ_FreeZlibStream(zlibStream: CPointer<ZlibStream>): Unit

@FastNative
foreign func CJ_ZlibStreamEncodeInit(level: Int32, winBits: Int32, memLevel: Int32, strategy: Int32,
    zlibStream: CPointer<ZlibStream>): Int32

@FastNative
foreign func CJ_ZlibStreamEncode(zlibStream: CPointer<ZlibStream>, flushType: Int32): Int32

@FastNative
foreign func CJ_ZlibStreamEncodeFini(zlibStream: CPointer<ZlibStream>): Int32

@FastNative
foreign func CJ_ZlibStreamDecodeInit(zlibStream: CPointer<ZlibStream>, winBits: Int32): Int32

@FastNative
foreign func CJ_ZlibStreamDecode(zlibStream: CPointer<ZlibStream>, flushType: Int32): Int32

@FastNative
foreign func CJ_ZlibStreamDecodeFini(zlibStream: CPointer<ZlibStream>): Int32
