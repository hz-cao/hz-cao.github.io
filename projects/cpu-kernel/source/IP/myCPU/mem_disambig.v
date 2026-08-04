// ROB-indexed load/store ordering tracker.
//
// Stores remain non-speculative and execute only at the ROB head. Loads may
// execute past older stores whose addresses are not known yet. When a store
// reaches the head and resolves its address, every younger speculative load
// is checked at byte granularity. A hit requests a precise pipeline replay.

module mem_disambig #(
	parameter ROB_ENTRIES = 32,
	parameter ROB_ID_W = 5
) (
	clk,
	reset,
	flush,
	rob_head,
	alloc_a_valid,
	alloc_a_id,
	alloc_a_is_load,
	alloc_a_is_store,
	alloc_b_valid,
	alloc_b_id,
	alloc_b_is_load,
	alloc_b_is_store,
	load_exec_valid,
	load_exec_id,
	load_exec_pc,
	load_exec_addr,
	load_exec_mask,
	store_probe_valid,
	store_probe_id,
	store_probe_pc,
	store_probe_addr,
	store_probe_mask,
	retire_a_valid,
	retire_a_id,
	retire_b_valid,
	retire_b_id,
	query_a_valid,
	query_a_id,
	query_a_pc,
	query_a_block,
	query_b_valid,
	query_b_id,
	query_b_pc,
	query_b_block,
	ordering_violation,
	violation_load_pc,
	violation_store_pc,
	speculative_load_count,
	ordering_violation_count
);
	input clk;
	input reset;
	input flush;
	input [ROB_ID_W-1:0] rob_head;
	input alloc_a_valid;
	input [ROB_ID_W-1:0] alloc_a_id;
	input alloc_a_is_load;
	input alloc_a_is_store;
	input alloc_b_valid;
	input [ROB_ID_W-1:0] alloc_b_id;
	input alloc_b_is_load;
	input alloc_b_is_store;
	input load_exec_valid;
	input [ROB_ID_W-1:0] load_exec_id;
	input [31:0] load_exec_pc;
	input [31:0] load_exec_addr;
	input [3:0] load_exec_mask;
	input store_probe_valid;
	input [ROB_ID_W-1:0] store_probe_id;
	input [31:0] store_probe_pc;
	input [31:0] store_probe_addr;
	input [3:0] store_probe_mask;
	input retire_a_valid;
	input [ROB_ID_W-1:0] retire_a_id;
	input retire_b_valid;
	input [ROB_ID_W-1:0] retire_b_id;
	input query_a_valid;
	input [ROB_ID_W-1:0] query_a_id;
	input [31:0] query_a_pc;
	output wire query_a_block;
	input query_b_valid;
	input [ROB_ID_W-1:0] query_b_id;
	input [31:0] query_b_pc;
	output wire query_b_block;
	output reg ordering_violation;
	output reg [31:0] violation_load_pc;
	output reg [31:0] violation_store_pc;
	output reg [31:0] speculative_load_count;
	output reg [31:0] ordering_violation_count;

	reg entry_valid [0:ROB_ENTRIES-1];
	reg entry_is_load [0:ROB_ENTRIES-1];
	reg entry_is_store [0:ROB_ENTRIES-1];
	reg store_addr_ready [0:ROB_ENTRIES-1];
	reg load_executed [0:ROB_ENTRIES-1];
	reg load_speculative [0:ROB_ENTRIES-1];
	reg [31:0] load_pc [0:ROB_ENTRIES-1];
	reg [31:0] load_addr [0:ROB_ENTRIES-1];
	reg [3:0] load_mask [0:ROB_ENTRIES-1];
	reg dep_valid [0:15];
	reg [25:0] dep_tag [0:15];
	reg [2:0] violation_pressure;
	reg adaptive_serialize;

	reg older_unknown_store;
	reg [ROB_ID_W-1:0] load_distance;
	reg [ROB_ID_W-1:0] store_distance;
	integer i;
	always @(*) begin
		older_unknown_store = 1'b0;
		load_distance = load_exec_id - rob_head;
		for (i = 0; i < ROB_ENTRIES; i = i + 1) begin
			store_distance = i[ROB_ID_W-1:0] - rob_head;
			if (entry_valid[i] && entry_is_store[i] && !store_addr_ready[i] &&
			    (store_distance < load_distance))
				older_unknown_store = 1'b1;
		end
	end

	wire query_a_dep_hit = dep_valid[query_a_pc[5:2]] &&
	                       (dep_tag[query_a_pc[5:2]] == query_a_pc[31:6]);
	wire query_b_dep_hit = dep_valid[query_b_pc[5:2]] &&
	                       (dep_tag[query_b_pc[5:2]] == query_b_pc[31:6]);
	reg query_a_older_unknown_store;
	reg query_b_older_unknown_store;
	reg [ROB_ID_W-1:0] query_a_distance;
	reg [ROB_ID_W-1:0] query_b_distance;
	reg [ROB_ID_W-1:0] query_store_distance;
	integer q;
	always @(*) begin
		query_a_older_unknown_store = 1'b0;
		query_b_older_unknown_store = 1'b0;
		query_a_distance = query_a_id - rob_head;
		query_b_distance = query_b_id - rob_head;
		for (q = 0; q < ROB_ENTRIES; q = q + 1) begin
			query_store_distance = q[ROB_ID_W-1:0] - rob_head;
			if (entry_valid[q] && entry_is_store[q] && !store_addr_ready[q]) begin
				if (query_store_distance < query_a_distance)
					query_a_older_unknown_store = 1'b1;
				if (query_store_distance < query_b_distance)
					query_b_older_unknown_store = 1'b1;
			end
		end
	end
	// Direct-mapped store-set entries handle isolated dependencies. If a
	// workload repeatedly violates ordering and thrashes that small table,
	// fall back to blocking all loads behind unresolved older stores until the
	// next architectural reset. This keeps low-conflict workloads speculative
	// while bounding replay pressure on long-running memory-heavy benchmarks.
	assign query_a_block = query_a_valid && query_a_older_unknown_store &&
	                       (query_a_dep_hit || adaptive_serialize);
	assign query_b_block = query_b_valid && query_b_older_unknown_store &&
	                       (query_b_dep_hit || adaptive_serialize);

	// Build conflict hits in parallel, then select one load PC with a balanced
	// five-level tree. Predictor training only needs a real conflicting PC; it
	// does not require the oldest one. This avoids a 32-entry serial priority
	// chain on the execute path.
	wire [ROB_ENTRIES-1:0] violation_hit;
	genvar vh;
	generate
		for (vh = 0; vh < ROB_ENTRIES; vh = vh + 1) begin : gen_violation_hit
			localparam [ROB_ID_W-1:0] ENTRY_ID = vh;
			wire [ROB_ID_W-1:0] entry_distance = ENTRY_ID - rob_head;
			wire [ROB_ID_W-1:0] probe_distance = store_probe_id - rob_head;
			assign violation_hit[vh] = store_probe_valid && entry_valid[vh] &&
			                           entry_is_load[vh] && load_executed[vh] &&
			                           load_speculative[vh] &&
			                           (entry_distance > probe_distance) &&
			                           (load_addr[vh][31:2] == store_probe_addr[31:2]) &&
			                           (|(load_mask[vh] & store_probe_mask));
		end
	endgenerate

	wire [15:0] violation_valid_l1;
	wire [7:0] violation_valid_l2;
	wire [3:0] violation_valid_l3;
	wire [1:0] violation_valid_l4;
	wire violation_valid_l5;
	wire [31:0] violation_pc_l1 [0:15];
	wire [31:0] violation_pc_l2 [0:7];
	wire [31:0] violation_pc_l3 [0:3];
	wire [31:0] violation_pc_l4 [0:1];
	wire [31:0] violation_pc_l5;
	genvar vt;
	generate
		for (vt = 0; vt < 16; vt = vt + 1) begin : gen_violation_l1
			assign violation_valid_l1[vt] = violation_hit[2*vt] |
			                                      violation_hit[2*vt+1];
			assign violation_pc_l1[vt] = violation_hit[2*vt] ?
			                              load_pc[2*vt] : load_pc[2*vt+1];
		end
		for (vt = 0; vt < 8; vt = vt + 1) begin : gen_violation_l2
			assign violation_valid_l2[vt] = violation_valid_l1[2*vt] |
			                                      violation_valid_l1[2*vt+1];
			assign violation_pc_l2[vt] = violation_valid_l1[2*vt] ?
			                              violation_pc_l1[2*vt] : violation_pc_l1[2*vt+1];
		end
		for (vt = 0; vt < 4; vt = vt + 1) begin : gen_violation_l3
			assign violation_valid_l3[vt] = violation_valid_l2[2*vt] |
			                                      violation_valid_l2[2*vt+1];
			assign violation_pc_l3[vt] = violation_valid_l2[2*vt] ?
			                              violation_pc_l2[2*vt] : violation_pc_l2[2*vt+1];
		end
		for (vt = 0; vt < 2; vt = vt + 1) begin : gen_violation_l4
			assign violation_valid_l4[vt] = violation_valid_l3[2*vt] |
			                                      violation_valid_l3[2*vt+1];
			assign violation_pc_l4[vt] = violation_valid_l3[2*vt] ?
			                              violation_pc_l3[2*vt] : violation_pc_l3[2*vt+1];
		end
	endgenerate
	assign violation_valid_l5 = violation_valid_l4[0] | violation_valid_l4[1];
	assign violation_pc_l5 = violation_valid_l4[0] ? violation_pc_l4[0] :
	                                                   violation_pc_l4[1];
	wire violation_found = violation_valid_l5;
	wire [31:0] violation_found_load_pc = violation_pc_l5;

	integer j;
	integer d;
	always @(posedge clk) begin
		if (reset) begin
			for (j = 0; j < ROB_ENTRIES; j = j + 1) begin
				entry_valid[j] <= 1'b0;
				entry_is_load[j] <= 1'b0;
				entry_is_store[j] <= 1'b0;
				store_addr_ready[j] <= 1'b0;
				load_executed[j] <= 1'b0;
				load_speculative[j] <= 1'b0;
			end
			for (d = 0; d < 16; d = d + 1) begin
				dep_valid[d] <= 1'b0;
				dep_tag[d] <= 26'b0;
			end
			speculative_load_count <= 32'b0;
			ordering_violation_count <= 32'b0;
			ordering_violation <= 1'b0;
			violation_load_pc <= 32'b0;
			violation_store_pc <= 32'b0;
			violation_pressure <= 3'b0;
			adaptive_serialize <= 1'b0;
		end
		else if (flush) begin
			ordering_violation <= 1'b0;
			for (j = 0; j < ROB_ENTRIES; j = j + 1) begin
				entry_valid[j] <= 1'b0;
				entry_is_load[j] <= 1'b0;
				entry_is_store[j] <= 1'b0;
				store_addr_ready[j] <= 1'b0;
				load_executed[j] <= 1'b0;
				load_speculative[j] <= 1'b0;
			end
			if (ordering_violation) begin
				ordering_violation_count <= ordering_violation_count + 1'b1;
				dep_valid[violation_load_pc[5:2]] <= 1'b1;
				dep_tag[violation_load_pc[5:2]] <= violation_load_pc[31:6];
				if (violation_pressure != 3'd7)
					violation_pressure <= violation_pressure + 1'b1;
				if (violation_pressure >= 3'd3)
					adaptive_serialize <= 1'b1;
			end
		end
		else begin
			// Register the violation before it drives replay and predictor update.
			// This removes the LSQ scan and dynamic predictor write from the
			// execute-to-global-flush timing path.
			ordering_violation <= violation_found;
			violation_load_pc <= violation_found_load_pc;
			violation_store_pc <= store_probe_pc;
			if (retire_a_valid)
				entry_valid[retire_a_id] <= 1'b0;
			if (retire_b_valid)
				entry_valid[retire_b_id] <= 1'b0;

			if (alloc_a_valid && (alloc_a_is_load || alloc_a_is_store)) begin
				entry_valid[alloc_a_id] <= 1'b1;
				entry_is_load[alloc_a_id] <= alloc_a_is_load;
				entry_is_store[alloc_a_id] <= alloc_a_is_store;
				store_addr_ready[alloc_a_id] <= 1'b0;
				load_executed[alloc_a_id] <= 1'b0;
				load_speculative[alloc_a_id] <= 1'b0;
			end
			if (alloc_b_valid && (alloc_b_is_load || alloc_b_is_store)) begin
				entry_valid[alloc_b_id] <= 1'b1;
				entry_is_load[alloc_b_id] <= alloc_b_is_load;
				entry_is_store[alloc_b_id] <= alloc_b_is_store;
				store_addr_ready[alloc_b_id] <= 1'b0;
				load_executed[alloc_b_id] <= 1'b0;
				load_speculative[alloc_b_id] <= 1'b0;
			end

			if (load_exec_valid) begin
				load_executed[load_exec_id] <= 1'b1;
				load_speculative[load_exec_id] <= older_unknown_store;
				load_pc[load_exec_id] <= load_exec_pc;
				load_addr[load_exec_id] <= load_exec_addr;
				load_mask[load_exec_id] <= load_exec_mask;
				if (older_unknown_store)
					speculative_load_count <= speculative_load_count + 1'b1;
			end

			if (store_probe_valid)
				store_addr_ready[store_probe_id] <= 1'b1;
		end
	end
endmodule
