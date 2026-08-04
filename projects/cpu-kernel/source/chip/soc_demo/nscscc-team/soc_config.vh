// Select exactly one board test mode.
`define RUN_FUNC_TEST
// `define RUN_PERF_TEST

// For performance test only: keep RUN_PERF_NO_DELAY disabled for board score.
`ifdef RUN_PERF_TEST
// `define RUN_PERF_NO_DELAY
`endif

// For simulation:
// 1. SIMU_USE_PLL=1 uses PLL-generated clocks and is slow.
// 2. SIMU_USE_PLL=0 assigns cpu_clk/sys_clk from the simulation clock.
`define SIMU_USE_PLL 0
`define SIMU_USE_DDR 0
