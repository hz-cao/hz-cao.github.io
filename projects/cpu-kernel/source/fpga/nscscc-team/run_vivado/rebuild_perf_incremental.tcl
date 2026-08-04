set script_dir [file dirname [file normalize [info script]]]
set project_path [file join $script_dir "build/perf/project/loongson_perf.xpr"]
set incremental_dcp [file join $script_dir "build/perf/incremental_prev.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]
set TEST_MODE perf
set PROJECT_PATH [file join $script_dir "build/perf/project"]
source [file join $script_dir "create_project.tcl"]
set_property incremental_checkpoint $incremental_dcp [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
set run_status [get_property STATUS [get_runs impl_1]]
puts "IMPL_STATUS=$run_status"
if {![string match "*Complete*" $run_status]} {
    exit 1
}
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $report_dir "timing_summary.rpt"]
report_utilization -file [file join $report_dir "utilization.rpt"]
set impl_dir [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1"]
file copy -force [file join $impl_dir "soc_top.bit"] \
    [file join $script_dir "bitstreams/soc_top_perf.bit"]
file copy -force [file join $impl_dir "soc_top.ltx"] \
    [file join $script_dir "bitstreams/soc_top_perf.ltx"]
puts "BIT_OUTPUT=[file join $script_dir bitstreams/soc_top_perf.bit]"
exit 0
