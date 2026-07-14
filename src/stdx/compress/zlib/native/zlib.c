/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

#include <stdlib.h>
#include <stdio.h>
#include "zlib.h"

extern z_stream* CJ_CreateZlibStream(void)
{
    z_stream* stream = (z_stream*)malloc(sizeof(z_stream));
    if (stream == NULL) {
        return NULL;
    }
    stream->zalloc = Z_NULL;
    stream->zfree = Z_NULL;
    stream->opaque = Z_NULL;
    stream->next_in = NULL;
    stream->avail_in = (uInt)0;
    stream->next_out = NULL;
    stream->avail_out = (uInt)0;
    stream->total_in = (uLong)0;
    stream->total_out = (uLong)0;
    return stream;
}

extern void CJ_SetInput(z_const Bytef* nextIn, uInt availIn, z_stream* zlibStream)
{
    zlibStream->next_in = nextIn;
    zlibStream->avail_in = availIn;
}

extern void CJ_SetOutput(Bytef* nextOut, uInt availOut, z_stream* zlibStream)
{
    zlibStream->next_out = nextOut;
    zlibStream->avail_out = availOut;
}

extern uInt CJ_ZlibStreamGetAvailIn(const z_stream* zlibStream)
{
    return zlibStream->avail_in;
}

extern uInt CJ_ZlibStreamGetAvailOut(const z_stream* zlibStream)
{
    return zlibStream->avail_out;
}

extern void CJ_FreeZlibStream(z_stream* zlibStream)
{
    if (zlibStream != NULL) {
        free(zlibStream);
    }
}

extern int CJ_ZlibStreamEncodeInit(int level, int winBits, int memLevel, int strategy, z_stream* zlibStream)
{
    return deflateInit2(zlibStream, level, Z_DEFLATED, winBits, memLevel, strategy);
}

extern int CJ_ZlibStreamEncode(z_stream* zlibStream, int flushType)
{
    return deflate(zlibStream, flushType);
}

extern int CJ_ZlibStreamEncodeFini(z_stream* zlibStream)
{
    return deflateEnd(zlibStream);
}

extern int CJ_ZlibStreamDecodeInit(z_stream* zlibStream, int winBits)
{
    return inflateInit2(zlibStream, winBits);
}

extern int CJ_ZlibStreamDecode(z_stream* zlibStream, int flushType)
{
    return inflate(zlibStream, flushType);
}

extern int CJ_ZlibStreamDecodeFini(z_stream* zlibStream)
{
    return inflateEnd(zlibStream);
}
