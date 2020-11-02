cmake_minimum_required(VERSION 3.1.5)
project(vitis_rtl)

set (VPP_TARGET hw)
set (PRJS byteswap vadd vadd_float vadd_float_hls vadd_float_hls_pure)

foreach (PRJ ${PRJS})
    add_subdirectory(${PRJ})
    set (RUNS ${RUNS} run_${PRJ})
endforeach()

add_custom_target(run
    DEPENDS ${RUNS}
)
