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
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
check_syntax
if { $::argc == 4 } {
    synth_design -top $top_file -rtl
} else {
    synth_design -top $top_file
}

close_project

