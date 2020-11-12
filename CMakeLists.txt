cmake_minimum_required(VERSION 3.12.4)
project(vitis_rtl)

set (VPP_TARGET hw_emu)
set (PRJS
    byteswap
    #    vadd
    #    vadd_float
    #    vadd_float_hls
    #    vadd_float_hls_pure
)
add_compile_definitions(DATA_SIZE=16*KB)

set(HLSLIB_DIR "${CMAKE_SOURCE_DIR}/hlslib")
set(RTLLIB_DIR "${CMAKE_SOURCE_DIR}/rtllib")

foreach (PRJ ${PRJS})
    add_subdirectory(${PRJ})
    set (RUNS ${RUNS} run_${PRJ})
endforeach()

add_custom_target(run
    DEPENDS ${RUNS}
)
