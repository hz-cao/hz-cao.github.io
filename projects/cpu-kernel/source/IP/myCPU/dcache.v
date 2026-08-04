module dcache (
	clk,
	resetn,
	valid,
	op,
	tag,
	index,
	offset,
	wstrb,
	wdata,
	uncached,
	size,
	addr_ok,
	data_ok,
	rdata,
	rd_req,
	rd_type,
	rd_addr,
	rd_rdy,
	ret_valid,
	ret_last,
	ret_data,
	wr_req,
	wr_type,
	wr_addr,
	wr_wstrb,
	wr_data,
	wr_rdy
);
	input wire clk;
	input wire resetn;
	input wire valid;
	input wire [2:0] op;
	input wire [19:0] tag;
	input wire [6:0] index;
	input wire [4:0] offset;
	input wire [3:0] wstrb;
	input wire [31:0] wdata;
	input wire uncached;
	input wire [1:0] size;
	output wire addr_ok;
	output wire data_ok;
	output wire [31:0] rdata;
	output wire rd_req;
	output wire [2:0] rd_type;
	output wire [31:0] rd_addr;
	input wire rd_rdy;
	input wire ret_valid;
	input wire ret_last;
	input wire [31:0] ret_data;
	output wire wr_req;
	output wire [2:0] wr_type;
	output wire [31:0] wr_addr;
	output wire [3:0] wr_wstrb;
	output wire [255:0] wr_data;
	input wire wr_rdy;
	wire [255:0] data_way0;
	wire [255:0] data_way1;
	wire [6:0] data_addr;
	wire cache_rdy;
	reg [2:0] op_reg;
	wire cacop;
	wire cacop_reg;
	wire [1:0] cacop_id_reg;
	wire cacop_iiw_reg;
	wire [0:0] cacop_way_id;
	reg [6:0] index_reg;
	reg [6:0] index_reg_miss;
	reg [19:0] tag_reg;
	reg [4:0] offset_reg;
	reg [4:0] offset_reg_miss;
	wire [4:0] offset_cell_w;
	wire [2:0] offset_w_reg;
	reg [2:0] offset_w_last_reg;
	reg uncached_reg;
	reg [1:0] size_reg;
	reg [3:0] wstrb_reg;
	reg [31:0] wdata_reg;
	reg wdata_ok_reg;
	reg [19:0] tag_way0 [0:127];
	reg [19:0] tag_way1 [0:127];
	(* keep = "true" *) reg [19:0] preload_tag_way0;
	(* keep = "true" *) reg [19:0] preload_tag_way1;
	reg [127:0] valid_way0;
	reg [127:0] valid_way1;
	reg [127:0] dirty_way0;
	reg [127:0] dirty_way1;
	reg [2:0] main_state;
	parameter OP_READ = 3'b000;
	parameter OP_WRITE = 3'b001;
	parameter OP_CACOP0 = 3'b100;
	parameter OP_CACOP1 = 3'b101;
	parameter OP_CACOP2 = 3'b110;
	parameter OP_CACOP3 = 3'b111;
	parameter RD_TYPE_CACHELINE = 3'b100;
	parameter WR_TYPE_CACHELINE = 3'b100;
	parameter MAIN_ST_IDLE = 0;
	parameter MAIN_ST_LOOKUP = 1;
	parameter MAIN_ST_MISS = 2;
	parameter MAIN_ST_REPLACE = 3;
	parameter MAIN_ST_REFILL = 4;
	parameter MAIN_ST_CACOP12 = 5;
	parameter SUB_ST_IDLE = 0;
	parameter SUB_ST_WRITE = 1;
	wire [2:0] rd_type_cache;
	wire [31:0] rd_addr_cache;
	wire rd_req_cache;
	reg wr_addr_ok;
	reg rd_addr_ok;
	wire ret_valid_last;
	reg finished;
	wire idle;
	wire lookup;
	wire miss;
	wire replace;
	wire refill;
	wire cacop12;
	wire hit_write;
	wire refill_write;
	wire cache_write;
	wire cacop0_write;
	wire cacop1_write;
	wire cacop2_write;
	wire cache_hit;
	wire cache_hit_and_cached;
	wire [1:0] cache_hit_way;
	wire [0:0] cache_hit_way_id;
	wire pipe_interface_latch;
	wire [255:0] buffer_read_data_new;
	wire [255:0] cache_rd_data;
	reg [255:0] buffer_read_data;
	reg [3:0] buffer_read_data_count;
	reg [3:0] buffer_read_data_count_start;
	reg [19:0] replace_tag;
	reg [0:0] replace_way_id_counter;
	wire [0:0] replace_way_id;
	wire replace_dirty;
	reg [255:0] cache_write_data_reg;
	wire [255:0] cache_write_data_actually;
	reg [31:0] cache_wstrb_reg;
	wire [0:0] cache_write_way_id;
	wire [255:0] cache_write_data_strobe;
	wire next_same_line;
	assign cacop = op[2];
	assign cacop_reg = op_reg[2];
	assign cacop_id_reg = op_reg[1:0];
	assign cacop_iiw_reg = cacop_reg & (cacop_id_reg[0] ^ cacop_id_reg[1]);
	assign cacop_way_id = (op_reg == OP_CACOP2 ? cache_hit_way_id : offset_reg[0:0]);
	assign data_addr = (pipe_interface_latch ? index : index_reg);
	assign cache_write_data_strobe = {{224 {1'b0}}, {8 {wstrb[3]}}, {8 {wstrb[2]}}, {8 {wstrb[1]}}, {8 {wstrb[0]}}} << (offset_cell_w * 8);
	assign offset_cell_w = {offset[4:2], 2'b00};
	assign offset_w_reg = offset_reg[4:2];
	assign idle = main_state == MAIN_ST_IDLE;
	assign lookup = main_state == MAIN_ST_LOOKUP;
	assign miss = main_state == MAIN_ST_MISS;
	assign replace = main_state == MAIN_ST_REPLACE;
	assign refill = main_state == MAIN_ST_REFILL;
	assign cacop12 = main_state == MAIN_ST_CACOP12;
	assign ret_valid_last = ret_valid & ret_last;
	assign next_same_line = (index == index_reg) & (tag == tag_reg);
	assign addr_ok = cache_rdy;
	assign pipe_interface_latch = valid & cache_rdy;
	assign cache_rdy = idle | ((lookup & (op_reg == OP_READ)) & cache_hit_and_cached);
	assign replace_dirty = (({replace_way_id == 0} & valid_way0[index_reg_miss]) | ({replace_way_id == 1} & valid_way1[index_reg_miss])) & (({replace_way_id == 0} & dirty_way0[index_reg_miss]) | ({replace_way_id == 1} & dirty_way1[index_reg_miss]));
	always @(posedge clk)
		if (!resetn)
			finished <= 1;
		else if (pipe_interface_latch)
			finished <= 0;
		else if (!pipe_interface_latch & data_ok)
			finished <= 1;
	always @(posedge clk)
		if (!resetn) begin
			cache_wstrb_reg <= 0;
			cache_write_data_reg <= 0;
		end
		else begin
			if (pipe_interface_latch) begin
				op_reg <= op;
				index_reg <= index;
				tag_reg <= tag;
				offset_reg <= offset;
				offset_w_last_reg <= offset[4:2];
				uncached_reg <= uncached & !cacop;
				size_reg <= size;
				wstrb_reg <= wstrb;
				wdata_reg <= wdata;
				if (!uncached & (op == OP_WRITE)) begin
					cache_wstrb_reg <= cache_wstrb_reg | ({{28 {1'b0}}, wstrb} << offset_cell_w);
					cache_write_data_reg <= (cache_write_data_reg & ~cache_write_data_strobe) | (({{224 {1'b0}}, wdata} << (offset_cell_w * 8)) & cache_write_data_strobe);
				end
			end
			else if (refill_write | hit_write) begin
				cache_wstrb_reg <= 0;
				cache_write_data_reg <= 0;
			end
			if (lookup) begin
				index_reg_miss <= index_reg;
				offset_reg_miss <= offset_reg;
			end
		end
	always @(posedge clk) wdata_ok_reg <= (op == OP_WRITE) & pipe_interface_latch;
	assign hit_write = (lookup & cache_hit_and_cached) & (op_reg == OP_WRITE);
	assign cacop0_write = lookup & (op_reg == OP_CACOP0);
	always @(posedge clk)
		if (!resetn) begin
			preload_tag_way0 <= 0;
			preload_tag_way1 <= 0;
		end
		else if ((idle | lookup) & pipe_interface_latch) begin
			preload_tag_way0 <= tag_way0[index];
			preload_tag_way1 <= tag_way1[index];
		end
	always @(posedge clk)
		if (!resetn) begin
			main_state <= 0;
			replace_way_id_counter <= 0;
		end
		else
			case (main_state)
				MAIN_ST_IDLE:
					if (pipe_interface_latch)
						main_state <= MAIN_ST_LOOKUP;
				MAIN_ST_LOOKUP:
					if (((!cacop_reg & cache_hit_and_cached) | (op_reg == OP_CACOP0)) | ((op_reg == OP_CACOP2) & !cache_hit_and_cached)) begin
						if (!pipe_interface_latch | hit_write)
							main_state <= MAIN_ST_IDLE;
					end
					else
						main_state <= MAIN_ST_MISS;
				MAIN_ST_MISS:
					if (uncached_reg) begin
						if ((op_reg == OP_READ) & rd_rdy)
							main_state <= MAIN_ST_REFILL;
						else if ((op_reg == OP_WRITE) & wr_rdy)
							main_state <= MAIN_ST_REPLACE;
					end
					else if (replace_dirty) begin
						if (wr_rdy)
							main_state <= MAIN_ST_REPLACE;
					end
					else if (cacop_iiw_reg)
						main_state <= MAIN_ST_CACOP12;
					else
						main_state <= MAIN_ST_REFILL;
				MAIN_ST_REPLACE:
					if (uncached_reg) begin
						if (wr_rdy)
							main_state <= MAIN_ST_IDLE;
					end
					else if (cacop_iiw_reg)
						main_state <= MAIN_ST_CACOP12;
					else if (rd_rdy)
						main_state <= MAIN_ST_REFILL;
				MAIN_ST_REFILL:
					if (ret_valid_last) begin
						main_state <= MAIN_ST_IDLE;
						replace_way_id_counter <= replace_way_id_counter + 1;
					end
				MAIN_ST_CACOP12: main_state <= MAIN_ST_IDLE;
			endcase
	genvar _genvar_i_1;
	generate
		for (_genvar_i_1 = 0; _genvar_i_1 < 2; _genvar_i_1 = _genvar_i_1 + 1) begin : gen_cache_hit_way
			localparam i = _genvar_i_1;
			assign cache_hit_way[i] = (({i == 0} & valid_way0[index_reg]) | ({i == 1} & valid_way1[index_reg])) & ((({20 {i == 0}} & preload_tag_way0) | ({20 {i == 1}} & preload_tag_way1)) == tag_reg);
		end
	endgenerate
	assign cache_hit = cache_hit_way != 0;
	assign cache_hit_and_cached = cache_hit & !uncached_reg;
	assign cache_hit_way_id = ({cache_hit_way[0]} & 0) | ({cache_hit_way[1]} & 1);
	assign cache_rd_data = (cache_hit ? ({256 {cache_hit_way_id == 0}} & data_way0) | ({256 {cache_hit_way_id == 1}} & data_way1) : (buffer_read_data_count[3] & (buffer_read_data_count[2:0] == buffer_read_data_count_start[2:0]) ? buffer_read_data : buffer_read_data_new));
	assign rdata = (uncached_reg ? ret_data : ((((((({32 {offset_w_reg == 0}} & cache_rd_data[31:0]) | ({32 {offset_w_reg == 1}} & cache_rd_data[63:32])) | ({32 {offset_w_reg == 2}} & cache_rd_data[95:64])) | ({32 {offset_w_reg == 3}} & cache_rd_data[127:96])) | ({32 {offset_w_reg == 4}} & cache_rd_data[159:128])) | ({32 {offset_w_reg == 5}} & cache_rd_data[191:160])) | ({32 {offset_w_reg == 6}} & cache_rd_data[223:192])) | ({32 {offset_w_reg == 7}} & cache_rd_data[255:224]));
	assign data_ok = (!cacop_reg & !finished) & (op_reg == OP_READ ? (lookup & cache_hit_and_cached) | (uncached_reg ? refill & ret_valid_last : (refill & ret_valid) & (buffer_read_data_count >= {offset_w_last_reg < buffer_read_data_count_start[2:0], offset_w_last_reg})) : wdata_ok_reg);
	always @(posedge clk)
		if (miss)
			replace_tag <= ({20 {replace_way_id == 0}} & preload_tag_way0) | ({20 {replace_way_id == 1}} & preload_tag_way1);
	assign replace_way_id = (cacop_reg ? cacop_way_id : replace_way_id_counter);
	assign wr_type = (uncached_reg ? {1'b0, size_reg} : WR_TYPE_CACHELINE);
	assign wr_addr = (uncached_reg ? {tag_reg, index_reg, offset_reg} : {replace_tag, index_reg_miss, {5 {1'b0}}});
	assign wr_data = (uncached_reg ? {{224 {1'b0}}, wdata_reg} : ({256 {replace_way_id == 0}} & data_way0) | ({256 {replace_way_id == 1}} & data_way1));
	assign wr_req = replace & ~wr_addr_ok;
	assign wr_wstrb = (uncached_reg ? wstrb_reg : 4'b1111);
	assign rd_type = (uncached_reg ? {1'b0, size_reg} : RD_TYPE_CACHELINE);
	assign rd_addr = (uncached_reg ? {tag_reg, index_reg, offset_reg} : {tag_reg, index_reg_miss, offset_reg_miss[4:2], 2'b00});
	assign rd_req = refill & ~rd_addr_ok;
	assign buffer_read_data_new = buffer_read_data | ({{224 {1'b0}}, ret_data} << (32 * buffer_read_data_count[2:0]));
	always @(posedge clk)
		if (!resetn) begin
			buffer_read_data <= 0;
			buffer_read_data_count <= 0;
		end
		else begin
			if ((!uncached_reg & refill) & ret_valid) begin
				buffer_read_data <= buffer_read_data_new;
				buffer_read_data_count <= buffer_read_data_count + 1;
			end
			if (rd_req) begin
				buffer_read_data <= 0;
				buffer_read_data_count <= {1'b0, rd_addr[4:2]};
				buffer_read_data_count_start <= {1'b0, rd_addr[4:2]};
			end
		end
	always @(posedge clk)
		if (!refill)
			rd_addr_ok <= 0;
		else if (refill & rd_rdy)
			rd_addr_ok <= 1;
	always @(posedge clk)
		if (!replace)
			wr_addr_ok <= 0;
		else if (replace & wr_rdy)
			wr_addr_ok <= 1;
	generate
		for (_genvar_i_1 = 0; _genvar_i_1 < 32; _genvar_i_1 = _genvar_i_1 + 1) begin : gen_refill_data
			localparam i = _genvar_i_1;
			assign cache_write_data_actually[(8 * i) + 7:8 * i] = (cache_wstrb_reg[i] ? cache_write_data_reg[(8 * i) + 7:8 * i] : cache_rd_data[(8 * i) + 7:8 * i]);
		end
	endgenerate
	assign cache_write_way_id = (hit_write ? cache_hit_way_id : replace_way_id);
	assign refill_write = (!uncached_reg & refill) & ret_valid_last;
	assign cacop1_write = cacop12 & (op_reg == OP_CACOP1);
	assign cacop2_write = cacop12 & (op_reg == OP_CACOP2);
	assign cache_write = hit_write | refill_write;
	always @(posedge clk)
		if (!resetn) begin : valid_tb_reset
			integer j;
			for (j = 0; j < 2; j = j + 1)
				begin
					valid_way0 <= 0;
					valid_way1 <= 0;
				end
		end
		else if (cache_write)
			case (cache_write_way_id)
				0: begin
					tag_way0[index_reg] <= tag_reg;
					valid_way0[index_reg] <= 1;
					dirty_way0[index_reg] <= op_reg == OP_WRITE;
				end
				1: begin
					tag_way1[index_reg] <= tag_reg;
					valid_way1[index_reg] <= 1;
					dirty_way1[index_reg] <= op_reg == OP_WRITE;
				end
			endcase
		else if ((cacop0_write | cacop1_write) | cacop2_write)
			case (cacop_way_id)
				0: valid_way0[index_reg] <= 0;
				1: valid_way1[index_reg] <= 0;
			endcase
	blk_mem_gen_cache_32 dcache_way0_ram(
		.addra(data_addr),
		.clka(clk),
		.dina(cache_write_data_actually),
		.douta(data_way0),
		.wea(cache_write & (cache_write_way_id == 0))
	);
	blk_mem_gen_cache_32 dcache_way1_ram(
		.addra(data_addr),
		.clka(clk),
		.dina(cache_write_data_actually),
		.douta(data_way1),
		.wea(cache_write & (cache_write_way_id == 1))
	);
endmodule
