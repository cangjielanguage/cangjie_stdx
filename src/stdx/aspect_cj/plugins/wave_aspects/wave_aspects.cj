/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.aspect_cj.plugins.wave_aspects

import std.collection.*
import std.convert.*
import std.fs.*
import std.io.*
import stdx.aspect_cj.*
import stdx.chir.*
import stdx.plugin.*

@CHIRPlugin
public class WaveAspects {
    var processInfos = ArrayList<OutputInfo>()
    var pkgInitFuncMangledNames = HashMap<String, String>()

    public override func run(pkg: Package): Bool {
        if (!readAnnoInfo(pkg.name)) {
            return false
        }
        callUpstreamPkgInitFunc(pkg)
        for (f in pkg.functions) {
            if (f.body.isNone()) {
                continue
            }
            for (pi in processInfos) {
                if (!meets(f, pi)) {
                    continue
                }
                weaveFuncBody(pkg, f, pi)
            }
        }
        return true
    }

    private func weaveFuncBody(pkg: Package, f: Function, pi: OutputInfo): Unit {
        let (args, success) = prepareArguments(f, pi)
        if (!success) {
            return
        }
        let callee = getCallee(pkg, pi, f, args)
        let funcCallCxt = FuncCallContext(args, Array<Type>(), computeThisTypeOfCallee(callee, args))
        if (pi.annoClassName == "InsertAtEntry") {
            let builder = CHIRBuilder(InsertPosition.AtStart(f.body.getOrThrow().entryBlock))
            builder.createApply(callee, funcCallCxt)
        } else if (pi.annoClassName == "InsertAtExit") {
            let visitor = InsertAtExitVisitor(callee, funcCallCxt)
            visitor.walk(f.body.getOrThrow())
        } else if (pi.annoClassName == "ReplaceFuncBody") {
            let wrapperFunc = pkg.addFunction(f.funcType, f.identifierWithoutPrefix, f.srcCodeName, f.packageName)
            f.replaceWith(wrapperFunc)
            wrapperFunc.initBody()
            let builder = CHIRBuilder(wrapperFunc.body.getOrThrow().entryBlock)
            let allocate = builder.createAllocate(f.funcType.returnType)
            wrapperFunc.returnValue = allocate.result
            if (args.size != 1) {
                for (i in 0..wrapperFunc.parameters.size) {
                    funcCallCxt.setArg(i, wrapperFunc.parameters[i])
                }
            }
            let apply = builder.createApply(callee, funcCallCxt)
            builder.createStore(apply.result, allocate.result)
            builder.createExit()
            f.identifier = wrapperFunc.identifier + ".original"
        } else {
            printError("Unknown annotation class name: ${pi.annoClassName}")
        }
    }

    private func computeThisTypeOfCallee(callee: Function, args: Array<Value>): ?Type {
        if (callee.isMemberMethod()) {
            if (callee.isStatic()) {
                return callee.outerType
            }
            return args[0].ty
        }
        return None
    }

    private func getCallee(pkg: Package, pi: OutputInfo, f: Function, args: Array<Value>): Function {
        if (let Some(v) <- pkg.getSpecifiedFunction(pi.insert.methodMangledName)) {
            return v
        }
        let paramTypes = mapArrayTo(args, {arg => arg.ty})
        var returnType: Type = UnitType.get()
        if (pi.annoClassName.isReplaceBodyAnno()) {
            returnType = f.funcType.returnType
        }
        let funcType = FuncType.get(paramTypes, returnType)
        let callee = pkg.addFunction(funcType, pi.insert.methodMangledName, "", pi.insert.packageName)
        callee.setImported(true)
        return callee
    }

    private func printError(message: String): Unit {
        println(message)
    }

    private func prepareArguments(f: Function, pi: OutputInfo): (Array<Value>, Bool) {
        var expectedParamsNum = pi.insert.paramsNum
        if (pi.annoClassName.isReplaceBodyAnno()) {
            expectedParamsNum -= 1
        }
        let args = ArrayList<Value>()
        if (expectedParamsNum != 0) {
            if (f.parameters.size != expectedParamsNum) {
                printError("${f.srcCodeName} and ${pi.insert.methodMangledName} have unmatched number of parameters.")
                return (Array<Value>(), false)
            }
            for (param in f.parameters) {
                args.add(param)
            }
        }
        if (pi.annoClassName.isReplaceBodyAnno()) {
            args.add(f)
        }
        return (args.toArray(), true)
    }

