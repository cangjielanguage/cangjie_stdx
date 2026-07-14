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

@C
struct ZlibStream {}

@FastNative
foreign func CJ_CreateZlibStream(): CPointer<ZlibStream>

@FastNative
foreign func CJ_SetInput(nextIn: CPointer<UInt8>, availIn: UInt32, zlibStream: CPointer<ZlibStream>): Unit

@FastNative
foreign func CJ_SetOutput(nextOut: CPointer<UInt8>, availOut: UInt32, zlibStream: CPointer<ZlibStream>): Unit

@FastNative
foreign func CJ_ZlibStreamGetAvailIn(zlibStream: CPointer<ZlibStream>): UInt32

@FastNative
foreign func CJ_ZlibStreamGetAvailOut(zlibStream: CPointer<ZlibStream>): UInt32

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
