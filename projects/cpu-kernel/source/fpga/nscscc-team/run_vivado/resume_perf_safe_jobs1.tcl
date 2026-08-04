set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir "build/perf/project/loongson_perf.xpr"]
set report_dir [file join $script_dir "build/perf/reports"]

if {![file exists $project_file]} {
    error "Performance project does not exist: $project_file"
}
set_param general.maxThreads 1
open_project $project_file

# Simulation projects also regenerate the shared IP output directories. Refresh
# the performance project's products before resetting its top-level run.
generate_target -force synthesis [get_ips]
foreach ip_name {clk_pll mig_axi_32} {
    set ip_obj [get_ips -quiet $ip_name]
    if {[llength $ip_obj] > 0} {
        generate_target -force implementation $ip_obj
    }
}
export_ip_user_files -of_objects [get_ips] -no_script -sync -force -quiet

# Reopen after regeneration so missing output products discovered during the
# first open are registered in the top-level compile order.
close_project
open_project $project_file
update_compile_order -fileset sources_1

foreach run [get_runs] {
    set status [get_property STATUS $run]
    puts "RUN_STATUS_BEFORE=[get_property NAME $run],$status"
    if {[string match "*Running*" $status] ||
        [string match "*ERROR*" $status] ||
        [string match "*Failed*" $status]} {
        catch {stop_runs $run}
        reset_run $run
    }
}

# Always rebuild the top-level design so a completed run from an older RTL
# revision can never be reused for the final bitstream.
set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
reset_run synth_1
launch_runs synth_1 -jobs 1
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "SAFE_SYNTH_STATUS=$synth_status"
if {![string match "*Complete*" $synth_status]} {
    exit 1
}

reset_property incremental_checkpoint [get_runs impl_1]
launch_runs impl_1 -to_step place_design -jobs 1
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "SAFE_PLACE_STATUS=$impl_status"
set placed_dcp [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1/soc_top_placed.dcp"]
if {![file exists $placed_dcp]} {
    exit 2
}

open_run impl_1
file mkdir $report_dir
report_timing_summary -delay_type max -report_unconstrained \
    -file [file join $report_dir "timing_summary_placed_registered.rpt"]
report_utilization -file [file join $report_dir "utilization_placed_registered.rpt"]
puts "SAFE_PLACED_DCP=$placed_dcp"
exit 0
