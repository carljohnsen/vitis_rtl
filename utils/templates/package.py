#!/usr/bin/env python3
import argparse
import json
import os

# TODO nogle af parametrene skal vel være unikke for hver? Så multi kernels!
def scalar_reg(param_name, addr, num_bytes):
    return '''
set reg [::ipx::add_register -quiet "{param_name}" $addr_block]
    set_property description    "Kernel parameter {param_name}" $reg
    set_property address_offset 0x{addr:03x} $reg
    set_property size           [expr {{{num_bytes}*8}}] $reg
'''.format(param_name=param_name, addr=addr, num_bytes=num_bytes)

def memory_ptr_reg(param_name, addr, busname):
    return '''
set reg [::ipx::add_register -quiet "{param_name}" $addr_block]
    set_property description    "Kernel parameter {param_name}" $reg
    set_property address_offset 0x{addr:03x} $reg
    set_property size           [expr {{8*8}}] $reg
    set regparam [::ipx::add_register_parameter -quiet {{ASSOCIATED_BUSIF}} $reg]
    set_property value          {busname} $regparam
'''.format(param_name=param_name, addr=addr, busname=busname)

def bus_clk(param_name):
    return f'ipx::associate_bus_interfaces -busif {param_name} -clock ap_clk $core\n'

def create(name, vendor, version, module_name):
    return f'create_ip -name {name} -vendor {vendor} -library ip -version {version} -module_name {module_name}\n'

def set_params(params, module_name):
    tmp = 'set_property -dict [list'
    for key, value in params.items():
        tmp += f' {key} {{{value}}}'
    tmp += f'] [get_ips {module_name}]\n'
    return tmp

