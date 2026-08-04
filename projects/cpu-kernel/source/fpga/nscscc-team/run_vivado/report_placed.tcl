set script_dir [file dirname [file normalize [info script]]]
set dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]
set report_dir [file join $script_dir "build/perf/reports"]
file mkdir $report_dir
open_checkpoint $dcp
report_timing_summary -delay_type max -report_unconstrained -file [file join $report_dir "timing_placed_summary.rpt"]
report_timing -delay_type max -max_paths 30 -nworst 3 -path_type full_clock_expanded -file [file join $report_dir "timing_placed_paths.rpt"]
report_utilization -file [file join $report_dir "utilization_placed.rpt"]
puts "PLACED_REPORTS=$report_dir"
exit 0
