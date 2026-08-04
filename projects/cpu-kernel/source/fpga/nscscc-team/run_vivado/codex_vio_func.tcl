set script_dir [file dirname [file normalize [info script]]]
set argv [list \
    [file join $script_dir "bitstreams/soc_top_func.bit"] \
    [file join $script_dir "bitstreams/soc_top_func.ltx"] \
    "func"]
source [file join $script_dir "vio.tcl"]
