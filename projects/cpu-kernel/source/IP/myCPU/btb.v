module btb (
	clk,
	reset,
	fetch_pc_0,
	fetch_pc_1,
	target_pc_0,
	target_pc_1,
	ins_type_0,
	ins_type_1,
	branch_mistaken,
	ins_type_w,
	wrong_pc,
	right_target
);
	parameter BTBNUM = 256;
	parameter BTBIDLEN = $clog2(BTBNUM);
	parameter BTBTAGLEN = 10;
	parameter BTBGROUP = 2;
	input clk;
	input reset;
	input [31:0] fetch_pc_0;
	input [31:0] fetch_pc_1;
	output wire [31:0] target_pc_0;
	output wire [31:0] target_pc_1;
	output wire [2:0] ins_type_0;
	output wire [2:0] ins_type_1;
	input branch_mistaken;
	input [2:0] ins_type_w;
	input [31:0] wrong_pc;
	input [31:0] right_target;
	wire hit_0;
	wire hit_1;
	wire hit_w;
	wire hit_inv;
	reg [(BTBNUM / BTBGROUP) - 1:0] btb_valid_way0;
	reg [(BTBNUM / BTBGROUP) - 1:0] btb_valid_way1;
	reg [BTBTAGLEN - 1:0] btb_tag_way0 [(BTBNUM / BTBGROUP) - 1:0];
	reg [BTBTAGLEN - 1:0] btb_tag_way1 [(BTBNUM / BTBGROUP) - 1:0];
	reg [31:0] btb_target_way0 [(BTBNUM / BTBGROUP) - 1:0];
	reg [31:0] btb_target_way1 [(BTBNUM / BTBGROUP) - 1:0];
	reg [2:0] btb_ins_type_way0 [(BTBNUM / BTBGROUP) - 1:0];
	reg [2:0] btb_ins_type_way1 [(BTBNUM / BTBGROUP) - 1:0];
	reg [$clog2(BTBGROUP) - 1:0] btb_last_visit [(BTBNUM / BTBGROUP) - 1:0];
	wire [29:0] pc_0_32to2;
	wire [29:0] pc_1_32to2;
	wire [29:0] pc_w_32to2;
	wire [BTBGROUP - 1:0] btb_hit_way_0;
	wire [BTBGROUP - 1:0] btb_hit_way_1;
	wire [BTBGROUP - 1:0] btb_hit_way_w;
	wire [BTBGROUP - 1:0] btb_hit_way_inv;
	wire [$clog2(BTBNUM / BTBGROUP) - 1:0] btb_group_num_0;
	wire [$clog2(BTBNUM / BTBGROUP) - 1:0] btb_group_num_1;
	wire [$clog2(BTBNUM / BTBGROUP) - 1:0] btb_group_num_w;
	wire [BTBTAGLEN - 1:0] btb_fetch_tag_0;
	wire [BTBTAGLEN - 1:0] btb_fetch_tag_1;
	wire [BTBTAGLEN - 1:0] btb_fetch_tag_w;
	wire [$clog2(BTBGROUP) - 1:0] btb_hit_way_id_0;
	wire [$clog2(BTBGROUP) - 1:0] btb_hit_way_id_1;
	wire [$clog2(BTBGROUP) - 1:0] btb_hit_way_id_w;
	wire [$clog2(BTBGROUP) - 1:0] btb_hit_way_id_inv;
	assign pc_0_32to2 = fetch_pc_0[31:2];
	assign pc_1_32to2 = fetch_pc_1[31:2];
	assign pc_w_32to2 = wrong_pc[31:2];
	assign btb_group_num_0 = pc_0_32to2[$clog2(BTBNUM / BTBGROUP) - 1:0];
	assign btb_group_num_1 = pc_1_32to2[$clog2(BTBNUM / BTBGROUP) - 1:0];
	assign btb_group_num_w = pc_w_32to2[$clog2(BTBNUM / BTBGROUP) - 1:0];
	assign btb_fetch_tag_0 = pc_0_32to2[29:20] ^ pc_0_32to2[19:10] ^ pc_0_32to2[9:0];
	assign btb_fetch_tag_1 = pc_1_32to2[29:20] ^ pc_1_32to2[19:10] ^ pc_1_32to2[9:0];
	assign btb_fetch_tag_w = pc_w_32to2[29:20] ^ pc_w_32to2[19:10] ^ pc_w_32to2[9:0];
	genvar _genvar_i_5;
	generate
		for (_genvar_i_5 = 0; _genvar_i_5 < BTBGROUP; _genvar_i_5 = _genvar_i_5 + 1) begin : BTB_match
			localparam i = _genvar_i_5;
			assign btb_hit_way_0[i] = (({i == 0} & btb_valid_way0[btb_group_num_0]) | ({i == 1} & btb_valid_way1[btb_group_num_0])) & ((({BTBTAGLEN {i == 0}} & btb_tag_way0[btb_group_num_0]) | ({BTBTAGLEN {i == 1}} & btb_tag_way1[btb_group_num_0])) == btb_fetch_tag_0);
			assign btb_hit_way_1[i] = (({i == 0} & btb_valid_way0[btb_group_num_1]) | ({i == 1} & btb_valid_way1[btb_group_num_1])) & ((({BTBTAGLEN {i == 0}} & btb_tag_way0[btb_group_num_1]) | ({BTBTAGLEN {i == 1}} & btb_tag_way1[btb_group_num_1])) == btb_fetch_tag_1);
			assign btb_hit_way_w[i] = (({i == 0} & btb_valid_way0[btb_group_num_w]) | ({i == 1} & btb_valid_way1[btb_group_num_w])) & ((({BTBTAGLEN {i == 0}} & btb_tag_way0[btb_group_num_w]) | ({BTBTAGLEN {i == 1}} & btb_tag_way1[btb_group_num_w])) == btb_fetch_tag_w);
			assign btb_hit_way_inv[i] = ~(({i == 0} & btb_valid_way0[btb_group_num_w]) | ({i == 1} & btb_valid_way1[btb_group_num_w]));
		end
	endgenerate
	assign btb_hit_way_id_0 = ({btb_hit_way_0[0]} & 0) | ({btb_hit_way_0[1]} & 1);
	assign btb_hit_way_id_1 = ({btb_hit_way_1[0]} & 0) | ({btb_hit_way_1[1]} & 1);
	assign btb_hit_way_id_w = ({btb_hit_way_w[0]} & 0) | ({btb_hit_way_w[1]} & 1);
	assign btb_hit_way_id_inv = ({btb_hit_way_inv[0]} & 0) | ({btb_hit_way_inv[1]} & 1);
	assign hit_0 = |btb_hit_way_0;
	assign hit_1 = |btb_hit_way_1;
	assign hit_w = |btb_hit_way_w;
	assign hit_inv = |btb_hit_way_inv;
	assign target_pc_0 = (hit_0 ? ({32 {btb_hit_way_id_0 == 0}} & btb_target_way0[btb_group_num_0]) | ({32 {btb_hit_way_id_0 == 1}} & btb_target_way1[btb_group_num_0]) : 32'b00000000000000000000000000000000);
	assign target_pc_1 = (hit_1 ? ({32 {btb_hit_way_id_1 == 0}} & btb_target_way0[btb_group_num_1]) | ({32 {btb_hit_way_id_1 == 1}} & btb_target_way1[btb_group_num_1]) : 32'b00000000000000000000000000000000);
	assign ins_type_0 = (hit_0 ? ({3 {btb_hit_way_id_0 == 0}} & btb_ins_type_way0[btb_group_num_0]) | ({3 {btb_hit_way_id_0 == 1}} & btb_ins_type_way1[btb_group_num_0]) : 3'b000);
	assign ins_type_1 = (hit_1 ? ({3 {btb_hit_way_id_1 == 0}} & btb_ins_type_way0[btb_group_num_1]) | ({3 {btb_hit_way_id_1 == 1}} & btb_ins_type_way1[btb_group_num_1]) : 3'b000);
	integer k;
	always @(posedge clk)
		if (reset)
			for (k = 0; k < (BTBNUM / BTBGROUP); k = k + 1)
				btb_last_visit[k] <= 0;
		else begin
			if (btb_hit_way_0[0])
				btb_last_visit[btb_group_num_0] <= 0;
			else if (btb_hit_way_0[1])
				btb_last_visit[btb_group_num_0] <= 1;
			if (btb_hit_way_1[0])
				btb_last_visit[btb_group_num_1] <= 0;
			else if (btb_hit_way_1[1])
				btb_last_visit[btb_group_num_1] <= 1;
		end
	always @(posedge clk)
		if (reset) begin
			btb_valid_way0 <= 0;
			btb_valid_way1 <= 0;
		end
		else if (branch_mistaken) begin
			if (hit_w)
				case (btb_hit_way_id_w)
					0: begin
						btb_tag_way0[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way0[btb_group_num_w] <= right_target;
						btb_ins_type_way0[btb_group_num_w] <= ins_type_w;
					end
					1: begin
						btb_tag_way1[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way1[btb_group_num_w] <= right_target;
						btb_ins_type_way1[btb_group_num_w] <= ins_type_w;
					end
				endcase
			else if (hit_inv)
				case (btb_hit_way_id_inv)
					0: begin
						btb_tag_way0[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way0[btb_group_num_w] <= right_target;
						btb_ins_type_way0[btb_group_num_w] <= ins_type_w;
						btb_valid_way0[btb_group_num_w] <= 1'b1;
					end
					1: begin
						btb_tag_way1[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way1[btb_group_num_w] <= right_target;
						btb_ins_type_way1[btb_group_num_w] <= ins_type_w;
						btb_valid_way1[btb_group_num_w] <= 1'b1;
					end
				endcase
			else
				case (btb_last_visit[btb_group_num_w])
					1: begin
						btb_tag_way0[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way0[btb_group_num_w] <= right_target;
						btb_ins_type_way0[btb_group_num_w] <= ins_type_w;
						btb_valid_way0[btb_group_num_w] <= 1'b1;
					end
					0: begin
						btb_tag_way1[btb_group_num_w] <= btb_fetch_tag_w;
						btb_target_way1[btb_group_num_w] <= right_target;
						btb_ins_type_way1[btb_group_num_w] <= ins_type_w;
						btb_valid_way1[btb_group_num_w] <= 1'b1;
					end
				endcase
		end
endmodule
