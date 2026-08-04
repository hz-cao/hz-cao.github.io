set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir "build/perf/project/loongson_perf.xpr"]
set synth_run [get_runs synth_1]
puts "AUTO_INCREMENTAL_VALUE=[get_property AUTO_INCREMENTAL_CHECKPOINT $synth_run]"
report_property $synth_run
exit 0
