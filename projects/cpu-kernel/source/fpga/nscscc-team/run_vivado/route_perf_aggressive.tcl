set script_dir [file dirname [file normalize [info script]]]
set placed_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]
set output_dcp [file join $script_dir "build/perf/routed_aggressive.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]
set bit_dir [file join $script_dir "bitstreams"]

if {![file exists $placed_dcp]} {
    error "Placed checkpoint does not exist: $placed_dcp"
}

set_param general.maxThreads 1
file mkdir $report_dir
file mkdir $bit_dir
open_checkpoint $placed_dcp
route_design -directive AggressiveExplore

report_route_status -file [file join $report_dir "route_status_aggressive.rpt"]
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir "timing_summary_aggressive.rpt"]
set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
puts "AGGRESSIVE_ROUTE_WNS=$wns"
puts "AGGRESSIVE_ROUTE_WHS=$whs"

write_checkpoint -force $output_dcp
if {$wns < 0.0 || $whs < 0.0} {
    puts "AGGRESSIVE_ROUTE_TIMING_FAILED"
    exit 2
}

write_debug_probes -force [file join $bit_dir "soc_top_perf.ltx"]
write_bitstream -force [file join $bit_dir "soc_top_perf.bit"]
puts "AGGRESSIVE_ROUTE_BIT_OUTPUT=[file join $bit_dir soc_top_perf.bit]"
exit 0
