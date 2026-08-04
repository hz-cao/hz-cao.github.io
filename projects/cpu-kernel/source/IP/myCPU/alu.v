module alu (
	opcode,
	src1,
	src2,
	result
);
	input wire [5:0] opcode;
	input [31:0] src1;
	input [31:0] src2;
	output reg [31:0] result;
	always @(*) begin
		(* full_case, parallel_case *)
		case (opcode)
			6'd0: result = src2;
			6'd1: result = src1 + src2;
			6'd2: result = src1 - src2;
			6'd3: result = (src1 == src2 ? 32'd1 : 32'd0);
			6'd4: result = ($signed(src1) < $signed(src2) ? 32'd1 : 32'd0);
			6'd5: result = (src1 < src2 ? 32'd1 : 32'd0);
			6'd6: result = src1 & src2;
			6'd7: result = ~(src1 | src2);
			6'd8: result = src1 | src2;
			6'd9: result = src1 ^ src2;
			6'd10: result = src1 << src2[4:0];
			6'd11: result = src1 >> src2[4:0];
			6'd12: result = $signed(src1) >>> src2[4:0];
			6'd13: begin
				case (src1)
					32'h00000001: result = 32'h0001f1f4;
					32'h00000002: result = 32'h00000000;
					32'h00000010: result = 32'h00000005;
					32'h00000011: result = 32'h04080001;
					32'h00000012: result = 32'h04080001;
					32'h00000013: result = 32'h00000000;
					default: result = 32'h00000000;
				endcase
			end
			default: result = src2;
		endcase
	end
endmodule
