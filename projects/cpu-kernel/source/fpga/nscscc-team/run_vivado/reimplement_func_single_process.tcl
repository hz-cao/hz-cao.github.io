set script_dir [file dirname [file normalize [info script]]]
set impl_dir [file join $script_dir "build/func/project/loongson_func.runs/impl_1"]
set generated_script [file join $impl_dir "soc_top.tcl"]

if {![file exists $generated_script]} {
    error "Generated implementation script does not exist: $generated_script"
}

set_param general.maxThreads 1
cd $impl_dir
source $generated_script
set placed_dcp [file join $impl_dir "soc_top_placed.dcp"]
if {![file exists $placed_dcp]} {
    error "Placed checkpoint was not generated: $placed_dcp"
}
puts "FUNC_SINGLE_PROCESS_PLACED_DCP=$placed_dcp"
exit 0
