module ooo_rat #(
	parameter ROB_ID_WIDTH = 4
) (
	clk,
	reset,
	flush,
	query0_r1,
	query0_r2,
	query1_r1,
	query1_r2,
	disp0_valid,
	disp0_dest,
	disp0_has_dest,
	disp0_id,
	disp1_valid,
	disp1_dest,
	disp1_has_dest,
	disp1_id,
	dispatch_accept,
	src0_r1_pending,
	src0_r1_tag,
	src0_r2_pending,
	src0_r2_tag,
	src1_r1_pending,
	src1_r1_tag,
	src1_r2_pending,
	src1_r2_tag,
	commit0_valid,
	commit0_dest,
	commit0_has_dest,
	commit0_id,
	commit1_valid,
	commit1_dest,
	commit1_has_dest,
	commit1_id
);
	input clk;
	input reset;
	input flush;
	input [4:0] query0_r1;
	input [4:0] query0_r2;
	input [4:0] query1_r1;
	input [4:0] query1_r2;
	input disp0_valid;
	input [4:0] disp0_dest;
	input disp0_has_dest;
	input [ROB_ID_WIDTH - 1:0] disp0_id;
	input disp1_valid;
	input [4:0] disp1_dest;
	input disp1_has_dest;
	input [ROB_ID_WIDTH - 1:0] disp1_id;
	input dispatch_accept;
	output wire src0_r1_pending;
	output wire [ROB_ID_WIDTH - 1:0] src0_r1_tag;
	output wire src0_r2_pending;
	output wire [ROB_ID_WIDTH - 1:0] src0_r2_tag;
	output wire src1_r1_pending;
	output wire [ROB_ID_WIDTH - 1:0] src1_r1_tag;
	output wire src1_r2_pending;
	output wire [ROB_ID_WIDTH - 1:0] src1_r2_tag;
	input commit0_valid;
	input [4:0] commit0_dest;
	input commit0_has_dest;
	input [ROB_ID_WIDTH - 1:0] commit0_id;
	input commit1_valid;
	input [4:0] commit1_dest;
	input commit1_has_dest;
	input [ROB_ID_WIDTH - 1:0] commit1_id;

	reg map_valid [0:31];
	reg [ROB_ID_WIDTH - 1:0] map_tag [0:31];
	wire disp0_writes = disp0_valid && disp0_has_dest && (disp0_dest != 5'd0);
	wire disp1_writes = disp1_valid && disp1_has_dest && (disp1_dest != 5'd0);
	wire commit0_writes = commit0_valid && commit0_has_dest && (commit0_dest != 5'd0);
	wire commit1_writes = commit1_valid && commit1_has_dest && (commit1_dest != 5'd0);

	assign src0_r1_pending = (query0_r1 != 5'd0) && map_valid[query0_r1];
	assign src0_r1_tag = map_tag[query0_r1];
	assign src0_r2_pending = (query0_r2 != 5'd0) && map_valid[query0_r2];
	assign src0_r2_tag = map_tag[query0_r2];
	assign src1_r1_pending = (query1_r1 != 5'd0) && ((disp0_writes && (disp0_dest == query1_r1)) || map_valid[query1_r1]);
	assign src1_r1_tag = (disp0_writes && (disp0_dest == query1_r1)) ? disp0_id : map_tag[query1_r1];
	assign src1_r2_pending = (query1_r2 != 5'd0) && ((disp0_writes && (disp0_dest == query1_r2)) || map_valid[query1_r2]);
	assign src1_r2_tag = (disp0_writes && (disp0_dest == query1_r2)) ? disp0_id : map_tag[query1_r2];

	integer i;
	always @(posedge clk) begin
		if (reset || flush) begin
			for (i = 0; i < 32; i = i + 1) begin
				map_valid[i] <= 1'b0;
				map_tag[i] <= {ROB_ID_WIDTH {1'b0}};
			end
		end
		else begin
			if (commit0_writes && map_valid[commit0_dest] && (map_tag[commit0_dest] == commit0_id))
				map_valid[commit0_dest] <= 1'b0;
			if (commit1_writes && map_valid[commit1_dest] && (map_tag[commit1_dest] == commit1_id))
				map_valid[commit1_dest] <= 1'b0;
			if (dispatch_accept && disp0_writes) begin
				map_valid[disp0_dest] <= 1'b1;
				map_tag[disp0_dest] <= disp0_id;
			end
			if (dispatch_accept && disp1_writes) begin
				map_valid[disp1_dest] <= 1'b1;
				map_tag[disp1_dest] <= disp1_id;
			end
		end
	end
endmodule
