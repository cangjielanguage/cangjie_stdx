/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.aspect_cj.plugins.collect_aspects

import std.collection.*
import std.convert.*
import std.fs.*
import stdx.aspect_cj.*
import stdx.chir.*
import stdx.plugin.*

@CHIRPlugin
class CollectAspects {
    var isGlobalVarsChecked = false
    var annoInfoFilePaths = HashSet<String>()

    public override func run(pkg: Package): Bool {
        var success = true
        for (f in pkg.functions) {
            if (f.isImported() || f.isCompilerAdd()) {
                continue
            }
            success = checkAndCollect(f, pkg) && success
        }
        return success
    }

    private func printError(msg: String): Unit {
        println(msg)
    }

    private func globalVarsArePrimitiveLiterals(pkg: Package): Bool {
        if (isGlobalVarsChecked) {
            return true
        }
        for (gv in pkg.globalVars) {
            if (gv.isImported() || gv.isCompilerAdd()) {
                continue
            }
            if (!gv.ty.stripAllRefs().isPrimitiveType()) {
                return false
            }
            if (gv.initializer == None || !gv.initializer.getOrThrow().isLiteral()) {
                return false
            }
        }
        isGlobalVarsChecked = true
        return true
    }

    private func checkAndCollect(f: Function, pkg: Package): Bool {
        let annoInstances = f.customAnnoInstances
        if (annoInstances.isEmpty()) {
            return true
        }
        var hasInsertAnno = false
        var hasReplaceBodyAnno = false
        var result = true
        for (anno in annoInstances) {
            let isInsert = isInsertAnno(anno.classSrcCodeName)
            let isReplaceBody = isReplaceBodyAnno(anno.classSrcCodeName)
            hasInsertAnno ||= isInsert
            hasReplaceBodyAnno ||= isReplaceBody
            if (hasInsertAnno && hasReplaceBodyAnno) {
                printError("Function '${f.srcCodeName}' cannot have both @InsertAtEntry/@InsertAtExit and @ReplaceFuncBody annotations.")
                return false
            }
            if (!isInsert && !isReplaceBody) {
                continue
            }
            if (!globalVarsArePrimitiveLiterals(pkg)) {
                printError("Global variables in package '${pkg.name}' must be initialized with primitive literal values when AOP annotations are used.")
                return false
            }
            if (!checkAspectFunction(f)) {
                return false
            }
            if (!checkAnnotationArgs(f, anno)) {
                return false
            }
            if (isInsert && !checkInsertAnnoFuncType(f, anno.argValues)) {
                return false
            }
            if (isReplaceBody && !checkReplaceBodyAnnoFuncType(f, anno.argValues)) {
                return false
            }
            let insert = Insert(
                pkg.name,
                f.identifierWithoutPrefix,
                f.parameters.size,
                f.isMemberMethod(),
                f.isStatic())
            let funcTypeStr = if (isInsert) {
                anno.argValues[5]
            } else {
                f.parameters[f.parameters.size - 1].ty.qualifiedName
            }
            let to = To(
                anno.argValues[0],
                anno.argValues[1],
                anno.argValues[2],
                funcTypeStr,
                Bool.parse(anno.argValues[3]),
                Bool.parse(anno.argValues[4]))
            result = writeAnnoInfoToFile(pkg, OutputInfo(anno.classSrcCodeName, insert, to)) && result
        }
        return result
    }

    private func writeAnnoInfoToFile(curPackage: Package, output: OutputInfo): Bool {
        if (!isValidPackageName(output.to.packageName)) {
            printError("Invalid package name '${output.to.packageName}': expected a non-empty valid Cangjie package name with valid segments and no path separators (/, \\, ..).")
            return false
        }
        let fileName = curPackage.name + PACKAGE_NAME_CONNECTOR + output.to.packageName + ANNO_INFO_FILE_SUFFIX
        let mode = if (annoInfoFilePaths.add(fileName)) {
            OpenMode.Write
        } else {
            OpenMode.Append
        }
        try (outFile = File(Path(fileName), mode)) {
            outFile.write((curPackage.name + "\n").toArray())
            let initFunc = curPackage.packageInitFunc.getOrThrow()
            outFile.write((initFunc.identifierWithoutPrefix + "\n").toArray())
            outFile.write((output.annoClassName + "\n").toArray())
            outFile.write((output.insert.packageName + "\n").toArray())
            outFile.write((output.insert.methodMangledName + "\n").toArray())
            outFile.write((output.insert.paramsNum.toString() + "\n").toArray())
            outFile.write((output.insert.isMemberFunc.toString() + "\n").toArray())
            outFile.write((output.insert.isStatic.toString() + "\n").toArray())
            outFile.write((output.to.packageName + "\n").toArray())
            outFile.write((output.to.className + "\n").toArray())
            outFile.write((output.to.methodName + "\n").toArray())
            outFile.write((output.to.funcTypeStr + "\n").toArray())
            outFile.write((output.to.isStatic.toString() + "\n").toArray())
            outFile.write((output.to.recursively.toString() + "\n").toArray())
            outFile.close()
        } catch (_: Exception) {
            printError("Failed to prepare or write annotation information for package '${curPackage.name}' to file '${fileName}'.")
            return false
        }
        return true
    }

