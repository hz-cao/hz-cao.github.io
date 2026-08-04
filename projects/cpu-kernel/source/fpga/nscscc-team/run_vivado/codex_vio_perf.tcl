set script_dir [file dirname [file normalize [info script]]]
set argv [list \
    [file join $script_dir "bitstreams/soc_top_perf.bit"] \
    [file join $script_dir "bitstreams/soc_top_perf.ltx"] \
    "perf"]
source [file join $script_dir "vio.tcl"]
