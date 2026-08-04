# 当前 CPU 架构框图绘制说明

这份说明对应当前工程中实际实例化的 `IP/myCPU/core.v` 和 `IP/myCPU/mycpu_top.v`。图的目标不是把每根 RTL 信号都画出来，而是准确表达模块边界、主数据通路、提交通路、预测恢复通路和缓存/AXI 通路。

## 一、推荐的总体版式

画布建议使用横向 16:10 或 A3 横向比例。沿水平方向放置 6 条流水线区域，用竖向虚线分隔：

1. `IF / Fetch`
2. `ID / Decode`
3. `Rename + Dispatch`
4. `Issue / Execute`
5. `MEM / Complete`
6. `WB / Commit`

AXI4 放在最上方，作为统一的外部存储器接口。I-cache、D-cache 分别位于前端和 LSU 旁边；MMU/TLB 可以放在图的右侧，用两条反馈线分别连接指令侧和数据侧。

建议使用三种线型：

- 实线箭头：正常的数据或控制流。
- 灰色虚线箭头：旁路、唤醒、预测更新、重定向、异常冲刷、提交回写。
- 粗线或带总线标签的箭头：AXI、cache line refill/writeback 等多比特总线。

## 二、必须绘制的组件及形状

### 1. 前端取指与预测

`PC`：使用普通实线圆角矩形，标注复位入口 `0x1c000000`。

`if_stage`：使用普通实线矩形，标注 `fetch / redirect / dual issue`。它负责发起 I-cache 请求、接收最多两条指令、处理取指异常，并根据预测结果生成下一取指地址。

`pred`：使用一个虚线圆角大框，内部再放 4 个小矩形：

- `BTB`：256 项、2 路组相联。
- `BHT`：256 项、8-bit 历史。
- `PHT`：512 项、2-bit 饱和计数器。
- `RAS`：16 项返回地址栈。

预测框的输入是 `fetch_pc_0/fetch_pc_1`，输出是两条指令的 `taken` 和目标地址。执行阶段发现分支错误时，必须画一条虚线回到 `pred`，表示 BTB/BHT/PHT/RAS 更新；同时画一条虚线回到 `PC/if_stage`，表示错误路径冲刷和重定向。

### 2. 指令地址翻译与 I-cache

`MMU-I`：普通矩形，标注 `addr_trans + TLB lookup`。它接收 `if_stage` 的虚拟页标记，向 I-cache 提供物理页标记、存储属性和异常状态。

`icache`：使用虚线圆角大框，内部画出：

- `data way 0`
- `data way 1`
- `tag way 0`
- `tag way 1`

当前实现是 2 路、128 组、32-byte cache line。I-cache 命中后把 64-bit 取指数据返回 `if_stage`；未命中时向 `axi_bridge` 发起 cache-line refill。I-cache 内部还存在预取路径，图中可以在大框底部加小字 `prefetch / refill`。

### 3. 取指到译码

`IF/ID regs`：窄矩形，表示取指结果进入流水线寄存器。

`ibuf`：普通矩形，表示指令缓冲和双发射打包/保持逻辑。它向后端输出 slot A 和 slot B 两条指令的 PC、操作类型、源寄存器、目标寄存器、立即数、分支和异常信息。

`id_stage A`、`id_stage B`：两个并列普通矩形，分别表示双发射的两个译码器。每个译码器输出：

- ALU、乘法、除法、访存、CSR、分支等操作类型；
- 源寄存器和目标寄存器；
- 立即数；
- 分支预测信息与实际分支类型；
- CSR/异常/LL-SC 等控制属性。

### 4. 架构寄存器、重命名和物理寄存器

`arch regfile`：普通矩形，标注 `4R / 2W committed architectural state`。它保存提交后的架构状态；当前后端的主要操作数读取路径使用 PRF 和旁路，不能把 arch regfile 画成唯一的执行源。

`rename`：普通矩形，标注 `s-RAT + a-RAT + free list`。当前实现使用 6-bit 物理寄存器编号，物理寄存器总数为 64 个，初始空闲表为物理寄存器 32 到 63。图中应画出：

