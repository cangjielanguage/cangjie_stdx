/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

import std.process.*
import std.io.*
import std.fs.*
import std.convert.*
import std.env.*

@When[os == "Windows"]
func getPythonCommand(): String {
    if (let Some(pyCommand) <- getPythonCommandFromEnv()){
        return pyCommand
 	}
    if(let Some(devecoPyCommand) <- getVariable("DEVECO_OH_NATIVE_HOME")){
        return devecoPyCommand + "/llvm/python3/bin/python3.11.exe"
    }
    throw Exception("Could not find 'python3' or 'python' in your system's PATH. Please ensure Python is installed and added to your environment variables!")
}

@When[os != "Windows"]
func getPythonCommand(): String {
    getPythonCommandFromEnv() ?? throw Exception(
        "Could not find 'python3' or 'python' in your system's PATH. Please ensure Python is installed and added to your environment variables!")
}

@When[os == "Windows"]
let isWin = true

@When[os != "Windows"]
let isWin = false

func getPythonCommandFromEnv(): ?String {
    let commands = ["python3", "python"];
    for (command in commands) {
        try {
            if (execute(command, "--version") == 0) {
                return command
            }
        } catch (_: Exception) {
            continue
        }
    }
    return None
}

func ensurePsutilInstalled(pyCommand: String): Unit {
    try {
        if (execute(pyCommand, "-c", "import psutil") != 0) {
            println("psutil library not found, installing...")
            if (isWin) {
                execute(pyCommand, "-m", "pip", "install", "psutil", "--timeout", "10", "--retries", "0")
            } else {
                execute("timeout", "-k", "0s", "15s", pyCommand, "-m", "pip", "install", "psutil", "--timeout", "10", "--retries", "0")
            }
            println("psutil installed successfully")
        }
    } catch (e: Exception) {}
}

func checkBuildTools(): Unit {
    // Check CMake
    var found = false
    try {
        if (execute("cmake", "--version") == 0) {
            found = true
        }
    } catch (_: Exception) {}
    if (!found) {
        throw Exception("Could not find 'cmake' in your system's PATH. Please ensure CMake is installed and added to your environment variables!")
    }
    found = false
    // Check Ninja
    try {
        if (execute("ninja", "--version") == 0) {
            found = true
        }
    } catch (_: Exception) {}
    if (!found) {
        throw Exception("Could not find 'ninja' in your system's PATH. Please ensure Ninja is installed and added to your environment variables!")
    }
    found = false
    
    // Check C/C++ compiler
    let ccCommands = ["gcc", "clang", "cc"]
    for (command in ccCommands) {
        try {
            if (execute(command, "--version") == 0) {
                found = true
                break
            }
        } catch (_: Exception) {
            continue
        }
    }
    if (!found) {
        throw Exception("Could not find C compiler (gcc/clang/cc) in your system's PATH. Please ensure a C compiler is installed!")
    }
}

main(): Int64 {
    // Check all required build tools first
    checkBuildTools()
    
    let pyCommand: String = getPythonCommand()
    match (getCommandLine()[1]) {
        case "pre-build" =>
            ensurePsutilInstalled(pyCommand)
            stagePreBuild(pyCommand)              
        case "post-build" => stagePostBuild(pyCommand)
        case "pre-clean" => stagePreClean(pyCommand)
        case _ => 0
    }
}

public func stagePreBuild(pyCommand: String): Int64 {
    let ret = execute(pyCommand, "cjpm_build.py", "build", "--build-stage", "preBuild")
    if (ret != 0) {
        return ret
    }
    // cjpm cmake skips chir/syntax targets, so flatc-generated CJ sources must be produced here
    // before cjpm compiles those packages (preBuild clean removes any stale copies).
    let genRet = generateFlatbuffersCjSources()
    if (genRet != 0) {
        return genRet
    }
    // Build a private, temporary flatbuffers static library from the compiler SDK sources.
    // Artifacts stay under build-script-cache/ (not target/), and are only consumed by
    // stdx.chir / stdx.syntax via bin-dependencies. Users must not depend on flatbuffers.
    return buildPrivateFlatbuffers()
}

