set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir "build/perf/project/loongson_perf.xpr"]
set report_dir [file join $script_dir "build/perf/reports"]
set placed_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]

if {![file exists $project_file]} {
    error "Performance project does not exist: $project_file"
}

set_param general.maxThreads 1
open_project $project_file
set synth_status [get_property STATUS [get_runs synth_1]]
puts "IMPL_RESUME_SYNTH_STATUS=$synth_status"
if {![string match "*Complete*" $synth_status]} {
    error "Top-level synthesis is not complete"
}

catch {stop_runs impl_1}
reset_run impl_1
reset_property incremental_checkpoint [get_runs impl_1]
launch_runs impl_1 -to_step place_design -jobs 1
wait_on_run impl_1
puts "IMPL_RESUME_STATUS=[get_property STATUS [get_runs impl_1]]"
if {![file exists $placed_dcp]} {
    error "Placed checkpoint was not generated: $placed_dcp"
}

open_run impl_1
file mkdir $report_dir
report_timing_summary -delay_type max -report_unconstrained \
    -file [file join $report_dir "timing_summary_placed_adaptive.rpt"]
report_utilization -file [file join $report_dir "utilization_placed_adaptive.rpt"]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
puts "IMPL_RESUME_PLACED_WNS=[get_property SLACK $setup_path]"
puts "IMPL_RESUME_PLACED_DCP=$placed_dcp"
exit 0
