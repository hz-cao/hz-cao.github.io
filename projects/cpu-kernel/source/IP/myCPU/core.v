module core (
	clk,
	resetn,
	ext_int,
	icache_req,
	icache_op,
	icache_addr,
	icache_uncached,
	icache_addr_ok,
	icache_data_ok,
	icache_rdata,
	dcache_valid,
	dcache_op,
	dcache_tag,
	dcache_index,
	dcache_offset,
	dcache_wstrb,
	dcache_wdata,
	dcache_uncached,
	dcache_size,
	dcache_addr_ok,
	dcache_data_ok,
	dcache_rdata,
	debug0_wb_pc,
	debug0_wb_rf_wen,
	debug0_wb_rf_wnum,
	debug0_wb_rf_wdata,
	debug1_wb_pc,
	debug1_wb_rf_wen,
	debug1_wb_rf_wnum,
	debug1_wb_rf_wdata,
	debug_status0,
	debug_status1
);
	input clk;
	input resetn;
	input [7:0] ext_int;
	output wire icache_req;
	output wire [2:0] icache_op;
	output wire [31:0] icache_addr;
	output wire icache_uncached;
	input icache_addr_ok;
	input icache_data_ok;
	input [63:0] icache_rdata;
	output wire dcache_valid;
	output wire [2:0] dcache_op;
	output wire [19:0] dcache_tag;
	output wire [6:0] dcache_index;
	output wire [4:0] dcache_offset;
	output wire [3:0] dcache_wstrb;
	output wire [31:0] dcache_wdata;
	output wire dcache_uncached;
	output wire [1:0] dcache_size;
	input dcache_addr_ok;
	input dcache_data_ok;
	input [31:0] dcache_rdata;
	output reg [31:0] debug0_wb_pc;
	output reg [3:0] debug0_wb_rf_wen;
	output reg [4:0] debug0_wb_rf_wnum;
	output reg [31:0] debug0_wb_rf_wdata;
	output reg [31:0] debug1_wb_pc;
	output reg [3:0] debug1_wb_rf_wen;
	output reg [4:0] debug1_wb_rf_wnum;
	output reg [31:0] debug1_wb_rf_wdata;
	output wire [31:0] debug_status0;
	output wire [31:0] debug_status1;
	function [3:0] mem_byte_mask;
		input [5:0] mem_opcode;
		input [1:0] addr_low;
		begin
			if (mem_opcode[0])
				mem_byte_mask = 4'b0001 << addr_low;
			else if (mem_opcode[1])
				mem_byte_mask = addr_low[1] ? 4'b1100 : 4'b0011;
			else
				mem_byte_mask = 4'b1111;
		end
	endfunction
	reg reset;
	always @(posedge clk) reset <= ~resetn;
	wire [1:0] if_stage_output_size;
	wire [31:0] if_stage_pc0;
	wire [31:0] if_stage_inst0;
	wire if_stage_pred_br_taken0;
	wire [31:0] if_stage_pred_br_target0;
	wire [31:0] if_stage_pc1;
	wire [31:0] if_stage_inst1;
	wire if_stage_pred_br_taken1;
	wire [31:0] if_stage_pred_br_target1;
	wire if_stage_have_excp;
	wire [14:0] if_stage_excp_type;
	reg ID_a_valid;
	reg [31:0] ID_a_pc;
	reg [31:0] ID_a_inst;
	reg ID_a_pred_br_taken;
	reg [31:0] ID_a_pred_br_target;
	reg ID_a_have_excp;
	reg [14:0] ID_a_excp_type;
	reg ID_b_valid;
	reg [31:0] ID_b_pc;
	reg [31:0] ID_b_inst;
	reg ID_b_pred_br_taken;
	reg [31:0] ID_b_pred_br_target;
	reg ID_b_have_excp;
	reg [14:0] ID_b_excp_type;
	wire [2:0] id_a_optype;
	wire [5:0] id_a_opcode;
	wire [4:0] id_a_dest;
	wire [31:0] id_a_imm;
	wire [2:0] id_a_br_type;
	wire id_a_br_condition;
	wire [31:0] id_a_br_target;
	wire id_a_have_excp;
	wire [14:0] id_a_excp_type;
	wire [13:0] id_a_csr_addr;
	wire id_a_csr_wr;
	wire id_a_is_spec_op;
	wire id_a_is_idle;
	wire id_a_is_ll;
	wire id_a_is_sc;
	wire [4:0] id_a_r1;
	wire [4:0] id_a_r2;
	wire id_a_src2_is_imm;
	wire id_a_br_mistaken;
	wire id_a_br_taken;
	wire [2:0] id_b_optype;
	wire [5:0] id_b_opcode;
	wire [4:0] id_b_dest;
	wire [31:0] id_b_imm;
	wire [2:0] id_b_br_type;
	wire id_b_br_condition;
	wire [31:0] id_b_br_target;
	wire id_b_have_excp;
	wire [14:0] id_b_excp_type;
	wire [13:0] id_b_csr_addr;
	wire id_b_csr_wr;
	wire id_b_is_spec_op;
	wire id_b_is_idle;
	wire id_b_is_ll;
	wire id_b_is_sc;
	wire [4:0] id_b_r1;
	wire [4:0] id_b_r2;
	wire id_b_src2_is_imm;
	wire id_b_br_mistaken;
	wire id_b_br_taken;
	reg [1:0] ibuf_i_size;
	wire ibuf_i_ready;
	wire [1:0] ibuf_o_size;
	wire ro_a_valid;
	wire [31:0] ro_a_pc;
	wire [31:0] ro_a_inst;
	wire [31:0] ro_b_inst;
	reg  [31:0] EX1_a_inst;
	reg  [31:0] EX1_b_inst;
	reg  [31:0] EX2_a_inst;
	reg  [31:0] EX2_b_inst;
	reg  [31:0] WB_a_inst;
	reg  [31:0] WB_b_inst;
	// Stage 2a rename shadow: physical dest / prev-dest pipeline
	wire [5:0]  rn_a_p_src1, rn_a_p_src2, rn_a_p_dst, rn_a_p_prev_dst;
	wire [5:0]  rn_b_p_src1, rn_b_p_src2, rn_b_p_dst, rn_b_p_prev_dst;
	wire        prf_ready1, prf_ready2, prf_ready3, prf_ready4;
	wire        rename_free_ready;  // unused in 2a; consumed at Stage 3+ dispatch stall
	wire        rename_recovering;
	reg  [5:0]  EX1_a_p_dst, EX1_a_p_prev_dst;
	reg  [5:0]  EX1_b_p_dst, EX1_b_p_prev_dst;
	reg  [5:0]  EX2_a_p_dst, EX2_a_p_prev_dst;
	reg  [5:0]  EX2_b_p_dst, EX2_b_p_prev_dst;
	reg  [5:0]  WB_a_p_dst,  WB_a_p_prev_dst;
	reg  [5:0]  WB_b_p_dst,  WB_b_p_prev_dst;
	// Stage 4a: rob_id propagation through pipeline (shadow — outputs unused).
	wire [4:0]  rob_alloc_a_id, rob_alloc_b_id;
	wire        rob_alloc_ready;
	wire [5:0]  rob_occ;
	wire [4:0]  rob_head, rob_tail;
	wire        rob_head_valid, rob_head_done;
	wire        ret_a_valid, ret_b_valid;
	wire [31:0] ret_a_pc, ret_b_pc;
	wire [31:0] ret_a_inst, ret_b_inst;
	wire [5:0]  ret_a_p_dst, ret_b_p_dst;
	wire [5:0]  ret_a_p_prev_dst, ret_b_p_prev_dst;
	wire [4:0]  ret_a_dest, ret_b_dest;
	wire        ret_a_has_dest, ret_b_has_dest;
	wire [31:0] ret_a_result, ret_b_result;
	wire        ret_a_have_excp, ret_b_have_excp;
	wire [14:0] ret_a_excp_type, ret_b_excp_type;
	wire [31:0] ret_a_excp_addr, ret_b_excp_addr;
	wire        ret_a_br_mispred, ret_b_br_mispred;
	wire [31:0] ret_a_br_actual_target, ret_b_br_actual_target;
	wire        ret_a_is_store, ret_b_is_store;
	wire        ret_a_is_csr_wr, ret_b_is_csr_wr;
	wire [13:0] ret_a_csr_addr, ret_b_csr_addr;
	wire        ret_a_is_ll, ret_b_is_ll, ret_a_is_sc, ret_b_is_sc;
	reg  [4:0]  EX1_a_rob_id, EX1_b_rob_id;
	reg  [4:0]  EX2_a_rob_id, EX2_b_rob_id;
	reg  [4:0]  WB_a_rob_id,  WB_b_rob_id;
	// Stage 4c: br_mispred / br_actual_target propagation (EX2→WB→ROB).
	// EX1_a_br_mistaken and ex1_a_br_target are already combinational at EX1.
	// Captured into EX2 regs at EX1→EX2 posedge; propagated to WB; fed to ROB.
	reg         EX2_a_br_mispred, EX2_b_br_mispred;
	reg  [31:0] EX2_a_br_actual_target, EX2_b_br_actual_target;
	reg         WB_a_br_mispred,  WB_b_br_mispred;
	reg  [31:0] WB_a_br_actual_target,  WB_b_br_actual_target;
	wire [2:0] ro_a_optype;
	wire [5:0] ro_a_opcode;
	wire [4:0] ro_a_dest;
	wire [31:0] ro_a_imm;
	wire ro_a_pred_br_taken;
	wire [31:0] ro_a_pred_br_target;
	wire [2:0] ro_a_br_type;
	wire ro_a_br_condition;
	wire [31:0] ro_a_br_target;
	wire ro_a_br_taken;
	wire ro_a_have_excp_no_int;
	wire [14:0] ro_a_excp_type_no_int;
	wire ro_a_have_excp;
	wire [14:0] ro_a_excp_type;
	wire [13:0] ro_a_csr_addr;
	wire ro_a_csr_wr;
	wire ro_a_is_spec_op;
	wire ro_a_is_idle;
	wire ro_a_is_ll;
	wire ro_a_is_sc;
	wire [4:0] ro_a_r1;
	wire [4:0] ro_a_r2;
	reg [31:0] ro_a_src1_passed;
	reg ro_a_src1_from_wba;
	reg ro_a_src1_ok;
	reg [31:0] ro_a_src2_passed;
	wire ro_a_src2_is_imm;
	reg ro_a_src2_from_wba;
	reg ro_a_src2_ok;
	wire ro_b_valid;
	wire [31:0] ro_b_pc;
	wire [2:0] ro_b_optype;
	wire [5:0] ro_b_opcode;
	wire [4:0] ro_b_dest;
	wire [31:0] ro_b_imm;
	wire ro_b_pred_br_taken;
	wire [31:0] ro_b_pred_br_target;
	wire [2:0] ro_b_br_type;
	wire ro_b_br_condition;
	wire [31:0] ro_b_br_target;
	wire ro_b_br_taken;
	wire ro_b_have_excp;
	wire [14:0] ro_b_excp_type;
	wire [13:0] ro_b_csr_addr;
	wire ro_b_csr_wr;
	wire ro_b_is_spec_op;
	wire ro_b_is_idle;
	wire ro_b_is_ll;
	wire ro_b_is_sc;
	wire [4:0] ro_b_r1;
	wire [4:0] ro_b_r2;
	reg [31:0] ro_b_src1_passed;
	reg ro_b_src1_from_wba;
	reg ro_b_src1_ok;
	reg [31:0] ro_b_src2_passed;
	wire ro_b_src2_is_imm;
	reg ro_b_src2_from_wba;
	reg ro_b_src2_ok;
	wire ro_b_delayed;
	wire ro_b_src1_delayed;
	wire ro_b_src2_delayed;
	wire [31:0] rf_rdata1;
	wire [31:0] rf_rdata2;
	wire [31:0] rf_rdata3;
	wire [31:0] rf_rdata4;
	// Stage 2b PRF read data (from physical tags via rename)
	wire [31:0] prf_rdata1;
	wire [31:0] prf_rdata2;
	wire [31:0] prf_rdata3;
	wire [31:0] prf_rdata4;
	wire rf_we1;
	wire [4:0] rf_waddr1;
	wire [31:0] rf_wdata1;
	wire rf_we2;
	wire [4:0] rf_waddr2;
	wire [31:0] rf_wdata2;
	wire allow_issue_a;
	wire allow_issue_b;
	wire [31:0] excp_target;
	wire interrupt;
	wire replay;
	wire [31:0] replay_target;
	wire serial_replay;
	wire [31:0] csr_rdata;
	wire csr_da;
	wire [1:0] csr_datf;
	wire [1:0] csr_datm;
	wire [1:0] csr_plv;
	wire [9:0] csr_asid;
	wire [9:0] csr_dmw0;
	wire [9:0] csr_dmw1;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	wire [4:0] csr_tlbidx;
	wire [88:0] csr_tlb_rdata;
	wire csr_tlb_we;
	wire [88:0] csr_tlb_wdata;
	wire csr_badv_we;
	wire [31:0] csr_badv_wdata;
	wire csr_vppn_we;
	wire [18:0] csr_vppn_wdata;
	wire csr_llbit;
	wire csr_llbit_we;
	wire csr_llbit_wdata;
	reg br_mistaken;
	reg [2:0] br_type;
	reg [31:0] wrong_pc;
	reg [31:0] right_target;
	reg [31:0] btb_target;
	wire update_orien_en;
	wire [31:0] retire_pc;
	wire right_orien;
	wire mmu_i_valid;
	wire [19:0] mmu_i_vtag;
	wire mmu_i_ok;
	wire [19:0] mmu_i_ptag;
	wire [1:0] mmu_i_mat;
	wire mmu_i_page_fault;
	wire mmu_i_page_invalid;
	wire mmu_i_plv_fault;
	wire mmu_d_valid;
	wire [19:0] mmu_d_vtag;
	wire mmu_d_ok;
	wire [19:0] mmu_d_ptag;
	wire [1:0] mmu_d_mat;
	wire mmu_d_page_fault;
	wire mmu_d_page_invalid;
	wire mmu_d_page_dirty;
	wire mmu_d_plv_fault;
	wire invtlb_valid;
	wire [4:0] invtlb_op;
	wire [9:0] invtlb_asid;
	wire [31:0] invtlb_va;
	wire tlb_we;
	wire [4:0] tlb_w_index;
	wire [88:0] tlb_w_entry;
	wire [4:0] tlb_r_index;
	wire [88:0] tlb_r_entry;
	wire tlbsrch_valid;
	wire tlbsrch_ok;
	wire [18:0] tlbsrch_vppn;
	wire tlbsrch_found;
	wire [4:0] tlbsrch_index;
	reg EX1_stalling;
	reg EX1_a_valid;
	reg [31:0] EX1_a_pc;
	reg [2:0] EX1_a_optype;
	reg [5:0] EX1_a_opcode;
	reg [4:0] EX1_a_dest;
	reg [31:0] EX1_a_src1_passed;
	reg EX1_a_src1_from_wba;
	reg [31:0] EX1_a_src1_stalled;
	reg [31:0] EX1_a_src2_passed;
	reg EX1_a_src2_from_wba;
	reg [31:0] EX1_a_src2_stalled;
	reg [31:0] EX1_a_imm;
	reg [2:0] EX1_a_br_type;
	reg EX1_a_br_condition;
	reg [31:0] EX1_a_br_target;
	reg EX1_a_pred_br_taken;
	reg [31:0] EX1_a_pred_br_target;
	reg EX1_a_br_taken;
	reg EX1_a_have_excp;
	reg [14:0] EX1_a_excp_type;
	reg [13:0] EX1_a_csr_addr;
	reg EX1_a_csr_wr;
	reg EX1_a_is_spec_op;
	reg EX1_a_is_idle;
	reg EX1_a_is_ll;
	reg EX1_a_is_sc;
	reg EX1_b_valid;
	reg [31:0] EX1_b_pc;
	reg [2:0] EX1_b_optype;
	reg [5:0] EX1_b_opcode;
	reg [4:0] EX1_b_dest;
	reg [31:0] EX1_b_src1_passed;
	reg EX1_b_src1_from_wba;
	reg [31:0] EX1_b_src1_stalled;
	reg [31:0] EX1_b_src2_passed;
	reg EX1_b_src2_from_wba;
	reg [31:0] EX1_b_src2_stalled;
	reg [31:0] EX1_b_imm;
	reg EX1_b_delayed;
	reg EX1_b_src1_delayed;
	reg EX1_b_src2_delayed;
	reg [2:0] EX1_b_br_type;
	reg EX1_b_br_condition;
	reg [31:0] EX1_b_br_target;
	reg EX1_b_pred_br_taken;
	reg [31:0] EX1_b_pred_br_target;
	reg EX1_b_br_taken;
	reg EX1_b_have_excp;
	reg [14:0] EX1_b_excp_type;
	wire ex1_ready;
	wire ex1_stall;
	wire [31:0] ex1_a_src1;
	wire [31:0] ex1_a_src2;
	wire [31:0] ex1_a_addr;
	reg ex1_a_br_taken;
	reg [31:0] ex1_a_br_target;
	wire ex1_a_br_mistaken;
	reg ex1_a_br_mistaken_long;
	wire [31:0] ex1_b_src1;
	wire [31:0] ex1_b_src2;
	wire [31:0] ex1_b_addr;
	reg ex1_b_br_taken;
	reg [31:0] ex1_b_br_target;
	reg ex1_b_br_mistaken;
	wire icacop_valid;
	wire dcacop_valid;
	wire invalid_cacop;
	wire [1:0] cacop_op;
	wire cacop2_valid;
	wire cacop2_ok;
	wire cacop_en;
	reg EX2_stalling;
	reg EX2_a_valid;
	reg [31:0] EX2_a_pc;
	reg [2:0] EX2_a_optype;
	reg [4:0] EX2_a_dest;
	reg [31:0] EX2_a_src1;
	reg [31:0] EX2_a_src2;
	reg [31:0] EX2_a_alu_result;
	reg [2:0] EX2_a_br_type;
	reg EX2_a_br_taken;
	reg EX2_a_have_excp;
	reg [14:0] EX2_a_excp_type;
	reg [31:0] EX2_a_excp_addr;
	reg [13:0] EX2_a_csr_addr;
	reg EX2_a_csr_wr;
	reg EX2_a_is_spec_op;
	reg EX2_a_is_idle;
	reg EX2_a_is_ll;
	reg EX2_a_is_sc;
	reg EX2_b_valid;
	reg [31:0] EX2_b_pc;
	reg EX2_b_delayed;
	reg [2:0] EX2_b_optype;
	reg [5:0] EX2_b_opcode;
	reg [4:0] EX2_b_dest;
	reg [31:0] EX2_b_src1;
	reg [31:0] EX2_b_src2;
	reg [31:0] EX2_b_alu_result;
	reg [31:0] EX2_b_imm;
	reg [2:0] EX2_b_br_type;
	reg EX2_b_br_taken;
	reg EX2_b_have_excp;
	reg [14:0] EX2_b_excp_type;
	reg [31:0] EX2_b_excp_addr;
	wire ex2_a_ok;
	wire ex2_b_ok;
	wire ex2_stall;
	wire ex2_have_excp;
	wire [14:0] ex2_excp_type;
	wire [31:0] ex2_excp_pc;
	wire [31:0] ex2_excp_addr;
	wire idle;
	reg WB_a_valid;
	reg WB_a_ok;
	reg [31:0] WB_a_pc;
	reg [4:0] WB_a_dest;
	reg [31:0] WB_a_result;
	reg [2:0] WB_a_br_type;
	reg WB_a_br_taken;
	reg WB_a_have_excp;
	reg [14:0] WB_a_excp_type;
	reg [31:0] WB_a_excp_addr;
	reg WB_b_valid;
	reg WB_b_ok;
	reg [31:0] WB_b_pc;
	reg [4:0] WB_b_dest;
	reg [31:0] WB_b_result;
	reg [2:0] WB_b_br_type;
	reg WB_b_br_taken;
	reg WB_b_have_excp;
	reg [14:0] WB_b_excp_type;
	reg [31:0] WB_b_excp_addr;
	wire [31:0] alu_a_result;
	wire [31:0] alu_b1_result;
	wire [31:0] alu_b2_result;
	wire mul_a_ok;
	wire [31:0] mul_a_result;
	wire mul_b_ok;
	wire [31:0] mul_b_result;
	wire div_ok;
	wire [31:0] div_result;
	wire lsu_ok;
	wire lsu_ready;
	wire lsu_valid;
	wire [31:0] lsu_result;
	wire lsu_have_excp;
	wire [14:0] lsu_excp_type;
	wire raise_excp;
	wire flush_id;
	wire flush_ibuf;
	wire flush_ex1;
	wire ibuf_no_out;
	wire mem_order_violation;
	wire [31:0] mem_order_replay_pc;
	wire [31:0] mem_order_replay_store_pc;
	wire [31:0] lsq_speculative_load_count;
	wire [31:0] lsq_ordering_violation_count;
	if_stage u_if_stage(
		.clk(clk),
		.reset(reset),
		.ibuf_i_ready(ibuf_i_ready),
		.output_size(if_stage_output_size),
		.pc0(if_stage_pc0),
		.inst0(if_stage_inst0),
		.pred_br_taken0(if_stage_pred_br_taken0),
		.pred_br_target0(if_stage_pred_br_target0),
		.pc1(if_stage_pc1),
		.inst1(if_stage_inst1),
		.pred_br_taken1(if_stage_pred_br_taken1),
		.pred_br_target1(if_stage_pred_br_target1),
		.have_excp(if_stage_have_excp),
		.excp_type(if_stage_excp_type),
		.br_mistaken(br_mistaken),
		.br_type(br_type),
		.right_target(right_target),
		.btb_target(btb_target),
		.wrong_pc(wrong_pc),
		.update_orien_en(update_orien_en),
		.retire_pc(retire_pc),
		.right_orien(right_orien),
		.icacop_valid(icacop_valid),
		.cacop_op(cacop_op),
		.cacop_addr(ex1_a_addr),
		.raise_excp(raise_excp),
		.excp_target(excp_target),
		.replay(replay),
		.replay_target(replay_target),
		.interrupt(interrupt),
		.idle(idle),
		.icache_req(icache_req),
		.icache_op(icache_op),
		.icache_addr(icache_addr),
		.icache_uncached(icache_uncached),
		.icache_addr_ok(icache_addr_ok),
		.icache_data_ok(icache_data_ok),
		.icache_rdata(icache_rdata),
		.mmu_valid(mmu_i_valid),
		.mmu_vtag(mmu_i_vtag),
		.mmu_ok(mmu_i_ok),
		.mmu_ptag(mmu_i_ptag),
		.mmu_mat(mmu_i_mat),
		.mmu_page_fault(mmu_i_page_fault),
		.mmu_page_invalid(mmu_i_page_invalid),
		.mmu_plv_fault(mmu_i_plv_fault)
	);
	always @(posedge clk) begin
		if (reset || flush_id) begin
			ID_a_valid <= 1'b0;
			ID_b_valid <= 1'b0;
		end
		else begin
			ID_a_valid <= if_stage_output_size >= 2'd1;
			ID_b_valid <= (if_stage_output_size >= 2'd2) && !if_stage_have_excp;
		end
		if (if_stage_output_size >= 2'd1) begin
			ID_a_pc <= if_stage_pc0;
			ID_a_inst <= if_stage_inst0;
			ID_a_pred_br_taken <= if_stage_pred_br_taken0;
			ID_a_pred_br_target <= if_stage_pred_br_target0;
			ID_a_have_excp <= if_stage_have_excp;
			ID_a_excp_type <= if_stage_excp_type;
		end
		if ((if_stage_output_size >= 2'd2) && !if_stage_have_excp) begin
			ID_b_pc <= if_stage_pc1;
			ID_b_inst <= if_stage_inst1;
			ID_b_pred_br_taken <= if_stage_pred_br_taken1;
			ID_b_pred_br_target <= if_stage_pred_br_target1;
			ID_b_have_excp <= if_stage_have_excp;
			ID_b_excp_type <= if_stage_excp_type;
		end
	end
	reg [63:0] counter;
	always @(posedge clk)
		if (reset)
			counter <= 0;
		else
			counter <= counter + 64'd1;
	id_stage u_id_stage_a(
		.pc(ID_a_pc),
		.inst(ID_a_inst),
		.pred_br_taken(ID_a_pred_br_taken),
		.pred_br_target(ID_a_pred_br_target),
		.counter(counter),
		.llbit(csr_llbit),
		.optype(id_a_optype),
		.opcode(id_a_opcode),
		.dest(id_a_dest),
		.imm(id_a_imm),
		.br_type(id_a_br_type),
		.br_condition(id_a_br_condition),
		.br_target(id_a_br_target),
		.have_excp(id_a_have_excp),
		.excp_type(id_a_excp_type),
		.csr_addr(id_a_csr_addr),
		.csr_wr(id_a_csr_wr),
		.is_spec_op(id_a_is_spec_op),
		.is_idle(id_a_is_idle),
		.is_ll(id_a_is_ll),
		.is_sc(id_a_is_sc),
		.r1(id_a_r1),
		.r2(id_a_r2),
		.src2_is_imm(id_a_src2_is_imm),
		.br_mistaken(id_a_br_mistaken),
		.br_taken(id_a_br_taken)
	);
	id_stage u_id_stage_b(
		.pc(ID_b_pc),
		.inst(ID_b_inst),
		.pred_br_taken(ID_b_pred_br_taken),
		.pred_br_target(ID_b_pred_br_target),
		.counter(counter),
		.llbit(csr_llbit),
		.optype(id_b_optype),
		.opcode(id_b_opcode),
		.dest(id_b_dest),
		.imm(id_b_imm),
		.br_type(id_b_br_type),
		.br_condition(id_b_br_condition),
		.br_target(id_b_br_target),
		.have_excp(id_b_have_excp),
		.excp_type(id_b_excp_type),
		.csr_addr(id_b_csr_addr),
		.csr_wr(id_b_csr_wr),
		.is_spec_op(id_b_is_spec_op),
		.is_idle(id_b_is_idle),
		.is_ll(id_b_is_ll),
		.is_sc(id_b_is_sc),
		.r1(id_b_r1),
		.r2(id_b_r2),
		.src2_is_imm(id_b_src2_is_imm),
		.br_mistaken(id_b_br_mistaken),
		.br_taken(id_b_br_taken)
	);
	always @(*) begin
		if (ex1_a_br_mistaken) begin
			br_mistaken = 1'b1;
			br_type = EX1_a_br_type;
			wrong_pc = EX1_a_pc;
			right_target = (ex1_a_br_taken ? ex1_a_br_target : EX1_a_pc + 32'd4);
			btb_target = ex1_a_br_target;
		end
		else if (ex1_b_br_mistaken) begin
			br_mistaken = 1'b1;
			br_type = EX1_b_br_type;
			wrong_pc = EX1_b_pc;
			right_target = (ex1_b_br_taken ? ex1_b_br_target : EX1_b_pc + 32'd4);
			btb_target = ex1_b_br_target;
		end
		else if (ID_a_valid && id_a_br_mistaken) begin
			br_mistaken = 1'b1;
			br_type = id_a_br_type;
			wrong_pc = ID_a_pc;
			right_target = (id_a_br_taken || ((id_a_br_type == 3'b010) && ID_a_pred_br_taken) ? id_a_br_target : ID_a_pc + 32'd4);
			btb_target = id_a_br_target;
		end
		else if (ID_b_valid && id_b_br_mistaken) begin
			br_mistaken = 1'b1;
			br_type = id_b_br_type;
			wrong_pc = ID_b_pc;
			right_target = (id_b_br_taken || ((id_b_br_type == 3'b010) && ID_b_pred_br_taken) ? id_b_br_target : ID_b_pc + 32'd4);
			btb_target = id_b_br_target;
		end
		else begin
			br_mistaken = 1'b0;
			br_type = 3'b000;
			wrong_pc = 32'd0;
			right_target = 32'd0;
			btb_target = 32'd0;
		end
	end
	assign flush_id = (raise_excp || replay) || br_mistaken;
	assign flush_ibuf = ((raise_excp || replay) || ex1_a_br_mistaken) || ex1_b_br_mistaken;
	assign ibuf_no_out = ex1_a_br_mistaken || ex1_b_br_mistaken;
	assign flush_ex1 = raise_excp || replay;
	always @(*) begin
		if (ID_b_valid) begin
			if (id_a_br_mistaken)
				ibuf_i_size = 2'd1;
			else
				ibuf_i_size = 2'd2;
		end
		else if (ID_a_valid)
			ibuf_i_size = 2'd1;
		else
			ibuf_i_size = 2'd0;
	end
	ibuf u_ibuf(
		.clk(clk),
		.reset(reset),
		.flush(flush_ibuf),
		.i_size(ibuf_i_size),
		.i_ready(ibuf_i_ready),
		.i_a_inst(ID_a_inst),
		.i_b_inst(ID_b_inst),
		.o_a_inst(ro_a_inst),
		.o_b_inst(ro_b_inst),
		.i_a_pc(ID_a_pc),
		.i_a_optype(id_a_optype),
		.i_a_opcode(id_a_opcode),
		.i_a_dest(id_a_dest),
		.i_a_imm(id_a_imm),
		.i_a_pred_br_taken(ID_a_pred_br_taken),
		.i_a_pred_br_target(ID_a_pred_br_target),
		.i_a_br_type(id_a_br_type),
		.i_a_br_condition(id_a_br_condition),
		.i_a_br_target(id_a_br_target),
		.i_a_br_taken(id_a_br_taken),
		.i_a_have_excp(ID_a_have_excp || id_a_have_excp),
		.i_a_excp_type((ID_a_have_excp ? ID_a_excp_type : id_a_excp_type)),
		.i_a_csr_addr(id_a_csr_addr),
		.i_a_csr_wr(id_a_csr_wr),
		.i_a_is_spec_op(id_a_is_spec_op),
		.i_a_is_idle(id_a_is_idle),
		.i_a_is_ll(id_a_is_ll),
		.i_a_is_sc(id_a_is_sc),
		.i_a_r1(id_a_r1),
		.i_a_r2(id_a_r2),
		.i_a_src2_is_imm(id_a_src2_is_imm),
		.i_b_pc(ID_b_pc),
		.i_b_optype(id_b_optype),
		.i_b_opcode(id_b_opcode),
		.i_b_dest(id_b_dest),
		.i_b_imm(id_b_imm),
		.i_b_pred_br_taken(ID_b_pred_br_taken),
		.i_b_pred_br_target(ID_b_pred_br_target),
		.i_b_br_type(id_b_br_type),
		.i_b_br_condition(id_b_br_condition),
		.i_b_br_target(id_b_br_target),
		.i_b_br_taken(id_b_br_taken),
		.i_b_have_excp(id_b_have_excp),
		.i_b_excp_type(id_b_excp_type),
		.i_b_csr_addr(id_b_csr_addr),
		.i_b_csr_wr(id_b_csr_wr),
		.i_b_is_spec_op(id_b_is_spec_op),
		.i_b_is_idle(id_b_is_idle),
		.i_b_is_ll(id_b_is_ll),
		.i_b_is_sc(id_b_is_sc),
		.i_b_r1(id_b_r1),
		.i_b_r2(id_b_r2),
		.i_b_src2_is_imm(id_b_src2_is_imm),
		.o_size(ibuf_o_size),
		.o_a_pc(ro_a_pc),
		.o_a_valid(ro_a_valid),
		.o_a_optype(ro_a_optype),
		.o_a_opcode(ro_a_opcode),
		.o_a_dest(ro_a_dest),
		.o_a_imm(ro_a_imm),
		.o_a_pred_br_taken(ro_a_pred_br_taken),
		.o_a_pred_br_target(ro_a_pred_br_target),
		.o_a_br_type(ro_a_br_type),
		.o_a_br_condition(ro_a_br_condition),
		.o_a_br_target(ro_a_br_target),
		.o_a_br_taken(ro_a_br_taken),
		.o_a_have_excp(ro_a_have_excp_no_int),
		.o_a_excp_type(ro_a_excp_type_no_int),
		.o_a_csr_addr(ro_a_csr_addr),
		.o_a_csr_wr(ro_a_csr_wr),
		.o_a_is_spec_op(ro_a_is_spec_op),
		.o_a_is_idle(ro_a_is_idle),
		.o_a_is_ll(ro_a_is_ll),
		.o_a_is_sc(ro_a_is_sc),
		.o_a_r1(ro_a_r1),
		.o_a_r2(ro_a_r2),
		.o_a_src2_is_imm(ro_a_src2_is_imm),
		.o_b_valid(ro_b_valid),
		.o_b_pc(ro_b_pc),
		.o_b_optype(ro_b_optype),
		.o_b_opcode(ro_b_opcode),
		.o_b_dest(ro_b_dest),
		.o_b_imm(ro_b_imm),
		.o_b_pred_br_taken(ro_b_pred_br_taken),
		.o_b_pred_br_target(ro_b_pred_br_target),
		.o_b_br_type(ro_b_br_type),
		.o_b_br_condition(ro_b_br_condition),
		.o_b_br_target(ro_b_br_target),
		.o_b_br_taken(ro_b_br_taken),
		.o_b_have_excp(ro_b_have_excp),
		.o_b_excp_type(ro_b_excp_type),
		.o_b_csr_addr(ro_b_csr_addr),
		.o_b_csr_wr(ro_b_csr_wr),
		.o_b_is_spec_op(ro_b_is_spec_op),
		.o_b_is_idle(ro_b_is_idle),
		.o_b_is_ll(ro_b_is_ll),
		.o_b_is_sc(ro_b_is_sc),
		.o_b_r1(ro_b_r1),
		.o_b_r2(ro_b_r2),
		.o_b_src2_is_imm(ro_b_src2_is_imm)
	);
	assign ro_a_have_excp = ro_a_have_excp_no_int || interrupt;
	assign ro_a_excp_type = (interrupt ? 15'h0000 : ro_a_excp_type_no_int);
	regfile u_regfile(
		.clk(clk),
		.raddr1(ro_a_r1),
		.rdata1(rf_rdata1),
		.raddr2(ro_a_r2),
		.rdata2(rf_rdata2),
		.raddr3(ro_b_r1),
		.rdata3(rf_rdata3),
		.raddr4(ro_b_r2),
		.rdata4(rf_rdata4),
		.we1(rf_we1),
		.waddr1(rf_waddr1),
		.wdata1(rf_wdata1),
		.we2(rf_we2),
		.waddr2(rf_waddr2),
		.wdata2(rf_wdata2)
	);
	// --------------------------------------------------------------------
	// Stage 2a passive shadow: rename (RAT + free list) and PRF.
	// Dispatch fires on the same posedge that the pipeline writes EX1_a/b
	// regs from ro_a/b. Commit fires from WB_a/b_valid one cycle later than
	// the arch RF write. Rename outputs are unused by execution in Stage 2a;
	// PRF writes mirror the arch RF writes with waddr translated to WB_x_p_dst.
	// --------------------------------------------------------------------
	rename u_rename(
		.clk(clk),
		.reset(reset),
		.flush(flush_ex1),
		.rob_empty(rob_occ == 0),
		.disp_a_fire(!flush_ex1 && !ex1_stall && allow_issue_a),
		.disp_a_src1(ro_a_r1),
		.disp_a_src2(ro_a_r2),
		.disp_a_dest(ro_a_dest),
		.disp_b_fire(!flush_ex1 && !ex1_stall && allow_issue_b && !ex1_a_br_mistaken),
		.disp_b_src1(ro_b_r1),
		.disp_b_src2(ro_b_r2),
		.disp_b_dest(ro_b_dest),
		.rn_a_p_src1(rn_a_p_src1),
		.rn_a_p_src2(rn_a_p_src2),
		.rn_a_p_dst(rn_a_p_dst),
		.rn_a_p_prev_dst(rn_a_p_prev_dst),
		.rn_b_p_src1(rn_b_p_src1),
		.rn_b_p_src2(rn_b_p_src2),
		.rn_b_p_dst(rn_b_p_dst),
		.rn_b_p_prev_dst(rn_b_p_prev_dst),
		.cmt_a_fire(ret_a_valid & ~ret_a_have_excp),
		.cmt_a_dest(ret_a_dest),
		.cmt_a_p_dst(ret_a_p_dst),
		.cmt_a_p_prev_dst(ret_a_p_prev_dst),
		.cmt_b_fire(ret_b_valid & ~ret_b_have_excp),
		.cmt_b_dest(ret_b_dest),
		.cmt_b_p_dst(ret_b_p_dst),
		.cmt_b_p_prev_dst(ret_b_p_prev_dst),
		.recovery_busy(rename_recovering),
		.free_list_ready(rename_free_ready)
	);
	prf u_prf(
		.clk(clk), .reset(reset),
		.raddr1(rn_a_p_src1),
		.rdata1(prf_rdata1),
		.raddr2(rn_a_p_src2),
		.rdata2(prf_rdata2),
		.raddr3(rn_b_p_src1),
		.rdata3(prf_rdata3),
		.raddr4(rn_b_p_src2),
		.rdata4(prf_rdata4),
		.rready1(prf_ready1), .rready2(prf_ready2),
		.rready3(prf_ready3), .rready4(prf_ready4),
		.alloc1_valid(!flush_ex1 && !ex1_stall && allow_issue_a && (ro_a_dest != 5'd0)),
		.alloc1_addr(rn_a_p_dst),
		.alloc2_valid(!flush_ex1 && !ex1_stall && allow_issue_b && !ex1_a_br_mistaken && (ro_b_dest != 5'd0)),
		.alloc2_addr(rn_b_p_dst),
		.we1(WB_a_valid && !WB_a_have_excp && (WB_a_p_dst != 6'd0)),
		.waddr1(WB_a_p_dst),
		.wdata1(WB_a_result),
		.we2(WB_b_valid && !WB_b_have_excp && (WB_b_p_dst != 6'd0)),
		.waddr2(WB_b_p_dst),
		.wdata2(WB_b_result)
	);
	// --------------------------------------------------------------------
	// Stage 3b: two reservation stations (RS_ALU0 feeds EX1_a, RS_ALU1
	// feeds EX1_b). RS_MEM from Stage 3a is dropped — memory ops share
	// the slot-A path with ALU, matching QHU's single-LSU-port structure.
	// Full field carry (30 fields per entry) + 4 wakeup taps + same-cycle
	// passthrough when RS is empty for IPC parity. Wakeup broadcasts fire
	// on EX1_a/b fast-path (single-cycle ALU) and WB_a/b commit.
	// --------------------------------------------------------------------
	// Dispatch gate: allow_issue_a keeps its baseline conditions AND now
	// also requires the target RS to have room. Same for slot B.
	wire rs_alu0_ready, rs_alu1_ready;   // forward decl for allow_issue gating
	wire disp_a_fire_pre = (!ex1_stall) && allow_issue_a;
	wire disp_b_fire_pre = (!ex1_stall) && allow_issue_b && !ex1_a_br_mistaken;
	reg  unresolved_branch;
	wire dispatches_branch = (disp_a_fire_pre && (ro_a_br_type != 3'b000)) ||
	                           (disp_b_fire_pre && (ro_b_br_type != 3'b000));
	wire resolves_branch = !ex1_stall &&
	                       ((EX1_a_valid && (EX1_a_br_type != 3'b000)) ||
	                        (EX1_b_valid && (EX1_b_br_type != 3'b000)));
	always @(posedge clk) begin
		if (reset || flush_ex1)
			unresolved_branch <= 1'b0;
		else if (resolves_branch)
			unresolved_branch <= 1'b0;
		else if (dispatches_branch)
			unresolved_branch <= 1'b1;
	end

	// Wakeup taps (identical for both RSes)
	wire        wk_ex1a_v = EX1_a_valid & (EX1_a_optype == 3'd0) & ~ex1_stall;
	wire [5:0]  wk_ex1a_t = EX1_a_p_dst;
	wire [31:0] wk_ex1a_d = alu_a_result;
	wire        wk_ex1b_v = EX1_b_valid & (EX1_b_optype == 3'd0) & ~EX1_b_delayed & ~ex1_stall;
	wire [5:0]  wk_ex1b_t = EX1_b_p_dst;
	wire [31:0] wk_ex1b_d = alu_b1_result;
	wire        wk_wba_v  = WB_a_valid  & ~WB_a_have_excp & (WB_a_p_dst != 6'd0);
	wire [5:0]  wk_wba_t  = WB_a_p_dst;
	wire [31:0] wk_wba_d  = WB_a_result;
	wire        wk_wbb_v  = WB_b_valid  & ~WB_b_have_excp & (WB_b_p_dst != 6'd0);
	wire [5:0]  wk_wbb_t  = WB_b_p_dst;
	wire [31:0] wk_wbb_d  = WB_b_result;

	// RS_ALU0 issue outputs — full 30-field set (mirror of ins fields)
	wire        rs_alu0_iss_valid;
	wire [31:0] rs_alu0_iss_pc, rs_alu0_iss_inst;
	wire [5:0]  rs_alu0_iss_p_dst, rs_alu0_iss_p_prev_dst;
	wire [2:0]  rs_alu0_iss_optype;
	wire [5:0]  rs_alu0_iss_opcode;
	wire [4:0]  rs_alu0_iss_dest;
	wire [31:0] rs_alu0_iss_src1_val, rs_alu0_iss_src2_val;
	wire [5:0]  rs_alu0_iss_p_src1, rs_alu0_iss_p_src2;
	wire        rs_alu0_iss_src1_fwba, rs_alu0_iss_src2_fwba;
	wire [31:0] rs_alu0_iss_imm;
	wire [2:0]  rs_alu0_iss_br_type;
	wire        rs_alu0_iss_br_condition;
	wire [31:0] rs_alu0_iss_br_target;
	wire        rs_alu0_iss_pred_br_taken;
	wire [31:0] rs_alu0_iss_pred_br_target;
	wire        rs_alu0_iss_br_taken;
	wire        rs_alu0_iss_have_excp;
	wire [14:0] rs_alu0_iss_excp_type;
	wire [13:0] rs_alu0_iss_csr_addr;
	wire        rs_alu0_iss_csr_wr;
	wire        rs_alu0_iss_is_spec_op, rs_alu0_iss_is_idle, rs_alu0_iss_is_ll, rs_alu0_iss_is_sc;
	wire        rs_alu0_iss_delayed, rs_alu0_iss_src1_delayed, rs_alu0_iss_src2_delayed;
	wire [4:0]  rs_alu0_iss_rob_id;
	wire [3:0]  rs_alu0_occ;
	wire        rs_alu0_issue_allowed;
	wire        rs_alu1_issue_allowed;

	rs #(.ENTRIES(8), .IDX_W(3), .PHYS_W(6)) u_rs_alu0(
		.clk(clk), .reset(reset), .flush(flush_ex1), .rob_head(rob_head),
		.ins_valid(disp_a_fire_pre),
		.ins_pc(ro_a_pc), .ins_inst(ro_a_inst),
		.ins_p_dst(rn_a_p_dst), .ins_p_prev_dst(rn_a_p_prev_dst),
		.ins_optype(ro_a_optype), .ins_opcode(ro_a_opcode), .ins_dest(ro_a_dest),
		.ins_src1_val(ro_a_src1_passed), .ins_src1_ready(ro_a_src1_ok),
		.ins_p_src1(rn_a_p_src1), .ins_src1_from_wba(ro_a_src1_from_wba),
		.ins_src2_val(ro_a_src2_passed), .ins_src2_ready(ro_a_src2_ok),
		.ins_p_src2(rn_a_p_src2), .ins_src2_from_wba(ro_a_src2_from_wba),
		.ins_imm(ro_a_imm),
		.ins_br_type(ro_a_br_type), .ins_br_condition(ro_a_br_condition),
		.ins_br_target(ro_a_br_target),
		.ins_pred_br_taken(ro_a_pred_br_taken), .ins_pred_br_target(ro_a_pred_br_target),
		.ins_br_taken(ro_a_br_taken),
		.ins_have_excp(ro_a_have_excp), .ins_excp_type(ro_a_excp_type),
		.ins_csr_addr(ro_a_csr_addr), .ins_csr_wr(ro_a_csr_wr),
		.ins_is_spec_op(ro_a_is_spec_op), .ins_is_idle(ro_a_is_idle),
		.ins_is_ll(ro_a_is_ll), .ins_is_sc(ro_a_is_sc),
		.ins_delayed(1'b0), .ins_src1_delayed(1'b0), .ins_src2_delayed(1'b0),
		.ins_rob_id(rob_alloc_a_id),
		.wake0_valid(wk_ex1a_v), .wake0_tag(wk_ex1a_t), .wake0_val(wk_ex1a_d),
		.wake1_valid(wk_ex1b_v), .wake1_tag(wk_ex1b_t), .wake1_val(wk_ex1b_d),
		.wake2_valid(wk_wba_v),  .wake2_tag(wk_wba_t),  .wake2_val(wk_wba_d),
		.wake3_valid(wk_wbb_v),  .wake3_tag(wk_wbb_t),  .wake3_val(wk_wbb_d),
		.iss_valid(rs_alu0_iss_valid),
		.iss_pc(rs_alu0_iss_pc), .iss_inst(rs_alu0_iss_inst),
		.iss_p_dst(rs_alu0_iss_p_dst), .iss_p_prev_dst(rs_alu0_iss_p_prev_dst),
		.iss_optype(rs_alu0_iss_optype), .iss_opcode(rs_alu0_iss_opcode),
		.iss_dest(rs_alu0_iss_dest),
		.iss_src1_val(rs_alu0_iss_src1_val),
		.iss_p_src1(rs_alu0_iss_p_src1), .iss_src1_from_wba(rs_alu0_iss_src1_fwba),
		.iss_src2_val(rs_alu0_iss_src2_val),
		.iss_p_src2(rs_alu0_iss_p_src2), .iss_src2_from_wba(rs_alu0_iss_src2_fwba),
		.iss_imm(rs_alu0_iss_imm),
		.iss_br_type(rs_alu0_iss_br_type), .iss_br_condition(rs_alu0_iss_br_condition),
		.iss_br_target(rs_alu0_iss_br_target),
		.iss_pred_br_taken(rs_alu0_iss_pred_br_taken),
		.iss_pred_br_target(rs_alu0_iss_pred_br_target),
		.iss_br_taken(rs_alu0_iss_br_taken),
		.iss_have_excp(rs_alu0_iss_have_excp), .iss_excp_type(rs_alu0_iss_excp_type),
		.iss_csr_addr(rs_alu0_iss_csr_addr), .iss_csr_wr(rs_alu0_iss_csr_wr),
		.iss_is_spec_op(rs_alu0_iss_is_spec_op), .iss_is_idle(rs_alu0_iss_is_idle),
		.iss_is_ll(rs_alu0_iss_is_ll), .iss_is_sc(rs_alu0_iss_is_sc),
		.iss_delayed(rs_alu0_iss_delayed),
		.iss_src1_delayed(rs_alu0_iss_src1_delayed),
		.iss_src2_delayed(rs_alu0_iss_src2_delayed),
		.iss_rob_id(rs_alu0_iss_rob_id),
		.iss_accepted(rs_alu0_iss_valid & rs_alu0_issue_allowed & ~ex1_stall),
		.ready_for_ins(rs_alu0_ready),
		.occupancy(rs_alu0_occ)
	);

	// RS_ALU1
	wire [4:0]  rs_alu1_iss_rob_id;
	wire        rs_alu1_iss_valid;
	wire [31:0] rs_alu1_iss_pc, rs_alu1_iss_inst;
	wire [5:0]  rs_alu1_iss_p_dst, rs_alu1_iss_p_prev_dst;
	wire [2:0]  rs_alu1_iss_optype;
	wire [5:0]  rs_alu1_iss_opcode;
	wire [4:0]  rs_alu1_iss_dest;
	wire [31:0] rs_alu1_iss_src1_val, rs_alu1_iss_src2_val;
	wire [5:0]  rs_alu1_iss_p_src1, rs_alu1_iss_p_src2;
	wire        rs_alu1_iss_src1_fwba, rs_alu1_iss_src2_fwba;
	wire [31:0] rs_alu1_iss_imm;
	wire [2:0]  rs_alu1_iss_br_type;
	wire        rs_alu1_iss_br_condition;
	wire [31:0] rs_alu1_iss_br_target;
	wire        rs_alu1_iss_pred_br_taken;
	wire [31:0] rs_alu1_iss_pred_br_target;
	wire        rs_alu1_iss_br_taken;
	wire        rs_alu1_iss_have_excp;
	wire [14:0] rs_alu1_iss_excp_type;
	wire        rs_alu1_iss_delayed, rs_alu1_iss_src1_delayed, rs_alu1_iss_src2_delayed;
	wire [3:0]  rs_alu1_occ;
	wire        rs_alu0_iss_mem = rs_alu0_iss_valid && (rs_alu0_iss_optype == 3'd3);
	wire        rs_alu1_iss_mem = rs_alu1_iss_valid && (rs_alu1_iss_optype == 3'd3);
	wire        rs_alu0_iss_div = rs_alu0_iss_valid && (rs_alu0_iss_optype == 3'd2);
	wire        rs_alu1_iss_div = rs_alu1_iss_valid && (rs_alu1_iss_optype == 3'd2);
	wire        rs_alu0_iss_store = rs_alu0_iss_mem && rs_alu0_iss_opcode[4];
	wire        rs_alu1_iss_store = rs_alu1_iss_mem && rs_alu1_iss_opcode[4];
	wire        rs_alu0_iss_load = rs_alu0_iss_mem && rs_alu0_iss_opcode[5];
	wire        rs_alu1_iss_load = rs_alu1_iss_mem && rs_alu1_iss_opcode[5];
	wire        rs_alu0_load_blocked;
	wire        rs_alu1_load_blocked;
	wire        rs_alu0_head_only = rs_alu0_iss_store || rs_alu0_iss_have_excp ||
	                                 (rs_alu0_iss_optype == 3'd4) ||
	                                 (rs_alu0_iss_optype == 3'd5) ||
	                                 (rs_alu0_iss_optype == 3'd6) ||
	                                 rs_alu0_iss_is_spec_op || rs_alu0_iss_is_idle ||
	                                 rs_alu0_iss_is_ll || rs_alu0_iss_is_sc;
	// Slot B is restricted to ordinary ALU/multiply/divide/load-store/branch
	// instructions at dispatch, so only memory and decoded exceptions can be
	// head-only here.
	wire        rs_alu1_head_only = rs_alu1_iss_store || rs_alu1_iss_have_excp;
	wire        rs_alu0_is_head = rs_alu0_iss_rob_id == rob_head;
	wire        rs_alu1_is_head = rs_alu1_iss_rob_id == rob_head;
	wire        rs_alu0_exclusive = rs_alu0_iss_have_excp ||
	                                  (rs_alu0_iss_optype == 3'd4) ||
	                                  (rs_alu0_iss_optype == 3'd5) ||
	                                  (rs_alu0_iss_optype == 3'd6) ||
	                                  rs_alu0_iss_is_spec_op || rs_alu0_iss_is_idle ||
	                                  rs_alu0_iss_is_ll || rs_alu0_iss_is_sc;
	wire        rs_alu1_exclusive = rs_alu1_iss_have_excp;
	wire        rs_alu0_exclusive_head = rs_alu0_iss_valid && rs_alu0_exclusive && rs_alu0_is_head;
	wire        rs_alu1_exclusive_head = rs_alu1_iss_valid && rs_alu1_exclusive && rs_alu1_is_head;
	assign      rs_alu0_issue_allowed = (!rs_alu0_head_only || rs_alu0_is_head) &&
	                                    !rs_alu0_load_blocked &&
	                                    !rs_alu1_exclusive_head;
	wire        rs_alu0_claims_mem = rs_alu0_iss_mem && rs_alu0_issue_allowed;
	assign      rs_alu1_issue_allowed = (!rs_alu1_head_only || rs_alu1_is_head) &&
	                                    !rs_alu1_load_blocked &&
	                                    !rs_alu0_exclusive_head &&
	                                    (!rs_alu0_iss_valid ||
	                                     (rs_alu0_iss_br_type == 3'b000)) &&
	                                    !(rs_alu0_claims_mem && rs_alu1_iss_mem) &&
	                                    !(rs_alu0_iss_div && rs_alu1_iss_div);

	rs #(.ENTRIES(8), .IDX_W(3), .PHYS_W(6)) u_rs_alu1(
		.clk(clk), .reset(reset), .flush(flush_ex1), .rob_head(rob_head),
		.ins_valid(disp_b_fire_pre),
		.ins_pc(ro_b_pc), .ins_inst(ro_b_inst),
		.ins_p_dst(rn_b_p_dst), .ins_p_prev_dst(rn_b_p_prev_dst),
		.ins_optype(ro_b_optype), .ins_opcode(ro_b_opcode), .ins_dest(ro_b_dest),
		.ins_src1_val(ro_b_src1_passed), .ins_src1_ready(ro_b_src1_ok),
		.ins_p_src1(rn_b_p_src1), .ins_src1_from_wba(ro_b_src1_from_wba),
		.ins_src2_val(ro_b_src2_passed), .ins_src2_ready(ro_b_src2_ok),
		.ins_p_src2(rn_b_p_src2), .ins_src2_from_wba(ro_b_src2_from_wba),
		.ins_imm(ro_b_imm),
		.ins_br_type(ro_b_br_type), .ins_br_condition(ro_b_br_condition),
		.ins_br_target(ro_b_br_target),
		.ins_pred_br_taken(ro_b_pred_br_taken), .ins_pred_br_target(ro_b_pred_br_target),
		.ins_br_taken(ro_b_br_taken),
		.ins_have_excp(ro_b_have_excp), .ins_excp_type(ro_b_excp_type),
		.ins_csr_addr(14'b0), .ins_csr_wr(1'b0),   // slot B does not carry these
		.ins_is_spec_op(1'b0), .ins_is_idle(1'b0), .ins_is_ll(1'b0), .ins_is_sc(1'b0),
		.ins_delayed(ro_b_delayed),
		.ins_src1_delayed(ro_b_src1_delayed), .ins_src2_delayed(ro_b_src2_delayed),
		.ins_rob_id(rob_alloc_b_id),
		.wake0_valid(wk_ex1a_v), .wake0_tag(wk_ex1a_t), .wake0_val(wk_ex1a_d),
		.wake1_valid(wk_ex1b_v), .wake1_tag(wk_ex1b_t), .wake1_val(wk_ex1b_d),
		.wake2_valid(wk_wba_v),  .wake2_tag(wk_wba_t),  .wake2_val(wk_wba_d),
		.wake3_valid(wk_wbb_v),  .wake3_tag(wk_wbb_t),  .wake3_val(wk_wbb_d),
		.iss_valid(rs_alu1_iss_valid),
		.iss_pc(rs_alu1_iss_pc), .iss_inst(rs_alu1_iss_inst),
		.iss_p_dst(rs_alu1_iss_p_dst), .iss_p_prev_dst(rs_alu1_iss_p_prev_dst),
		.iss_optype(rs_alu1_iss_optype), .iss_opcode(rs_alu1_iss_opcode),
		.iss_dest(rs_alu1_iss_dest),
		.iss_src1_val(rs_alu1_iss_src1_val),
		.iss_p_src1(rs_alu1_iss_p_src1), .iss_src1_from_wba(rs_alu1_iss_src1_fwba),
		.iss_src2_val(rs_alu1_iss_src2_val),
		.iss_p_src2(rs_alu1_iss_p_src2), .iss_src2_from_wba(rs_alu1_iss_src2_fwba),
		.iss_imm(rs_alu1_iss_imm),
		.iss_br_type(rs_alu1_iss_br_type), .iss_br_condition(rs_alu1_iss_br_condition),
		.iss_br_target(rs_alu1_iss_br_target),
		.iss_pred_br_taken(rs_alu1_iss_pred_br_taken),
		.iss_pred_br_target(rs_alu1_iss_pred_br_target),
		.iss_br_taken(rs_alu1_iss_br_taken),
		.iss_have_excp(rs_alu1_iss_have_excp), .iss_excp_type(rs_alu1_iss_excp_type),
		.iss_csr_addr(), .iss_csr_wr(),
		.iss_is_spec_op(), .iss_is_idle(), .iss_is_ll(), .iss_is_sc(),
		.iss_delayed(rs_alu1_iss_delayed),
		.iss_src1_delayed(rs_alu1_iss_src1_delayed),
		.iss_src2_delayed(rs_alu1_iss_src2_delayed),
		.iss_rob_id(rs_alu1_iss_rob_id),
		.iss_accepted(rs_alu1_iss_valid & rs_alu1_issue_allowed & ~ex1_stall),
		.ready_for_ins(rs_alu1_ready),
		.occupancy(rs_alu1_occ)
	);
	// --------------------------------------------------------------------
	// Stage 4a: Reorder Buffer (SHADOW).
	// Alloc on same cycle as RS insert (dispatch); complete when WB commits
	// (via propagated rob_id); retire outputs unused (existing WB-direct
	// commit path preserved). Flush on flush_ex1: full reset (simplest for
	// shadow; loses tracking of in-flight EX2/WB entries but their
	// completions post-flush no-op harmlessly).
	// --------------------------------------------------------------------
	// Stage 4b: gate alloc on !flush_ex1 to prevent ghost entries on flush cycle.
	wire        rob_alloc_a_v = (!ex1_stall) & allow_issue_a & !flush_ex1;
	wire        rob_alloc_b_v = (!ex1_stall) & allow_issue_b & !ex1_a_br_mistaken & !flush_ex1;
	wire        cmp_a_v = WB_a_valid;
	wire        cmp_b_v = WB_b_valid;
	// Flush preserve boundary: youngest rob_id currently in EX2/WB.
	wire [4:0]  flush_preserve_high_id =
		EX2_b_valid ? EX2_b_rob_id :
		EX2_a_valid ? EX2_a_rob_id :
		WB_b_valid  ? WB_b_rob_id  :
		WB_a_valid  ? WB_a_rob_id  :
		5'd0;
	wire        flush_preserve_valid = (EX2_a_valid | EX2_b_valid | WB_a_valid | WB_b_valid) &&
	                                    !mem_order_violation && !raise_excp;
	// Stage 4b: retire outputs are load-bearing (drive arch RF and rename commit).
	rob #(.SIZE(32), .ID_W(5)) u_rob(
		.clk(clk), .reset(reset), .flush(flush_ex1),
		.flush_preserve_high_id(flush_preserve_high_id),
		.flush_preserve_valid(flush_preserve_valid),
		.alloc_a_valid(rob_alloc_a_v),
		.alloc_a_pc(ro_a_pc), .alloc_a_inst(ro_a_inst),
		.alloc_a_p_dst(rn_a_p_dst), .alloc_a_p_prev_dst(rn_a_p_prev_dst),
		.alloc_a_dest(ro_a_dest),
		.alloc_a_is_branch(ro_a_br_type != 3'b000),
		.alloc_a_is_store((ro_a_optype == 3'd3) & (ro_a_opcode[5] == 1'b0)),
		.alloc_a_is_csr_wr(ro_a_csr_wr),
		.alloc_a_csr_addr(ro_a_csr_addr),
		.alloc_a_is_ll(ro_a_is_ll), .alloc_a_is_sc(ro_a_is_sc),
		.alloc_a_is_unique(ro_a_is_spec_op | ro_a_is_idle),
		.alloc_a_id(rob_alloc_a_id),
		.alloc_b_valid(rob_alloc_b_v),
		.alloc_b_pc(ro_b_pc), .alloc_b_inst(ro_b_inst),
		.alloc_b_p_dst(rn_b_p_dst), .alloc_b_p_prev_dst(rn_b_p_prev_dst),
		.alloc_b_dest(ro_b_dest),
		.alloc_b_is_branch(ro_b_br_type != 3'b000),
		.alloc_b_is_store((ro_b_optype == 3'd3) & (ro_b_opcode[5] == 1'b0)),
		.alloc_b_is_csr_wr(1'b0),
		.alloc_b_csr_addr(14'b0),
		.alloc_b_is_ll(1'b0), .alloc_b_is_sc(1'b0),
		.alloc_b_is_unique(1'b0),
		.alloc_b_id(rob_alloc_b_id),
		.alloc_ready(rob_alloc_ready),
		.cmp_a_valid(cmp_a_v), .cmp_a_id(WB_a_rob_id),
		.cmp_a_result(WB_a_result),
		.cmp_a_have_excp(WB_a_have_excp), .cmp_a_excp_type(WB_a_excp_type),
		.cmp_a_excp_addr(WB_a_excp_addr),
		.cmp_a_br_mispredicted(WB_a_br_mispred),
		.cmp_a_br_actual_target(WB_a_br_actual_target),
		.cmp_b_valid(cmp_b_v), .cmp_b_id(WB_b_rob_id),
		.cmp_b_result(WB_b_result),
		.cmp_b_have_excp(WB_b_have_excp), .cmp_b_excp_type(WB_b_excp_type),
		.cmp_b_excp_addr(WB_b_excp_addr),
		.cmp_b_br_mispredicted(WB_b_br_mispred),
		.cmp_b_br_actual_target(WB_b_br_actual_target),
		.ret_a_valid(ret_a_valid), .ret_a_pc(ret_a_pc), .ret_a_inst(ret_a_inst),
		.ret_a_p_dst(ret_a_p_dst), .ret_a_p_prev_dst(ret_a_p_prev_dst),
		.ret_a_dest(ret_a_dest), .ret_a_has_dest(ret_a_has_dest),
		.ret_a_result(ret_a_result), .ret_a_have_excp(ret_a_have_excp),
		.ret_a_excp_type(ret_a_excp_type), .ret_a_excp_addr(ret_a_excp_addr),
		.ret_a_br_mispred(ret_a_br_mispred),
		.ret_a_br_actual_target(ret_a_br_actual_target),
		.ret_a_is_store(ret_a_is_store), .ret_a_is_csr_wr(ret_a_is_csr_wr),
		.ret_a_csr_addr(ret_a_csr_addr),
		.ret_a_is_ll(ret_a_is_ll), .ret_a_is_sc(ret_a_is_sc),
		.ret_b_valid(ret_b_valid), .ret_b_pc(ret_b_pc), .ret_b_inst(ret_b_inst),
		.ret_b_p_dst(ret_b_p_dst), .ret_b_p_prev_dst(ret_b_p_prev_dst),
		.ret_b_dest(ret_b_dest), .ret_b_has_dest(ret_b_has_dest),
		.ret_b_result(ret_b_result), .ret_b_have_excp(ret_b_have_excp),
		.ret_b_excp_type(ret_b_excp_type), .ret_b_excp_addr(ret_b_excp_addr),
		.ret_b_br_mispred(ret_b_br_mispred),
		.ret_b_br_actual_target(ret_b_br_actual_target),
		.ret_b_is_store(ret_b_is_store), .ret_b_is_csr_wr(ret_b_is_csr_wr),
		.ret_b_csr_addr(ret_b_csr_addr),
		.ret_b_is_ll(ret_b_is_ll), .ret_b_is_sc(ret_b_is_sc),
		.occupancy(rob_occ), .head_ptr(rob_head), .tail_ptr(rob_tail),
		.head_valid(rob_head_valid), .head_done(rob_head_done)
	);

	wire lsq_alloc_a_load = rob_alloc_a_v && (ro_a_optype == 3'd3) && ro_a_opcode[5];
	wire lsq_alloc_a_store = rob_alloc_a_v && (ro_a_optype == 3'd3) && ro_a_opcode[4];
	wire lsq_alloc_b_load = rob_alloc_b_v && (ro_b_optype == 3'd3) && ro_b_opcode[5];
	wire lsq_alloc_b_store = rob_alloc_b_v && (ro_b_optype == 3'd3) && ro_b_opcode[4];
	wire ex1_mem_select_a = EX1_a_valid && (EX1_a_optype == 3'd3);
	wire ex1_mem_select_b = !ex1_mem_select_a && EX1_b_valid && (EX1_b_optype == 3'd3);
	wire [5:0] ex1_mem_opcode = ex1_mem_select_a ? EX1_a_opcode : EX1_b_opcode;
	wire [31:0] ex1_mem_addr = ex1_mem_select_a ? ex1_a_addr : ex1_b_addr;
	wire [31:0] ex1_mem_pc = ex1_mem_select_a ? EX1_a_pc : EX1_b_pc;
	wire [4:0] ex1_mem_rob_id = ex1_mem_select_a ? EX1_a_rob_id : EX1_b_rob_id;
	wire [3:0] ex1_mem_mask = mem_byte_mask(ex1_mem_opcode, ex1_mem_addr[1:0]);
	wire lsq_load_exec_valid = (ex1_mem_select_a || ex1_mem_select_b) &&
	                           ex1_mem_opcode[5] && lsu_valid && lsu_ready &&
	                           !lsu_have_excp;
	wire lsq_store_probe_valid = (ex1_mem_select_a || ex1_mem_select_b) &&
	                             ex1_mem_opcode[4] && lsu_valid && lsu_ready &&
	                             !lsu_have_excp && !EX1_stalling && !ex2_stall;
	mem_disambig #(.ROB_ENTRIES(32), .ROB_ID_W(5)) u_mem_disambig(
		.clk(clk), .reset(reset), .flush(flush_ex1), .rob_head(rob_head),
		.alloc_a_valid(rob_alloc_a_v), .alloc_a_id(rob_alloc_a_id),
		.alloc_a_is_load(lsq_alloc_a_load), .alloc_a_is_store(lsq_alloc_a_store),
		.alloc_b_valid(rob_alloc_b_v), .alloc_b_id(rob_alloc_b_id),
		.alloc_b_is_load(lsq_alloc_b_load), .alloc_b_is_store(lsq_alloc_b_store),
		.load_exec_valid(lsq_load_exec_valid), .load_exec_id(ex1_mem_rob_id),
		.load_exec_pc(ex1_mem_pc),
		.load_exec_addr(ex1_mem_addr), .load_exec_mask(ex1_mem_mask),
		.store_probe_valid(lsq_store_probe_valid), .store_probe_id(ex1_mem_rob_id),
		.store_probe_pc(ex1_mem_pc),
		.store_probe_addr(ex1_mem_addr), .store_probe_mask(ex1_mem_mask),
		.retire_a_valid(ret_a_valid), .retire_a_id(rob_head),
		.retire_b_valid(ret_b_valid), .retire_b_id(rob_head + 5'd1),
		.query_a_valid(rs_alu0_iss_load), .query_a_id(rs_alu0_iss_rob_id),
		.query_a_pc(rs_alu0_iss_pc), .query_a_block(rs_alu0_load_blocked),
		.query_b_valid(rs_alu1_iss_load), .query_b_id(rs_alu1_iss_rob_id),
		.query_b_pc(rs_alu1_iss_pc), .query_b_block(rs_alu1_load_blocked),
		.ordering_violation(mem_order_violation),
		.violation_load_pc(mem_order_replay_pc),
		.violation_store_pc(mem_order_replay_store_pc),
		.speculative_load_count(lsq_speculative_load_count),
		.ordering_violation_count(lsq_ordering_violation_count)
	);
	always @(*) begin
		ro_a_src1_from_wba = 1'b0;
		if (ro_a_r1 == 5'd0) begin
			ro_a_src1_ok = 1'b1;
			ro_a_src1_passed = 32'd0;
		end
		else if ((EX1_b_valid && (EX1_b_p_dst == rn_a_p_src1)) && !ex1_a_br_mistaken_long) begin
			ro_a_src1_ok = (EX1_b_optype == 3'd0) && !EX1_b_delayed;
			ro_a_src1_passed = alu_b1_result;
		end
		else if (EX1_a_valid && (EX1_a_p_dst == rn_a_p_src1)) begin
			ro_a_src1_ok = EX1_a_optype == 3'd0;
			ro_a_src1_passed = alu_a_result;
		end
		else if (EX2_b_valid && (EX2_b_p_dst == rn_a_p_src1)) begin
			ro_a_src1_ok = EX2_b_optype == 3'd0;
			ro_a_src1_passed = alu_b2_result;
		end
		else if (EX2_a_valid && (EX2_a_p_dst == rn_a_p_src1)) begin
			ro_a_src1_ok = (EX2_a_optype == 3'd0) || ((((EX2_a_optype == 3'd3) && lsu_ok) && (ro_a_optype != 3'd3)) && (ro_a_optype != 3'd6));
			ro_a_src1_from_wba = (((EX2_a_optype == 3'd3) && lsu_ok) && (ro_a_optype != 3'd3)) && (ro_a_optype != 3'd6);
			ro_a_src1_passed = ((EX2_a_optype == 3'd3) && lsu_ok) ? lsu_result : EX2_a_alu_result;
		end
		else if (WB_b_valid && (WB_b_p_dst == rn_a_p_src1)) begin
			ro_a_src1_ok = 1'b1;
			ro_a_src1_passed = WB_b_result;
		end
		else if (WB_a_valid && (WB_a_p_dst == rn_a_p_src1)) begin
			ro_a_src1_ok = 1'b1;
			ro_a_src1_passed = WB_a_result;
		end
		else begin
			ro_a_src1_ok = prf_ready1;
			ro_a_src1_passed = prf_rdata1;
		end
	end
	always @(*) begin
		ro_a_src2_from_wba = 1'b0;
		if (ro_a_src2_is_imm) begin
			ro_a_src2_ok = 1'b1;
			ro_a_src2_passed = ro_a_imm;
		end
		else if (ro_a_r2 == 5'd0) begin
			ro_a_src2_ok = 1'b1;
			ro_a_src2_passed = 32'd0;
		end
		else if ((EX1_b_valid && (EX1_b_p_dst == rn_a_p_src2)) && !ex1_a_br_mistaken_long) begin
			ro_a_src2_ok = (EX1_b_optype == 3'd0) && !EX1_b_delayed;
			ro_a_src2_passed = alu_b1_result;
		end
		else if (EX1_a_valid && (EX1_a_p_dst == rn_a_p_src2)) begin
			ro_a_src2_ok = EX1_a_optype == 3'd0;
			ro_a_src2_passed = alu_a_result;
		end
		else if (EX2_b_valid && (EX2_b_p_dst == rn_a_p_src2)) begin
			ro_a_src2_ok = EX2_b_optype == 3'd0;
			ro_a_src2_passed = alu_b2_result;
		end
		else if (EX2_a_valid && (EX2_a_p_dst == rn_a_p_src2)) begin
			ro_a_src2_ok = (EX2_a_optype == 3'd0) || ((EX2_a_optype == 3'd3) && lsu_ok);
			ro_a_src2_from_wba = (EX2_a_optype == 3'd3) && lsu_ok;
			ro_a_src2_passed = ((EX2_a_optype == 3'd3) && lsu_ok) ? lsu_result : EX2_a_alu_result;
		end
		else if (WB_b_valid && (WB_b_p_dst == rn_a_p_src2)) begin
			ro_a_src2_ok = 1'b1;
			ro_a_src2_passed = WB_b_result;
		end
		else if (WB_a_valid && (WB_a_p_dst == rn_a_p_src2)) begin
			ro_a_src2_ok = 1'b1;
			ro_a_src2_passed = WB_a_result;
		end
		else begin
			ro_a_src2_ok = prf_ready2;
			ro_a_src2_passed = prf_rdata2;
		end
	end
	always @(*) begin
		ro_b_src1_from_wba = 1'b0;
		if (ro_b_r1 == 5'd0) begin
			ro_b_src1_ok = 1'b1;
			ro_b_src1_passed = 32'd0;
		end
		else if (ro_a_valid && (ro_a_dest != 5'd0) && (ro_b_r1 == ro_a_dest)) begin
			ro_b_src1_ok = 1'b0;
			ro_b_src1_passed = 32'd0;
		end
		else if ((EX1_b_valid && (EX1_b_p_dst == rn_b_p_src1)) && !ex1_a_br_mistaken_long) begin
			ro_b_src1_ok = (EX1_b_optype == 3'd0) && !EX1_b_delayed;
			ro_b_src1_passed = alu_b1_result;
		end
		else if (EX1_a_valid && (EX1_a_p_dst == rn_b_p_src1)) begin
			ro_b_src1_ok = EX1_a_optype == 3'd0;
			ro_b_src1_passed = alu_a_result;
		end
		else if (EX2_b_valid && (EX2_b_p_dst == rn_b_p_src1)) begin
			ro_b_src1_ok = EX2_b_optype == 3'd0;
			ro_b_src1_passed = alu_b2_result;
		end
		else if (EX2_a_valid && (EX2_a_p_dst == rn_b_p_src1)) begin
			ro_b_src1_ok = (EX2_a_optype == 3'd0) || (((EX2_a_optype == 3'd3) && lsu_ok) && (ro_b_optype != 3'd3));
			ro_b_src1_from_wba = ((EX2_a_optype == 3'd3) && lsu_ok) && (ro_b_optype != 3'd3);
			ro_b_src1_passed = ((EX2_a_optype == 3'd3) && lsu_ok) ? lsu_result : EX2_a_alu_result;
		end
		else if (WB_b_valid && (WB_b_p_dst == rn_b_p_src1)) begin
			ro_b_src1_ok = 1'b1;
			ro_b_src1_passed = WB_b_result;
		end
		else if (WB_a_valid && (WB_a_p_dst == rn_b_p_src1)) begin
			ro_b_src1_ok = 1'b1;
			ro_b_src1_passed = WB_a_result;
		end
		else begin
			ro_b_src1_ok = prf_ready3;
			ro_b_src1_passed = prf_rdata3;
		end
	end
	always @(*) begin
		ro_b_src2_from_wba = 1'b0;
		if (ro_b_src2_is_imm) begin
			ro_b_src2_ok = 1'b1;
			ro_b_src2_passed = ro_b_imm;
		end
		else if (ro_b_r2 == 5'd0) begin
			ro_b_src2_ok = 1'b1;
			ro_b_src2_passed = 32'd0;
		end
		else if (ro_a_valid && (ro_a_dest != 5'd0) && (ro_b_r2 == ro_a_dest)) begin
			ro_b_src2_ok = 1'b0;
			ro_b_src2_passed = 32'd0;
		end
		else if ((EX1_b_valid && (EX1_b_p_dst == rn_b_p_src2)) && !ex1_a_br_mistaken_long) begin
			ro_b_src2_ok = (EX1_b_optype == 3'd0) && !EX1_b_delayed;
			ro_b_src2_passed = alu_b1_result;
		end
		else if (EX1_a_valid && (EX1_a_p_dst == rn_b_p_src2)) begin
			ro_b_src2_ok = EX1_a_optype == 3'd0;
			ro_b_src2_passed = alu_a_result;
		end
		else if (EX2_b_valid && (EX2_b_p_dst == rn_b_p_src2)) begin
			ro_b_src2_ok = EX2_b_optype == 3'd0;
			ro_b_src2_passed = alu_b2_result;
		end
		else if (EX2_a_valid && (EX2_a_p_dst == rn_b_p_src2)) begin
			ro_b_src2_ok = (EX2_a_optype == 3'd0) || ((EX2_a_optype == 3'd3) && lsu_ok);
			ro_b_src2_from_wba = (EX2_a_optype == 3'd3) && lsu_ok;
			ro_b_src2_passed = ((EX2_a_optype == 3'd3) && lsu_ok) ? lsu_result : EX2_a_alu_result;
		end
		else if (WB_b_valid && (WB_b_p_dst == rn_b_p_src2)) begin
			ro_b_src2_ok = 1'b1;
			ro_b_src2_passed = WB_b_result;
		end
		else if (WB_a_valid && (WB_a_p_dst == rn_b_p_src2)) begin
			ro_b_src2_ok = 1'b1;
			ro_b_src2_passed = WB_a_result;
		end
		else begin
			ro_b_src2_ok = prf_ready4;
			ro_b_src2_passed = prf_rdata4;
		end
	end
	wire related = ((ro_a_dest == ro_b_r1) || (ro_a_dest == ro_b_r2)) && (ro_a_dest != 5'd0);
	wire b_will_br = ((ro_b_br_type == 3'b010) || (ro_b_br_type == 3'b101)) || (ro_b_br_type == 3'b100);
	assign ro_b_delayed = 1'b0;
	assign ro_b_src1_delayed = 1'b0;
	assign ro_b_src2_delayed = 1'b0;
	wire ro_b_unsupported_serial = (ro_b_optype == 3'd4) ||
	                               (ro_b_optype == 3'd5) ||
	                               (ro_b_optype == 3'd6) ||
	                               ro_b_is_spec_op || ro_b_is_idle ||
	                               ro_b_is_ll || ro_b_is_sc;
	assign allow_issue_a = (!ibuf_no_out && ro_a_valid) && !unresolved_branch && rs_alu0_ready &&
	                       rob_alloc_ready && rename_free_ready && !rename_recovering;
	assign allow_issue_b = (((((((!ibuf_no_out && allow_issue_a) && !ro_a_have_excp) &&
	                       ro_b_valid) && !ro_a_is_spec_op) && !ro_b_is_spec_op) &&
	                       (ro_a_br_type == 3'b000)) && !ro_b_unsupported_serial &&
	                       !((ro_a_optype == 3'd2) && (ro_b_optype == 3'd2))) &&
	                       !((ro_a_optype == 3'd3) && (ro_b_optype == 3'd3)) && rs_alu1_ready;
	assign ibuf_o_size = (ex1_stall ? 2'd0 : (allow_issue_b ? 2'd2 : (allow_issue_a ? 2'd1 : 2'd0)));
	always @(posedge clk) begin
		if (reset || flush_ex1) begin
			EX1_a_valid <= 1'b0;
			EX1_b_valid <= 1'b0;
		end
		else if (!ex1_stall) begin
			EX1_a_valid <= rs_alu0_iss_valid && rs_alu0_issue_allowed;
			EX1_b_valid <= rs_alu1_iss_valid && rs_alu1_issue_allowed;
		end
		if (!ex1_stall && rs_alu0_iss_valid && rs_alu0_issue_allowed) begin
			EX1_a_pc            <= rs_alu0_iss_pc;
			EX1_a_inst          <= rs_alu0_iss_inst;
			EX1_a_p_dst         <= rs_alu0_iss_p_dst;
			EX1_a_p_prev_dst    <= rs_alu0_iss_p_prev_dst;
			EX1_a_rob_id        <= rs_alu0_iss_rob_id;
			EX1_a_optype        <= rs_alu0_iss_optype;
			EX1_a_opcode        <= rs_alu0_iss_opcode;
			EX1_a_dest          <= rs_alu0_iss_dest;
			EX1_a_src1_passed   <= rs_alu0_iss_src1_val;
			EX1_a_src1_from_wba <= rs_alu0_iss_src1_fwba;
			EX1_a_src2_passed   <= rs_alu0_iss_src2_val;
			EX1_a_src2_from_wba <= rs_alu0_iss_src2_fwba;
			EX1_a_imm           <= rs_alu0_iss_imm;
			EX1_a_br_type       <= rs_alu0_iss_br_type;
			EX1_a_br_condition  <= rs_alu0_iss_br_condition;
			EX1_a_br_target     <= rs_alu0_iss_br_target;
			EX1_a_pred_br_taken <= rs_alu0_iss_pred_br_taken;
			EX1_a_pred_br_target<= rs_alu0_iss_pred_br_target;
			EX1_a_br_taken      <= rs_alu0_iss_br_taken;
			EX1_a_have_excp     <= rs_alu0_iss_have_excp;
			EX1_a_excp_type     <= rs_alu0_iss_excp_type;
			EX1_a_csr_addr      <= rs_alu0_iss_csr_addr;
			EX1_a_csr_wr        <= rs_alu0_iss_csr_wr;
			EX1_a_is_spec_op    <= rs_alu0_iss_is_spec_op;
			EX1_a_is_idle       <= rs_alu0_iss_is_idle;
			EX1_a_is_ll         <= rs_alu0_iss_is_ll;
			EX1_a_is_sc         <= rs_alu0_iss_is_sc;
		end
		if (!ex1_stall && rs_alu1_iss_valid && rs_alu1_issue_allowed) begin
			EX1_b_pc            <= rs_alu1_iss_pc;
			EX1_b_inst          <= rs_alu1_iss_inst;
			EX1_b_p_dst         <= rs_alu1_iss_p_dst;
			EX1_b_p_prev_dst    <= rs_alu1_iss_p_prev_dst;
			EX1_b_rob_id        <= rs_alu1_iss_rob_id;
			EX1_b_optype        <= rs_alu1_iss_optype;
			EX1_b_opcode        <= rs_alu1_iss_opcode;
			EX1_b_dest           <= rs_alu1_iss_dest;
			EX1_b_src1_passed   <= rs_alu1_iss_src1_val;
			EX1_b_src1_from_wba <= rs_alu1_iss_src1_fwba;
			EX1_b_src2_passed   <= rs_alu1_iss_src2_val;
			EX1_b_src2_from_wba <= rs_alu1_iss_src2_fwba;
			EX1_b_imm           <= rs_alu1_iss_imm;
			EX1_b_delayed       <= rs_alu1_iss_delayed;
			EX1_b_src1_delayed  <= rs_alu1_iss_src1_delayed;
			EX1_b_src2_delayed  <= rs_alu1_iss_src2_delayed;
			EX1_b_br_type       <= rs_alu1_iss_br_type;
			EX1_b_br_condition  <= rs_alu1_iss_br_condition;
			EX1_b_br_target     <= rs_alu1_iss_br_target;
			EX1_b_pred_br_taken <= rs_alu1_iss_pred_br_taken;
			EX1_b_pred_br_target<= rs_alu1_iss_pred_br_target;
			EX1_b_br_taken      <= rs_alu1_iss_br_taken;
			EX1_b_have_excp     <= rs_alu1_iss_have_excp;
			EX1_b_excp_type     <= rs_alu1_iss_excp_type;
		end
	end
	always @(posedge clk) begin
		EX1_stalling <= ex1_stall;
		if (ex1_stall) begin
			EX1_a_src1_stalled <= ex1_a_src1;
			EX1_a_src2_stalled <= ex1_a_src2;
			EX1_b_src1_stalled <= ex1_b_src1;
			EX1_b_src2_stalled <= ex1_b_src2;
		end
	end
	assign ex1_a_src1 = (EX1_stalling ? EX1_a_src1_stalled : (EX1_a_src1_from_wba ? WB_a_result : EX1_a_src1_passed));
	assign ex1_a_src2 = (EX1_stalling ? EX1_a_src2_stalled : (EX1_a_src2_from_wba ? WB_a_result : EX1_a_src2_passed));
	assign ex1_b_src1 = (EX1_stalling ? EX1_b_src1_stalled : (EX1_b_src1_from_wba ? WB_a_result : EX1_b_src1_passed));
	assign ex1_b_src2 = (EX1_stalling ? EX1_b_src2_stalled : (EX1_b_src2_from_wba ? WB_a_result : EX1_b_src2_passed));
	assign ex1_a_addr = ex1_a_src1 + EX1_a_imm;
	assign ex1_b_addr = ex1_b_src1 + EX1_b_imm;
	reg cacop2_ok_reg;
	wire is_tlbsrch = (EX1_a_valid && (EX1_a_optype == 3'd5)) && (EX1_a_opcode == 6'd0);
	wire is_mem_op = (EX1_a_valid && (EX1_a_optype == 3'd3)) || (EX1_b_valid && (EX1_b_optype == 3'd3));
	// An ordering replay is raised only after the head store request has been
	// accepted. Let that store finish in the cache, then restart at the store.
	// Serializing replays still cancel the current request.
	wire mem_cancel = (raise_excp || serial_replay) || ex1_a_br_mistaken_long;
	assign lsu_valid = (is_mem_op && !ex2_stall) && !mem_cancel;
	assign ex1_ready = ((!lsu_valid || lsu_ready) && (!is_tlbsrch || tlbsrch_ok)) && (!cacop2_valid || cacop2_ok_reg);
	assign ex1_stall = !ex1_ready || ex2_stall;
	alu u_alu_a(
		.opcode(EX1_a_opcode),
		.src1(ex1_a_src1),
		.src2(ex1_a_src2),
		.result(alu_a_result)
	);
	always @(*) begin
		if (EX1_a_br_type == 3'b010) begin
			ex1_a_br_taken = EX1_a_br_condition == alu_a_result[0];
			ex1_a_br_target = EX1_a_br_target;
			ex1_a_br_mistaken_long = EX1_a_valid && (ex1_a_br_taken != EX1_a_pred_br_taken);
		end
		else if ((EX1_a_br_type == 3'b101) || (EX1_a_br_type == 3'b100)) begin
			ex1_a_br_taken = 1'b1;
			ex1_a_br_target = ex1_a_src1 + EX1_a_br_target;
			ex1_a_br_mistaken_long = EX1_a_valid && (!EX1_a_pred_br_taken || (ex1_a_br_target != EX1_a_pred_br_target));
		end
		else begin
			ex1_a_br_taken = 1'b0;
			ex1_a_br_target = 32'd0;
			ex1_a_br_mistaken_long = 1'b0;
		end
	end
	assign ex1_a_br_mistaken = ex1_a_br_mistaken_long && !EX1_stalling;
	alu u_alu_b1(
		.opcode(EX1_b_opcode),
		.src1(ex1_b_src1),
		.src2(ex1_b_src2),
		.result(alu_b1_result)
	);
	always @(*) begin
		if (!EX1_b_delayed && (EX1_b_br_type == 3'b010)) begin
			ex1_b_br_taken = EX1_b_br_condition == alu_b1_result[0];
			ex1_b_br_target = EX1_b_br_target;
			ex1_b_br_mistaken = (EX1_b_valid && !EX1_stalling) && (ex1_b_br_taken != EX1_b_pred_br_taken);
		end
		else if (!EX1_b_delayed && ((EX1_b_br_type == 3'b101) || (EX1_b_br_type == 3'b100))) begin
			ex1_b_br_taken = 1'b1;
			ex1_b_br_target = ex1_b_src1 + EX1_b_br_target;
			ex1_b_br_mistaken = (EX1_b_valid && !EX1_stalling) && (!EX1_b_pred_br_taken || (ex1_b_br_target != EX1_b_pred_br_target));
		end
		else begin
			ex1_b_br_taken = 1'b0;
			ex1_b_br_target = 32'd0;
			ex1_b_br_mistaken = 1'b0;
		end
	end
	mul u_mul_a(
		.clk(clk),
		.valid(((EX1_a_valid && (EX1_a_optype == 3'd1)) && !ex1_stall) && !flush_ex1),
		.opcode(EX1_a_opcode),
		.src1(ex1_a_src1),
		.src2(ex1_a_src2),
		.ok(mul_a_ok),
		.result(mul_a_result)
	);
	mul u_mul_b(
		.clk(clk),
		.valid(((((EX1_b_valid && (EX1_b_optype == 3'd1)) && !ex1_stall) && !ex1_a_br_mistaken_long) && !lsu_have_excp) && !flush_ex1),
		.opcode(EX1_b_opcode),
		.src1(ex1_b_src1),
		.src2(ex1_b_src2),
		.ok(mul_b_ok),
		.result(mul_b_result)
	);
	div u_div(
		.clk(clk),
		.reset(reset),
		.valid((((EX1_a_valid && (EX1_a_optype == 3'd2)) && !ex1_stall) || ((((EX1_b_valid && (EX1_b_optype == 3'd2)) && !ex1_stall) && !ex1_a_br_mistaken_long) && !lsu_have_excp)) && !flush_ex1),
		.opcode((EX1_a_optype == 3'd2 ? EX1_a_opcode : EX1_b_opcode)),
		.src1((EX1_a_optype == 3'd2 ? ex1_a_src1 : ex1_b_src1)),
		.src2((EX1_a_optype == 3'd2 ? ex1_a_src2 : ex1_b_src2)),
		.ok(div_ok),
		.result(div_result)
	);
	lsu u_lsu(
		.clk(clk),
		.reset(reset),
		.valid(lsu_valid),
		.ready(lsu_ready),
		.addr((EX1_a_valid && ((EX1_a_optype == 3'd3) || (EX1_a_optype == 3'd6)) ? ex1_a_addr : ex1_b_addr)),
		.opcode((EX1_a_valid && (EX1_a_optype == 3'd3) ? EX1_a_opcode : EX1_b_opcode)),
		.st_data((EX1_a_valid && (EX1_a_optype == 3'd3) ? ex1_a_src2 : ex1_b_src2)),
		.dcacop_valid(dcacop_valid),
		.cacop_op(cacop_op),
		.cacop2_valid(cacop2_valid),
		.cacop2_ok(cacop2_ok),
		.have_excp(lsu_have_excp),
		.excp_type(lsu_excp_type),
		.ok(lsu_ok),
		.ld_data(lsu_result),
		.dcache_valid(dcache_valid),
		.dcache_op(dcache_op),
		.dcache_tag(dcache_tag),
		.dcache_index(dcache_index),
		.dcache_offset(dcache_offset),
		.dcache_wstrb(dcache_wstrb),
		.dcache_wdata(dcache_wdata),
		.dcache_uncached(dcache_uncached),
		.dcache_size(dcache_size),
		.dcache_addr_ok(dcache_addr_ok),
		.dcache_data_ok(dcache_data_ok),
		.dcache_rdata(dcache_rdata),
		.mmu_valid(mmu_d_valid),
		.mmu_vtag(mmu_d_vtag),
		.mmu_ok(mmu_d_ok),
		.mmu_ptag(mmu_d_ptag),
		.mmu_mat(mmu_d_mat),
		.mmu_page_fault(mmu_d_page_fault),
		.mmu_page_invalid(mmu_d_page_invalid),
		.mmu_page_dirty(mmu_d_page_dirty),
		.mmu_plv_fault(mmu_d_plv_fault)
	);
	reg tlbsrch_valid_reg;
	reg tlbsrch_found_reg;
	reg [4:0] tlbsrch_index_reg;
	always @(posedge clk)
		if (reset || !tlbsrch_valid)
			tlbsrch_valid_reg <= 1'b0;
		else if (!ex1_stall) begin
			tlbsrch_valid_reg <= tlbsrch_valid;
			tlbsrch_found_reg <= tlbsrch_found;
			tlbsrch_index_reg <= tlbsrch_index;
		end
	reg csr_tlb_we_reg;
	reg [88:0] csr_tlb_wdata_reg;
	always @(posedge clk)
		if (reset || !csr_tlb_we)
			csr_tlb_we_reg <= 1'b0;
		else if (!ex1_stall) begin
			csr_tlb_we_reg <= csr_tlb_we;
			csr_tlb_wdata_reg <= csr_tlb_wdata;
		end
	reg [4:0] tlb_idx_reg;
	always @(posedge clk)
		if ((ex1_stall && (EX1_a_optype == 3'd5)) && (EX1_a_opcode == 6'd3))
			tlb_idx_reg <= counter[4:0];
	assign invtlb_valid = (((EX1_a_valid && !EX1_stalling) && (EX1_a_optype == 3'd5)) && (EX1_a_opcode == 6'd4)) && !flush_ex1;
	assign invtlb_op = EX1_a_imm[4:0];
	assign invtlb_asid = ex1_a_src1[9:0];
	assign invtlb_va = ex1_a_src2;
	assign tlb_we = (((EX1_a_valid && !EX1_stalling) && (EX1_a_optype == 3'd5)) && ((EX1_a_opcode == 6'd2) || (EX1_a_opcode == 6'd3))) && !flush_ex1;
	assign tlb_w_index = (EX1_a_opcode == 6'd2 ? csr_tlbidx : counter[4:0]);
	assign tlb_w_entry = csr_tlb_rdata;
	assign tlb_r_index = csr_tlbidx;
	assign csr_tlb_wdata = tlb_r_entry;
	assign tlbsrch_valid = (is_tlbsrch && !ex2_stall) && !flush_ex1;
	assign tlbsrch_vppn = csr_tlb_rdata[88-:19];
	assign csr_tlb_we = ((EX1_a_valid && (EX1_a_optype == 3'd5)) && (EX1_a_opcode == 6'd1)) && !flush_ex1;
	assign icacop_valid = ((EX1_a_valid && (EX1_a_optype == 3'd6)) && (EX1_a_opcode[2:0] == 0)) && cacop_en;
	assign dcacop_valid = ((EX1_a_valid && (EX1_a_optype == 3'd6)) && (EX1_a_opcode[2:0] == 1)) && cacop_en;
	assign cacop_op = EX1_a_opcode[4:3];
	assign cacop2_valid = (EX1_a_valid && (EX1_a_optype == 3'd6)) && (cacop_op == 2);
	assign cacop_en = (!ex2_stall && !flush_ex1) && (!cacop2_valid || (cacop2_ok_reg && !lsu_have_excp));
	always @(posedge clk)
		if (reset || !ex1_stall)
			cacop2_ok_reg <= 1'b0;
		else if (cacop2_ok)
			cacop2_ok_reg <= 1'b1;
	always @(posedge clk) begin
		if (reset) begin
			EX2_a_valid <= 1'b0;
			EX2_b_valid <= 1'b0;
		end
		else if (!ex2_stall) begin
			EX2_a_valid <= (ex1_ready && EX1_a_valid) && !flush_ex1;
			EX2_b_valid <= ((((ex1_ready && EX1_b_valid) && !ex1_a_br_mistaken_long) && !EX1_a_have_excp) && !(lsu_have_excp && (EX1_a_optype == 3'd3))) && !flush_ex1;
		end
		EX2_stalling <= ex2_stall;
		if (((!ex2_stall && ex1_ready) && EX1_a_valid) && !flush_ex1) begin
			EX2_a_pc <= EX1_a_pc;
			EX2_a_inst <= EX1_a_inst;
			EX2_a_p_dst      <= EX1_a_p_dst;
			EX2_a_p_prev_dst <= EX1_a_p_prev_dst;
			EX2_a_rob_id     <= EX1_a_rob_id;
			EX2_a_br_mispred        <= ex1_a_br_mistaken;
			EX2_a_br_actual_target  <= ex1_a_br_target;
			EX2_a_optype <= EX1_a_optype;
			EX2_a_dest <= EX1_a_dest;
			EX2_a_src1 <= ex1_a_src1;
			EX2_a_src2 <= ex1_a_src2;
			EX2_a_alu_result <= alu_a_result;
			EX2_a_br_type <= EX1_a_br_type;
			EX2_a_br_taken <= ex1_a_br_taken || EX1_a_br_taken;
			EX2_a_have_excp <= EX1_a_have_excp || (((EX1_a_optype == 3'd3) || cacop2_valid) && lsu_have_excp);
			EX2_a_excp_type <= (((EX1_a_optype == 3'd3) || cacop2_valid) && lsu_have_excp ? lsu_excp_type : EX1_a_excp_type);
			EX2_a_excp_addr <= ex1_a_addr;
			EX2_a_csr_addr <= EX1_a_csr_addr;
			EX2_a_csr_wr <= EX1_a_csr_wr;
			EX2_a_is_spec_op <= EX1_a_is_spec_op;
			EX2_a_is_idle <= EX1_a_is_idle;
			EX2_a_is_ll <= EX1_a_is_ll;
			EX2_a_is_sc <= EX1_a_is_sc;
		end
		if ((((!ex2_stall && ex1_ready) && EX1_b_valid) && !flush_ex1) && !ex1_a_br_mistaken) begin
			EX2_b_pc <= EX1_b_pc;
			EX2_b_inst <= EX1_b_inst;
			EX2_b_p_dst      <= EX1_b_p_dst;
			EX2_b_p_prev_dst <= EX1_b_p_prev_dst;
			EX2_b_rob_id     <= EX1_b_rob_id;
			EX2_b_br_mispred        <= ex1_b_br_mistaken;
			EX2_b_br_actual_target  <= ex1_b_br_target;
			EX2_b_delayed <= EX1_b_delayed;
			EX2_b_optype <= EX1_b_optype;
			EX2_b_opcode <= EX1_b_opcode;
			EX2_b_dest <= EX1_b_dest;
			EX2_b_src1 <= (EX1_b_src1_delayed ? alu_a_result : ex1_b_src1);
			EX2_b_src2 <= (EX1_b_src2_delayed ? alu_a_result : ex1_b_src2);
			EX2_b_alu_result <= alu_b1_result;
			EX2_b_imm <= EX1_b_imm;
			EX2_b_br_type <= EX1_b_br_type;
			EX2_b_br_taken <= ex1_b_br_taken || EX1_b_br_taken;
			EX2_b_have_excp <= EX1_b_have_excp || ((EX1_b_optype == 3'd3) && lsu_have_excp);
			EX2_b_excp_type <= ((EX1_b_optype == 3'd3) && lsu_have_excp ? lsu_excp_type : EX1_b_excp_type);
			EX2_b_excp_addr <= ex1_b_addr;
		end
	end
	assign ex2_have_excp = (EX2_a_valid && EX2_a_have_excp) || (EX2_b_valid && EX2_b_have_excp);
	wire raw_ex2_a_excp = EX2_a_valid && EX2_a_have_excp;
	wire [14:0] raw_ex2_excp_type = raw_ex2_a_excp ? EX2_a_excp_type : EX2_b_excp_type;
	wire [31:0] raw_ex2_excp_pc = raw_ex2_a_excp ? EX2_a_pc : EX2_b_pc;
	wire [31:0] raw_ex2_excp_addr = raw_ex2_a_excp ? EX2_a_excp_addr : EX2_b_excp_addr;
	wire [4:0] raw_ex2_excp_rob_id = raw_ex2_a_excp ? EX2_a_rob_id : EX2_b_rob_id;
	wire retire_excp_now = ret_a_valid && ret_a_have_excp;
	wire ex2_head_excp_now = ex2_have_excp && !EX2_stalling &&
	                         (raw_ex2_excp_rob_id == rob_head);
	assign ex2_excp_type = retire_excp_now ? ret_a_excp_type : raw_ex2_excp_type;
	assign ex2_excp_pc = retire_excp_now ? ret_a_pc : raw_ex2_excp_pc;
	assign ex2_excp_addr = retire_excp_now ? ret_a_excp_addr : raw_ex2_excp_addr;
	assign raise_excp = retire_excp_now || ex2_head_excp_now;
	// Stage 4c: commit-triggered exception + walk-back signals.
	// - raise_excp_c: for csr.v — delivers ERA/ESTAT update at ROB commit
	//   (deferred 1 cycle from EX2). Walk-back for mispredict is observable
	//   but NOT load-bearing until Stage 6 provides SQ (see DESIGN_OOO.md).
	// - walk_back: infrastructure signal for Stage 4d/6. Currently observable
	//   only; pipeline flushes stay immediate (see Stage 6 prerequisite note).
	wire raise_excp_c = retire_excp_now;
	wire walk_back    = ret_a_valid & (ret_a_have_excp | ret_a_br_mispred);
	assign csr_badv_we = raise_excp && (((((((((ex2_excp_type == 15'h7a00) || (ex2_excp_type == 15'h7c00)) || (ex2_excp_type == 15'h1000)) || (ex2_excp_type == 15'h1200)) || (ex2_excp_type == 15'h0200)) || (ex2_excp_type == 15'h0400)) || (ex2_excp_type == 15'h0600)) || (ex2_excp_type == 15'h0800)) || (ex2_excp_type == 15'h0e00));
	assign csr_badv_wdata = (((ex2_excp_type == 15'h1000) || (ex2_excp_type == 15'h0600)) || (ex2_excp_type == 15'h7a00) ? ex2_excp_pc : ex2_excp_addr);
	assign csr_vppn_we = raise_excp && (((((((ex2_excp_type == 15'h7a00) || (ex2_excp_type == 15'h7c00)) || (ex2_excp_type == 15'h0200)) || (ex2_excp_type == 15'h0400)) || (ex2_excp_type == 15'h0600)) || (ex2_excp_type == 15'h0800)) || (ex2_excp_type == 15'h0e00));
	assign csr_vppn_wdata = ((ex2_excp_type == 15'h0600) || (ex2_excp_type == 15'h7a00) ? ex2_excp_pc[31:13] : ex2_excp_addr[31:13]);
	assign idle = EX2_a_valid && EX2_a_is_idle;
	assign csr_llbit_we = (EX2_a_valid && !EX2_a_have_excp) && (EX2_a_is_ll || EX2_a_is_sc);
	assign csr_llbit_wdata = EX2_a_is_ll;
	assign ex2_a_ok = !((((EX2_a_optype == 3'd2) && !div_ok) || ((EX2_a_optype == 3'd1) && !mul_a_ok)) || (((EX2_a_optype == 3'd3) && !lsu_ok) && !EX2_a_have_excp));
	assign ex2_b_ok = !((((EX2_b_optype == 3'd2) && !div_ok) || ((EX2_b_optype == 3'd1) && !mul_b_ok)) || (((EX2_b_optype == 3'd3) && !lsu_ok) && !EX2_b_have_excp));
	assign ex2_stall = ((EX2_a_valid && !ex2_a_ok) && !WB_a_ok) || ((EX2_b_valid && !ex2_b_ok) && !WB_b_ok);
	alu u_alu_b2(
		.opcode(EX2_b_opcode),
		.src1(EX2_b_src1),
		.src2(EX2_b_src2),
		.result(alu_b2_result)
	);
	assign serial_replay = (!EX2_stalling && EX2_a_valid) && EX2_a_is_spec_op;
	assign replay = serial_replay || mem_order_violation;
	assign replay_target = mem_order_violation ? mem_order_replay_store_pc : (EX2_a_pc + 32'd4);
	always @(posedge clk) begin
		if (reset) begin
			WB_a_valid <= 1'b0;
			WB_b_valid <= 1'b0;
		end
		else begin
			WB_a_valid <= !ex2_stall && EX2_a_valid;
			WB_b_valid <= !ex2_stall && EX2_b_valid;
		end
		if (!ex2_stall && EX2_a_valid) begin
			WB_a_pc <= EX2_a_pc;
			WB_a_inst <= EX2_a_inst;
			WB_a_p_dst      <= EX2_a_p_dst;
			WB_a_p_prev_dst <= EX2_a_p_prev_dst;
			WB_a_rob_id     <= EX2_a_rob_id;
			WB_a_br_mispred        <= EX2_a_br_mispred;
			WB_a_br_actual_target  <= EX2_a_br_actual_target;
			WB_a_dest <= (EX2_a_have_excp ? 0 : EX2_a_dest);
			WB_a_br_type <= EX2_a_br_type;
			WB_a_br_taken <= EX2_a_br_taken;
			WB_a_have_excp <= EX2_a_have_excp;
			WB_a_excp_type <= EX2_a_excp_type;
			WB_a_excp_addr <= EX2_a_excp_addr;
		end
		if (!ex2_stall && EX2_b_valid) begin
			WB_b_pc <= EX2_b_pc;
			WB_b_inst <= EX2_b_inst;
			WB_b_p_dst      <= EX2_b_p_dst;
			WB_b_p_prev_dst <= EX2_b_p_prev_dst;
			WB_b_rob_id     <= EX2_b_rob_id;
			WB_b_br_mispred        <= EX2_b_br_mispred;
			WB_b_br_actual_target  <= EX2_b_br_actual_target;
			WB_b_dest <= (EX2_b_have_excp ? 0 : EX2_b_dest);
			WB_b_br_type <= EX2_b_br_type;
			WB_b_br_taken <= EX2_b_br_taken;
			WB_b_have_excp <= EX2_b_have_excp;
			WB_b_excp_type <= EX2_b_excp_type;
			WB_b_excp_addr <= EX2_b_excp_addr;
		end
	end
	assign update_orien_en = (WB_a_valid && (WB_a_br_type == 3'b010)) || (WB_b_valid && (WB_b_br_type == 3'b010));
	assign retire_pc = (WB_a_valid && (WB_a_br_type == 3'b010) ? WB_a_pc : WB_b_pc);
	assign right_orien = (WB_a_valid && (WB_a_br_type == 3'b010) ? WB_a_br_taken : WB_b_br_taken);
	always @(posedge clk)
		if (reset)
			WB_a_ok <= 1'b0;
		else begin
			if (ex2_a_ok && !WB_a_ok) begin
				if (ex2_stall)
					WB_a_ok <= 1'b1;
				(* full_case, parallel_case *)
				case (EX2_a_optype)
					3'd0: WB_a_result <= (EX2_a_is_sc ? 32'd0 : EX2_a_alu_result);
					3'd1: WB_a_result <= mul_a_result;
					3'd2: WB_a_result <= div_result;
					3'd3: WB_a_result <= (EX2_a_is_sc ? 32'd1 : lsu_result);
					3'd4: WB_a_result <= csr_rdata;
					default: WB_a_result <= 32'd0;
				endcase
			end
			if (!ex2_stall)
				WB_a_ok <= 1'b0;
		end
	always @(posedge clk)
		if (reset)
			WB_b_ok <= 1'b0;
		else begin
			if (ex2_b_ok && !WB_b_ok) begin
				if (ex2_stall)
					WB_b_ok <= 1'b1;
				(* full_case, parallel_case *)
				case (EX2_b_optype)
					3'd0: WB_b_result <= (EX2_b_delayed ? alu_b2_result : EX2_b_alu_result);
					3'd1: WB_b_result <= mul_b_result;
					3'd2: WB_b_result <= div_result;
					3'd3: WB_b_result <= lsu_result;
					default: WB_b_result <= 32'd0;
				endcase
			end
			if (!ex2_stall)
				WB_b_ok <= 1'b0;
		end
	// Stage 4b: arch RF and rename commit sourced from ROB retire (was WB).
	// Under in-order execution, retire fires same cycle as WB completion via
	// the ROB's same-cycle bypass — arch RF NBA timing unchanged from baseline.
	assign rf_we1    = ret_a_valid && !ret_a_have_excp && ret_a_has_dest;
	assign rf_waddr1 = ret_a_dest;
	assign rf_wdata1 = ret_a_result;
	assign rf_we2    = ret_b_valid && !ret_b_have_excp && ret_b_has_dest;
	assign rf_waddr2 = ret_b_dest;
	assign rf_wdata2 = ret_b_result;
	assign debug_status0 = {
		rob_occ, rob_head, rob_tail, rs_alu0_occ, rs_alu1_occ,
		rs_alu0_iss_rob_id, rob_head_valid, rob_head_done, ex1_stall
	};
	assign debug_status1 = {
		rs_alu1_iss_rob_id,
		rs_alu0_iss_valid, rs_alu0_issue_allowed,
		rs_alu1_iss_valid, rs_alu1_issue_allowed,
		EX1_a_valid, EX1_b_valid, EX2_a_valid, EX2_b_valid,
		WB_a_valid, WB_b_valid,
		lsu_valid, lsu_ready, lsu_ok,
		ex1_stall, ex2_stall, unresolved_branch, rename_recovering,
		prf_ready1, prf_ready2, prf_ready3, prf_ready4,
		allow_issue_a, allow_issue_b, rob_alloc_ready, rename_free_ready,
		mem_order_violation, replay
	};
	always @(posedge clk) begin
		debug0_wb_pc <= WB_a_pc;
		debug0_wb_rf_wen <= {4 {WB_a_valid && !WB_a_have_excp}};
		debug0_wb_rf_wnum <= WB_a_dest;
		debug0_wb_rf_wdata <= WB_a_result;
		debug1_wb_pc <= WB_b_pc;
		debug1_wb_rf_wen <= {4 {WB_b_valid && !WB_b_have_excp}};
		debug1_wb_rf_wnum <= WB_b_dest;
		debug1_wb_rf_wdata <= WB_b_result;
	end
	csr u_csr(
		.clk(clk),
		.reset(reset),
		.ext_int(ext_int),
		.addr(EX2_a_csr_addr),
		.rdata(csr_rdata),
		.we(EX2_a_valid && (EX2_a_optype == 3'd4)),
		.mask((EX2_a_csr_wr ? 32'hffffffff : EX2_a_src1)),
		.wdata(EX2_a_src2),
		.raise_excp(raise_excp),
		.excp_type(ex2_excp_type),
		.pc_in(ex2_excp_pc),
		.pc_out(excp_target),
		.interrupt(interrupt),
		.badv_we(csr_badv_we),
		.badv_data(csr_badv_wdata),
		.vppn_we(csr_vppn_we),
		.vppn_data(csr_vppn_wdata),
		.csr_tlbsrch_we(tlbsrch_valid_reg),
		.csr_tlbsrch_found(tlbsrch_found_reg),
		.csr_tlbsrch_index(tlbsrch_index_reg),
		.csr_tlb_we(csr_tlb_we_reg),
		.csr_tlb_wdata(csr_tlb_wdata_reg),
		.csr_tlb_rdata(csr_tlb_rdata),
		.csr_tlbidx(csr_tlbidx),
		.csr_asid(csr_asid),
		.csr_da(csr_da),
		.csr_datf(csr_datf),
		.csr_datm(csr_datm),
		.csr_plv(csr_plv),
		.csr_dmw0(csr_dmw0),
		.csr_dmw1(csr_dmw1),
		.csr_llbit(csr_llbit),
		.csr_llbit_we(csr_llbit_we),
		.csr_llbit_wdata(csr_llbit_wdata)
	);

	mmu u_mmu(
		.clk(clk),
		.reset(reset),
		.da(csr_da),
		.datf(csr_datf),
		.datm(csr_datm),
		.plv(csr_plv),
		.asid(csr_asid),
		.dmw0(csr_dmw0),
		.dmw1(csr_dmw1),
		.i_valid(mmu_i_valid),
		.i_vtag(mmu_i_vtag),
		.i_ok(mmu_i_ok),
		.i_ptag(mmu_i_ptag),
		.i_mat(mmu_i_mat),
		.i_page_fault(mmu_i_page_fault),
		.i_page_invalid(mmu_i_page_invalid),
		.i_plv_fault(mmu_i_plv_fault),
		.d_valid(mmu_d_valid),
		.d_vtag(mmu_d_vtag),
		.d_ok(mmu_d_ok),
		.d_ptag(mmu_d_ptag),
		.d_mat(mmu_d_mat),
		.d_page_fault(mmu_d_page_fault),
		.d_page_invalid(mmu_d_page_invalid),
		.d_page_dirty(mmu_d_page_dirty),
		.d_plv_fault(mmu_d_plv_fault),
		.tlb_we(tlb_we),
		.tlb_w_index(tlb_w_index),
		.tlb_w_entry(tlb_w_entry),
		.tlb_r_index(tlb_r_index),
		.tlb_r_entry(tlb_r_entry),
		.is_tlbsrch(is_tlbsrch),
		.tlbsrch_valid(tlbsrch_valid),
		.tlbsrch_vppn(tlbsrch_vppn),
		.tlbsrch_ok(tlbsrch_ok),
		.tlbsrch_found(tlbsrch_found),
		.tlbsrch_index(tlbsrch_index),
		.invtlb_valid(invtlb_valid),
		.invtlb_op(invtlb_op),
		.invtlb_asid(invtlb_asid),
		.invtlb_va(invtlb_va)
	);
endmodule
