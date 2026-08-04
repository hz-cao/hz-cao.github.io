set script_dir [file dirname [file normalize [info script]]]
set placed_dcp [file join $script_dir "build/func/project/loongson_func.runs/impl_1/soc_top_placed.dcp"]
set output_dcp [file join $script_dir "build/func/routed_safe.dcp"]
set report_dir [file join $script_dir "build/func/reports"]
set bit_dir [file join $script_dir "bitstreams"]

if {![file exists $placed_dcp]} {
    error "Placed checkpoint does not exist: $placed_dcp"
}
file mkdir $report_dir
file mkdir $bit_dir

set_param general.maxThreads 1
open_checkpoint $placed_dcp
route_design -directive Explore

report_route_status -file [file join $report_dir "route_status_safe.rpt"]
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir "timing_summary_safe.rpt"]
report_utilization -file [file join $report_dir "utilization_safe.rpt"]

set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
puts "FUNC_SAFE_ROUTE_WNS=$wns"
puts "FUNC_SAFE_ROUTE_WHS=$whs"

write_checkpoint -force $output_dcp
if {$wns < 0.0 || $whs < 0.0} {
    puts "FUNC_SAFE_ROUTE_TIMING_FAILED"
    exit 2
}

write_debug_probes -force [file join $bit_dir "soc_top_func.ltx"]
write_bitstream -force [file join $bit_dir "soc_top_func.bit"]
puts "FUNC_SAFE_ROUTE_BIT_OUTPUT=[file join $bit_dir soc_top_func.bit]"
exit 0
