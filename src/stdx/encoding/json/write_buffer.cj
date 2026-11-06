/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.encoding.json

@FastNative
foreign func memcpy_s(dest: CPointer<UInt8>, destMax: UIntNative, src: CPointer<UInt8>, count: UIntNative): Int32

let BOOL_TRUE_STRING = "true".toArray()
let BOOL_FALSE_STRING = "false".toArray()
let NULL_STRING = "null".toArray()
const MIN_CAPACITY = 16
const BLANK: Byte = ' '
const MAX_JSON_WRITE_DEPTH = 100

/*
 * This is a stringbuilder customized for json serialization.
 * Compared with stringbuilder, it has the following optimization points:
 *  1. Constructor with capacity, and func asumecapacity(jv: JsonVaule) is used to
 *     estimate the capacity in advance. Although this is not accurate,
 *     it can reduce a large amount of memory application and copy during
 *     long jsonvalue serialization.
 *  2. The cache(_buffer) is initialized with blank character. when adding blanks,
 *     only need to move the pointer.
 *  3. append(str: String), faster then StringBuilder.
 *  4. func removetail(), faster then StringBuilder.
 */
class WriteBuffer {
    private var _buffer: Array<Byte>
    private var _size: Int64 = 0

    /*
     * buff must be filled with blank
     */
    init(capacity: Int64) {
        let cap = if (capacity > MIN_CAPACITY) {
            capacity
        } else {
            MIN_CAPACITY
        }
        _buffer = Array<Byte>(cap, repeat: BLANK)
    }

    prop size: Int64 {
        get() {
            return _size
        }
    }

    /*
     * buff must be filled with blank
     */
    func checkAndExpend(addition: Int64): Unit {
        let minCapacity = _size + addition
        let oldCapacity: Int64 = _buffer.size
        if (minCapacity < oldCapacity) {
            return
        }

        var newCapacity: Int64 = oldCapacity + (oldCapacity >> 1)
        if (newCapacity < minCapacity) {
            newCapacity = minCapacity
        }
        let newArr: Array<Byte> = Array<Byte>(newCapacity, repeat: BLANK)
        _buffer.copyTo(newArr, 0, 0, _size)
        _buffer = newArr
    }

    func append(arr: Array<Byte>): WriteBuffer {
        checkAndExpend(arr.size)

        if (arr.size < 32) {
            for (index in 0..arr.size) {
                _buffer[_size] = arr[index]
                _size++
            }
        } else {
            arr.copyTo(_buffer, 0, _size, arr.size)
            _size += arr.size
        }
        return this
    }

    func append(str: String): WriteBuffer {
        append(unsafe { str.rawData() })
        return this
    }

    func append(byte: Byte): WriteBuffer {
        checkAndExpend(1)
        _buffer[_size] = byte
        _size++
        return this
    }

    func append(n: Int64): WriteBuffer {
        checkAndExpend(22)
        unsafe {
            let buff = acquireArrayRawData<Byte>(_buffer)
            let len = CJ_JSON_WriteBufferAppendInt(buff.pointer + _size, n)
            releaseArrayRawData(buff)
            _size += len
        }
        return this
    }

    func append(fl: Float64): WriteBuffer {
        unsafe {
            let p: CPointer<UInt8> = CJ_CORE_Float64ToCPointer(fl)
            if (p.isNull()) {
                return this
            }
            let cpSize = Int64(strlen(p))
            checkAndExpend(cpSize)
            let dest = acquireArrayRawData(_buffer)
            memcpy_s(dest.pointer + _size, UIntNative(_buffer.size - _size), p, UIntNative(cpSize))
            releaseArrayRawData(dest)
            LibC.free(p)
            _size += cpSize
        }

        // the result of CJ_CORE_Float64ToCPointer have at least 6 decimal points
        // there is no out-of-bounds risk
        while (_buffer[_size - 1] == b'0') {
            _size--
        }
        if (_buffer[_size - 1] == b'.') {
            _size--
        }
        return this
    }

