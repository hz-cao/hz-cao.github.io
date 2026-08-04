module tcache (
	clk,
	reset,
	s_vppn,
	s_va_bit12,
	s_asid,
	s_result,
	invalid,
	refill_valid,
	refill_data,
	refill_index
);
	input clk;
	input reset;
	input [18:0] s_vppn;
	input s_va_bit12;
	input [9:0] s_asid;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	output reg [37:0] s_result;
	input invalid;
	input refill_valid;
	input wire [88:0] refill_data;
	input [4:0] refill_index;
	reg [83:0] data;
	reg [4:0] index;
	wire match_4m = s_vppn[18:9] == data[81:72];
	wire match_4k = s_vppn == data[81-:19];
	wire match_vppn = (data[82] ? match_4m : match_4k);
	wire match_asid = s_asid == data[62-:10];
	wire match = (data[83] && match_vppn) && (match_asid || data[52]);
	wire [5:1] wire_467C5;
	assign wire_467C5 = index;
	always @(*) s_result[36-:5] = wire_467C5;
	wire [1:1] wire_C2EFF;
	assign wire_C2EFF = match;
	always @(*) s_result[37] = wire_C2EFF;
	always @(*) begin
		if (((data[82] == 0) && (s_va_bit12 == 0)) || ((data[82] == 1) && (s_vppn[8] == 0))) begin
			s_result[31-:20] = data[51-:20];
			s_result[11-:6] = (data[82] ? 21 : 12);
			s_result[5-:2] = data[31-:2];
			s_result[3-:2] = data[29-:2];
			s_result[1] = data[27];
			s_result[0] = data[26];
		end
		else begin
			s_result[31-:20] = data[25-:20];
			s_result[11-:6] = (data[82] ? 21 : 12);
			s_result[5-:2] = data[5-:2];
			s_result[3-:2] = data[3-:2];
			s_result[1] = data[1];
			s_result[0] = data[0];
		end
	end
	always @(posedge clk)
		if (reset || invalid)
			data[83] <= 0;
		else if (refill_valid) begin
			index <= refill_index;
			data[83] <= refill_data[52];
			data[81-:19] <= refill_data[88-:19];
			data[82] <= (refill_data[69-:6] == 12 ? 0 : 1);
			data[62-:10] <= refill_data[62-:10];
			data[52] <= refill_data[63];
			data[51-:20] <= refill_data[51-:20];
			data[31-:2] <= refill_data[31-:2];
			data[29-:2] <= refill_data[29-:2];
			data[27] <= refill_data[27];
			data[26] <= refill_data[26];
			data[25-:20] <= refill_data[25-:20];
			data[5-:2] <= refill_data[5-:2];
			data[3-:2] <= refill_data[3-:2];
			data[1] <= refill_data[1];
			data[0] <= refill_data[0];
		end
endmodule
