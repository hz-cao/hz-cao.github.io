if {[llength $argv] < 1} {
    error "Usage: codex_vio_single_probe.tcl <switch_hex> ?duration_seconds?"
}

set script_dir [file dirname [file normalize [info script]]]
set switch_hex [string trimleft [string tolower [lindex $argv 0]] "0x"]
set duration 8
if {[llength $argv] >= 2} {
    set duration [lindex $argv 1]
}

open_hw_manager
connect_hw_server
open_hw_target
set hw_device [lindex [get_hw_devices -quiet] 0]
set probes_file [file join $script_dir "bitstreams/soc_top_perf.ltx"]
set_property PROBES.FILE $probes_file $hw_device
set_property FULL_PROBES.FILE $probes_file $hw_device
refresh_hw_device $hw_device
set vio_core [lindex [get_hw_vios -quiet] 0]
set num_data_probe [lindex [get_hw_probes -quiet num_data] 0]
if {$num_data_probe eq ""} {
    set num_data_probe [lindex [get_hw_probes -quiet vio_num_data] 0]
}

set_property OUTPUT_VALUE $switch_hex [get_hw_probes switch_vio]
commit_hw_vio [get_hw_probes switch_vio]
after 500
set_property OUTPUT_VALUE 0 [get_hw_probes resetn_vio]
commit_hw_vio [get_hw_probes resetn_vio]
after 500
set_property OUTPUT_VALUE 1 [get_hw_probes resetn_vio]
commit_hw_vio [get_hw_probes resetn_vio]

puts "SINGLE_PROBE_SWITCH=$switch_hex"
puts "time_ms,debug_wb_pc,num_data,led_rg0,led_rg1"
for {set elapsed 0} {$elapsed <= $duration * 1000} {incr elapsed 500} {
    refresh_hw_vio $vio_core
    set debug_pc [get_property INPUT_VALUE [get_hw_probes debug_wb_pc]]
    set num_data [get_property INPUT_VALUE $num_data_probe]
    set led0 [get_property INPUT_VALUE [get_hw_probes led_rg0_OBUF]]
    set led1 [get_property INPUT_VALUE [get_hw_probes led_rg1_OBUF]]
    puts "$elapsed,$debug_pc,$num_data,$led0,$led1"
    after 500
}
close_hw_manager
exit 0
