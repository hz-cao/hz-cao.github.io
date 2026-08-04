module csr (
	clk,
	reset,
	ext_int,
	addr,
	rdata,
	we,
	mask,
	wdata,
	raise_excp,
	excp_type,
	pc_in,
	pc_out,
	interrupt,
	badv_we,
	badv_data,
	vppn_we,
	vppn_data,
	csr_tlbsrch_we,
	csr_tlbsrch_found,
	csr_tlbsrch_index,
	csr_tlb_we,
	csr_tlb_wdata,
	csr_tlb_rdata,
	csr_tlbidx,
	csr_asid,
	csr_da,
	csr_datf,
	csr_datm,
	csr_plv,
	csr_dmw0,
	csr_dmw1,
	csr_llbit_we,
	csr_llbit_wdata,
	csr_llbit
);
	input clk;
	input reset;
	input [7:0] ext_int;
	input wire [13:0] addr;
	output reg [31:0] rdata;
	input we;
	input [31:0] mask;
	input [31:0] wdata;
	input raise_excp;
	input wire [14:0] excp_type;
	input [31:0] pc_in;
	output wire [31:0] pc_out;
	output wire interrupt;
	input badv_we;
	input [31:0] badv_data;
	input vppn_we;
	input [18:0] vppn_data;
	input csr_tlbsrch_we;
	input csr_tlbsrch_found;
	localparam TLBNUM = 32;
	localparam TLBIDLEN = 5;
	input [4:0] csr_tlbsrch_index;
	input csr_tlb_we;
	input wire [88:0] csr_tlb_wdata;
	output wire [88:0] csr_tlb_rdata;
	output wire [4:0] csr_tlbidx;
	output wire [9:0] csr_asid;
	output wire csr_da;
	output wire [1:0] csr_datf;
	output wire [1:0] csr_datm;
	output wire [1:0] csr_plv;
	output wire [9:0] csr_dmw0;
	output wire [9:0] csr_dmw1;
	input csr_llbit_we;
	input csr_llbit_wdata;
	output wire csr_llbit;
	reg [31:0] CRMD;
	reg [31:0] PRMD;
	reg [31:0] ECFG;
	reg [31:0] ESTAT;
	reg [31:0] ERA;
	reg [31:0] BADV;
	reg [31:0] EENTRY;
	reg [31:0] TLBIDX;
	reg [31:0] TLBEHI;
	localparam PALEN = 32;
	reg [31:0] TLBELO0;
	reg [31:0] TLBELO1;
	reg [31:0] ASID;
	reg [31:0] PGDL;
	reg [31:0] PGDH;
	reg [31:0] SAVE0;
	reg [31:0] SAVE1;
	reg [31:0] SAVE2;
	reg [31:0] SAVE3;
	reg [31:0] LLBCTL;
	reg [31:0] TID;
	reg [31:0] TCFG;
	reg [31:0] TVAL;
	reg [31:0] TLBRENTRY;
	reg [31:0] DMW0;
	reg [31:0] DMW1;
	wire [31:0] wdata_m = (rdata & ~mask) | (wdata & mask);
	assign pc_out = (excp_type == 15'h783c ? ERA : ((excp_type == 15'h7a00) || (excp_type == 15'h7c00) ? TLBRENTRY : EENTRY));
	wire [12:0] int_vec = ESTAT[12-:13] & ECFG[12-:13];
	assign interrupt = CRMD[2] && (int_vec != 13'h0000);
	reg timer_en;
	always @(posedge clk) ESTAT[9:2] <= ext_int;
	always @(*) begin
		(* full_case, parallel_case *)
		case (addr)
			14'h0000: rdata = CRMD;
			14'h0001: rdata = PRMD;
			14'h0004: rdata = ECFG;
			14'h0005: rdata = ESTAT;
			14'h0006: rdata = ERA;
			14'h0007: rdata = BADV;
			14'h000c: rdata = EENTRY;
			14'h0010: rdata = TLBIDX;
			14'h0011: rdata = TLBEHI;
			14'h0012: rdata = TLBELO0;
			14'h0013: rdata = TLBELO1;
			14'h0018: rdata = ASID;
			14'h0019: rdata = PGDL;
			14'h001a: rdata = PGDH;
			14'h001b: rdata = (BADV[31] ? PGDH : PGDL);
			14'h0030: rdata = SAVE0;
			14'h0031: rdata = SAVE1;
			14'h0032: rdata = SAVE2;
			14'h0033: rdata = SAVE3;
			14'h0040: rdata = TID;
			14'h0041: rdata = TCFG;
			14'h0042: rdata = TVAL;
			14'h0044: rdata = 32'h00000000;
			14'h0060: rdata = LLBCTL;
			14'h0088: rdata = TLBRENTRY;
			14'h0180: rdata = DMW0;
			14'h0181: rdata = DMW1;
			default: rdata = 32'h00000000;
		endcase
	end
	assign csr_tlb_rdata[88-:19] = TLBEHI[31-:19];
	assign csr_tlb_rdata[69-:6] = TLBIDX[29-:6];
	assign csr_tlb_rdata[63] = TLBELO0[6] && TLBELO1[6];
	assign csr_tlb_rdata[62-:10] = ASID[9-:10];
	assign csr_tlb_rdata[52] = (ESTAT[21-:6] == 6'h3f ? 1'b1 : !TLBIDX[31]);
	assign csr_tlb_rdata[51-:20] = TLBELO0[27-:20];
	assign csr_tlb_rdata[31-:2] = TLBELO0[3-:2];
	assign csr_tlb_rdata[29-:2] = TLBELO0[5-:2];
	assign csr_tlb_rdata[27] = TLBELO0[1];
	assign csr_tlb_rdata[26] = TLBELO0[0];
	assign csr_tlb_rdata[25-:20] = TLBELO1[27-:20];
	assign csr_tlb_rdata[5-:2] = TLBELO1[3-:2];
	assign csr_tlb_rdata[3-:2] = TLBELO1[5-:2];
	assign csr_tlb_rdata[1] = TLBELO1[1];
	assign csr_tlb_rdata[0] = TLBELO1[0];
	assign csr_tlbidx = TLBIDX[4-:TLBIDLEN];
	assign csr_asid = ASID[9-:10];
	assign csr_da = CRMD[3];
	assign csr_datf = CRMD[6-:2];
	assign csr_datm = CRMD[8-:2];
	assign csr_plv = CRMD[1-:2];
	assign csr_dmw0[9] = DMW0[0];
	assign csr_dmw0[8] = DMW0[3];
	assign csr_dmw0[7-:2] = DMW0[5-:2];
	assign csr_dmw0[5-:3] = DMW0[27-:3];
	assign csr_dmw0[2-:3] = DMW0[31-:3];
	assign csr_dmw1[9] = DMW1[0];
	assign csr_dmw1[8] = DMW1[3];
	assign csr_dmw1[7-:2] = DMW1[5-:2];
	assign csr_dmw1[5-:3] = DMW1[27-:3];
	assign csr_dmw1[2-:3] = DMW1[31-:3];
	assign csr_llbit = LLBCTL[0];
	always @(posedge clk) begin
		if (reset) begin
			CRMD[1-:2] <= 0;
			CRMD[2] <= 0;
			CRMD[3] <= 1;
			CRMD[4] <= 0;
			CRMD[6-:2] <= 0;
			CRMD[8-:2] <= 0;
			CRMD[31-:23] <= 0;
			PRMD[31-:29] <= 0;
			ECFG <= 0;
			ESTAT[31:10] <= 0;
			ESTAT[1:0] <= 0;
			EENTRY[5-:6] <= 0;
			TLBIDX[30] <= 0;
			TLBIDX[23-:8] <= 0;
			TLBIDX[15-:11] <= 0;
			TLBEHI[12-:13] <= 0;
			TLBELO0[31-:4] <= 0;
			TLBELO0[7] <= 0;
			TLBELO1[31-:4] <= 0;
			TLBELO1[7] <= 0;
			ASID[31-:8] <= 0;
			ASID[23-:8] <= 10;
			ASID[15-:6] <= 0;
			PGDL[11-:12] <= 0;
			PGDH[11-:12] <= 0;
			TCFG[0] <= 0;
			TVAL <= 0;
			LLBCTL[31-:29] <= 0;
			LLBCTL[1] <= 0;
			LLBCTL[2] <= 0;
			TLBRENTRY[5-:6] <= 0;
			DMW0 <= 0;
			DMW1 <= 0;
			timer_en <= 0;
		end
		else if (raise_excp) begin
			if (excp_type != 15'h783c) begin
				PRMD[1-:2] <= CRMD[1-:2];
				PRMD[2] <= CRMD[2];
				CRMD[1-:2] <= 2'h0;
				CRMD[2] <= 1'h0;
				ERA[31-:32] <= pc_in;
				if ((excp_type == 15'h7a00) || (excp_type == 15'h7c00)) begin
					CRMD[3] <= 1'b1;
					CRMD[4] <= 1'b0;
					{ESTAT[21-:6], ESTAT[30-:9]} <= 15'h7e00;
				end
				else
					{ESTAT[21-:6], ESTAT[30-:9]} <= excp_type;
			end
			else begin
				CRMD[1-:2] <= PRMD[1-:2];
				CRMD[2] <= PRMD[2];
				if (ESTAT[21-:6] == 6'h3f) begin
					CRMD[3] <= 1'b0;
					CRMD[4] <= 1'b1;
				end
				if (!LLBCTL[2])
					LLBCTL[0] <= 1'b0;
				else
					LLBCTL[2] <= 1'b0;
			end
		end
		else if (csr_tlbsrch_we) begin
			if (csr_tlbsrch_found) begin
				TLBIDX[4-:TLBIDLEN] <= csr_tlbsrch_index;
				TLBIDX[31] <= 1'b0;
			end
			else
				TLBIDX[31] <= 1'b1;
		end
		else if (csr_tlb_we) begin
			if (csr_tlb_wdata[52]) begin
				TLBEHI[31-:19] <= csr_tlb_wdata[88-:19];
				TLBIDX[29-:6] <= csr_tlb_wdata[69-:6];
				TLBELO0[6] <= csr_tlb_wdata[63];
				TLBELO1[6] <= csr_tlb_wdata[63];
				ASID[9-:10] <= csr_tlb_wdata[62-:10];
				TLBELO0[27-:20] <= csr_tlb_wdata[51-:20];
				TLBELO0[3-:2] <= csr_tlb_wdata[31-:2];
				TLBELO0[5-:2] <= csr_tlb_wdata[29-:2];
				TLBELO0[1] <= csr_tlb_wdata[27];
				TLBELO0[0] <= csr_tlb_wdata[26];
				TLBELO1[27-:20] <= csr_tlb_wdata[25-:20];
				TLBELO1[3-:2] <= csr_tlb_wdata[5-:2];
				TLBELO1[5-:2] <= csr_tlb_wdata[3-:2];
				TLBELO1[1] <= csr_tlb_wdata[1];
				TLBELO1[0] <= csr_tlb_wdata[0];
			end
			else begin
				TLBIDX[31] <= 1'b1;
				ASID[9-:10] <= 10'h000;
				TLBEHI <= 32'h00000000;
				TLBELO0 <= 32'h00000000;
				TLBELO1 <= 32'h00000000;
				TLBIDX[29-:6] <= 6'h00;
			end
		end
		else if (we)
			(* full_case, parallel_case *)
			case (addr)
				14'h0000: CRMD[8:0] <= wdata_m[8:0];
				14'h0001: PRMD[2:0] <= wdata_m[2:0];
				14'h0004: {ECFG[9:0], ECFG[12:11]} <= {wdata_m[9:0], wdata_m[12:11]};
				14'h0005: ESTAT[1:0] <= wdata_m[1:0];
				14'h0006: ERA[31:0] <= wdata_m[31:0];
				14'h0007: BADV[31:0] <= wdata_m[31:0];
				14'h000c: EENTRY[31:6] <= wdata_m[31:6];
				14'h0010: begin
					TLBIDX <= wdata_m;
					TLBIDX[30] <= 0;
					TLBIDX[23-:8] <= 0;
					TLBIDX[15-:11] <= 0;
				end
				14'h0011: TLBEHI[31:13] <= wdata_m[31:13];
				14'h0012: begin
					TLBELO0 <= wdata_m;
					TLBELO0[31-:4] <= 0;
					TLBELO0[7] <= 0;
				end
				14'h0013: begin
					TLBELO1 <= wdata_m;
					TLBELO1[31-:4] <= 0;
					TLBELO1[7] <= 0;
				end
				14'h0018: ASID[9:0] <= wdata_m[9:0];
				14'h0019: PGDL[31:12] <= wdata_m[31:12];
				14'h001a: PGDH[31:12] <= wdata_m[31:12];
				14'h001b:
					;
				14'h0030: SAVE0[31:0] <= wdata_m[31:0];
				14'h0031: SAVE1[31:0] <= wdata_m[31:0];
				14'h0032: SAVE2[31:0] <= wdata_m[31:0];
				14'h0033: SAVE3[31:0] <= wdata_m[31:0];
				14'h0040: TID[31:0] <= wdata_m[31:0];
				14'h0041: begin
					TCFG[31:0] <= wdata_m[31:0];
					timer_en <= wdata_m[0];
					if (wdata_m[0])
						TVAL[31-:32] <= {wdata_m[31:2], 2'b00};
				end
				14'h0042:
					;
				14'h0044:
					if (wdata_m[0])
						ESTAT[11] <= 1'h0;
				14'h0060: begin
					if (wdata_m[1])
						LLBCTL[0] <= 1'b0;
					LLBCTL[2] <= wdata_m[2];
				end
				14'h0088: TLBRENTRY[31:6] <= wdata_m[31:6];
				14'h0180: {DMW0[0], DMW0[5:3], DMW0[27:25], DMW0[31:29]} <= {wdata_m[0], wdata_m[5:3], wdata_m[27:25], wdata_m[31:29]};
				14'h0181: {DMW1[0], DMW1[5:3], DMW1[27:25], DMW1[31:29]} <= {wdata_m[0], wdata_m[5:3], wdata_m[27:25], wdata_m[31:29]};
				default:
					;
			endcase
		if (csr_llbit_we)
			LLBCTL[0] <= csr_llbit_wdata;
		if (badv_we)
			BADV[31-:32] <= badv_data;
		if (vppn_we)
			TLBEHI[31-:19] <= vppn_data;
		if (timer_en) begin
			if (TVAL[31-:32] == 32'h00000000) begin
				if (TCFG[1])
					TVAL[31-:32] <= {TCFG[31-:30], 2'b00};
				else
					timer_en <= 1'h0;
				ESTAT[11] <= 1'h1;
			end
			else
				TVAL[31-:32] <= TVAL[31-:32] - 32'h00000001;
		end
	end
endmodule
