module icache (
	clk,
	resetn,
	valid,
	op,
	tag,
	index,
	offset,
	uncached,
	addr_ok,
	data_ok,
	rdata_l,
	rdata_h,
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
	input wire uncached;
	output wire addr_ok;
	output wire data_ok;
	output wire [31:0] rdata_l;
	output wire [31:0] rdata_h;
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
	reg [2:0] op_reg;
	wire cacop;
	wire cacop_reg;
	wire [1:0] cacop_id_reg;
	wire [0:0] cacop_way_id;
	reg [6:0] index_reg;
	reg [6:0] index_reg_miss;
	reg [19:0] tag_reg;
	reg [4:0] offset_reg;
	reg [4:0] offset_reg_miss;
	wire [2:0] offset_w_reg;
	reg uncached_reg;
	reg [19:0] tag_way0 [0:127];
	reg [19:0] tag_way1 [0:127];
	(* keep = "true" *) reg [19:0] preload_tag_way0;
	(* keep = "true" *) reg [19:0] preload_tag_way1;
	reg [127:0] valid_way0;
	reg [127:0] valid_way1;
	reg [2:0] main_state;
	parameter OP_READ = 3'b000;
	parameter OP_WRITE = 3'b001;
	parameter OP_CACOP0 = 3'b100;
	parameter OP_CACOP1 = 3'b101;
	parameter OP_CACOP2 = 3'b110;
	parameter OP_CACOP3 = 3'b111;
	parameter RD_TYPE_WORD = 3'b010;
	parameter RD_TYPE_CACHELINE = 3'b100;
	parameter WR_TYPE_CACHELINE = 3'b100;
	parameter MAIN_ST_IDLE = 0;
	parameter MAIN_ST_LOOKUP = 1;
	parameter MAIN_ST_MISS = 2;
	parameter MAIN_ST_REPLACE = 3;
	parameter MAIN_ST_REFILL = 4;
	wire [2:0] rd_type_cache;
	wire [31:0] rd_addr_cache;
	wire rd_req_cache;
	wire [31:0] rd_addr_prefetch;
	wire rd_req_prefetch;
	reg rd_addr_ok;
	wire ret_valid_last;
	reg finished;
	wire idle;
	wire lookup;
	wire miss;
	wire refill;
	wire cache_hit;
	wire cache_hit_and_cached;
	wire refill_write;
	wire cacop0_write;
	wire cacop1_write;
	wire cacop2_write;
	wire [1:0] cache_hit_way;
	wire [0:0] cache_hit_way_id;
	wire pipe_interface_latch;
	wire [255:0] buffer_read_data_new;
	wire [255:0] cache_rd_data;
	reg [255:0] buffer_read_data;
	reg [3:0] buffer_read_data_count;
	reg [3:0] buffer_read_data_count_start;
	reg [0:0] refill_way_id;
	wire next_same_line;
	wire rdata_h_valid;
	wire [19:0] prefetch_tag;
	wire [6:0] prefetch_index;
	reg [19:0] prefetch_tag_reg;
	reg [6:0] prefetch_index_reg;
	reg [255:0] prefetch_data_reg;
	reg prefetch_valid_reg;
	reg prefetching;
	wire prefetch_cached;
	wire [1:0] prefetch_cached_way;
	wire prefetch_hit;
	wire prefetch_same_line;
	wire prefetch_next_same_line;
	wire fetch_ok;
	assign cacop = op[2];
	assign cacop_reg = op_reg[2];
	assign cacop_id_reg = op_reg[1:0];
	assign cacop_way_id = (op_reg == OP_CACOP2 ? cache_hit_way_id : offset_reg[0:0]);
	assign data_addr = (pipe_interface_latch ? index : index_reg);
	assign offset_w_reg = offset_reg[4:2];
	assign idle = main_state == MAIN_ST_IDLE;
	assign lookup = main_state == MAIN_ST_LOOKUP;
	assign miss = main_state == MAIN_ST_MISS;
	assign refill = main_state == MAIN_ST_REFILL;
	assign ret_valid_last = ret_valid & ret_last;
	assign next_same_line = (index == index_reg) & (tag == tag_reg);
	assign pipe_interface_latch = valid & (cacop | cacop_reg ? !prefetching & (idle | (lookup & cache_hit_and_cached)) : (((idle & !((prefetching & prefetch_next_same_line) & ret_valid_last)) | (lookup & cache_hit_and_cached)) | (miss & ((!prefetching & next_same_line) | prefetch_next_same_line))) | (((((refill & !uncached_reg) & uncached) & (data_ok | finished)) & next_same_line) & !fetch_ok));
	always @(posedge clk)
		if (!resetn)
			finished <= 1;
		else if (addr_ok)
			finished <= 0;
		else if (!addr_ok & data_ok)
			finished <= 1;
	always @(posedge clk)
		if (!resetn)
			;
		else begin
			if (pipe_interface_latch) begin
				op_reg <= op;
				index_reg <= index;
				tag_reg <= tag;
				offset_reg <= offset;
				uncached_reg <= uncached;
			end
			if (lookup) begin
				index_reg_miss <= index_reg;
				offset_reg_miss <= offset_reg;
			end
		end
	assign addr_ok = pipe_interface_latch;
	assign cacop0_write = lookup & (op_reg == OP_CACOP0);
	assign cacop1_write = lookup & (op_reg == OP_CACOP1);
	assign cacop2_write = (lookup & (op_reg == OP_CACOP2)) & cache_hit;
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
			refill_way_id <= 0;
		end
		else
			case (main_state)
				MAIN_ST_IDLE:
					if (pipe_interface_latch)
						main_state <= MAIN_ST_LOOKUP;
				MAIN_ST_LOOKUP:
					if (cache_hit_and_cached | cacop_reg) begin
						if (!pipe_interface_latch)
							main_state <= MAIN_ST_IDLE;
					end
					else
						main_state <= MAIN_ST_MISS;
				MAIN_ST_MISS:
					if (!prefetching) begin
						if (uncached_reg) begin
							if (rd_rdy & !prefetching)
								main_state <= MAIN_ST_REFILL;
						end
						else if (!prefetching)
							main_state <= MAIN_ST_REFILL;
					end
				MAIN_ST_REFILL:
					if (fetch_ok) begin
						main_state <= MAIN_ST_IDLE;
						refill_way_id <= refill_way_id + 1;
					end
			endcase
	genvar _genvar_i_2;
	generate
		for (_genvar_i_2 = 0; _genvar_i_2 < 2; _genvar_i_2 = _genvar_i_2 + 1) begin : gen_cache_hit_way
			localparam i = _genvar_i_2;
			assign cache_hit_way[i] = (({i == 0} & valid_way0[index_reg]) | ({i == 1} & valid_way1[index_reg])) & ((({20 {i == 0}} & preload_tag_way0) | ({20 {i == 1}} & preload_tag_way1)) == tag_reg);
		end
	endgenerate
	assign cache_hit = cache_hit_way != 0;
	assign cache_hit_and_cached = cache_hit & !uncached_reg;
	assign cache_hit_way_id = ({cache_hit_way[0]} & 0) | ({cache_hit_way[1]} & 1);
	assign cache_rd_data = (cache_hit ? ({256 {cache_hit_way_id == 0}} & data_way0) | ({256 {cache_hit_way_id == 1}} & data_way1) : (prefetch_hit ? prefetch_data_reg : (buffer_read_data_count[3] & (buffer_read_data_count[2:0] == offset_reg_miss[4:2]) ? buffer_read_data : buffer_read_data_new)));
	assign rdata_l = (uncached_reg ? ret_data : ((((((({32 {offset_w_reg == 0}} & cache_rd_data[31:0]) | ({32 {offset_w_reg == 1}} & cache_rd_data[63:32])) | ({32 {offset_w_reg == 2}} & cache_rd_data[95:64])) | ({32 {offset_w_reg == 3}} & cache_rd_data[127:96])) | ({32 {offset_w_reg == 4}} & cache_rd_data[159:128])) | ({32 {offset_w_reg == 5}} & cache_rd_data[191:160])) | ({32 {offset_w_reg == 6}} & cache_rd_data[223:192])) | ({32 {offset_w_reg == 7}} & cache_rd_data[255:224]));
	assign rdata_h = ((((((({32 {(offset_w_reg + 1) == 0}} & cache_rd_data[31:0]) | ({32 {(offset_w_reg + 1) == 1}} & cache_rd_data[63:32])) | ({32 {(offset_w_reg + 1) == 2}} & cache_rd_data[95:64])) | ({32 {(offset_w_reg + 1) == 3}} & cache_rd_data[127:96])) | ({32 {(offset_w_reg + 1) == 4}} & cache_rd_data[159:128])) | ({32 {(offset_w_reg + 1) == 5}} & cache_rd_data[191:160])) | ({32 {(offset_w_reg + 1) == 6}} & cache_rd_data[223:192])) | ({32 {(offset_w_reg + 1) == 7}} & cache_rd_data[255:224]);
	assign rdata_h_valid = (offset_w_reg != {3 {1'b1}}) & !uncached_reg;
	assign data_ok = (!cacop_reg & !finished) & (((lookup & cache_hit_and_cached) | prefetch_hit) | (uncached_reg ? refill & ret_valid_last : ((refill | (prefetching & prefetch_same_line)) & ret_valid) & (rdata_h_valid ? buffer_read_data_count > {offset_w_reg < buffer_read_data_count_start[2:0], offset_w_reg} : buffer_read_data_count >= {offset_w_reg < buffer_read_data_count_start[2:0], offset_w_reg})));
	assign wr_type = 0;
	assign wr_addr = 0;
	assign wr_data = 0;
	assign wr_req = 0;
	assign wr_wstrb = 0;
	assign rd_type_cache = (uncached_reg ? RD_TYPE_WORD : RD_TYPE_CACHELINE);
	assign rd_addr_cache = (uncached_reg ? {tag_reg, index_reg, offset_reg} : {tag_reg, index_reg_miss, {5 {1'b0}}});
	assign rd_req_cache = (!prefetch_hit & refill) & ~rd_addr_ok;
	assign rd_type = (prefetching ? RD_TYPE_CACHELINE : rd_type_cache);
	assign rd_addr = (prefetching ? rd_addr_prefetch : rd_addr_cache);
	assign rd_req = (prefetching ? rd_req_prefetch : rd_req_cache);
	assign buffer_read_data_new = buffer_read_data | ({{224 {1'b0}}, ret_data} << (32 * buffer_read_data_count[2:0]));
	always @(posedge clk)
		if (!resetn) begin
			buffer_read_data <= 0;
			buffer_read_data_count <= 0;
		end
		else begin
			if (!uncached_reg & ret_valid) begin
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
		if (!(refill | prefetching))
			rd_addr_ok <= 0;
		else if ((refill | prefetching) & rd_rdy)
			rd_addr_ok <= 1;
	assign refill_write = (!uncached_reg & refill) & fetch_ok;
	always @(posedge clk)
		if (!resetn) begin : valid_tb_reset
			integer j;
			for (j = 0; j < 2; j = j + 1)
				begin
					valid_way0 <= 0;
					valid_way1 <= 0;
				end
		end
		else if (refill_write)
			case (refill_way_id)
				0: begin
					tag_way0[index_reg] <= tag_reg;
					valid_way0[index_reg] <= 1;
				end
				1: begin
					tag_way1[index_reg] <= tag_reg;
					valid_way1[index_reg] <= 1;
				end
			endcase
		else if ((cacop0_write | cacop1_write) | cacop2_write)
			case (cacop_way_id)
				0: valid_way0[index_reg] <= 0;
				1: valid_way1[index_reg] <= 0;
			endcase
	blk_mem_gen_cache_32 icache_way0_ram(
		.addra(data_addr),
		.clka(clk),
		.dina(cache_rd_data),
		.douta(data_way0),
		.wea(refill_write & (refill_way_id == 0))
	);
	blk_mem_gen_cache_32 icache_way1_ram(
		.addra(data_addr),
		.clka(clk),
		.dina(cache_rd_data),
		.douta(data_way1),
		.wea(refill_write & (refill_way_id == 1))
	);
	assign prefetch_tag = tag_reg;
	assign prefetch_index = index_reg + 1;
	assign rd_addr_prefetch = {prefetch_tag_reg, prefetch_index_reg, {5 {1'b0}}};
	assign rd_req_prefetch = prefetching & !rd_addr_ok;
	generate
		for (_genvar_i_2 = 0; _genvar_i_2 < 2; _genvar_i_2 = _genvar_i_2 + 1) begin : gen_prefetch_cached_way
			localparam i = _genvar_i_2;
			assign prefetch_cached_way[i] = (({i == 0} & valid_way0[prefetch_index]) | ({i == 1} & valid_way1[prefetch_index])) & ((({20 {i == 0}} & tag_way0[prefetch_index]) | ({20 {i == 1}} & tag_way1[prefetch_index])) == prefetch_tag);
		end
	endgenerate
	assign prefetch_next_same_line = (prefetch_index_reg == index) & (prefetch_tag_reg == tag);
	assign prefetch_same_line = (prefetch_index_reg == index_reg) & (prefetch_tag_reg == tag_reg);
	assign prefetch_cached = prefetch_cached_way != 0;
	assign prefetch_hit = (!uncached_reg & prefetch_valid_reg) & prefetch_same_line;
	assign fetch_ok = prefetch_hit | ret_valid_last;
	always @(posedge clk) begin
		if (!resetn) begin
			prefetching <= 0;
			prefetch_valid_reg <= 0;
			prefetch_tag_reg <= 0;
			prefetch_index_reg <= 0;
		end
		if (prefetching & ret_valid_last) begin
			prefetching <= 0;
			prefetch_valid_reg <= 1;
			prefetch_data_reg <= buffer_read_data_new;
		end
	end
endmodule
