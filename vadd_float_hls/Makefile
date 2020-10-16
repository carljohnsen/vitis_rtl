TARGET = hw_emu
KERNEL = vadd_float
include ../utils/utils.mk

build/obj/reader.xo: src/hls/reader.cpp
	v++ -t hw_emu --config ./connections.ini --platform xilinx_u250_xdma_201830_2 -c -k reader -o build/obj/reader.xo src/hls/reader.cpp

build/obj/writer.xo: src/hls/writer.cpp
	v++ -t hw_emu --config ./connections.ini --platform xilinx_u250_xdma_201830_2 -c -k writer -o build/obj/writer.xo src/hls/writer.cpp

build/obj/vadd_float.xo: src/hls/adder.cpp
	v++ -t hw_emu --config ./connections.ini --platform xilinx_u250_xdma_201830_2 -c -k vadd_float -o build/obj/vadd_float.xo src/hls/adder.cpp

build/bin/float_vadd.link.xclbin: build/obj/reader.xo build/obj/writer.xo build/obj/vadd_float.xo
	v++ -t hw_emu --platform xilinx_u250_xdma_201830_2 -l --config ./connections.ini -o build/bin/float_vadd.link.xclbin build/obj/reader.xo build/obj/vadd_float.xo build/obj/writer.xo

build/bin/float_vadd.xclbin: build/bin/float_vadd.link.xclbin
	v++ -p build/bin/float_vadd.link.xclbin -t hw_emu --platform xilinx_u250_xdma_201830_2 -o build/bin/float_vadd.xclbin

hls: $(HOST_BINARY) build/bin/float_vadd.xclbin
	XCL_EMULATION_MODE=hw_emu build/bin/vadd build/bin/float_vadd.xclbin
