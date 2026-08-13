package stdx.encoding.json
exclave func jsonWriteWithoutFormat(json: JsonValue @local?, buff: WriteBuffer @local!, htmlSafe!: Bool = true): Unit {
    jsonWriteWithoutFormat(json, buff, 0, htmlSafe: htmlSafe)
}

exclave func jsonWriteWithoutFormat(json: JsonValue @local?, buff: WriteBuffer @local!, depth: Int64, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            if (jo.size() == 0) {
                buff.append(b'{')
                buff.append(b'}')
                return
            }
            buff.append(b'{')
            for ((strKey, jv) in jo.getFields()) {
                buff.append(b'\"')
                buff.appendEscape(strKey)
                buff.append("\":".toArray())
                jsonWriteWithoutFormat(jv, buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b'}')
        case ja: JsonArray =>
            if (ja.size() == 0) {
                buff.append(b'[')
                buff.append(b']')
                return
            }
            buff.append(b'[')
            for (item in ja.getItems()) {
                jsonWriteWithoutFormat(item, buff, depth + 1, htmlSafe: htmlSafe)
                buff.append(b',')
            }
            buff.removetail()
            buff.append(b']')
        case js: JsonString => buff.append(b'\"')
            buff.appendEscape(js.getValue(), htmlSafe:htmlSafe)
            buff.append(b'\"')
        case jb: JsonBool => buff.append(jb.getValue())
        case ji: JsonInt => buff.append(ji.getValue())
        case jf: JsonFloat => buff.append(jf.getValue())
        case _ => buff.append("null")
    }
}

exclave func jsonWriteObject(json: JsonObject @local?, buff: WriteBuffer @local!, depth: Int64, bracketInNewLine: Bool, indent: String @local!, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append(b'{')
        buff.append(b'}')
        return
    }

    buff.append(b'{')
    let new_depth = depth + 1
    for ((key, jv) in json.getFields()) {
        buff.append(b'\n')
        for (_ in 0..new_depth) {
            buff.append(indent)
        }
        buff.append(b'\"')
        buff.appendEscape(key)
        buff.append(b'\"')
        buff.append(b':')
        buff.appendBlank(1)
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

exclave func jsonWriteArray(json: JsonArray @local?, buff: WriteBuffer @local!, depth: Int64, bracketInNewLine: Bool, indent: String @local!, htmlSafe!: Bool = true): Unit {
    checkJsonWriteDepth(depth)
    if (bracketInNewLine) {
        for (_ in 0..depth) {
            buff.append(indent)
        }
    }

    if (json.size() == 0) {
        buff.append("[]")
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

exclave func estimateCapacityWithDepth(json: JsonValue @local?, depth: Int64): Int64 {
    checkJsonWriteDepth(depth)
    match (json) {
        case jo: JsonObject =>
            var sum: Int64 = 2  // {}
            for ((k, v) in jo.getFields()) {
                sum += k.size + 4  // "key": ,
                sum += estimateCapacityWithDepth(v, depth + 1)
            }
            return sum
        case ja: JsonArray =>
            var sum: Int64 = 2  // []
            for (v in ja.getItems()) {
                sum += estimateCapacityWithDepth(v, depth + 1) + 1  // value + comma
            }
            return sum
        case _ => return json.estimateCapacity()
    }
}

exclave func asumecapacity(json: JsonValue @local?): Int64 {
    return estimateCapacityWithDepth(json, 0)
}

exclave func asumecapacity(json: JsonValue @local?, depth: Int64): Int64 {
    return estimateCapacityWithDepth(json, depth)
}
