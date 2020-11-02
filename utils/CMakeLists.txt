cmake_minimum_required(VERSION 3.1.5)

# Make sure hlslib is downloaded
find_package(git QUIET)
if (GIT_FOUND AND EXISTS "${PARENT_DIR}/.git")
    option(GIT_SUBMODULE "Check submodules during build" ON)
    if (GIT_SUBMODULE)
        message(STATUS "Submodule update")
        execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY ${PARENT_DIR}
            RESULT_VARIABLE GIT_SUBMOD_RESULT)

        if (NOT GITSUBMOD_RESULT EQUAL "0")
            message (FATAL_ERROR "git submodule --init failed with ${GIT_SUBMOD_RESULT}")
        endif()
    endif()
endif()


#####
# Load hlslib
#####
set(HLSLIB_DIR "${PARENT_DIR}/hlslib")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${HLSLIB_DIR}/cmake)
find_package(Vitis REQUIRED)
include_directories(${HLSLIB_DIR}/include ${Vitis_INCLUDE_DIRS})

#####
# Load rtllib
#####
set(TEMPLATES_DIR "${UTILS_DIR}/templates")
set(CONTROL_TEMPLATE "${TEMPLATES_DIR}/control.py")
set(PACKAGE_TEMPLATE "${TEMPLATES_DIR}/package.py")
set(SYNTH_TEMPLATE "${TEMPLATES_DIR}/synth.py")
set(RTLLIB_DIR "${UTILS_DIR}/rtl")

