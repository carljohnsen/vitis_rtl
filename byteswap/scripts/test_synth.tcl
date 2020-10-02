if { !($::argc == 3 || $::argc == 4) } {
    puts "Error: Program \"$::argv0\" requires 2-3 arguments.\n"
    puts "Usage: $::argv0 <srcdir> <top_file> <builddir> (elaborate)\n"
    exit
}

set src_dir   [lindex $::argv 0]
set top_file  [lindex $::argv 1]
set build_dir [lindex $::argv 2]

create_project batch_synthesis_test $build_dir/synthesis_test -part xcu250-figd2104-2L-e
set_property board_part xilinx.com:au250:part0:1.3 [current_project]
add_files [glob $src_dir/*.v $src_dir/*.sv]
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
if { $::argc == 4 } {
    synth_design -top $top_file -rtl
} else {
    synth_design -top $top_file
}

close_project

