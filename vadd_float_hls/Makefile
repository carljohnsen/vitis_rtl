TARGET = hw_emu
KERNEL = vadd_float
include ../utils/utils.mk

build/obj/reader.xo: src/hls/reader.cpp
	v++ -t $(TARGET) --config ./connections.ini --platform $(PLATFORM) -c -k reader -o build/obj/reader.xo src/hls/reader.cpp

build/obj/writer.xo: src/hls/writer.cpp
	v++ -t $(TARGET) --config ./connections.ini --platform $(PLATFORM) -c -k writer -o build/obj/writer.xo src/hls/writer.cpp

build/bin/float_vadd.link.xclbin: build/obj/reader.xo build/obj/writer.xo build/obj/vadd_float.xo connections.ini
	v++ -t $(TARGET) --platform $(PLATFORM) -l --config ./connections.ini -o build/bin/float_vadd.link.xclbin build/obj/reader.xo build/obj/vadd_float.xo build/obj/writer.xo

build/bin/float_vadd.xclbin: build/bin/float_vadd.link.xclbin
	v++ -p build/bin/float_vadd.link.xclbin -t $(TARGET) --platform $(PLATFORM) -o build/bin/float_vadd.xclbin

hls: $(HOST_BINARY) build/bin/float_vadd.xclbin $(EMCONFIG)
	XCL_EMULATION_MODE=$(TARGET) build/bin/vadd build/bin/float_vadd.xclbin
