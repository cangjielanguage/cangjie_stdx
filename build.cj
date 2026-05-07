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
            execute(pyCommand, "-m", "pip", "install", "psutil")
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
    ensurePsutilInstalled(pyCommand)
    match (getCommandLine()[1]) {
        case "pre-build" => stagePreBuild(pyCommand)              
        case "post-build" => stagePostBuild(pyCommand)
        case "pre-clean" => stagePreClean(pyCommand)
        case _ => 0
    }
}

public func stagePreBuild(pyCommand: String): Int64 {
    return execute(pyCommand, "cjpm_build.py", "build", "--build-stage", "preBuild")
}

public func stagePostBuild(pyCommand: String): Int64 {
    return execute(pyCommand, "cjpm_build.py", "build", "--build-stage", "postBuild")
}

public func stagePreClean(pyCommand: String): Int64 {
    return execute(pyCommand, "cjpm_build.py", "clean")
}
