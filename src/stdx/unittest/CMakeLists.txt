# Copyright (c) Huawei Technologies Co., Ltd. 2025. All rights reserved.
#
# This source file is part of the Cangjie project, licensed under Apache-2.0
# with Runtime Library Exception.
#
# See https://cangjie-lang.cn/pages/LICENSE for license information.

if(NOT CANGJIE_BUILD_WITHOUT_UNITTEST_CONCURRENT)
    add_subdirectory(concurrent)
    add_subdirectory(sync)
endif()
add_subdirectory(data)