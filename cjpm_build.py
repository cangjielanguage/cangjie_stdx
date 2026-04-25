# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

# check python version must be before all other imports and code
if sys.version_info.major < 3:
    sys.stderr.write("error: current python version is {}.{}, please use python 3 or higher\n".format(
        sys.version_info.major, sys.version_info.minor))
    sys.exit(1)

import argparse
import logging
import multiprocessing
import glob
import os
import platform
import re
import shutil
import stat
import subprocess
from enum import Enum
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path
from subprocess import DEVNULL, PIPE

DEVECO_CUR_DIR = ""
BUILD_TARGET_DIR = ""
BUILD_TARGET = ""
DEVECO_OH_NATIVE_HOME = None
HAS_DEBUG_FLAG = False
BUILD_TYPE_CJPM = "release"
WMIC_PATH = "C:/Windows/System32/wbem/wmic.exe"
IS_MOCK = False

def get_platform():
    if sys.platform.startswith("linux"):
        return "linux"
    elif sys.platform.startswith("darwin"):
        return "macos"
    elif sys.platform.startswith("win"):
        return "windows"
    return "unknown"


def run_command(cmd):
    try:
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.PIPE)
        return output.decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return None


def get_cmdline_linux(pid):
    try:
        with open("/proc/{}/cmdline".format(pid), "rb") as f:
            # cmdline is null-separated
            data = f.read()
            # Split by null byte, filter empty strings if any
            return [
                x.decode("utf-8", errors="ignore") for x in data.split(b"\x00") if x
            ]
    except OSError:
        return []


def get_cmdline_macos(pid):
    # ps -p {pid} -ww -o args=
    out = run_command("ps -p {} -ww -o args=".format(pid))
    if out:
        import shlex

        return shlex.split(out)
    return []


def get_cmdline_windows(pid):
    cmd = "{} process where processid={} get CommandLine /value".format(WMIC_PATH, pid)
    out = run_command(cmd)
    if not out:
        return []
    for line in out.splitlines():
        if line.strip().startswith("CommandLine="):
            import shlex

            val = line.strip().split("=", 1)[1]
            # Windows command lines can be tricky. shlex might not be perfect for cmd/powershell but is better than space split.
            return val.split()
    return []


def extract_target_value(args):
    # Args is a list of strings
    for i, arg in enumerate(args):
        if arg == "--target":
            if i + 1 < len(args):
                return args[i + 1]
        elif arg.startswith("--target="):
            return arg.split("=", 1)[1]
    return None

def extract_target_dir_value(args):
    # Args is a list of strings
    for i, arg in enumerate(args):
        if arg == "--target-dir":
            if i + 1 < len(args):
                return args[i + 1]
        elif arg.startswith("--target-dir="):
            return arg.split("=", 1)[1]
    return None

def check_debug_flag(args):
    """
    Check if -g flag exists in command line arguments
    
    Args:
        args (list): Command line arguments list
        
    Returns:
        bool: True if -g flag is present, False otherwise
    """
    if not args:
        return False
    
    for arg in args:
        if arg.lower() == "-g":
            return True
    
    return False


def get_cwd_linux(pid):
    try:
        return os.readlink("/proc/{}/cwd".format(pid))
    except OSError:
        return None


def get_cwd_macos(pid):
    # -a: AND selection, -p: pid, -d: file descriptor, cwd, -F: format
    out = run_command("lsof -a -p {} -d cwd -F n".format(pid))
    if out:
        lines = out.splitlines()
        for line in lines:
            if line.startswith("n"):
                return line[1:]
    return "/tmp/stdx"


def get_cwd_windows(pid, debug=False):
    """
    Get the current working directory of a process on Windows.
    
    Args:
        pid (int): Process ID
        debug (bool): Debug flag
        
    Returns:
        str: Current working directory of the process or None if failed
    """
    # Try using psutil if available (most reliable)
    try:
        import psutil
        process = psutil.Process(pid)
        return process.cwd()
    except ImportError:
        return None
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        if debug:
            print(f"Failed to get cwd for pid {pid} using psutil")
        return None

