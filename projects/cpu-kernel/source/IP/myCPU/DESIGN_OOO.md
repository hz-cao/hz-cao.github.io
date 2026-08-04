# SESSION HANDOFF — 2026-07-12

**Purpose**: fresh-conversation restart point for Stage 4d work. Read this section first; the rest of this document is the full design record.

## Stage completion status

| Stage | Status | Correctness gate result |
|---|---|---|
| 1 (design doc) | DONE | — |
| 2a (rename+PRF shadow) | DONE | bit-exact baseline |
| 2b (PRF via phys-tag bypass) | DONE | bit-exact baseline |
| 3a (RS shadow, 3 RSes) | DONE | bit-exact baseline |
| 3b (RS mediates dispatch→EX1) | DONE | bit-exact baseline via same-cycle passthrough |
| 4a (ROB shadow) | DONE | bit-exact baseline |
| 4b (ROB retire drives arch RF / a-RAT / free-list) | DONE | bit-exact baseline via same-cycle retire bypass |
| **4c (CSR-defer, minimum viable)** | **DONE** | +1 inst / +1 cycle / IPC unchanged — verified consistent |
| 4d (drop dispatch ready-gate, real OoO) | NOT STARTED | — |
| 5 (dual-issue front-end + 2nd ALU port) | NOT STARTED | — |
| 6 (LSQ / SQ / branch predictor) | NOT STARTED | — |

## Correctness gate as of Stage 4c

- **Pass count**: 20/20 (non-negotiable, unchanged).
- **Instructions committed**: `baseline + 1` (permanent characteristic of deferred-CSR design). For `func_lab3` = 197,298.
- **Cycles**: `baseline + 1`. For `func_lab3` = 1,762,626.
- **IPC**: 0.111934 (unchanged to 6 decimal digits — the +1/+1 shift preserves the ratio).
- **DIFFTEST**: zero divergence in any A/B run.

## Verified A/B — Stage 4c termination-shift consistency

3-test A/B swap (revert csr.v inputs + mycpu_top.v tap, run, restore, run) confirmed identical +1/+1 shift:

| Test | 4b-eq | 4c | Δ |
|---|---|---|---|
| func_lab3 | 197,297 / 1,762,625 | 197,298 / 1,762,626 | +1/+1 |
| func_lab4 | 56,293 / 525,914 | 56,294 / 525,915 | +1/+1 |
| func_lab7 | 107,612 / 1,009,400 | 107,613 / 1,009,401 | +1/+1 |

