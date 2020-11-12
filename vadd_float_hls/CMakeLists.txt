cmake_minimum_required(VERSION 3.1.5)

project(vadd_float_hls)
set (RTL_KERNELS vadd_float)
set (CPP_KERNELS reader writer)

if (NOT DEFINED VPP_TARGET)
    set (VPP_TARGET hw_emu)
endif()

if (NOT DEFINED HLSLIB_DIR)
    get_filename_component(PARENT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
    set(HLSLIB_DIR "${PARENT_DIR}/hlslib")
endif()

if (NOT DEFINED RTLLIB_DIR)
    get_filename_component(PARENT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
    set(RTLLIB_DIR "${PARENT_DIR}/rtllib")
endif()

include ("${RTLLIB_DIR}/cmake/CMakeLists.txt")