#####
# Device section
#####
set (GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set (SCRIPTS_DIR "${CMAKE_CURRENT_BINARY_DIR}/scripts")
set (OBJ_DIR "${CMAKE_CURRENT_BINARY_DIR}/obj")
set (LOG_DIR "${CMAKE_CURRENT_BINARY_DIR}/log")
set (REPORTS_DIR "${CMAKE_CURRENT_BINARY_DIR}/reports")
set (BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/bin")
file (MAKE_DIRECTORY ${GENERATED_DIR} ${SCRIPTS_DIR} ${OBJ_DIR} ${LOG_DIR} ${REPORTS_DIR} ${BIN_DIR})

# RTL_KERNELS
set (HDL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/hdl")
set (VIVADO_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp/vivado")
foreach (RTL_KERNEL ${RTL_KERNELS})
    set (VIVADO_FLAGS -mode batch -log ${LOG_DIR}/vivado_${RTL_KERNEL}.log -journal ${LOG_DIR}/vivado_${RTL_KERNEL}.jou)
    set (KERNEL_DIR "${HDL_DIR}/${RTL_KERNEL}")
    file(GLOB SRCS "${KERNEL_DIR}/*.*v")
    set (CFG "${KERNEL_DIR}/kernel.json")
    set (CTRL "${CMAKE_CURRENT_BINARY_DIR}/generated/${RTL_KERNEL}_Control.v")
    add_custom_command(
        OUTPUT  ${CTRL}
        COMMAND ${CONTROL_TEMPLATE} ${CFG} -o ${CTRL} -f
        DEPENDS ${CONTROL_TEMPLATE} ${CFG}
    )
    set (PKG "${CMAKE_CURRENT_BINARY_DIR}/scripts/${RTL_KERNEL}_package.tcl")
    add_custom_command(
        OUTPUT  ${PKG}
        COMMAND ${PACKAGE_TEMPLATE} ${CFG} -o ${PKG} -f
        DEPENDS ${PACKAGE_TEMPLATE} ${CFG}
    )
    set (XO "${CMAKE_CURRENT_BINARY_DIR}/obj/${RTL_KERNEL}.xo")
    add_custom_command(
        OUTPUT  ${XO}
        COMMAND ${Vitis_VIVADO} ${VIVADO_FLAGS} -source ${PKG} -tclargs ${XO} ${RTL_KERNEL} ${VIVADO_TMP_DIR}/${RTL_KERNEL} ${KERNEL_DIR} ${RTLLIB_DIR} ${GENERATED_DIR}
        DEPENDS ${CTRL} ${PKG} ${RTL_KERNEL_SRC}
    )
    set (XOS ${XOS} ${XO})

    set (SYNTH "${CMAKE_CURRENT_BINARY_DIR}/scripts/${RTL_KERNEL}_synth.tcl")
    add_custom_command(
        OUTPUT ${SYNTH}
        COMMAND ${SYNTH_TEMPLATE} ${CFG} -o ${SYNTH} -f
        DEPENDS ${SYNTH_TEMPLATE} ${CFG}
    )
    set (VIVADO_FLAGS -mode batch -log ${LOG_DIR}/vivado_elaborate_${RTL_KERNEL}.log -journal ${LOG_DIR}/vivado_elaborate_${RTL_KERNEL}.jou)
    add_custom_target(elaborate_${PROJECT_NAME}_${RTL_KERNEL}
        COMMAND ${Vitis_VIVADO} ${VIVADO_FLAGS} -source ${SYNTH} -tclargs ${KERNEL_DIR} ${RTL_KERNEL} ${VIVADO_TMP_DIR}/elaborate_${RTL_KERNEL} ${RTLLIB_DIR} ${GENERATED_DIR} -rtl
        DEPENDS ${CTRL} ${SYNTH} ${RTL_KERNEL_SRC}
    )
    set (VIVADO_FLAGS -mode batch -log ${LOG_DIR}/vivado_synth_${RTL_KERNEL}.log -journal ${LOG_DIR}/vivado_synth_${RTL_KERNEL}.jou)
    add_custom_target(synth_${PROJECT_NAME}_${RTL_KERNEL}
        COMMAND ${Vitis_VIVADO} ${VIVADO_FLAGS} -source ${SYNTH} -tclargs ${KERNEL_DIR} ${RTL_KERNEL} ${VIVADO_TMP_DIR}/synth_${RTL_KERNEL} ${RTLLIB_DIR} ${GENERATED_DIR}
        DEPENDS ${CTRL} ${SYNTH} ${RTL_KERNEL_SRC}
    )
endforeach()

set (VPP_PLATFORM xilinx_u250_xdma_201830_2)
set (VPP_FLAGS --log_dir ${LOG_DIR} -t ${VPP_TARGET} -f ${VPP_PLATFORM} -s --report_dir ${REPORTS_DIR})
set (VPP_TMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp/vitis")
set (CONFIGS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/configs")

# HLS kernels
set (HLS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/hls")
foreach (CPP_KERNEL ${CPP_KERNELS})
    if (EXISTS "${CONFIGS_DIR}/build.ini")
        set (CONFIG_BUILD --config "${CONFIGS_DIR}/build.ini")
    endif()
    set (CPP_KERNEL_SRC "${HLS_DIR}/${CPP_KERNEL}.cpp")
    set (XO "${CMAKE_CURRENT_BINARY_DIR}/obj/${CPP_KERNEL}.xo")
    add_custom_command(
        OUTPUT ${XO}
        COMMAND ${Vitis_COMPILER} ${VPP_FLAGS} ${CONFIG_BUILD} --temp_dir ${VPP_TMP_DIR}/build_${CPP_KERNEL} -o ${XO} -c -k ${CPP_KERNEL} ${CPP_KERNEL_SRC}
        DEPENDS ${CPP_KERNEL_SRC})
    set (XOS ${XOS} ${XO})
endforeach()

# Link the .xo files
set (VPP_LINKED "${CMAKE_CURRENT_BINARY_DIR}/obj/${PROJECT_NAME}.link.xclbin")
if (EXISTS "${CONFIGS_DIR}/link.ini")
    set (CONFIG_LINK --config "${CONFIGS_DIR}/link.ini")
endif()
add_custom_command(
    OUTPUT ${VPP_LINKED}
    COMMAND ${Vitis_COMPILER} ${VPP_FLAGS} ${CONFIG_LINK} --temp_dir ${VPP_TMP_DIR}/link -o ${VPP_LINKED} -l ${XOS}
    DEPENDS ${XOS})

# Package the .xclbin file
set (DEVICE_BINARY "${CMAKE_CURRENT_BINARY_DIR}/bin/${PROJECT_NAME}.xclbin")
if (EXISTS "${CONFIGS_DIR}/package.ini")
    set (CONFIG_PKG --config "${CONFIGS_DIR}/package.ini")
endif()
add_custom_command(
    OUTPUT ${DEVICE_BINARY}
    COMMAND ${Vitis_COMPILER} ${VPP_FLAGS} ${CONFIG_PKG} --temp_dir ${VPP_TMP_DIR}/pkg -o ${DEVICE_BINARY} -p ${VPP_LINKED}
    DEPENDS ${VPP_LINKED})

#####
# hw_emu xrt
#####
set (EMCONFIG "${CMAKE_CURRENT_BINARY_DIR}/bin/emconfig.json")
add_custom_command(
    OUTPUT ${EMCONFIG}
    COMMAND emconfigutil --platform ${VPP_PLATFORM} --od bin)

#####
# Host section
#####
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -DHLSLIB_LEGACY_SDX=0")
set (HOST_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/host.cpp")
add_executable(${PROJECT_NAME} ${HOST_SRC})
target_link_libraries(${PROJECT_NAME} ${Vitis_LIBRARIES})
set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin")

#####
# Targets
#####
add_custom_target(device_${PROJECT_NAME}
    ALL
    DEPENDS ${DEVICE_BINARY} ${EMCONFIG}
)

add_custom_target(run_${PROJECT_NAME}
    COMMAND XCL_EMULATION_MODE=${VPP_TARGET} "${CMAKE_CURRENT_BINARY_DIR}/bin/${PROJECT_NAME}" ${DEVICE_BINARY}
    DEPENDS ${PROJECT_NAME} ${DEVICE_BINARY} ${EMCONFIG}
)
