/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.net.http

import stdx.encoding.url.URL

const TLS_CTX_SESSION_NAME = "CANGJIE-SERVER"
const MAX_METHOD_SIZE = 100
const MAX_LINE_SIZE = 32 * 1024
const MAX_TRAILER_LINE_COUNT = 64
const NULL_BYTE = "\0"
const CHUNK_SIZE = 8 * 1024
const DEFAULT_HEADER_CAPACITY = 8
let VALID_HOST_SYMBOLS: Array<Byte> = [
    // cjlint-ignore -start !G.OTH.03
    // Refer to RFC spec, where sub-delims is:
    // https://www.rfc-editor.org/rfc/rfc3986#section-2.2
    //      sub-delims  = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    //
    // Where unreserved is:
    // https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    // cjlint-ignore -end
    //      unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
    b'!', // sub-delims
    b'$', // sub-delims
    b'&', // sub-delims
    b'\'', // sub-delims
    b'(', // sub-delims
    b')', // sub-delims
    b'*', // sub-delims
    b'+', // sub-delims
    b',', // sub-delims
    b';', // sub-delims
    b'=', // sub-delims
    b'%', // pct-encoded (and used in IPv6 zones)
    b'-', // unreserved
    b'.', // unreserved
    b'_', // unreserved
    b'~', // unreserved
    b':', // IPv6address + Host expression's optional port
    b'[', // enclosing the IP literal
    b']' // enclosing the IP literal
]

// server.cj
const SERVER_COROUTINE_POOL_CAPACITY = 10 ** 4
const SERVER_COROUTINE_POOL_PREHEAT = 0
const SERVER_COROUTINE_POOL_QUEUE_CAPACITY = 10 ** 4
const CR: Byte = '\r'
const LF: Byte = '\n'
const WS: Byte = ' '
const SYMBOL_COLON: Byte = ':'
const SYMBOL_COMMA: Byte = ','
const SYMBOL_EQUAL: Byte = '='
const SEMICOLON: Byte = ';'
const ASTERISK = "*"
const SLASH = "/"
let HopByHopHeaders = ["proxy-connection", "keep-alive", "te", "transfer-encoding", "upgrade"]
// RFC 9110 6.5.1: fields that are necessary for message framing, routing,
// request modifiers, authentication, or payload content encoding/type
// MUST NOT be carried in a trailer section.
let TRAILER_EXCLUDE_LIST: Array<Str> = [Str("transfer-encoding"), Str("trailer"), Str("content-length"), Str("host"),
    Str("authorization"), Str("cookie"), Str("content-encoding"), Str("content-type"), Str("content-range"),
    Str("expect"), Str("max-forwards"), Str("cache-control"), Str("set-cookie"), Str("www-authenticate"),
    Str("proxy-authenticate"), Str("proxy-authorization"), Str("te"), Str("connection"), Str("keep-alive"),
    Str("proxy-connection"), Str("upgrade"), Str("range"), Str("if-match"), Str("if-none-match"),
    Str("if-modified-since"), Str("if-unmodified-since"), Str("if-range"),
    Str("age"), Str("date"), Str("expires"), Str("retry-after"),
    Str("vary"), Str("warning")]

// operator ** is better than <<
// min value of max frame size
let MIN_FRAME_SIZE = UInt32(2 ** 14)
// max value of max frame size
let MAX_FRAME_SIZE = UInt32(2 ** 24 - 1)
let MAX_STREAM_ID: UInt32 = UInt32(2 ** 31 - 1)
// for flow-control
let MAX_WINDOW: UInt32 = UInt32(2 ** 31 - 1)
const DEFAULT_WINDOW_SIZE = 65535u32

// default value of concurrent streams
const INITIAL_MAX_CONCURRENT_STREAMS = 100u32
const DEFAULT_MAX_CONCURRENT_STREAMS = 1000u32
// default header list size
const DEFAULT_MAX_HEADER_LIST_SIZE = 8192u32
// default max header count (security: prevent header count attack)
const DEFAULT_MAX_HEADER_COUNT = 100
// default body size limit is 2M
const DEFAULT_MAX_BODY_SIZE = 2 ** 21

// Default Empty URL
let EMPTY_URL = URL.parse("")

// num of stream pools, every connection claims a stream pool
let MAX_STREAM_POOLS_CAPACITY = 8192
let STREAM_POOLS_THRESHOLD = 100
// num of streams in a pool
let MAX_STREAM_POOL_CAPACITY = 100
// num of arrays of every provided size, arrays are used to convey frame payloads
let MAX_ARRAY_POOL_CAPACITY = 8192
let ARRAY_POOL_THRESHOLD = 100

// read write buffer size
const WRITE_CHUNK_SIZE = 4096
const READ_CHUNK_SIZE = 4096
