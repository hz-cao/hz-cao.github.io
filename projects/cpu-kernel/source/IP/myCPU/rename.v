// Stage 2a — Register renaming module (RAT + free list).
//
// Passive shadow: this module tracks the arch->physical mapping for every
// dispatched instruction and updates on every committed instruction. It does
// NOT participate in the execution path yet (Stage 2b will switch operand
// reads to physical tags). All src-rename outputs are provided for Stage 2b
// consumers; in Stage 2a they are unused and verilator may warn accordingly.
//
// Conventions:
//   - r0 (arch reg 0) is always mapped to physical reg 0. r0 is never
//     renamed; instructions writing to r0 do not allocate a physical reg
//     (p_dst = 6'd0 as a "no-alloc" sentinel).
//   - Initial mapping: arch reg i -> physical reg i for i in 0..31.
//   - Free list initially contains physical regs 32..63 (32 entries).
//   - Slot A is earlier than slot B in program order within one dispatch cycle.
//   - Flush on branch mispredict / exception restores s-RAT from a-RAT and
//     drains the free list back to the committed state.

module rename #(
	parameter PHYS_REG_WIDTH = 6
) (
	clk,
	reset,
	flush,
	rob_empty,
	// Dispatch (combinational lookup) — inputs from ibuf output
	disp_a_fire,      // dispatch slot A this cycle
	disp_a_src1,      // arch src1
	disp_a_src2,      // arch src2
	disp_a_dest,      // arch dest (0 = no dest)
	disp_b_fire,
	disp_b_src1,
	disp_b_src2,
	disp_b_dest,
	// Rename outputs (combinational)
	rn_a_p_src1,
	rn_a_p_src2,
	rn_a_p_dst,       // new physical dest; 0 if dest arch = 0
	rn_a_p_prev_dst,  // previous physical mapping (for free at commit)
	rn_b_p_src1,
	rn_b_p_src2,
	rn_b_p_dst,
	rn_b_p_prev_dst,
	// Commit (from WB stage, one cycle later than the arch-RF write)
	cmt_a_fire,
	cmt_a_dest,
	cmt_a_p_dst,
	cmt_a_p_prev_dst,
	cmt_b_fire,
	cmt_b_dest,
	cmt_b_p_dst,
	cmt_b_p_prev_dst,
	// Recovery and free-list status
	recovery_busy,
	free_list_ready
);
	input clk;
	input reset;
	input flush;
	input rob_empty;

	input disp_a_fire;
	input [4:0] disp_a_src1;
	input [4:0] disp_a_src2;
	input [4:0] disp_a_dest;
	input disp_b_fire;
	input [4:0] disp_b_src1;
	input [4:0] disp_b_src2;
	input [4:0] disp_b_dest;
	output wire [PHYS_REG_WIDTH-1:0] rn_a_p_src1;
	output wire [PHYS_REG_WIDTH-1:0] rn_a_p_src2;
	output wire [PHYS_REG_WIDTH-1:0] rn_a_p_dst;
	output wire [PHYS_REG_WIDTH-1:0] rn_a_p_prev_dst;
	output wire [PHYS_REG_WIDTH-1:0] rn_b_p_src1;
	output wire [PHYS_REG_WIDTH-1:0] rn_b_p_src2;
	output wire [PHYS_REG_WIDTH-1:0] rn_b_p_dst;
	output wire [PHYS_REG_WIDTH-1:0] rn_b_p_prev_dst;

	input cmt_a_fire;
	input [4:0] cmt_a_dest;
	input [PHYS_REG_WIDTH-1:0] cmt_a_p_dst;
	input [PHYS_REG_WIDTH-1:0] cmt_a_p_prev_dst;
	input cmt_b_fire;
	input [4:0] cmt_b_dest;
	input [PHYS_REG_WIDTH-1:0] cmt_b_p_dst;
	input [PHYS_REG_WIDTH-1:0] cmt_b_p_prev_dst;

	output wire recovery_busy;
	output wire free_list_ready;  // free list has >= 2 entries

	// ---- s-RAT and a-RAT ----
	reg [PHYS_REG_WIDTH-1:0] s_rat [0:31];
	reg [PHYS_REG_WIDTH-1:0] a_rat [0:31];

	// ---- Free list (circular queue of 32 entries) ----
	reg [PHYS_REG_WIDTH-1:0] free_list [0:31];
	reg [4:0] fl_head;
	reg [4:0] fl_tail;
	reg [5:0] fl_count;
	reg recovery_busy_reg;

	// Whether each slot's dest actually consumes a phys reg
	wire disp_a_alloc = disp_a_fire & (disp_a_dest != 5'd0);
	wire disp_b_alloc = disp_b_fire & (disp_b_dest != 5'd0);

	// New phys regs from free list (combinational reads at current head)
	wire [PHYS_REG_WIDTH-1:0] new_p_a = free_list[fl_head];
	wire [PHYS_REG_WIDTH-1:0] new_p_b = free_list[fl_head + 5'd1];

	assign rn_a_p_dst = disp_a_alloc ? new_p_a : {PHYS_REG_WIDTH{1'b0}};
	assign rn_b_p_dst = disp_b_alloc ? (disp_a_alloc ? new_p_b : new_p_a) : {PHYS_REG_WIDTH{1'b0}};

	// Src rename: read s-RAT; slot B forwards from slot A's just-allocated dest
	// when its src matches slot A's dest.
	assign rn_a_p_src1 = s_rat[disp_a_src1];
	assign rn_a_p_src2 = s_rat[disp_a_src2];
	assign rn_b_p_src1 = (disp_a_alloc & (disp_b_src1 == disp_a_dest)) ? rn_a_p_dst : s_rat[disp_b_src1];
	assign rn_b_p_src2 = (disp_a_alloc & (disp_b_src2 == disp_a_dest)) ? rn_a_p_dst : s_rat[disp_b_src2];

	// Previous dest mapping (for free at commit); slot B forwards slot A when they share dest
	assign rn_a_p_prev_dst = disp_a_alloc ? s_rat[disp_a_dest] : {PHYS_REG_WIDTH{1'b0}};
	assign rn_b_p_prev_dst = disp_b_alloc
		? ((disp_a_alloc & (disp_b_dest == disp_a_dest)) ? rn_a_p_dst : s_rat[disp_b_dest])
		: {PHYS_REG_WIDTH{1'b0}};

	assign recovery_busy = recovery_busy_reg;
	assign free_list_ready = !recovery_busy_reg && (fl_count >= 6'd2);

	// ---- State update ----
	integer i;
	integer p;
	integer r;
	integer rebuild_count;
	reg rebuild_used;
	initial begin
		for (i = 0; i < 32; i = i + 1) begin
			s_rat[i] = i[PHYS_REG_WIDTH-1:0];
			a_rat[i] = i[PHYS_REG_WIDTH-1:0];
			free_list[i] = 6'd32 + i[PHYS_REG_WIDTH-1:0];
		end
		fl_head  = 5'd0;
		fl_tail  = 5'd0;
		fl_count = 6'd32;
		recovery_busy_reg = 1'b0;
	end

	// Number of allocations and frees this cycle (0, 1, or 2 each)
	wire [1:0] n_alloc = {1'b0, disp_a_alloc} + {1'b0, disp_b_alloc};
	wire cmt_a_free = cmt_a_fire & (cmt_a_dest != 5'd0);
	wire cmt_b_free = cmt_b_fire & (cmt_b_dest != 5'd0);
	wire [1:0] n_free = {1'b0, cmt_a_free} + {1'b0, cmt_b_free};

	always @(posedge clk) begin
		if (reset) begin
			for (i = 0; i < 32; i = i + 1) begin
				s_rat[i] <= i[PHYS_REG_WIDTH-1:0];
				a_rat[i] <= i[PHYS_REG_WIDTH-1:0];
				free_list[i] <= 6'd32 + i[PHYS_REG_WIDTH-1:0];
			end
			fl_head  <= 5'd0;
			fl_tail  <= 5'd0;
			fl_count <= 6'd32;
			recovery_busy_reg <= 1'b0;
		end
		else if (recovery_busy_reg && rob_empty) begin
			// All pre-flush instructions have retired. Reconstruct both the
			// speculative map and the free list from the committed map.
			for (i = 0; i < 32; i = i + 1)
				s_rat[i] <= a_rat[i];

			rebuild_count = 0;
			for (p = 1; p < (1 << PHYS_REG_WIDTH); p = p + 1) begin
				rebuild_used = 1'b0;
				for (r = 1; r < 32; r = r + 1)
					if (a_rat[r] == p[PHYS_REG_WIDTH-1:0])
						rebuild_used = 1'b1;
				if (!rebuild_used) begin
					free_list[rebuild_count] <= p[PHYS_REG_WIDTH-1:0];
					rebuild_count = rebuild_count + 1;
				end
			end
			fl_head <= 5'd0;
			fl_tail <= 5'd0;
			fl_count <= rebuild_count[5:0];
			recovery_busy_reg <= 1'b0;
		end
		else begin
			// a-RAT update on commit
			if (cmt_a_free)
				a_rat[cmt_a_dest] <= cmt_a_p_dst;
			if (cmt_b_free)
				a_rat[cmt_b_dest] <= cmt_b_p_dst;

			if (!recovery_busy_reg) begin
				// s-RAT update on dispatch (slot A first, slot B wins on same dest).
				if (disp_a_alloc)
					s_rat[disp_a_dest] <= new_p_a;
				if (disp_b_alloc)
					s_rat[disp_b_dest] <= disp_a_alloc ? new_p_b : new_p_a;

				// Free list: pop on dispatch and return old mappings on commit.
				if (n_alloc != 2'd0)
					fl_head <= fl_head + n_alloc;
				if (cmt_a_free)
					free_list[fl_tail] <= cmt_a_p_prev_dst;
				if (cmt_b_free)
					free_list[fl_tail + {4'b0, cmt_a_free}] <= cmt_b_p_prev_dst;
				if (n_free != 2'd0)
					fl_tail <= fl_tail + n_free;
				fl_count <= fl_count + {4'b0, n_free} - {4'b0, n_alloc};
			end

			// Dispatch is blocked until the preserved ROB prefix drains, then
			// the block above rebuilds a precise post-commit rename state.
			if (flush)
				recovery_busy_reg <= 1'b1;
		end
	end
endmodule