public func stagePostBuild(pyCommand: String): Int64 {
    return execute(pyCommand, "cjpm_build.py", "build", "--build-stage", "postBuild")
}

public func stagePreClean(pyCommand: String): Int64 {
    // Drop the private flatbuffers cache along with other cjpm clean work.
    try {
        let cacheDir = Path("build-script-cache/flatbuffers-private")
        if (exists(cacheDir)) {
            remove(cacheDir)
        }
    } catch (_: Exception) {}
    return execute(pyCommand, "cjpm_build.py", "clean")
}

/**
 * Run flatc from the compiler SDK to emit StdxSyntaxFormat_generated.cj and
 * StdxChirFormat_generated.cj into the package source trees.
 */
func generateFlatbuffersCjSources(): Int64 {
    let home = getVariable("CANGJIE_HOME") ?? ""
    if (home.isEmpty()) {
        println("Error: CANGJIE_HOME is not set; cannot generate flatbuffers Cangjie sources.")
        return 1
    }
    let flatc = home + "/third_party/flatbuffers/bin/flatc"
    if (!exists(Path(flatc))) {
        println("Error: flatc not found: ${flatc}")
        return 1
    }

    // Local schema for stdx.syntax; chir schema is shipped with the compiler SDK.
    let jobs: Array<(String, String)> = [
        ("schema/StdxSyntaxFormat.fbs", "src/stdx/syntax"),
        (home + "/schema/StdxChirFormat.fbs", "src/stdx/chir")
    ]
    for ((schema, outDir) in jobs) {
        if (!exists(Path(schema))) {
            println("Error: flatbuffers schema not found: ${schema}")
            return 1
        }
        println("generating flatbuffers Cangjie sources from ${schema} ...")
        let code = execute(flatc, "--no-warnings", "--cangjie", "-o", outDir, schema)
        if (code != 0) {
            println("Error: flatc failed for ${schema} (exit ${code})")
            return code
        }
    }
    return 0
}

/**
 * Compiles $CANGJIE_HOME/third_party/flatbuffers/cangjie into
 * build-script-cache/flatbuffers-private/flatbuffers/{flatbuffers.cjo,libflatbuffers.a}.
 */
func buildPrivateFlatbuffers(): Int64 {
    let home = getVariable("CANGJIE_HOME") ?? ""
    if (home.isEmpty()) {
        println("Error: CANGJIE_HOME is not set; cannot build private flatbuffers library.")
        return 1
    }
    let srcDir = home + "/third_party/flatbuffers/cangjie"
    if (!exists(Path(srcDir))) {
        println("Error: flatbuffers sources not found: ${srcDir}")
        return 1
    }

    let outDir = "build-script-cache/flatbuffers-private/flatbuffers"
    let outLib = outDir + "/libflatbuffers.a"
    let outCjo = outDir + "/flatbuffers.cjo"

    try {
        Directory.create(Path(outDir), recursive: true)
    } catch (e: Exception) {
        println("Error: failed to create ${outDir}: ${e}")
        return 1
    }

    println("building private flatbuffers from ${srcDir} ...")
    let code = execute(
        "cjc",
        "--no-sub-pkg",
        "--output-type=staticlib",
        "-p",
        srcDir,
        "--output",
        outLib,
        "-O2")
    if (code != 0) {
        println("Error: failed to build private flatbuffers (cjc exit ${code})")
        return code
    }
    if (!exists(Path(outLib)) || !exists(Path(outCjo))) {
        println("Error: private flatbuffers artifacts missing under ${outDir}")
        return 1
    }
    println("private flatbuffers ready: ${outDir}")
    return 0
}
