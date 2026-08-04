set script_dir [file dirname [file normalize [info script]]]
set package_root [file normalize [file join $script_dir "../../.."]]
set project_dir [get_property DIRECTORY [current_project]]
set simulation_program [file normalize [file join $project_dir "../inst_data.bin"]]

set benchmarks {
    bitcount bubble_sort coremark crc32 dhrystone quick_sort select_sort sha
    stream_copy stringsearch fireye_A0 fireye_B2 fireye_C0 fireye_D1
    fireye_I2 inner_product lookup_table loop_induction my_memcmp
    minmax_sequence
}

foreach benchmark $benchmarks {
    set source_program [file join $package_root \
        "software/examples/nscscc_perf/obj/$benchmark/inst_data.bin"]
    if {![file exists $source_program]} {
        error "Performance test program does not exist: $source_program"
    }
    puts "RUNNING_BENCHMARK=$benchmark"
    file copy -force $source_program $simulation_program
    restart
    run all
}
