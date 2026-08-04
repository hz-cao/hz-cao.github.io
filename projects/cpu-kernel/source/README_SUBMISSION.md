# 我们自己动手实践的一个 CPU：提交与复现说明

## 基线和环境

- ChipLab 基线：`a0205122a7186144dcfd73a836ff9b436638b1da`
- 系统：Windows 64 位
- Vivado：2023.2
- FPGA：`xc7a200tfbg676-2`
- 顶层：`soc_top`
- CPU 实际主频：`32.000 MHz`
- 工程根目录：`D:\version-2`

启动 Vivado 前必须在同一个 PowerShell 设置：

```powershell
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
```

否则本机的 `vivado.bat` 可能静默退出。

## CPU 架构

当前 CPU 是 LoongArch32 Reduced 兼容的双发射乱序核，主要结构如下：

- 双发射、双执行、最多双退休。
- 32 项 ROB、两组 8 项保留站、64 项物理寄存器文件。
- PRF ready scoreboard、双写回唤醒、oldest-ready Wakeup-Select。
- 256 项 2-way BTB、256 项 BHT、512 项 2-bit 饱和 PHT、8-bit 历史、16 项 RAS。
- 32 项 ROB 索引的 Load/Store ordering tracker，允许 load 越过地址未确定的 older store 推测执行。
- 地址冲突时精确 replay；32 路冲突检测使用 5 级平衡树。
- 低冲突时保持投机；累计第 4 次 ordering violation 后自适应串行化，避免高冲突程序反复 replay。
- 分支错误恢复、精确异常、双退休提交和 RAT/free-list 恢复。

实现位置主要在 `IP/myCPU/core.v`、`rob.v`、`rename.v`、`rs.v`、`prf.v`、`pred.v`、`btb.v` 和 `mem_disambig.v`。

## 已验证结果

### 功能

- XSim：58/58 Functional Test Point PASS，0 fail。
- XSim 完成时间：约 `22,708,863.5 ns`。
- 实板 VIO：`0x3a00003a`，板上功能结果为 `3A`。
- 最终时序：WNS `+0.067 ns`，TNS `0`，WHS `+0.052 ns`，THS `0`。

### 性能

- allbench 实板连续测试：20/20 的 `correct_flag=1`。
- CoreMark 冷启动单测 `7C`：PASS，约 1100 ms，`num_data=0x00e37b56`。
- inner_product 冷启动单测 `6F`：PASS，约 1300 ms，`num_data=0x02797645`。
- 连续测试中的 SHA `77`：PASS，`soc_count=0x00858972`，`cpu_count=0x002aa268`。
- 最终时序：WNS `+0.003 ns`，TNS `0`，WHS `+0.054 ns`，THS `0`。
- 完整 20 项计数见 `reports/final/perf_vio.csv`，行顺序对应开关 `7E` 到 `6B`。

这些是当前板卡和当前测试镜像的实测结果，不把竞赛名次作为可验证结论。

## 最终烧录文件

功能测试必须成对使用：

```text
fpga/nscscc-team/run_vivado/bitstreams/soc_top_func.bit
fpga/nscscc-team/run_vivado/bitstreams/soc_top_func.ltx
```

性能测试必须成对使用：

```text
fpga/nscscc-team/run_vivado/bitstreams/soc_top_perf.bit
fpga/nscscc-team/run_vivado/bitstreams/soc_top_perf.ltx
```

不要混用不同版本的 bit 和 ltx。

## 功能仿真

在 PowerShell 中执行：

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
.\simulate.ps1 -Mode func
```

日志末尾应出现第 58 个功能点 PASS、`Test end!` 和 `----PASS!!!`。

性能单项仿真示例：

```powershell
.\simulate.ps1 -Mode perf -Benchmark coremark
.\simulate.ps1 -Mode perf -Benchmark inner_product
```

## 低内存重新生成性能 bit

每条 Vivado 命令结束后再执行下一条，不并行运行综合、实现或仿真：

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
$vivado = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'

& $vivado -mode batch -log build_perf_safe.log -source build_perf_safe_to_place.tcl
& $vivado -mode batch -log place_perf_single.log -source reimplement_single_process.tcl
& $vivado -mode batch -log route_perf_safe.log -source route_perf_safe.tcl
& $vivado -mode batch -log postroute_perf.log -source postroute_perf_opt.tcl
```

`route_perf_safe.tcl` 在小幅负裕量时会返回非零，但会保留 `build/perf/routed_safe.dcp`；随后运行 post-route 脚本即可。最终脚本只有在 WNS/WHS 均非负时才生成性能 bit。

## 低内存重新生成功能 bit

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
$vivado = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'

& $vivado -mode batch -log build_func_safe.log -source build_func_safe_to_place.tcl
& $vivado -mode batch -log place_func_single.log -source reimplement_func_single_process.tcl
& $vivado -mode batch -log route_func_safe.log -source route_func_safe.tcl
& $vivado -mode batch -log postroute_func.log -source postroute_func_opt.tcl
```

脚本固定 `general.maxThreads=1`；项目生成、opt/place、route/post-route 分进程运行，适合本机 16 GB 内存。

可在另一个 PowerShell 给正在运行的 Vivado 降低优先级并启用保护：

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$p = Get-Process vivado | Sort-Object StartTime -Descending | Select-Object -First 1
$p.PriorityClass = 'BelowNormal'
.\monitor_vivado_resources.ps1 -VivadoPid $p.Id
```

保护器在空闲物理内存低于 1 GB、持续低于 1.5 GB、空闲虚拟内存低于 10 GB，或工具总工作集超过 10 GB 时停止 Vivado。

## 上板功能测试

板卡连接后，在 PowerShell 执行：

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
& 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat' -mode batch `
  -log board_func.log -source codex_vio_func.tcl
```

脚本会烧录功能 bit、加载 `software/examples/nscscc_func/obj/main.bin`、复位并读取 VIO。正确输出是 `3a00003a`。

## 上板性能测试

```powershell
cd D:\version-2\fpga\nscscc-team\run_vivado
$env:PROCESSOR_ARCHITECTURE = 'AMD64'
& 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat' -mode batch `
  -log board_perf.log -source codex_vio_perf.tcl
```

脚本会烧录性能 bit、加载 `software/examples/nscscc_perf/obj/allbench/inst_data.bin`，依次运行开关 `7E` 到 `6B`，结果写入 `perf_vio.csv`。应有 20 行数据，所有 `correct_flag` 都为 `1`，且两个计数均非零。

## 最终文件校验

```text
C7AAF1BBBEF3D0E7EC32BE3324BAA73747484F7B43BA804909DE9C71A65E4A76  soc_top_func.bit
18E8B86A3E42304E2C96AB92694F776AD61BD64EF80F2FBD9F2273E55565C1EB  soc_top_func.ltx
5CB72C5F7BFFA6C4D19D4576CAF1A0A42BDCA7E930CAC6EA708A8316C271DDA3  soc_top_perf.bit
18E8B86A3E42304E2C96AB92694F776AD61BD64EF80F2FBD9F2273E55565C1EB  soc_top_perf.ltx
```

最终时序、利用率、CSV 和板测日志归档在 `reports/final/`。
