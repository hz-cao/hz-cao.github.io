if {[llength $argv] < 2} {
    error "Usage: run_single_board_test.tcl <program.bin> <switch_hex> ?timeout_ms?"
}

set script_dir [file dirname [file normalize [info script]]]
set bin_path [file normalize [lindex $argv 0]]
set switch_hex [string trimleft [string tolower [lindex $argv 1]] "0x"]
set timeout_ms 15000
if {[llength $argv] >= 3} {
    set timeout_ms [lindex $argv 2]
}
if {![file exists $bin_path]} {
    error "Program does not exist: $bin_path"
}

open_hw_manager
if {[catch {connect_hw_server} hw_server_msg]} {
    if {[string first "before making a new one" $hw_server_msg] < 0 &&
        [string first "already" [string tolower $hw_server_msg]] < 0} {
        error $hw_server_msg
    }
}
if {[catch {open_hw_target} hw_target_msg]} {
    if {[string first "already" [string tolower $hw_target_msg]] < 0} {
        error $hw_target_msg
    }
}

set hw_device [lindex [get_hw_devices -quiet] 0]
set probes_file [file join $script_dir "bitstreams/soc_top_perf.ltx"]
set bit_file [file join $script_dir "bitstreams/soc_top_perf.bit"]
set_property PROBES.FILE $probes_file $hw_device
set_property FULL_PROBES.FILE $probes_file $hw_device
set_property PROGRAM.FILE $bit_file $hw_device
program_hw_devices $hw_device
refresh_hw_device $hw_device

set vio_core [lindex [get_hw_vios -quiet] 0]
set num_data_probe [lindex [get_hw_probes -quiet num_data] 0]
if {$num_data_probe eq ""} {
    set num_data_probe [lindex [get_hw_probes -quiet vio_num_data] 0]
}
if {$vio_core eq "" || $num_data_probe eq ""} {
    error "VIO probes were not found; check the matching LTX file."
}

source [file join $script_dir "jtag_axi_master.tcl"]

set_property OUTPUT_VALUE $switch_hex [get_hw_probes switch_vio]
commit_hw_vio [get_hw_probes switch_vio]
after 500
set_property OUTPUT_VALUE 0 [get_hw_probes resetn_vio]
commit_hw_vio [get_hw_probes resetn_vio]
after 500
set_property OUTPUT_VALUE 1 [get_hw_probes resetn_vio]
commit_hw_vio [get_hw_probes resetn_vio]

puts "SINGLE_TEST_PROGRAM=$bin_path"
puts "SINGLE_TEST_SWITCH=$switch_hex"
puts "time_ms,debug_wb_pc,num_data,led_rg0,led_rg1"
for {set elapsed 0} {$elapsed <= $timeout_ms} {incr elapsed 100} {
    refresh_hw_vio $vio_core
    set debug_pc [get_property INPUT_VALUE [get_hw_probes debug_wb_pc]]
    set num_data [get_property INPUT_VALUE $num_data_probe]
    set led0 [get_property INPUT_VALUE [get_hw_probes led_rg0_OBUF]]
    set led1 [get_property INPUT_VALUE [get_hw_probes led_rg1_OBUF]]
    puts "$elapsed,$debug_pc,$num_data,$led0,$led1"
    if {$led0 ne "0" && $led1 ne "0"} {
        puts "SINGLE_TEST_RESULT=$led0"
        close_hw_manager
        exit 0
    }
    after 100
}

puts "SINGLE_TEST_RESULT=TIMEOUT"
close_hw_manager
exit 2