    private func callUpstreamPkgInitFunc(pkg: Package): Unit {
        let curPkgInitFunc = pkg.packageInitFunc.getOrThrow()
        let bb = curPkgInitFunc.body.getOrThrow().entryBlock
        let builder = CHIRBuilder(InsertPosition.AtStart(bb))
        for ((pkgName, initFuncMangledName) in pkgInitFuncMangledNames) {
            if (pkgName == pkg.name) {
                continue
            }
            let funcType = FuncType.get(Array<Type>(), UnitType.get())
            let importedInitFunc = pkg.addFunction(funcType, initFuncMangledName, "", pkgName)
            importedInitFunc.setImported(true)
            let funcCallCxt = FuncCallContext(Array<Value>(), Array<Type>(), None)
            builder.createApply(importedInitFunc, funcCallCxt)
        }
    }

    private func meets(f: Function, pi: OutputInfo): Bool {
        if (pi.to.packageName != f.packageName) {
            return false
        }
        if (!outerTypeNameMeets(f, pi)) {
            return false
        }
        if (pi.to.methodName != f.srcCodeName) {
            return false
        }
        if (pi.to.isStatic != f.isStatic()) {
            return false
        }
        var params = f.parameters
        if (f.isInstanceMemberMethod()) {
            (_, params) = params.splitAt(1)
        }
        let paramTypes = mapArrayTo(params, {param => param.ty})
        let funcTypeStr = FuncType.get(paramTypes, f.funcType.returnType).qualifiedName
        if (pi.to.funcTypeStr != funcTypeStr) {
            return false
        }
        return true
    }

    private func outerTypeNameMeets(f: Function, pi: OutputInfo): Bool {
        if (getFuncOuterTypeName(f) == pi.to.className) {
            return true
        }
        if (let Some(outerType) <- f.outerType && pi.to.recursively) {
            let superTypes: Array<ClassLikeType>
            if (let Some(bt) <- (outerType as BuiltinType)) {
                superTypes = bt.getSuperTypesRecusively()
            } else if (let Some(ct) <- (outerType as CustomType)) {
                superTypes = ct.getSuperTypesRecusively()
            } else {
                return false
            }
            for (superType in superTypes) {
                if (superType.def.srcCodeName == pi.to.className) {
                    return true
                }
            }
        }
        return false
    }

    private func readAnnoInfo(curPkgName: String): Bool {
        Directory.walk(
            Path("."),
            {
                fileInfo =>
                let fileName = fileInfo.name
                let results = fileName.split(PACKAGE_NAME_CONNECTOR)
                if (results.size != 2) {
                    return true
                }
                if (results[1] != curPkgName + ANNO_INFO_FILE_SUFFIX) {
                    return true
                }
                try (f = File(Path(fileName), OpenMode.Read)) {
                    let reader = StringReader(f)
                    while (let Some(pkgName) <- reader.readln()) {
                        // Package init function mangled name
                        let initFuncMangledName = reader.readln().getOrThrow()
                        pkgInitFuncMangledNames.add(pkgName, initFuncMangledName)
                        // Anno class name
                        let annoClassName = reader.readln().getOrThrow()
                        // Insert
                        let inPackageName = reader.readln().getOrThrow()
                        let methodMangledName = reader.readln().getOrThrow()
                        let paramsNum = Int64.parse(reader.readln().getOrThrow())
                        let isMemberFunc = Bool.parse(reader.readln().getOrThrow())
                        let inIsStatic = Bool.parse(reader.readln().getOrThrow())
                        let insert = Insert(inPackageName, methodMangledName, paramsNum, isMemberFunc, inIsStatic)
                        // To
                        let toPackageName = reader.readln().getOrThrow()
                        let className = reader.readln().getOrThrow()
                        let methodName = reader.readln().getOrThrow()
                        let funcTypeStr = reader.readln().getOrThrow()
                        let toIsStatic = Bool.parse(reader.readln().getOrThrow())
                        let recursively = Bool.parse(reader.readln().getOrThrow())
                        let to = To(toPackageName, className, methodName, funcTypeStr, toIsStatic, recursively)
                        // OutputInfo
                        let processInfo = OutputInfo(annoClassName, insert, to)
                        processInfos.add(processInfo)
                    }
                } catch (_: Exception) {}
                return true
            }
        )
        return true
    }
}

extend String {
    internal func isInsertAnno(): Bool {
        return this == "InsertAtEntry" || this == "InsertAtExit"
    }
    internal func isReplaceBodyAnno(): Bool {
        return this == "ReplaceFuncBody"
    }
}

internal class InsertAtExitVisitor <: CHIRVisitor {
    let callee: Function
    let funcCallCxt: FuncCallContext
    public init(callee: Function, funcCallCxt: FuncCallContext) {
        this.callee = callee
        this.funcCallCxt = funcCallCxt
    }
    public override func action(e: Expression): IRActionMode {
        if (e.isLambda()) {
            return IRActionMode.Skip
        }
        if (e.isExit()) {
            let builder = CHIRBuilder(InsertPosition.Before(e))
            builder.createApply(callee, funcCallCxt)
        }
        return IRActionMode.Continue
    }
}