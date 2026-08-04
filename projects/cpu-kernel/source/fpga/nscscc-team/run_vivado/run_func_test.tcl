set script_dir [file dirname [file normalize [info script]]]
set package_root [file normalize [file join $script_dir "../../.."]]
set project_dir [get_property DIRECTORY [current_project]]
set simulation_program [file normalize [file join $project_dir "../inst_data.bin"]]
set source_program [file join $package_root "software/examples/nscscc_func/obj/main.bin"]

if {![file exists $source_program]} {
    error "Function test program does not exist: $source_program"
}
file copy -force $source_program $simulation_program
restart
run all