def find_ancestor_and_cwd(target_name="cjpm"):
    global BUILD_TARGET
    global BUILD_TARGET_DIR
    global DEVECO_OH_NATIVE_HOME
    global DEVECO_CUR_DIR
    current_pid = os.getpid()
    plat = get_platform()
    win_cwd = None
    # We start checking from the current process logic (which covers self-renamed usage)
    # and then move up to parents.

    while True:
        ppid = None
        name = None

        if plat == "linux":
            try:
                with open("/proc/{}/stat".format(current_pid), "r") as f:
                    content = f.read()
                    # Parse assuming format: pid (name) state ppid ...
                    end_paren = content.rfind(")")
                    if end_paren == -1:
                        break

                    name = content[content.find("(") + 1 : end_paren]
                    rest = content[end_paren + 1 :].strip().split()
                    ppid = int(rest[1])  # state is rest[0], ppid is rest[1]
            except (IOError, ValueError, IndexError):
                break

        elif plat == "macos":
            ppid_str = run_command("ps -p {} -o ppid=".format(current_pid))
            name_str = run_command("ps -p {} -o comm=".format(current_pid))
            if ppid_str:
                ppid = int(ppid_str.strip())
            if name_str:
                name = os.path.basename(name_str.strip())

        elif plat == "windows":
            cmd = "{} process where processid={} get ParentProcessId,Name,ExecutablePath /value".format(WMIC_PATH, current_pid)
            out = run_command(cmd)
            if out:
                info = {}
                for line in out.splitlines():
                    if "=" in line:
                        k, v = line.strip().split("=", 1)
                        info[k] = v
                if "ParentProcessId" in info:
                    ppid = int(info["ParentProcessId"])
                if "Name" in info:
                    name = info["Name"]
                # Try to get working directory using our new function
                temp_cwd = get_cwd_windows(current_pid)
                if temp_cwd:
                    win_cwd = temp_cwd
                # Fallback to the original logic if needed
                elif "ExecutablePath" in info and "build-script" in info["ExecutablePath"]:
                    win_cwd = info["ExecutablePath"].split("build-script-cache")[0]
                    print("Using fallback cwd from executable path: " + win_cwd)
                if DEVECO_OH_NATIVE_HOME != "" and win_cwd:
                    DEVECO_CUR_DIR = win_cwd
                    print("DEVECO_CUR_DIR:", DEVECO_CUR_DIR)

        if not ppid or not name:
            break

        # Check match
        if target_name.lower() in name.lower():
            # Found match
            cwd = None
            if plat == "linux":
                cwd = get_cwd_linux(current_pid)
            elif plat == "macos":
                cwd = get_cwd_macos(current_pid)
            elif plat == "windows":
                cwd = win_cwd

            cmdline = []
            if plat == "linux":
                cmdline = get_cmdline_linux(current_pid)
            elif plat == "macos":
                cmdline = get_cmdline_macos(current_pid)
            elif plat == "windows":
                cmdline = get_cmdline_windows(current_pid)

            target_val = extract_target_value(cmdline)
            BUILD_TARGET = target_val
            target_dir_val = extract_target_dir_value(cmdline)
            BUILD_TARGET_DIR = target_dir_val

            global HAS_DEBUG_FLAG
            global BUILD_TYPE_CJPM
            global IS_MOCK
            HAS_DEBUG_FLAG = check_debug_flag(cmdline)
            if "--mock" in cmdline:
                IS_MOCK = True
            if(HAS_DEBUG_FLAG):
                BUILD_TYPE_CJPM = "debug"
            else:
                BUILD_TYPE_CJPM = "release"
            if cwd:
                return cwd
            else:
                return None

        # Stop if we hit init or deadlock
        if ppid == 0 or ppid == current_pid:
            break
        current_pid = ppid

    return None


CJPM_DIR = find_ancestor_and_cwd("cjpm")

