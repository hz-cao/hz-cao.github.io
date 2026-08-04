// Simulation stub for Xilinx mult_gen_0 (Multiplier v12.0).
// Config: signed 33 x signed 33 -> signed 64, C_LATENCY=2, no CE, no SCLR.
// Replaced by the real IP for synthesis (see xilinx_ip/mult_gen_0.xci).
module mult_gen_0 (
	CLK,
	A,
	B,
	P
);
	input         CLK;
	input  [32:0] A;
	input  [32:0] B;
	output [63:0] P;

	// 2-cycle latency: combinational product -> reg stage1 -> reg stage2 -> P
	reg signed [65:0] p_stage1;
	reg signed [65:0] p_stage2;

	wire signed [32:0] a_s = A;
	wire signed [32:0] b_s = B;
	wire signed [65:0] product = a_s * b_s;

	initial begin
		p_stage1 = 66'b0;
		p_stage2 = 66'b0;
	end

	always @(posedge CLK) begin
		p_stage1 <= product;
		p_stage2 <= p_stage1;
	end

	assign P = p_stage2[63:0];
endmodule
