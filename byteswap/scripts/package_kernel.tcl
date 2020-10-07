#
# Argument parsing
#
if { $::argc != 5 } {
    puts "Error: Program \"$::argv0\" requires 5 arguments.\n"
    puts "Usage: $::argv0 <xoname> <kernel_name> <build_dir> <rtl_src_dir> <include_dir>\n"
    exit
}
# TODO muligvis have memory bus navn?
set xoname      [lindex $::argv 0]
set kernel_name [lindex $::argv 1]
set build_dir   [lindex $::argv 2]
set src_dir     [lindex $::argv 3]
set include_dir [lindex $::argv 4]

set tmp_dir "$build_dir/tmp"
set pkg_dir "$build_dir/pkg"

#
# Build the kernel
#
create_project kernel_packing $tmp_dir
add_files [glob $src_dir/*.v $src_dir/*.sv $include_dir/*.v $include_dir/*.sv]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -root_dir $pkg_dir -vendor xilinx.com -library RTLKernel -taxonomy /KernelIP -import_files -set_current false
ipx::unload_core $pkg_dir/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_project -directory $pkg_dir $pkg_dir/component.xml

set core [ipx::current_core]

set_property core_revision 2 $core
foreach up [ipx::get_user_parameters] {
    ipx::remove_user_parameter [get_property NAME $up] $core
}
ipx::associate_bus_interfaces -busif m00_axi -clock ap_clk $core
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk $core

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
    set_property description          "Control signals"                             $reg
    set_property address_offset       0x000                                         $reg
    set_property size                 32                                            $reg
set field [ipx::add_field AP_START $reg]
    set_property ACCESS               {read-write}                                  $field
    set_property BIT_OFFSET           {0}                                           $field
    set_property BIT_WIDTH            {1}                                           $field
    set_property DESCRIPTION          {Control signal Register for 'ap_start'.}     $field
    set_property MODIFIED_WRITE_VALUE {modify}                                      $field
set field [ipx::add_field AP_DONE $reg]
    set_property ACCESS               {read-only}                                   $field
    set_property BIT_OFFSET           {1}                                           $field
    set_property BIT_WIDTH            {1}                                           $field
    set_property DESCRIPTION          {Control signal Register for 'ap_done'.}      $field
    set_property READ_ACTION          {modify}                                      $field
set field [ipx::add_field AP_IDLE $reg]
    set_property ACCESS               {read-only}                                   $field
    set_property BIT_OFFSET           {2}                                           $field
    set_property BIT_WIDTH            {1}                                           $field
    set_property DESCRIPTION          {Control signal Register for 'ap_idle'.}      $field
    set_property READ_ACTION          {modify}                                      $field
set field [ipx::add_field AP_READY $reg]
    set_property ACCESS               {read-only}                                   $field
    set_property BIT_OFFSET           {3}                                           $field
    set_property BIT_WIDTH            {1}                                           $field
    set_property DESCRIPTION          {Control signal Register for 'ap_ready'.}     $field
    set_property READ_ACTION          {modify}                                      $field
set field [ipx::add_field AP_RESERVED_1 $reg]
    set_property ACCESS               {read-only}                                   $field
    set_property BIT_OFFSET           {4}                                           $field
    set_property BIT_WIDTH            {3}                                           $field
    set_property DESCRIPTION          {Reserved.  0s on read.}                      $field
    set_property READ_ACTION          {modify}                                      $field
set field [ipx::add_field AUTO_RESTART $reg]
    set_property ACCESS               {read-write}                                  $field
    set_property BIT_OFFSET           {7}                                           $field
    set_property BIT_WIDTH            {1}                                           $field
    set_property DESCRIPTION          {Control signal Register for 'auto_restart'.} $field
    set_property MODIFIED_WRITE_VALUE {modify}                                      $field
set field [ipx::add_field RESERVED_2 $reg]
    set_property ACCESS               {read-only}                                   $field
    set_property BIT_OFFSET           {8}                                           $field
    set_property BIT_WIDTH            {24}                                          $field
    set_property DESCRIPTION          {Reserved.  0s on read.}                      $field
    set_property READ_ACTION          {modify}                                      $field

# Set the interrupt registers
set reg [::ipx::add_register "GIER" $addr_block]
    set_property description    "Global Interrupt Enable Register"        $reg
    set_property address_offset 0x004                                     $reg
    set_property size           32                                        $reg
set reg [::ipx::add_register "IP_IER" $addr_block]
    set_property description    "IP Interrupt Enable Register"            $reg
    set_property address_offset 0x008                                     $reg
    set_property size           32                                        $reg
set reg [::ipx::add_register "IP_ISR" $addr_block]
    set_property description    "IP Interrupt Status Register"            $reg
    set_property address_offset 0x00C                                     $reg
    set_property size           32                                        $reg

# Set the IP registers of the core
set reg [::ipx::add_register -quiet "scalar00" $addr_block]
    set_property description    "Kernel parameter scalar00"               $reg
    set_property address_offset 0x010                                     $reg
    set_property size           [expr {4*8}]                              $reg
set reg [::ipx::add_register -quiet "a" $addr_block]
    set_property description    "Kernel parameter axi00"                  $reg
    set_property address_offset 0x018                                     $reg
    set_property size           [expr {8*8}]                              $reg
    set regparam [::ipx::add_register_parameter -quiet {ASSOCIATED_BUSIF} $reg]
    set_property value          m00_axi                                $regparam

set_property slave_memory_map_ref "s_axi_control" [::ipx::get_bus_interfaces -of $core "s_axi_control"]

# Set the final project properties
set_property xpm_libraries             {XPM_CDC XPM_MEMORY XPM_FIFO} $core
set_property sdx_kernel                true                          $core
set_property sdx_kernel_type           rtl                           $core
set_property supported_families        { }                           $core
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
package_xo -xo_path ${xoname} -kernel_name $kernel_name -ip_directory $pkg_dir
