# Vitis RTL samples
This repository holds different Vitis projects, which implement RTL kernels written in Verilog. Some are generated using the RTL Kernel Wizard in Xilinx Vivado, while others are a mix of generated files and hand-written RTL files.

# Prerequisites
- [Xilinx Vitis 2020.1](https://www.xilinx.com/products/design-tools/vitis/vitis-platform.html)
- [Xilinx Runtime Library (XRT)](https://www.xilinx.com/products/design-tools/vitis/xrt.html)
- [Xilinx Alveo U250 platform](https://www.xilinx.com/products/boards-and-kits/alveo/u250.html#gettingStarted)

# Building/Running a project
All of the projects requires the environment variables from Xilinx Vitis and Xilinx Runtime Library (XRT). Assuming both are installed in `/opt/`, run the following commands from a `bash` shell (For some reason, `zsh` won't work):
```
source /opt/Xilinx/Vitis/2020.1/settings64.sh
source /opt/xilinx/xrt/setup.sh
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
```
Each project has its own `Makefile`. So to run either, `cd` into their directory and run one of the following commands:

To check whether Xilinx Vivado can parse and elaborate the RTL code:
```
make elaborate
```

To check whether Xilinx Vivado can synthesize the RTL code:
```
make synth
```

To build a project (both host and device code):
```
make build
```

And to run a project:
```
make run
```

# Projects
- [Byteswap](byteswap/) - Swaps the order of bytes in each input, so the least significant byte becomes the most significant byte.
- [Vector add](vadd/) - Sums the two input vectors. It is a modified version of the [Xilinx](https://github.com/Xilinx/Vitis_Accel_Examples/tree/master/rtl_kernels/rtl_vadd) sample.
- [Vector add floating point](vadd_float/) - Same as Vector add, but uses the [Xilinx Floating Point IP](https://www.xilinx.com/support/documentation/ip_documentation/floating_point/v7_1/pg060-floating-point.pdf) for the addition.
- [Vector add floating point hls](vadd_float_hls/) - Multi kernel Vector add, with HLS for memory management and with RTL as compute kernel.
- [Vector add floating point hls pure](vadd_float_hls_pure) - Multi kernel Vector add, written purely in HLS.

# Utilities
- `utils.mk` - a library of commonly used Makefile rules and variables.
- `host.cpp` - TODO a template host program containing most of the generic boilerplate OpenCL code.
- `package_kernel.tcl` - TODO a template TCL script containing most of the generic boilerplate Vivado project TCL code.
- `test_synthesis.tcl` - TODO a template TCL script for testing whether the RTL code can be synthesized.
- `empty_project` - TODO an empty project containing the basic requirements for a project, such as `Makefile` and folder structure.
