set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir "build/sim_perf/project/loongson_perf.xpr"]
if {![file exists $project_file]} {
    error "Performance simulation project does not exist: $project_file"
}

set duration_ns 30000000
if {[llength $argv] >= 1} {
    set duration_ns [lindex $argv 0]
}
set forced_switch ""
if {[llength $argv] >= 2} {
    set forced_switch [string trimleft [string tolower [lindex $argv 1]] "0x"]
    if {![regexp {^[0-9a-f]{1,2}$} $forced_switch]} {
        error "forced_switch must be an 8-bit hexadecimal value"
    }
}

open_project $project_file
launch_simulation
restart
if {$forced_switch ne ""} {
    add_force -radix hex "/tb_top/u_soc_top/switch" $forced_switch
    puts "SIM_FORCED_SWITCH=$forced_switch"
    puts "SIM_FORCED_SWITCH_VALUE=[get_value -radix hex /tb_top/u_soc_top/switch]"
}
run ${duration_ns}ns

set core_path "/tb_top/u_soc_top/u_cpu/inner_cpu/core_0"
puts "SIM_DEBUG_SNAPSHOT_BEGIN"
foreach {label signal_path radix} {
    TB_SWITCH /tb_top/switch hex
    SOC_SWITCH_FPGA /tb_top/u_soc_top/switch_fpga hex
    SOC_SWITCH_VIO /tb_top/u_soc_top/switch_vio hex
    SOC_VIRTUAL_FLAG /tb_top/u_soc_top/virtual_flag unsigned
    SOC_SWITCH /tb_top/u_soc_top/switch hex
    CPU_CYCLES /tb_top/codex_cpu_cycles unsigned
    RETIRED_INSTRUCTIONS /tb_top/codex_retired_instructions unsigned
    DUAL_RETIRE_CYCLES /tb_top/codex_dual_retire_cycles unsigned
} {
    if {![catch {get_value -radix $radix $signal_path} value]} {
        puts "$label=$value"
    }
}
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
    RENAME_FREE_READY rename_free_ready unsigned
	UNRESOLVED_BRANCH unresolved_branch unsigned
	PRF_READY_BITS u_prf/ready_bits hex
	LSQ_SPECULATIVE_LOADS lsq_speculative_load_count unsigned
	LSQ_ORDERING_VIOLATIONS lsq_ordering_violation_count unsigned
	IF_PC_START u_if_stage/pc_start hex
	IF_PC_START_SENT u_if_stage/pc_start_sent hex
	IF_PENDING_DATA u_if_stage/pending_data unsigned
	IF_IDLE_STATE u_if_stage/idle_state unsigned
	IF_ICACHE_REQ u_if_stage/icache_req unsigned
	IF_IBUF_READY ibuf_i_ready unsigned
	IF_OUTPUT_SIZE if_stage_output_size unsigned
	ICACHE_ADDR_OK icache_addr_ok unsigned
	ICACHE_DATA_OK icache_data_ok unsigned
} {
    if {![catch {get_value -radix $radix "$core_path/$signal_name"} value]} {
        puts "$label=$value"
    }
}
puts "ROB_ENTRIES_BEGIN"
for {set i 0} {$i < 32} {incr i} {
    set valid_path [format {%s/u_rob/e_valid[%d]} $core_path $i]
    if {![catch {get_value -radix unsigned $valid_path} valid] && $valid eq "1"} {
        set done [get_value -radix unsigned [format {%s/u_rob/e_done[%d]} $core_path $i]]
        set pc [get_value -radix hex [format {%s/u_rob/e_pc[%d]} $core_path $i]]
        set inst [get_value -radix hex [format {%s/u_rob/e_inst[%d]} $core_path $i]]
        puts "ROB_ENTRY=$i,$done,$pc,$inst"
    }
}
puts "ROB_ENTRIES_END"
foreach {rs_name rs_path} {RS0 u_rs_alu0 RS1 u_rs_alu1} {
    puts "${rs_name}_ENTRIES_BEGIN"
    for {set i 0} {$i < 8} {incr i} {
        set valid_path [format {%s/%s/e_valid[%d]} $core_path $rs_path $i]
        if {![catch {get_value -radix unsigned $valid_path} valid] && $valid eq "1"} {
            set pc [get_value -radix hex [format {%s/%s/e_pc[%d]} $core_path $rs_path $i]]
            set rob_id [get_value -radix unsigned [format {%s/%s/e_rob_id[%d]} $core_path $rs_path $i]]
            set src1_ready [get_value -radix unsigned [format {%s/%s/e_src1_ready[%d]} $core_path $rs_path $i]]
            set src2_ready [get_value -radix unsigned [format {%s/%s/e_src2_ready[%d]} $core_path $rs_path $i]]
            set src1_tag [get_value -radix unsigned [format {%s/%s/e_p_src1[%d]} $core_path $rs_path $i]]
            set src2_tag [get_value -radix unsigned [format {%s/%s/e_p_src2[%d]} $core_path $rs_path $i]]
            puts "${rs_name}_ENTRY=$i,$rob_id,$pc,$src1_ready,$src2_ready,$src1_tag,$src2_tag"
        }
    }
    puts "${rs_name}_ENTRIES_END"
}
puts "SIM_DEBUG_SNAPSHOT_END"
close_sim
exit 0