Mechanism: `raise_excp_c` fires at ROB commit (1 cycle later than baseline's EX2-timed `raise_excp`). DIFFTEST `raise_excp_d` taps commit-timing → NEMU steps 1 cycle later → 1 extra WB commit counted before sim-over. Zero functional bug; documented as a permanent characteristic.

## Unresolved dependency — Stage 6 coupling

**Full commit-deferred mispredict/exception recovery requires the Store Queue (SQ, Stage 6)** to buffer wrong-path stores until they retire. Without SQ, a mispredicted branch feeding into a store path would execute the store at EX1 and corrupt dcache. Baseline safety comes from `mem_cancel = raise_excp || replay || ex1_a_br_mistaken_long` at LSU issue.

**Consequence for 4d and beyond**:
- Only CSR delivery is deferred to commit in 4c (`raise_excp_c` → csr.v).
- ALL flush-triggering paths (`flush_ex1`, `flush_ibuf`, `mem_cancel`) MUST remain immediate at EX1/EX2 until Stage 6 SQ exists.
- Stage 4d can drop the dispatch ready-gate safely because ROB-ordered commit + immediate mispredict flush + immediate mem_cancel together preserve arch RF and memory correctness under OoO issue.

## Files on disk — current state (all at Stage 4c final, nothing mid-edit or uncommitted)

| File | State |
|---|---|
| `chiplab/IP/myCPU/rob.v` | 4c — 20-field entry, wrap-safe kill range, same-cycle retire bypass, ret_a/b_br_mispred and ret_a/b_br_actual_target outputs |
| `chiplab/IP/myCPU/core.v` | 4c — br_mispred/actual_target propagation EX1→EX2→WB→ROB; walk_back and raise_excp_c signals; csr.v inputs → ret_a_pc / ret_a_excp_type / raise_excp_c |
| `chiplab/IP/myCPU/mycpu_top.v` | 4c — DIFFTEST ExcpEvent taps raise_excp_c / ret_a_excp_type / ret_a_pc |
| `chiplab/IP/myCPU/DESIGN_OOO.md` | this document (fully updated including this handoff section) |
| `chiplab/IP/myCPU/rs.v` | 3b — full 30-field entry + 4 wakeup taps + rob_id field |
| `chiplab/IP/myCPU/rename.v` | 2a — RAT + free list + flush semantics |
| `chiplab/IP/myCPU/prf.v` | 2b — 64×32 PRF, r0 hardwired |
| `chiplab/IP/myCPU/{mult_gen_0,div_gen_0,blk_mem_gen_cache_32}.v` | Xilinx IP behavioral stubs (baseline reconstruction) |
| `chiplab/IP/myCPU/core_top.sv` | Byte-identical to pre-project (port list preserved) |
| `chiplab/sims/verilator/run_prog/config-software.mak` | `RUN_SOFTWARE=func/func_lab3` (restored after lab4/7 verification) |

## Remaining work — Stage 4d onward

**Stage 4d (next)**: drop `ro_a_src1_ok && ro_a_src2_ok` from `allow_issue_a`/`allow_issue_b`. RS entries can now insert with `src_ready=0` → wakeup fires when producer completes → real OoO issue. Store safety comes from immediate `mem_cancel` (unchanged from 4c). Register-file safety from ROB-ordered commit (unchanged from 4b). Expected: pass count 20/20 stays, instruction count = 197,298 stays, cycle count MAY drop below 1,762,626 (real OoO benefit) or stay flat.

**Stage 5**: widen fetch/decode to 2 insts/cycle proper (currently ibuf is 2-wide but fetch is 1-wide effectively). Add 2nd ALU port to increase issue width. IPC gain expected.

**Stage 6**: Store Queue (SQ) + Load Queue (LQ) with memory disambiguation. Enables removing `mem_cancel` and truly deferring mispredict recovery. Also: branch predictor upgrade (BTB → gshare or similar).

**Deferred DIFFTEST wiring** (for `func_lab14`/`15`/`19`): `Skip`, `IsTlbFill`, `TlbFillIndex`, `IsCount`, `Count`, `CsrRstat`, `CsrData`, `Eret` — currently tied to 0 in `mycpu_top.v`. Not required for `func_lab3` (no TLB/counter/CSR-read tests in TEST1 = n1..n20).

---

# Out-of-Order Dual-Issue Redesign — Stage 1 Design Document

Target: LoongArch32R core in `chiplab/IP/myCPU/`, keeping `core_top.sv` (604 lines) port-boundary identical. Only `mycpu_top` and modules below it may change.

---

## 0. Baseline established (was: precondition)

Baseline reconstructed by adopting QHU `src/src/mycpu/` pipeline and adding the Difftest bundle producer wiring inside `mycpu_top.v`. `core_top.sv` port list unchanged.

**Newly established baseline — func_lab3 (CORRECTNESS GATE for all subsequent stages):**
- **Pass count: 20/20** (TEST_NUM=20 for `func_lab3`; TEST1=1, TEST2..9=0 in `lab_config.h`).
- **Instructions committed: 197,297** (Stages 2–4b), **197,298** (Stage 4c onward — see termination-shift note below).
- **Cycles: 1,762,625** (Stages 2–4b), **1,762,626** (Stage 4c onward).
- **IPC: 0.111934** (bit-exact preserved across all stages — the +1 shift affects both numerator and denominator identically).

**Stage 4c termination-shift artifact (VERIFIED — permanent characteristic of deferred-CSR design):**

Under Stage 4c, `raise_excp_c = ret_a_valid & ret_a_have_excp` fires at ROB commit (1 cycle later than baseline's EX2-timed `raise_excp`). DIFFTEST's ExcpEvent bundle also taps commit-timing signals (via `raise_excp_c` and `ret_a_pc`/`ret_a_excp_type`) to keep NEMU-step in sync with DUT-CSR-visible timing. Consequence: NEMU processes the terminal SYSCALL 1 cycle later than baseline; during that extra cycle, one more WB commit fires and is counted by `inst_total`.

**A/B verification results (2025-Q3):**

| Test | 4b-eq (pre-CSR-defer) | 4c (CSR-defer) | Δ inst | Δ cycles |
|---|---|---|---|---|
| func_lab3 | 197,297 / 1,762,625 | 197,298 / 1,762,626 | +1 | +1 |
| func_lab4 | 56,293 / 525,914 | 56,294 / 525,915 | +1 | +1 |
| func_lab7 | 107,612 / 1,009,400 | 107,613 / 1,009,401 | +1 | +1 |

Consistent +1/+1 shift across three test configurations (different NOP densities, different total workloads, different test-count = 20/20/46). Confirms termination-shift is a pure boundary artifact from the DIFFTEST-signal source change, not workload-dependent. Zero DIFFTEST divergence in any run.

**Correctness gate from Stage 4c onward** (updated):
- Pass count: 20/20 (unchanged, non-negotiable).
- Instruction count: `baseline count + 1` (accounts for CSR-defer termination shift). For func_lab3 = 197,298.
- Cycle count: `baseline count + 1` for func_lab3 = 1,762,626.
- IPC: 0.111934 (unchanged to 6 digits; +1/+1 preserves ratio).
- Any deviation OUTSIDE `+1` (e.g., +0, +2, or larger) must be investigated before proceeding.

**Stage progress:**
- Stage 1: design document — DONE
- Stage 2a: rename+PRF shadow — DONE (bit-exact baseline)
- Stage 2b: switch operand reads to PRF via phys-tag bypass — DONE (bit-exact baseline)
- Stage 3a: reservation station shadow (3 RSes) — DONE (bit-exact baseline)
- Stage 3b: RS mediates dispatch → EX1 fill (2 RSes: RS_ALU0 + RS_ALU1, RS_MEM deferred) — DONE (bit-exact baseline via same-cycle passthrough)
- Stage 4a: ROB shadow (32-entry, 20-field, parallel tracking) — DONE (bit-exact baseline)
- Stage 4b: ROB retire drives arch RF / a-RAT / free-list (replaces WB-direct path) — DONE (bit-exact baseline)
- **Stage 4c: minimum-viable CSR-defer + walk-back scaffolding — DONE (verified +1 termination-shift consistent across 3 test suites)**
- Stage 4d: drop `ro_a_src1_ok && ro_a_src2_ok` from dispatch gate (real OoO) — pending
- Stage 5: dual-issue front-end + 2nd ALU port — pending
- Stage 6: LSQ disambig + branch predictor — pending

## Stage 4: ROB — active planning notes

### ROB entry field set (20 fields, ~230 bits each × 32 entries = ~7.4 Kb)

| Field | Width | Populated at |
|---|---|---|
| `valid` | 1 | alloc / retire / flush |
| `done` | 1 | WB completion (via rob_id) |
| `pc` | 32 | alloc |
| `inst` | 32 | alloc |
| `p_dst` | 6 | alloc |
| `p_prev_dst` | 6 | alloc |
| `dest_arch` | 5 | alloc |
| `has_dest` | 1 | alloc (= `dest_arch != 0`) |
| `result` | 32 | WB completion |
| `have_excp` | 1 | WB completion |
| `excp_type` | 15 | WB completion |
| `is_branch` | 1 | alloc |
| `br_mispredicted` | 1 | WB completion (Stage 4c wires) |
| `br_actual_target` | 32 | WB completion (Stage 4c wires) |
| `is_store` | 1 | alloc |
| `is_csr_wr` | 1 | alloc |
| `csr_addr` | 14 | alloc |
| `is_ll` | 1 | alloc |
| `is_sc` | 1 | alloc |
| `is_unique` | 1 | alloc |

### Stage 4a → 4b → 4c → 4d plan

- **4a**: ROB shadow — alloc + complete + retire logic operational, retire outputs unused. Flush = full reset. Confirmed harmless in shadow. Bit-exact baseline. **[DONE]**
- **4b**: Retire outputs drive arch RF write, `rename` module a-RAT update, `rename` free-list push. Exceptions still delivered immediately at EX2 (unchanged). Flush policy MUST change: preserve EX2/WB entries so they retire; kill only EX1 (RS is empty under passthrough). Correctness gate: bit-exact baseline.
- **4c**: Exception/mispredict delivery deferred from EX2 → ROB commit head. Walk-back machinery: on `have_excp` retire, squash all newer ROB entries (bulk-invalidate + free their `p_dst` back to free-list + s-RAT ← a-RAT + PC redirect). `flush_ex1` becomes ROB-triggered. Execution still in-order. Correctness gate: bit-exact baseline.
- **4d**: Drop `ro_a_src1_ok && ro_a_src2_ok` from `allow_issue_a/b`. RS wakeup becomes load-bearing. **First real OoO.** Pass count and instruction count must stay 20/20 and 197,297; cycle count/IPC may improve.

### Stage 4b flush policy — awaiting user confirmation

Concern raised from 4a observation: on `flush_ex1` (raise_excp at EX2), the current 4a "full reset" policy squashes the SYSCALL's own ROB entry and ~2–4 in-flight EX2/WB entries prematurely. Harmless in shadow but breaks 4b's load-bearing retire path.

**Confirmed 4b flush policy:**
- Preserve entries in EX2 and WB stages (they will retire cleanly).
- Invalidate only entries in EX1 (and RS — always 0 under passthrough).
- `new_tail = youngest_preserved_rob_id + 1`, where `youngest_preserved_rob_id` is the youngest rob_id currently in EX2 or WB (priority: EX2_b > EX2_a > WB_b > WB_a). Computed in `core.v` and passed to `rob.v` as `flush_preserve_high_id`.
- Wrap-safe kill range check per entry: `(i[4:0] - preserve) != 0 && (i[4:0] - preserve) < (tail[4:0] - preserve)` using 5-bit unsigned modular arithmetic.
- Wrap-safe new tail: `head + {1'b0, (preserve - head[4:0] + 1)}` — 6-bit add, wrap bit auto-managed.
- Gate `alloc_a_v` / `alloc_b_v` on `!flush_ex1` (prevent ghost alloc on flush cycle).
- **Retire policy**: retire fires for `valid && (done || same-cycle-completion-bypass)`, regardless of `have_excp`. Downstream (`rf_we`, rename `cmt_fire`) gates on `!have_excp` to preserve baseline arch RF write semantics. Under in-order execution the SYSCALL retires cleanly but does no arch RF write.
- **Same-cycle retire bypass**: if the head entry's rob_id matches the current cycle's `cmp_a_valid`/`cmp_b_valid` completion, retire fires this cycle using bypass values — preserves baseline timing (arch RF NBA fires same cycle as it would under Stage 3b, no 1-cycle drift).

**KNOWN EDGE CASE (untested by func_lab3):** `flush_preserve_valid == 0` fallback path (full ROB reset). Reachable only if flush fires via `replay` with pipeline drained past WB. Not exercised by func_lab3's single terminal-SYSCALL flush. **REVISIT when func_lab14/15/19 or longer stress tests are wired.**

### Stage 6 prerequisite — coupling of flush-defer and store queue

**Full commit-deferred mispredict/exception recovery requires a Store Queue (SQ) to buffer wrong-path stores until they're confirmed non-speculative at ROB commit.** Without SQ, a mispredicted branch whose wrong-path fetches include a store would cause the store to execute at EX1 (writing dcache) before the mispredict resolves — corrupting memory.

Baseline handles this via `mem_cancel = raise_excp || replay || ex1_a_br_mistaken_long`, which cancels the store operation at LSU issue time on immediate mispredict/exception. This mechanism relies on IMMEDIATE flush at EX1.

Consequence for the stage roadmap:
- **Stage 4c (minimum viable — this stage):** Only CSR-update delivery is deferred to commit. All flush-triggering paths (`flush_ex1`, `flush_ibuf`, `mem_cancel`) remain immediate. Walk-back signal computed and ROB `br_mispred`/`br_actual_target` fields propagated as infrastructure, but not load-bearing for flush.
- **Stage 4d (OoO issue):** OoO safety hinges on ROB-ordered commit (already in place from 4b) and precise CSR update at commit (4c). Register-file writes are safe because arch RF sources from ROB retire. Store safety still depends on immediate `mem_cancel` at EX1.
- **Stage 6 (SQ + LSQ):** Once SQ buffers stores until commit, `mem_cancel` can be removed and flushes can be fully deferred to walk-back at commit. Only then does the "unified walk-back path" from the Stage 4 planning notes become fully load-bearing for mispredict as well as exception.

**Important context for whoever picks up Stage 4d and Stage 6**: the two are more tightly coupled than the original 4a→4b→4c→4d breakdown suggested. Stage 4d can proceed with immediate mispredict flush safely (in-order commit via ROB is what makes OoO issue safe for register writes, and store safety is orthogonal). But truly moving mispredict recovery to commit MUST wait for Stage 6's SQ.


- **DIFFTEST verdict: clean pass** ("END by Syscall" + "HIT GOOD TRAP" from NEMU, no `Both Error`, no `different at pc` warnings).

The "81 test points" figure elsewhere refers to the `.S` file count in `func_lab3/inst/`; only 20 of them are enabled by the compile-time `TEST1..TEST9` guards. All Stage 2–5 gates use this 20-point suite.

**DIFFTEST tap map (see mycpu_top.v):**
- `Dretire*`, `DifftestDelayBundle_DifftestInstrCommit*`, `DifftestDelayBundle_DifftestWen/Wdest/Wdata_*`: 1-cycle-delayed regs on `WB_a/b_*`.
- `DaRAT_val_0..30`: live read of `core_0.u_regfile.rf[1..31]`.
- `DifftestBundle_DifftestCSRRegState*`: live read of `core_0.u_csr.<REG>`.
- `DifftestDelayBundle_DifftestExcpEvent*`: 1-cycle-delayed regs on `raise_excp`, `ex2_excp_type`, `ex2_excp_pc`, `interrupt`. **The 1-cycle delay is critical**: without it, DIFFTEST's `proxy->exec(1)` steps NEMU past the SYSCALL at the same posedge where the DUT's csr.v NBA queues ERA/ESTAT updates — CSR read on that posedge sees pre-update values, causing a spurious ERA/ecode mismatch at test end. Fixed by delaying ExcpEvent bundle so NEMU steps one cycle after the DUT's NBA has applied.

**TODO — deferred RS structure (from Stage 3b scope decision):**

- **Dedicated AGU/LSU port for RS_MEM** — DESIGN_OOO.md §4 originally specified three distinct RSes (RS_ALU0/RS_ALU1/RS_MEM) with independent issue ports. Stage 3b collapsed RS_MEM into slot A (shared LSU port) to match QHU's existing single-LSU-port pipeline structure without invasive re-plumbing. This limits potential memory/ALU parallelism. **Candidate for optimization pass after Stage 5/6 if time permits** — would require adding a second AGU/LSU port to the pipeline and restoring RS_MEM as a distinct issue queue.

**TODO — deferred DIFFTEST wiring (needed for func_lab14/15/19, NOT for func_lab3):**

The following Difftest signals are currently tied to zero in `mycpu_top.v`. They do not affect func_lab3 (which only exercises TEST1 = n1..n20, arithmetic/logical/branch instructions). They MUST be wired before running func_lab14/15/19 or the competition submission:

| Signal | What it does | Which tests need it |
|---|---|---|
| `DifftestDelayBundle_DifftestExcpEventEret` | Signals ERET commit distinctly from exception entry | any test that uses ERTN (all exception tests) |
| `DifftestDelayBundle_DifftestSkip_{0,1,2}` | Tells NEMU to skip this instruction (MMIO / uncached loads) | tests with uncached loads |
| `DifftestDelayBundle_DifftestIsTlbFill_{0,1,2}` + `TlbFillIndex_*` | TLB fill event to keep NEMU's TLB in sync | n60 (tlbfill), n70 (tlb_4MB), n71 (tlb_ex), n62..n68 (invtlb) |
| `DifftestDelayBundle_DifftestIsCount_{0,1,2}` + `Count_*` | RDCNTVL/VH_W hint — accept DUT's timer value | n49 (ti_ex), n58 (rdcnt), n80 (ti_ex_wait) |
| `DifftestDelayBundle_DifftestCsrRstat_{0,1,2}` + `CsrData_*` | ESTAT read hint for CSR-read insts | most tests using CSRRD ESTAT |

These need to be wired before claiming full test coverage for competition submission, but not required to validate core OoO correctness in Stages 2–5.

---

## 1. Interface contract (unchanged)

From `core_top.sv`:
- **AXI3 master, 32-bit**: `ar*`/`r*`/`aw*`/`w*`/`b*` with 4-bit ID, 8-bit len, 3-bit size, 2-bit burst. One master port — arbitration between IF and MEM happens internally in `axi_bridge`.
- **Interrupts**: `intrpt[7:0]`.
- **Debug**: `break_point`, `infor_flag`, `reg_num[4:0]`, `ws_valid`, `rf_rdata[31:0]`.
- **Difftest retire bundle**: 3 commit slots (`DretireMask[2:0]`, `Dretire{Addr,Inst,Waddr,Wresult}_{0,1,2}`, `DretireWen[2:0]`, `DuniqueRetire[2:0]`).
- **Difftest GPR snapshot**: `DaRAT_val_0..30` (31 architectural GPRs, r0 hardwired 0).
- **Difftest CSR bundle**: 27 CSR state wires.
- **Debug wb ports**: `debug{0,1,2}_wb_{pc,rf_wen,rf_wnum,rf_wdata,inst}`.

Design width therefore accepts up to **3-way commit**, but this redesign uses **2-way commit**; slot 2 is tied to zero.

---

## 2. Top-level pipeline (2-way, OoO)

```
IF1  IF2   ID/RN      DISP        ISSUE           EX          COMPLETE     COMMIT
+--+ +--+ +--+  +--+  +-------+   +-----+   +-------------+   +---------+  +----+
|PC|→|I$|→|Al|→|Dec|→|RAT+FL |→ |RS_A |→ ALU0 ─┐            → |ROB write|→|CMT|
|BP|                 |Rename |   |RS_M |→ ALU1 ─┼─ CDB ─────→ |          |  |RAT|
+--+                 +-------+   |RS_MD|→ AGU ──┤              +---------+  |FL |
                                 +-----+   MUL/DIV─┘                        +---+
                                            LSU  (LSQ)
```

- **Fetch width**: 2 insts/cycle (8-byte aligned group from I$ line).
- **Dispatch/rename width**: 2 insts/cycle into ROB and RS.
- **Issue width**: 2 (ALU0 + ALU1/AGU shared; MUL/DIV shares ALU1 slot but takes multiple cycles; LSU is its own port).
- **Commit width**: 2 insts/cycle from ROB head.
- **Retire slots exposed to Difftest**: 2 (slots 0,1), slot 2 forced to 0.

---

## 3. Register renaming

### 3.1 Physical register file
- **Size**: 64 physical regs (PRF), 6-bit tag `p[5:0]`. r0 (arch 0) is not renamed — always zero.
- **Rationale**: 32 architectural + ~32 in-flight, matched to ROB=32.
- **Ports**: 4 read (2 issue slots × 2 srcs) + 2 write (2 completion ports from EX). Single-cycle read; write-back is 1-cycle.

### 3.2 Rename Alias Tables — two RATs
- **s-RAT (speculative / front-end)**: 32 × 6-bit. Updated at DISPATCH with newly-allocated physical dest. Used for source lookup at dispatch.
- **a-RAT (architectural / retirement)**: 32 × 6-bit. Updated at COMMIT. This is the "gold" mapping. On exception rollback, s-RAT ← a-RAT (single-cycle copy of 32 × 6-bit = 192 bits).

### 3.3 Free list
- **Storage**: 32-entry circular queue of "free physical regs" (initial content = p32..p63). Head/tail pointers 5-bit, wrap-bit for full/empty.
- **Alloc**: at dispatch, pop up to 2. Stall dispatch if free list has fewer entries than needed.
- **Release**: at commit, if the committed insn had an arch dest, push back the *previously* mapped physical reg (the one that was in a-RAT before this commit overwrites it).
- **Recovery**: on mispredict rollback via ROB (see §5.4), free-list head restored from a checkpoint captured at that branch's dispatch. On exception, the safer path: walk ROB from tail toward the faulting insn, push each squashed insn's newly-allocated dest back to the free list, then s-RAT ← a-RAT.

### 3.4 Dual-slot rename in one cycle
- Slot0 sources read s-RAT unmodified.
- Slot1 sources: if slot1.src == slot0.arch_dest, forward slot0's new tag; else read s-RAT.
- Slot1 dest allocates the *second* free-list entry.
- WAW between slot0 and slot1 with same arch dest: both allocate physical regs; slot1's tag wins in s-RAT; slot0's freed at slot1's commit.

---

## 4. Reservation stations

Distributed, small, one issue port each:

| RS | Depth | Feeds | Notes |
|---|---|---|---|
| `RS_ALU0` | 8 | ALU0 | All arith/logic/shift/branch resolve |
| `RS_ALU1` | 8 | ALU1 | Second ALU; also handles MUL/DIV dispatch |
| `RS_MEM`  | 8 | AGU→LSU | Load/store address-gen + LSQ interface |

Total 24 RS entries. Each entry:
```
{ valid, rob_id[4:0], op[7:0], p_dst[5:0], has_dst,
  src1_tag[5:0], src1_ready, src1_val[31:0],
  src2_tag[5:0], src2_ready, src2_val[31:0],
  imm[31:0], flags, pc[31:0] }
```

### 4.1 Wakeup / select
- **Wakeup**: 2 completion tags (`p_dst_0`, `p_dst_1`) broadcast per cycle to every RS entry; entry's `srcN_ready` sets when `srcN_tag` matches an incoming tag. Val also captured on match (bypass PRF read for the just-completed value).
- **Select**: per-RS, oldest-ready-first (age matrix or an entry-alloc-timestamp comparator). For 8-entry RS this is a 3-level tree of ready-AND-oldest priority encoders — fits in one cycle at target clock.
- **Fast wakeup path**: back-to-back dependent single-cycle ops. Producer's tag broadcast in the same cycle it enters EX; consumer sees ready, issues next cycle. No wakeup stall for 1-cycle ALU ops.

### 4.2 Non-pipelined units (MUL, DIV)
- MUL: 3-cycle, pipelined. Occupies ALU1 issue slot but blocks its writeback port for 1 cycle at cycle 3.
- DIV: 32-cycle iterative, non-pipelined. Held in a small dedicated FU; RS_ALU1 issues to it and does not issue another op to DIV until it completes.

### 4.3 Dispatch stalls
- Any of: ROB full, free list < needed, target RS full → dispatch stall (holds slot0 first, then slot1).

---

## 5. Reorder Buffer

### 5.1 Layout
- **Size**: 32 entries, 5-bit tag `rob_id[4:0]`.
- **Format**:
  ```
  { valid, ready, has_dst, p_dst[5:0], a_dst[4:0], p_prev_dst[5:0],
    pc[31:0], is_branch, br_pred_taken, br_actual_taken, br_target[31:0],
    is_store, is_load, is_csr, is_syscall, is_eret, is_unique,
    excp_valid, excp_type[5:0], excp_addr[31:0] }
  ```
- **Pointers**: `alloc_ptr`, `commit_ptr`, 5-bit + wrap. `alloc_ptr - commit_ptr` gives occupancy.

### 5.2 Dispatch (write)
- Up to 2 entries allocated per cycle. Both share the same cycle's checkpoint if either is a branch.
- `ready=0` at alloc. Set to 1 by CDB when EX completes and returns the value.

### 5.3 Commit (read)
- Up to 2 entries retired per cycle, in order, from `commit_ptr`.
- Retire iff `ready=1`, no excp, and (for slot2) slot1 also retirable in same cycle.
- On retire:
  - Update a-RAT: `a_rat[a_dst] ← p_dst`.
  - Push `p_prev_dst` to free list (or, for slot pair, push both).
  - Update Difftest retire bundle (slot0, slot1 → `Dretire*_0/1`), slot2 wires forced 0.
  - Update `debug{0,1}_wb_*` from retire slot0/1.
  - Store commits: signal SQ to drain to L1D.
  - CSR/ERET/SYSCALL: force `is_unique=1` at dispatch → commits alone in its cycle to avoid ordering issues.

### 5.4 Rollback protocol
Three trigger classes:

**A. Branch mispredict (fast path)**
- Detected at EX stage of a branch. Branch's ROB entry marks `br_actual_taken` and `br_target`.
- Front-end already may have fetched wrong-path insts. On resolution:
  1. Squash all ROB entries with `rob_id` newer than the branch.
  2. Squash RS entries newer than the branch (each RS entry tags its ROB id; compare against branch id).
  3. Restore s-RAT and free-list head from the **checkpoint** taken at branch dispatch. Checkpoints stored in a small stack: 4 slots. If checkpoint stack full, dispatch of the 5th outstanding branch stalls. (This is a well-known limitation of small-checkpoint machines; 4 is enough for typical code.)
  4. Redirect PC to correct target; flush IF1/IF2/ID.
- 1-cycle recovery from the checkpoint copy; front-end refill takes I$ latency.

**B. Exception (slow path)**
- Detected at any EX; recorded in ROB entry.
- Not acted on until that entry reaches the ROB head (precise). At that point:
  1. Squash all newer ROB entries.
  2. Squash all RS entries.
  3. **Walk-back**: for each squashed ROB entry with `has_dst=1`, push its `p_dst` back to the free list.
  4. s-RAT ← a-RAT (single-cycle 32×6 copy).
  5. CSR update, EENTRY jump, front-end redirect.
- Walk-back can be pipelined 2 per cycle to match dispatch width; worst case 16 cycles for a full ROB. Acceptable — exceptions are rare.

**C. Store-load ordering violation (Stage 6, LSQ replay)**
- Same protocol as A, but checkpoint taken at load dispatch instead of branch; or equivalent — a full flush of everything younger than the offending load is acceptable at Stage 6's disambiguation policy.

### 5.5 Interaction with debug/Difftest
- Retire order to Difftest is strictly `commit_ptr` order. Two commit slots per cycle map to `Dretire*_0` and `Dretire*_1`. Slot 2 tied to 0.
- CSR/store/load event bundles fire from the committing ROB entry, not from EX — this preserves precise commit-time visibility even for OoO-executed instructions.

---

## 6. Dual-issue front-end

### 6.1 Fetch alignment
- Fetch group size: 8 bytes (2 × 32-bit insts).
- PC is 4-byte aligned always. Fetch group is `{PC[31:3], 3'b000}` when PC[2]=0, and `{PC[31:3]+1, 3'b000}` when PC[2]=1 — in the latter case only 1 valid insn returned this cycle (the upper 4 bytes of the previous line). This is the "unaligned fetch" case.
- I$ line size assumed 32 B (typical). Cross-line fetch: when the second insn of a group would fall in the *next* cache line, hold slot1 invalid, advance PC only 4 bytes. Slot1 fetched next cycle. Simple; loses 1 slot at line boundary — negligible for 32-B lines (~1 in 8 groups).

### 6.2 Branch prediction (Stage 5 baseline; Stage 6 upgrade)
- **Stage 5**: keep the existing BTB (if any) or use a 128-entry direct-mapped BTB with 1-bit taken/not-taken. Predict at IF1 using the fetch-group PC. If both slot0 and slot1 are branches, predict slot0 only; if slot0 is taken, slot1 is squashed.
- **Stage 6**: upgrade to gshare (256-entry PHT, 2-bit saturating counter, 8-bit global history XOR PC). Optional TAGE if time permits.
- RAS (return-address stack) 8-entry, updated at rename dispatch of BL/JIRL-return.

### 6.3 Structural conflicts at decode
Dual-decode must reject certain 2-inst groups and only forward slot0:
- Slot1 is CSR read/write.
- Slot1 is IDLE / ERET / SYSCALL / BREAK / TLB op / CACOP.
- Both slots are stores (only 1 AGU per cycle in Stage 5; slot1 held).
- Both slots need MUL or DIV (only 1 issue slot to that FU).
- Slot0 is a taken branch (slot1 speculative; not necessarily rejected, but branch-in-slot0 constrains predictor).

`is_unique` flag propagates to ROB; unique instructions dispatch alone.

### 6.4 Instruction buffer
- 8-entry ibuf between IF2 and ID/RN, sized to cover one full I$ miss latency without stalling rename.
- Head/tail 3-bit + wrap; refills 2 per cycle from IF2; drains 2 per cycle to ID/RN.

---

## 7. Load/Store Queue

### 7.1 Stage 4 policy (safe / in-order)
- **SQ**: 8 entries, in-order alloc at dispatch, in-order drain to L1D at commit.
- **LQ**: 8 entries, alloc at dispatch, execution allowed when address is ready **AND** no older store in SQ has an unresolved address.
- On load exec:
  - Search SQ for older stores with same (aligned) address. If hit → forward store data (byte-mask-aware).
  - If no hit → issue to L1D via LSU port.
- This policy is conservative but correct; no store-load ordering violations possible.

### 7.2 Stage 6 upgrade (speculative loads)
- Loads may execute past older stores with unresolved addresses.
- When a store's address resolves, LSQ checks all younger loads that already executed: if any has an overlapping address → mark that load's ROB entry with `excp_valid=1`, `excp_type=REPLAY`, causing rollback at commit.
- Alternatively: a lightweight predictor (store-set) can gate speculation for known-conflicting loads.

### 7.3 Alignment / uncached
- Unaligned access: split into two AXI transactions or raise ALE — pick the existing baseline's policy (need to inspect the restored `lsu.v` before finalizing).
- Uncached (per DMW config): bypass L1D; issue directly to AXI. LSU serializes uncached with the SQ.

---

## 8. Sizing summary

| Structure | Depth | Width | Notes |
|---|---|---|---|
| PRF | 64 | 32 bits | 4R/2W |
| s-RAT | 32 | 6 bits | 4R (2×2 srcs) + 2W |
| a-RAT | 32 | 6 bits | 2R (rollback broadcast) + 2W |
| Free list | 32 | 6 bits | pop 2, push 2 |
| ROB | 32 | ~180 bits | alloc 2, retire 2, complete 2 |
| RS_ALU0 | 8 | ~140 bits | issue 1 |
| RS_ALU1 | 8 | ~140 bits | issue 1 (also feeds MUL/DIV) |
| RS_MEM  | 8 | ~140 bits | issue 1 → AGU/LSU |
| SQ | 8 | ~80 bits | in-order |
| LQ | 8 | ~80 bits | in-order alloc |
| BTB | 128 | valid+tag+target+bit | direct-mapped |
| Checkpoint stack | 4 | 32×6 + 5 bits | one per in-flight branch |

Approx BRAM footprint: PRF ≈ 1 × 36Kb, ROB ≈ 6-8 distributed RAMs, RATs in LUT-RAM. Comfortable for Artyx-7/Kintex-7 boards.

---

## 9. Verification gates per stage

| Stage | Gate | Debug hook |
|---|---|---|
| 2 (rename) | func pass count == baseline exactly | `a-RAT` values dumped via existing `DaRAT_val_*` wires — same values across cycles as baseline PRF read |
| 3 (RS + OoO issue) | func pass count == baseline exactly | Retire order to Difftest still in-order; ROB not yet — sim needs a stand-in in-order commit list |
| 4 (ROB + rollback) | func pass count == baseline; adds precise-exception func tests (n27..n32 arithmetic/div for overflow, n37..n39 CSR/excp, n80 timer irq) | Difftest ExcpEvent bundle |
| 5 (dual-issue) | func pass; performance test cycle count lower than baseline | Retire IPC counter |
| 6 (LSQ/BP) | func pass; performance improved further | LSQ replay counter |

Every stage runs against the restored baseline's exact func pass count. If baseline is `N/81` on `func_lab3`, every stage's gate is `≥ N/81`.

---

## 10. Files to be added/modified (Stage 2 preview)

For Stage 2 (rename only, in-order execute retained):

- **New**: `rename.v` (RAT + free list + dual-slot rename combinational logic).
- **New**: `prf.v` (physical register file, 64×32).
- **Modified**: `id_stage.v` — insert rename stage between decode and issue; source operands become physical tags fed to a small "read PRF" stage.
- **Modified**: `exe_stage.v`, `mem_stage.v`, `wb_stage.v` — carry `p_dst`, `p_prev_dst` through the pipeline.
- **Modified**: `regfile.v` — replace 32-reg arch RF with a-RAT-indexed view of PRF for Difftest, OR keep arch RF in parallel updated at commit and route `DaRAT_val_*` from it.
- **Modified**: `mycpu_top.v` — plumb new rename signals.

Stage 2 does NOT introduce OoO issue or ROB. It's a pure renamer sitting in front of an in-order pipeline — it must be a functional no-op vs. baseline, and that's the gate.

---

## 11. Open questions for you

1. **Baseline restoration**: how do I get the in-order files back? Options I can see — (a) `git submodule update` inside `chiplab/` (the entry `160000 commit aa3bde1f... IP/myCPU` in `git ls-tree` suggests myCPU is a submodule that isn't checked out); (b) restore from `hc-core/` which is a similar in-order design; (c) restore from a zip you have locally.
2. **Func-suite reference**: which lab is the 58-point suite? `func_lab3` has 81 tests, not 58. `func_lab14/15/19` have their own counts. Please pinpoint.
3. **Retire width**: the debug/Difftest interface exposes 3 slots. Do you want me to design for 3-way retire, or keep 2-way with slot 2 tied to 0? (2-way is much simpler and matches "dual-issue" wording. I recommend 2.)
4. **FPGA target**: is this for a specific board (nscscc-team, thinpad, etc.)? Sizing above assumes ~7-series Xilinx; a smaller board (Artix XC7A35T) may need PRF=48, ROB=24.

Once you answer 1–4 and approve sections 2–8, Stage 2 can begin.
