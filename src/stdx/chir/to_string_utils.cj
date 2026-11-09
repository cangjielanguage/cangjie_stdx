/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

internal const INDENT_SPACE: UInt64 = 2

internal func annoInfoToString(obj: AnnoInfo, indent: UInt64): String {
    let result = StringBuilder()
    if (!obj._annoInstances.isEmpty()) {
        result.append(indentToString(indent))
        result.append(String.join(obj._annoInstances.toArray().mapTo({ anno => annoInstanceToString(anno, indent) }), delimiter: "\n"))
    }
    return result.toString()
}

internal func annoInstanceToString(obj: CustomAnnoInstance, indent: UInt64): String {
    let result = StringBuilder()
    result.append(indentToString(indent))
    result.append("@")
    result.append(obj._classSrcCodeName)
    result.append("[")
    result.append(String.join(obj._argValues.toArray(), delimiter: ", "))
    result.append("]")
    return result.toString()
}

internal func blockGroupToString(obj: BlockGroup, indent: UInt64): String {
    var result = ""
    result += indentToString(indent)
    result += obj._attributes.toString()
    result += "{"
    var comment = ArrayList<String>()
    comment.add("Block Group: " + obj.identifier)
    if (let str <- obj.baseCommentToString() && !str.isEmpty()) {
        comment.add(str)
    }
    if (!comment.isEmpty()) {
        result += " // " + String.join(comment.toArray(), delimiter: ", ")
    }
    for (block in obj.blocks) {
        result += "\n"
        result += blockToString(block, indent)
    }
    result += "\n" + indentToString(indent) + "}"
    return result
}

internal func blockToString(obj: Block, indent: UInt64): String {
    var result = ""
    result += indentToString(indent)
    result += obj._attributes.toString()
    result += "Block " + obj.identifier + ":"
    var comment = ArrayList<String>()
    if (let str <- valueIdVecToString("[", obj._predecessors, "]", false) && !str.isEmpty()) {
        comment.add("predecessors: " + str)
    }
    if (let str <- obj.baseCommentToString() && !str.isEmpty()) {
        comment.add(str)
    }
    if (obj.isLandingPadBlock) {
        var exceptionStr = typeVecToString("[", obj.exceptions, "]")
        if (exceptionStr.isEmpty()) {
            comment.add("exceptions: [All]")
        } else {
            comment.add("exceptions: " + exceptionStr)
        }
    }
    if (!comment.isEmpty()) {
        result += " // " + String.join(comment.toArray(), delimiter: ", ")
    }
    for (expr in obj.exprs) {
        result += "\n"
        result += expressionToString(expr, indent + INDENT_SPACE)
    }
    return result
}

internal func enumCtorInfoToString(obj: EnumCtorInfo, indent: UInt64): String {
    let result = StringBuilder()
    if (let str <- annoInfoToString(obj._annoInfo, indent) && !str.isEmpty()) {
        result.append(str)
        result.append("\n")
    }
    result.append(indentToString(indent))
    result.append(obj.srcCodeName)
    result.append(typeVecToString("(", obj.funcType.paramTypes, ")"))
    return result.toString()
}

internal func expressionToString(expr: Expression, indent: UInt64): String {
    var result = ""
    if (expr._kind == ExprKind.Lambda) {
        result += lambdaToString((expr as Lambda).getOrThrow(), indent)
    } else {
        result += indentToString(indent)
        result += expr.toString()
    }
    return result
}

internal func functionToString(obj: Function, indent: UInt64): String {
    var result = ""
    result += indentToString(indent)
    result += obj._attributes.toString()
    if (obj._isFastNative) {
        result += "[fastNative]"
    }
    if (obj._isCFFIWrapper) {
        result += "[CFFIWrapper]"
    }

    // function identifier
    result += "Func " + obj.identifier + typeVecToString("<", obj.genericTypeParams, ">") + "("

    // parameters
    var params = ArrayList<String>()
    for (param in obj.parameters) {
        params.add(parameterToString(param, indent + INDENT_SPACE))
    }
    if (!params.isEmpty()) {
        result += "\n"
        result += String.join(params.toArray(), delimiter: ",\n")
        result += "\n" + indentToString(indent)
    }

    // return type
    result += "): " + (obj.ty as FuncType).getOrThrow().returnType.toString()

    // generic constraints
    result += genericTypeParamsConstraintToString(obj.genericTypeParams)

    // comments
    var comment = ArrayList<String>()
    if (let str <- obj.baseCommentToString() && !str.isEmpty()) {
        comment.add(str)
    }
    if (obj._funcKind != FuncKind.Default) {
        comment.add("funcKind: " + obj._funcKind.toString())
    }
    if (obj._genericDecl.isSome()) {
        comment.add("genericDecl: " + obj._genericDecl.getOrThrow().identifier)
    }
    if (let str <- obj.globalValueToString() && !str.isEmpty()) {
        comment.add(str)
    }
    if (obj._propLocation.isValid()) {
        comment.add("propLocation: " + obj._propLocation.toString())
    }
    if (let Some(host) <- obj._paramDftValHostParam) {
        comment.add(paramDftValHostParamComment(host))
    }
    if (let Some(v) <- obj._originalLambdaInfo) {
        comment.add("originalLambdaInfo: " + v.toString())
    }
    if (!comment.isEmpty()) {
        result += " // " + String.join(comment.toArray(), delimiter: ", ")
    }

    // body
    if (let Some(body) <- obj._body) {
        result += "\n"
        result += blockGroupToString(body, indent)
    }
    return result
}

