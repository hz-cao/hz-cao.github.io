set script_dir [file dirname [file normalize [info script]]]
set TEST_MODE func
set PROJECT_PATH [file join $script_dir "build/func/project"]
set report_dir [file join $script_dir "build/func/reports"]

set_param general.maxThreads 1
source [file join $script_dir "create_project.tcl"]
file mkdir $report_dir

set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
launch_runs synth_1 -jobs 1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "FUNC_SAFE_SYNTH_STATUS=$synth_status"
if {![string match "*Complete*" $synth_status]} {
    exit 1
}

# Generate the implementation Tcl without keeping the project process alive
# during opt/place. The next script runs those steps in one bounded process.
launch_runs impl_1 -to_step place_design -scripts_only
set generated_script [file join $PROJECT_PATH "loongson_func.runs/impl_1/soc_top.tcl"]
if {![file exists $generated_script]} {
    error "Implementation script was not generated: $generated_script"
}
puts "FUNC_IMPL_SCRIPT=$generated_script"
exit 0
