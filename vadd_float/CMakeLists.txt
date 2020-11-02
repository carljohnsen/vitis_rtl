cmake_minimum_required(VERSION 3.1.5)
project(vadd)
set (RTL_KERNELS vadd_float)
set (VPP_TARGet hw_emu)

get_filename_component(PARENT_DIR "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)
set(UTILS_DIR "${PARENT_DIR}/utils")
include ("${UTILS_DIR}/CMakeLists.txt")