STDX_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_DIR = os.path.join(STDX_DIR, "build_temp")
SYNTAX_DIR = os.path.join(STDX_DIR, "src/stdx/syntax")
FUZZ_DIR = os.path.join(STDX_DIR, "src/stdx/fuzz")
ASPECTCJ_DIR = os.path.join(STDX_DIR, "src/stdx/aspectCJ")
CMAKE_BUILD_DIR = os.path.join(BUILD_DIR, "build")
CMAKE_OUTPUT_DIR = os.path.join(CJPM_DIR, "target/" + BUILD_TYPE_CJPM)
LOG_DIR = os.path.join(BUILD_DIR, "logs")
LOG_FILE = os.path.join(LOG_DIR, "cangjie.log")

IS_WINDOWS = get_platform() == "windows"
IS_MACOS = get_platform() == "macos"
IS_ARM = platform.uname().processor in ["arm","aarch64","arm64"]
# Wait for the version of aarch64 libcore to be ready.
MAKE_JOBS = multiprocessing.cpu_count() + 2

TARGET_DICTIONARY = {
    "native": None,
    "ohos-aarch64": "aarch64-linux-ohos",
    "ohos-arm": "arm-linux-ohos",
    "ohos-x86_64": "x86_64-linux-ohos",
    "windows-x86_64": "x86_64-w64-mingw32",
    "ios-simulator-aarch64": "arm64-apple-ios11-simulator",
    "ios-simulator-x86_64": "x86_64-apple-ios11-simulator",
    "ios-aarch64": "arm64-apple-ios11",
    "android-aarch64": "aarch64-linux-android",
    "android31-aarch64": "aarch64-linux-android31",
    "android26-aarch64": "aarch64-linux-android26",
    "android-x86_64": "x86_64-linux-android",
    "android31-x86_64": "x86_64-linux-android31",
    "android26-x86_64": "x86_64-linux-android26"
}

def resolve_path(path):
    if os.path.isabs(path):
        return path
    return os.path.abspath(path)


def log_output(output, checker=None, args=[]):
    """log command output"""
    while True:
        line = output.stdout.readline()
        if not line:
            output.communicate()
            returncode = output.returncode
            if returncode != 0:
                LOG.error("build error: %d!\n", returncode)
                sys.exit(1)
            break
        try:
            LOG.info(line.decode("ascii", "ignore").rstrip())
        except UnicodeEncodeError:
            LOG.info(line.decode("utf-8", "ignore").rstrip())


def init_log(name):
    """init log config"""
    if not os.path.exists(LOG_DIR):
        os.makedirs(LOG_DIR)

    log = logging.getLogger(name)
    log.setLevel(logging.DEBUG)
    formatter = logging.Formatter(
        "[%(asctime)s] [%(module)s] [%(levelname)s] %(message)s", "%Y-%m-%d %H:%M:%S"
    )
    streamhandler = logging.StreamHandler(sys.stdout)
    streamhandler.setLevel(logging.DEBUG)
    streamhandler.setFormatter(formatter)
    log.addHandler(streamhandler)
    filehandler = TimedRotatingFileHandler(
        LOG_FILE, when="W6", interval=1, backupCount=60
    )
    filehandler.setLevel(logging.DEBUG)
    filehandler.setFormatter(formatter)
    log.addHandler(filehandler)
    return log


class BuildType(Enum):
    """CMAKE_BUILD_TYPE options"""

    debug = "Debug"
    release = "Release"
    relwithdebinfo = "RelWithDebInfo"

    def __str__(self):
        return self.name

    def __repr__(self):
        return str(self)

    @staticmethod
    def argparse(s):
        try:
            return BuildType[s]
        except KeyError:
            return s.build_type


class BuildStage(Enum):

    preBuild = "preBuild"
    postBuild = "postBuild"

    def __str__(self):
        return self.name

    def __repr__(self):
        return str(self)

    @staticmethod
    def argparse(s):
        try:
            return BuildStage[s]
        except KeyError:
            return s.build_stage


