set script_dir [file dirname [file normalize [info script]]]
set opt_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_opt.dcp"]
set placed_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]

if {![file exists $opt_dcp]} {
    error "Optimized checkpoint does not exist: $opt_dcp"
}

set_param general.maxThreads 1
file mkdir $report_dir
open_checkpoint $opt_dcp
if {[llength [get_debug_cores -quiet]] > 0} {
    implement_debug_core
}
place_design -directive Explore
report_timing_summary -delay_type max -report_unconstrained \
    -file [file join $report_dir "timing_summary_placed_adaptive.rpt"]
report_utilization -file [file join $report_dir "utilization_placed_adaptive.rpt"]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
puts "DIRECT_PLACE_WNS=[get_property SLACK $setup_path]"
write_checkpoint -force $placed_dcp
puts "DIRECT_PLACE_DCP=$placed_dcp"
exit 0
