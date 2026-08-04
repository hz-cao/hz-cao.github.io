set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir "build/perf/project/loongson_perf.xpr"]
set report_dir [file join $script_dir "build/perf/reports"]
set bit_dir [file join $script_dir "bitstreams"]

if {![file exists $project_file]} {
    error "Performance project does not exist: $project_file"
}
file mkdir $report_dir
file mkdir $bit_dir

open_project $project_file
set impl_run [get_runs impl_1]
set initial_status [get_property STATUS $impl_run]
puts "IMPL_INITIAL_STATUS=$initial_status"

if {[string match "*Running*" $initial_status]} {
    catch {stop_runs impl_1}
    reset_run impl_1
} elseif {![string match "*Complete*" $initial_status]} {
    reset_run impl_1
}

# Vivado 2023.2 can crash in the incremental placer after substantial CPU
# netlist changes. Reuse the completed synthesis run, but place and route the
# implementation from scratch for a deterministic final result.
reset_property incremental_checkpoint $impl_run
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set final_status [get_property STATUS $impl_run]
puts "IMPL_FINAL_STATUS=$final_status"
if {![string match "*Complete*" $final_status]} {
    exit 1
}

open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir "timing_summary_storeset.rpt"]
report_utilization -file [file join $report_dir "utilization_storeset.rpt"]

set setup_path [get_timing_paths -delay_type max -max_paths 1]
set hold_path [get_timing_paths -delay_type min -max_paths 1]
set wns [get_property SLACK $setup_path]
set whs [get_property SLACK $hold_path]
puts "FINAL_WNS=$wns"
puts "FINAL_WHS=$whs"
if {$wns < 0.0 || $whs < 0.0} {
    puts "FINAL_TIMING_FAILED"
    exit 2
}

set impl_dir [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1"]
file copy -force [file join $impl_dir "soc_top.bit"] \
    [file join $bit_dir "soc_top_perf.bit"]
file copy -force [file join $impl_dir "soc_top.ltx"] \
    [file join $bit_dir "soc_top_perf.ltx"]
puts "BIT_OUTPUT=[file join $bit_dir soc_top_perf.bit]"
exit 0
