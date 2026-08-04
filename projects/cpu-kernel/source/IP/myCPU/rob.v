// Stage 4a — Reorder Buffer (SHADOW).
//
// 32-entry ROB tracked in parallel with the existing WB-stage commit path.
// In Stage 4a the ROB's retire outputs are UNUSED — commit still happens at
// WB stage exactly as in Stage 3b. This stage exists to verify allocation,
// completion tracking (via rob_id from WB), retirement pointer advance, and
// flush behavior without any of it being load-bearing yet.
//
// Stage 4b will wire ret_* outputs to drive arch RF, a-RAT, and free-list.
// Stage 4c will hold exceptions until commit and add walk-back.
//
// Stage 4a flush policy: on flush_ex1, invalidate all entries + reset
// head/tail = 0. Post-flush completion signals for pre-flush rob_ids will
// no-op (entry valid=0). Any timing race between reset and completion is
// harmless because retire outputs are unused.

module rob #(
	parameter SIZE = 32,
	parameter ID_W = 5
) (
	clk, reset, flush,
	flush_preserve_high_id, flush_preserve_valid,

	// ---- Allocation (2-way, at tail) ----
	alloc_a_valid,
	alloc_a_pc, alloc_a_inst, alloc_a_p_dst, alloc_a_p_prev_dst,
	alloc_a_dest, alloc_a_is_branch, alloc_a_is_store, alloc_a_is_csr_wr,
	alloc_a_csr_addr, alloc_a_is_ll, alloc_a_is_sc, alloc_a_is_unique,
	alloc_a_id,
	alloc_b_valid,
	alloc_b_pc, alloc_b_inst, alloc_b_p_dst, alloc_b_p_prev_dst,
	alloc_b_dest, alloc_b_is_branch, alloc_b_is_store, alloc_b_is_csr_wr,
	alloc_b_csr_addr, alloc_b_is_ll, alloc_b_is_sc, alloc_b_is_unique,
	alloc_b_id,
	alloc_ready,

	// ---- Completion (from WB stage, via rob_id) ----
	cmp_a_valid, cmp_a_id, cmp_a_result, cmp_a_have_excp, cmp_a_excp_type, cmp_a_excp_addr,
	cmp_a_br_mispredicted, cmp_a_br_actual_target,
	cmp_b_valid, cmp_b_id, cmp_b_result, cmp_b_have_excp, cmp_b_excp_type, cmp_b_excp_addr,
	cmp_b_br_mispredicted, cmp_b_br_actual_target,

	// ---- Retire (from head) — 4b load-bearing, 4c adds br_mispred/target ----
	ret_a_valid, ret_a_pc, ret_a_inst,
	ret_a_p_dst, ret_a_p_prev_dst, ret_a_dest, ret_a_has_dest,
	ret_a_result, ret_a_have_excp, ret_a_excp_type, ret_a_excp_addr,
	ret_a_br_mispred, ret_a_br_actual_target,
	ret_a_is_store, ret_a_is_csr_wr, ret_a_csr_addr,
	ret_a_is_ll, ret_a_is_sc,
	ret_b_valid, ret_b_pc, ret_b_inst,
	ret_b_p_dst, ret_b_p_prev_dst, ret_b_dest, ret_b_has_dest,
	ret_b_result, ret_b_have_excp, ret_b_excp_type, ret_b_excp_addr,
	ret_b_br_mispred, ret_b_br_actual_target,
	ret_b_is_store, ret_b_is_csr_wr, ret_b_csr_addr,
	ret_b_is_ll, ret_b_is_sc,

	// ---- Observability ----
	occupancy, head_ptr, tail_ptr, head_valid, head_done
);
	input clk, reset, flush;
	input [ID_W-1:0] flush_preserve_high_id;
	input flush_preserve_valid;

	input alloc_a_valid;
	input [31:0] alloc_a_pc, alloc_a_inst;
	input [5:0]  alloc_a_p_dst, alloc_a_p_prev_dst;
	input [4:0]  alloc_a_dest;
	input        alloc_a_is_branch, alloc_a_is_store, alloc_a_is_csr_wr;
	input [13:0] alloc_a_csr_addr;
	input        alloc_a_is_ll, alloc_a_is_sc, alloc_a_is_unique;
	output wire [ID_W-1:0] alloc_a_id;

	input alloc_b_valid;
	input [31:0] alloc_b_pc, alloc_b_inst;
	input [5:0]  alloc_b_p_dst, alloc_b_p_prev_dst;
	input [4:0]  alloc_b_dest;
	input        alloc_b_is_branch, alloc_b_is_store, alloc_b_is_csr_wr;
	input [13:0] alloc_b_csr_addr;
	input        alloc_b_is_ll, alloc_b_is_sc, alloc_b_is_unique;
	output wire [ID_W-1:0] alloc_b_id;
	output wire alloc_ready;

	input cmp_a_valid;
	input [ID_W-1:0] cmp_a_id;
	input [31:0] cmp_a_result;
	input        cmp_a_have_excp;
	input [14:0] cmp_a_excp_type;
	input [31:0] cmp_a_excp_addr;
	input        cmp_a_br_mispredicted;
	input [31:0] cmp_a_br_actual_target;
	input cmp_b_valid;
	input [ID_W-1:0] cmp_b_id;
	input [31:0] cmp_b_result;
	input        cmp_b_have_excp;
	input [14:0] cmp_b_excp_type;
	input [31:0] cmp_b_excp_addr;
	input        cmp_b_br_mispredicted;
	input [31:0] cmp_b_br_actual_target;

	output wire ret_a_valid;
	output wire [31:0] ret_a_pc, ret_a_inst;
	output wire [5:0]  ret_a_p_dst, ret_a_p_prev_dst;
	output wire [4:0]  ret_a_dest;
	output wire        ret_a_has_dest;
	output wire [31:0] ret_a_result;
	output wire        ret_a_have_excp;
	output wire [14:0] ret_a_excp_type;
	output wire [31:0] ret_a_excp_addr;
	output wire        ret_a_br_mispred;
	output wire [31:0] ret_a_br_actual_target;
	output wire        ret_a_is_store, ret_a_is_csr_wr;
	output wire [13:0] ret_a_csr_addr;
	output wire        ret_a_is_ll, ret_a_is_sc;
	output wire ret_b_valid;
	output wire [31:0] ret_b_pc, ret_b_inst;
	output wire [5:0]  ret_b_p_dst, ret_b_p_prev_dst;
	output wire [4:0]  ret_b_dest;
	output wire        ret_b_has_dest;
	output wire [31:0] ret_b_result;
	output wire        ret_b_have_excp;
	output wire [14:0] ret_b_excp_type;
	output wire [31:0] ret_b_excp_addr;
	output wire        ret_b_br_mispred;
	output wire [31:0] ret_b_br_actual_target;
	output wire        ret_b_is_store, ret_b_is_csr_wr;
	output wire [13:0] ret_b_csr_addr;
	output wire        ret_b_is_ll, ret_b_is_sc;

	output wire [ID_W:0] occupancy;
	output wire [ID_W-1:0] head_ptr, tail_ptr;
	output wire head_valid, head_done;

	// ---- Storage ----
	reg              e_valid       [0:SIZE-1];
	reg              e_done        [0:SIZE-1];
	reg [31:0]       e_pc          [0:SIZE-1];
	reg [31:0]       e_inst        [0:SIZE-1];
	reg [5:0]        e_p_dst       [0:SIZE-1];
	reg [5:0]        e_p_prev_dst  [0:SIZE-1];
	reg [4:0]        e_dest        [0:SIZE-1];
	reg              e_has_dest    [0:SIZE-1];
	reg [31:0]       e_result      [0:SIZE-1];
	reg              e_have_excp   [0:SIZE-1];
	reg [14:0]       e_excp_type   [0:SIZE-1];
	reg [31:0]       e_excp_addr   [0:SIZE-1];
	reg              e_is_branch   [0:SIZE-1];
	reg              e_br_mispred  [0:SIZE-1];
	reg [31:0]       e_br_target   [0:SIZE-1];
	reg              e_is_store    [0:SIZE-1];
	reg              e_is_csr_wr   [0:SIZE-1];
	reg [13:0]       e_csr_addr    [0:SIZE-1];
	reg              e_is_ll       [0:SIZE-1];
	reg              e_is_sc       [0:SIZE-1];
	reg              e_is_unique   [0:SIZE-1];

	reg [ID_W:0] head, tail;   // (ID_W+1)-bit with wrap

	integer ii;
	initial begin
		for (ii = 0; ii < SIZE; ii = ii + 1) begin
			e_valid[ii] = 1'b0;
			e_done[ii]  = 1'b0;
		end
		head = {(ID_W+1){1'b0}};
		tail = {(ID_W+1){1'b0}};
	end

	// Pointers into storage array
	wire [ID_W-1:0] tail_lo   = tail[ID_W-1:0];
	wire [ID_W-1:0] tail_lo_1 = tail_lo + 1'b1;
	wire [ID_W-1:0] head_lo   = head[ID_W-1:0];
	wire [ID_W-1:0] head_lo_1 = head_lo + 1'b1;

	assign alloc_a_id = tail_lo;
	assign alloc_b_id = tail_lo_1;

	wire [ID_W:0] occ_now = tail - head;
	assign occupancy = occ_now;
	assign head_ptr  = head_lo;
	assign tail_ptr  = tail_lo;
	assign head_valid = e_valid[head_lo];
	assign head_done = e_done[head_lo];
	assign alloc_ready = (occ_now <= (SIZE - 2));

	// Same-cycle completion bypass for retire head entries.
	// When head_lo's rob_id equals a current-cycle cmp_*, use the incoming
	// result / have_excp instead of the not-yet-NBA'd e_done/e_result.
	wire cmp_a_at_h  = cmp_a_valid & (cmp_a_id == head_lo);
	wire cmp_b_at_h  = cmp_b_valid & (cmp_b_id == head_lo);
	wire cmp_a_at_h1 = cmp_a_valid & (cmp_a_id == head_lo_1);
	wire cmp_b_at_h1 = cmp_b_valid & (cmp_b_id == head_lo_1);
	wire h_bypass    = cmp_a_at_h  | cmp_b_at_h;
	wire h1_bypass   = cmp_a_at_h1 | cmp_b_at_h1;
	wire h_done_now  = e_done[head_lo]   | h_bypass;
	wire h1_done_now = e_done[head_lo_1] | h1_bypass;

	wire [31:0] h_bypass_result   = cmp_a_at_h ? cmp_a_result : cmp_b_result;
	wire        h_bypass_excp     = cmp_a_at_h ? cmp_a_have_excp : cmp_b_have_excp;
	wire [14:0] h_bypass_etype    = cmp_a_at_h ? cmp_a_excp_type : cmp_b_excp_type;
	wire [31:0] h_bypass_eaddr    = cmp_a_at_h ? cmp_a_excp_addr : cmp_b_excp_addr;
	wire        h_bypass_br_mp    = cmp_a_at_h ? cmp_a_br_mispredicted : cmp_b_br_mispredicted;
	wire [31:0] h_bypass_br_tgt   = cmp_a_at_h ? cmp_a_br_actual_target : cmp_b_br_actual_target;
	wire [31:0] h1_bypass_result  = cmp_a_at_h1 ? cmp_a_result : cmp_b_result;
	wire        h1_bypass_excp    = cmp_a_at_h1 ? cmp_a_have_excp : cmp_b_have_excp;
	wire [14:0] h1_bypass_etype   = cmp_a_at_h1 ? cmp_a_excp_type : cmp_b_excp_type;
	wire [31:0] h1_bypass_eaddr   = cmp_a_at_h1 ? cmp_a_excp_addr : cmp_b_excp_addr;
	wire        h1_bypass_br_mp   = cmp_a_at_h1 ? cmp_a_br_mispredicted : cmp_b_br_mispredicted;
	wire [31:0] h1_bypass_br_tgt  = cmp_a_at_h1 ? cmp_a_br_actual_target : cmp_b_br_actual_target;

	// Retire fires whenever head is valid and either e_done is 1 or the
	// current cycle brings its completion via bypass. Does NOT gate on
	// have_excp — downstream (arch RF write in core.v) gates that.
	assign ret_a_valid       = e_valid[head_lo] & h_done_now;
	assign ret_a_pc          = e_pc[head_lo];
	assign ret_a_inst        = e_inst[head_lo];
	assign ret_a_p_dst       = e_p_dst[head_lo];
	assign ret_a_p_prev_dst  = e_p_prev_dst[head_lo];
	assign ret_a_dest        = e_dest[head_lo];
	assign ret_a_has_dest    = e_has_dest[head_lo];
	assign ret_a_result      = e_done[head_lo] ? e_result[head_lo]    : h_bypass_result;
	assign ret_a_have_excp   = e_done[head_lo] ? e_have_excp[head_lo] : h_bypass_excp;
	assign ret_a_excp_type   = e_done[head_lo] ? e_excp_type[head_lo] : h_bypass_etype;
	assign ret_a_excp_addr   = e_done[head_lo] ? e_excp_addr[head_lo] : h_bypass_eaddr;
	assign ret_a_br_mispred        = e_done[head_lo] ? e_br_mispred[head_lo] : h_bypass_br_mp;
	assign ret_a_br_actual_target  = e_done[head_lo] ? e_br_target[head_lo]  : h_bypass_br_tgt;
	assign ret_a_is_store    = e_is_store[head_lo];
	assign ret_a_is_csr_wr   = e_is_csr_wr[head_lo];
	assign ret_a_csr_addr    = e_csr_addr[head_lo];
	assign ret_a_is_ll       = e_is_ll[head_lo];
	assign ret_a_is_sc       = e_is_sc[head_lo];
	// Slot B does NOT retire in the same cycle as an exception or mispredict
	// on slot A — a walk-back at slot A squashes everything younger.
	assign ret_b_valid       = ret_a_valid & e_valid[head_lo_1] & h1_done_now
	                           & ~ret_a_have_excp & ~ret_a_br_mispred;
	assign ret_b_pc          = e_pc[head_lo_1];
	assign ret_b_inst        = e_inst[head_lo_1];
	assign ret_b_p_dst       = e_p_dst[head_lo_1];
	assign ret_b_p_prev_dst  = e_p_prev_dst[head_lo_1];
	assign ret_b_dest        = e_dest[head_lo_1];
	assign ret_b_has_dest    = e_has_dest[head_lo_1];
	assign ret_b_result      = e_done[head_lo_1] ? e_result[head_lo_1]    : h1_bypass_result;
	assign ret_b_have_excp   = e_done[head_lo_1] ? e_have_excp[head_lo_1] : h1_bypass_excp;
	assign ret_b_excp_type   = e_done[head_lo_1] ? e_excp_type[head_lo_1] : h1_bypass_etype;
	assign ret_b_excp_addr   = e_done[head_lo_1] ? e_excp_addr[head_lo_1] : h1_bypass_eaddr;
	assign ret_b_br_mispred        = e_done[head_lo_1] ? e_br_mispred[head_lo_1] : h1_bypass_br_mp;
	assign ret_b_br_actual_target  = e_done[head_lo_1] ? e_br_target[head_lo_1]  : h1_bypass_br_tgt;
	assign ret_b_is_store    = e_is_store[head_lo_1];
	assign ret_b_is_csr_wr   = e_is_csr_wr[head_lo_1];
	assign ret_b_csr_addr    = e_csr_addr[head_lo_1];
	assign ret_b_is_ll       = e_is_ll[head_lo_1];
	assign ret_b_is_sc       = e_is_sc[head_lo_1];

	// ---- Wrap-safe flush kill-range boundary ----
	//   Kill entries whose position is in {preserve_high+1, ..., tail_lo-1} mod 32.
	//   New tail_lo = preserve_high + 1; wrap-bit adjusted via 6-bit add of the
	//   preserved count to head.
	wire [4:0] occ_preserved = flush_preserve_high_id - head[ID_W-1:0] + 5'd1;
	wire [ID_W:0] flush_new_tail = head + {1'b0, occ_preserved};

	// ---- State update ----
	integer jj;
	always @(posedge clk) begin
		if (reset || (flush && !flush_preserve_valid)) begin
			// Full reset — reachable via reset OR the untested-by-func_lab3
			// no-EX2-no-WB flush fallback (see DESIGN_OOO.md TODO).
			for (jj = 0; jj < SIZE; jj = jj + 1) begin
				e_valid[jj] <= 1'b0;
				e_done[jj]  <= 1'b0;
			end
			head <= {(ID_W+1){1'b0}};
			tail <= {(ID_W+1){1'b0}};
		end
		else if (flush) begin
			// Partial invalidation: preserve entries in EX2/WB, kill only
			// entries with rob_id in the kill range (EX1/RS entries).
			for (jj = 0; jj < SIZE; jj = jj + 1) begin
				if (e_valid[jj]) begin
					if ( (jj[ID_W-1:0] - flush_preserve_high_id) != 5'd0
					   && (jj[ID_W-1:0] - flush_preserve_high_id)
					        < (tail[ID_W-1:0] - flush_preserve_high_id) )
						e_valid[jj] <= 1'b0;
				end
			end
			tail <= flush_new_tail;

			// A younger EX2 flush can coincide with completion of an older WB
			// instruction. Preserve that completion; it will never be replayed.
			if (cmp_a_valid && e_valid[cmp_a_id]) begin
				e_done[cmp_a_id]       <= 1'b1;
				e_result[cmp_a_id]     <= cmp_a_result;
				e_have_excp[cmp_a_id]  <= cmp_a_have_excp;
				e_excp_type[cmp_a_id]  <= cmp_a_excp_type;
				e_excp_addr[cmp_a_id]  <= cmp_a_excp_addr;
				e_br_mispred[cmp_a_id] <= cmp_a_br_mispredicted;
				e_br_target[cmp_a_id]  <= cmp_a_br_actual_target;
			end
			if (cmp_b_valid && e_valid[cmp_b_id]) begin
				e_done[cmp_b_id]       <= 1'b1;
				e_result[cmp_b_id]     <= cmp_b_result;
				e_have_excp[cmp_b_id]  <= cmp_b_have_excp;
				e_excp_type[cmp_b_id]  <= cmp_b_excp_type;
				e_excp_addr[cmp_b_id]  <= cmp_b_excp_addr;
				e_br_mispred[cmp_b_id] <= cmp_b_br_mispredicted;
				e_br_target[cmp_b_id]  <= cmp_b_br_actual_target;
			end

			// The completion bypass can also make the head retire on this edge.
			if (ret_a_valid)
				e_valid[head_lo] <= 1'b0;
			if (ret_b_valid)
				e_valid[head_lo_1] <= 1'b0;
			head <= head + {{ID_W{1'b0}}, ret_a_valid}
			             + {{ID_W{1'b0}}, ret_b_valid};
		end
		else begin
			// Allocate at tail
			if (alloc_a_valid) begin
				e_valid[tail_lo]      <= 1'b1;
				e_done[tail_lo]       <= 1'b0;
				e_pc[tail_lo]         <= alloc_a_pc;
				e_inst[tail_lo]       <= alloc_a_inst;
				e_p_dst[tail_lo]      <= alloc_a_p_dst;
				e_p_prev_dst[tail_lo] <= alloc_a_p_prev_dst;
				e_dest[tail_lo]       <= alloc_a_dest;
				e_has_dest[tail_lo]   <= (alloc_a_dest != 5'd0);
				e_have_excp[tail_lo]  <= 1'b0;
				e_br_mispred[tail_lo] <= 1'b0;
				e_is_branch[tail_lo]  <= alloc_a_is_branch;
				e_is_store[tail_lo]   <= alloc_a_is_store;
				e_is_csr_wr[tail_lo]  <= alloc_a_is_csr_wr;
				e_csr_addr[tail_lo]   <= alloc_a_csr_addr;
				e_is_ll[tail_lo]      <= alloc_a_is_ll;
				e_is_sc[tail_lo]      <= alloc_a_is_sc;
				e_is_unique[tail_lo]  <= alloc_a_is_unique;
			end
			if (alloc_b_valid) begin
				e_valid[tail_lo_1]      <= 1'b1;
				e_done[tail_lo_1]       <= 1'b0;
				e_pc[tail_lo_1]         <= alloc_b_pc;
				e_inst[tail_lo_1]       <= alloc_b_inst;
				e_p_dst[tail_lo_1]      <= alloc_b_p_dst;
				e_p_prev_dst[tail_lo_1] <= alloc_b_p_prev_dst;
				e_dest[tail_lo_1]       <= alloc_b_dest;
				e_has_dest[tail_lo_1]   <= (alloc_b_dest != 5'd0);
				e_have_excp[tail_lo_1]  <= 1'b0;
				e_br_mispred[tail_lo_1] <= 1'b0;
				e_is_branch[tail_lo_1]  <= alloc_b_is_branch;
				e_is_store[tail_lo_1]   <= alloc_b_is_store;
				e_is_csr_wr[tail_lo_1]  <= alloc_b_is_csr_wr;
				e_csr_addr[tail_lo_1]   <= alloc_b_csr_addr;
				e_is_ll[tail_lo_1]      <= alloc_b_is_ll;
				e_is_sc[tail_lo_1]      <= alloc_b_is_sc;
				e_is_unique[tail_lo_1]  <= alloc_b_is_unique;
			end
			tail <= tail + {{ID_W{1'b0}}, alloc_a_valid} + {{ID_W{1'b0}}, alloc_b_valid};

			// Completion
			if (cmp_a_valid && e_valid[cmp_a_id]) begin
				e_done[cmp_a_id]       <= 1'b1;
				e_result[cmp_a_id]     <= cmp_a_result;
				e_have_excp[cmp_a_id]  <= cmp_a_have_excp;
				e_excp_type[cmp_a_id]  <= cmp_a_excp_type;
				e_excp_addr[cmp_a_id]  <= cmp_a_excp_addr;
				e_br_mispred[cmp_a_id] <= cmp_a_br_mispredicted;
				e_br_target[cmp_a_id]  <= cmp_a_br_actual_target;
			end
			if (cmp_b_valid && e_valid[cmp_b_id]) begin
				e_done[cmp_b_id]       <= 1'b1;
				e_result[cmp_b_id]     <= cmp_b_result;
				e_have_excp[cmp_b_id]  <= cmp_b_have_excp;
				e_excp_type[cmp_b_id]  <= cmp_b_excp_type;
				e_excp_addr[cmp_b_id]  <= cmp_b_excp_addr;
				e_br_mispred[cmp_b_id] <= cmp_b_br_mispredicted;
				e_br_target[cmp_b_id]  <= cmp_b_br_actual_target;
			end

			// Retire at head — invalidate + advance
			if (ret_a_valid)
				e_valid[head_lo] <= 1'b0;
			if (ret_b_valid)
				e_valid[head_lo_1] <= 1'b0;
			head <= head + {{ID_W{1'b0}}, ret_a_valid} + {{ID_W{1'b0}}, ret_b_valid};
		end
	end
endmodule