internal func genericTypeParamsConstraintToString(obj: Array<GenericType>): String {
    if (obj.isEmpty()) {
        return String.empty
    }
    var result = ArrayList<String>()
    for (gType in obj) {
        if (gType.upperBounds.isEmpty()) {
            continue
        }
        var upperBoundStr = ArrayList<String>()
        for (bound in gType.upperBounds) {
            upperBoundStr.add(bound.toString())
        }
        result.add(gType.srcCodeName + " <: " + String.join(upperBoundStr.toArray(), delimiter: " & "))
    }
    if (result.isEmpty()) {
        return String.empty
    }
    return " where " + String.join(result.toArray(), delimiter: ", ")
}

internal func indentToString(indent: UInt64): String {
    return StringBuilder(r' ', Int64(indent)).toString()
}

internal func lambdaToString(expr: Lambda, indent: UInt64): String {
    var result = ""
    result += indentToString(indent)
    if (let Some(v) <- expr._result) {
        result += localVarResultToString(v)
    } else {
        throw CHIRException("Lambda result is not set.")
    }
    if (expr.isCompileTimeValue) {
        result += "[compileTimeVal]"
    }
    if (expr.isLocalFunc) {
        result += "[localFunc]"
    }
    result += expr._kind.toString() + " " + expr.identifier + typeVecToString("<", expr.genericTypeParams, ">")

    // parameters
    var params = ArrayList<String>()
    for (param in expr.parameters) {
        params.add(parameterToString(param, indent + INDENT_SPACE))
    }
    result += "("
    if (!params.isEmpty()) {
        result += "\n"
        result += String.join(params.toArray(), delimiter: ",\n")
        result += "\n" + indentToString(indent)
    }
    result += ")"
    result += ": " + expr.funcType.returnType.toString()
    result += genericTypeParamsConstraintToString(expr.genericTypeParams)
    result += "\n"
    result += blockGroupToString(expr.body, indent)
    result += expr.getCommentString()
    return result
}

internal func parameterToString(obj: Parameter, indent: UInt64): String {
    let result = StringBuilder()
    if (let str <- annoInfoToString(obj._annoInfo, indent) && !str.isEmpty()) {
        result.append(str)
        result.append("\n")
    }
    result.append(indentToString(indent))
    result.append(obj._attributes.toString())
    result.append(obj.identifier)
    if (!obj._srcCodeName.isEmpty()) {
        result.append("[" + obj._srcCodeName + "]")
    }
    result.append(": " + obj.ty.toString())
    var comments = ArrayList<String>()
    if (let str <- obj.baseCommentToString() && !str.isEmpty()) {
        comments.add(str)
    }
    if (let Some(dft) <- obj._paramDftValFunc) {
        comments.add("paramDftValFunc: " + dft.identifier)
    }
    if (!comments.isEmpty()) {
        result.append(" // ")
        result.append(String.join(comments.toArray(), delimiter: ", "))
    }
    return result.toString()
}

// Matches compiler Expression::ToString: `%id[srcCodeName]: type =`.
internal func localVarResultToString(v: LocalVar): String {
    var result = ""
    if (v._isRetValue) {
        result += "[ret] "
    }
    result += v.identifier
    if (!v._srcCodeName.isEmpty()) {
        result += "[" + v._srcCodeName + "]"
    }
    result += ": " + v.ty.toString() + " = "
    return result
}

// Host may be a Function, or a Lambda whose result LocalVar owns the parameter.
internal func paramDftValHostParamComment(param: Parameter): String {
    let ownerId = if (let Some(owner) <- (param._owner as Function)) {
        owner.identifier
    } else if (let Some(lv) <- (param._owner as LocalVar) && lv.expr.isLambda()) {
        (lv.expr as Lambda).getOrThrow().identifier
    } else {
        throw CHIRException("paramDftValHostParam owner is neither Function nor Lambda")
    }
    return "paramDftValHostParam: ${ownerId}[${param.identifier}]"
}

internal func typeVecToString<T>(start: String, types: Array<T>, end: String): String where T <: Type {
    if (types.isEmpty()) {
        return String.empty
    }
    let result = StringBuilder()
    result.append(start)
    result.append(String.join(types.mapTo({ ty => ty.toString() }), delimiter: ", "))
    result.append(end)
    return result.toString()
}

internal func valueIdVecToString<T>(prefix: String, values: ArrayList<T>, suffix: String, hasExceptionBranch: Bool): String where T <: Value {
    if (values.isEmpty()) {
        return ""
    }
    var result = ArrayList<String>()
    for (value in values) {
        if (value.isLiteral()) {
            result.add(value.toString())
        } else {
            result.add(value.identifier)
        }
    }
    if (hasExceptionBranch) {
        let size = result.size
        assert(size >= 2, "Value size must be at least 2.")
        result[size - 2] = "normal: " + result[size - 2]
        result[size - 1] = "exception: " + result[size - 1]
    }
    return prefix + String.join(result.toArray(), delimiter: ", ") + suffix
}