    private func checkAspectFunction(f: Function): Bool {
        if (!f.isPublic() || !f.isExternalLinkage()) {
            printError("Function '${f.srcCodeName}' with AOP annotations must be public and have external linkage.")
            return false
        }
        if (f.isForeign()) {
            printError("Function '${f.srcCodeName}' with AOP annotations cannot be foreign.")
            return false
        }
        if (f.isAbstract()) {
            printError("Function '${f.srcCodeName}' with AOP annotations cannot be abstract.")
            return false
        }
        let outerDef = getFuncOuterDeclaredOrExtendedDef(f)
        if (f.isGeneric() || (outerDef.isSome() && outerDef.getOrThrow().isGeneric())) {
            printError("Function '${f.srcCodeName}' with AOP annotations cannot be generic or belong to a generic type.")
            return false
        }
        return true
    }

    private func checkAnnotationArgs(f: Function, anno: CustomAnnoInstance): Bool {
        let argValues = anno.argValues
        let packageName = argValues[0]
        if (!isValidPackageName(packageName)) {
            printError("Function '${f.srcCodeName}' has an invalid package name '${packageName}': expected a non-empty valid Cangjie package name with valid segments and no path separators (/, \\, ..).")
            return false
        }
        let className = argValues[1]
        let methodName = argValues[2]
        let isStatic = argValues[3]
        let isRecursive = argValues[4]
        if (f.isInstanceMemberMethod()) {
            if (className.isEmpty() || isStatic == "true") {
                printError("Instance member function '${f.srcCodeName}' cannot be woven into a global or static member function.")
                return false
            }
            if (f.packageName != packageName || getFuncOuterTypeName(f) != className) {
                printError("Instance method '${f.srcCodeName}' has an incompatible receiver type: got '${f.packageName}.${getFuncOuterTypeName(f)}', expected '${packageName}.${className}'.")
                return false
            }
        }
        if (className.isEmpty() && isRecursive == "true") {
            printError("Invalid annotation arguments for function '${f.srcCodeName}': 'recursive' is true while 'className' is empty.")
            return false
        }
        return true
    }

    private func checkInsertAnnoFuncType(f: Function, annoArgValues: Array<String>): Bool {
        let className = annoArgValues[1]
        let isStatic = Bool.parse(annoArgValues[3])
        let wovenFuncTypeStr = annoArgValues[5]
        if (f.funcType.returnType != UnitType.get()) {
            printError("Function '${f.srcCodeName}' annotated with @InsertAtEntry/@InsertAtExit has return type '${f.funcType.returnType.qualifiedName}', expected Unit.")
            return false
        }
        if (funcExplicitParamSize(f) == 0) {
            return true
        }
        var rightParenthesisIndex = wovenFuncTypeStr.lastIndexOf(")").getOrThrow()
        let funcType1 = wovenFuncTypeStr[0..rightParenthesisIndex + 1]  // remove return type
        var paramTypes = f.funcType.paramTypes
        if (f.isInstanceMemberMethod()) {
            (_, paramTypes) = paramTypes.splitAt(1)
        } else if (!className.isEmpty() && !isStatic) {
            let (thisParamTypes, explicitParamTypes) = paramTypes.splitAt(1)
            let thisParamType = thisParamTypes[0]
            if (let Some(c) <- (thisParamType as CustomType)) {
                if (c.def.srcCodeName != className) {
                    printError("Function '${f.srcCodeName}' annotated with @InsertAtEntry/@InsertAtExit has first parameter type '${thisParamType.qualifiedName}', expected a type named '${className}'.")
                    return false
                }
            } else {
                printError("Function '${f.srcCodeName}' annotated with @InsertAtEntry/@InsertAtExit has first parameter type '${thisParamType.qualifiedName}', expected a type named '${className}'.")
                return false
            }
            paramTypes = explicitParamTypes
        }
        let aspectFuncTypeStr = FuncType.get(paramTypes, UnitType.get()).qualifiedName
        rightParenthesisIndex = aspectFuncTypeStr.lastIndexOf(")").getOrThrow()
        let funcType2 = aspectFuncTypeStr[0..rightParenthesisIndex + 1]  // remove return type
        if (funcType1 != funcType2) {
            printError("Aspect function '${f.srcCodeName}' has parameter types '${funcType2}', expected '${funcType1}'.")
            return false
        }
        return true
    }

