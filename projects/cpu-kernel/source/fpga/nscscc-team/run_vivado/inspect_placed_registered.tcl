set script_dir [file dirname [file normalize [info script]]]
set placed_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]

if {![file exists $placed_dcp]} {
    error "Placed checkpoint does not exist: $placed_dcp"
}
set_param general.maxThreads 1
file mkdir $report_dir
open_checkpoint $placed_dcp
report_timing_summary -delay_type max -report_unconstrained \
    -file [file join $report_dir "timing_summary_placed_registered.rpt"]
report_timing -delay_type max -max_paths 20 -sort_by group \
    -file [file join $report_dir "timing_paths_placed_registered.rpt"]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
puts "PLACED_REGISTERED_WNS=[get_property SLACK $setup_path]"
exit 0
