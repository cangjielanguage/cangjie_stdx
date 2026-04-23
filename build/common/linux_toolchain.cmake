# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

set(CMAKE_SYSTEM_NAME Linux)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_VERBOSE_MAKEFILEON ON)
set(EXTRA_WARNING_SETTINGS "-Wsign-compare")
set(WARNINGS_SETTINGS "-Wall ${EXTRA_WARNING_SETTINGS} -Werror -Wdate-time")
set(C_OTHER_FLAGS "-fsigned-char")
set(CXX_OTHER_FLAGS "-Weffc++")

set(OTHER_FLAGS "-fno-omit-frame-pointer -pipe -fno-common -fno-strict-aliasing -fstack-protector-all")
set(GCOV_FLAGS "-fno-inline -O0 -fprofile-arcs -ftest-coverage")
set(ASAN_FLAGS "-fsanitize=address -fno-omit-frame-pointer")
set(TSAN_FLAGS "-fsanitize=thread")

set(LINK_FLAGS "-Wl,-z,relro,-z,now,-z,noexecstack")
set(STRIP_FLAG "-s")
set(SAFE_EXE_LINK_FLAG "-pie")

set(LINK_FLAGS_BUILD_ID "-Wl,--build-id=none")

set(EXTRA_C_FLAGS "-Wextra -Wno-implicit-function-declaration -Wno-unused-parameter -Wformat=2 -Wno-format-nonliteral -Wstrict-prototypes -Wframe-larger-than=100000 -Wvla -Wunused -Wnon-virtual-dtor -Wdelete-non-virtual-dtor -Woverloaded-virtual -Wconversion -Wno-shorten-64-to-32 -Wno-implicit-int-conversion -Wno-sign-conversion -Wno-string-conversion -Wfloat-equal")
set(C_FLAGS "${WARNINGS_SETTINGS} ${C_OTHER_FLAGS} ${OTHER_FLAGS} ${EXTRA_C_FLAGS} -std=gnu11 -Wshadow")
set(CPP_FLAGS "${WARNINGS_SETTINGS} ${CXX_OTHER_FLAGS} ${OTHER_FLAGS} ${EXTRA_C_FLAGS} -std=c++11 -Wswitch-default -Wcast-qual -Wcast-align -Wshadow")

set(CMAKE_C_FLAGS "${C_FLAGS}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g")
set(CMAKE_C_FLAGS_RELEASE "-D_FORTIFY_SOURCE=2 -O2")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g")
set(CMAKE_C_FLAGS_MINSIZEREL "-Os")
set(CMAKE_CXX_FLAGS "${CPP_FLAGS}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g")
set(CMAKE_CXX_FLAGS_RELEASE "-D_FORTIFY_SOURCE=2 -O2")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -fstandalone-debug")
set(CMAKE_CXX_FLAGS_MINSIZEREL "-Os")
if(CMAKE_BUILD_TYPE MATCHES Release)
    set(EXTRA_LINKER_FLAGS "-Wl,-Bsymbolic -rdynamic")
    set(CMAKE_EXE_LINKER_FLAGS "${LINK_FLAGS} ${LINK_FLAGS_BUILD_ID} ${STRIP_FLAG} ${EXTRA_LINKER_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS "${LINK_FLAGS} ${LINK_FLAGS_BUILD_ID} ${STRIP_FLAG} ${EXTRA_LINKER_FLAGS}")
else()
    set(CMAKE_EXE_LINKER_FLAGS "${LINK_FLAGS} ${LINK_FLAGS_BUILD_ID}")
endif()

set(LINKER_OPTION_PREFIX "-Wl,")
set(MAKE_SO_STACK_PROTECTOR_OPTION)
set(LLVM_BUILD_C_COMPILER ${CMAKE_C_COMPILER})
set(LLVM_BUILD_CXX_COMPILER ${CMAKE_CXX_COMPILER})

if(CANGJIE_TARGET_SYSROOT)
    set(CMAKE_SYSROOT ${CANGJIE_TARGET_SYSROOT})
endif()