def generate_cmake_defs(args):
    """convert args to cmake defs"""

    def bool_to_opt(value):
        return "ON" if value else "OFF"

    if args.target:
        if args.target == "aarch64-linux-ohos":
            toolchain_file = "ohos_aarch64_clang_toolchain.cmake"
        elif args.target == "x86_64-linux-ohos":
            toolchain_file = "ohos_x86_64_clang_toolchain.cmake"
        elif args.target == "x86_64-w64-mingw32":
            toolchain_file = "mingw_x86_64_toolchain.cmake"
        elif "aarch64-linux-android" in args.target:
            toolchain_file = "android_aarch64_toolchain.cmake"
        elif "x86_64-linux-android" in args.target:
            toolchain_file = "android_x86_64_toolchain.cmake"
        elif args.target == "arm64-apple-ios11-simulator":
            toolchain_file = "ios_simulator_arm64_toolchain.cmake"
        elif args.target == "arm64-apple-ios11":
            toolchain_file = "ios_arm64_toolchain.cmake"
    else:
        args.target = None
        if IS_WINDOWS:
            toolchain_file = "mingw_x86_64_toolchain.cmake"
        elif IS_MACOS:
            toolchain_file = (
                "darwin_aarch64_toolchain.cmake"
                if IS_ARM
                else "darwin_x86_64_toolchain.cmake"
            )
        elif IS_ARM:
            toolchain_file = "linux_aarch64_toolchain.cmake"
        else:
            toolchain_file = "linux_x86_64_toolchain.cmake"

    if args.target:
        fields = args.target.split("-")
    global IS_MOCK
    target_dir = "target"
    if IS_MOCK:
        target_dir = "target/mock"
    if CJPM_DIR == STDX_DIR:
        install_prefix = os.path.join(CJPM_DIR, target_dir)
    else:
        install_prefix = os.path.join(CJPM_DIR, target_dir + "/" + BUILD_TYPE_CJPM)
    result = [
        "-DCMAKE_BUILD_TYPE=" + args.build_type.value,
        "-DCMAKE_IS_MOCK=" + bool_to_opt(IS_MOCK),
        "-DCMAKE_BUILD_STAGE=" + args.build_stage.value,
        "-DCMAKE_TOOLCHAIN_FILE=../../build/common/" + toolchain_file,
        "-DCMAKE_INSTALL_PREFIX=" + install_prefix,
        "-DCANGJIE_TARGET_LIB=" + (";".join(args.target_lib) if args.target_lib else ""),
        "-DCANGJIE_TARGET_TOOLCHAIN=" + (args.target_toolchain if args.target_toolchain else ""),
        "-DCANGJIE_INCLUDE=" + (";".join(args.include) if args.include else ""),
        "-DCANGJIE_CJPM_DIR=" + (CJPM_DIR.replace("\\", "/") if IS_WINDOWS else CJPM_DIR),
        "-DCANGJIE_CJPM_BUILD_SELF=" + ("ON" if CJPM_DIR == STDX_DIR else "OFF"),
        "-DCANGJIE_CJPM_BUILD_TYPE=True",
        "-DCANGJIE_TARGET_SYSROOT=" + (args.target_sysroot if args.target_sysroot else ""),
        "-DCANGJIE_BUILD_WITHOUT_EFFECT_HANDLERS=" + bool_to_opt(args.without_effect_handlers),
        "-DCANGJIE_BUILD_STDLIB_WITH_COVERAGE=" + bool_to_opt(args.stdlib_coverage),
        "-DCANGJIE_BUILD_ARGS=" + (";".join(args.build_args) if args.build_args else "")]
    if args.target and "aarch64-linux-android" in args.target:
        android_api_level = re.match(r'aarch64-linux-android(\d{2})?', args.target).group(1)
        result.append("-DCMAKE_ANDROID_NDK=" + os.path.join(args.target_toolchain, "../../../../.."))
        result.append("-DCMAKE_ANDROID_API=" + (android_api_level if android_api_level else ""))
    if args.target and "x86_64-linux-android" in args.target:
        android_api_level = re.match(r'x86_64-linux-android(\d{2})?', args.target).group(1)
        result.append("-DCMAKE_ANDROID_NDK=" + os.path.join(args.target_toolchain, "../../../../.."))
        result.append("-DCMAKE_ANDROID_API=" + (android_api_level if android_api_level else ""))
    return result

