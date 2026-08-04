module if_stage (
	clk,
	reset,
	ibuf_i_ready,
	output_size,
	pc0,
	inst0,
	pred_br_taken0,
	pred_br_target0,
	pc1,
	inst1,
	pred_br_taken1,
	pred_br_target1,
	have_excp,
	excp_type,
	br_mistaken,
	br_type,
	right_target,
	btb_target,
	wrong_pc,
	update_orien_en,
	retire_pc,
	right_orien,
	icacop_valid,
	cacop_op,
	cacop_addr,
	raise_excp,
	excp_target,
	replay,
	replay_target,
	interrupt,
	idle,
	icache_req,
	icache_op,
	icache_addr,
	icache_uncached,
	icache_addr_ok,
	icache_data_ok,
	icache_rdata,
	mmu_valid,
	mmu_vtag,
	mmu_ok,
	mmu_ptag,
	mmu_mat,
	mmu_page_fault,
	mmu_page_invalid,
	mmu_plv_fault
);
	input clk;
	input reset;
	input ibuf_i_ready;
	output wire [1:0] output_size;
	output wire [31:0] pc0;
	output wire [31:0] inst0;
	output reg pred_br_taken0;
	output reg [31:0] pred_br_target0;
	output wire [31:0] pc1;
	output wire [31:0] inst1;
	output reg pred_br_taken1;
	output reg [31:0] pred_br_target1;
	output reg have_excp;
	output reg [14:0] excp_type;
	input br_mistaken;
	input wire [2:0] br_type;
	input [31:0] right_target;
	input [31:0] btb_target;
	input [31:0] wrong_pc;
	input update_orien_en;
	input [31:0] retire_pc;
	input right_orien;
	input icacop_valid;
	input [1:0] cacop_op;
	input [31:0] cacop_addr;
	input raise_excp;
	input [31:0] excp_target;
	input replay;
	input [31:0] replay_target;
	input interrupt;
	input idle;
	output wire icache_req;
	output wire [2:0] icache_op;
	output wire [31:0] icache_addr;
	output wire icache_uncached;
	input icache_addr_ok;
	input icache_data_ok;
	input [63:0] icache_rdata;
	output wire mmu_valid;
	output wire [19:0] mmu_vtag;
	input mmu_ok;
	input [19:0] mmu_ptag;
	input [1:0] mmu_mat;
	input mmu_page_fault;
	input mmu_page_invalid;
	input mmu_plv_fault;
	reg [31:0] pc_start;
	reg [31:0] pc_start_sent;
	reg have_excp_inner;
	reg [14:0] excp_type_inner;
	wire pred_br_taken0_inner;
	wire [31:0] pred_br_target0_inner;
	wire pred_br_taken1_inner;
	wire [31:0] pred_br_target1_inner;
	reg mmu_ok_reg;
	wire dual;
	reg sent_dual;
	reg pending_data;
	reg cancel;
	reg [31:0] pred_pc_start;
	reg br_mistaken_buf;
	reg [2:0] br_type_buf;
	reg [31:0] btb_target_buf;
	reg [31:0] wrong_pc_buf;
	reg ras_en;
	reg idle_state;
	reg pending_icacop;
	reg [1:0] cacop_op_reg;
	reg [31:0] cacop_addr_reg;
	wire addr_ok;
	assign addr_ok = icache_addr_ok && !pending_icacop;
	assign mmu_valid = (((!idle_state && !mmu_ok_reg) && !br_mistaken) && !raise_excp) && !replay;
	assign mmu_vtag = pc_start[31:12];
	always @(posedge clk)
		if (reset)
			mmu_ok_reg <= 1'b0;
		else if (((addr_ok || br_mistaken) || raise_excp) || replay)
			mmu_ok_reg <= 1'b0;
		else if (mmu_ok)
			mmu_ok_reg <= 1'b1;
	always @(posedge clk)
		if (reset)
			idle_state <= 1'b0;
		else if (interrupt)
			idle_state <= 1'b0;
		else if (idle)
			idle_state <= 1'b1;
	always @(posedge clk)
		if (reset || icache_addr_ok)
			pending_icacop <= 1'b0;
		else if (icacop_valid) begin
			pending_icacop <= 1'b1;
			cacop_op_reg <= cacop_op;
			cacop_addr_reg <= cacop_addr;
		end
	always @(*) begin
		if (pred_br_taken0_inner)
			pred_pc_start = pred_br_target0_inner;
		else if (pred_br_taken1_inner && dual)
			pred_pc_start = pred_br_target1_inner;
		else if (dual)
			pred_pc_start = pc_start + 32'd8;
		else
			pred_pc_start = pc_start + 32'd4;
	end
	assign pc0 = pc_start_sent;
	assign pc1 = pc0 + 32'd4;
	assign inst0 = (have_excp ? 32'h03400000 : icache_rdata[31:0]);
	assign inst1 = icache_rdata[63:32];
	always @(posedge clk)
		if (reset) begin
			pc_start <= 32'h1c000000;
			pending_data <= 1'b0;
			cancel <= 1'b0;
			have_excp <= 1'b0;
		end
		else if ((br_mistaken || raise_excp) || replay) begin
			if ((icache_req && addr_ok) || (pending_data && !icache_data_ok)) begin
				cancel <= 1'b1;
				pending_data <= 1'b1;
			end
			else if (icache_data_ok) begin
				if (cancel)
					cancel <= 1'b0;
				pending_data <= 1'b0;
			end
			if (raise_excp)
				pc_start <= excp_target;
			else if (replay)
				pc_start <= replay_target;
			else
				pc_start <= right_target;
			have_excp <= 1'b0;
		end
		else begin
			if (icache_data_ok) begin
				if (cancel)
					cancel <= 1'b0;
				pending_data <= 1'b0;
			end
			if ((icache_req && addr_ok) || (have_excp_inner && (!pending_data || icache_data_ok))) begin
				pc_start_sent <= pc_start;
				pred_br_taken0 <= pred_br_taken0_inner;
				pred_br_target0 <= pred_br_target0_inner;
				pred_br_taken1 <= pred_br_taken1_inner;
				pred_br_target1 <= pred_br_target1_inner;
				sent_dual <= dual;
				have_excp <= have_excp_inner;
				excp_type <= excp_type_inner;
			end
			if (icache_req && addr_ok) begin
				pc_start <= pred_pc_start;
				pending_data <= 1'b1;
			end
		end
	assign icache_req = ((((!idle_state && (mmu_ok || mmu_ok_reg)) && !have_excp_inner) && ibuf_i_ready) && (!pending_data || icache_data_ok)) || pending_icacop;
	assign icache_op = (pending_icacop ? {1'b1, cacop_op_reg} : 3'd0);
	assign icache_uncached = mmu_mat == 2'd0;
	assign icache_addr = (pending_icacop ? cacop_addr_reg : {mmu_ptag, pc_start[11:0]});
	assign output_size = (have_excp ? {1'b0, ibuf_i_ready} : (!icache_data_ok || cancel ? 2'd0 : (sent_dual && !pred_br_taken0 ? 2'd2 : 2'd1)));
	assign dual = (mmu_mat == 2'd1) && (pc_start[4:2] != {3 {1'b1}});
	always @(*) begin
		if (pc_start[1:0] != 2'h0) begin
			have_excp_inner = 1'b1;
			excp_type_inner = 15'h1000;
		end
		else if (mmu_page_fault && (mmu_ok || mmu_ok_reg)) begin
			have_excp_inner = 1'b1;
			excp_type_inner = 15'h7a00;
		end
		else if (mmu_page_invalid && (mmu_ok || mmu_ok_reg)) begin
			have_excp_inner = 1'b1;
			excp_type_inner = 15'h0600;
		end
		else if (mmu_plv_fault && (mmu_ok || mmu_ok_reg)) begin
			have_excp_inner = 1'b1;
			excp_type_inner = 15'h0e00;
		end
		else begin
			have_excp_inner = 1'b0;
			excp_type_inner = 15'h1000;
		end
	end
	always @(posedge clk) begin
		br_mistaken_buf <= br_mistaken;
		br_type_buf <= br_type;
		btb_target_buf <= btb_target;
		wrong_pc_buf <= wrong_pc;
		ras_en <= icache_req && icache_addr_ok;
	end
	pred u_pred(
		.clk(clk),
		.reset(reset),
		.fetch_pc_0(pc_start),
		.fetch_pc_1(pc_start + 32'd4),
		.dual_issue(sent_dual),
		.ras_en(ras_en),
		.ret_pc_0(pred_br_target0_inner),
		.ret_pc_1(pred_br_target1_inner),
		.taken_0(pred_br_taken0_inner),
		.taken_1(pred_br_taken1_inner),
		.branch_mistaken(br_mistaken_buf),
		.wrong_pc(wrong_pc_buf),
		.right_target(btb_target_buf),
		.ins_type_w(br_type_buf),
		.update_orien_en(update_orien_en),
		.retire_pc(retire_pc),
		.right_orien(right_orien)
	);
endmodule
