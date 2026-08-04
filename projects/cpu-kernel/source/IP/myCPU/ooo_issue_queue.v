module ooo_issue_queue #(
	parameter IQ_SIZE = 8,
	parameter IQ_ID_WIDTH = 3,
	parameter ROB_ID_WIDTH = 4
) (
	clk,
	reset,
	flush,
	dispatch0_valid,
	dispatch0_payload,
	dispatch0_src1_ready,
	dispatch0_src1_value,
	dispatch0_src1_tag,
	dispatch0_src2_ready,
	dispatch0_src2_value,
	dispatch0_src2_tag,
	dispatch1_valid,
	dispatch1_payload,
	dispatch1_src1_ready,
	dispatch1_src1_value,
	dispatch1_src1_tag,
	dispatch1_src2_ready,
	dispatch1_src2_value,
	dispatch1_src2_tag,
	dispatch_ready,
	wakeup0_valid,
	wakeup0_tag,
	wakeup0_value,
	wakeup1_valid,
	wakeup1_tag,
	wakeup1_value,
	issue0_allow,
	issue0_valid,
	issue0_payload,
	issue0_src1_value,
	issue0_src2_value,
	issue1_allow,
	issue1_valid,
	issue1_payload,
	issue1_src1_value,
	issue1_src2_value
);
	input clk;
	input reset;
	input flush;
	input dispatch0_valid;
	input [193:0] dispatch0_payload;
	input dispatch0_src1_ready;
	input [31:0] dispatch0_src1_value;
	input [ROB_ID_WIDTH - 1:0] dispatch0_src1_tag;
	input dispatch0_src2_ready;
	input [31:0] dispatch0_src2_value;
	input [ROB_ID_WIDTH - 1:0] dispatch0_src2_tag;
	input dispatch1_valid;
	input [193:0] dispatch1_payload;
	input dispatch1_src1_ready;
	input [31:0] dispatch1_src1_value;
	input [ROB_ID_WIDTH - 1:0] dispatch1_src1_tag;
	input dispatch1_src2_ready;
	input [31:0] dispatch1_src2_value;
	input [ROB_ID_WIDTH - 1:0] dispatch1_src2_tag;
	output wire dispatch_ready;
	input wakeup0_valid;
	input [ROB_ID_WIDTH - 1:0] wakeup0_tag;
	input [31:0] wakeup0_value;
	input wakeup1_valid;
	input [ROB_ID_WIDTH - 1:0] wakeup1_tag;
	input [31:0] wakeup1_value;
	input issue0_allow;
	output wire issue0_valid;
	output wire [193:0] issue0_payload;
	output wire [31:0] issue0_src1_value;
	output wire [31:0] issue0_src2_value;
	input issue1_allow;
	output wire issue1_valid;
	output wire [193:0] issue1_payload;
	output wire [31:0] issue1_src1_value;
	output wire [31:0] issue1_src2_value;

	reg valid [0:IQ_SIZE - 1];
	reg [193:0] payload [0:IQ_SIZE - 1];
	reg src1_ready [0:IQ_SIZE - 1];
	reg [31:0] src1_value [0:IQ_SIZE - 1];
	reg [ROB_ID_WIDTH - 1:0] src1_tag [0:IQ_SIZE - 1];
	reg src2_ready [0:IQ_SIZE - 1];
	reg [31:0] src2_value [0:IQ_SIZE - 1];
	reg [ROB_ID_WIDTH - 1:0] src2_tag [0:IQ_SIZE - 1];

	reg [IQ_ID_WIDTH - 1:0] free0_idx;
	reg [IQ_ID_WIDTH - 1:0] free1_idx;
	reg free0_found;
	reg free1_found;
	reg [IQ_ID_WIDTH - 1:0] issue0_idx;
	reg [IQ_ID_WIDTH - 1:0] issue1_idx;
	reg issue0_found;
	reg issue1_found;
	wire issue0_fire = issue0_allow && issue0_found;
	wire issue1_fire = issue1_allow && issue1_found;

	assign dispatch_ready = dispatch1_valid ? (free0_found && free1_found) : (!dispatch0_valid || free0_found);
	assign issue0_valid = issue0_found;
	assign issue0_payload = payload[issue0_idx];
	assign issue0_src1_value = src1_value[issue0_idx];
	assign issue0_src2_value = src2_value[issue0_idx];
	assign issue1_valid = issue1_found;
	assign issue1_payload = payload[issue1_idx];
	assign issue1_src1_value = src1_value[issue1_idx];
	assign issue1_src2_value = src2_value[issue1_idx];

	integer i;
	always @(*) begin
		free0_idx = 0;
		free1_idx = 0;
		free0_found = 1'b0;
		free1_found = 1'b0;
		for (i = 0; i < IQ_SIZE; i = i + 1) begin
			if (!valid[i] && !free0_found) begin
				free0_found = 1'b1;
				free0_idx = i[IQ_ID_WIDTH - 1:0];
			end
			else if (!valid[i] && !free1_found) begin
				free1_found = 1'b1;
				free1_idx = i[IQ_ID_WIDTH - 1:0];
			end
		end
	end

	always @(*) begin
		issue0_idx = 0;
		issue1_idx = 0;
		issue0_found = 1'b0;
		issue1_found = 1'b0;
		for (i = 0; i < IQ_SIZE; i = i + 1) begin
			if (valid[i] && src1_ready[i] && src2_ready[i] && !issue0_found) begin
				issue0_found = 1'b1;
				issue0_idx = i[IQ_ID_WIDTH - 1:0];
			end
			else if (valid[i] && src1_ready[i] && src2_ready[i] && !issue1_found) begin
				issue1_found = 1'b1;
				issue1_idx = i[IQ_ID_WIDTH - 1:0];
			end
		end
	end

	always @(posedge clk) begin
		if (reset || flush) begin
			for (i = 0; i < IQ_SIZE; i = i + 1)
				valid[i] <= 1'b0;
		end
		else begin
			for (i = 0; i < IQ_SIZE; i = i + 1) begin
				if (valid[i] && !src1_ready[i]) begin
					if (wakeup0_valid && (wakeup0_tag == src1_tag[i])) begin
						src1_ready[i] <= 1'b1;
						src1_value[i] <= wakeup0_value;
					end
					else if (wakeup1_valid && (wakeup1_tag == src1_tag[i])) begin
						src1_ready[i] <= 1'b1;
						src1_value[i] <= wakeup1_value;
					end
				end
				if (valid[i] && !src2_ready[i]) begin
					if (wakeup0_valid && (wakeup0_tag == src2_tag[i])) begin
						src2_ready[i] <= 1'b1;
						src2_value[i] <= wakeup0_value;
					end
					else if (wakeup1_valid && (wakeup1_tag == src2_tag[i])) begin
						src2_ready[i] <= 1'b1;
						src2_value[i] <= wakeup1_value;
					end
				end
			end
			if (issue0_fire)
				valid[issue0_idx] <= 1'b0;
			if (issue1_fire)
				valid[issue1_idx] <= 1'b0;
			if (dispatch0_valid && dispatch_ready) begin
				valid[free0_idx] <= 1'b1;
				payload[free0_idx] <= dispatch0_payload;
				src1_ready[free0_idx] <= dispatch0_src1_ready;
				src1_value[free0_idx] <= dispatch0_src1_value;
				src1_tag[free0_idx] <= dispatch0_src1_tag;
				src2_ready[free0_idx] <= dispatch0_src2_ready;
				src2_value[free0_idx] <= dispatch0_src2_value;
				src2_tag[free0_idx] <= dispatch0_src2_tag;
			end
			if (dispatch1_valid && dispatch_ready) begin
				valid[free1_idx] <= 1'b1;
				payload[free1_idx] <= dispatch1_payload;
				src1_ready[free1_idx] <= dispatch1_src1_ready;
				src1_value[free1_idx] <= dispatch1_src1_value;
				src1_tag[free1_idx] <= dispatch1_src1_tag;
				src2_ready[free1_idx] <= dispatch1_src2_ready;
				src2_value[free1_idx] <= dispatch1_src2_value;
				src2_tag[free1_idx] <= dispatch1_src2_tag;
			end
		end
	end
endmodule