def run_cmake_and_build(args):
    check_compiler(args)
    generator = "Ninja"
    build_cmd = ["ninja"]
    if args.jobs > 0:
        build_cmd.extend(["-j", str(args.jobs)])

    cmake_command = (
        ["cmake", STDX_DIR, "-G", generator] + generate_cmake_defs(args)
    )

    if not os.path.exists(BUILD_DIR):
        os.makedirs(BUILD_DIR)

    cmake_build_dir = (
        os.path.join(BUILD_DIR, "build-libs-{}".format(args.target))
        if args.target
        else CMAKE_BUILD_DIR
    )
    LOG.info("cmake_build_dir: " + cmake_build_dir)
    if not os.path.exists(cmake_build_dir):
        os.makedirs(cmake_build_dir)

    output = subprocess.Popen(cmake_command, cwd=cmake_build_dir, stdout=PIPE)
    log_output(output)

    output = subprocess.Popen(build_cmd, cwd=cmake_build_dir, stdout=PIPE)
    log_output(output)

    if output.returncode != 0:
        LOG.fatal("build failed")

    LOG.info("end build")

    install(args)


def build(args):
    global CJPM_DIR
    global IS_MOCK
    global DEVECO_OH_NATIVE_HOME
    
    if not HAS_DEBUG_FLAG:
        args.build_type = BuildType.release
    else:
        args.build_type = BuildType.debug
    
    LOG.info("args: " + str(args))
    LOG.info("CJPM_DIR: " + CJPM_DIR)
    LOG.info("args.build_stage: " + str(args.build_stage))
    DEVECO_OH_NATIVE_HOME = os.environ.get("DEVECO_OH_NATIVE_HOME", "")
    LOG.info("DEVECO_OH_NATIVE_HOME: " + str(DEVECO_OH_NATIVE_HOME))
    if args.build_stage.value == "preBuild":
        clean(args)
        cleanLibs()
    
    if DEVECO_OH_NATIVE_HOME:
        if IS_WINDOWS:
            DEVECO_OH_NATIVE_HOME = DEVECO_OH_NATIVE_HOME.replace("\\", "/")
        cmake_path = os.path.join(
            DEVECO_OH_NATIVE_HOME, "build-tools", "cmake", "bin"
        )
        custom_paths = [cmake_path]

        current_path = os.environ.get("PATH", "")

        if custom_paths:
            new_paths = os.pathsep.join(custom_paths)
            if current_path:
                os.environ["PATH"] = new_paths + os.pathsep + current_path
            else:
                os.environ["PATH"] = new_paths

    if args.target:
        args.target = TARGET_DICTIONARY[args.target]
    if BUILD_TARGET and (
        BUILD_TARGET == "aarch64-linux-ohos" or BUILD_TARGET == "x86_64-linux-ohos"
    ):
        if args.build_stage.value == "preBuild" and not DEVECO_OH_NATIVE_HOME:
            LOG.info("begin build native stdx")
            run_cmake_and_build(args)
            LOG.info("end build native stdx")
        args.target = BUILD_TARGET
        if DEVECO_OH_NATIVE_HOME:
            args.target_toolchain = DEVECO_OH_NATIVE_HOME + "/llvm/bin"
            args.target_sysroot = DEVECO_OH_NATIVE_HOME + "/sysroot"
        else:
            args.target_toolchain = os.environ.get("OHOS_TOOLCHAIN_PATH", "")
            args.target_sysroot = os.environ.get("OHOS_SYSROOT_PATH", "")
    
    LOG.info("begin build py----")
    if args.build_stage.value == "postBuild":
        target_dir = "target"
        if IS_MOCK:
            target_dir = "target/mock"
        if not IS_WINDOWS:
            if CJPM_DIR != STDX_DIR:
                return 0
            parts = [CJPM_DIR, target_dir, args.target, BUILD_TYPE_CJPM, "stdx"]
            target_dir = os.path.join(*(p for p in parts if p is not None))
            if not extract_libstdx(target_dir, args):
                LOG.info("skip to extract libstdx")
                return 0
        else:
            parts = [STDX_DIR, target_dir, args.target, BUILD_TYPE_CJPM, "stdx"]
            target_dir = os.path.join(*(p for p in parts if p is not None))
            if not extract_libstdx(target_dir, args):
                LOG.info("skip to extract libstdx")
                return 0
            CJPM_DIR = STDX_DIR
    
    run_cmake_and_build(args)

