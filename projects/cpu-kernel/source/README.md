# LoongArch32 Out-of-Order CPU on FPGA

[![LoongArch32 CPU architecture cover](assets/cpu_kernel_cover.png)](assets/cpu_kernel.pdf)

## FPGA board test evidence

The CPU has been programmed onto the FPGA board through the Xilinx JTAG interface. The functional board test reaches the expected `3A 00 00 3A` display result:

[![FPGA board functional test showing 3A](../evidence/functional/functional-3a.jpg)](../evidence/functional/functional-3a.jpg)

The complete set of twenty performance-test pairs is documented in [`evidence/README.md`](../evidence/README.md). Files ending in `-red` record the progress marker for a test item; the matching numbered file records the score shown on the board.
+
### Performance test photos

The gallery below shows all twenty performance-test pairs directly in this README. Each row is one test item: the left photo is the progress marker and the right photo is the corresponding score.

<table>
<tr><th>Item</th><th>Progress marker (`-red`)</th><th>Board score</th></tr>
<tr>
  <td>1</td>
  <td><a href="../evidence/performance/1-red.jpg"><img src="../evidence/performance/1-red.jpg" alt="Performance test item 1 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/1.jpg"><img src="../evidence/performance/1.jpg" alt="Performance test item 1 score" width="320"></a></td>
</tr>
<tr>
  <td>2</td>
  <td><a href="../evidence/performance/2-red.jpg"><img src="../evidence/performance/2-red.jpg" alt="Performance test item 2 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/2.jpg"><img src="../evidence/performance/2.jpg" alt="Performance test item 2 score" width="320"></a></td>
</tr>
<tr>
  <td>3</td>
  <td><a href="../evidence/performance/3-red.jpg"><img src="../evidence/performance/3-red.jpg" alt="Performance test item 3 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/3.jpg"><img src="../evidence/performance/3.jpg" alt="Performance test item 3 score" width="320"></a></td>
</tr>
<tr>
  <td>4</td>
  <td><a href="../evidence/performance/4-red.jpg"><img src="../evidence/performance/4-red.jpg" alt="Performance test item 4 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/4.jpg"><img src="../evidence/performance/4.jpg" alt="Performance test item 4 score" width="320"></a></td>
</tr>
<tr>
  <td>5</td>
  <td><a href="../evidence/performance/5-red.jpg"><img src="../evidence/performance/5-red.jpg" alt="Performance test item 5 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/5.jpg"><img src="../evidence/performance/5.jpg" alt="Performance test item 5 score" width="320"></a></td>
</tr>
<tr>
  <td>6</td>
  <td><a href="../evidence/performance/6-red.jpg"><img src="../evidence/performance/6-red.jpg" alt="Performance test item 6 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/6.jpg"><img src="../evidence/performance/6.jpg" alt="Performance test item 6 score" width="320"></a></td>
</tr>
<tr>
  <td>7</td>
  <td><a href="../evidence/performance/7-red.jpg"><img src="../evidence/performance/7-red.jpg" alt="Performance test item 7 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/7.jpg"><img src="../evidence/performance/7.jpg" alt="Performance test item 7 score" width="320"></a></td>
</tr>
<tr>
  <td>8</td>
  <td><a href="../evidence/performance/8-red.jpg"><img src="../evidence/performance/8-red.jpg" alt="Performance test item 8 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/8.jpg"><img src="../evidence/performance/8.jpg" alt="Performance test item 8 score" width="320"></a></td>
</tr>
<tr>
  <td>9</td>
  <td><a href="../evidence/performance/9-red.jpg"><img src="../evidence/performance/9-red.jpg" alt="Performance test item 9 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/9.jpg"><img src="../evidence/performance/9.jpg" alt="Performance test item 9 score" width="320"></a></td>
</tr>
<tr>
  <td>10</td>
  <td><a href="../evidence/performance/10-red.jpg"><img src="../evidence/performance/10-red.jpg" alt="Performance test item 10 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/10.jpg"><img src="../evidence/performance/10.jpg" alt="Performance test item 10 score" width="320"></a></td>
