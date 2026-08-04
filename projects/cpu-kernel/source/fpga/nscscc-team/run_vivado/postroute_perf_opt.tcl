set script_dir [file dirname [file normalize [info script]]]
set input_dcp [file join $script_dir "build/perf/routed_safe.dcp"]
set output_dcp [file join $script_dir "build/perf/postroute_optimized.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]
set bit_dir [file join $script_dir "bitstreams"]

if {![file exists $input_dcp]} {
    error "Routed checkpoint does not exist: $input_dcp"
}
file mkdir $report_dir
file mkdir $bit_dir

set_param general.maxThreads 1
open_checkpoint $input_dcp
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore

report_route_status -file [file join $report_dir "route_status_postroute.rpt"]
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir "timing_summary_postroute.rpt"]
report_utilization -file [file join $report_dir "utilization_postroute.rpt"]

set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
puts "POSTROUTE_WNS=$wns"
puts "POSTROUTE_WHS=$whs"
write_checkpoint -force $output_dcp
if {$wns < 0.0 || $whs < 0.0} {
    puts "POSTROUTE_TIMING_FAILED"
    exit 2
}

write_debug_probes -force [file join $bit_dir "soc_top_perf.ltx"]
write_bitstream -force [file join $bit_dir "soc_top_perf.bit"]
puts "POSTROUTE_BIT_OUTPUT=[file join $bit_dir soc_top_perf.bit]"
exit 0
