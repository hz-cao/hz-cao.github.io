// Stage 2a — Physical Register File.
//
// 64 × 32-bit, 4 read ports, 2 write ports. Physical reg 0 hardwired to 0
// (r0 semantics). Reads are combinational (0-cycle) to match the current
// arch regfile.v behavior. Writes are synchronous on posedge clk.
//
// In Stage 2a this PRF is a passive shadow: writes mirror the arch RF
// writes (with waddr translated to the physical reg via the p_dst allocated
// at dispatch). No consumer reads it yet. Stage 2b will switch the pipeline
// operand-read logic to source from here.

module prf (
	clk, reset,
	// Read ports (combinational)
	raddr1, rdata1,
	raddr2, rdata2,
	raddr3, rdata3,
	raddr4, rdata4,
	rready1, rready2, rready3, rready4,
	alloc1_valid, alloc1_addr,
	alloc2_valid, alloc2_addr,
	// Write ports (synchronous)
	we1, waddr1, wdata1,
	we2, waddr2, wdata2
);
	input clk;
	input reset;
	input  [5:0]  raddr1;
	output [31:0] rdata1;
	input  [5:0]  raddr2;
	output [31:0] rdata2;
	input  [5:0]  raddr3;
	output [31:0] rdata3;
	input  [5:0]  raddr4;
	output [31:0] rdata4;
	output wire rready1;
	output wire rready2;
	output wire rready3;
	output wire rready4;
	input         alloc1_valid;
	input  [5:0]  alloc1_addr;
	input         alloc2_valid;
	input  [5:0]  alloc2_addr;
	input         we1;
	input  [5:0]  waddr1;
	input  [31:0] wdata1;
	input         we2;
	input  [5:0]  waddr2;
	input  [31:0] wdata2;

	reg [31:0] prf_mem [0:63];
	reg [63:0] ready_bits;
	integer i;
	initial begin
		for (i = 0; i < 64; i = i + 1)
			prf_mem[i] = 32'b0;
		ready_bits = 64'h00000000ffffffff;
	end

	always @(posedge clk) begin
		if (reset)
			ready_bits <= 64'h00000000ffffffff;
		else begin
			if (alloc1_valid && alloc1_addr != 6'd0)
				ready_bits[alloc1_addr] <= 1'b0;
			if (alloc2_valid && alloc2_addr != 6'd0)
				ready_bits[alloc2_addr] <= 1'b0;
			// Skip writes to phys reg 0 (reserved for r0)
			if (we1 && waddr1 != 6'd0) begin
				prf_mem[waddr1] <= wdata1;
				ready_bits[waddr1] <= 1'b1;
			end
			if (we2 && waddr2 != 6'd0) begin
				prf_mem[waddr2] <= wdata2;
				ready_bits[waddr2] <= 1'b1;
			end
		end
	end

	// Read port: phys 0 always returns 0
	assign rdata1 = (raddr1 == 6'd0) ? 32'b0 : prf_mem[raddr1];
	assign rdata2 = (raddr2 == 6'd0) ? 32'b0 : prf_mem[raddr2];
	assign rdata3 = (raddr3 == 6'd0) ? 32'b0 : prf_mem[raddr3];
	assign rdata4 = (raddr4 == 6'd0) ? 32'b0 : prf_mem[raddr4];
	assign rready1 = (raddr1 == 6'd0) || ready_bits[raddr1];
	assign rready2 = (raddr2 == 6'd0) || ready_bits[raddr2];
	assign rready3 = (raddr3 == 6'd0) || ready_bits[raddr3];
	assign rready4 = (raddr4 == 6'd0) || ready_bits[raddr4];
endmodule
