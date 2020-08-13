
#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

#change working directory to script file directory
cd [getScriptDirectory]
#set ip_repo_path to script dir
set masterDir [getScriptDirectory]
set rootDir ..\/

# PACKAGE RISCV_AXI_IP
source $rootDir\/RISCV_w_cache\/RISCV_w_cache_AXI\/tcl_script\/RISCV_w_cache_AXI_ip.tcl

cd $masterDir
# Make block design
source RISCV_AXI_system.tcl
