# 最终验证摘要

验证环境：Windows、Vivado 2023.2、`xc7a200tfbg676-2`，CPU 32.000 MHz。

| 项目 | 结果 |
| --- | --- |
| 功能 XSim | 58/58 PASS，0 fail |
| 功能实板 | `0x3a00003a`，显示 `3A` |
| 功能时序 | WNS `+0.067 ns`，WHS `+0.052 ns` |
| CoreMark 冷测 `7C` | PASS，`0x00e37b56` |
| inner_product 冷测 `6F` | PASS，`0x02797645` |
| 性能 allbench | 20/20，全部 `correct_flag=1` |
| 性能时序 | WNS `+0.003 ns`，WHS `+0.054 ns` |

原始结果：

- `reports/final/func_vio.csv`
- `reports/final/perf_vio.csv`
- `reports/final/timing_summary_func.rpt`
- `reports/final/timing_summary_perf.rpt`
- `reports/final/board_func_adaptive.log`
- `reports/final/board_perf_full_adaptive.log`

最终 bit/ltx 位于 `fpga/nscscc-team/run_vivado/bitstreams/`，SHA-256 见根目录 `README_SUBMISSION.md`。
