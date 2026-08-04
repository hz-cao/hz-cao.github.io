if {[llength $argv] < 1} {
    error "Usage: vivado -mode batch -source codex_hw_probe.tcl -tclargs <ltx_file> ?seconds?"
}

set probes_file [file normalize [lindex $argv 0]]
set duration 20
if {[llength $argv] >= 2} {
    set duration [lindex $argv 1]
}

open_hw_manager
connect_hw_server
open_hw_target

set hw_device [lindex [get_hw_devices -quiet] 0]
if {$hw_device eq ""} {
    error "No FPGA device found on the hardware target."
}

set_property PROBES.FILE $probes_file $hw_device
set_property FULL_PROBES.FILE $probes_file $hw_device
refresh_hw_device $hw_device

set vio_core [lindex [get_hw_vios -quiet] 0]
if {$vio_core eq ""} {
    error "No VIO core found. Check the .ltx file."
}
set num_data_probe [lindex [get_hw_probes -quiet num_data] 0]
if {$num_data_probe eq ""} {
    set num_data_probe [lindex [get_hw_probes -quiet vio_num_data] 0]
}

set resetn_value [get_property OUTPUT_VALUE [get_hw_probes resetn_vio]]
set switch_value [get_property OUTPUT_VALUE [get_hw_probes switch_vio]]
puts "VIO outputs: resetn_vio=$resetn_value switch_vio=$switch_value"
refresh_hw_vio $vio_core
puts "VIO_SNAPSHOT_BEGIN"
foreach probe [get_hw_probes -of_objects $vio_core] {
    set probe_name [get_property NAME $probe]
    if {![catch {get_property INPUT_VALUE $probe} probe_value] && $probe_value ne ""} {
        puts "$probe_name=$probe_value"
    }
}
puts "VIO_SNAPSHOT_END"
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
