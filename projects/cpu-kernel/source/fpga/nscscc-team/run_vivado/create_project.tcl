# Portable ChipLab nscscc-team project creation script for Vivado 2023.2.
# In the Vivado Tcl console:
#   set TEST_MODE perf
#   source create_project.tcl

set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

if {![info exists TEST_MODE]} {
    set TEST_MODE perf
}
if {$TEST_MODE ni {func perf}} {
    error "TEST_MODE must be func or perf"
}
if {![info exists PROJECT_PATH]} {
    set PROJECT_PATH [file normalize [file join $script_dir "build/$TEST_MODE/project"]]
}

source [file join $script_dir "test_mode.tcl"]

set package_root [file normalize [file join $script_dir "../../.."]]
set soc_dir [file join $package_root "chip/soc_demo/nscscc-team"]
set cpu_dir [file join $package_root "IP/myCPU"]
set config_path [file join $soc_dir "soc_config.vh"]
configure_test_mode $config_path $TEST_MODE

# IP output products are regenerated for each project. Removing them before
# the recursive source scan prevents OOC encrypted HDL from being added to
# sources_1 as ordinary top-level RTL on a later build.
foreach ip_gen_dir [glob -nocomplain [file join $soc_dir "xilinx_ip/*/gen"]] {
    file delete -force $ip_gen_dir
}

if {[llength [get_projects -quiet]] > 0} {
    close_project
}
file delete -force $PROJECT_PATH
file mkdir [file dirname $PROJECT_PATH]

set project_name "loongson_$TEST_MODE"
create_project -force $project_name $PROJECT_PATH -part xc7a200tfbg676-2

add_files -scan_for_includes $soc_dir
add_files -scan_for_includes [file join $package_root "IP/AXI_SRAM_BRIDGE"]
add_files -scan_for_includes [file join $package_root "IP/APB_DEV/URT"]
add_files -norecurse [file join $package_root "IP/APB_DEV/apb_dev_top_no_nand.v"]
add_files -norecurse [file join $package_root "IP/APB_DEV/apb_mux2.v"]
add_files -norecurse [file join $package_root "IP/AMBA/axi2apb.v"]

# Only the official openLA500 root RTL is needed by ChipLab. The optional
# standalone SRAM IP containers under IP/myCPU/IP are intentionally excluded;
# the team SoC supplies synthesizable cache SRAM wrappers.
set cpu_sources [concat \
    [glob -nocomplain [file join $cpu_dir "*.v"]] \
    [glob -nocomplain [file join $cpu_dir "*.sv"]] \
    [glob -nocomplain [file join $cpu_dir "*.h"]] \
    [glob -nocomplain [file join $cpu_dir "*.vh"]]]
add_files -norecurse $cpu_sources

add_files -quiet [glob -nocomplain [file join $soc_dir "xilinx_ip/*/*.xci"]]
add_files -fileset sim_1 [file join $package_root "fpga/nscscc-team/testbench"]
add_files -fileset constrs_1 -quiet [file join $package_root "fpga/nscscc-team/constraints"]

upgrade_ip -quiet [get_ips]
generate_target -force synthesis [get_ips]
foreach ip_name {clk_pll mig_axi_32} {
    set ip_obj [get_ips -quiet $ip_name]
    if {[llength $ip_obj] > 0} {
        generate_target -force implementation $ip_obj
    }
}
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

set_property top soc_top [get_filesets sources_1]
set_property top tb_top [get_filesets sim_1]
set_property verilog_define {SYNTHESIS} [get_filesets sim_1]
# Batch regressions only need console pass/fail and counters. Full hierarchy
# WDB logging makes the 0.5 MB performance image initialization prohibitively slow.
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_Explore [get_runs impl_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "PROJECT_CREATED=[file join $PROJECT_PATH ${project_name}.xpr]"
puts "TEST_MODE=$TEST_MODE"
