module mycpu_top (
	aclk,
	aresetn,
	ext_int,
	intrpt,
	arid,
	araddr,
	arlen,
	arsize,
	arburst,
	arlock,
	arcache,
	arprot,
	arvalid,
	arready,
	rid,
	rdata,
	rresp,
	rlast,
	rvalid,
	rready,
	awid,
	awaddr,
	awlen,
	awsize,
	awburst,
	awlock,
	awcache,
	awprot,
	awvalid,
	awready,
	wid,
	wdata,
	wstrb,
	wlast,
	wvalid,
	wready,
	bid,
	bresp,
	bvalid,
	bready,
	break_point,
	infor_flag,
	reg_num,
	ws_valid,
	rf_rdata,
	debug0_wb_pc,
	debug0_wb_rf_wen,
	debug0_wb_rf_wnum,
	debug0_wb_rf_wdata,
	debug1_wb_pc,
	debug1_wb_rf_wen,
	debug1_wb_rf_wnum,
	debug1_wb_rf_wdata,
	debug_wb_pc,
	debug_wb_rf_we,
	debug_wb_rf_wnum,
	debug_wb_rf_wdata,
	DretireMask, DretireAddr_0, DretireAddr_1, DretireAddr_2,
	DretireInst_0, DretireInst_1, DretireInst_2,
	DretireWen, DretireWaddr_0, DretireWaddr_1, DretireWaddr_2,
	DretireWresult_0, DretireWresult_1, DretireWresult_2, DuniqueRetire,
	DaRAT_val_0, DaRAT_val_1, DaRAT_val_2, DaRAT_val_3, DaRAT_val_4,
	DaRAT_val_5, DaRAT_val_6, DaRAT_val_7, DaRAT_val_8, DaRAT_val_9,
	DaRAT_val_10, DaRAT_val_11, DaRAT_val_12, DaRAT_val_13, DaRAT_val_14,
	DaRAT_val_15, DaRAT_val_16, DaRAT_val_17, DaRAT_val_18, DaRAT_val_19,
	DaRAT_val_20, DaRAT_val_21, DaRAT_val_22, DaRAT_val_23, DaRAT_val_24,
	DaRAT_val_25, DaRAT_val_26, DaRAT_val_27, DaRAT_val_28, DaRAT_val_29, DaRAT_val_30,
	DifftestBundle_DifftestCSRRegStateCRMD, DifftestBundle_DifftestCSRRegStatePRMD,
	DifftestBundle_DifftestCSRRegStateEUEN, DifftestBundle_DifftestCSRRegStateECFG,
	DifftestBundle_DifftestCSRRegStateESTAT, DifftestBundle_DifftestCSRRegStateERA,
	DifftestBundle_DifftestCSRRegStateBADV, DifftestBundle_DifftestCSRRegStateEENTRY,
	DifftestBundle_DifftestCSRRegStateTLBIDX, DifftestBundle_DifftestCSRRegStateTLBEHI,
	DifftestBundle_DifftestCSRRegStateTLBELO0, DifftestBundle_DifftestCSRRegStateTLBELO1,
	DifftestBundle_DifftestCSRRegStateASID, DifftestBundle_DifftestCSRRegStatePGDL,
	DifftestBundle_DifftestCSRRegStatePGDH, DifftestBundle_DifftestCSRRegStateSAVE0,
	DifftestBundle_DifftestCSRRegStateSAVE1, DifftestBundle_DifftestCSRRegStateSAVE2,
	DifftestBundle_DifftestCSRRegStateSAVE3, DifftestBundle_DifftestCSRRegStateTID,
	DifftestBundle_DifftestCSRRegStateTCFG, DifftestBundle_DifftestCSRRegStateTVAL,
	DifftestBundle_DifftestCSRRegStateTICLR, DifftestBundle_DifftestCSRRegStateLLBCTL,
	DifftestBundle_DifftestCSRRegStateTLBRENTRY, DifftestBundle_DifftestCSRRegStateDMW0,
	DifftestBundle_DifftestCSRRegStateDMW1,
	DifftestDelayBundle_DifftestInstrCommitIndex_0, DifftestDelayBundle_DifftestInstrCommitIndex_1, DifftestDelayBundle_DifftestInstrCommitIndex_2,
	DifftestDelayBundle_DifftestInstrCommitValid_0, DifftestDelayBundle_DifftestInstrCommitValid_1, DifftestDelayBundle_DifftestInstrCommitValid_2,
	DifftestDelayBundle_DifftestInstrCommitPC_0, DifftestDelayBundle_DifftestInstrCommitPC_1, DifftestDelayBundle_DifftestInstrCommitPC_2,
	DifftestDelayBundle_DifftestInstrCommitInstr_0, DifftestDelayBundle_DifftestInstrCommitInstr_1, DifftestDelayBundle_DifftestInstrCommitInstr_2,
	DifftestDelayBundle_DifftestSkip_0, DifftestDelayBundle_DifftestSkip_1, DifftestDelayBundle_DifftestSkip_2,
	DifftestDelayBundle_DifftestIsTlbFill_0, DifftestDelayBundle_DifftestIsTlbFill_1, DifftestDelayBundle_DifftestIsTlbFill_2,
	DifftestDelayBundle_DifftestTlbFillIndex_0, DifftestDelayBundle_DifftestTlbFillIndex_1, DifftestDelayBundle_DifftestTlbFillIndex_2,
	DifftestDelayBundle_DifftestIsCount_0, DifftestDelayBundle_DifftestIsCount_1, DifftestDelayBundle_DifftestIsCount_2,
	DifftestDelayBundle_DifftestCount_0, DifftestDelayBundle_DifftestCount_1, DifftestDelayBundle_DifftestCount_2,
	DifftestDelayBundle_DifftestWen_0, DifftestDelayBundle_DifftestWen_1, DifftestDelayBundle_DifftestWen_2,
	DifftestDelayBundle_DifftestWdest_0, DifftestDelayBundle_DifftestWdest_1, DifftestDelayBundle_DifftestWdest_2,
	DifftestDelayBundle_DifftestWdata_0, DifftestDelayBundle_DifftestWdata_1, DifftestDelayBundle_DifftestWdata_2,
	DifftestDelayBundle_DifftestCsrRstat_0, DifftestDelayBundle_DifftestCsrRstat_1, DifftestDelayBundle_DifftestCsrRstat_2,
	DifftestDelayBundle_DifftestCsrData_0, DifftestDelayBundle_DifftestCsrData_1, DifftestDelayBundle_DifftestCsrData_2,
	DifftestDelayBundle_DifftestExcpEventExcpValid, DifftestDelayBundle_DifftestExcpEventEret,
	DifftestDelayBundle_DifftestExcpEventIntrNO, DifftestDelayBundle_DifftestExcpEventCause,
	DifftestDelayBundle_DifftestExcpEventEPC, DifftestDelayBundle_DifftestExcpEventInst,
	DifftestDelayBundle_DifftestStoreEventValid, DifftestDelayBundle_DifftestStoreEventPAddr,
	DifftestDelayBundle_DifftestStoreEventVAddr, DifftestDelayBundle_DifftestStoreEventData,
	DifftestDelayBundle_DifftestLoadEventValid, DifftestDelayBundle_DifftestLoadEventPAddr,
	DifftestDelayBundle_DifftestLoadEventVAddr
);
	input wire aclk;
	input wire aresetn;
	input wire [7:0] ext_int;
	input wire [7:0] intrpt;
	output wire [3:0] arid;
	output wire [31:0] araddr;
	output wire [7:0] arlen;
	output wire [2:0] arsize;
	output wire [1:0] arburst;
	output wire [1:0] arlock;
	output wire [3:0] arcache;
	output wire [2:0] arprot;
	output wire arvalid;
	input wire arready;
	input wire [3:0] rid;
	input wire [31:0] rdata;
	input wire [1:0] rresp;
	input wire rlast;
	input wire rvalid;
	output wire rready;
	output wire [3:0] awid;
	output wire [31:0] awaddr;
	output wire [7:0] awlen;
	output wire [2:0] awsize;
	output wire [1:0] awburst;
	output wire [1:0] awlock;
	output wire [3:0] awcache;
	output wire [2:0] awprot;
	output wire awvalid;
	input wire awready;
	output wire [3:0] wid;
	output wire [31:0] wdata;
	output wire [3:0] wstrb;
	output wire wlast;
	output wire wvalid;
	input wire wready;
	input wire [3:0] bid;
	input wire [1:0] bresp;
	input wire bvalid;
	output wire bready;
	input wire break_point;
	input wire infor_flag;
	input wire [4:0] reg_num;
	output wire ws_valid;
	output wire [31:0] rf_rdata;
	output wire [31:0] debug1_wb_pc;
	output wire [3:0] debug1_wb_rf_wen;
	output wire [4:0] debug1_wb_rf_wnum;
	output wire [31:0] debug1_wb_rf_wdata;
	output wire [31:0] debug0_wb_pc;
	output wire [3:0] debug0_wb_rf_wen;
	output wire [4:0] debug0_wb_rf_wnum;
	output wire [31:0] debug0_wb_rf_wdata;
	output wire [31:0] debug_wb_pc;
	output wire [3:0] debug_wb_rf_we;
	output wire [4:0] debug_wb_rf_wnum;
	output wire [31:0] debug_wb_rf_wdata;

	// ---- Difftest bundle outputs (Stage-0 baseline reconstruction) ----
	output wire [2:0]  DretireMask;
	output wire [31:0] DretireAddr_0, DretireAddr_1, DretireAddr_2;
	output wire [31:0] DretireInst_0, DretireInst_1, DretireInst_2;
	output wire [2:0]  DretireWen;
	output wire [4:0]  DretireWaddr_0, DretireWaddr_1, DretireWaddr_2;
	output wire [31:0] DretireWresult_0, DretireWresult_1, DretireWresult_2;
	output wire [2:0]  DuniqueRetire;
	output wire [31:0] DaRAT_val_0,  DaRAT_val_1,  DaRAT_val_2,  DaRAT_val_3,  DaRAT_val_4;
	output wire [31:0] DaRAT_val_5,  DaRAT_val_6,  DaRAT_val_7,  DaRAT_val_8,  DaRAT_val_9;
	output wire [31:0] DaRAT_val_10, DaRAT_val_11, DaRAT_val_12, DaRAT_val_13, DaRAT_val_14;
	output wire [31:0] DaRAT_val_15, DaRAT_val_16, DaRAT_val_17, DaRAT_val_18, DaRAT_val_19;
	output wire [31:0] DaRAT_val_20, DaRAT_val_21, DaRAT_val_22, DaRAT_val_23, DaRAT_val_24;
	output wire [31:0] DaRAT_val_25, DaRAT_val_26, DaRAT_val_27, DaRAT_val_28, DaRAT_val_29, DaRAT_val_30;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateCRMD;
	output wire [63:0] DifftestBundle_DifftestCSRRegStatePRMD;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateEUEN;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateECFG;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateESTAT;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateERA;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateBADV;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateEENTRY;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTLBIDX;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTLBEHI;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTLBELO0;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTLBELO1;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateASID;
	output wire [63:0] DifftestBundle_DifftestCSRRegStatePGDL;
	output wire [63:0] DifftestBundle_DifftestCSRRegStatePGDH;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateSAVE0;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateSAVE1;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateSAVE2;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateSAVE3;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTID;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTCFG;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTVAL;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTICLR;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateLLBCTL;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateTLBRENTRY;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateDMW0;
	output wire [63:0] DifftestBundle_DifftestCSRRegStateDMW1;
	output wire [7:0]  DifftestDelayBundle_DifftestInstrCommitIndex_0;
	output wire [7:0]  DifftestDelayBundle_DifftestInstrCommitIndex_1;
	output wire [7:0]  DifftestDelayBundle_DifftestInstrCommitIndex_2;
	output wire        DifftestDelayBundle_DifftestInstrCommitValid_0;
	output wire        DifftestDelayBundle_DifftestInstrCommitValid_1;
	output wire        DifftestDelayBundle_DifftestInstrCommitValid_2;
	output wire [63:0] DifftestDelayBundle_DifftestInstrCommitPC_0;
	output wire [63:0] DifftestDelayBundle_DifftestInstrCommitPC_1;
	output wire [63:0] DifftestDelayBundle_DifftestInstrCommitPC_2;
	output wire [31:0] DifftestDelayBundle_DifftestInstrCommitInstr_0;
	output wire [31:0] DifftestDelayBundle_DifftestInstrCommitInstr_1;
	output wire [31:0] DifftestDelayBundle_DifftestInstrCommitInstr_2;
	output wire        DifftestDelayBundle_DifftestSkip_0;
	output wire        DifftestDelayBundle_DifftestSkip_1;
	output wire        DifftestDelayBundle_DifftestSkip_2;
	output wire        DifftestDelayBundle_DifftestIsTlbFill_0;
	output wire        DifftestDelayBundle_DifftestIsTlbFill_1;
	output wire        DifftestDelayBundle_DifftestIsTlbFill_2;
	output wire [4:0]  DifftestDelayBundle_DifftestTlbFillIndex_0;
	output wire [4:0]  DifftestDelayBundle_DifftestTlbFillIndex_1;
	output wire [4:0]  DifftestDelayBundle_DifftestTlbFillIndex_2;
	output wire        DifftestDelayBundle_DifftestIsCount_0;
	output wire        DifftestDelayBundle_DifftestIsCount_1;
	output wire        DifftestDelayBundle_DifftestIsCount_2;
	output wire [63:0] DifftestDelayBundle_DifftestCount_0;
	output wire [63:0] DifftestDelayBundle_DifftestCount_1;
	output wire [63:0] DifftestDelayBundle_DifftestCount_2;
	output wire        DifftestDelayBundle_DifftestWen_0;
	output wire        DifftestDelayBundle_DifftestWen_1;
	output wire        DifftestDelayBundle_DifftestWen_2;
	output wire [7:0]  DifftestDelayBundle_DifftestWdest_0;
	output wire [7:0]  DifftestDelayBundle_DifftestWdest_1;
	output wire [7:0]  DifftestDelayBundle_DifftestWdest_2;
	output wire [63:0] DifftestDelayBundle_DifftestWdata_0;
	output wire [63:0] DifftestDelayBundle_DifftestWdata_1;
	output wire [63:0] DifftestDelayBundle_DifftestWdata_2;
	output wire        DifftestDelayBundle_DifftestCsrRstat_0;
	output wire        DifftestDelayBundle_DifftestCsrRstat_1;
	output wire        DifftestDelayBundle_DifftestCsrRstat_2;
	output wire [31:0] DifftestDelayBundle_DifftestCsrData_0;
	output wire [31:0] DifftestDelayBundle_DifftestCsrData_1;
	output wire [31:0] DifftestDelayBundle_DifftestCsrData_2;
	output wire        DifftestDelayBundle_DifftestExcpEventExcpValid;
	output wire        DifftestDelayBundle_DifftestExcpEventEret;
	output wire [31:0] DifftestDelayBundle_DifftestExcpEventIntrNO;
	output wire [31:0] DifftestDelayBundle_DifftestExcpEventCause;
	output wire [63:0] DifftestDelayBundle_DifftestExcpEventEPC;
	output wire [31:0] DifftestDelayBundle_DifftestExcpEventInst;
	output wire [7:0]  DifftestDelayBundle_DifftestStoreEventValid;
	output wire [63:0] DifftestDelayBundle_DifftestStoreEventPAddr;
	output wire [63:0] DifftestDelayBundle_DifftestStoreEventVAddr;
	output wire [63:0] DifftestDelayBundle_DifftestStoreEventData;
	output wire [7:0]  DifftestDelayBundle_DifftestLoadEventValid;
	output wire [63:0] DifftestDelayBundle_DifftestLoadEventPAddr;
	output wire [63:0] DifftestDelayBundle_DifftestLoadEventVAddr;

	wire icache_req;
	wire [2:0] icache_op;
	wire [31:0] icache_addr;
	wire icache_uncached;
	wire icache_addr_ok;
	wire icache_data_ok;
	wire [63:0] icache_rdata;
	wire dcache_valid;
	wire [2:0] dcache_op;
	wire [19:0] dcache_tag;
	wire [6:0] dcache_index;
	wire [4:0] dcache_offset;
	wire [3:0] dcache_wstrb;
	wire [31:0] dcache_wdata;
	wire dcache_uncached;
	wire [1:0] dcache_size;
	wire dcache_addr_ok;
	wire dcache_data_ok;
	wire [31:0] dcache_rdata;
	wire inst_rd_req;
	wire [2:0] inst_rd_type;
	wire [31:0] inst_rd_addr;
	wire inst_rd_rdy;
	wire inst_ret_valid;
	wire inst_ret_last;
	wire [31:0] inst_ret_data;
	wire inst_wr_req;
	wire [2:0] inst_wr_type;
	wire [31:0] inst_wr_addr;
	wire [3:0] inst_wr_wstrb;
	wire [255:0] inst_wr_data;
	wire inst_wr_rdy;
	wire data_rd_req;
	wire [2:0] data_rd_type;
	wire [31:0] data_rd_addr;
	wire data_rd_rdy;
	wire data_ret_valid;
	wire data_ret_last;
	wire [31:0] data_ret_data;
	wire data_wr_req;
	wire [2:0] data_wr_type;
	wire [31:0] data_wr_addr;
	wire [3:0] data_wr_wstrb;
	wire [255:0] data_wr_data;
	wire data_wr_rdy;
	wire [31:0] core_debug_status0;
	wire [31:0] core_debug_status1;
	core core_0(
		.clk(aclk),
		.resetn(aresetn),
		.ext_int(intrpt),
		.icache_req(icache_req),
		.icache_op(icache_op),
		.icache_addr(icache_addr),
		.icache_uncached(icache_uncached),
		.icache_addr_ok(icache_addr_ok),
		.icache_data_ok(icache_data_ok),
		.icache_rdata(icache_rdata),
		.dcache_valid(dcache_valid),
		.dcache_op(dcache_op),
		.dcache_tag(dcache_tag),
		.dcache_index(dcache_index),
		.dcache_offset(dcache_offset),
		.dcache_wstrb(dcache_wstrb),
		.dcache_wdata(dcache_wdata),
		.dcache_uncached(dcache_uncached),
		.dcache_size(dcache_size),
		.dcache_addr_ok(dcache_addr_ok),
		.dcache_data_ok(dcache_data_ok),
		.dcache_rdata(dcache_rdata),
		.debug0_wb_pc(debug0_wb_pc),
		.debug0_wb_rf_wen(debug0_wb_rf_wen),
		.debug0_wb_rf_wnum(debug0_wb_rf_wnum),
		.debug0_wb_rf_wdata(debug0_wb_rf_wdata),
		.debug1_wb_pc(debug1_wb_pc),
		.debug1_wb_rf_wen(debug1_wb_rf_wen),
		.debug1_wb_rf_wnum(debug1_wb_rf_wnum),
		.debug1_wb_rf_wdata(debug1_wb_rf_wdata),
		.debug_status0(core_debug_status0),
		.debug_status1(core_debug_status1)
	);
	wire [31:0] icache_rdata_l;
	wire [31:0] icache_rdata_h;
	assign icache_rdata = {icache_rdata_h, icache_rdata_l};
	icache icache(
		.clk(aclk),
		.resetn(aresetn),
		.valid(icache_req),
		.op(icache_op),
		.tag(icache_addr[31:12]),
		.index(icache_addr[11:5]),
		.offset(icache_addr[4:0]),
		.uncached(icache_uncached),
		.addr_ok(icache_addr_ok),
		.data_ok(icache_data_ok),
		.rdata_l(icache_rdata_l),
		.rdata_h(icache_rdata_h),
		.rd_req(inst_rd_req),
		.rd_type(inst_rd_type),
		.rd_addr(inst_rd_addr),
		.rd_rdy(inst_rd_rdy),
		.ret_valid(inst_ret_valid),
		.ret_last(inst_ret_last),
		.ret_data(inst_ret_data),
		.wr_req(inst_wr_req),
		.wr_type(inst_wr_type),
		.wr_addr(inst_wr_addr),
		.wr_wstrb(inst_wr_wstrb),
		.wr_data(inst_wr_data),
		.wr_rdy(inst_wr_rdy)
	);
	dcache dcache(
		.clk(aclk),
		.resetn(aresetn),
		.valid(dcache_valid),
		.op(dcache_op),
		.tag(dcache_tag),
		.index(dcache_index),
		.offset(dcache_offset),
		.wstrb(dcache_wstrb),
		.wdata(dcache_wdata),
		.uncached(dcache_uncached),
		.size(dcache_size),
		.addr_ok(dcache_addr_ok),
		.data_ok(dcache_data_ok),
		.rdata(dcache_rdata),
		.rd_req(data_rd_req),
		.rd_type(data_rd_type),
		.rd_addr(data_rd_addr),
		.rd_rdy(data_rd_rdy),
		.ret_valid(data_ret_valid),
		.ret_last(data_ret_last),
		.ret_data(data_ret_data),
		.wr_req(data_wr_req),
		.wr_type(data_wr_type),
		.wr_addr(data_wr_addr),
		.wr_wstrb(data_wr_wstrb),
		.wr_data(data_wr_data),
		.wr_rdy(data_wr_rdy)
	);
	axi_bridge axi_bridge_0(
		.clk(aclk),
		.reset(~aresetn),
		.arid(arid),
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arlock(arlock),
		.arcache(arcache),
		.arprot(arprot),
		.arvalid(arvalid),
		.arready(arready),
		.rid(rid),
		.rdata(rdata),
		.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		.awid(awid),
		.awaddr(awaddr),
		.awlen(awlen),
		.awsize(awsize),
		.awburst(awburst),
		.awlock(awlock),
		.awcache(awcache),
		.awprot(awprot),
		.awvalid(awvalid),
		.awready(awready),
		.wid(wid),
		.wdata(wdata),
		.wstrb(wstrb),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		.bid(bid),
		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		.inst_rd_req(inst_rd_req),
		.inst_rd_type(inst_rd_type),
		.inst_rd_addr(inst_rd_addr),
		.inst_rd_rdy(inst_rd_rdy),
		.inst_ret_valid(inst_ret_valid),
		.inst_ret_last(inst_ret_last),
		.inst_ret_data(inst_ret_data),
		.inst_wr_req(inst_wr_req),
		.inst_wr_type(inst_wr_type),
		.inst_wr_addr(inst_wr_addr),
		.inst_wr_wstrb(inst_wr_wstrb),
		.inst_wr_data(inst_wr_data),
		.inst_wr_rdy(inst_wr_rdy),
		.data_rd_req(data_rd_req),
		.data_rd_type(data_rd_type),
		.data_rd_addr(data_rd_addr),
		.data_rd_rdy(data_rd_rdy),
		.data_ret_valid(data_ret_valid),
		.data_ret_last(data_ret_last),
		.data_ret_data(data_ret_data),
		.data_wr_req(data_wr_req),
		.data_wr_type(data_wr_type),
		.data_wr_addr(data_wr_addr),
		.data_wr_wstrb(data_wr_wstrb),
		.data_wr_data(data_wr_data),
		.data_wr_rdy(data_wr_rdy),
		.write_buffer_empty()
	);

	// ================================================================
	// Difftest bundle wiring (reconstructed baseline — see DESIGN_OOO.md)
	// Taps use hierarchical references into core_0's internal signals.
	// ================================================================

	// ---- Arch GPR snapshot: DaRAT_val_N maps to arch register (N+1) ----
	// With delayed InstrCommit reporting, rf[] is already post-update at
	// the DPI sample cycle — plain read, no bypass needed.
	assign DaRAT_val_0  = core_0.u_regfile.rf[1];
	assign DaRAT_val_1  = core_0.u_regfile.rf[2];
	assign DaRAT_val_2  = core_0.u_regfile.rf[3];
	assign DaRAT_val_3  = core_0.u_regfile.rf[4];
	assign DaRAT_val_4  = core_0.u_regfile.rf[5];
	assign DaRAT_val_5  = core_0.u_regfile.rf[6];
	assign DaRAT_val_6  = core_0.u_regfile.rf[7];
	assign DaRAT_val_7  = core_0.u_regfile.rf[8];
	assign DaRAT_val_8  = core_0.u_regfile.rf[9];
	assign DaRAT_val_9  = core_0.u_regfile.rf[10];
	assign DaRAT_val_10 = core_0.u_regfile.rf[11];
	assign DaRAT_val_11 = core_0.u_regfile.rf[12];
	assign DaRAT_val_12 = core_0.u_regfile.rf[13];
	assign DaRAT_val_13 = core_0.u_regfile.rf[14];
	assign DaRAT_val_14 = core_0.u_regfile.rf[15];
	assign DaRAT_val_15 = core_0.u_regfile.rf[16];
	assign DaRAT_val_16 = core_0.u_regfile.rf[17];
	assign DaRAT_val_17 = core_0.u_regfile.rf[18];
	assign DaRAT_val_18 = core_0.u_regfile.rf[19];
	assign DaRAT_val_19 = core_0.u_regfile.rf[20];
	assign DaRAT_val_20 = core_0.u_regfile.rf[21];
	assign DaRAT_val_21 = core_0.u_regfile.rf[22];
	assign DaRAT_val_22 = core_0.u_regfile.rf[23];
	assign DaRAT_val_23 = core_0.u_regfile.rf[24];
	assign DaRAT_val_24 = core_0.u_regfile.rf[25];
	assign DaRAT_val_25 = core_0.u_regfile.rf[26];
	assign DaRAT_val_26 = core_0.u_regfile.rf[27];
	assign DaRAT_val_27 = core_0.u_regfile.rf[28];
	assign DaRAT_val_28 = core_0.u_regfile.rf[29];
	assign DaRAT_val_29 = core_0.u_regfile.rf[30];
	assign DaRAT_val_30 = core_0.u_regfile.rf[31];

	// ---- CSR snapshot: zero-extend each 32-bit CSR to 64 bits ----
	assign DifftestBundle_DifftestCSRRegStateCRMD      = {32'b0, core_0.u_csr.CRMD};
	assign DifftestBundle_DifftestCSRRegStatePRMD      = {32'b0, core_0.u_csr.PRMD};
	assign DifftestBundle_DifftestCSRRegStateEUEN      = 64'b0;  // FPU not implemented in QHU pipeline
	assign DifftestBundle_DifftestCSRRegStateECFG      = {32'b0, core_0.u_csr.ECFG};
	assign DifftestBundle_DifftestCSRRegStateESTAT     = {32'b0, core_0.u_csr.ESTAT};
	assign DifftestBundle_DifftestCSRRegStateERA       = {32'b0, core_0.u_csr.ERA};
	assign DifftestBundle_DifftestCSRRegStateBADV      = {32'b0, core_0.u_csr.BADV};
	assign DifftestBundle_DifftestCSRRegStateEENTRY    = {32'b0, core_0.u_csr.EENTRY};
	assign DifftestBundle_DifftestCSRRegStateTLBIDX    = {32'b0, core_0.u_csr.TLBIDX};
	assign DifftestBundle_DifftestCSRRegStateTLBEHI    = {32'b0, core_0.u_csr.TLBEHI};
	assign DifftestBundle_DifftestCSRRegStateTLBELO0   = {32'b0, core_0.u_csr.TLBELO0};
	assign DifftestBundle_DifftestCSRRegStateTLBELO1   = {32'b0, core_0.u_csr.TLBELO1};
	assign DifftestBundle_DifftestCSRRegStateASID      = {32'b0, core_0.u_csr.ASID};
	assign DifftestBundle_DifftestCSRRegStatePGDL      = {32'b0, core_0.u_csr.PGDL};
	assign DifftestBundle_DifftestCSRRegStatePGDH      = {32'b0, core_0.u_csr.PGDH};
	assign DifftestBundle_DifftestCSRRegStateSAVE0     = {32'b0, core_0.u_csr.SAVE0};
	assign DifftestBundle_DifftestCSRRegStateSAVE1     = {32'b0, core_0.u_csr.SAVE1};
	assign DifftestBundle_DifftestCSRRegStateSAVE2     = {32'b0, core_0.u_csr.SAVE2};
	assign DifftestBundle_DifftestCSRRegStateSAVE3     = {32'b0, core_0.u_csr.SAVE3};
	assign DifftestBundle_DifftestCSRRegStateTID       = {32'b0, core_0.u_csr.TID};
	assign DifftestBundle_DifftestCSRRegStateTCFG      = {32'b0, core_0.u_csr.TCFG};
	assign DifftestBundle_DifftestCSRRegStateTVAL      = {32'b0, core_0.u_csr.TVAL};
	assign DifftestBundle_DifftestCSRRegStateTICLR     = 64'b0;  // write-only in LoongArch; no state
	assign DifftestBundle_DifftestCSRRegStateLLBCTL    = {32'b0, core_0.u_csr.LLBCTL};
	assign DifftestBundle_DifftestCSRRegStateTLBRENTRY = {32'b0, core_0.u_csr.TLBRENTRY};
	assign DifftestBundle_DifftestCSRRegStateDMW0      = {32'b0, core_0.u_csr.DMW0};
	assign DifftestBundle_DifftestCSRRegStateDMW1      = {32'b0, core_0.u_csr.DMW1};

	// ---- Retire (Dretire*) bundle: 2-way used, slot 2 forced 0 ----
	// One-cycle-delayed pipeline of the commit signals — this matches the
	// "DelayBundle" naming convention: DPI samples the delayed commit at the
	// same posedge where live CSR/PRF read shows the post-update state.
	//   valid = commit fires (includes exception commits)
	//   wen   = commit AND (result written to a non-zero reg)
	reg        wb_a_valid_d, wb_b_valid_d;
	reg        wb_a_wen_d,   wb_b_wen_d;
	reg [31:0] wb_a_pc_d,    wb_b_pc_d;
	reg [31:0] wb_a_inst_d,  wb_b_inst_d;
	reg [4:0]  wb_a_dest_d,  wb_b_dest_d;
	reg [31:0] wb_a_result_d,wb_b_result_d;
	initial begin
		wb_a_valid_d = 0; wb_b_valid_d = 0;
		wb_a_wen_d   = 0; wb_b_wen_d   = 0;
		wb_a_pc_d    = 0; wb_b_pc_d    = 0;
		wb_a_inst_d  = 0; wb_b_inst_d  = 0;
		wb_a_dest_d  = 0; wb_b_dest_d  = 0;
		wb_a_result_d = 0; wb_b_result_d = 0;
	end
	always @(posedge aclk) begin
		wb_a_valid_d  <= core_0.WB_a_valid;
		wb_b_valid_d  <= core_0.WB_b_valid;
		wb_a_wen_d    <= core_0.WB_a_valid & ~core_0.WB_a_have_excp & (core_0.WB_a_dest != 5'd0);
		wb_b_wen_d    <= core_0.WB_b_valid & ~core_0.WB_b_have_excp & (core_0.WB_b_dest != 5'd0);
		wb_a_pc_d     <= core_0.WB_a_pc;
		wb_b_pc_d     <= core_0.WB_b_pc;
		wb_a_inst_d   <= core_0.WB_a_inst;
		wb_b_inst_d   <= core_0.WB_b_inst;
		wb_a_dest_d   <= core_0.WB_a_dest;
		wb_b_dest_d   <= core_0.WB_b_dest;
		wb_a_result_d <= core_0.WB_a_result;
		wb_b_result_d <= core_0.WB_b_result;
	end
	// Legacy same-cycle handles retained for internal use (GPR write-through)
	wire wb_a_commit_valid = core_0.WB_a_valid & ~core_0.WB_a_have_excp;
	wire wb_b_commit_valid = core_0.WB_b_valid & ~core_0.WB_b_have_excp;

	// ---- 1-cycle-delayed ExcpEvent bundle ----
	// raise_excp fires at cycle N (SYSCALL at EX2). csr.v NBA queues
	// ERA/ESTAT updates that apply at end of N. If we drove ExcpValid=1
	// live at N, DIFFTEST proxy->exec(1) would step NEMU at posedge N,
	// then DPI CSR read at that same posedge would see pre-NBA ERA=0.
	// Delaying ExcpValid by 1 cycle makes the sample cycle N+1, where
	// the DUT's ERA/ESTAT have already been written.
	reg        raise_excp_d;
	reg [14:0] ex2_excp_type_d;
	reg [31:0] ex2_excp_pc_d;
	reg        interrupt_d;
	initial begin
		raise_excp_d    = 0;
		ex2_excp_type_d = 0;
		ex2_excp_pc_d   = 0;
		interrupt_d     = 0;
	end
	always @(posedge aclk) begin
		// Stage 4c: tap the commit-triggered exception signals (raise_excp_c
		// = ret_a_valid & ret_a_have_excp) so DIFFTEST ExcpEvent aligns with
		// csr.v's now-commit-time ERA/ESTAT update. The 1-cycle delay reg
		// keeps NEMU-step in sync with DUT-CSR-visible timing.
		raise_excp_d    <= core_0.raise_excp;
		ex2_excp_type_d <= core_0.ex2_excp_type;
		ex2_excp_pc_d   <= core_0.ex2_excp_pc;
		interrupt_d     <= core_0.interrupt;
	end
	assign DretireMask     = {1'b0, wb_b_valid_d, wb_a_valid_d};
	assign DretireAddr_0   = wb_a_pc_d;
	assign DretireAddr_1   = wb_b_pc_d;
	assign DretireAddr_2   = core_debug_status0;
	assign DretireInst_0   = wb_a_inst_d;
	assign DretireInst_1   = wb_b_inst_d;
	assign DretireInst_2   = core_debug_status1;
	assign DretireWen      = {1'b0, wb_b_wen_d, wb_a_wen_d};
	assign DretireWaddr_0  = wb_a_dest_d;
	assign DretireWaddr_1  = wb_b_dest_d;
	assign DretireWaddr_2  = 5'b0;
	assign DretireWresult_0 = wb_a_result_d;
	assign DretireWresult_1 = wb_b_result_d;
	assign DretireWresult_2 = 32'b0;
	assign DuniqueRetire   = 3'b0;  // QHU pipeline does not mark unique-retire

	// ---- DifftestDelayBundle: per-slot commit signals (2-way used) ----
	assign DifftestDelayBundle_DifftestInstrCommitIndex_0 = 8'd0;
	assign DifftestDelayBundle_DifftestInstrCommitIndex_1 = 8'd1;
	assign DifftestDelayBundle_DifftestInstrCommitIndex_2 = 8'd2;
	assign DifftestDelayBundle_DifftestInstrCommitValid_0 = wb_a_valid_d;
	assign DifftestDelayBundle_DifftestInstrCommitValid_1 = wb_b_valid_d;
	assign DifftestDelayBundle_DifftestInstrCommitValid_2 = 1'b0;
	assign DifftestDelayBundle_DifftestInstrCommitPC_0    = {32'b0, wb_a_pc_d};
	assign DifftestDelayBundle_DifftestInstrCommitPC_1    = {32'b0, wb_b_pc_d};
	assign DifftestDelayBundle_DifftestInstrCommitPC_2    = 64'b0;
	assign DifftestDelayBundle_DifftestInstrCommitInstr_0 = wb_a_inst_d;
	assign DifftestDelayBundle_DifftestInstrCommitInstr_1 = wb_b_inst_d;
	assign DifftestDelayBundle_DifftestInstrCommitInstr_2 = 32'b0;
	assign DifftestDelayBundle_DifftestSkip_0             = 1'b0;
	assign DifftestDelayBundle_DifftestSkip_1             = 1'b0;
	assign DifftestDelayBundle_DifftestSkip_2             = 1'b0;
	assign DifftestDelayBundle_DifftestIsTlbFill_0        = 1'b0;
	assign DifftestDelayBundle_DifftestIsTlbFill_1        = 1'b0;
	assign DifftestDelayBundle_DifftestIsTlbFill_2        = 1'b0;
	assign DifftestDelayBundle_DifftestTlbFillIndex_0     = 5'b0;
	assign DifftestDelayBundle_DifftestTlbFillIndex_1     = 5'b0;
	assign DifftestDelayBundle_DifftestTlbFillIndex_2     = 5'b0;
	assign DifftestDelayBundle_DifftestIsCount_0          = 1'b0;
	assign DifftestDelayBundle_DifftestIsCount_1          = 1'b0;
	assign DifftestDelayBundle_DifftestIsCount_2          = 1'b0;
	assign DifftestDelayBundle_DifftestCount_0            = 64'b0;
	assign DifftestDelayBundle_DifftestCount_1            = 64'b0;
	assign DifftestDelayBundle_DifftestCount_2            = 64'b0;
	assign DifftestDelayBundle_DifftestWen_0              = wb_a_wen_d;
	assign DifftestDelayBundle_DifftestWen_1              = wb_b_wen_d;
	assign DifftestDelayBundle_DifftestWen_2              = 1'b0;
	assign DifftestDelayBundle_DifftestWdest_0            = {3'b0, wb_a_dest_d};
	assign DifftestDelayBundle_DifftestWdest_1            = {3'b0, wb_b_dest_d};
	assign DifftestDelayBundle_DifftestWdest_2            = 8'b0;
	assign DifftestDelayBundle_DifftestWdata_0            = {32'b0, wb_a_result_d};
	assign DifftestDelayBundle_DifftestWdata_1            = {32'b0, wb_b_result_d};
	assign DifftestDelayBundle_DifftestWdata_2            = 64'b0;
	assign DifftestDelayBundle_DifftestCsrRstat_0         = 1'b0;
	assign DifftestDelayBundle_DifftestCsrRstat_1         = 1'b0;
	assign DifftestDelayBundle_DifftestCsrRstat_2         = 1'b0;
	assign DifftestDelayBundle_DifftestCsrData_0          = 32'b0;
	assign DifftestDelayBundle_DifftestCsrData_1          = 32'b0;
	assign DifftestDelayBundle_DifftestCsrData_2          = 32'b0;

	// ---- Exception / eret event (single-fire, not per-slot) ----
	// 1-cycle-delayed so the DUT's csr.v NBA (ERA/ESTAT update) has settled
	// before DIFFTEST proxy->exec(1) fires.
	assign DifftestDelayBundle_DifftestExcpEventExcpValid = raise_excp_d;
	assign DifftestDelayBundle_DifftestExcpEventEret      = 1'b0;  // ertn detected via excp_type=0xf83c inside csr; deferred wiring
	assign DifftestDelayBundle_DifftestExcpEventIntrNO    = {31'b0, interrupt_d};
	assign DifftestDelayBundle_DifftestExcpEventCause     = {17'b0, ex2_excp_type_d};
	assign DifftestDelayBundle_DifftestExcpEventEPC       = {32'b0, ex2_excp_pc_d};
	assign DifftestDelayBundle_DifftestExcpEventInst      = wb_a_inst_d;

	// ---- Store / Load event (tapped at LSU; slot0 only, others tied 0) ----
	assign DifftestDelayBundle_DifftestStoreEventValid    = {7'b0, core_0.u_lsu.dcache_valid & (core_0.u_lsu.dcache_op[0])};
	assign DifftestDelayBundle_DifftestStoreEventPAddr    = {12'b0, core_0.u_lsu.mmu_ptag, core_0.u_lsu.dcache_index, core_0.u_lsu.dcache_offset};
	assign DifftestDelayBundle_DifftestStoreEventVAddr    = {32'b0, core_0.u_lsu.addr};
	assign DifftestDelayBundle_DifftestStoreEventData     = {32'b0, core_0.u_lsu.dcache_wdata};
	assign DifftestDelayBundle_DifftestLoadEventValid     = {7'b0, core_0.u_lsu.dcache_valid & ~(core_0.u_lsu.dcache_op[0])};
	assign DifftestDelayBundle_DifftestLoadEventPAddr     = {12'b0, core_0.u_lsu.mmu_ptag, core_0.u_lsu.dcache_index, core_0.u_lsu.dcache_offset};
	assign DifftestDelayBundle_DifftestLoadEventVAddr     = {32'b0, core_0.u_lsu.addr};

endmodule
