if { !($::argc == 4 || $::argc == 5) } {
    puts "Error: Program \"$::argv0\" requires 2-3 arguments.\n"
    puts "Usage: $::argv0 <srcdir> <top_file> <builddir> <include_dir> (elaborate)\n"
    exit
}

set src_dir     [lindex $::argv 0]
set top_file    [lindex $::argv 1]
set build_dir   [lindex $::argv 2]
set include_dir [lindex $::argv 3]

create_project batch_synthesis_test $build_dir/synthesis_test -part xcu250-figd2104-2L-e
set_property board_part xilinx.com:au250:part0:1.3 [current_project]
add_files [glob $src_dir/*.v $src_dir/*.sv $include_dir/*.v $include_dir/*.sv]

create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name floating_point_0
set_property -dict [list CONFIG.Add_Sub_Value {Add} CONFIG.Has_ARESETn {true} CONFIG.Has_A_TLAST {true} CONFIG.Has_A_TUSER {false} CONFIG.Has_B_TLAST {true} CONFIG.Has_B_TUSER {false} CONFIG.RESULT_TLAST_Behv {OR_all_TLASTs}] [get_ips floating_point_0]

set_property top $top_file [current_fileset]
set_property top_file {$src_dir/$top_file} [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
check_syntax
synth_ip [get_ips]
if { $::argc == 5 } {
    synth_design -top $top_file -rtl
} else {
    synth_design -top $top_file
}
report_methodology -checks {ULMTCS-2 ULMTCS-1 XDCH-2 XDCH-1 XDCC-8 XDCC-7 XDCC-6 XDCC-5 XDCC-4 XDCC-3 XDCC-2 XDCC-1 XDCB-6 XDCB-5 XDCB-4 XDCB-3 XDCB-2 XDCB-1 CLKC-77 CLKC-76 CLKC-54 CLKC-53 CLKC-52 CLKC-51 CLKC-48 CLKC-47 CLKC-58 CLKC-44 CLKC-34 CLKC-17 CLKC-13 CLKC-57 CLKC-43 CLKC-33 CLKC-16 CLKC-12 CLKC-56 CLKC-42 CLKC-40 CLKC-32 CLKC-30 CLKC-28 CLKC-26 CLKC-24 CLKC-22 CLKC-15 CLKC-11 CLKC-55 CLKC-41 CLKC-39 CLKC-31 CLKC-29 CLKC-27 CLKC-25 CLKC-23 CLKC-21 CLKC-14 CLKC-10 CLKC-8 CLKC-7 CLKC-6 CLKC-78 CLKC-9 CLKC-5 CLKC-38 CLKC-37 CLKC-36 CLKC-35 CLKC-4 CLKC-20 CLKC-63 CLKC-19 CLKC-18 CLKC-3 CLKC-2 CLKC-1 HPDR-1 BLICHK-3 RRRS-1 RROR-1 ROAS-1 RMOR-1 RMIR-1 RFTL-1 RFRC-1 RFRA-1 RFFI-1 RFFH-1 RFCF-1 RCCL-1 RCBG-1 RAMP-1 RAMF-1 RAMD-1 RAKN-1}
report_drc -ruledecks {default}

close_project

