// Iterative 32-bit divider for DIV.W/DIV.WU/MOD.W/MOD.WU.
// One quotient bit is produced per cycle, avoiding the large combinational
// divider inferred by Verilog '/' and '%' operators.

module div (
	clk,
	reset,
	valid,
	opcode,
	src1,
	src2,
	ok,
	result
);
	input clk;
	input reset;
	input valid;
	input [5:0] opcode;
	input [31:0] src1;
	input [31:0] src2;
	output reg ok;
	output reg [31:0] result;

	reg busy;
	reg [5:0] iteration;
	reg [31:0] divisor_abs;
	reg [31:0] dividend_shift;
	reg [32:0] remainder_work;
	reg [31:0] quotient_work;
	reg quotient_negative;
	reg remainder_negative;
	reg want_quotient;
	reg divide_by_zero;
	reg [31:0] original_dividend;

	wire signed_op = (opcode == 6'd0) || (opcode == 6'd2);
	wire quotient_op = (opcode == 6'd0) || (opcode == 6'd1);
	wire [31:0] src1_abs = (signed_op && src1[31]) ? (~src1 + 1'b1) : src1;
	wire [31:0] src2_abs = (signed_op && src2[31]) ? (~src2 + 1'b1) : src2;
	wire [32:0] shifted_remainder = {remainder_work[31:0], dividend_shift[31]};
	wire trial_succeeds = shifted_remainder >= {1'b0, divisor_abs};
	wire [32:0] remainder_next = trial_succeeds
	                               ? shifted_remainder - {1'b0, divisor_abs}
	                               : shifted_remainder;
	wire [31:0] quotient_next = {quotient_work[30:0], trial_succeeds};
	wire [31:0] signed_quotient = quotient_negative ? (~quotient_next + 1'b1)
	                                                       : quotient_next;
	wire [31:0] unsigned_remainder = remainder_next[31:0];
	wire [31:0] signed_remainder = remainder_negative
	                              ? (~unsigned_remainder + 1'b1)
	                              : unsigned_remainder;

	initial begin
		busy = 1'b0;
		ok = 1'b0;
		result = 32'b0;
	end

	always @(posedge clk) begin
		if (reset) begin
			busy <= 1'b0;
			ok <= 1'b0;
			iteration <= 6'b0;
			result <= 32'b0;
		end
		else begin
			ok <= 1'b0;
			if (valid && !busy) begin
				busy <= 1'b1;
				iteration <= 6'b0;
				divisor_abs <= src2_abs;
				dividend_shift <= src1_abs;
				remainder_work <= 33'b0;
				quotient_work <= 32'b0;
				quotient_negative <= signed_op && (src1[31] ^ src2[31]);
				remainder_negative <= signed_op && src1[31];
				want_quotient <= quotient_op;
				divide_by_zero <= src2 == 32'b0;
				original_dividend <= src1;
			end
			else if (busy) begin
				dividend_shift <= {dividend_shift[30:0], 1'b0};
				remainder_work <= remainder_next;
				quotient_work <= quotient_next;
				if (iteration == 6'd31) begin
					busy <= 1'b0;
					ok <= 1'b1;
					if (divide_by_zero)
						result <= want_quotient ? 32'hffffffff : original_dividend;
					else
						result <= want_quotient ? signed_quotient : signed_remainder;
				end
				else
					iteration <= iteration + 1'b1;
			end
		end
	end
endmodule
