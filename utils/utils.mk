##############################
# Project specific variables #
##############################
#KERNEL = rtl_kernel_wizard_1
#TARGET = hw_emu

#########################
# Environment variables #
#########################
# Directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
LOG_DIR = logs
OBJECTS_DIR = $(BUILD_DIR)/obj
PKG_DIR = $(BUILD_DIR)/pkg
SCRIPT_DIR = scripts
SRC_DIR = src
SRC_HDL_DIR = $(SRC_DIR)/hdl
VITIS_BUILD_DIR = $(BUILD_DIR)/vitis
VIVADO_BUILD_DIR = $(BUILD_DIR)/vivado
VIVADO_ELABORATE_DIR = $(VIVADO_BUILD_DIR)/elaborate
VIVADO_PACKAGE_DIR = $(VIVADO_BUILD_DIR)/package
VIVADO_SYNTH_DIR = $(VIVADO_BUILD_DIR)/synth

# Compilers
CPP = g++
VPP = v++
VIVADO = $(XILINX_VIVADO)/bin/vivado

# Flags
CFLAGS = -O0 -std=c++11
INCLUDES = -I$(XILINX_XRT)/include -I$(XILINX_VIVADO)/include
LIBS = -lOpenCL -lpthread -lstdc++ -lrt -Wall
LIB_DIRS = -L$(XILINX_XRT)/lib
PLATFORM = xilinx_u250_xdma_201830_2
VIVADO_LOG = -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou

# Source files
HOST_FILES = $(SRC_DIR)/host.cpp
TCL_PACKAGE = $(SCRIPT_DIR)/package_kernel.tcl
TCL_ELABORATE = $(SCRIPT_DIR)/test_elaborate.tcl
TCL_SYNTH = $(SCRIPT_DIR)/test_synth.tcl
VERILOG_FILES = $(SRC_HDL_DIR)/*.v
SYSTEM_VERILOG_FILES = $(SRC_HDL_DIR)/*.sv

# Binary files
DEVICE_BINARY = $(BIN_DIR)/$(KERNEL).xclbin
HOST_BINARY = $(BIN_DIR)/vadd
OBJECTS = $(OBJECTS_DIR)/host.o
PACKAGED_KERNEL = $(OBJECTS_DIR)/$(KERNEL).xo
COMPILED_KERNEL = $(OBJECTS_DIR)/$(KERNEL).link.xclbin
EMCONFIG = $(BIN_DIR)/emconfig.json

#########
# Rules #
#########
# Generic rules
all: check_parameters build link

# TODO also remove some of the hidden folders, and find a way to move all this pesky logging...
clean:
	rm -rf ./$(BUILD_DIR) ./_x ./$(LOG_DIR)
	rm -f ./hs_err_pid* ./v++_* ./xcd.log ./xrc.log

build: check_parameters $(PACKAGED_KERNEL) $(OBJECTS) $(EMCONFIG)

link: check_parameters $(DEVICE_BINARY) $(HOST_BINARY)

run: all
	XCL_EMULATION_MODE=$(TARGET) $(HOST_BINARY) $(DEVICE_BINARY)

check_parameters:
ifndef TARGET
$(error $$TARGET is not set!)
endif
ifndef KERNEL
$(error $$KERNEL is not set!)
endif

# Device specific rules
elaborate: check_parameters
	mkdir -p $(VIVADO_ELABORATE_DIR)
	mkdir -p $(LOG_DIR)
	$(VIVADO) -mode batch $(VIVADO_LOG) -source $(TCL_SYNTH) -tclargs $(SRC_HDL_DIR) $(KERNEL) $(VIVADO_ELABORATE_DIR) -rtl

synth: check_parameters
	mkdir -p $(VIVADO_SYNTH_DIR)
	mkdir -p $(LOG_DIR)
	$(VIVADO) -mode batch $(VIVADO_LOG) -source $(TCL_SYNTH) -tclargs $(SRC_HDL_DIR) $(KERNEL) $(VIVADO_SYNTH_DIR)

$(PACKAGED_KERNEL): $(TCL_PACKAGE) $(VERILOG_FILES) $(SYSTEM_VERILOG_FILES)
	mkdir -p $(VIVADO_PACKAGE_DIR)
	mkdir -p $(OBJECTS_DIR)
	mkdir -p $(LOG_DIR)
	$(VIVADO) -mode batch $(VIVADO_LOG) -source $(TCL_PACKAGE) -tclargs $(PACKAGED_KERNEL) $(KERNEL) $(VIVADO_PACKAGE_DIR) $(SRC_HDL_DIR)

$(DEVICE_BINARY): $(PACKAGED_KERNEL)
	mkdir -p $(VITIS_BUILD_DIR)
	mkdir -p $(PKG_DIR)
	mkdir -p $(LOG_DIR)
	$(VPP) --log_dir $(LOG_DIR) -l -t $(TARGET) --platform $(PLATFORM) --save-temps --temp_dir $(VITIS_BUILD_DIR) -o $(COMPILED_KERNEL) $^
	$(VPP) --log_dir $(LOG_DIR) -p $(COMPILED_KERNEL) -t $(TARGET) --platform $(PLATFORM) --temp_dir $(PKG_DIR) --package.out_dir $(PKG_DIR) -o $(DEVICE_BINARY)

$(EMCONFIG):
	emconfigutil --platform $(PLATFORM) --od $(BIN_DIR)

# Host specific rules
$(OBJECTS_DIR)/%.o: $(SRC_DIR)/%.cpp
	mkdir -p $(OBJECTS_DIR)
	$(CPP) $(INCLUDES) -c $< -g -o $@

$(HOST_BINARY): $(OBJECTS)
	mkdir -p $(BIN_DIR)
	$(CPP) -o $@ $^ $(LIB_DIRS) $(LIBS)

