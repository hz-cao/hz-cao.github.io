module pred (
	clk,
	reset,
	fetch_pc_0,
	fetch_pc_1,
	dual_issue,
	ras_en,
	ret_pc_0,
	ret_pc_1,
	taken_0,
	taken_1,
	branch_mistaken,
	wrong_pc,
	right_target,
	ins_type_w,
	update_orien_en,
	retire_pc,
	right_orien
);
	parameter RASNUM = 16;
	parameter RASIDLEN = $clog2(RASNUM);
	parameter BHTNUM = 256;
	parameter BHTIDLEN = $clog2(BHTNUM);
	parameter BHRLEN = 8;
	parameter PHTNUM = 512;
	parameter PHTIDLEN = $clog2(PHTNUM);
	input clk;
	input reset;
	input [31:0] fetch_pc_0;
	input [31:0] fetch_pc_1;
	input dual_issue;
	input ras_en;
	output reg [31:0] ret_pc_0;
	output reg [31:0] ret_pc_1;
	output wire taken_0;
	output wire taken_1;
	input branch_mistaken;
	input [31:0] wrong_pc;
	input [31:0] right_target;
	input [2:0] ins_type_w;
	input update_orien_en;
	input [31:0] retire_pc;
	input right_orien;
	wire [2:0] ins_type_0;
	wire [2:0] ins_type_1;
	reg bht_v [BHTNUM - 1:0];
	reg [BHRLEN - 1:0] bht [BHTNUM - 1:0];
	wire [BHTIDLEN - 1:0] bht_index_0;
	wire [BHTIDLEN - 1:0] bht_index_1;
	wire [BHTIDLEN - 1:0] bht_index_o;
	wire [BHTIDLEN - 1:0] bht_index_w;
	wire [BHRLEN - 1:0] bht_val_0;
	wire [BHRLEN - 1:0] bht_val_1;
	wire [BHRLEN - 1:0] bht_val_o;
	wire [BHRLEN - 1:0] bht_val_w;
	wire [PHTIDLEN - 1:0] pc_frag_0;
	wire [PHTIDLEN - 1:0] pc_frag_1;
	wire [PHTIDLEN - 1:0] pc_frag_o;
	wire [PHTIDLEN - 1:0] pc_frag_w;
	wire [PHTIDLEN - 1:0] hashed_index_0;
	wire [PHTIDLEN - 1:0] hashed_index_1;
	wire [PHTIDLEN - 1:0] hashed_index_o;
	wire [PHTIDLEN - 1:0] hashed_index_w;
	assign bht_index_0 = fetch_pc_0[9:2] ^ fetch_pc_0[17:10] ^ fetch_pc_0[25:18] ^ {2'b0, fetch_pc_0[31:26]};
	assign bht_index_1 = fetch_pc_1[9:2] ^ fetch_pc_1[17:10] ^ fetch_pc_1[25:18] ^ {2'b0, fetch_pc_1[31:26]};
	assign bht_index_o = retire_pc[9:2] ^ retire_pc[17:10] ^ retire_pc[25:18] ^ {2'b0, retire_pc[31:26]};
	assign bht_index_w = wrong_pc[9:2] ^ wrong_pc[17:10] ^ wrong_pc[25:18] ^ {2'b0, wrong_pc[31:26]};
	assign bht_val_0 = {BHRLEN {bht_v[bht_index_0]}} & bht[bht_index_0];
	assign bht_val_1 = {BHRLEN {bht_v[bht_index_1]}} & bht[bht_index_1];
	assign bht_val_o = {BHRLEN {bht_v[bht_index_o]}} & bht[bht_index_o];
	assign bht_val_w = {BHRLEN {bht_v[bht_index_w]}} & bht[bht_index_w];
	assign pc_frag_0 = fetch_pc_0[PHTIDLEN + 1:2];
	assign pc_frag_1 = fetch_pc_1[PHTIDLEN + 1:2];
	assign pc_frag_o = retire_pc[PHTIDLEN + 1:2];
	assign pc_frag_w = wrong_pc[PHTIDLEN + 1:2];
	assign hashed_index_0 = {{(PHTIDLEN-BHRLEN){1'b0}}, bht_val_0} ^ pc_frag_0;
	assign hashed_index_1 = {{(PHTIDLEN-BHRLEN){1'b0}}, bht_val_1} ^ pc_frag_1;
	assign hashed_index_o = {{(PHTIDLEN-BHRLEN){1'b0}}, bht_val_o} ^ pc_frag_o;
	assign hashed_index_w = {{(PHTIDLEN-BHRLEN){1'b0}}, bht_val_w} ^ pc_frag_w;
	integer i;
	always @(posedge clk)
		if (reset)
			for (i = 0; i < BHTNUM; i = i + 1)
				bht_v[i] <= 0;
		else if (update_orien_en) begin
			if (bht_v[bht_index_o]) begin
				bht[bht_index_o] <= bht[bht_index_o] << 1;
				bht[bht_index_o][0] <= right_orien;
			end
			else begin
				bht[bht_index_o] <= right_orien;
				bht_v[bht_index_o] <= 1;
			end
		end
	reg pht_v [PHTNUM - 1:0];
	reg [1:0] pht [PHTNUM - 1:0];
	wire [1:0] pht_res_0;
	wire [1:0] pht_res_1;
	assign pht_res_0 = {2 {pht_v[hashed_index_0]}} & pht[hashed_index_0];
	assign pht_res_1 = {2 {pht_v[hashed_index_1]}} & pht[hashed_index_1];
	assign taken_0 = (ins_type_0 == 3'b000 ? 1'b0 : (ins_type_0 == 3'b010 ? pht_res_0[1] : 1'b1));
	assign taken_1 = (ins_type_1 == 3'b000 ? 1'b0 : (ins_type_1 == 3'b010 ? pht_res_1[1] : 1'b1));
	integer j;
	always @(posedge clk)
		if (reset)
			for (j = 0; j < PHTNUM; j = j + 1)
				pht_v[j] = 0;
		else if (update_orien_en) begin
			if (pht_v[hashed_index_o]) begin
				if (right_orien) begin
					if (pht[hashed_index_o] != 2'b11)
						pht[hashed_index_o] <= pht[hashed_index_o] + 1;
				end
				else if (pht[hashed_index_o] != 2'b00)
					pht[hashed_index_o] <= pht[hashed_index_o] - 1;
			end
			else begin
				pht_v[hashed_index_o] <= 1;
				pht[hashed_index_o] <= {1'b0, right_orien};
			end
		end
	reg [31:0] ras_pc [RASNUM - 1:0];
	reg [$clog2(RASNUM) - 1:0] ras_top;
	reg [31:0] ras_res;
	wire [31:0] ras_top_val;
	wire [31:0] ras_ret_pc;
	wire [31:0] ras_ret_pc_0;
	wire [31:0] ras_ret_pc_1;
	wire [2:0] ras_ins_type;
	assign ras_top_val = ras_pc[ras_top];
	assign ras_ins_type = ((ins_type_0 == 3'b011) || (ins_type_0 == 3'b100) ? ins_type_0 : ins_type_1 & {3 {dual_issue}});
	assign ras_ret_pc = ((ins_type_0 == 3'b011) || (ins_type_0 == 3'b100) ? ras_ret_pc_0 : ras_ret_pc_1);
	assign ras_ret_pc_0 = {fetch_pc_0[31:2] + 1'b1, fetch_pc_0[1:0]};
	assign ras_ret_pc_1 = {fetch_pc_1[31:2] + 1'b1, fetch_pc_1[1:0]};
	integer k;
	always @(posedge clk)
		if (reset) begin
			for (k = 0; k < RASNUM; k = k + 1)
				ras_pc[k] <= 0;
			ras_top <= 0;
		end
		else if (ras_en) begin
			if (ras_ins_type == 3'b011) begin
				ras_pc[ras_top + 1] <= ras_ret_pc;
				ras_top <= ras_top + 1;
			end
			else if (ras_ins_type == 3'b100)
				ras_top <= ras_top - 1;
		end
	wire [32:1] wire_4DAE6;
	assign wire_4DAE6 = ras_top_val;
	always @(*) ras_res = wire_4DAE6;
	wire [31:0] btb_res_0;
	wire [31:0] btb_res_1;
	btb btb(
		.clk(clk),
		.reset(reset),
		.fetch_pc_0(fetch_pc_0),
		.fetch_pc_1(fetch_pc_1),
		.target_pc_0(btb_res_0),
		.target_pc_1(btb_res_1),
		.ins_type_0(ins_type_0),
		.ins_type_1(ins_type_1),
		.branch_mistaken(branch_mistaken),
		.ins_type_w(ins_type_w),
		.wrong_pc(wrong_pc),
		.right_target(right_target)
	);
	always @(*) begin
		(* full_case, parallel_case *)
		case (ins_type_0)
			3'b000: ret_pc_0 = {fetch_pc_0[31:2] + 1'b1, 2'b00};
			3'b100: ret_pc_0 = ras_res;
			default: ret_pc_0 = btb_res_0;
		endcase
	end
	always @(*) begin
		(* full_case, parallel_case *)
		case (ins_type_1)
			3'b000: ret_pc_1 = {fetch_pc_1[31:2] + 1'b1, 2'b00};
			3'b100: ret_pc_1 = ras_res;
			default: ret_pc_1 = btb_res_1;
		endcase
	end
endmodule
