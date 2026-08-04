module tlb_top (
	clk,
	reset,
	s0_vppn,
	s0_va_bit12,
	s0_asid,
	s0_valid,
	s0_result,
	s0_ok,
	s1_vppn,
	s1_va_bit12,
	s1_asid,
	s1_valid,
	s1_result,
	s1_ok,
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
	input s0_va_bit12;
	input [9:0] s0_asid;
	input wire s0_valid;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	output wire [37:0] s0_result;
	output wire s0_ok;
	input [18:0] s1_vppn;
	input s1_va_bit12;
	input [9:0] s1_asid;
	input wire s1_valid;
	output wire [37:0] s1_result;
	output wire s1_ok;
	input invtlb_valid;
	input [4:0] invtlb_op;
	input [9:0] invtlb_asid;
	input [31:0] invtlb_va;
	input we;
	input [4:0] w_index;
	input wire [88:0] w_entry;
	input [4:0] r_index;
	output wire [88:0] r_entry;
	reg [1:0] inst_tlb_state;
	reg [1:0] data_tlb_state;
	reg [18:0] s0_vppn_reg;
	reg [18:0] s1_vppn_reg;
	reg [9:0] s0_asid_reg;
	reg [9:0] s1_asid_reg;
	reg s0_va_bit12_reg;
	reg s1_va_bit12_reg;
	wire l2_hit_0;
	wire l2_hit_1;
	wire inst_tlb_hit;
	wire data_tlb_hit;
	wire inst_tlb_refill_valid;
	wire data_tlb_refill_valid;
	wire [4:0] l2_hit_index_0;
	wire [4:0] l2_hit_index_1;
	wire [4:0] inst_tlb_refill_index;
	wire [4:0] data_tlb_refill_index;
	wire [88:0] inst_tlb_refill_data;
	wire [88:0] data_tlb_refill_data;
	reg inst_tlb_refill_valid_reg;
	reg data_tlb_refill_valid_reg;
	reg [4:0] inst_tlb_refill_index_reg;
	reg [4:0] data_tlb_refill_index_reg;
	reg [88:0] inst_tlb_refill_data_reg;
	reg [88:0] data_tlb_refill_data_reg;
	wire [88:0] l2_entry_0;
	wire [88:0] l2_entry_1;
	reg [37:0] l2_result_0;
	reg [37:0] l2_result_1;
	wire [37:0] inst_tlb_result;
	wire [37:0] data_tlb_result;
	assign inst_tlb_hit = inst_tlb_result[37];
	assign data_tlb_hit = data_tlb_result[37];
	assign inst_tlb_refill_valid = l2_hit_0 & (inst_tlb_state == 2);
	assign data_tlb_refill_valid = l2_hit_1 & (data_tlb_state == 2);
	assign inst_tlb_refill_index = l2_hit_index_0;
	assign data_tlb_refill_index = l2_hit_index_1;
	assign inst_tlb_refill_data = l2_entry_0;
	assign data_tlb_refill_data = l2_entry_1;
	always @(posedge clk) begin : refill_buff
		if (reset) begin
			inst_tlb_refill_valid_reg <= 0;
			data_tlb_refill_valid_reg <= 0;
		end
		else begin
			inst_tlb_refill_valid_reg <= inst_tlb_refill_valid;
			data_tlb_refill_valid_reg <= data_tlb_refill_valid;
			inst_tlb_refill_index_reg <= inst_tlb_refill_index;
			data_tlb_refill_index_reg <= data_tlb_refill_index;
			inst_tlb_refill_data_reg <= inst_tlb_refill_data;
			data_tlb_refill_data_reg <= data_tlb_refill_data;
		end
	end
	wire [1:1] wire_BD49B;
	assign wire_BD49B = l2_hit_0;
	always @(*) l2_result_0[37] = wire_BD49B;
	wire [1:1] wire_424DB;
	assign wire_424DB = l2_hit_1;
	always @(*) l2_result_1[37] = wire_424DB;
	wire [5:1] wire_BEC07;
	assign wire_BEC07 = l2_hit_index_0;
	always @(*) l2_result_0[36-:5] = wire_BEC07;
	wire [5:1] wire_223F7;
	assign wire_223F7 = l2_hit_index_1;
	always @(*) l2_result_1[36-:5] = wire_223F7;
	assign s0_result = (inst_tlb_state == 0 ? inst_tlb_result : l2_result_0);
	assign s1_result = (data_tlb_state == 0 ? data_tlb_result : l2_result_1);
	assign s0_ok = (inst_tlb_hit & (inst_tlb_state == 0)) | (inst_tlb_state == 3);
	assign s1_ok = (data_tlb_hit & (data_tlb_state == 0)) | (data_tlb_state == 3);
	always @(posedge clk) begin : state_transition
		if (reset) begin
			inst_tlb_state <= 0;
			data_tlb_state <= 0;
		end
		else begin
			case (inst_tlb_state)
				0:
					if (s0_valid && !inst_tlb_hit)
						inst_tlb_state <= 1;
				1:
					if (!s0_valid)
						inst_tlb_state <= 0;
					else
						inst_tlb_state <= 2;
				2:
					if (!s0_valid)
						inst_tlb_state <= 0;
					else
						inst_tlb_state <= 3;
				3: inst_tlb_state <= 0;
			endcase
			case (data_tlb_state)
				0:
					if (s1_valid && !data_tlb_hit)
						data_tlb_state <= 1;
				1:
					if (!s1_valid)
						data_tlb_state <= 0;
					else
						data_tlb_state <= 2;
				2:
					if (!s1_valid)
						data_tlb_state <= 0;
					else
						data_tlb_state <= 3;
				3: data_tlb_state <= 0;
			endcase
		end
	end
	always @(posedge clk)
		if (reset) begin
			s0_vppn_reg <= 0;
			s0_asid_reg <= 0;
			s0_va_bit12_reg <= 0;
		end
		else if (inst_tlb_state == 0) begin
			s0_vppn_reg <= s0_vppn;
			s0_asid_reg <= s0_asid;
			s0_va_bit12_reg <= s0_va_bit12;
		end
	always @(posedge clk)
		if (reset) begin
			s1_vppn_reg <= 0;
			s1_asid_reg <= 0;
			s1_va_bit12_reg <= 0;
		end
		else if (data_tlb_state == 0) begin
			s1_vppn_reg <= s1_vppn;
			s1_asid_reg <= s1_asid;
			s1_va_bit12_reg <= s1_va_bit12;
		end
	always @(*) begin : l2_result_comb
		if (((l2_entry_0[69-:6] == 12) && (s0_va_bit12_reg == 0)) || ((l2_entry_0[69-:6] == 21) && (s0_vppn_reg[8] == 0))) begin
			l2_result_0[31-:20] = l2_entry_0[51-:20];
			l2_result_0[11-:6] = l2_entry_0[69-:6];
			l2_result_0[5-:2] = l2_entry_0[31-:2];
			l2_result_0[3-:2] = l2_entry_0[29-:2];
			l2_result_0[1] = l2_entry_0[27];
			l2_result_0[0] = l2_entry_0[26];
		end
		else begin
			l2_result_0[31-:20] = l2_entry_0[25-:20];
			l2_result_0[11-:6] = l2_entry_0[69-:6];
			l2_result_0[5-:2] = l2_entry_0[5-:2];
			l2_result_0[3-:2] = l2_entry_0[3-:2];
			l2_result_0[1] = l2_entry_0[1];
			l2_result_0[0] = l2_entry_0[0];
		end
		if (((l2_entry_1[69-:6] == 12) && (s1_va_bit12_reg == 0)) || ((l2_entry_1[69-:6] == 21) && (s1_vppn_reg[8] == 0))) begin
			l2_result_1[31-:20] = l2_entry_1[51-:20];
			l2_result_1[11-:6] = l2_entry_1[69-:6];
			l2_result_1[5-:2] = l2_entry_1[31-:2];
			l2_result_1[3-:2] = l2_entry_1[29-:2];
			l2_result_1[1] = l2_entry_1[27];
			l2_result_1[0] = l2_entry_1[26];
		end
		else begin
			l2_result_1[31-:20] = l2_entry_1[25-:20];
			l2_result_1[11-:6] = l2_entry_1[69-:6];
			l2_result_1[5-:2] = l2_entry_1[5-:2];
			l2_result_1[3-:2] = l2_entry_1[3-:2];
			l2_result_1[1] = l2_entry_1[1];
			l2_result_1[0] = l2_entry_1[0];
		end
	end
	tcache inst_tlb(
		.clk(clk),
		.reset(reset),
		.s_vppn(s0_vppn),
		.s_va_bit12(s0_va_bit12),
		.s_asid(s0_asid),
		.s_result(inst_tlb_result),
		.invalid(we || invtlb_valid),
		.refill_valid(inst_tlb_refill_valid_reg & (inst_tlb_state == 3)),
		.refill_data(inst_tlb_refill_data_reg),
		.refill_index(inst_tlb_refill_index_reg)
	);
	tcache data_tlb(
		.clk(clk),
		.reset(reset),
		.s_vppn(s1_vppn),
		.s_va_bit12(s1_va_bit12),
		.s_asid(s1_asid),
		.s_result(data_tlb_result),
		.invalid(we || invtlb_valid),
		.refill_valid(data_tlb_refill_valid_reg & (data_tlb_state == 3)),
		.refill_data(data_tlb_refill_data_reg),
		.refill_index(data_tlb_refill_index_reg)
	);
	tlb_L2 tlb_L2(
		.clk(clk),
		.reset(reset),
		.s0_vppn(s0_vppn_reg),
		.s0_asid(s0_asid_reg),
		.s0_result(l2_entry_0),
		.s0_found(l2_hit_0),
		.s0_index(l2_hit_index_0),
		.s1_vppn(s1_vppn_reg),
		.s1_asid(s1_asid_reg),
		.s1_result(l2_entry_1),
		.s1_found(l2_hit_1),
		.s1_index(l2_hit_index_1),
		.invtlb_valid(invtlb_valid),
		.invtlb_op(invtlb_op),
		.invtlb_asid(invtlb_asid),
		.invtlb_va(invtlb_va),
		.we(we),
		.w_index(w_index),
		.w_entry(w_entry),
		.r_index(r_index),
		.r_entry(r_entry)
	);
endmodule
