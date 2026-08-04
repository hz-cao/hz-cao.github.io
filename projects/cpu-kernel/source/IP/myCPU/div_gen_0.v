// Simulation stub for Xilinx div_gen_0 (Divider Generator v5.1, AXI4-Stream).
// Config: unsigned 32 / unsigned 32 -> {quotient[31:0], remainder[31:0]}, 64-bit dout.
// C_LATENCY=34, ALGORITHM_TYPE=1 (Radix-2 iterative), blocking throttle.
// div.v handles sign externally (this stub is purely unsigned).
// Replaced by the real IP for synthesis (see xilinx_ip/div_gen_0.xci).
module div_gen_0 (
	aclk,
	s_axis_divisor_tvalid,
	s_axis_divisor_tdata,
	s_axis_dividend_tvalid,
	s_axis_dividend_tdata,
	m_axis_dout_tvalid,
	m_axis_dout_tdata
);
	input          aclk;
	input          s_axis_divisor_tvalid;
	input  [31:0]  s_axis_divisor_tdata;
	input          s_axis_dividend_tvalid;
	input  [31:0]  s_axis_dividend_tdata;
	output         m_axis_dout_tvalid;
	output [63:0]  m_axis_dout_tdata;

	// Combinational unsigned division.  Latency modeled by a 34-stage
	// shift register on {tvalid, tdata}.  Matches the real IP's contract:
	// tvalid asserted N cycles == tvalid asserted 34 cycles later.
	wire        start_valid = s_axis_divisor_tvalid & s_axis_dividend_tvalid;
	wire [31:0] quotient    = (s_axis_divisor_tdata == 32'b0) ? 32'hFFFFFFFF
	                        : (s_axis_dividend_tdata / s_axis_divisor_tdata);
	wire [31:0] remainder   = (s_axis_divisor_tdata == 32'b0) ? s_axis_dividend_tdata
	                        : (s_axis_dividend_tdata % s_axis_divisor_tdata);
	wire [63:0] result_now  = {quotient, remainder};

	// 34-stage delay pipeline
	reg         valid_pipe [0:33];
	reg [63:0]  data_pipe  [0:33];
	integer i;

	initial begin
		for (i = 0; i < 34; i = i + 1) begin
			valid_pipe[i] = 1'b0;
			data_pipe[i]  = 64'b0;
		end
	end

	always @(posedge aclk) begin
		valid_pipe[0] <= start_valid;
		data_pipe[0]  <= result_now;
		for (i = 1; i < 34; i = i + 1) begin
			valid_pipe[i] <= valid_pipe[i-1];
			data_pipe[i]  <= data_pipe[i-1];
		end
	end

	assign m_axis_dout_tvalid = valid_pipe[33];
	assign m_axis_dout_tdata  = data_pipe[33];
endmodule
