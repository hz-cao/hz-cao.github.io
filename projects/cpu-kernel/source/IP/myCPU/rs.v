// Stage 3b — Reservation Station (full field carry + passthrough).
//
// Holds up to ENTRIES pending instructions between dispatch and EX1. Carries
// the full ~30-field EX1 payload as VALUES (not just phys tags), so wakeup
// broadcasts include values and issue drives EX1 fill directly.
//
// Design decisions (per Stage 3b sign-off):
//   - Store src values in-entry (Q1: yes).
//   - 4 wakeup taps per entry (EX1_a, EX1_b, WB_a, WB_b) — semantically clean
//     over the same-cycle-tag corner (Q2: yes).
//   - Same-cycle passthrough when occ=0 AND ins ready — IPC parity fast path.
//   - `delayed` fields preserve baseline ro_b_delayed / from_wba semantics
//     (Q3: option a) — the RS carries them through to EX1 unchanged.
//
// Slot A vs slot B: slot A uses the full field superset. Slot B uses the
// same superset but the extras (delayed, src1/2_delayed) come alive. Slot A
// ties those to 0 at insert; verilator optimizes unused paths.

module rs #(
	parameter ENTRIES = 8,
	parameter IDX_W   = 3,
	parameter PHYS_W  = 6
) (
	clk, reset, flush, rob_head,

	// ---- Insert (single-wide) ----
	ins_valid,
	ins_pc, ins_inst, ins_p_dst, ins_p_prev_dst, ins_optype, ins_opcode, ins_dest,
	ins_src1_val, ins_src1_ready, ins_p_src1, ins_src1_from_wba,
	ins_src2_val, ins_src2_ready, ins_p_src2, ins_src2_from_wba,
	ins_imm,
	ins_br_type, ins_br_condition, ins_br_target,
	ins_pred_br_taken, ins_pred_br_target, ins_br_taken,
	ins_have_excp, ins_excp_type,
	ins_csr_addr, ins_csr_wr,
	ins_is_spec_op, ins_is_idle, ins_is_ll, ins_is_sc,
	ins_delayed, ins_src1_delayed, ins_src2_delayed,
	ins_rob_id,

	// ---- 4 wakeup taps ----
	wake0_valid, wake0_tag, wake0_val,
	wake1_valid, wake1_tag, wake1_val,
	wake2_valid, wake2_tag, wake2_val,
	wake3_valid, wake3_tag, wake3_val,

	// ---- Issue outputs (mirror insert set) ----
	iss_valid,
	iss_pc, iss_inst, iss_p_dst, iss_p_prev_dst, iss_optype, iss_opcode, iss_dest,
	iss_src1_val, iss_p_src1, iss_src1_from_wba,
	iss_src2_val, iss_p_src2, iss_src2_from_wba,
	iss_imm,
	iss_br_type, iss_br_condition, iss_br_target,
	iss_pred_br_taken, iss_pred_br_target, iss_br_taken,
	iss_have_excp, iss_excp_type,
	iss_csr_addr, iss_csr_wr,
	iss_is_spec_op, iss_is_idle, iss_is_ll, iss_is_sc,
	iss_delayed, iss_src1_delayed, iss_src2_delayed,
	iss_rob_id,
	iss_accepted,

	// ---- Status ----
	ready_for_ins,
	occupancy
);
	input clk, reset, flush;
	input [4:0] rob_head;

	// Insert ports
	input ins_valid;
	input [31:0] ins_pc, ins_inst;
	input [PHYS_W-1:0] ins_p_dst, ins_p_prev_dst;
	input [2:0]  ins_optype;
	input [5:0]  ins_opcode;
	input [4:0]  ins_dest;
	input [31:0] ins_src1_val;
	input        ins_src1_ready;
	input [PHYS_W-1:0] ins_p_src1;
	input        ins_src1_from_wba;
	input [31:0] ins_src2_val;
	input        ins_src2_ready;
	input [PHYS_W-1:0] ins_p_src2;
	input        ins_src2_from_wba;
	input [31:0] ins_imm;
	input [2:0]  ins_br_type;
	input        ins_br_condition;
	input [31:0] ins_br_target;
	input        ins_pred_br_taken;
	input [31:0] ins_pred_br_target;
	input        ins_br_taken;
	input        ins_have_excp;
	input [14:0] ins_excp_type;
	input [13:0] ins_csr_addr;
	input        ins_csr_wr;
	input        ins_is_spec_op, ins_is_idle, ins_is_ll, ins_is_sc;
	input        ins_delayed, ins_src1_delayed, ins_src2_delayed;
	input [4:0]  ins_rob_id;

	// Wakeup taps
	input wake0_valid; input [PHYS_W-1:0] wake0_tag; input [31:0] wake0_val;
	input wake1_valid; input [PHYS_W-1:0] wake1_tag; input [31:0] wake1_val;
	input wake2_valid; input [PHYS_W-1:0] wake2_tag; input [31:0] wake2_val;
	input wake3_valid; input [PHYS_W-1:0] wake3_tag; input [31:0] wake3_val;

	// Issue outputs
	output wire iss_valid;
	output wire [31:0] iss_pc, iss_inst;
	output wire [PHYS_W-1:0] iss_p_dst, iss_p_prev_dst;
	output wire [2:0]  iss_optype;
	output wire [5:0]  iss_opcode;
	output wire [4:0]  iss_dest;
	output wire [31:0] iss_src1_val;
	output wire [PHYS_W-1:0] iss_p_src1;
	output wire        iss_src1_from_wba;
	output wire [31:0] iss_src2_val;
	output wire [PHYS_W-1:0] iss_p_src2;
	output wire        iss_src2_from_wba;
	output wire [31:0] iss_imm;
	output wire [2:0]  iss_br_type;
	output wire        iss_br_condition;
	output wire [31:0] iss_br_target;
	output wire        iss_pred_br_taken;
	output wire [31:0] iss_pred_br_target;
	output wire        iss_br_taken;
	output wire        iss_have_excp;
	output wire [14:0] iss_excp_type;
	output wire [13:0] iss_csr_addr;
	output wire        iss_csr_wr;
	output wire        iss_is_spec_op, iss_is_idle, iss_is_ll, iss_is_sc;
	output wire        iss_delayed, iss_src1_delayed, iss_src2_delayed;
	output wire [4:0]  iss_rob_id;
	input              iss_accepted;

	output wire ready_for_ins;
	output wire [IDX_W:0] occupancy;

	// ====================================================================
	// Storage (per entry)
	// ====================================================================
	reg              e_valid       [0:ENTRIES-1];
	reg [31:0]       e_pc          [0:ENTRIES-1];
	reg [31:0]       e_inst        [0:ENTRIES-1];
	reg [PHYS_W-1:0] e_p_dst       [0:ENTRIES-1];
	reg [PHYS_W-1:0] e_p_prev_dst  [0:ENTRIES-1];
	reg [2:0]        e_optype      [0:ENTRIES-1];
	reg [5:0]        e_opcode      [0:ENTRIES-1];
	reg [4:0]        e_dest        [0:ENTRIES-1];
	reg [31:0]       e_src1_val    [0:ENTRIES-1];
	reg              e_src1_ready  [0:ENTRIES-1];
	reg [PHYS_W-1:0] e_p_src1      [0:ENTRIES-1];
	reg              e_src1_fwba   [0:ENTRIES-1];
	reg [31:0]       e_src2_val    [0:ENTRIES-1];
	reg              e_src2_ready  [0:ENTRIES-1];
	reg [PHYS_W-1:0] e_p_src2      [0:ENTRIES-1];
	reg              e_src2_fwba   [0:ENTRIES-1];
	reg [31:0]       e_imm         [0:ENTRIES-1];
	reg [2:0]        e_br_type     [0:ENTRIES-1];
	reg              e_br_cond     [0:ENTRIES-1];
	reg [31:0]       e_br_target   [0:ENTRIES-1];
	reg              e_pred_taken  [0:ENTRIES-1];
	reg [31:0]       e_pred_target [0:ENTRIES-1];
	reg              e_br_taken    [0:ENTRIES-1];
	reg              e_have_excp   [0:ENTRIES-1];
	reg [14:0]       e_excp_type   [0:ENTRIES-1];
	reg [13:0]       e_csr_addr    [0:ENTRIES-1];
	reg              e_csr_wr      [0:ENTRIES-1];
	reg              e_is_spec_op  [0:ENTRIES-1];
	reg              e_is_idle     [0:ENTRIES-1];
	reg              e_is_ll       [0:ENTRIES-1];
	reg              e_is_sc       [0:ENTRIES-1];
	reg              e_delayed     [0:ENTRIES-1];
	reg              e_src1_delayed[0:ENTRIES-1];
	reg              e_src2_delayed[0:ENTRIES-1];
	reg [4:0]        e_rob_id      [0:ENTRIES-1];
	integer ii;
	initial begin
		for (ii = 0; ii < ENTRIES; ii = ii + 1) begin
			e_valid[ii] = 1'b0;
			e_src1_ready[ii] = 1'b0;
			e_src2_ready[ii] = 1'b0;
		end
	end

	// ====================================================================
	// Ready mask and oldest-ready select
	// ====================================================================
	wire [ENTRIES-1:0] ready_mask;
	genvar gi;
	generate
		for (gi = 0; gi < ENTRIES; gi = gi + 1) begin : gen_ready
			assign ready_mask[gi] = e_valid[gi] & e_src1_ready[gi] & e_src2_ready[gi];
		end
	endgenerate

	wire [4:0] dist0 = e_rob_id[0] - rob_head;
	wire [4:0] dist1 = e_rob_id[1] - rob_head;
	wire [4:0] dist2 = e_rob_id[2] - rob_head;
	wire [4:0] dist3 = e_rob_id[3] - rob_head;
	wire [4:0] dist4 = e_rob_id[4] - rob_head;
	wire [4:0] dist5 = e_rob_id[5] - rob_head;
	wire [4:0] dist6 = e_rob_id[6] - rob_head;
	wire [4:0] dist7 = e_rob_id[7] - rob_head;
	reg pair0_valid, pair1_valid, pair2_valid, pair3_valid;
	reg [IDX_W-1:0] pair0_idx, pair1_idx, pair2_idx, pair3_idx;
	reg [4:0] pair0_dist, pair1_dist, pair2_dist, pair3_dist;
	reg group0_valid, group1_valid;
	reg [IDX_W-1:0] group0_idx, group1_idx;
	reg [4:0] group0_dist, group1_dist;
	reg sel_found;
	reg [IDX_W-1:0] sel_idx;
	always @(*) begin
		pair0_valid = ready_mask[0] | ready_mask[1];
		if (!ready_mask[0]) begin pair0_idx = 1; pair0_dist = dist1; end
		else if (!ready_mask[1] || (dist0 <= dist1)) begin pair0_idx = 0; pair0_dist = dist0; end
		else begin pair0_idx = 1; pair0_dist = dist1; end
		pair1_valid = ready_mask[2] | ready_mask[3];
		if (!ready_mask[2]) begin pair1_idx = 3; pair1_dist = dist3; end
		else if (!ready_mask[3] || (dist2 <= dist3)) begin pair1_idx = 2; pair1_dist = dist2; end
		else begin pair1_idx = 3; pair1_dist = dist3; end
		pair2_valid = ready_mask[4] | ready_mask[5];
		if (!ready_mask[4]) begin pair2_idx = 5; pair2_dist = dist5; end
		else if (!ready_mask[5] || (dist4 <= dist5)) begin pair2_idx = 4; pair2_dist = dist4; end
		else begin pair2_idx = 5; pair2_dist = dist5; end
		pair3_valid = ready_mask[6] | ready_mask[7];
		if (!ready_mask[6]) begin pair3_idx = 7; pair3_dist = dist7; end
		else if (!ready_mask[7] || (dist6 <= dist7)) begin pair3_idx = 6; pair3_dist = dist6; end
		else begin pair3_idx = 7; pair3_dist = dist7; end

		group0_valid = pair0_valid | pair1_valid;
		if (!pair0_valid) begin group0_idx = pair1_idx; group0_dist = pair1_dist; end
		else if (!pair1_valid || (pair0_dist <= pair1_dist)) begin group0_idx = pair0_idx; group0_dist = pair0_dist; end
		else begin group0_idx = pair1_idx; group0_dist = pair1_dist; end
		group1_valid = pair2_valid | pair3_valid;
		if (!pair2_valid) begin group1_idx = pair3_idx; group1_dist = pair3_dist; end
		else if (!pair3_valid || (pair2_dist <= pair3_dist)) begin group1_idx = pair2_idx; group1_dist = pair2_dist; end
		else begin group1_idx = pair3_idx; group1_dist = pair3_dist; end

		sel_found = group0_valid | group1_valid;
		if (!group0_valid)
			sel_idx = group1_idx;
		else if (!group1_valid || (group0_dist <= group1_dist))
			sel_idx = group0_idx;
		else
			sel_idx = group1_idx;
	end

	// Lowest-index free slot for insert
	reg              free_found;
	reg [IDX_W-1:0]  free_idx;
	integer kk;
	always @(*) begin
		free_found = 1'b0;
		free_idx   = {IDX_W{1'b0}};
		for (kk = ENTRIES-1; kk >= 0; kk = kk - 1) begin
			if (!e_valid[kk]) begin
				free_found = 1'b1;
				free_idx   = kk[IDX_W-1:0];
			end
		end
	end

	assign ready_for_ins = free_found;

	// Occupancy
	reg [IDX_W:0] occ;
	integer mm;
	always @(*) begin
		occ = {(IDX_W+1){1'b0}};
		for (mm = 0; mm < ENTRIES; mm = mm + 1)
			if (e_valid[mm]) occ = occ + 1'b1;
	end
	assign occupancy = occ;

	// ====================================================================
	// Same-cycle passthrough
	//   If occupancy==0 AND ins is fully ready, issue ins directly.
	//   Otherwise, issue the oldest ready stored entry (if any).
	// ====================================================================
	wire can_bypass = (occ == {(IDX_W+1){1'b0}}) &&
	                   ins_valid && ins_src1_ready && ins_src2_ready;

	assign iss_valid          = sel_found | can_bypass;
	assign iss_pc             = sel_found ? e_pc[sel_idx]          : ins_pc;
	assign iss_inst           = sel_found ? e_inst[sel_idx]        : ins_inst;
	assign iss_p_dst          = sel_found ? e_p_dst[sel_idx]       : ins_p_dst;
	assign iss_p_prev_dst     = sel_found ? e_p_prev_dst[sel_idx]  : ins_p_prev_dst;
	assign iss_optype         = sel_found ? e_optype[sel_idx]      : ins_optype;
	assign iss_opcode         = sel_found ? e_opcode[sel_idx]      : ins_opcode;
	assign iss_dest           = sel_found ? e_dest[sel_idx]        : ins_dest;
	assign iss_src1_val       = sel_found ? e_src1_val[sel_idx]    : ins_src1_val;
	assign iss_p_src1         = sel_found ? e_p_src1[sel_idx]      : ins_p_src1;
	assign iss_src1_from_wba  = sel_found ? e_src1_fwba[sel_idx]   : ins_src1_from_wba;
	assign iss_src2_val       = sel_found ? e_src2_val[sel_idx]    : ins_src2_val;
	assign iss_p_src2         = sel_found ? e_p_src2[sel_idx]      : ins_p_src2;
	assign iss_src2_from_wba  = sel_found ? e_src2_fwba[sel_idx]   : ins_src2_from_wba;
	assign iss_imm            = sel_found ? e_imm[sel_idx]         : ins_imm;
	assign iss_br_type        = sel_found ? e_br_type[sel_idx]     : ins_br_type;
	assign iss_br_condition   = sel_found ? e_br_cond[sel_idx]     : ins_br_condition;
	assign iss_br_target      = sel_found ? e_br_target[sel_idx]   : ins_br_target;
	assign iss_pred_br_taken  = sel_found ? e_pred_taken[sel_idx]  : ins_pred_br_taken;
	assign iss_pred_br_target = sel_found ? e_pred_target[sel_idx] : ins_pred_br_target;
	assign iss_br_taken       = sel_found ? e_br_taken[sel_idx]    : ins_br_taken;
	assign iss_have_excp      = sel_found ? e_have_excp[sel_idx]   : ins_have_excp;
	assign iss_excp_type      = sel_found ? e_excp_type[sel_idx]   : ins_excp_type;
	assign iss_csr_addr       = sel_found ? e_csr_addr[sel_idx]    : ins_csr_addr;
	assign iss_csr_wr         = sel_found ? e_csr_wr[sel_idx]      : ins_csr_wr;
	assign iss_is_spec_op     = sel_found ? e_is_spec_op[sel_idx]  : ins_is_spec_op;
	assign iss_is_idle        = sel_found ? e_is_idle[sel_idx]     : ins_is_idle;
	assign iss_is_ll          = sel_found ? e_is_ll[sel_idx]       : ins_is_ll;
	assign iss_is_sc          = sel_found ? e_is_sc[sel_idx]       : ins_is_sc;
	assign iss_delayed        = sel_found ? e_delayed[sel_idx]     : ins_delayed;
	assign iss_src1_delayed   = sel_found ? e_src1_delayed[sel_idx]: ins_src1_delayed;
	assign iss_src2_delayed   = sel_found ? e_src2_delayed[sel_idx]: ins_src2_delayed;
	assign iss_rob_id         = sel_found ? e_rob_id[sel_idx]      : ins_rob_id;

	// If the bypassed instruction is not accepted this cycle, keep it in
	// the RS. Otherwise a downstream issue gate can silently drop it.
	wire ins_goes_to_store = ins_valid && !(can_bypass && iss_accepted);

	// ====================================================================
	// State update
	// ====================================================================
	integer nn;
	always @(posedge clk) begin
		if (reset || flush) begin
			for (nn = 0; nn < ENTRIES; nn = nn + 1)
				e_valid[nn] <= 1'b0;
		end
		else begin
			// Wakeup ready-bit and value update on every valid entry
			for (nn = 0; nn < ENTRIES; nn = nn + 1) begin
				if (e_valid[nn]) begin
					if (!e_src1_ready[nn]) begin
						if (wake0_valid && (e_p_src1[nn] == wake0_tag) && (wake0_tag != {PHYS_W{1'b0}})) begin
							e_src1_ready[nn] <= 1'b1;
							e_src1_val[nn]   <= wake0_val;
							e_src1_fwba[nn]  <= 1'b0;
						end else if (wake1_valid && (e_p_src1[nn] == wake1_tag) && (wake1_tag != {PHYS_W{1'b0}})) begin
							e_src1_ready[nn] <= 1'b1;
							e_src1_val[nn]   <= wake1_val;
							e_src1_fwba[nn]  <= 1'b0;
						end else if (wake2_valid && (e_p_src1[nn] == wake2_tag) && (wake2_tag != {PHYS_W{1'b0}})) begin
							e_src1_ready[nn] <= 1'b1;
							e_src1_val[nn]   <= wake2_val;
							e_src1_fwba[nn]  <= 1'b0;
						end else if (wake3_valid && (e_p_src1[nn] == wake3_tag) && (wake3_tag != {PHYS_W{1'b0}})) begin
							e_src1_ready[nn] <= 1'b1;
							e_src1_val[nn]   <= wake3_val;
							e_src1_fwba[nn]  <= 1'b0;
						end
					end
					if (!e_src2_ready[nn]) begin
						if (wake0_valid && (e_p_src2[nn] == wake0_tag) && (wake0_tag != {PHYS_W{1'b0}})) begin
							e_src2_ready[nn] <= 1'b1;
							e_src2_val[nn]   <= wake0_val;
							e_src2_fwba[nn]  <= 1'b0;
						end else if (wake1_valid && (e_p_src2[nn] == wake1_tag) && (wake1_tag != {PHYS_W{1'b0}})) begin
							e_src2_ready[nn] <= 1'b1;
							e_src2_val[nn]   <= wake1_val;
							e_src2_fwba[nn]  <= 1'b0;
						end else if (wake2_valid && (e_p_src2[nn] == wake2_tag) && (wake2_tag != {PHYS_W{1'b0}})) begin
							e_src2_ready[nn] <= 1'b1;
							e_src2_val[nn]   <= wake2_val;
							e_src2_fwba[nn]  <= 1'b0;
						end else if (wake3_valid && (e_p_src2[nn] == wake3_tag) && (wake3_tag != {PHYS_W{1'b0}})) begin
							e_src2_ready[nn] <= 1'b1;
							e_src2_val[nn]   <= wake3_val;
							e_src2_fwba[nn]  <= 1'b0;
						end
					end
				end
			end

			// Retire selected entry on accepted issue (only for stored path)
			if (sel_found && iss_accepted)
				e_valid[sel_idx] <= 1'b0;

			// Insert new entry (unless passthrough consumed it)
			if (ins_goes_to_store && free_found) begin
				e_valid[free_idx]       <= 1'b1;
				e_pc[free_idx]          <= ins_pc;
				e_inst[free_idx]        <= ins_inst;
				e_p_dst[free_idx]       <= ins_p_dst;
				e_p_prev_dst[free_idx]  <= ins_p_prev_dst;
				e_optype[free_idx]      <= ins_optype;
				e_opcode[free_idx]      <= ins_opcode;
				e_dest[free_idx]        <= ins_dest;
				e_src1_val[free_idx]    <= ins_src1_val;
				e_src1_ready[free_idx]  <= ins_src1_ready;
				e_p_src1[free_idx]      <= ins_p_src1;
				e_src1_fwba[free_idx]   <= 1'b0;
				e_src2_val[free_idx]    <= ins_src2_val;
				e_src2_ready[free_idx]  <= ins_src2_ready;
				e_p_src2[free_idx]      <= ins_p_src2;
				e_src2_fwba[free_idx]   <= 1'b0;
				e_imm[free_idx]         <= ins_imm;
				e_br_type[free_idx]     <= ins_br_type;
				e_br_cond[free_idx]     <= ins_br_condition;
				e_br_target[free_idx]   <= ins_br_target;
				e_pred_taken[free_idx]  <= ins_pred_br_taken;
				e_pred_target[free_idx] <= ins_pred_br_target;
				e_br_taken[free_idx]    <= ins_br_taken;
				e_have_excp[free_idx]   <= ins_have_excp;
				e_excp_type[free_idx]   <= ins_excp_type;
				e_csr_addr[free_idx]    <= ins_csr_addr;
				e_csr_wr[free_idx]      <= ins_csr_wr;
				e_is_spec_op[free_idx]  <= ins_is_spec_op;
				e_is_idle[free_idx]     <= ins_is_idle;
				e_is_ll[free_idx]       <= ins_is_ll;
				e_is_sc[free_idx]       <= ins_is_sc;
				e_delayed[free_idx]     <= ins_delayed;
				e_src1_delayed[free_idx]<= ins_src1_delayed;
				e_src2_delayed[free_idx]<= ins_src2_delayed;
				e_rob_id[free_idx]      <= ins_rob_id;
			end
		end
	end
endmodule
