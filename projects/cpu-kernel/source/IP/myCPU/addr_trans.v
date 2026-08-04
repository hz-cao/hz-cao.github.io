module addr_trans (
	direct_access,
	direct_access_mat,
	plv,
	asid,
	dmw0,
	dmw1,
	use_tlb,
	tlb_s_vppn,
	tlb_s_va_bit12,
	tlb_s_asid,
	tlb_s_result,
	vtag,
	ptag,
	mat,
	page_fault,
	page_invalid,
	page_dirty,
	plv_fault
);
	input direct_access;
	input [1:0] direct_access_mat;
	input [1:0] plv;
	input [9:0] asid;
	input wire [9:0] dmw0;
	input wire [9:0] dmw1;
	output reg use_tlb;
	output wire [18:0] tlb_s_vppn;
	output wire tlb_s_va_bit12;
	output wire [9:0] tlb_s_asid;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	input wire [37:0] tlb_s_result;
	input [19:0] vtag;
	output reg [19:0] ptag;
	output reg [1:0] mat;
	output wire page_fault;
	output wire page_invalid;
	output wire page_dirty;
	output wire plv_fault;
	always @(*) begin
		if (direct_access) begin
			ptag = vtag;
			mat = direct_access_mat;
			use_tlb = 1'b0;
		end
		else if ((vtag[19:17] == dmw0[2-:3]) && (((plv == 2'd0) && dmw0[9]) || ((plv == 2'd3) && dmw0[8]))) begin
			ptag = {dmw0[5-:3], vtag[16:0]};
			mat = dmw0[7-:2];
			use_tlb = 1'b0;
		end
		else if ((vtag[19:17] == dmw1[2-:3]) && (((plv == 2'd0) && dmw1[9]) || ((plv == 2'd3) && dmw1[8]))) begin
			ptag = {dmw1[5-:3], vtag[16:0]};
			mat = dmw1[7-:2];
			use_tlb = 1'b0;
		end
		else begin
			if (tlb_s_result[11-:6] == 12)
				ptag = tlb_s_result[31-:20];
			else
				ptag = {tlb_s_result[31:21], vtag[8:0]};
			mat = tlb_s_result[3-:2];
			use_tlb = 1'b1;
		end
	end
	assign tlb_s_vppn = vtag[19:1];
	assign tlb_s_va_bit12 = vtag[0];
	assign tlb_s_asid = asid;
	assign page_fault = use_tlb && !tlb_s_result[37];
	assign page_invalid = use_tlb && !tlb_s_result[0];
	assign page_dirty = use_tlb && (tlb_s_result[1] == 1'b0);
	assign plv_fault = use_tlb && (plv > tlb_s_result[5-:2]);
endmodule
