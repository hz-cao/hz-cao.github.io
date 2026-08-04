if {[llength $argv] < 1} {
    error "Usage: simulate.tcl <func|perf> ?performance_benchmark? ?switch_hex? ?duration_ns?"
}

set TEST_MODE [lindex $argv 0]
if {$TEST_MODE ni {func perf}} {
    error "Simulation mode must be func or perf"
}

set benchmark stream_copy
if {[llength $argv] >= 2} {
    set benchmark [lindex $argv 1]
}

set switch_hex ff
if {[llength $argv] >= 3} {
    set switch_hex [string trimleft [string tolower [lindex $argv 2]] "0x"]
    if {![regexp {^[0-9a-f]{1,2}$} $switch_hex]} {
        error "switch_hex must be an 8-bit hexadecimal value"
    }
}

set duration_ns 0
if {[llength $argv] >= 4} {
    set duration_ns [lindex $argv 3]
    if {![string is integer -strict $duration_ns] || $duration_ns <= 0} {
        error "duration_ns must be a positive integer"
    }
}

set script_dir [file dirname [file normalize [info script]]]
set package_root [file normalize [file join $script_dir "../../.."]]
set PROJECT_PATH [file normalize [file join $script_dir "build/sim_$TEST_MODE/project"]]
source [file join $script_dir "create_project.tcl"]
set sim_defines [list SYNTHESIS [format "SIM_SWITCH=8'h%02s" $switch_hex]]
set_property verilog_define $sim_defines [get_filesets sim_1]

if {$TEST_MODE eq "func"} {
    set program_file [file join $package_root "software/examples/nscscc_func/obj/main.bin"]
} else {
    set program_file [file join $package_root "software/examples/nscscc_perf/obj/$benchmark/inst_data.bin"]
}
if {![file exists $program_file]} {
    error "Simulation program does not exist: $program_file"
}

set simulation_program [file join [file dirname $PROJECT_PATH] "inst_data.bin"]
file copy -force $program_file $simulation_program
puts "SIM_PROGRAM=$program_file"

launch_simulation
if {$TEST_MODE eq "perf" && $benchmark eq "allbench"} {
    set sim_switch_path "/tb_top/u_soc_top/switch"
    add_force -radix hex $sim_switch_path $switch_hex
    puts "SIM_FORCED_SWITCH=$switch_hex"
}
if {$duration_ns > 0} {
    run ${duration_ns}ns
} else {
    run all
}
set core_path "/tb_top/u_soc_top/u_cpu/inner_cpu/core_0"
foreach {label signal_name} {
    LSQ_SPECULATIVE_LOADS lsq_speculative_load_count
    LSQ_ORDERING_VIOLATIONS lsq_ordering_violation_count
} {
    if {![catch {get_value -radix unsigned "$core_path/$signal_name"} signal_value]} {
        puts "$label=$signal_value"
    }
}
if {$duration_ns > 0} {
    puts "SIM_DEBUG_SNAPSHOT_BEGIN"
    foreach {label signal_name radix} {
        DEBUG_WB_PC debug0_wb_pc hex
        ROB_HEAD rob_head unsigned
        ROB_TAIL rob_tail unsigned
        ROB_OCC rob_occ unsigned
        RS0_OCC rs_alu0_occ unsigned
        RS1_OCC rs_alu1_occ unsigned
        RS0_ISS_VALID rs_alu0_iss_valid unsigned
        RS0_ISS_PC rs_alu0_iss_pc hex
        RS0_ISS_ROB_ID rs_alu0_iss_rob_id unsigned
        RS0_ISS_ALLOWED rs_alu0_issue_allowed unsigned
        RS1_ISS_VALID rs_alu1_iss_valid unsigned
        RS1_ISS_PC rs_alu1_iss_pc hex
        RS1_ISS_ROB_ID rs_alu1_iss_rob_id unsigned
        RS1_ISS_ALLOWED rs_alu1_issue_allowed unsigned
        EX1_A_VALID EX1_a_valid unsigned
        EX1_A_PC EX1_a_pc hex
        EX1_B_VALID EX1_b_valid unsigned
        EX1_B_PC EX1_b_pc hex
        EX2_A_VALID EX2_a_valid unsigned
        EX2_A_PC EX2_a_pc hex
        EX2_B_VALID EX2_b_valid unsigned
        EX2_B_PC EX2_b_pc hex
        WB_A_VALID WB_a_valid unsigned
        WB_A_PC WB_a_pc hex
        WB_B_VALID WB_b_valid unsigned
        WB_B_PC WB_b_pc hex
        LSU_VALID lsu_valid unsigned
        LSU_READY lsu_ready unsigned
        LSU_OK lsu_ok unsigned
        EX1_STALL ex1_stall unsigned
        EX2_STALL ex2_stall unsigned
        RENAME_RECOVERING rename_recovering unsigned
        UNRESOLVED_BRANCH unresolved_branch unsigned
    } {
        if {![catch {get_value -radix $radix "$core_path/$signal_name"} value]} {
            puts "$label=$value"
        }
    }
    puts "SIM_DEBUG_SNAPSHOT_END"
}
close_sim
puts "SIMULATION_COMPLETED=$TEST_MODE"
exit 0
