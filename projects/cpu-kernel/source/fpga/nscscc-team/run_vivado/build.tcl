if {[llength $argv] < 1} {
    error "Usage: build.tcl <func|perf> ?project|synth|bitstream?"
}

set TEST_MODE [lindex $argv 0]
set BUILD_ACTION bitstream
if {[llength $argv] >= 2} {
    set BUILD_ACTION [lindex $argv 1]
}
if {$BUILD_ACTION ni {project synth bitstream}} {
    error "BUILD_ACTION must be project, synth, or bitstream"
}

set script_dir [file dirname [file normalize [info script]]]
set PROJECT_PATH [file normalize [file join $script_dir "build/$TEST_MODE/project"]]
source [file join $script_dir "create_project.tcl"]

if {$BUILD_ACTION eq "project"} {
    exit 0
}

set report_dir [file normalize [file join $script_dir "build/$TEST_MODE/reports"]]
file mkdir $report_dir

if {$BUILD_ACTION eq "synth"} {
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
    set run_status [get_property STATUS [get_runs synth_1]]
    puts "SYNTH_STATUS=$run_status"
    if {![string match "*Complete*" $run_status]} {
        exit 1
    }
    open_run synth_1
    report_utilization -file [file join $report_dir "utilization_synth.rpt"]
    exit 0
}

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

set project_name "loongson_$TEST_MODE"
set impl_dir [file join $PROJECT_PATH "${project_name}.runs/impl_1"]
set output_dir [file join $script_dir "bitstreams"]
file mkdir $output_dir

set bit_src [file join $impl_dir "soc_top.bit"]
set ltx_src [file join $impl_dir "soc_top.ltx"]
if {![file exists $bit_src] || ![file exists $ltx_src]} {
    error "The implementation did not produce a matching soc_top.bit/soc_top.ltx pair"
}
set bit_dst [file join $output_dir "soc_top_${TEST_MODE}.bit"]
set ltx_dst [file join $output_dir "soc_top_${TEST_MODE}.ltx"]
file copy -force $bit_src $bit_dst
file copy -force $ltx_src $ltx_dst
puts "BIT_OUTPUT=$bit_dst"
puts "LTX_OUTPUT=$ltx_dst"
exit 0
