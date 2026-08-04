set script_dir [file dirname [file normalize [info script]]]
set TEST_MODE perf
set PROJECT_PATH [file join $script_dir "build/perf/project"]
set report_dir [file join $script_dir "build/perf/reports"]

set_param general.maxThreads 1
source [file join $script_dir "create_project.tcl"]
file mkdir $report_dir

set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
launch_runs synth_1 -jobs 1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "SAFE_SYNTH_STATUS=$synth_status"
if {![string match "*Complete*" $synth_status]} {
    exit 1
}

launch_runs impl_1 -to_step place_design -scripts_only
set generated_script [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top.tcl"]
if {![file exists $generated_script]} {
    error "Implementation script was not generated: $generated_script"
}
puts "SAFE_IMPL_SCRIPT=$generated_script"
exit 0