    func append(b: Bool): WriteBuffer {
        if (b) {
            append(BOOL_TRUE_STRING)
        } else {
            append(BOOL_FALSE_STRING)
        }
    }

    func appendBlank(n: Int64): WriteBuffer {
        checkAndExpend(n)
        _size += n
        return this
    }

    func removetail(): WriteBuffer {
        if (_size > 0) {
            _size--
        }
        return this
    }

    func appendEscape(str: String, htmlSafe!: Bool = true) {
        var escapenum = 0

        unsafe {
            let input = acquireArrayRawData(str.rawData())
            escapenum = CJ_JSON_StringEscapeCharNumGet(input.pointer, str.size, htmlSafe)
            releaseArrayRawData(input)
        }

        if (escapenum == 0) {
            append(str)
            return this
        } else {
            checkAndExpend(str.size + escapenum)
            unsafe {
                let input = acquireArrayRawData(str.rawData())
                let buff = acquireArrayRawData<Byte>(_buffer)
                let len = CJ_JSON_ReplaceEscapeChar(input.pointer, str.size, buff.pointer + _size, htmlSafe)
                releaseArrayRawData(input)
                releaseArrayRawData(buff)
                _size += len
                return this
            }
        }
    }

    func getAndClear(): Array<Byte> {
        let ret = _buffer[0.._size]
        _buffer = Array<Byte>(0, repeat: BLANK)
        _size = 0
        return ret
    }

    @When[env != "ohos"]
    public exclave init(this @local!, capacity: Int64) {
        let cap = if (capacity > MIN_CAPACITY) {
            capacity
        } else {
            MIN_CAPACITY
        }
        _buffer = Array<Byte>(cap, repeat: BLANK) @local!
    }

    @When[env != "ohos"]
    public exclave func checkAndExpend(this @local!, addition: Int64): Unit {
        let minCapacity = _size + addition
        let oldCapacity: Int64 = _buffer.size
        if (minCapacity < oldCapacity) {
            return
        }

        var newCapacity: Int64 = oldCapacity + (oldCapacity >> 1)
        if (newCapacity < minCapacity) {
            newCapacity = minCapacity
        }
        let newArr: Array<Byte> @local! = Array<Byte>(newCapacity, repeat: BLANK)
        _buffer.copyTo(newArr, 0, 0, _size)
        _buffer = newArr
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, arr: Array<Byte> @local!): WriteBuffer @local! {
        appendBytes(arr)
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, arr: Array<Byte> @local?): WriteBuffer @local! { // cjlint-ignore !G.DCL.01
        appendBytes(arr)
    }

    @When[env != "ohos"]
    private exclave func appendBytes(this @local!, arr: Array<Byte> @local?): WriteBuffer @local! {
        checkAndExpend(arr.size)

        if (arr.size < 32) {
            for (index in 0..arr.size) {
                _buffer[_size] = arr[index]
                _size++
            }
        } else {
            arr.copyTo(_buffer, 0, _size, arr.size)
            _size += arr.size
        }
        this
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, str: String @local!): WriteBuffer @local! { // cjlint-ignore !G.DCL.01
        append(unsafe { str.rawData() })
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, str: String @local?): WriteBuffer @local! { // cjlint-ignore !G.DCL.01
        append(unsafe { str.toString().rawData() })
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, byte: Byte): WriteBuffer @local! {
        checkAndExpend(1)
        _buffer[_size] = byte
        _size++
        this
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, n: Int64): WriteBuffer @local! {
        checkAndExpend(22)
        unsafe {
            let buff = acquireArrayRawData<Byte>(_buffer)
            let len = CJ_JSON_WriteBufferAppendInt(buff.pointer + _size, n)
            releaseArrayRawData(buff)
            _size += len
        }
        this
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, fl: Float64): WriteBuffer @local! {
        unsafe {
            let p: CPointer<UInt8> = CJ_CORE_Float64ToCPointer(fl)
            if (p.isNull()) {
                return this
            }
            let cpSize = Int64(strlen(p))
            checkAndExpend(cpSize)
            let dest = acquireArrayRawData(_buffer)
            memcpy_s(dest.pointer + _size, UIntNative(_buffer.size - _size), p, UIntNative(cpSize))
            releaseArrayRawData(dest)
            LibC.free(p)
            _size += cpSize
        }

        while (_buffer[_size - 1] == b'0') {
            _size--
        }
        if (_buffer[_size - 1] == b'.') {
            _size--
        }
        this
    }

