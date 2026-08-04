set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir "build/perf/project/loongson_perf.xpr"]

open_project $project_file
set clk_ip [get_ips clk_pll]
puts "CPU_CLOCK_REQUEST_BEFORE=[get_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_ip]"
set_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 32.000 $clk_ip
generate_target -force synthesis $clk_ip
generate_target -force implementation $clk_ip
reset_run clk_pll_synth_1
launch_runs clk_pll_synth_1 -jobs 1
wait_on_run clk_pll_synth_1
export_ip_user_files -of_objects $clk_ip -no_script -sync -force -quiet
puts "CPU_CLOCK_REQUEST_AFTER=[get_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_ip]"
puts "CPU_CLOCK_MMCM_MULT=[get_property CONFIG.MMCM_CLKFBOUT_MULT_F $clk_ip]"
puts "CPU_CLOCK_MMCM_DIVIDE=[get_property CONFIG.MMCM_CLKOUT0_DIVIDE_F $clk_ip]"
close_project
exit 0