def extract_libstdx(directory, args):
    """
    Extract libstdx*.a files
    
    Args:
        directory (str): Target directory path
        
    Returns:
        bool: True if extraction succeeded, False otherwise
    """
    dir_path = Path(directory).resolve()

    if not dir_path.is_dir():
        LOG.error("Error: Directory does not exist: " + str(dir_path))
        return False

    pattern = str(dir_path / "libstdx*.a")
    libraries = glob.glob(pattern)

    if not libraries:
        LOG.warning("Warning: No libstdx*.a files were found in directory '" + str(dir_path) + "'")
        return False

    LOG.info("Start processing directory: " + str(dir_path))
    extracted_any = False

    for lib_path in libraries:
        lib_path = Path(lib_path)
        if not lib_path.is_file():
            continue

        LOG.info("Unpacking: " + lib_path.name + "-" + str(dir_path) + "/")

        try:
            ar = "ar"
            if args.target and (
                args.target == "aarch64-linux-ohos"
                or args.target == "x86_64-linux-ohos"
            ):
                ar = os.path.join(args.target_toolchain, "llvm-ar")
            result = subprocess.run(
                [ar, "x", lib_path.name],
                cwd=dir_path,
                check=True,
                capture_output=True,
                text=True,
            )
            extracted_any = True

            for obj_file in dir_path.glob("stdx.*.o"):
                if obj_file.name == "stdx.o":
                    continue
                new_name = obj_file.name.replace("stdx.", "", 1)
                new_path = obj_file.parent / new_name
                if new_path.exists():
                    LOG.info("Skip renaming (target already exists): " + obj_file.name + " - " + new_name)
                else:
                    obj_file.rename(new_path)
                    LOG.info(" rename: " + obj_file.name + " - " + new_name)

        except subprocess.CalledProcessError as e:
            LOG.error("Unpacking failed: " + lib_path.name + "\n  error: " + e.stderr.strip())
        except Exception as e:
            LOG.error("Processing failed: " + lib_path.name + "\n  error: " + str(e))

    if extracted_any:
        LOG.info("All libraries have been successfully unpacked")
    else:
        LOG.info("No files were successfully unpacked.")
    return extracted_any

def main():
    parser = argparse.ArgumentParser(description="build stdx project")
    subparsers = parser.add_subparsers(help="sub command help", required=True)
    build_parser = subparsers.add_parser("build", help="build_parser")
    build_parser.add_argument(
        "-t",
        "--build-type",
        type=BuildType.argparse,
        dest="build_type",
        choices=list(BuildType),
        help="select target build type",
    )
    build_parser.add_argument(
        "--build-stage",
        type=BuildStage.argparse,
        dest="build_stage",
        choices=list(BuildStage),
        required=True,
        help="select cjpm build stage",
    )
    build_parser.add_argument(
        "--jobs",
        dest="jobs",
        type=int,
        default=0,
        help="run N jobs in parallel (0 means default)",
    )
    build_parser.add_argument(
        "--target",
        dest="target",
        type=str,
        choices=TARGET_DICTIONARY.keys(),
        help="build a second stdxlib for the target triple specified",
    )
    build_parser.add_argument(
        "--target-lib",
        "-L",
        dest="target_lib",
        type=str,
        action="append",
        default=[],
        help="link libraries under this path for all products",
    )
    build_parser.add_argument(
        "--target-toolchain",
        dest="target_toolchain",
        type=str,
        help="use the tools under the given path to cross-compile stdxlib",
    )
    build_parser.add_argument(
        "--include",
        "-I",
        dest="include",
        type=str,
        action="append",
        default=[],
        help="search header files in given paths",
    )
    build_parser.add_argument(
        "--target-sysroot",
        dest="target_sysroot",
        type=str,
        help="pass this argument to C/CXX compiler as --sysroot",
    )
    build_parser.add_argument(
        "--stdlib-coverage", action="store_true", help="build stdlib with coverage"
    )
    build_parser.add_argument("--cjpm", action="store_true", help="build stdx by cjpm")
    build_parser.add_argument(
        "--build-args",
        dest="build_args",
        type=str,
        action="append",
        default=[],
        help="other arguments directly passed to cjc",
    )
    build_parser.add_argument(
        "--without-effect-handlers",
        dest="without_effect_handlers",
        action="store_true",
        help="build a version without effect handlers",
    )
    build_parser.add_argument(
        "--host",
        dest="host",
        type=str,
        choices=TARGET_DICTIONARY.keys(),
        help="Generate installation package for the host",
    )
    build_parser.add_argument("--prefix", dest="prefix", help="target install prefix")
    build_parser.set_defaults(func=build)

    clean_parser = subparsers.add_parser("clean", help="clean build")
    clean_parser.set_defaults(func=clean)

    args = parser.parse_args()
    args.func(args)


