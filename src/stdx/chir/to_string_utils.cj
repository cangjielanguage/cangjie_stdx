/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.chir

internal const INDENT_SPACE: UInt64 = 2
internal func indentToString(indent: UInt64): String {
    return StringBuilder(r' ', Int64(indent)).toString()
}

internal func typeVecToString<T>(start: String, types: Array<T>, end: String): String where T <: Type {
    if (types.isEmpty()) {
        return String.empty
    }
    let result = StringBuilder()
    result.append(start)
    result.append(String.join(types.map({ ty => ty.toString() }), delimiter: ", "))
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
        assert(size >= 2, "Wrong value size")
        result[size - 2] = "normal: " + result[size - 2]
        result[size - 1] = "exception: " + result[size - 1]
    }
    return prefix + String.join(result.toArray(), delimiter: ", ") + suffix
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
    result += "Func " + obj.identifier + typeVecToString("<", obj.genericTypeParams, ">")
    // parameters
    var params = ArrayList<String>()
    for (param in obj.parameters) {
        parameterToString(param, indent + INDENT_SPACE)
    }
    result += "(" + String.join(params.toArray(), delimiter: ",\n")
    result += "\n" + indentToString(indent) + ")"
    // return type
    result += ": " + (obj.ty as FuncType).getOrThrow().returnType.toString()
    // generic constraints
    result += genericTypeParamsConstraintToString(obj.genericTypeParams)
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
    if (obj._paramDftValHostFunc.isSome()) {
        comment.add("paramDftValHostFunc: " + obj._paramDftValHostFunc.getOrThrow().identifier)
    }
    if (obj._oriLambdaFuncTy.isSome()) {
        comment.add("oriLambdaFuncTy: " + obj._oriLambdaFuncTy.getOrThrow().toString())
    }
    if (obj._oriLambdaGenericTypeParams.isSome()) {
        comment.add("oriLambdaGenericTypeParams: " + typeVecToString("<", obj._oriLambdaGenericTypeParams.getOrThrow().toArray(), ">"))
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

internal func lambdaToString(expr: Lambda, indent: UInt64): String {
    var result = ""
    result += indentToString(indent)
    result += expr.result.identifier + ": " + expr.result.ty.toString() + " = "
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
        parameterToString(param, indent + INDENT_SPACE)
    }
    result += "(" + String.join(params.toArray(), delimiter: ",\n")
    result += "\n" + indentToString(indent) + ")"
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
    result.append(obj.identifier + ": " + obj.ty.toString())
    if (let str <- obj.baseCommentToString() && !str.isEmpty()) {
        result.append(" // ")
        result.append(str)
    }
    return result.toString()
}

internal func annoInfoToString(obj: AnnoInfo, indent: UInt64): String {
    let result = StringBuilder()
    result.append(indentToString(indent))
    result.append(String.join(obj._annoClasses.toArray().map({ anno => anno.toString() }), delimiter: "\n"))
    return result.toString()
}

internal func enumCtorInfoToString(obj: EnumCtorInfo, indent: UInt64): String {
    let result = StringBuilder()
    if (let str <- annoInfoToString(obj._annotations, indent) && !str.isEmpty()) {
        result.append(str)
        result.append("\n")
    }
    result.append(indentToString(indent))
    result.append(obj.srcCodeName)
    result.append(typeVecToString("(", obj.funcType.paramTypes, ")"))
    return result.toString()
}