    private func checkReplaceBodyAnnoFuncType(f: Function, annoArgValues: Array<String>): Bool {
        let params = f.parameters
        if (params.isEmpty()) {
            printError("Function '${f.srcCodeName}' annotated with @ReplaceFuncBody has invalid parameter count: got 0, expected at least 1.")
            return false
        }
        let className = annoArgValues[1]
        let isStatic = Bool.parse(annoArgValues[3])
        if (!className.isEmpty() && !isStatic) {
            let packageName = annoArgValues[0]
            if (params[0].ty.qualifiedName != "${packageName}.${className}") {
                printError("Function '${f.srcCodeName}' annotated with @ReplaceFuncBody has first parameter type '${params[0].ty.qualifiedName}', expected '${packageName}.${className}'.")
                return false
            }
        }
        let lastParamType = params[params.size - 1].ty
        if (!lastParamType.isFuncType()) {
            printError("Function '${f.srcCodeName}' annotated with @ReplaceFuncBody has last parameter type '${lastParamType.qualifiedName}', expected a function type.")
            return false
        }
        let wovenFuncType = (lastParamType as FuncType).getOrThrow()
        if (wovenFuncType.returnType != f.funcType.returnType) {
            printError("Function '${f.srcCodeName}' annotated with @ReplaceFuncBody has return type '${f.funcType.returnType.qualifiedName}', expected '${wovenFuncType.returnType.qualifiedName}'.")
            return false
        }
        var (aspectParams, wovenFunc) = params.splitAt(params.size - 1)
        if (f.isInstanceMemberMethod()) {
            (_, aspectParams) = aspectParams.splitAt(1)
        }
        let aspectParamsType = mapArrayTo(aspectParams, {p => p.ty})
        if (aspectParamsType.isEmpty()) {
            return true
        }
        let aspectFuncTypeStr = FuncType.get(aspectParamsType, f.funcType.returnType).toString()
        let wovenFuncTypeStr = wovenFunc[0].ty.toString()
        if (aspectFuncTypeStr != wovenFuncTypeStr) {
            printError("Aspect function '${f.srcCodeName}' has function type '${aspectFuncTypeStr}', expected '${wovenFuncTypeStr}'.")
            return false
        }
        return true
    }

    private func isValidPackageName(name: String): Bool {
        if (name.isEmpty()) {
            return false
        }
        if (name.contains("/") || name.contains("\\") || name.contains("..")) {
            return false
        }
        let segments = name.split(".", removeEmpty: false)
        if (segments.isEmpty()) {
            return false
        }
        for (segment in segments) {
            if (!isValidPackageNameSegment(segment)) {
                return false
            }
        }
        return true
    }

    private func isValidPackageNameSegment(segment: String): Bool {
        if (segment.isEmpty()) {
            return false
        }
        var idx: Int64 = 0
        for (c in segment) {
            if (idx == 0) {
                if (!c.isAsciiLetter() && UInt32(c) != UInt32(r'_')) {
                    return false
                }
            } else if (!c.isAsciiNumberOrLetter() && UInt32(c) != UInt32(r'_') && UInt32(c) != UInt32(r'-')) {
                return false
            }
            idx += 1
        }
        return true
    }
}

private func getFuncOuterDeclaredOrExtendedDef(f: Function): ?CustomTypeDef {
    if (let Some(p) <- f.declaredParent) {
        if (let Some(ex) <- (p as ExtendDef)) {
            if (let Some(c) <- (ex.extendedType as CustomType)) {
                return c.def
            } else {
                return None
            }
        } else {
            return p
        }
    }
    return None
}

private func funcExplicitParamSize(f: Function): Int64 {
    var paramSize = f.parameters.size
    if (f.isInstanceMemberMethod()) {
        paramSize -= 1
    }
    return paramSize
}
