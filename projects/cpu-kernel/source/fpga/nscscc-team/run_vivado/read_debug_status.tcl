set script_dir [file dirname [file normalize [info script]]]
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

refresh_hw_vio $vio_core
set original_switch [get_property OUTPUT_VALUE [get_hw_probes switch_vio]]
set stalled_pc [get_property INPUT_VALUE [get_hw_probes debug_wb_pc]]
puts "STALLED_SWITCH=$original_switch"
puts "STALLED_PC=$stalled_pc"

set_property OUTPUT_VALUE a0 [get_hw_probes switch_vio]
commit_hw_vio [get_hw_probes switch_vio]
after 100
refresh_hw_vio $vio_core
set status0 [get_property INPUT_VALUE [get_hw_probes debug_wb_pc]]
set status1 [get_property INPUT_VALUE $num_data_probe]
puts "DEBUG_STATUS0=$status0"
puts "DEBUG_STATUS1=$status1"

set_property OUTPUT_VALUE $original_switch [get_hw_probes switch_vio]
commit_hw_vio [get_hw_probes switch_vio]
close_hw_manager
exit 0
