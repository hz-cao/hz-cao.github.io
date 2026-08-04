module mul (
	clk,
	valid,
	opcode,
	src1,
	src2,
	ok,
	result
);
	input clk;
	input valid;
	input wire [5:0] opcode;
	input [31:0] src1;
	input [31:0] src2;
	output reg ok;
	output wire [31:0] result;
	wire sign_ex;
	wire signed [32:0] src1_sign_ex;
	wire signed [32:0] src2_sign_ex;
	wire signed [65:0] mul_product;
	reg [63:0] mul_output_stage1;
	reg [63:0] mul_output;
	reg [5:0] opcode_buf;
	reg [5:0] opcode_result_buf;
	reg valid_buf;
	assign sign_ex = opcode == 6'd1;
	assign src1_sign_ex = {sign_ex & src1[31], src1};
	assign src2_sign_ex = {sign_ex & src2[31], src2};
	assign mul_product = src1_sign_ex * src2_sign_ex;
	always @(posedge clk) begin
		if (valid) begin
			opcode_buf <= opcode;
			mul_output_stage1 <= mul_product[63:0];
		end
		if (valid_buf) begin
			opcode_result_buf <= opcode_buf;
			mul_output <= mul_output_stage1;
		end
		valid_buf <= valid;
		ok <= valid_buf;
	end
	assign result = (opcode_result_buf == 6'd0 ? mul_output[31:0] : mul_output[63:32]);
endmodule