def check_compiler(args):
    # If user didn't specify --target-toolchain, we search for an available compiler in $PATH.
    # If user did specify --target-toolchain, we search in user given path ONLY. By doing so
    # user could see a 'compiler not found' error if the given path is incorrect.
    toolchain_path = args.target_toolchain if args.target_toolchain else None
    if toolchain_path and (not os.path.exists(toolchain_path)):
        LOG.error("the given toolchain path does not exist, {}".format(toolchain_path))
    # The gcc with the MinGW triple prefix is used for Windows native compiling.
    if IS_WINDOWS and args.target is None:
        c_compiler = shutil.which("x86_64-w64-mingw32-gcc.exe", path=toolchain_path)
        cxx_compiler = shutil.which("x86_64-w64-mingw32-g++.exe", path=toolchain_path)
    else:  # On other platform, clang is always the first choice.
        c_compiler = shutil.which("clang", path=toolchain_path)
        cxx_compiler = shutil.which("clang++", path=toolchain_path)
    # If clang is not available and we are cross compiling, we check for gcc cross compiler.
    if (c_compiler == None or cxx_compiler == None) and args.target:
        c_compiler = shutil.which(args.target + "-gcc", path=toolchain_path)
        cxx_compiler = shutil.which(args.target + "-g++", path=toolchain_path)
    # If none of above is available, we search for generic gcc compiler.

    if c_compiler == None or cxx_compiler == None:
        c_compiler = shutil.which("gcc", path=toolchain_path)
        cxx_compiler = shutil.which("g++", path=toolchain_path)

    if c_compiler == None or cxx_compiler == None:
        if toolchain_path:
            LOG.error("cannot find available compiler in the given toolchain path")
        else:
            LOG.error("cannot find available compiler in $PATH")
        LOG.error("clang/clang++ or gcc/g++ is required to build cangjie compiler")
    if c_compiler:
        os.environ["CC"] = c_compiler
    else:
        LOG.error("cannot find available c_compiler in $PATH")

    if cxx_compiler:
        os.environ["CXX"] = cxx_compiler
    else:
        LOG.error("cannot find available cxx_compiler in $PATH")

