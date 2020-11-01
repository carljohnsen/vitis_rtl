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
set(HLSLIB_DIR "${CMAKE_SOURCE_DIR}/../hlslib")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${HLSLIB_DIR}/cmake)
find_package(Vitis REQUIRED)
include_directories(${HLSLIB_DIR}/include ${Vitis_INCLUDE_DIRS})

#####
# Load rtllib
#####
set(UTILS_DIR "${CMAKE_SOURCE_DIR}/../utils")
set(TEMPLATES_DIR "${UTILS_DIR}/templates")
set(CONTROL_TEMPLATE "${TEMPLATES_DIR}/control.py")
set(PACKAGE_TEMPLATE "${TEMPLATES_DIR}/package.py")
set(RTLLIB_DIR "${UTILS_DIR}/rtl")

#####
# Device section
#####
set (LOG_DIR "${CMAKE_BINARY_DIR}/log")
set (REPORT_DIR "${CMAKE_BINARY_DIR}/reports")

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/scripts")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/obj")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/log")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/reports")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set (RTL_KERNELS byteswap)
set (VIVADO_FLAGS -mode batch -log ${LOG_DIR}/vivado.log -journal ${LOG_DIR}/vivado.jou)
set (HDL_DIR "${CMAKE_SOURCE_DIR}/src/hdl")
set (RTLLIB_DIR "${UTILS_DIR}/rtl")
foreach (RTL_KERNEL ${RTL_KERNELS})
    set (KERNEL_DIR "${HDL_DIR}/${RTL_KERNEL}")
    file(GLOB SRCS "${KERNEL_DIR}/*.*v")
    set (CFG "${KERNEL_DIR}/kernel.json")
    set (CTRL "generated/${RTL_KERNEL}_Control.v")
    add_custom_command(
        OUTPUT  ${CTRL}
        COMMAND ${CONTROL_TEMPLATE} ${CFG} -o ${CTRL} -f
        DEPENDS ${CONTROL_TEMPLATE} ${CFG} #${GENERATED_DIR}
    )
    set (PKG "scripts/${RTL_KERNEL}_package.tcl")
    add_custom_command(
        OUTPUT  ${PKG}
        COMMAND ${PACKAGE_TEMPLATE} ${CFG} -o ${PKG} -f
        DEPENDS ${PACKAGE_TEMPLATE} ${CFG} #${SCRIPTS_DIR}
    )
    set (XO "obj/${RTL_KERNEL}.xo")
    add_custom_command(
        OUTPUT  ${XO}
        COMMAND ${Vitis_VIVADO} ${VIVADO_FLAGS} -source ${PKG} -tclargs ${XO} ${RTL_KERNEL} "tmp/vivado/${RTL_KERNEL}/" ${KERNEL_DIR} ${RTLLIB_DIR} generated
        DEPENDS ${CTRL} ${PKG} ${RTL_KERNEL_SRC}
    )
endforeach()

set (VPP_TARGET hw_emu)
set (VPP_PLATFORM xilinx_u250_xdma_201830_2)
set (VPP_FLAGS --log_dir ${LOG_DIR} -t ${VPP_TARGET} -f ${VPP_PLATFORM} -s --report_dir ${REPORT_DIR})

# Link the .xo files
add_custom_command(
    OUTPUT obj/${CMAKE_PROJECT_NAME}.link.xclbin
    COMMAND ${Vitis_COMPILER} ${VPP_FLAGS} ${CONFIG_LINK} --temp_dir tmp/vitis/link -o obj/${CMAKE_PROJECT_NAME}.link.xclbin -l obj/byteswap.xo
    DEPENDS obj/byteswap.xo)

# Package the .xclbin file
set (DEVICE_BINARY "${CMAKE_BINARY_DIR}/bin/${CMAKE_PROJECT_NAME}.xclbin")
add_custom_command(
    OUTPUT ${DEVICE_BINARY}
    COMMAND ${Vitis_COMPILER} ${VPP_FLAGS} ${CONFIG_PKG} --temp_dir tmp/vitis/pkg -o ${DEVICE_BINARY} -p obj/${CMAKE_PROJECT_NAME}.link.xclbin
    DEPENDS obj/${CMAKE_PROJECT_NAME}.link.xclbin)

#####
# hw_emu xrt
#####
set (EMCONFIG "${CMAKE_BINARY_DIR}/bin/emconfig.json")
add_custom_command(
    OUTPUT ${EMCONFIG}
    COMMAND emconfigutil --platform ${VPP_PLATFORM} --od bin)

#####
# Host section
#####
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -DHLSLIB_LEGACY_SDX=0")
set (HOST_SRC "${CMAKE_SOURCE_DIR}/src/host.cpp")
add_executable(${CMAKE_PROJECT_NAME} ${HOST_SRC} ${DEVICE_BINARY} ${EMCONFIG})
#add_dependencies(${CMAKE_PROJECT_NAME} )
target_link_libraries(${CMAKE_PROJECT_NAME} ${Vitis_LIBRARIES} ${LINK_CONFIG})
set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

add_custom_target(run
    COMMAND XCL_EMULATION_MODE=${VPP_TARGET} bin/${CMAKE_PROJECT_NAME} bin/${CMAKE_PROJECT_NAME}.xclbin
    DEPENDS ${CMAKE_PROJECT_NAME})
