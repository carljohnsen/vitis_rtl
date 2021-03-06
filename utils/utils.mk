#########################
# Environment variables #
#########################
# Directories
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
CONFIGS_DIR = $(SRC_DIR)/configs
GENERATED_DIR = generated
HLSLIB_DIR = ../hlslib
LOG_DIR = logs
OBJ_DIR = $(BUILD_DIR)/obj
PKG_DIR = $(BUILD_DIR)/pkg
REPORT_DIR = $(VITIS_BUILD_DIR)/reports
RTLLIB_DIR = $(UTILS_DIR)/rtl
SCRIPT_DIR = scripts
SRC_DIR = src
SRC_HDL_DIR = $(SRC_DIR)/hdl
SRC_HLS_DIR = $(SRC_DIR)/hls
TEMPLATES_DIR = $(UTILS_DIR)/templates
UTILS_DIR = ../utils
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
CONFIG_BUILD = $(foreach CFG, $(wildcard $(CONFIGS_DIR)/build.ini), --config $(CFG))
CONFIG_LINK = $(foreach CFG, $(wildcard $(CONFIGS_DIR)/link.ini), --config $(CFG))
CONFIG_PACKAGE = $(foreach CFG, $(wildcard $(CONFIGS_DIR)/package.ini), --config $(CFG))
INCLUDES = -I$(XILINX_XRT)/include -I$(XILINX_VIVADO)/include -I$(HLSLIB_DIR)/include
LIBS = -lOpenCL -lpthread -lstdc++ -lrt -Wall
LIB_DIRS = -L$(XILINX_XRT)/lib
PLATFORM = xilinx_u250_xdma_201830_2
VIVADO_FLAGS = -mode batch -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou
VPP_FLAGS = --log_dir $(LOG_DIR) -t $(TARGET) -f $(PLATFORM) -s --report_dir $(REPORT_DIR)

# Source files
CONTROL_TEMPLATE = $(TEMPLATES_DIR)/control.py
HOST_FILES = $(SRC_DIR)/host.cpp
KERNEL_CONFIGS = $(foreach KRNL, $(RTL_KERNELS), $(SRC_HDL_DIR)/$(KRNL)/kernel.json)
PACKAGE_TEMPLATE = $(TEMPLATES_DIR)/package.py
SYNTH_TEMPLATE = $(TEMPLATES_DIR)/synth.py

# Target files
CPP_XO_TARGETS = $(foreach KRNL, $(CPP_KERNELS), $(OBJ_DIR)/cpp_$(KRNL).xo)
DEVICE_BINARY = $(BIN_DIR)/$(NAME).xclbin
EMCONFIG = $(BIN_DIR)/emconfig.json
HOST_BINARY = $(BIN_DIR)/$(NAME)
KERNEL_CONTROLS = $(foreach KRNL, $(RTL_KERNELS), $(GENERATED_DIR)/$(KRNL)_control.v)
LINKED_KERNEL = $(OBJ_DIR)/$(NAME).link.xclbin
OBJECTS = $(OBJ_DIR)/host.o
RTL_XO_TARGETS = $(foreach KRNL, $(RTL_KERNELS), $(OBJ_DIR)/rtl_$(KRNL).xo)
TCL_PACKAGES = $(foreach KRNL, $(RTL_KERNELS), $(SCRIPT_DIR)/$(KRNL)_package.tcl)
TCL_SYNTHS = $(foreach KRNL, $(RTL_KERNELS), $(SCRIPT_DIR)/$(KRNL)_synth.tcl)

#########
# Rules #
#########
# Generic rules
all: build

# TODO also remove some of the hidden folders, and find a way to move all this pesky logging...
clean:
	rm -rf ./$(BUILD_DIR) ./$(LOG_DIR) ./$(SCRIPT_DIR) ./$(GENERATED_DIR)
	rm -rf ./.ipcache/ ./.Xil/ ./$(PLATFORM)-* ./.hbs/
	rm -f ./hs_err_pid* ./profile_kernels.csv ./timeline_kernels.csv

build: $(DEVICE_BINARY) $(HOST_BINARY) $(EMCONFIG)

run: all
	XCL_EMULATION_MODE=$(TARGET) $(HOST_BINARY) $(DEVICE_BINARY)

# Device specific rules
pack: $(KERNEL_CONTROLS) $(TCL_PACKAGES) $(RTL_XO_TARGETS)

$(TCL_SYNTHS): $(SCRIPT_DIR)/%_synth.tcl: $(SYNTH_TEMPLATE) $(SRC_HDL_DIR)/%/kernel.json
	mkdir -p $(SCRIPT_DIR)
	python3 $^ -o $@ -f