def package_script(bus_clks, ip_cores, scalar_regs, memory_ptr_regs):
    return '''
#
# Argument parsing
#
if {{ $::argc != 6 }} {{
    puts "Error: Program \\"$::argv0\\" requires 6 arguments.\\n"
    puts "Usage: $::argv0 <xoname> <kernel_name> <build_dir> <rtl_src_dir> <library_dir> <generate_dir>\\n"
    exit
}}

set xoname      [lindex $::argv 0]
set kernel_name [lindex $::argv 1]
set build_dir   [lindex $::argv 2]
set src_dir     [lindex $::argv 3]
set lib_dir     [lindex $::argv 4]
set gen_dir     [lindex $::argv 5]

set tmp_dir "$build_dir/tmp"
set pkg_dir "$build_dir/pkg"

#
# Build the kernel
#
create_project kernel_packing $tmp_dir
add_files [glob $src_dir/*.*v $lib_dir/*.*v $gen_dir/*.*v]
{ip_cores}
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property top $kernel_name [current_fileset]
set_property top_file {{$src_dir/$kernel_name}} [current_fileset]
set_msg_config -id "HDL" -new_severity "ERROR"
check_syntax
reset_msg_config -id "HDL" -default_severity
ipx::package_project -root_dir $pkg_dir -vendor xilinx.com -library RTLKernel -taxonomy /KernelIP -import_files -set_current false
ipx::unload_core $pkg_dir/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_project -directory $pkg_dir $pkg_dir/component.xml

set core [ipx::current_core]

set_property core_revision 2 $core
foreach up [ipx::get_user_parameters] {{
    ipx::remove_user_parameter [get_property NAME $up] $core
}}
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk $core
{bus_clks}

# Specify the freq_hz
set clkbif      [::ipx::get_bus_interfaces -of $core "ap_clk"]
set clkbifparam [::ipx::add_bus_parameter -quiet "FREQ_HZ" $clkbif]
# Set the frequency
set_property value 250000000 $clkbifparam
# Set value_resolve_type 'user' if the frequency can vary. Otherwise, set to 'immediate'.
set_property value_resolve_type user $clkbifparam

set mem_map    [::ipx::add_memory_map -quiet "s_axi_control" $core]
set addr_block [::ipx::add_address_block -quiet "reg0" $mem_map]

# Set the control registers
set reg [::ipx::add_register "CTRL" $addr_block]
    set_property description          "Control signals" $reg
    set_property address_offset       0x000             $reg
    set_property size                 32                $reg
set field [ipx::add_field AP_START $reg]
    set_property ACCESS               {{read-write}}                              $field
    set_property BIT_OFFSET           {{0}}                                       $field
    set_property BIT_WIDTH            {{1}}                                       $field
    set_property DESCRIPTION          {{Control signal Register for 'ap_start'.}} $field
    set_property MODIFIED_WRITE_VALUE {{modify}}                                  $field
set field [ipx::add_field AP_DONE $reg]
    set_property ACCESS               {{read-only}}                              $field
    set_property BIT_OFFSET           {{1}}                                      $field
    set_property BIT_WIDTH            {{1}}                                      $field
    set_property DESCRIPTION          {{Control signal Register for 'ap_done'.}} $field
    set_property READ_ACTION          {{modify}}                                 $field
set field [ipx::add_field AP_IDLE $reg]
    set_property ACCESS               {{read-only}}                              $field
    set_property BIT_OFFSET           {{2}}                                      $field
    set_property BIT_WIDTH            {{1}}                                      $field
    set_property DESCRIPTION          {{Control signal Register for 'ap_idle'.}} $field
    set_property READ_ACTION          {{modify}}                                 $field
set field [ipx::add_field AP_READY $reg]
    set_property ACCESS               {{read-only}}                               $field
    set_property BIT_OFFSET           {{3}}                                       $field
    set_property BIT_WIDTH            {{1}}                                       $field
    set_property DESCRIPTION          {{Control signal Register for 'ap_ready'.}} $field
    set_property READ_ACTION          {{modify}}                                  $field
set field [ipx::add_field AP_RESERVED_1 $reg]
    set_property ACCESS               {{read-only}}              $field
    set_property BIT_OFFSET           {{4}}                      $field
    set_property BIT_WIDTH            {{3}}                      $field
    set_property DESCRIPTION          {{Reserved.  0s on read.}} $field
    set_property READ_ACTION          {{modify}}                 $field
set field [ipx::add_field AUTO_RESTART $reg]
    set_property ACCESS               {{read-write}}                                  $field
    set_property BIT_OFFSET           {{7}}                                           $field
    set_property BIT_WIDTH            {{1}}                                           $field
    set_property DESCRIPTION          {{Control signal Register for 'auto_restart'.}} $field
    set_property MODIFIED_WRITE_VALUE {{modify}}                                      $field
set field [ipx::add_field RESERVED_2 $reg]
    set_property ACCESS               {{read-only}}              $field
    set_property BIT_OFFSET           {{8}}                      $field
    set_property BIT_WIDTH            {{24}}                     $field
    set_property DESCRIPTION          {{Reserved.  0s on read.}} $field
    set_property READ_ACTION          {{modify}}                 $field

# Set the interrupt registers
set reg [::ipx::add_register "GIER" $addr_block]
    set_property description    "Global Interrupt Enable Register" $reg
    set_property address_offset 0x004                              $reg
    set_property size           32                                 $reg
set reg [::ipx::add_register "IP_IER" $addr_block]
    set_property description    "IP Interrupt Enable Register" $reg
    set_property address_offset 0x008                          $reg
    set_property size           32                             $reg
set reg [::ipx::add_register "IP_ISR" $addr_block]
    set_property description    "IP Interrupt Status Register" $reg
    set_property address_offset 0x00C                          $reg
    set_property size           32                             $reg

# Set the IP registers of the core
{scalar_regs}

{memory_ptr_regs}

set_property slave_memory_map_ref "s_axi_control" [::ipx::get_bus_interfaces -of $core "s_axi_control"]

# Set the final project properties
set_property xpm_libraries             {{XPM_CDC XPM_MEMORY XPM_FIFO}} $core
set_property sdx_kernel                true                          $core
set_property sdx_kernel_type           rtl                           $core
set_property supported_families        {{ }}                           $core
set_property auto_family_support_level level_2                       $core

# Save and close the project
ipx::create_xgui_files       $core
ipx::update_checksums        $core
ipx::check_integrity -kernel $core
ipx::save_core               $core
close_project

#
# Package the kernel
#
package_xo -xo_path ${{xoname}} -kernel_name $kernel_name -ip_directory $pkg_dir
'''.format(bus_clks=bus_clks,
        ip_cores=ip_cores,
        scalar_regs=scalar_regs,
        memory_ptr_regs=memory_ptr_regs)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Script for generating package tcl script')

    parser.add_argument('config', nargs=1, help='The config file describing the core')
    parser.add_argument('-o', '--output', help='The output path for the resulting tcl script', metavar='<file>', nargs=1, default=['package_kernel.tcl'])
    parser.add_argument('-f', '--force', help='Toggles whether output file should be overwritten', action='store_true')

    args = parser.parse_args()

    if not os.path.exists(args.config[0]):
        print (f'Error, {args.config} does not exist')
        quit(1)
    with open(args.config[0], 'r') as f:
        config = json.load(f)

    bus_clks = ''
    for name in config['buses']:
        bus_clks += bus_clk(name)

    ip_cores = ''
    for name, info in config['ip_cores'].items():
        ip_cores += create(name, info['vendor'], info['version'], info['module_name'])
        ip_cores += set_params(info['params'], info['module_name'])

    addr = 0x10
    scalars = ''
    for name, size in config['params']['scalars'].items():
        scalars += scalar_reg(name, addr, size//8)
        addr += size//8 + 4

    memory_ptrs = ''
    for name, bus_name in config['params']['memory'].items():
        memory_ptrs += memory_ptr_reg(name, addr, bus_name)
        addr += 8 + 4

    script_str = package_script(bus_clks, ip_cores, scalars, memory_ptrs)

    if not args.force and os.path.exists(args.output[0]):
        print (f'Error, "{args.output[0]}" already exists. Add -f flag to overwrite')
        quit(1)
    with open(args.output[0], 'w') as f:
        f.write(script_str)