    @When[env != "ohos"]
    public exclave func append(this @local!, b: Bool): WriteBuffer @local! {
        if (b) {
            append(b't').append(b'r').append(b'u').append(b'e')
        } else {
            append(b'f').append(b'a').append(b'l').append(b's').append(b'e')
        }
    }

    @When[env != "ohos"]
    public exclave func appendBlank(this @local!, n: Int64): WriteBuffer @local! {
        checkAndExpend(n)
        _size += n
        this
    }

    @When[env != "ohos"]
    public exclave func removetail(this @local!): WriteBuffer @local! {
        if (_size > 0) {
            _size--
        }
        this
    }

    @When[env != "ohos"]
    public exclave func appendEscape(this @local!, str: String @local!, htmlSafe!: Bool = true): WriteBuffer @local! { // cjlint-ignore !G.DCL.01
        appendEscapeOwned(str, htmlSafe)
    }

    @When[env != "ohos"]
    public exclave func appendEscape(this @local!, str: String @local?, htmlSafe!: Bool = true): WriteBuffer @local! { // cjlint-ignore !G.DCL.01
        appendEscapeOwned(str.toString(), htmlSafe)
    }

    @When[env != "ohos"]
    private exclave func appendEscapeOwned(this @local!, materialised: String @local!, htmlSafe: Bool): WriteBuffer @local! {
        var escapenum = 0

        unsafe {
            let input = acquireArrayRawData(materialised.rawData())
            escapenum = CJ_JSON_StringEscapeCharNumGet(input.pointer, materialised.size, htmlSafe)
            releaseArrayRawData(input)
        }

        if (escapenum == 0) {
            append(materialised)
            return this
        }

        checkAndExpend(materialised.size + escapenum)
        unsafe {
            let input = acquireArrayRawData(materialised.rawData())
            let buff = acquireArrayRawData<Byte>(_buffer)
            let len = CJ_JSON_ReplaceEscapeChar(input.pointer, materialised.size, buff.pointer + _size, htmlSafe)
            releaseArrayRawData(input)
            releaseArrayRawData(buff)
            _size += len
        }
        this
    }

    @When[env != "ohos"]
    public exclave func getAndClear(this @local!): Array<Byte> @local! {
        let ret: Array<Byte> @local! = _buffer[0.._size]
        _buffer = Array<Byte>(0, repeat: BLANK) @local!
        _size = 0
        ret
    }
}

@When[env != "ohos"]
exclave func jsonWriteWithoutFormat(json: JsonValue @local?, buff: WriteBuffer @local!, htmlSafe!: Bool = true): Unit {
    jsonWriteWithoutFormat(json, buff, 0, htmlSafe: htmlSafe)
}

