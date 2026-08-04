module ooo_rob #(
	parameter ROB_SIZE = 16,
	parameter ROB_ID_WIDTH = 4
) (
	clk,
	reset,
	flush,
	disp0_valid,
	disp0_pc,
	disp0_dest,
	disp0_has_dest,
	disp0_br_type,
	disp0_have_excp,
	disp0_excp_type,
	disp0_excp_addr,
	disp0_id,
	disp1_valid,
	disp1_pc,
	disp1_dest,
	disp1_has_dest,
	disp1_br_type,
	disp1_have_excp,
	disp1_excp_type,
	disp1_excp_addr,
	disp1_id,
	alloc_ready,
	complete0_valid,
	complete0_id,
	complete0_value,
	complete0_have_excp,
	complete0_excp_type,
	complete0_excp_addr,
	complete0_br_taken,
	complete1_valid,
	complete1_id,
	complete1_value,
	complete1_have_excp,
	complete1_excp_type,
	complete1_excp_addr,
	complete1_br_taken,
	commit0_valid,
	commit0_id,
	commit0_pc,
	commit0_dest,
	commit0_has_dest,
	commit0_value,
	commit0_br_type,
	commit0_br_taken,
	commit0_have_excp,
	commit0_excp_type,
	commit0_excp_addr,
	commit1_valid,
	commit1_id,
	commit1_pc,
	commit1_dest,
	commit1_has_dest,
	commit1_value,
	commit1_br_type,
	commit1_br_taken,
	commit1_have_excp,
	commit1_excp_type,
	commit1_excp_addr
);
	input clk;
	input reset;
	input flush;
	input disp0_valid;
	input [31:0] disp0_pc;
	input [4:0] disp0_dest;
	input disp0_has_dest;
	input [2:0] disp0_br_type;
	input disp0_have_excp;
	input [14:0] disp0_excp_type;
	input [31:0] disp0_excp_addr;
	output wire [ROB_ID_WIDTH - 1:0] disp0_id;
	input disp1_valid;
	input [31:0] disp1_pc;
	input [4:0] disp1_dest;
	input disp1_has_dest;
	input [2:0] disp1_br_type;
	input disp1_have_excp;
	input [14:0] disp1_excp_type;
	input [31:0] disp1_excp_addr;
	output wire [ROB_ID_WIDTH - 1:0] disp1_id;
	output wire alloc_ready;
	input complete0_valid;
	input [ROB_ID_WIDTH - 1:0] complete0_id;
	input [31:0] complete0_value;
	input complete0_have_excp;
	input [14:0] complete0_excp_type;
	input [31:0] complete0_excp_addr;
	input complete0_br_taken;
	input complete1_valid;
	input [ROB_ID_WIDTH - 1:0] complete1_id;
	input [31:0] complete1_value;
	input complete1_have_excp;
	input [14:0] complete1_excp_type;
	input [31:0] complete1_excp_addr;
	input complete1_br_taken;
	output wire commit0_valid;
	output wire [ROB_ID_WIDTH - 1:0] commit0_id;
	output wire [31:0] commit0_pc;
	output wire [4:0] commit0_dest;
	output wire commit0_has_dest;
	output wire [31:0] commit0_value;
	output wire [2:0] commit0_br_type;
	output wire commit0_br_taken;
	output wire commit0_have_excp;
	output wire [14:0] commit0_excp_type;
	output wire [31:0] commit0_excp_addr;
	output wire commit1_valid;
	output wire [ROB_ID_WIDTH - 1:0] commit1_id;
	output wire [31:0] commit1_pc;
	output wire [4:0] commit1_dest;
	output wire commit1_has_dest;
	output wire [31:0] commit1_value;
	output wire [2:0] commit1_br_type;
	output wire commit1_br_taken;
	output wire commit1_have_excp;
	output wire [14:0] commit1_excp_type;
	output wire [31:0] commit1_excp_addr;

	reg [ROB_ID_WIDTH - 1:0] head;
	reg [ROB_ID_WIDTH - 1:0] tail;
	reg [ROB_ID_WIDTH:0] count;
	reg valid [0:ROB_SIZE - 1];
	reg ready [0:ROB_SIZE - 1];
	reg [31:0] pc [0:ROB_SIZE - 1];
	reg [4:0] dest [0:ROB_SIZE - 1];
	reg has_dest [0:ROB_SIZE - 1];
	reg [31:0] value [0:ROB_SIZE - 1];
	reg [2:0] br_type [0:ROB_SIZE - 1];
	reg br_taken [0:ROB_SIZE - 1];
	reg have_excp [0:ROB_SIZE - 1];
	reg [14:0] excp_type [0:ROB_SIZE - 1];
	reg [31:0] excp_addr [0:ROB_SIZE - 1];

	wire [ROB_ID_WIDTH - 1:0] head_next = head + {{ROB_ID_WIDTH - 1 {1'b0}}, 1'b1};
	wire [ROB_ID_WIDTH - 1:0] tail_next = tail + {{ROB_ID_WIDTH - 1 {1'b0}}, 1'b1};
	wire dispatch_two = disp0_valid && disp1_valid;
	wire dispatch_one = disp0_valid ^ disp1_valid;
	wire commit0_fire;
	wire commit1_fire;
	wire [ROB_ID_WIDTH:0] dispatch_num = dispatch_two ? {{ROB_ID_WIDTH - 1 {1'b0}}, 2'd2} : (dispatch_one ? {{ROB_ID_WIDTH {1'b0}}, 1'b1} : {ROB_ID_WIDTH + 1 {1'b0}});
	wire [ROB_ID_WIDTH:0] commit_num = commit1_fire ? {{ROB_ID_WIDTH - 1 {1'b0}}, 2'd2} : (commit0_fire ? {{ROB_ID_WIDTH {1'b0}}, 1'b1} : {ROB_ID_WIDTH + 1 {1'b0}});

	assign disp0_id = tail;
	assign disp1_id = tail_next;
	assign alloc_ready = count <= (ROB_SIZE - 2);
	assign commit0_fire = valid[head] && ready[head];
	assign commit1_fire = commit0_fire && valid[head_next] && ready[head_next] && !have_excp[head];
	assign commit0_valid = commit0_fire;
	assign commit0_id = head;
	assign commit0_pc = pc[head];
	assign commit0_dest = dest[head];
	assign commit0_has_dest = has_dest[head];
	assign commit0_value = value[head];
	assign commit0_br_type = br_type[head];
	assign commit0_br_taken = br_taken[head];
	assign commit0_have_excp = have_excp[head];
	assign commit0_excp_type = excp_type[head];
	assign commit0_excp_addr = excp_addr[head];
	assign commit1_valid = commit1_fire;
	assign commit1_id = head_next;
	assign commit1_pc = pc[head_next];
	assign commit1_dest = dest[head_next];
	assign commit1_has_dest = has_dest[head_next];
	assign commit1_value = value[head_next];
	assign commit1_br_type = br_type[head_next];
	assign commit1_br_taken = br_taken[head_next];
	assign commit1_have_excp = have_excp[head_next];
	assign commit1_excp_type = excp_type[head_next];
	assign commit1_excp_addr = excp_addr[head_next];

	integer i;
	always @(posedge clk) begin
		if (reset || flush) begin
			head <= 0;
			tail <= 0;
			count <= 0;
			for (i = 0; i < ROB_SIZE; i = i + 1) begin
				valid[i] <= 1'b0;
				ready[i] <= 1'b0;
			end
		end
		else begin
			if (disp0_valid) begin
				valid[tail] <= 1'b1;
				ready[tail] <= disp0_have_excp;
				pc[tail] <= disp0_pc;
				dest[tail] <= disp0_dest;
				has_dest[tail] <= disp0_has_dest;
				value[tail] <= 32'd0;
				br_type[tail] <= disp0_br_type;
				br_taken[tail] <= 1'b0;
				have_excp[tail] <= disp0_have_excp;
				excp_type[tail] <= disp0_excp_type;
				excp_addr[tail] <= disp0_excp_addr;
			end
			if (disp1_valid) begin
				valid[tail_next] <= 1'b1;
				ready[tail_next] <= disp1_have_excp;
				pc[tail_next] <= disp1_pc;
				dest[tail_next] <= disp1_dest;
				has_dest[tail_next] <= disp1_has_dest;
				value[tail_next] <= 32'd0;
				br_type[tail_next] <= disp1_br_type;
				br_taken[tail_next] <= 1'b0;
				have_excp[tail_next] <= disp1_have_excp;
				excp_type[tail_next] <= disp1_excp_type;
				excp_addr[tail_next] <= disp1_excp_addr;
			end
			if (complete0_valid) begin
				ready[complete0_id] <= 1'b1;
				value[complete0_id] <= complete0_value;
				br_taken[complete0_id] <= complete0_br_taken;
				have_excp[complete0_id] <= complete0_have_excp;
				excp_type[complete0_id] <= complete0_excp_type;
				excp_addr[complete0_id] <= complete0_excp_addr;
			end
			if (complete1_valid) begin
				ready[complete1_id] <= 1'b1;
				value[complete1_id] <= complete1_value;
				br_taken[complete1_id] <= complete1_br_taken;
				have_excp[complete1_id] <= complete1_have_excp;
				excp_type[complete1_id] <= complete1_excp_type;
				excp_addr[complete1_id] <= complete1_excp_addr;
			end
			if (commit0_fire)
				valid[head] <= 1'b0;
			if (commit1_fire)
				valid[head_next] <= 1'b0;
			head <= head + commit_num[ROB_ID_WIDTH - 1:0];
			tail <= tail + dispatch_num[ROB_ID_WIDTH - 1:0];
			count <= count + dispatch_num - commit_num;
		end
	end
endmodule
