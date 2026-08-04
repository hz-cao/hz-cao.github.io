module lsu (
	clk,
	reset,
	valid,
	ready,
	addr,
	opcode,
	st_data,
	dcacop_valid,
	cacop_op,
	cacop2_valid,
	cacop2_ok,
	have_excp,
	excp_type,
	ok,
	ld_data,
	dcache_valid,
	dcache_op,
	dcache_tag,
	dcache_index,
	dcache_offset,
	dcache_wstrb,
	dcache_wdata,
	dcache_uncached,
	dcache_size,
	dcache_addr_ok,
	dcache_data_ok,
	dcache_rdata,
	mmu_valid,
	mmu_vtag,
	mmu_ok,
	mmu_ptag,
	mmu_mat,
	mmu_page_fault,
	mmu_page_invalid,
	mmu_page_dirty,
	mmu_plv_fault
);
	input clk;
	input reset;
	input valid;
	output wire ready;
	input [31:0] addr;
	input wire [5:0] opcode;
	input [31:0] st_data;
	input dcacop_valid;
	input [1:0] cacop_op;
	input cacop2_valid;
	output wire cacop2_ok;
	output reg have_excp;
	output reg [14:0] excp_type;
	output wire ok;
	output reg [31:0] ld_data;
	output wire dcache_valid;
	output wire [2:0] dcache_op;
	output wire [19:0] dcache_tag;
	output wire [6:0] dcache_index;
	output wire [4:0] dcache_offset;
	output reg [3:0] dcache_wstrb;
	output reg [31:0] dcache_wdata;
	output wire dcache_uncached;
	output wire [1:0] dcache_size;
	input dcache_addr_ok;
	input dcache_data_ok;
	input [31:0] dcache_rdata;
	output wire mmu_valid;
	output wire [19:0] mmu_vtag;
	input mmu_ok;
	input [19:0] mmu_ptag;
	input [1:0] mmu_mat;
	input mmu_page_fault;
	input mmu_page_invalid;
	input mmu_page_dirty;
	input mmu_plv_fault;
	reg mmu_ok_reg;
	reg [1:0] addr_lowbit_reg;
	reg [5:0] opcode_reg;
	always @(posedge clk)
		if (reset)
			mmu_ok_reg <= 1'b0;
		else if (((valid && ready) || cacop2_valid) || have_excp)
			mmu_ok_reg <= 1'b0;
		else if (mmu_ok)
			mmu_ok_reg <= 1'b1;
	always @(posedge clk)
		if (valid && ready) begin
			addr_lowbit_reg <= addr[1:0];
			opcode_reg <= opcode;
		end
	assign ready = dcache_addr_ok && (mmu_ok || mmu_ok_reg);
	assign ok = dcache_data_ok;
	assign dcache_valid = ((valid && !have_excp) && (mmu_ok || mmu_ok_reg)) || dcacop_valid;
	assign dcache_tag = mmu_ptag;
	assign dcache_index = addr[11:5];
	assign dcache_offset = addr[4:0];
	assign dcache_op = (dcacop_valid ? {1'b1, cacop_op} : {2'd0, opcode[4]});
	assign dcache_size = (opcode[0] ? 2'd0 : (opcode[1] ? 2'd1 : 2'd2));
	assign dcache_uncached = mmu_mat == 2'd0;
	assign mmu_vtag = addr[31:12];
	assign mmu_valid = (valid && !mmu_ok_reg) || cacop2_valid;
	assign cacop2_ok = mmu_ok;
	always @(*) begin
		if (opcode[0]) begin
			(* full_case, parallel_case *)
			case (addr[1:0])
				2'b00: dcache_wstrb = 4'b0001;
				2'b01: dcache_wstrb = 4'b0010;
				2'b10: dcache_wstrb = 4'b0100;
				2'b11: dcache_wstrb = 4'b1000;
			endcase
			dcache_wdata = {4 {st_data[7:0]}};
		end
		else if (opcode[1]) begin
			(* full_case, parallel_case *)
			case (addr[1])
				1'b0: dcache_wstrb = 4'b0011;
				1'b1: dcache_wstrb = 4'b1100;
			endcase
			dcache_wdata = {2 {st_data[15:0]}};
		end
		else begin
			dcache_wstrb = 4'b1111;
			dcache_wdata = st_data;
		end
	end
	always @(*) begin
		if (!valid) begin
			if (cacop2_valid && mmu_page_fault) begin
				have_excp = 1'b1;
				excp_type = 15'h7c00;
			end
			else if (cacop2_valid && mmu_page_invalid) begin
				have_excp = 1'b1;
				excp_type = 15'h0200;
			end
			else begin
				have_excp = 1'b0;
				excp_type = 15'h1200;
			end
		end
		else if ((opcode[1] && addr[0]) || (opcode[2] && (addr[1:0] != 2'h0))) begin
			have_excp = 1'b1;
			excp_type = 15'h1200;
		end
		else if (mmu_page_fault && (mmu_ok || mmu_ok_reg)) begin
			have_excp = 1'b1;
			excp_type = 15'h7c00;
		end
		else if ((mmu_page_invalid && opcode[5]) && (mmu_ok || mmu_ok_reg)) begin
			have_excp = 1'b1;
			excp_type = 15'h0200;
		end
		else if ((mmu_page_invalid && opcode[4]) && (mmu_ok || mmu_ok_reg)) begin
			have_excp = 1'b1;
			excp_type = 15'h0400;
		end
		else if (mmu_plv_fault && (mmu_ok || mmu_ok_reg)) begin
			have_excp = 1'b1;
			excp_type = 15'h0e00;
		end
		else if ((mmu_page_dirty && opcode[4]) && (mmu_ok || mmu_ok_reg)) begin
			have_excp = 1'b1;
			excp_type = 15'h0800;
		end
		else begin
			have_excp = 1'b0;
			excp_type = 15'h1200;
		end
	end
	always @(*) begin
		if (opcode_reg[0]) begin : block_1
			reg [7:0] load_b;
			(* full_case, parallel_case *)
			case (addr_lowbit_reg[1:0])
				2'b00: load_b = dcache_rdata[7:0];
				2'b01: load_b = dcache_rdata[15:8];
				2'b10: load_b = dcache_rdata[23:16];
				2'b11: load_b = dcache_rdata[31:24];
			endcase
			ld_data = {{24 {load_b[7] && opcode_reg[3]}}, load_b};
		end
		else if (opcode_reg[1]) begin : block_2
			reg [15:0] load_h;
			(* full_case, parallel_case *)
			case (addr_lowbit_reg[1])
				1'b0: load_h = dcache_rdata[15:0];
				1'b1: load_h = dcache_rdata[31:16];
			endcase
			ld_data = {{16 {load_h[15] && opcode_reg[3]}}, load_h};
		end
		else
			ld_data = dcache_rdata;
	end
endmodule
