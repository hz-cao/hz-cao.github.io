set script_dir [file dirname [file normalize [info script]]]
set impl_dir [file join $script_dir "build/perf/project/loongson_perf.runs/impl_1"]
set generated_script [file join $impl_dir "soc_top.tcl"]

if {![file exists $generated_script]} {
    error "Generated implementation script does not exist: $generated_script"
}

set_param general.maxThreads 1
cd $impl_dir
source $generated_script
puts "SINGLE_PROCESS_IMPLEMENTATION_DCP=[file join $impl_dir soc_top_placed.dcp]"
exit 0
