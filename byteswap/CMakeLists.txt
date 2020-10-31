cmake_minimum_required(VERSION 3.1.5)
project(byteswap)

# Make sure hlslib is downloaded
find_package(git QUIET)
if (GIT_FOUND AND EXISTS "${PROJECT_SOURCE_DIR}/.git")
    option(GIT_SUBMODULE "Check submodules during build" ON)
    if (GIT_SUBMODULE)
        message(STATUS "Submodule update")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE GIT_SUBMOD_RESULT)

        if (NOT GITSUBMOD_RESULT EQUAL "0")
            message (FATAL_ERROR "git submodule --init failed with ${GIT_SUBMOD_RESULT}")
        endif()
    endif()
endif()

# TODO fix paths :)

#####
# Load hlslib
#####
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/../hlslib/cmake)
find_package(Vitis REQUIRED)
include_directories(${CMAKE_SOURCE_DIR}/../hlslib/include ${Vitis_INCLUDE_DIRS})

#####
# Load rtllib
#####
set(CONTROL_TEMPLATE "${CMAKE_SOURCE_DIR}/../utils/templates/control.py")
set(PACKAGE_TEMPLATE "${CMAKE_SOURCE_DIR}/../utils/templates/package.py")

#####
# Device section
#####
# Get source files for each kernel
add_custom_target(GENERATED_DIR ALL COMMAND ${CMAKE_COMMAND} -E make_directory generated)
add_custom_target(SCRIPTS_DIR ALL COMMAND ${CMAKE_COMMAND} -E make_directory scripts)
set (RTL_KERNELS byteswap)
set (VIVADO_FLAGS -mode batch -log vivado.log -journal vivado.jou)
foreach (RTL_KERNEL ${RTL_KERNELS})
    file (GLOB ${RTL_KERNEL}_SRC "${CMAKE_SOURCE_DIR}/src/hdl/${RTL_KERNEL}/*.*v")
    set(config "${CMAKE_SOURCE_DIR}/src/hdl/${RTL_KERNEL}/kernel.json")
    add_custom_command(
        OUTPUT  generated/${RTL_KERNEL}_Control.v
        COMMAND ${CONTROL_TEMPLATE} ${config} -o generated/${RTL_KERNEL}_Control.v -f
        DEPENDS ${CONTROL_TEMPLATE} ${config} ${GENERATED_DIR}
    )
    add_custom_command(
        OUTPUT  scripts/${RTL_KERNEL}_package.tcl
        COMMAND ${PACKAGE_TEMPLATE} ${config} -o scripts/${RTL_KERNEL}_package.tcl -f
        DEPENDS ${PACKAGE_TEMPLATE} ${config} ${SCRIPTS_DIR}
    )
    add_custom_command(
        OUTPUT  ${RTL_KERNEL}.xo
        COMMAND ${Vitis_VIVADO} ${VIVADO_FLAGS} -source scripts/${RTL_KERNEL}_package.tcl -tclargs obj/${RTL_KERNEL}.xo ${RTL_KERNEL} "tmp/pkg/" "${CMAKE_SOURCE_DIR}/src/hdl/${RTL_KERNEL}/" "${CMAKE_SOURCE_DIR}/../utils/rtl" "generated"
        DEPENDS scripts/${RTL_KERNEL}_package.tcl generated/${RTL_KERNEL}_Control.v ${RTL_KERNEL_SRC}
    )
endforeach()

#####
# Host section
#####
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -DHLSLIB_LEGACY_SDX=0")
set (HOST_SRC "${CMAKE_SOURCE_DIR}/src/host.cpp")
add_executable(${CMAKE_PROJECT_NAME} ${HOST_SRC} byteswap.xo)
target_link_libraries(${CMAKE_PROJECT_NAME} ${Vitis_LIBRARIES})
