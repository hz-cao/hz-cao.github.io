module axi_bridge (
	clk,
	reset,
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
	inst_rd_req,
	inst_rd_type,
	inst_rd_addr,
	inst_rd_rdy,
	inst_ret_valid,
	inst_ret_last,
	inst_ret_data,
	inst_wr_req,
	inst_wr_type,
	inst_wr_addr,
	inst_wr_wstrb,
	inst_wr_data,
	inst_wr_rdy,
	data_rd_req,
	data_rd_type,
	data_rd_addr,
	data_rd_rdy,
	data_ret_valid,
	data_ret_last,
	data_ret_data,
	data_wr_req,
	data_wr_type,
	data_wr_addr,
	data_wr_wstrb,
	data_wr_data,
	data_wr_rdy,
	write_buffer_empty
);
	input wire clk;
	input wire reset;
	output reg [3:0] arid;
	output reg [31:0] araddr;
	output reg [7:0] arlen;
	output reg [2:0] arsize;
	output wire [1:0] arburst;
	output wire [1:0] arlock;
	output wire [3:0] arcache;
	output wire [2:0] arprot;
	output reg arvalid;
	input wire arready;
	input wire [3:0] rid;
	input wire [31:0] rdata;
	input wire [1:0] rresp;
	input wire rlast;
	input wire rvalid;
	output reg rready;
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
	output reg wvalid;
	input wire wready;
	input wire [3:0] bid;
	input wire [1:0] bresp;
	input wire bvalid;
	output reg bready;
	input wire inst_rd_req;
	input wire [2:0] inst_rd_type;
	input wire [31:0] inst_rd_addr;
	output wire inst_rd_rdy;
	output wire inst_ret_valid;
	output wire inst_ret_last;
	output wire [31:0] inst_ret_data;
	input wire inst_wr_req;
	input wire [2:0] inst_wr_type;
	input wire [31:0] inst_wr_addr;
	input wire [3:0] inst_wr_wstrb;
	input wire [255:0] inst_wr_data;
	output wire inst_wr_rdy;
	input wire data_rd_req;
	input wire [2:0] data_rd_type;
	input wire [31:0] data_rd_addr;
	output wire data_rd_rdy;
	output wire data_ret_valid;
	output wire data_ret_last;
	output wire [31:0] data_ret_data;
	input wire data_wr_req;
	input wire [2:0] data_wr_type;
	input wire [31:0] data_wr_addr;
	input wire [3:0] data_wr_wstrb;
	input wire [255:0] data_wr_data;
	output wire data_wr_rdy;
	output wire write_buffer_empty;
	assign arlock = 2'b00;
	assign arcache = 4'b0000;
	assign arprot = 3'b000;
	assign awid = 4'b0001;
	assign awburst = 2'b01;
	assign awlock = 2'b00;
	assign awcache = 4'b0000;
	assign awprot = 3'b000;
	assign wid = 4'b0001;
	assign inst_wr_rdy = 1'b1;
	parameter RD_REQ_ST_IDLE = 1'b0;
	parameter RD_REQ_ST_RDY = 1'b1;
	parameter RD_RES_ST_IDLE = 1'b0;
	parameter RD_RES_ST_RX = 1'b1;
	parameter WR_ST_TX_WAIT = 0;
	parameter WR_ST_TX = 1;
	parameter WR_ST_WAIT_B = 2;
	reg read_requst_state;
	reg read_respond_state;
	reg [2:0] write_state;
	wire write_wait_enable;
	wire rd_requst_state_is_empty;
	wire rd_requst_can_receive;
	wire data_rd_cache_line;
	wire inst_rd_cache_line;
	assign arburst = (inst_rd_cache_line | data_rd_cache_line ? 2'b10 : 2'b01);
	assign rd_requst_state_is_empty = read_requst_state == RD_REQ_ST_IDLE;
	wire [2:0] data_real_rd_size;
	wire [7:0] data_real_rd_len;
	wire [2:0] inst_real_rd_size;
	wire [7:0] inst_real_rd_len;
	wire data_wr_cache_line;
	wire [2:0] data_real_wr_size;
	wire [7:0] data_real_wr_len;
	reg [255:0] write_buffer_data;
	reg [2:0] write_countdown_reg;
	wire write_buffer_last;
	assign write_buffer_empty = (write_countdown_reg == {3 {1'b0}}) & !write_wait_enable;
	wire write_queue_last;
	assign rd_requst_can_receive = rd_requst_state_is_empty & (!write_wait_enable | ((bvalid & bready) & write_queue_last));
	assign data_rd_rdy = rd_requst_can_receive;
	assign inst_rd_rdy = !data_rd_req & rd_requst_can_receive;
	assign data_rd_cache_line = data_rd_type == 3'b100;
	assign data_real_rd_size = (data_rd_cache_line ? 3'b010 : data_rd_type);
	assign data_real_rd_len = (data_rd_cache_line ? 7 : 8'b00000000);
	assign inst_rd_cache_line = inst_rd_type == 3'b100;
	assign inst_real_rd_size = (inst_rd_cache_line ? 3'b010 : inst_rd_type);
	assign inst_real_rd_len = (inst_rd_cache_line ? 7 : 8'b00000000);
	assign data_wr_cache_line = data_wr_type == 3'b100;
	assign data_real_wr_size = (data_wr_cache_line ? 3'b010 : data_wr_type);
	assign data_real_wr_len = (data_wr_cache_line ? 7 : 8'b00000000);
	assign inst_ret_valid = !rid[0] & rvalid;
	assign inst_ret_last = !rid[0] & rlast;
	assign inst_ret_data = rdata;
	assign data_ret_valid = rid[0] & rvalid;
	assign data_ret_last = rid[0] & rlast;
	assign data_ret_data = rdata;
	assign write_buffer_last = write_countdown_reg == 0;
	always @(posedge clk)
		if (reset) begin
			read_requst_state <= RD_REQ_ST_IDLE;
			arvalid <= 1'b0;
		end
		else
			case (read_requst_state)
				RD_REQ_ST_IDLE:
					if (data_rd_req) begin
						if (write_wait_enable) begin
							if (((bid[0] & bvalid) & bready) & write_queue_last) begin
								read_requst_state <= RD_REQ_ST_RDY;
								arid <= 4'b0001;
								araddr <= data_rd_addr;
								arsize <= data_real_rd_size;
								arlen <= data_real_rd_len;
								arvalid <= 1'b1;
							end
						end
						else begin
							read_requst_state <= RD_REQ_ST_RDY;
							arid <= 4'b0001;
							araddr <= data_rd_addr;
							arsize <= data_real_rd_size;
							arlen <= data_real_rd_len;
							arvalid <= 1'b1;
						end
					end
					else if (inst_rd_req) begin
						if (write_wait_enable) begin
							if (((bid[0] & bvalid) & bready) & write_queue_last) begin
								read_requst_state <= RD_REQ_ST_RDY;
								arid <= 4'b0000;
								araddr <= inst_rd_addr;
								arsize <= inst_real_rd_size;
								arlen <= inst_real_rd_len;
								arvalid <= 1'b1;
							end
						end
						else begin
							read_requst_state <= RD_REQ_ST_RDY;
							arid <= 4'b0000;
							araddr <= inst_rd_addr;
							arsize <= inst_real_rd_size;
							arlen <= inst_real_rd_len;
							arvalid <= 1'b1;
						end
					end
				RD_REQ_ST_RDY:
					if (arready & arid[0]) begin
						read_requst_state <= RD_REQ_ST_IDLE;
						arvalid <= 1'b0;
					end
					else if (arready & !arid[0]) begin
						read_requst_state <= RD_REQ_ST_IDLE;
						arvalid <= 1'b0;
					end
			endcase
	always @(posedge clk)
		if (reset) begin
			read_respond_state <= RD_RES_ST_IDLE;
			rready <= 1'b1;
		end
		else
			case (read_respond_state)
				RD_RES_ST_IDLE:
					if (rvalid & rready)
						read_respond_state <= RD_RES_ST_RX;
				RD_RES_ST_RX:
					if (rlast & rvalid)
						read_respond_state <= RD_RES_ST_IDLE;
			endcase
	reg [255:0] write_queue_data [3:0];
	reg [3:0] write_queue_wstrb [3:0];
	reg [2:0] write_queue_type [3:0];
	reg [31:0] write_queue_addr [3:0];
	reg [7:0] write_queue_len [3:0];
	reg [2:0] write_queue_size [3:0];
	reg [1:0] write_queue_head;
	reg [1:0] write_queue_tail;
	wire [1:0] write_queue_tail_plus_1;
	wire [1:0] write_queue_head_plus_1;
	wire write_queue_empty;
	wire write_queue_full;
	assign write_queue_tail_plus_1 = write_queue_tail + 1;
	assign write_queue_head_plus_1 = write_queue_head + 1;
	assign write_queue_empty = write_queue_head == write_queue_tail;
	assign write_queue_full = write_queue_head == write_queue_tail_plus_1;
	assign write_queue_last = write_queue_tail == write_queue_head_plus_1;
	assign data_wr_rdy = ~write_queue_full;
	wire [2:0] wtype;
	wire [255:0] write_queue_data_line;
	assign write_queue_data_line = write_queue_data[write_queue_head];
	assign wdata = write_queue_data_line[31:0];
	assign wstrb = write_queue_wstrb[write_queue_head];
	assign wtype = write_queue_type[write_queue_head];
	assign awaddr = write_queue_addr[write_queue_head];
	assign awsize = write_queue_size[write_queue_head];
	assign awlen = write_queue_len[write_queue_head];
	assign awvalid = !write_queue_empty & (write_state == WR_ST_TX_WAIT);
	assign wlast = write_buffer_last & (write_state == WR_ST_TX);
	always @(posedge clk) begin
		if (reset) begin
			write_state <= WR_ST_TX_WAIT;
			write_countdown_reg <= 0;
			write_buffer_data <= 0;
			write_queue_head <= 0;
			write_queue_tail <= 0;
		end
		else if (!write_queue_full & data_wr_req) begin
			write_queue_data[write_queue_tail] <= data_wr_data;
			write_queue_wstrb[write_queue_tail] <= data_wr_wstrb;
			write_queue_type[write_queue_tail] <= data_wr_type;
			write_queue_addr[write_queue_tail] <= data_wr_addr;
			write_queue_len[write_queue_tail] <= data_real_wr_len;
			write_queue_size[write_queue_tail] <= data_real_wr_size;
			write_queue_tail <= write_queue_tail + 1;
		end
		case (write_state)
			WR_ST_TX_WAIT: begin
				if (awready & !write_queue_empty) begin
					write_state <= WR_ST_TX;
					wvalid <= 1'b1;
				end
				if (wtype == 3'b100)
					write_countdown_reg <= {3 {1'b1}};
				else
					write_countdown_reg <= 0;
			end
			WR_ST_TX:
				if (wready) begin
					if (wlast) begin
						write_state <= WR_ST_WAIT_B;
						wvalid <= 1'b0;
						bready <= 1'b1;
					end
					else begin
						write_state <= WR_ST_TX;
						wvalid <= 1'b1;
						write_queue_data[write_queue_head] <= {32'b00000000000000000000000000000000, write_queue_data_line[255:32]};
						write_countdown_reg <= write_countdown_reg - 1;
					end
				end
			WR_ST_WAIT_B:
				if ((bid[0] & bvalid) & bready) begin
					write_state <= WR_ST_TX_WAIT;
					bready <= 1'b0;
					write_queue_head <= write_queue_head + 1;
				end
			default: write_state <= WR_ST_TX_WAIT;
		endcase
	end
	assign write_wait_enable = !write_queue_empty;
endmodule
