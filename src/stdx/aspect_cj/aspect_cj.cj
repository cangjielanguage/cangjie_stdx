/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0 
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.aspect_cj

import std.collection.*
import stdx.chir.*

protected const ANNO_INFO_FILE_SUFFIX = ".annoinfo"
protected const PACKAGE_NAME_CONNECTOR = "-"
protected const INSERT_AT_ENTRY_ANNO_CLASS_NAME = "InsertAtEntry"
protected const INSERT_AT_EXIT_ANNO_CLASS_NAME = "InsertAtExit"
protected const REPLACE_FUNC_BODY_ANNO_CLASS_NAME = "ReplaceFuncBody"

@Annotation
public class InsertAtEntry {
    let packageName: String
    let className: String
    let methodName: String
    let isStatic: Bool
    let recursive: Bool
    let funcTypeStr: String
    public const init(packageName!: String, className!: String, methodName!: String, isStatic!: Bool, recursive!: Bool, funcTypeStr!: String) {
        this.packageName = packageName
        this.className = className
        this.methodName = methodName
        this.isStatic = isStatic
        this.recursive = recursive
        this.funcTypeStr = funcTypeStr
    }
}

@Annotation
public class InsertAtExit {
    let packageName: String
    let className: String
    let methodName: String
    let isStatic: Bool
    let recursive: Bool
    let funcTypeStr: String
    public const init(packageName!: String, className!: String, methodName!: String, isStatic!: Bool, recursive!: Bool, funcTypeStr!: String) {
        this.packageName = packageName
        this.className = className
        this.methodName = methodName
        this.isStatic = isStatic
        this.recursive = recursive
        this.funcTypeStr = funcTypeStr
    }
}

@Annotation
public class ReplaceFuncBody {
    let packageName: String
    let className: String
    let methodName: String
    let isStatic: Bool
    let recursive: Bool
    public const init(packageName!: String, className!: String, methodName!: String, isStatic!: Bool, recursive!: Bool) {
        this.packageName = packageName
        this.className = className
        this.methodName = methodName
        this.isStatic = isStatic
        this.recursive = recursive
    }
}

protected struct To {
    let packageName: String
    let className: String
    let methodName: String
    let funcTypeStr: String
    let isStatic: Bool
    let recursively: Bool
    public init(packageName: String, className: String, methodName: String, funcTypeStr: String, isStatic: Bool, recursively: Bool) {
        this.packageName = packageName
        this.className = className
        this.methodName = methodName
        this.funcTypeStr = funcTypeStr
        this.isStatic = isStatic
        this.recursively = recursively
    }
}

protected struct Insert {
    let packageName: String
    let methodMangledName: String
    let paramsNum: Int64
    let isMemberFunc: Bool
    let isStatic: Bool
    public init(packageName: String, methodMangledName: String, paramsNum: Int64, isMemberFunc: Bool, isStatic: Bool) {
        this.packageName = packageName
        this.methodMangledName = methodMangledName
        this.paramsNum = paramsNum
        this.isMemberFunc = isMemberFunc
        this.isStatic = isStatic
    }
}

protected struct OutputInfo {
    let annoClassName: String
    let insert: Insert
    let to: To
    public init(annoClassName: String, insert: Insert, to: To) {
        this.annoClassName = annoClassName
        this.insert = insert
        this.to = to
    }
}

protected func getFuncOuterTypeName(f: Function): String {
    if (!f.isMemberMethod()) {
        return ""
    }
    let outerType = f.declaredParent.getOrThrow().ty
    if (let Some(c) <- (outerType as CustomType)) {
        return c.def.srcCodeName
    } else {
        return outerType.qualifiedName
    }
}

protected func mapArrayTo<T, R>(array: Array<T>, f: (T) -> R): Array<R> {
    var result = ArrayList<R>()
    for (i in array) {
        result.add(f(i))
    }
    return result.toArray()
}

protected func isInsertAnno(item: String): Bool {
    return item == INSERT_AT_ENTRY_ANNO_CLASS_NAME || item == INSERT_AT_EXIT_ANNO_CLASS_NAME
}

protected func isReplaceBodyAnno(item: String): Bool {
    return item == REPLACE_FUNC_BODY_ANNO_CLASS_NAME
}