def install(args):
    """install targets"""
    LOG.info("begin install targets...")

    global CJPM_DIR
    global DEVECO_CUR_DIR
    global BUILD_TARGET_DIR
    global BUILD_TYPE_CJPM

    if args.host:
        args.host = TARGET_DICTIONARY[args.host]

    targets = []

    # - If "build.py install" is invoked without "--host",
    #   the native build directories and all cross-compiled libs
    #   will be installed to the "output" directory.
    # - If "build.py install" is invoked with "--host <triple>",
    #   the build-cjc-<triple> directories and all cross-compiled libs
    #   will be installed to a seperated "output-<target>" directory.

    # Searching for cjc's build directory.
    if not args.host:
        if os.path.exists(CMAKE_BUILD_DIR):
            targets.append(("native", CMAKE_BUILD_DIR))
    else:
        suffix = "cjc-{}".format(args.host)
        cross_build_path = os.path.join(BUILD_DIR, "build-{}".format(suffix))
        if os.path.exists(cross_build_path):
            targets.append((suffix, cross_build_path))

    # Searching for all libs' build directories.
    for directory in os.listdir(BUILD_DIR):
        build_prefix = "build-libs-"
        if directory.startswith(build_prefix):
            targets.append(
                (
                    "libs-{}".format(directory[len(build_prefix) :]),
                    os.path.join(BUILD_DIR, directory),
                )
            )

    if len(targets) == 0:
        LOG.fatal("Nothing is built yet.")
        sys.exit(1)

    # Install for all build directories in the list
    for target in targets:
        LOG.info("installing {} build...".format(target[0]))
        cmake_cmd = ["cmake", "--install", "."]
        if args.prefix:
            cmake_cmd += ["--prefix", os.path.abspath(args.prefix)]
        elif args.host:
            cmake_cmd += [
                "--prefix",
                os.path.join(STDX_DIR, "output-{}".format(args.host)),
            ]
        LOG.info(target[1])
        output = subprocess.Popen(cmake_cmd, cwd=target[1], stdout=PIPE)
        log_output(output)
        if output.returncode != 0:
            LOG.fatal("install {} build failed".format(target[0]))
            sys.exit(1)

    if args.host == "x86_64-w64-mingw32":
        mingw_bin_path = os.path.join(
            STDX_DIR, "output-x86_64-w64-mingw32/third_party/mingw/bin"
        )
        if os.path.exists(mingw_bin_path):
            for bin in os.listdir(mingw_bin_path):
                bin_path = os.path.join(mingw_bin_path, bin)
                if os.path.isfile(bin_path) and not bin.endswith(".exe"):
                    os.remove(bin_path)
    LOG.info("end install targets...")

    if type(DEVECO_CUR_DIR) == str and DEVECO_CUR_DIR != "" and type(BUILD_TARGET_DIR) == str and BUILD_TARGET_DIR != "":
        src_dir = os.path.join(CJPM_DIR, "target/" + BUILD_TYPE_CJPM + "/stdx")
        dst_dir = os.path.join(DEVECO_CUR_DIR, BUILD_TARGET_DIR + "/aarch64-linux-ohos/release/stdx")
        if not os.path.exists(dst_dir):
            os.makedirs(dst_dir)
        shutil.copytree(src_dir, dst_dir, dirs_exist_ok=True)

def redo_with_write(redo_func, path, err):

    # Is the error an access error?
    if not os.access(path, os.W_OK):
        os.chmod(path, stat.S_IWUSR)
        redo_func(path)
    else:
        raise


def clean(args):
    """clean build outputs and logs"""
    LOG.info("begin clean...\n")
    handlerToBeRemoved = []
    for handler in LOG.handlers:
        if isinstance(handler, logging.FileHandler):
            handler.close()
            handlerToBeRemoved.append(handler)
    for handler in handlerToBeRemoved:
        LOG.removeHandler(handler)
    output_dirs = []
    # Remove entire build directory by default
    output_dirs.append(BUILD_DIR)
    for file_path in output_dirs:
        abs_file_path = os.path.join(STDX_DIR, file_path)
        if os.path.isdir(abs_file_path):
            # If some build files are read-only and not allowed to be deleted (especially in Windows),
            # Try to deal with the error by giving write permissions and deleting them again.
            shutil.rmtree(abs_file_path, ignore_errors=False, onerror=redo_with_write)
        if os.path.isfile(abs_file_path):
            os.remove(abs_file_path)
    LOG.info("end clean\n")


def cleanLibs():
    LOG.info("begin clean libs...\n")
    output_dirs = []
    output_dirs.append(ASPECTCJ_DIR)
    output_dirs.append(SYNTAX_DIR)
    if IS_WINDOWS and not DEVECO_OH_NATIVE_HOME:
        output_dirs.append(FUZZ_DIR)
    for file_path in output_dirs:
        abs_file_path = os.path.join(STDX_DIR, file_path)
        if os.path.isdir(abs_file_path):
            shutil.rmtree(abs_file_path, ignore_errors=False, onerror=redo_with_write)
        if os.path.isfile(abs_file_path):
            os.remove(abs_file_path)
    LOG.info("end clean libs\n")


if __name__ == "__main__":
    LOG = init_log("root")
    os.environ["LANG"] = "C.UTF-8"
    main()