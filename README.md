# Vitis RTL samples
This repository holds different Vitis projects, which implement RTL kernels
written in Verilog. Some are generated using the RTL Kernel Wizard in Xilinx
Vivado, while others are a mix of generated files and hand-written RTL files.

# Prerequisites
- [CMake >= 3.12.4](https://github.com/Kitware/CMake)
- [Xilinx Vitis 2020.1](https://www.xilinx.com/products/design-tools/vitis/vitis-platform.html)
- [Xilinx Runtime Library (XRT)](https://www.xilinx.com/products/design-tools/vitis/xrt.html)
- A Xilinx platform, such as the [Xilinx Alveo U250 platform](https://www.xilinx.com/products/boards-and-kits/alveo/u250.html#gettingStarted)

# Building/running a project
First, all of the environment variables for Xilinx Vivado need to be set. An
example shell file with the default variables can be sourced or added to rc
file (e.g. `~/.bashrc`):
```
source source.sh
```

To generate all of the build scripts in a folder called `build/`:
```
cmake -Bbuild -H.
```

To build all of the projects:
```
cmake --build build
```

To build a single project, here `byteswap` is used as an example:
```
cmake --build build --target build_byteswap
```

To run all of the projects:
```
cmake --build build --target run
```

To run a single project, here `byteswap` is used as an example:
```
cmake --build build --target run_byteswap
```

# Project file structure
Files encapsulated in `[]` are optional files and folders. Filenames with `*`
indicates the glob pattern for source files. The filenames such as
`rtl_kernel_0` and `hls_kernel_0` are purely suggestions.
```
project/
|-- CMakeLists.txt          # cmake configuration
`-- src
    |-- [configs]           # optional folder for v++ configs
    |   |-- [build.ini]     # optional v++ config for build HLS kernels
    |   |-- [link.ini]      # optional v++ config for linking .xo kernels
    |   `-- [package.ini]   # optional v++ config for packaging .xclbin binary
    |-- [hdl]
    |   `-- rtl_kernel_0
    |   |   |-- kernel.json # kernel configuration for generating scripts
    |   |   |-- *.v
    |   |   `-- *.sv
    |   `-- rtl_kernel_1
    |       |-- kernel.json
    |       |-- *.v
    |       `-- *.sv
    |-- [hls]
    |   |-- hls_kernel_0.cpp
    |   `-- hls_kernel_1.cpp
    `-- host.cpp
```

# Projects
- [Byteswap](byteswap/) - Swaps the order of bytes for each 32 bit input, so
  the least significant byte becomes the most significant byte.
- [Vector add](vadd/) - Sums the two input vectors. It is a modified version of
  the
  [Xilinx](https://github.com/Xilinx/Vitis_Accel_Examples/tree/master/rtl_kernels/rtl_vadd)
  sample.
- [Vector add floating point](vadd_float/) - Same as Vector add, but uses the
  [Xilinx Floating Point IP](https://www.xilinx.com/support/documentation/ip_documentation/floating_point/v7_1/pg060-floating-point.pdf)
  for the addition.
- [Vector add floating point hls](vadd_float_hls/) - Multi kernel Vector add,
  with HLS for memory management and with RTL as compute kernel.
- [Vector add floating point hls pure](vadd_float_hls_pure) - Multi kernel
  Vector add, written purely in HLS.

# Utilities
- [CMakeLists](utils/CMakeLists.txt) - cmake file containing all the rules and
  commands for building the projects.
- [rtl/](utils/rtl/) - RTL library with implementations of utility cores.
  - [axi_counter](utils/rtl/axi_counter.sv) - Counter, which is used by the AXI
    cores.
  - [axi_read_master](utils/rtl/axi_read_master.sv) - Multi channel AXI read
    master.
  - [axi_write_master](utils/rtl/axi_write_master.sv) - Multi channel AXI write
    master.
- [templates/](utils/templates) - Python scripts for generating TCL scripts and
  RTL files.
  - [control](utils/templates/control.py) - Python script for generating a
    Verilog controller for Vitis.
  - [package](utils/templates/package.py) - Python script for generating a TCL
    script for packaging an RTL kernel into an `.xo` file.
  - [synth](utils/templates/synth.py) - Python script for generating a TCL
    script for elaborating and synthesizing RTL kernels for finding errors,
    such as syntax errors.
- [utils.mk](utils/utils.mk) (deprecated) - Makefile for building all of the
  projects.
