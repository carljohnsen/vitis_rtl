import argparse
import json
import os
def create(name, vendor, version, module_name):
    return f'create_ip -name {name} -vendor {vendor} -library ip -version {version} -module_name {module_name}\n'

def set_params(params, module_name):
    tmp = 'set_property -dict [list'
    for key, value in params.items():
        tmp += f' {key} {{{value}}}'
    tmp += '] [get_ips {module_name}]\n'
    return

def synth_script(ip_cores):
    synth_ip = 'synth_ip [get_ips]' if ip_cores != '' else ''
    return '''
if {{ !($::argc == 4 || $::argc == 5) }} {{
    puts "Error: Program \\"$::argv0\\" requires 4-5 arguments.\\n"
    puts "Usage: $::argv0 <srcdir> <top_file> <builddir> <include_dir> (elaborate)\\n"
    exit
}}

set src_dir     [lindex $::argv 0]
set top_file    [lindex $::argv 1]
set build_dir   [lindex $::argv 2]
set include_dir [lindex $::argv 3]

create_project batch_synthesis $build_dir/synthesis -part xcu250-figd2104-2L-e
set_property board_part xilinx.com:au250:part0:1.3 [current_project]
add_files [glob $src_dir/*.v $src_dir/*.sv $include_dir/*.v $include_dir/*.sv]
set_property top $top_file [current_fileset]
set_property top_file {{$src_dir/$top_file}} [current_fileset]
{ip_cores}
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
check_syntax
{synth_ip}
if {{ $::argc == 5 }} {{
    synth_design -top $top_file -rtl
}} else {{
    synth_design -top $top_file
}}

close_project
'''.format(ip_cores=ip_cores, synth_ip=synth_ip)

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

    ip_cores = ''
    for name, info in config['ip_cores'].items():
        ip_cores += create(name, info['vendor'], info['version'], info['module_name'])
        ip_cores += set_params(info['params'], info['module_name'])

    script_str = synth_script(ip_cores)

    if not args.force and os.path.exists(args.output[0]):
        print (f'Error, "{args.output[0]}" already exists. Add -f flag to overwrite')
        quit(1)
    with open(args.output[0], 'w') as f:
        f.write(script_str)
