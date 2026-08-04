module id_stage (
	pc,
	inst,
	pred_br_taken,
	pred_br_target,
	counter,
	llbit,
	optype,
	opcode,
	dest,
	imm,
	br_type,
	br_condition,
	br_target,
	have_excp,
	excp_type,
	csr_addr,
	csr_wr,
	is_spec_op,
	is_idle,
	is_ll,
	is_sc,
	r1,
	r2,
	src2_is_imm,
	br_mistaken,
	br_taken
);
	input [31:0] pc;
	input [31:0] inst;
	input pred_br_taken;
	input [31:0] pred_br_target;
	input [63:0] counter;
	input llbit;
	output wire [2:0] optype;
	output wire [5:0] opcode;
	output wire [4:0] dest;
	output wire [31:0] imm;
	output wire [2:0] br_type;
	output wire br_condition;
	output wire [31:0] br_target;
	output wire have_excp;
	output wire [14:0] excp_type;
	output wire [13:0] csr_addr;
	output wire csr_wr;
	output wire is_spec_op;
	output wire is_idle;
	output wire is_ll;
	output wire is_sc;
	output wire [4:0] r1;
	output wire [4:0] r2;
	output wire src2_is_imm;
	output wire br_mistaken;
	output wire br_taken;
	wire valid_inst;
	wire ine;
	wire [21:0] op_31_10 = inst[31:10];
	wire [16:0] op_31_15 = inst[31:15];
	wire [13:0] op_31_18 = inst[31:18];
	wire [11:0] op_31_20 = inst[31:20];
	wire [9:0] op_31_22 = inst[31:22];
	wire [7:0] op_31_24 = inst[31:24];
	wire [6:0] op_31_25 = inst[31:25];
	wire [5:0] op_31_26 = inst[31:26];
	wire [4:0] rd = inst[4:0];
	wire [4:0] rj = inst[9:5];
	wire [4:0] rk = inst[14:10];
	wire [4:0] i5 = inst[14:10];
	wire [11:0] i12 = inst[21:10];
	wire [13:0] i14 = inst[23:10];
	wire [15:0] i16 = inst[25:10];
	wire [19:0] i20 = inst[24:5];
	wire [25:0] i26 = {inst[9:0], inst[25:10]};
	wire [31:0] ui5 = {27'd0, i5};
	wire [31:0] si12 = {{20 {i12[11]}}, i12};
	wire [31:0] ui12 = {20'd0, i12};
	wire [31:0] si14 = {{16 {i14[13]}}, i14, 2'b00};
	wire [31:0] si16 = {{14 {i16[15]}}, i16, 2'b00};
	wire [31:0] si20 = {i20, 12'b000000000000};
	wire [31:0] si26 = {{4 {i26[25]}}, i26, 2'b00};
	wire inst_rdcntid_w = ((op_31_10 == 22'b0000000000000000011000) && (rd == 5'd0)) && (rj != 5'd0);
	wire inst_rdcntvl_w = ((op_31_10 == 22'b0000000000000000011000) && (rd != 5'd0)) && (rj == 5'd0);
	wire inst_rdcntvh_w = op_31_10 == 22'b0000000000000000011001;
	wire inst_cpucfg = (op_31_15 == 17'b0) && (rk == 5'h1b);
	wire inst_add_w = op_31_15 == 17'b00000000000100000;
	wire inst_sub_w = op_31_15 == 17'b00000000000100010;
	wire inst_slt = op_31_15 == 17'b00000000000100100;
	wire inst_sltu = op_31_15 == 17'b00000000000100101;
	wire inst_nor = op_31_15 == 17'b00000000000101000;
	wire inst_and = op_31_15 == 17'b00000000000101001;
	wire inst_or = op_31_15 == 17'b00000000000101010;
	wire inst_xor = op_31_15 == 17'b00000000000101011;
	wire inst_sll_w = op_31_15 == 17'b00000000000101110;
	wire inst_srl_w = op_31_15 == 17'b00000000000101111;
	wire inst_sra_w = op_31_15 == 17'b00000000000110000;
	wire inst_mul_w = op_31_15 == 17'b00000000000111000;
	wire inst_mulh_w = op_31_15 == 17'b00000000000111001;
	wire inst_mulh_wu = op_31_15 == 17'b00000000000111010;
	wire inst_div_w = op_31_15 == 17'b00000000001000000;
	wire inst_mod_w = op_31_15 == 17'b00000000001000001;
	wire inst_div_wu = op_31_15 == 17'b00000000001000010;
	wire inst_mod_wu = op_31_15 == 17'b00000000001000011;
	wire inst_break = op_31_15 == 17'b00000000001010100;
	wire inst_syscall = op_31_15 == 17'b00000000001010110;
	wire inst_slli_w = op_31_15 == 17'b00000000010000001;
	wire inst_srli_w = op_31_15 == 17'b00000000010001001;
	wire inst_srai_w = op_31_15 == 17'b00000000010010001;
	wire inst_slti = op_31_22 == 10'b0000001000;
	wire inst_sltui = op_31_22 == 10'b0000001001;
	wire inst_addi_w = op_31_22 == 10'b0000001010;
	wire inst_andi = op_31_22 == 10'b0000001101;
	wire inst_ori = op_31_22 == 10'b0000001110;
	wire inst_xori = op_31_22 == 10'b0000001111;
	wire inst_csrx = op_31_24 == 8'b00000100;
	wire inst_cacop = op_31_22 == 10'b0000011000;
	wire inst_tlbsrch = op_31_10 == 22'b0000011001001000001010;
	wire inst_tlbrd = op_31_10 == 22'b0000011001001000001011;
	wire inst_tlbwr = op_31_10 == 22'b0000011001001000001100;
	wire inst_tlbfill = op_31_10 == 22'b0000011001001000001101;
	wire inst_ertn = inst == 32'b00000110010010000011100000000000;
	wire inst_idle = op_31_15 == 17'b00000110010010001;
	wire inst_invtlb = op_31_15 == 17'b00000110010010011;
	wire inst_lu12i_w = op_31_25 == 7'b0001010;
	wire inst_pcaddu12i = op_31_25 == 7'b0001110;
	wire inst_ll_w = op_31_24 == 8'b00100000;
	wire inst_sc_w = op_31_24 == 8'b00100001;
	wire inst_ld_b = op_31_22 == 10'b0010100000;
	wire inst_ld_h = op_31_22 == 10'b0010100001;
	wire inst_ld_w = op_31_22 == 10'b0010100010;
	wire inst_st_b = op_31_22 == 10'b0010100100;
	wire inst_st_h = op_31_22 == 10'b0010100101;
	wire inst_st_w = op_31_22 == 10'b0010100110;
	wire inst_ld_bu = op_31_22 == 10'b0010101000;
	wire inst_ld_hu = op_31_22 == 10'b0010101001;
	wire inst_preld = op_31_22 == 10'b0010101011;
	wire inst_dbar = op_31_15 == 17'b00111000011100100;
	wire inst_ibar = op_31_15 == 17'b00111000011100101;
	wire inst_jirl = op_31_26 == 6'b010011;
	wire inst_b = op_31_26 == 6'b010100;
	wire inst_bl = op_31_26 == 6'b010101;
	wire inst_beq = op_31_26 == 6'b010110;
	wire inst_bne = op_31_26 == 6'b010111;
	wire inst_blt = op_31_26 == 6'b011000;
	wire inst_bge = op_31_26 == 6'b011001;
	wire inst_bltu = op_31_26 == 6'b011010;
	wire inst_bgeu = op_31_26 == 6'b011011;
	wire [5:0] mem_opcode;
	assign mem_opcode[5] = ((((inst_ld_b | inst_ld_bu) | inst_ld_h) | inst_ld_hu) | inst_ld_w) | inst_ll_w;
	assign mem_opcode[4] = ((inst_st_b | inst_st_h) | inst_st_w) | inst_sc_w;
	assign mem_opcode[3] = inst_ld_b | inst_ld_h;
	assign mem_opcode[2] = ((inst_ld_w | inst_st_w) | inst_ll_w) | inst_sc_w;
	assign mem_opcode[1] = (inst_ld_h | inst_ld_hu) | inst_st_h;
	assign mem_opcode[0] = (inst_ld_b | inst_ld_bu) | inst_st_b;
	wire [2:0] sc_optype;
	assign sc_optype = (llbit ? 3'd3 : 3'd0);
	assign {valid_inst, optype, opcode, r1, r2, src2_is_imm, imm, dest} = ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((({58 {inst_add_w}} & {10'h201, rj, rk, 33'h000000000, rd}) | ({58 {inst_sub_w}} & {10'h202, rj, rk, 33'h000000000, rd})) | ({58 {inst_addi_w}} & {10'h201, rj, 6'h01, si12, rd})) | ({58 {inst_lu12i_w}} & {21'h100001, si20, rd})) | ({58 {inst_slt}} & {10'h204, rj, rk, 33'h000000000, rd})) | ({58 {inst_sltu}} & {10'h205, rj, rk, 33'h000000000, rd})) | ({58 {inst_slti}} & {10'h204, rj, 6'h01, si12, rd})) | ({58 {inst_sltui}} & {10'h205, rj, 6'h01, si12, rd})) | ({58 {inst_pcaddu12i}} & {21'h100001, pc + si20, rd})) | ({58 {inst_and}} & {10'h206, rj, rk, 33'h000000000, rd})) | ({58 {inst_or}} & {10'h208, rj, rk, 33'h000000000, rd})) | ({58 {inst_nor}} & {10'h207, rj, rk, 33'h000000000, rd})) | ({58 {inst_xor}} & {10'h209, rj, rk, 33'h000000000, rd})) | ({58 {inst_andi}} & {10'h206, rj, 6'h01, ui12, rd})) | ({58 {inst_ori}} & {10'h208, rj, 6'h01, ui12, rd})) | ({58 {inst_xori}} & {10'h209, rj, 6'h01, ui12, rd})) | ({58 {inst_mul_w}} & {10'h240, rj, rk, 33'h000000000, rd})) | ({58 {inst_mulh_w}} & {10'h241, rj, rk, 33'h000000000, rd})) | ({58 {inst_mulh_wu}} & {10'h242, rj, rk, 33'h000000000, rd})) | ({58 {inst_div_w}} & {10'h280, rj, rk, 33'h000000000, rd})) | ({58 {inst_div_wu}} & {10'h281, rj, rk, 33'h000000000, rd})) | ({58 {inst_mod_w}} & {10'h282, rj, rk, 33'h000000000, rd})) | ({58 {inst_mod_wu}} & {10'h283, rj, rk, 33'h000000000, rd})) | ({58 {inst_sll_w}} & {10'h20a, rj, rk, 33'h000000000, rd})) | ({58 {inst_srl_w}} & {10'h20b, rj, rk, 33'h000000000, rd})) | ({58 {inst_sra_w}} & {10'h20c, rj, rk, 33'h000000000, rd})) | ({58 {inst_slli_w}} & {10'h20a, rj, 6'h01, ui5, rd})) | ({58 {inst_srli_w}} & {10'h20b, rj, 6'h01, ui5, rd})) | ({58 {inst_srai_w}} & {10'h20c, rj, 6'h01, ui5, rd})) | ({58 {inst_beq}} & {10'h203, rj, rd, 38'h0000000000})) | ({58 {inst_bne}} & {10'h203, rj, rd, 38'h0000000000})) | ({58 {inst_blt}} & {10'h204, rj, rd, 38'h0000000000})) | ({58 {inst_bltu}} & {10'h205, rj, rd, 38'h0000000000})) | ({58 {inst_bge}} & {10'h204, rj, rd, 38'h0000000000})) | ({58 {inst_bgeu}} & {10'h205, rj, rd, 38'h0000000000})) | ({58 {inst_b}} & 58'h200000000000000)) | ({58 {inst_bl}} & {21'h100001, pc + 32'd4, 5'd1})) | ({58 {inst_jirl}} & {10'h200, rj, 6'h01, pc + 32'd4, rd})) | ({58 {inst_ld_b}} & {4'hb, mem_opcode, rj, 6'h01, si12, rd})) | ({58 {inst_ld_h}} & {4'hb, mem_opcode, rj, 6'h00, si12, rd})) | ({58 {inst_ld_w}} & {4'hb, mem_opcode, rj, 6'h00, si12, rd})) | ({58 {inst_ld_bu}} & {4'hb, mem_opcode, rj, 6'h00, si12, rd})) | ({58 {inst_ld_hu}} & {4'hb, mem_opcode, rj, 6'h00, si12, rd})) | ({58 {inst_st_b}} & {4'hb, mem_opcode, rj, rd, 1'b0, si12, 5'd0})) | ({58 {inst_st_h}} & {4'hb, mem_opcode, rj, rd, 1'b0, si12, 5'd0})) | ({58 {inst_st_w}} & {4'hb, mem_opcode, rj, rd, 1'b0, si12, 5'd0})) | ({58 {inst_preld}} & 58'h200000000000000)) | ({58 {inst_ll_w}} & {4'hb, mem_opcode, rj, 6'h00, si14, rd})) | ({58 {inst_sc_w}} & {1'b1, sc_optype, mem_opcode, rj, rd, 1'b0, si14, rd})) | ({58 {inst_dbar}} & 58'h200000000000000)) | ({58 {inst_ibar}} & 58'h200000000000000)) | ({58 {inst_syscall}} & 58'h200000000000000)) | ({58 {inst_break}} & 58'h200000000000000)) | ({58 {inst_rdcntvl_w}} & {21'h100001, counter[31:0], rd})) | ({58 {inst_rdcntvh_w}} & {21'h100001, counter[63:32], rd})) | ({58 {inst_rdcntid_w}} & {53'h18000000000000, rj})) | ({58 {inst_cpucfg}} & {10'h20d, rj, 6'h01, 32'h00000000, rd})) | ({58 {inst_csrx}} & {10'h300, rj, rd, 33'h000000000, rd})) | ({58 {inst_cacop}} & {5'h1c, rd, rj, 6'h01, si12, 5'd0})) | ({58 {inst_tlbsrch}} & 58'h340000000000000)) | ({58 {inst_tlbrd}} & 58'h341000000000000)) | ({58 {inst_tlbwr}} & 58'h342000000000000)) | ({58 {inst_tlbfill}} & 58'h343000000000000)) | ({58 {inst_invtlb}} & {10'h344, rj, rk, 28'h0000000, rd, 5'd0})) | ({58 {inst_ertn}} & 58'h200000000000000)) | ({58 {inst_idle}} & 58'h200000000000000);
	assign csr_addr = (inst_rdcntid_w ? 14'h0040 : inst[23:10]);
	assign csr_wr = rj == 5'd1;
	wire [2:0] jirl_type;
	assign jirl_type = (((rd == 5'd0) && (rj == 5'd1)) && (i16 == 0) ? 3'b100 : 3'b101);
	assign {br_type, br_target, br_condition} = (((((((({36 {inst_beq}} & {3'b010, pc + si16, 1'b1}) | ({36 {inst_bne}} & {3'b010, pc + si16, 1'b0})) | ({36 {inst_blt}} & {3'b010, pc + si16, 1'b1})) | ({36 {inst_bltu}} & {3'b010, pc + si16, 1'b1})) | ({36 {inst_bge}} & {3'b010, pc + si16, 1'b0})) | ({36 {inst_bgeu}} & {3'b010, pc + si16, 1'b0})) | ({36 {inst_b}} & {3'b001, pc + si26, 1'b0})) | ({36 {inst_bl}} & {3'b011, pc + si26, 1'b0})) | ({36 {inst_jirl}} & {jirl_type, si16, 1'b0});
	assign br_taken = inst_b | inst_bl;
	assign br_mistaken = (pred_br_taken && ((br_type == 3'b000) || (!inst_jirl && (pred_br_target != br_target)))) || (!pred_br_taken && br_taken);
	assign ine = !valid_inst || (inst_invtlb && (rd > 5'd6));
	assign {have_excp, excp_type} = ((({16 {inst_ertn}} & 16'hf83c) | ({16 {inst_syscall}} & 16'h9600)) | ({16 {inst_break}} & 16'h9800)) | ({16 {ine}} & 16'h9a00);
	assign is_spec_op = ((((((optype == 3'd5) || (optype == 3'd4)) || (optype == 3'd6)) || inst_idle) || inst_ll_w) || inst_sc_w) || inst_ibar;
	assign is_idle = inst_idle;
	assign is_ll = inst_ll_w;
	assign is_sc = inst_sc_w;
endmodule