- 译码结果进入 `rename`；
- `rename` 输出两个 slot 的物理源标签、物理目的标签和旧物理目的标签；
- ROB 提交结果回到 `rename`，用于更新 a-RAT、释放旧物理寄存器；
- 分支错误或异常从 `rename` 接收恢复/冲刷信号。

`PRF`：普通矩形，标注 `64 × 32-bit, 4R / 2W, ready bits`。PRF 接收物理源标签，输出操作数值和 ready 状态；执行结果写回 PRF。图中还应从 EX1、EX2、WB 画虚线旁路到 PRF/RS 的唤醒网络。

### 5. 发射队列与唤醒选择

`RS_ALU0` 和 `RS_ALU1`：使用两个虚线圆角大框，每个标注 `8 entries`。

- `RS_ALU0` 对应 slot A，并优先连接 EX1 A。
- `RS_ALU1` 对应 slot B，并优先连接 EX1 B。
- 每个 RS 保存 PC、指令、操作类型、物理标签、操作数值/ready、立即数、分支属性和 ROB ID。
- 两个 RS 都接收 EX1 A、EX1 B、WB A、WB B 的 wakeup 广播。
- RS 输出 ready/select/issue 信号到执行单元。

`wakeup / forwarding`：可画成 RS 下方的普通矩形或一条横向总线，标注 `EX1 A/B + WB A/B broadcasts`。这部分是当前乱序执行效果的关键，不应省略。

### 6. ROB 和内存相关性检查

`ROB`：使用虚线圆角大框，标注 `32 entries / 2-wide allocate / in-order retire`。必须画出三类接口：

- dispatch 时从 slot A/B 分配 ROB 项；
- EX/WB 完成时按 ROB ID 写入结果、异常和分支错误信息；
- ROB head 按程序顺序最多双发射退休。

当前 `core.v` 中 ROB 的退休输出已经用于驱动架构寄存器写回、rename 提交和旧物理寄存器释放，因此图中应从 `ROB retire` 回连到 `arch regfile` 和 `rename`。

`mem_disambig`：普通矩形，放在 ROB 和 LSU 之间，标注 `older-store check / speculative-load replay`。当前策略是：store 只能在 ROB head 执行；load 可以越过地址尚未确定的 older store；当 store 地址确定后，对年轻的 speculative load 做字节级比较，发现冲突则输出 ordering violation，触发 replay。

注意：当前 `core.v` 实际实例化的是 `mem_disambig`，不是独立的 `ooo_lsq`。不要把 `ooo_lsq` 画成当前运行中的 LSQ。

### 7. 执行单元

在 `Issue / Execute` 区域绘制以下矩形：

- `ALU A`：slot A 的整数/分支执行，标注 `branch resolve`。
- `ALU B`：slot B 的整数执行。
- `MUL A / MUL B`：两个乘法通路。
- `DIV`：单个除法通路。
- `LSU`：单个访存执行端口。

RS 的 issue 输出连接这些执行单元；执行结果统一进入 `EX2 / WB`。图中要特别标出：当前只有一个 LSU，两个发射槽不能在同一周期无约束地同时占用两个 memory port；除法和访存也受到调度限制。

### 8. LSU、数据地址翻译与 D-cache

`MMU-D`：普通矩形，标注 `addr_trans + TLB lookup`，位于 LSU 与 D-cache 之间或右下侧。

`dcache`：使用虚线圆角大框，内部画出：

- `data way 0`
- `data way 1`
- `tag way 0`
- `tag way 1`

当前实现同样是 2 路、128 组、32-byte cache line，并包含命中读写、dirty replacement、writeback、refill 和 CACOP 相关状态。LSU 的读写请求进入 D-cache；D-cache 的 miss、writeback 和 refill 请求进入 `axi_bridge`。

### 9. EX2/WB、提交和 CSR

