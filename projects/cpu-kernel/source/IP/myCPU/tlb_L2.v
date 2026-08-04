module tlb_L2 (
	clk,
	reset,
	s0_vppn,
	s0_asid,
	s0_result,
	s0_found,
	s0_index,
	s1_vppn,
	s1_asid,
	s1_result,
	s1_found,
	s1_index,
	invtlb_valid,
	invtlb_op,
	invtlb_asid,
	invtlb_va,
	we,
	w_index,
	w_entry,
	r_index,
	r_entry
);
	input clk;
	input reset;
	input [18:0] s0_vppn;
	input [9:0] s0_asid;
	output wire [88:0] s0_result;
	output wire s0_found;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	output wire [4:0] s0_index;
	input [18:0] s1_vppn;
	input [9:0] s1_asid;
	output wire [88:0] s1_result;
	output wire s1_found;
	output wire [4:0] s1_index;
	input invtlb_valid;
	input [4:0] invtlb_op;
	input [9:0] invtlb_asid;
	input [31:0] invtlb_va;
	input we;
	input [4:0] w_index;
	input wire [88:0] w_entry;
	input [4:0] r_index;
	output wire [88:0] r_entry;
	reg [83:0] data [0:31];
	wire [31:0] match0;
	wire [31:0] match1;
	reg [31:0] match0_reg;
	reg [31:0] match1_reg;
	wire [4:0] match_id_sel0 [0:31];
	wire [4:0] match_id_sel1 [0:31];
	reg [4:0] match_id0;
	reg [4:0] match_id1;
	wire [83:0] result_sel0 [0:31];
	wire [83:0] result_sel1 [0:31];
	reg [83:0] result0;
	reg [83:0] result1;
	genvar _genvar_i_3;
	function automatic signed [4:0] demo_cast_signed;
		input reg signed [4:0] inp;
		demo_cast_signed = inp;
	endfunction
	generate
		for (_genvar_i_3 = 0; _genvar_i_3 < TLBNUM; _genvar_i_3 = _genvar_i_3 + 1) begin : gen_match0
			localparam i = _genvar_i_3;
			wire match_4m = s0_vppn[18:9] == data[i][81:72];
			wire match_4k = s0_vppn == data[i][81-:19];
			wire match_vppn = (data[i][82] ? match_4m : match_4k);
			wire match_asid = s0_asid == data[i][62-:10];
			assign match0[i] = (data[i][83] && match_vppn) && (match_asid || data[i][52]);
			assign match_id_sel0[i] = {TLBIDLEN {match0_reg[i]}} & demo_cast_signed(i);
			assign result_sel0[i] = {84 {match0_reg[i]}} & data[i];
		end
	endgenerate
	genvar _genvar_i_4;
	generate
		for (_genvar_i_4 = 0; _genvar_i_4 < TLBNUM; _genvar_i_4 = _genvar_i_4 + 1) begin : gen_match1
			localparam i = _genvar_i_4;
			wire match_4m = s1_vppn[18:9] == data[i][81:72];
			wire match_4k = s1_vppn == data[i][81-:19];
			wire match_vppn = (data[i][82] ? match_4m : match_4k);
			wire match_asid = s1_asid == data[i][62-:10];
			assign match1[i] = (data[i][83] && match_vppn) && (match_asid || data[i][52]);
			assign match_id_sel1[i] = {TLBIDLEN {match1_reg[i]}} & demo_cast_signed(i);
			assign result_sel1[i] = {84 {match1_reg[i]}} & data[i];
		end
	endgenerate
	always @(*) begin
		match_id0 = 0;
		match_id1 = 0;
		result0 = 0;
		result1 = 0;
		begin : block_1
			reg signed [31:0] i;
			for (i = 0; i < TLBNUM; i = i + 1)
				begin
					match_id0 = match_id0 | match_id_sel0[i];
					match_id1 = match_id1 | match_id_sel1[i];
					result0 = result0 | result_sel0[i];
					result1 = result1 | result_sel1[i];
				end
		end
	end
	assign s0_index = match_id0;
	assign s1_index = match_id1;
	assign s0_found = |match0;
	assign s1_found = |match1;
	assign s0_result[52] = result0[83];
	assign s0_result[69-:6] = (result0[82] ? 21 : 12);
	assign s0_result[88-:19] = result0[81-:19];
	assign s0_result[62-:10] = result0[62-:10];
	assign s0_result[63] = result0[52];
	assign s0_result[51-:20] = result0[51-:20];
	assign s0_result[31-:2] = result0[31-:2];
	assign s0_result[29-:2] = result0[29-:2];
	assign s0_result[27] = result0[27];
	assign s0_result[26] = result0[26];
	assign s0_result[25-:20] = result0[25-:20];
	assign s0_result[5-:2] = result0[5-:2];
	assign s0_result[3-:2] = result0[3-:2];
	assign s0_result[1] = result0[1];
	assign s0_result[0] = result0[0];
	assign s1_result[52] = result1[83];
	assign s1_result[69-:6] = (result1[82] ? 21 : 12);
	assign s1_result[88-:19] = result1[81-:19];
	assign s1_result[62-:10] = result1[62-:10];
	assign s1_result[63] = result1[52];
	assign s1_result[51-:20] = result1[51-:20];
	assign s1_result[31-:2] = result1[31-:2];
	assign s1_result[29-:2] = result1[29-:2];
	assign s1_result[27] = result1[27];
	assign s1_result[26] = result1[26];
	assign s1_result[25-:20] = result1[25-:20];
	assign s1_result[5-:2] = result1[5-:2];
	assign s1_result[3-:2] = result1[3-:2];
	assign s1_result[1] = result1[1];
	assign s1_result[0] = result1[0];
	wire tlb_clr = (invtlb_op == 5'h00) || (invtlb_op == 5'h01);
	wire tlb_clr_g1 = invtlb_op == 5'h02;
	wire tlb_clr_g0 = invtlb_op == 5'h03;
	wire tlb_clr_g0_asid = invtlb_op == 5'h04;
	wire tlb_clr_g0_asid_vpn = invtlb_op == 5'h05;
	wire tlb_clr_g1_asid_vpn = invtlb_op == 5'h06;
	wire [18:0] invtlb_vppn = invtlb_va[31:13];
	always @(posedge clk) begin
		match0_reg <= match0;
		match1_reg <= match1;
		if (reset) begin : block_2
			reg signed [31:0] i;
			for (i = 0; i < TLBNUM; i = i + 1)
				data[i][83] <= 0;
		end
		else if (invtlb_valid) begin : block_3
			reg signed [31:0] i;
			for (i = 0; i < TLBNUM; i = i + 1)
				if (data[i][83]) begin
					if (((((tlb_clr || (tlb_clr_g1 && (data[i][52] == 1))) || (tlb_clr_g0 && (data[i][52] == 0))) || ((tlb_clr_g0_asid && (data[i][52] == 0)) && (data[i][62-:10] == invtlb_asid))) || (((tlb_clr_g0_asid_vpn && (data[i][52] == 0)) && (data[i][62-:10] == invtlb_asid)) && (data[i][82] ? invtlb_vppn[18:9] == data[i][81:72] : invtlb_vppn == data[i][81-:19]))) || ((tlb_clr_g1_asid_vpn && ((data[i][52] == 1) || (data[i][62-:10] == invtlb_asid))) && (data[i][82] ? invtlb_vppn[18:9] == data[i][81:72] : invtlb_vppn == data[i][81-:19])))
						data[i][83] <= 0;
				end
		end
		else if (we) begin
			data[w_index][83] <= w_entry[52];
			data[w_index][81-:19] <= w_entry[88-:19];
			data[w_index][82] <= (w_entry[69-:6] == 12 ? 0 : 1);
			data[w_index][62-:10] <= w_entry[62-:10];
			data[w_index][52] <= w_entry[63];
			data[w_index][51-:20] <= w_entry[51-:20];
			data[w_index][31-:2] <= w_entry[31-:2];
			data[w_index][29-:2] <= w_entry[29-:2];
			data[w_index][27] <= w_entry[27];
			data[w_index][26] <= w_entry[26];
			data[w_index][25-:20] <= w_entry[25-:20];
			data[w_index][5-:2] <= w_entry[5-:2];
			data[w_index][3-:2] <= w_entry[3-:2];
			data[w_index][1] <= w_entry[1];
			data[w_index][0] <= w_entry[0];
		end
	end
	assign r_entry[52] = data[r_index][83];
	assign r_entry[88-:19] = data[r_index][81-:19];
	assign r_entry[69-:6] = (data[r_index][82] ? 21 : 12);
	assign r_entry[62-:10] = data[r_index][62-:10];
	assign r_entry[63] = data[r_index][52];
	assign r_entry[51-:20] = data[r_index][51-:20];
	assign r_entry[31-:2] = data[r_index][31-:2];
	assign r_entry[29-:2] = data[r_index][29-:2];
	assign r_entry[27] = data[r_index][27];
	assign r_entry[26] = data[r_index][26];
	assign r_entry[25-:20] = data[r_index][25-:20];
	assign r_entry[5-:2] = data[r_index][5-:2];
	assign r_entry[3-:2] = data[r_index][3-:2];
	assign r_entry[1] = data[r_index][1];
	assign r_entry[0] = data[r_index][0];
endmodule
