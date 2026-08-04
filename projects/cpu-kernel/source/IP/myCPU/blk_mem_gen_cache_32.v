// Simulation stub for Xilinx blk_mem_gen_cache_32 (Block Memory Generator v8.4).
// Config: single-port, 256-bit wide x 128 entries, C_READ_LATENCY=1,
//         WRITE_FIRST, no ENA, no REGCEA, no RSTA, no byte-write-enable.
// Replaced by the real IP for synthesis (see xilinx_ip/blk_mem_gen_cache_32.xci).
module blk_mem_gen_cache_32 (
	clka,
	wea,
	addra,
	dina,
	douta
);
	input          clka;
	input          wea;
	input  [6:0]   addra;
	input  [255:0] dina;
	output reg [255:0] douta;

	reg [255:0] mem [0:127];
	integer i;

	initial begin
		for (i = 0; i < 128; i = i + 1)
			mem[i] = 256'b0;
		douta = 256'b0;
	end

	always @(posedge clka) begin
		if (wea) begin
			mem[addra] <= dina;
			douta      <= dina;         // WRITE_FIRST semantics
		end else begin
			douta      <= mem[addra];
		end
	end
endmodule