</tr>
<tr>
  <td>11</td>
  <td><a href="../evidence/performance/11-red.jpg"><img src="../evidence/performance/11-red.jpg" alt="Performance test item 11 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/11.jpg"><img src="../evidence/performance/11.jpg" alt="Performance test item 11 score" width="320"></a></td>
</tr>
<tr>
  <td>12</td>
  <td><a href="../evidence/performance/12-red.jpg"><img src="../evidence/performance/12-red.jpg" alt="Performance test item 12 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/12.jpg"><img src="../evidence/performance/12.jpg" alt="Performance test item 12 score" width="320"></a></td>
</tr>
<tr>
  <td>13</td>
  <td><a href="../evidence/performance/13-red.jpg"><img src="../evidence/performance/13-red.jpg" alt="Performance test item 13 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/13.jpg"><img src="../evidence/performance/13.jpg" alt="Performance test item 13 score" width="320"></a></td>
</tr>
<tr>
  <td>14</td>
  <td><a href="../evidence/performance/14-red.jpg"><img src="../evidence/performance/14-red.jpg" alt="Performance test item 14 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/14.jpg"><img src="../evidence/performance/14.jpg" alt="Performance test item 14 score" width="320"></a></td>
</tr>
<tr>
  <td>15</td>
  <td><a href="../evidence/performance/15-red.jpg"><img src="../evidence/performance/15-red.jpg" alt="Performance test item 15 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/15.jpg"><img src="../evidence/performance/15.jpg" alt="Performance test item 15 score" width="320"></a></td>
</tr>
<tr>
  <td>16</td>
  <td><a href="../evidence/performance/16-red.jpg"><img src="../evidence/performance/16-red.jpg" alt="Performance test item 16 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/16.jpg"><img src="../evidence/performance/16.jpg" alt="Performance test item 16 score" width="320"></a></td>
</tr>
<tr>
  <td>17</td>
  <td><a href="../evidence/performance/17-red.jpg"><img src="../evidence/performance/17-red.jpg" alt="Performance test item 17 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/17.jpg"><img src="../evidence/performance/17.jpg" alt="Performance test item 17 score" width="320"></a></td>
</tr>
<tr>
  <td>18</td>
  <td><a href="../evidence/performance/18-red.jpg"><img src="../evidence/performance/18-red.jpg" alt="Performance test item 18 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/18.jpg"><img src="../evidence/performance/18.jpg" alt="Performance test item 18 score" width="320"></a></td>
</tr>
<tr>
  <td>19</td>
  <td><a href="../evidence/performance/19-red.jpg"><img src="../evidence/performance/19-red.jpg" alt="Performance test item 19 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/19.jpg"><img src="../evidence/performance/19.jpg" alt="Performance test item 19 score" width="320"></a></td>
</tr>
<tr>
  <td>20</td>
  <td><a href="../evidence/performance/20-red.jpg"><img src="../evidence/performance/20-red.jpg" alt="Performance test item 20 progress marker" width="320"></a></td>
  <td><a href="../evidence/performance/20.jpg"><img src="../evidence/performance/20.jpg" alt="Performance test item 20 score" width="320"></a></td>
</tr>
</table>


本目录基于 ChipLab 项目实践基线提交 `a0205122a7186144dcfd73a836ff9b436638b1da`，目标环境为 Windows、Vivado 2023.2、`xc7a200tfbg676-2`。

- 完整构建、仿真、烧板和结果说明：[`README_SUBMISSION.md`](README_SUBMISSION.md)
- 项目开发环境说明：[`nscscc_readme.md`](nscscc_readme.md)
- CPU RTL：[`IP/myCPU`](IP/myCPU)
- 最终 bit/ltx：[`fpga/nscscc-team/run_vivado/bitstreams`](fpga/nscscc-team/run_vivado/bitstreams)
- 最终报告和板测记录：[`reports/final`](reports/final)
- 板级实测照片与测试说明：[`evidence/README.md`](evidence/README.md)

当前默认 `soc_config.vh` 为性能测试模式；所有构建脚本都会按 `func`/`perf` 自动切换，不需要手工改宏。
