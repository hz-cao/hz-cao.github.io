module ooo_lsq #(
	parameter LSQ_SIZE = 8,
	parameter LSQ_ID_WIDTH = 3,
	parameter ROB_ID_WIDTH = 4
) (
	clk,
	reset,
	flush,
	alloc0_valid,
	alloc0_is_store,
	alloc0_rob_id,
	alloc0_id,
	alloc1_valid,
	alloc1_is_store,
	alloc1_rob_id,
	alloc1_id,
	alloc_ready,
	addr0_valid,
	addr0_id,
	addr0_addr,
	addr0_wstrb,
	addr0_wdata,
	addr1_valid,
	addr1_id,
	addr1_addr,
	addr1_wstrb,
	addr1_wdata,
	load_issue_valid,
	load_issue_id,
	load_issue_addr,
	store_commit_valid,
	store_commit_rob_id,
	store_issue_valid,
	store_issue_id,
	store_issue_addr,
	store_issue_wstrb,
	store_issue_wdata,
	complete_valid,
	complete_id
);
	input clk;
	input reset;
	input flush;
	input alloc0_valid;
	input alloc0_is_store;
	input [ROB_ID_WIDTH - 1:0] alloc0_rob_id;
	output wire [LSQ_ID_WIDTH - 1:0] alloc0_id;
	input alloc1_valid;
	input alloc1_is_store;
	input [ROB_ID_WIDTH - 1:0] alloc1_rob_id;
	output wire [LSQ_ID_WIDTH - 1:0] alloc1_id;
	output wire alloc_ready;
	input addr0_valid;
	input [LSQ_ID_WIDTH - 1:0] addr0_id;
	input [31:0] addr0_addr;
	input [3:0] addr0_wstrb;
	input [31:0] addr0_wdata;
	input addr1_valid;
	input [LSQ_ID_WIDTH - 1:0] addr1_id;
	input [31:0] addr1_addr;
	input [3:0] addr1_wstrb;
	input [31:0] addr1_wdata;
	output wire load_issue_valid;
	output wire [LSQ_ID_WIDTH - 1:0] load_issue_id;
	output wire [31:0] load_issue_addr;
	input store_commit_valid;
	input [ROB_ID_WIDTH - 1:0] store_commit_rob_id;
	output wire store_issue_valid;
	output wire [LSQ_ID_WIDTH - 1:0] store_issue_id;
	output wire [31:0] store_issue_addr;
	output wire [3:0] store_issue_wstrb;
	output wire [31:0] store_issue_wdata;
	input complete_valid;
	input [LSQ_ID_WIDTH - 1:0] complete_id;

	reg valid [0:LSQ_SIZE - 1];
	reg is_store [0:LSQ_SIZE - 1];
	reg issued [0:LSQ_SIZE - 1];
	reg addr_ready [0:LSQ_SIZE - 1];
	reg [ROB_ID_WIDTH - 1:0] rob_id [0:LSQ_SIZE - 1];
	reg [31:0] addr [0:LSQ_SIZE - 1];
	reg [3:0] wstrb [0:LSQ_SIZE - 1];
	reg [31:0] wdata [0:LSQ_SIZE - 1];
	reg [LSQ_ID_WIDTH - 1:0] head;
	reg [LSQ_ID_WIDTH - 1:0] tail;
	reg [LSQ_ID_WIDTH:0] count;
	reg [LSQ_ID_WIDTH - 1:0] load_idx;
	reg [LSQ_ID_WIDTH - 1:0] store_idx;
	reg load_found;
	reg store_found;
	reg older_store_pending;

	wire [LSQ_ID_WIDTH - 1:0] tail_next = tail + {{LSQ_ID_WIDTH - 1 {1'b0}}, 1'b1};
	wire alloc_two = alloc0_valid && alloc1_valid;
	wire alloc_one = alloc0_valid ^ alloc1_valid;
	wire [LSQ_ID_WIDTH:0] alloc_num = alloc_two ? {{LSQ_ID_WIDTH - 1 {1'b0}}, 2'd2} : (alloc_one ? {{LSQ_ID_WIDTH {1'b0}}, 1'b1} : {LSQ_ID_WIDTH + 1 {1'b0}});

	assign alloc0_id = tail;
	assign alloc1_id = tail_next;
	assign alloc_ready = count <= (LSQ_SIZE - 2);
	assign load_issue_valid = load_found;
	assign load_issue_id = load_idx;
	assign load_issue_addr = addr[load_idx];
	assign store_issue_valid = store_found;
	assign store_issue_id = store_idx;
	assign store_issue_addr = addr[store_idx];
	assign store_issue_wstrb = wstrb[store_idx];
	assign store_issue_wdata = wdata[store_idx];

	integer i;
	always @(*) begin
		load_idx = head;
		store_idx = head;
		load_found = 1'b0;
		store_found = 1'b0;
		older_store_pending = 1'b0;
		for (i = 0; i < LSQ_SIZE; i = i + 1) begin
			if (valid[i] && is_store[i] && !issued[i])
				older_store_pending = 1'b1;
			if (valid[i] && !is_store[i] && !issued[i] && addr_ready[i] && !older_store_pending && !load_found) begin
				load_found = 1'b1;
				load_idx = i[LSQ_ID_WIDTH - 1:0];
			end
			if (valid[i] && is_store[i] && !issued[i] && addr_ready[i] && (rob_id[i] == store_commit_rob_id) && store_commit_valid && !store_found) begin
				store_found = 1'b1;
				store_idx = i[LSQ_ID_WIDTH - 1:0];
			end
		end
	end

	always @(posedge clk) begin
		if (reset || flush) begin
			head <= 0;
			tail <= 0;
			count <= 0;
			for (i = 0; i < LSQ_SIZE; i = i + 1) begin
				valid[i] <= 1'b0;
				issued[i] <= 1'b0;
				addr_ready[i] <= 1'b0;
			end
		end
		else begin
			if (alloc0_valid && alloc_ready) begin
				valid[tail] <= 1'b1;
				is_store[tail] <= alloc0_is_store;
				issued[tail] <= 1'b0;
				addr_ready[tail] <= 1'b0;
				rob_id[tail] <= alloc0_rob_id;
			end
			if (alloc1_valid && alloc_ready) begin
				valid[tail_next] <= 1'b1;
				is_store[tail_next] <= alloc1_is_store;
				issued[tail_next] <= 1'b0;
				addr_ready[tail_next] <= 1'b0;
				rob_id[tail_next] <= alloc1_rob_id;
			end
			if (addr0_valid) begin
				addr_ready[addr0_id] <= 1'b1;
				addr[addr0_id] <= addr0_addr;
				wstrb[addr0_id] <= addr0_wstrb;
				wdata[addr0_id] <= addr0_wdata;
			end
			if (addr1_valid) begin
				addr_ready[addr1_id] <= 1'b1;
				addr[addr1_id] <= addr1_addr;
				wstrb[addr1_id] <= addr1_wstrb;
				wdata[addr1_id] <= addr1_wdata;
			end
			if (load_issue_valid)
				issued[load_idx] <= 1'b1;
			if (store_issue_valid)
				issued[store_idx] <= 1'b1;
			if (complete_valid) begin
				valid[complete_id] <= 1'b0;
				if (complete_id == head)
					head <= head + {{LSQ_ID_WIDTH - 1 {1'b0}}, 1'b1};
				count <= count - {{LSQ_ID_WIDTH {1'b0}}, 1'b1};
			end
			if ((alloc0_valid || alloc1_valid) && alloc_ready) begin
				tail <= tail + alloc_num[LSQ_ID_WIDTH - 1:0];
				count <= count + alloc_num;
			end
		end
	end
endmodule