elaborate_%: $(SCRIPT_DIR)/%_synth.tcl $(GENERATED_DIR)/%_control.v $(SRC_HDL_DIR)/%/*.*v
	rm -rf $(VIVADO_ELABORATE_DIR)
	mkdir -p $(VIVADO_ELABORATE_DIR) $(LOG_DIR)
	$(VIVADO) $(VIVADO_FLAGS) -source $< -tclargs $(SRC_HDL_DIR)/$(*F) $(*F) $(VIVADO_ELABORATE_DIR) $(RTLLIB_DIR) $(GENERATED_DIR) -rtl

synth_%: $(SCRIPT_DIR)/%_synth.tcl $(GENERATED_DIR)/%_control.v $(SRC_HDL_DIR)/%/*.*v
	rm -rf $(VIVADO_SYNTH_DIR)
	mkdir -p $(VIVADO_SYNTH_DIR) $(LOG_DIR)
	$(VIVADO) $(VIVADO_FLAGS) -source $< -tclargs $(SRC_HDL_DIR)/$(*F) $(*F) $(VIVADO_SYNTH_DIR) $(RTLLIB_DIR) $(GENERATED_DIR)

$(KERNEL_CONTROLS): $(GENERATED_DIR)/%_control.v: $(CONTROL_TEMPLATE) $(SRC_HDL_DIR)/%/kernel.json
	mkdir -p $(GENERATED_DIR)
	python3 $^ -o $@ -f

$(TCL_PACKAGES): $(SCRIPT_DIR)/%_package.tcl: $(PACKAGE_TEMPLATE) $(SRC_HDL_DIR)/%/kernel.json
	mkdir -p $(SCRIPT_DIR)
	python3 $^ -o $@ -f

$(OBJ_DIR)/rtl_%.xo: $(SCRIPT_DIR)/%_package.tcl $(GENERATED_DIR)/%_control.v $(SRC_HDL_DIR)/%/*.*v
	rm -rf $(VIVADO_PACKAGE_DIR)/$(*F) $@
	mkdir -p $(VIVADO_PACKAGE_DIR)/$(*F) $(OBJ_DIR) $(LOG_DIR)
	$(VIVADO) $(VIVADO_FLAGS) -source $< -tclargs $@ $(*F) $(VIVADO_PACKAGE_DIR)/$(*F) $(SRC_HDL_DIR)/$(*F) $(RTLLIB_DIR) $(GENERATED_DIR)

$(OBJ_DIR)/cpp_%.xo: $(SRC_HLS_DIR)/%.cpp
	mkdir -p $(OBJ_DIR) $(VITIS_BUILD_DIR)/$(*F) $(REPORT_DIR) $(LOG_DIR)
	$(VPP) $(VPP_FLAGS) $(CONFIG_BUILD) --temp_dir $(VITIS_BUILD_DIR)/$(*F) -o $@ -c -k $(*F) $<

$(LINKED_KERNEL): $(RTL_XO_TARGETS) $(CPP_XO_TARGETS)
	mkdir -p $(OBJ_DIR) $(VITIS_BUILD_DIR)/link $(REPORT_DIR) $(LOG_DIR)
	$(VPP) $(VPP_FLAGS) $(CONFIG_LINK) --temp_dir $(VITIS_BUILD_DIR)/link -o $@ -l $^
	mv xcd.log $(LOG_DIR)/xcd_link.log
	mv xrc.log $(LOG_DIR)/xrc_link.log

$(DEVICE_BINARY): $(LINKED_KERNEL)
	mkdir -p $(BIN_DIR) $(VITIS_BUILD_DIR)/pack $(REPORT_DIR) $(LOG_DIR)
	$(VPP) $(VPP_FLAGS) $(CONFIG_PACKAGE) --temp_dir $(VITIS_BUILD_DIR)/pack -o $@ -p $<
	mv xcd.log $(LOG_DIR)/xcd_pkg.log
	mv xrc.log $(LOG_DIR)/xrc_pkg.log

$(EMCONFIG):
	emconfigutil --platform $(PLATFORM) --od $(BIN_DIR)

# Host specific rules
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	mkdir -p $(OBJ_DIR)
	$(CPP) $(INCLUDES) -c $< -g -o $@

$(HOST_BINARY): $(OBJECTS)
	mkdir -p $(BIN_DIR)
	$(CPP) -o $@ $^ $(LIB_DIRS) $(LIBS)

######################
# Parameter checking #
######################
ifndef TARGET
$(error $$TARGET is not set!)
endif
ifndef NAME
$(error $$NAME is not set!)
endif
ifndef RTL_KERNELS
ifndef CPP_KERNELS
$(error No kernels ($$RTL_KERNELS or $$CPP_KERNELS) specified!)
endif
endif