`EX2 / WB`：普通矩形，表示 EX1 到 EX2、再到 WB 的流水寄存器和结果汇合点。它接收 ALU/MUL/DIV/LSU 的结果，并把结果、ROB ID、异常和分支恢复信息送给 ROB。

`ROB retire`：普通矩形或实线矩形，标注 `in-order commit`。它向：

- `arch regfile` 写入提交结果；
- `rename` 发送 commit 信息；
- `PRF`/wakeup 网络提供已完成结果；
- `if_stage` 发送分支恢复、异常和 replay 控制。

`CSR`：普通矩形，标注 `CSR / interrupt / exception`。它接收 EX2 slot A 的 CSR 访问和外部中断，输出异常目标地址、TLB/CACOP/LLbit 等控制信息。异常或中断路径必须用虚线回到 `if_stage/PC`。

### 10. MMU/TLB 总体框

可以在图的右侧再画一个虚线大框 `MMU / TLB`，内部标注：

- `32-entry TLB`；
- instruction-side lookup；
- data-side lookup；
- `addr_trans`；
- TLB search/read/write/invalidate。

`mmu.v` 中有 instruction side 和 data side 两个地址翻译接口；两者共享 `tlb_top`，并接受 CSR 提供的 DA/DATF/DATM/PLV/ASID/DMW 配置。该框需要分别用虚线连接 `if_stage` 和 `LSU`，不能只画成连接 I-cache 的单一路径。

### 11. AXI 桥和 SoC 接口

`axi_bridge`：放在图顶部，使用普通矩形，向上连接 `AXI4 / SoC memory`。它同时接收：

- I-cache 的 `inst_rd/inst_wr` 请求；
- D-cache 的 `data_rd/data_wr` 请求；

并把 AXI 返回数据分别送回 I-cache 和 D-cache。图中不要画成 CPU 直接连 AXI；准确关系是：

`core → icache/dcache → axi_bridge → AXI4`。

## 三、建议绘制的关键连接顺序

正常取指通路：

`PC → pred → if_stage → MMU-I → icache → if_stage → IF/ID regs → ibuf → id_stage A/B`

双发射后端通路：

`id_stage A/B → rename → PRF/arch regfile read + forwarding → RS_ALU0/RS_ALU1 → issue select → ALU/MUL/DIV/LSU → EX2/WB`

提交通路：

`EX2/WB → ROB completion → ROB head retire → arch regfile`

`ROB head retire → rename commit → a-RAT update + old physical register free`

结果唤醒通路：

`EX1 A/B + WB A/B → wakeup/forwarding → RS_ALU0/RS_ALU1`

访存通路：

`LSU → MMU-D → dcache → axi_bridge → AXI4`

I-cache miss 通路：

`icache miss/refill → axi_bridge → icache`

分支恢复通路：

`ALU A branch resolve → branch mispredict → flush/redirect → PC/if_stage`

同时：

`branch resolve → pred update`

异常/中断通路：

`CSR / LSU exception → exception target → PC/if_stage`

内存顺序冲突通路：

`mem_disambig ordering violation → replay_target → PC/if_stage + pipeline flush`

## 四、当前版本中不要画错的内容

1. 不要画成单发射；当前 IF、译码、RS、ROB 和退休均有 A/B 双槽结构，但执行资源并非所有单元都双份。
2. 不要画独立的 `ooo_lsq`、`ooo_issue_queue`、`ooo_rob`、`ooo_rat` 为当前活动后端；当前 `core.v` 实际使用的是 `rename`、`prf`、两个 `rs`、`rob` 和 `mem_disambig`。
3. 不要把 arch regfile 画成唯一的操作数来源；当前物理标签和 PRF ready 位参与源操作数读取，EX1/EX2/WB 还有多级旁路。
4. 不要画两个独立 LSU；当前只有一个 `lsu u_lsu` 实例。
5. 不要把 ROB 画成只用于统计的旁路模块；按当前 `core.v` 的实际连接，ROB retire 已参与 arch RF 写回和 rename commit。
6. 不要把 I-cache、D-cache 直接连接到外部 AXI；两者都经过 `axi_bridge`。

