set script_dir [file dirname [file normalize [info script]]]
set_param general.maxThreads 1
set project_file [file join $script_dir "build/sim_func/project/loongson_func.xpr"]
set source_program [file normalize [file join $script_dir "../../../software/examples/nscscc_func/obj/main.bin"]]
set simulation_program [file join $script_dir "build/sim_func/inst_data.bin"]
set config_path [file normalize [file join $script_dir "../../../chip/soc_demo/nscscc-team/soc_config.vh"]]

if {![file exists $project_file]} {
    error "Function simulation project does not exist: $project_file"
}
if {![file exists $source_program]} {
    error "Function test program does not exist: $source_program"
}

file copy -force $source_program $simulation_program
source [file join $script_dir "test_mode.tcl"]
configure_test_mode $config_path func
open_project $project_file
launch_simulation
run all
close_sim
exit 0