@When[env != "ohos"]
exclave func jsonWriteWithoutFormat(json: JsonValue @local?, buff: WriteBuffer @local!, depth: Int64,
    htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            if (jo.size() == 0) {
                buff.append(b'{').append(b'}')
                return
            }
            buff.append(b'{')
            for ((strKey, jv) in jo.getFields()) {
                buff.append(b'\"').appendEscape(strKey, htmlSafe: htmlSafe).append(b'\"').append(b':')
                jsonWriteWithoutFormat(jv, buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b'}')
        case ja: JsonArray =>
            if (ja.size() == 0) {
                buff.append(b'[').append(b']')
                return
            }
            buff.append(b'[')
            let items = ja.getItems()
            for (index in 0..items.size) {
                jsonWriteWithoutFormat(items[index], buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b']')
        case js: JsonString => buff.append(b'\"').appendEscape(js.getValue(), htmlSafe: htmlSafe).append(b'\"')
        case jb: JsonBool => buff.append(jb.getValue())
        case ji: JsonInt => buff.append(ji.getValue())
        case jf: JsonFloat => buff.append(jf.getValue())
        case _: JsonNull => buff.append(b'n').append(b'u').append(b'l').append(b'l')
        // Unreachable once all JsonValue subclasses are covered; kept for exhaustiveness.
        case _ => throw JsonException("Unsupported JsonValue type.")
    }
}

@When[env != "ohos"]
exclave func jsonWriteObject(json: JsonObject @local?, buff: WriteBuffer @local!, depth: Int64,
    bracketInNewLine: Bool, indent: String @local?, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append(b'{').append(b'}')
        return
    }

    buff.append(b'{')
    let new_depth = depth + 1
    for ((key, jv) in json.getFields()) {
        buff.append(b'\n')
        for (_ in 0..new_depth) {
            buff.append(indent)
        }
        buff.append(b'\"').appendEscape(key, htmlSafe: htmlSafe).append(b'\"').append(b':').appendBlank(1)
        match (jv) {
            case jo: JsonObject => jsonWriteObject(jo, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case ja: JsonArray => jsonWriteArray(ja, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case _ => jsonWriteWithoutFormat(jv, buff, new_depth, htmlSafe: htmlSafe)
        }
        buff.append(b',')
    }
    buff.removetail()
    buff.append(b'\n')
    for (_ in 0..depth) {
        buff.append(indent)
    }
    buff.append(b'}')
}

@When[env != "ohos"]
exclave func jsonWriteArray(json: JsonArray @local?, buff: WriteBuffer @local!, depth: Int64,
    bracketInNewLine: Bool, indent: String @local?, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append(b'[').append(b']')
        return
    }

    buff.append(b'[')
    let new_depth = depth + 1
    let items = json.getItems()
    for (index in 0..items.size) {
        buff.append(b'\n')
        for (_ in 0..new_depth) {
            buff.append(indent)
        }
        let value = items[index]
        match (value) {
            case jo: JsonObject => jsonWriteObject(jo, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case ja: JsonArray => jsonWriteArray(ja, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case _ => jsonWriteWithoutFormat(value, buff, new_depth, htmlSafe: htmlSafe)
        }
        buff.append(b',')
    }
    buff.removetail()
    buff.append(b'\n')
    for (_ in 0..depth) {
        buff.append(indent)
    }
    buff.append(b']')
}

@When[env != "ohos"]
func asumecapacity(json: JsonValue @local?, depth: Int64): Int64 {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            var sum: Int64 = 2
            for ((key, value) in jo.getFields()) {
                sum += key.size + 4
                sum += asumecapacity(value, depth + 1)
            }
            sum
        case ja: JsonArray =>
            var sum: Int64 = 2
            let items = ja.getItems()
            for (index in 0..items.size) {
                sum += asumecapacity(items[index], depth + 1) + 1
            }
            sum
        case js: JsonString => js.getValue().size + 2
        case _: JsonBool => 5
        case _: JsonInt => 22
        case _: JsonFloat => 200
        case _: JsonNull => 4
        // Unreachable once all JsonValue subclasses are covered; kept for exhaustiveness.
        case _ => throw JsonException("Unsupported JsonValue type.")
    }
}

@When[env != "ohos"]
func asumecapacity(json: JsonValue @local?): Int64 {
    asumecapacity(json, 0)
}

func checkJsonWriteDepth(depth: Int64): Unit {
    if (depth > MAX_JSON_WRITE_DEPTH) {
        throw JsonException("Json nested depth exceeds ${MAX_JSON_WRITE_DEPTH}.")
    }
}

func jsonWriteWithoutFormat(json: JsonValue, buff: WriteBuffer, htmlSafe!: Bool = true): Unit {
    jsonWriteWithoutFormat(json, buff, 0, htmlSafe: htmlSafe)
}

func jsonWriteWithoutFormat(json: JsonValue, buff: WriteBuffer, depth: Int64, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            if (jo.size() == 0) {
                buff.append("{}".toArray())
                return
            }
            buff.append(b'{')
            for ((strKey, jv) in jo.getFields()) {
                buff.append(b'\"').appendEscape(strKey).append("\":".toArray())
                jsonWriteWithoutFormat(jv, buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b'}')
        case ja: JsonArray =>
            if (ja.size() == 0) {
                buff.append("[]".toArray())
                return
            }
            buff.append(b'[')
            for (item in ja.getItems()) {
                jsonWriteWithoutFormat(item, buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b']')
        case js: JsonString => buff.append(b'\"').appendEscape(js.getValue(), htmlSafe:htmlSafe).append(b'\"')
        case jb: JsonBool => buff.append(jb.getValue())
        case ji: JsonInt => buff.append(ji.getValue())
        case jf: JsonFloat => buff.append(jf.getValue())
        case _ => buff.append(NULL_STRING)
    }
}

func jsonWriteObject(json: JsonObject, buff: WriteBuffer, depth: Int64, bracketInNewLine: Bool, indent: String, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append("{}".toArray())
        return
    }

    buff.append(b'{')
    let new_depth = depth + 1
    for ((key, jv) in json.getFields()) {
        buff.append(b'\n')
        for (_ in 0..new_depth) {
            buff.append(indent)
        }
        buff.append(b'\"').appendEscape(key).append(b'\"').append(b':').appendBlank(1)
        match (jv) {
            case jo: JsonObject => jsonWriteObject(jo, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case ja: JsonArray => jsonWriteArray(ja, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case _ => jsonWriteWithoutFormat(jv, buff, new_depth, htmlSafe: htmlSafe)
        }
        buff.append(b',')
    }
    buff.removetail()
    buff.append(b'\n')
    for (_ in 0..depth) {
        buff.append(indent)
    }
    buff.append(b'}')
}

func jsonWriteArray(json: JsonArray, buff: WriteBuffer, depth: Int64, bracketInNewLine: Bool, indent: String, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append("[]".toArray())
        return
    }

    buff.append(b'[')
    let new_depth = depth + 1
    for (v in json.getItems()) {
        buff.append(b'\n')
        for (_ in 0..new_depth) {
            buff.append(indent)
        }
        match (v) {
            case jo: JsonObject => jsonWriteObject(jo, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case ja: JsonArray => jsonWriteArray(ja, buff, new_depth, false, indent, htmlSafe: htmlSafe)
            case _ => jsonWriteWithoutFormat(v, buff, new_depth, htmlSafe: htmlSafe)
        }
        buff.append(b',')
    }
    buff.removetail()
    buff.append(b'\n')
    for (_ in 0..depth) {
        buff.append(indent)
    }
    buff.append(b']')
}

// Keep container capacity estimation recomputed on each serialization. JsonArray and JsonObject expose
// mutable backing collections, so a persistent cached capacity could become stale after external mutation.
func asumecapacity(json: JsonValue, depth: Int64): Int64 {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            var sum: Int64 = 2  // {}
            for ((k, v) in jo.getFields()) {
                sum += k.size + 4  // "key": ,
                sum += asumecapacity(v, depth + 1)
            }
            return sum
        case ja: JsonArray =>
            var sum: Int64 = 2  // []
            for (v in ja.getItems()) {
                sum += asumecapacity(v, depth + 1) + 1  // value + comma
            }
            return sum
        case js: JsonString => return js.getValue().size + 2  // "value"
        case _: JsonBool => return 5  // max of "false" and "true"
        case _: JsonInt => return 22  // max len is 22
        case _: JsonFloat => return 200  // not precision
        case _: JsonNull => return 4  // "null"
        case _ => return 0
    }
}

func asumecapacity(json: JsonValue): Int64 {
    return asumecapacity(json, 0)
}
