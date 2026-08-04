module ibuf (
	clk,
	reset,
	flush,
	i_size,
	i_ready,
	i_a_inst,
	i_b_inst,
	o_a_inst,
	o_b_inst,
	i_a_pc,
	i_a_optype,
	i_a_opcode,
	i_a_dest,
	i_a_imm,
	i_a_pred_br_taken,
	i_a_pred_br_target,
	i_a_br_type,
	i_a_br_condition,
	i_a_br_target,
	i_a_br_taken,
	i_a_have_excp,
	i_a_excp_type,
	i_a_csr_addr,
	i_a_csr_wr,
	i_a_is_spec_op,
	i_a_is_idle,
	i_a_is_ll,
	i_a_is_sc,
	i_a_r1,
	i_a_r2,
	i_a_src2_is_imm,
	i_b_pc,
	i_b_optype,
	i_b_opcode,
	i_b_dest,
	i_b_imm,
	i_b_pred_br_taken,
	i_b_pred_br_target,
	i_b_br_type,
	i_b_br_condition,
	i_b_br_taken,
	i_b_br_target,
	i_b_have_excp,
	i_b_excp_type,
	i_b_csr_addr,
	i_b_csr_wr,
	i_b_is_spec_op,
	i_b_is_idle,
	i_b_is_ll,
	i_b_is_sc,
	i_b_r1,
	i_b_r2,
	i_b_src2_is_imm,
	o_size,
	o_a_pc,
	o_a_valid,
	o_a_optype,
	o_a_opcode,
	o_a_dest,
	o_a_imm,
	o_a_pred_br_taken,
	o_a_pred_br_target,
	o_a_br_type,
	o_a_br_condition,
	o_a_br_target,
	o_a_br_taken,
	o_a_have_excp,
	o_a_excp_type,
	o_a_csr_addr,
	o_a_csr_wr,
	o_a_is_spec_op,
	o_a_is_idle,
	o_a_is_ll,
	o_a_is_sc,
	o_a_r1,
	o_a_r2,
	o_a_src2_is_imm,
	o_b_pc,
	o_b_valid,
	o_b_optype,
	o_b_opcode,
	o_b_dest,
	o_b_imm,
	o_b_pred_br_taken,
	o_b_pred_br_target,
	o_b_br_type,
	o_b_br_condition,
	o_b_br_target,
	o_b_br_taken,
	o_b_have_excp,
	o_b_excp_type,
	o_b_csr_addr,
	o_b_csr_wr,
	o_b_is_spec_op,
	o_b_is_idle,
	o_b_is_ll,
	o_b_is_sc,
	o_b_r1,
	o_b_r2,
	o_b_src2_is_imm
);
	input clk;
	input reset;
	input flush;
	input [1:0] i_size;
	output wire i_ready;
	input [31:0] i_a_pc;
	input wire [2:0] i_a_optype;
	input wire [5:0] i_a_opcode;
	input [4:0] i_a_dest;
	input [31:0] i_a_imm;
	input i_a_pred_br_taken;
	input [31:0] i_a_pred_br_target;
	input wire [2:0] i_a_br_type;
	input i_a_br_condition;
	input [31:0] i_a_br_target;
	input i_a_br_taken;
	input i_a_have_excp;
	input wire [14:0] i_a_excp_type;
	input wire [13:0] i_a_csr_addr;
	input i_a_csr_wr;
	input i_a_is_spec_op;
	input i_a_is_idle;
	input i_a_is_ll;
	input i_a_is_sc;
	input [4:0] i_a_r1;
	input [4:0] i_a_r2;
	input i_a_src2_is_imm;
	input [31:0] i_b_pc;
	input wire [2:0] i_b_optype;
	input wire [5:0] i_b_opcode;
	input [4:0] i_b_dest;
	input [31:0] i_b_imm;
	input i_b_pred_br_taken;
	input [31:0] i_b_pred_br_target;
	input wire [2:0] i_b_br_type;
	input i_b_br_condition;
	input i_b_br_taken;
	input [31:0] i_b_br_target;
	input i_b_have_excp;
	input wire [14:0] i_b_excp_type;
	input wire [13:0] i_b_csr_addr;
	input i_b_csr_wr;
	input i_b_is_spec_op;
	input i_b_is_idle;
	input i_b_is_ll;
	input i_b_is_sc;
	input [4:0] i_b_r1;
	input [4:0] i_b_r2;
	input i_b_src2_is_imm;
	input [1:0] o_size;
	output wire [31:0] o_a_pc;
	output wire o_a_valid;
	output wire [2:0] o_a_optype;
	output wire [5:0] o_a_opcode;
	output wire [4:0] o_a_dest;
	output wire [31:0] o_a_imm;
	output wire o_a_pred_br_taken;
	output wire [31:0] o_a_pred_br_target;
	output wire [2:0] o_a_br_type;
	output wire o_a_br_condition;
	output wire [31:0] o_a_br_target;
	output wire o_a_br_taken;
	output wire o_a_have_excp;
	output wire [14:0] o_a_excp_type;
	output wire [13:0] o_a_csr_addr;
	output wire o_a_csr_wr;
	output wire o_a_is_spec_op;
	output wire o_a_is_idle;
	output wire o_a_is_ll;
	output wire o_a_is_sc;
	output wire [4:0] o_a_r1;
	output wire [4:0] o_a_r2;
	output wire o_a_src2_is_imm;
	output wire [31:0] o_b_pc;
	output wire o_b_valid;
	output wire [2:0] o_b_optype;
	output wire [5:0] o_b_opcode;
	output wire [4:0] o_b_dest;
	output wire [31:0] o_b_imm;
	output wire o_b_pred_br_taken;
	output wire [31:0] o_b_pred_br_target;
	output wire [2:0] o_b_br_type;
	output wire o_b_br_condition;
	output wire [31:0] o_b_br_target;
	output wire o_b_br_taken;
	output wire o_b_have_excp;
	output wire [14:0] o_b_excp_type;
	output wire [13:0] o_b_csr_addr;
	output wire o_b_csr_wr;
	output wire o_b_is_spec_op;
	output wire o_b_is_idle;
	output wire o_b_is_ll;
	output wire o_b_is_sc;
	output wire [4:0] o_b_r1;
	output wire [4:0] o_b_r2;
	output wire o_b_src2_is_imm;
	input [31:0] i_a_inst;
	input [31:0] i_b_inst;
	output wire [31:0] o_a_inst;
	output wire [31:0] o_b_inst;

	reg [225:0] data_way0 [0:7];
	reg [225:0] data_way1 [0:7];
	reg [2:0] head_way0;
	reg [2:0] head_way1;
	reg head_way;
	reg [2:0] tail_way0;
	reg [2:0] tail_way1;
	reg tail_way;
	reg [4:0] length;
	wire [225:0] input_data0;
	wire [225:0] input_data1;
	assign i_ready = length <= 5'd10;
	assign o_a_valid = length >= 5'd1;
	assign {o_a_inst, o_a_pc, o_a_optype, o_a_opcode, o_a_dest, o_a_imm, o_a_pred_br_taken, o_a_pred_br_target, o_a_br_type, o_a_br_condition, o_a_br_target, o_a_br_taken, o_a_have_excp, o_a_excp_type, o_a_csr_addr, o_a_csr_wr, o_a_is_spec_op, o_a_is_idle, o_a_is_ll, o_a_is_sc, o_a_r1, o_a_r2, o_a_src2_is_imm} = (head_way ? data_way1[head_way1] : data_way0[head_way0]);
	assign o_b_valid = length >= 5'd2;
	assign {o_b_inst, o_b_pc, o_b_optype, o_b_opcode, o_b_dest, o_b_imm, o_b_pred_br_taken, o_b_pred_br_target, o_b_br_type, o_b_br_condition, o_b_br_target, o_b_br_taken, o_b_have_excp, o_b_excp_type, o_b_csr_addr, o_b_csr_wr, o_b_is_spec_op, o_b_is_idle, o_b_is_ll, o_b_is_sc, o_b_r1, o_b_r2, o_b_src2_is_imm} = (head_way ? data_way0[head_way0] : data_way1[head_way1]);
	assign input_data0 = {i_a_inst, i_a_pc, i_a_optype, i_a_opcode, i_a_dest, i_a_imm, i_a_pred_br_taken, i_a_pred_br_target, i_a_br_type, i_a_br_condition, i_a_br_target, i_a_br_taken, i_a_have_excp, i_a_excp_type, i_a_csr_addr, i_a_csr_wr, i_a_is_spec_op, i_a_is_idle, i_a_is_ll, i_a_is_sc, i_a_r1, i_a_r2, i_a_src2_is_imm};
	assign input_data1 = {i_b_inst, i_b_pc, i_b_optype, i_b_opcode, i_b_dest, i_b_imm, i_b_pred_br_taken, i_b_pred_br_target, i_b_br_type, i_b_br_condition, i_b_br_target, i_b_br_taken, i_b_have_excp, i_b_excp_type, i_b_csr_addr, i_b_csr_wr, i_b_is_spec_op, i_b_is_idle, i_b_is_ll, i_b_is_sc, i_b_r1, i_b_r2, i_b_src2_is_imm};
	always @(posedge clk)
		if (reset || flush) begin
			head_way <= 1'd0;
			head_way0 <= 3'd0;
			head_way1 <= 3'd0;
			tail_way <= 1'd0;
			tail_way0 <= 3'd0;
			tail_way1 <= 3'd0;
			length <= 5'd0;
		end
		else begin
			if (((tail_way == 1'b0) && (i_size == 2'd1)) || (i_size == 2'd2))
				tail_way0 <= tail_way0 + 3'd1;
			if (((tail_way == 1'b1) && (i_size == 2'd1)) || (i_size == 2'd2))
				tail_way1 <= tail_way1 + 3'd1;
			if (((head_way == 1'b0) && (o_size == 2'd1)) || (o_size == 2'd2))
				head_way0 <= head_way0 + 3'd1;
			if (((head_way == 1'b1) && (o_size == 2'd1)) || (o_size == 2'd2))
				head_way1 <= head_way1 + 3'd1;
			tail_way <= tail_way ^ i_size[0];
			head_way <= head_way ^ o_size[0];
			length <= (length + {2'b00, i_size}) - {2'b00, o_size};
			if ((i_size == 2'd1) || (i_size == 2'd2)) begin
				if (tail_way == 1'b0)
					data_way0[tail_way0] <= input_data0;
				else
					data_way1[tail_way1] <= input_data0;
			end
			if (i_size == 2'd2) begin
				if (tail_way == 1'b0)
					data_way1[tail_way1] <= input_data1;
				else
					data_way0[tail_way0] <= input_data1;
			end
		end
endmodule
