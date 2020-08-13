#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

# change working directory to script file directory
cd [getScriptDirectory]
# set result directory
set resultDir ..\/result\/RISCV_AXI_system
# set release directory
set releaseDir ..\/release\/RISCV_AXI_system
# set ip_repo_path to script dir
set ip_repo_path ..\/release

file mkdir $resultDir

# CONNECT SYSTEM
create_project RISCV_AXI_system_project $resultDir  -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
create_bd_design "riscv_axi_bd"
update_compile_order -fileset sources_1
# add ip-s to main repo
set_property  ip_repo_paths  $ip_repo_path [current_project]
update_ip_catalog

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
# set clock freq to 98MHz
startgroup
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {98}] [get_bd_cells processing_system7_0]
endgroup
# add AXI_HP
startgroup
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64}] [get_bd_cells processing_system7_0]
endgroup
# add RISCV
startgroup
create_bd_cell -type ip -vlnv FTN:user:RISCV_AXI:1.0 RISCV_AXI_0
endgroup
# apply bd automation
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/RISCV_AXI_0/axif_m} Slave {/processing_system7_0/S_AXI_HP0} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/processing_system7_0/M_AXI_GP0} Slave {/RISCV_AXI_0/axil_s} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins RISCV_AXI_0/axil_s]
# enable fifo in axi master interconnect
startgroup
set_property -dict [list CONFIG.S00_HAS_DATA_FIFO {1}] [get_bd_cells axi_mem_intercon]
endgroup
# regenerate layout
regenerate_bd_layout
#Creating hdl wrapper
make_wrapper -files [get_files $resultDir/RISCV_AXI_system_project.srcs/sources_1/bd/riscv_axi_bd/riscv_axi_bd.bd] -top
add_files -norecurse $resultDir/RISCV_AXI_system_project.srcs/sources_1/bd/riscv_axi_bd/hdl/riscv_axi_bd_wrapper.v
#running synthesis and implementation
create_run synth_opt -flow {Vivado Synthesis 2019} -strategy Flow_PerfOptimized_high
create_run impl_opt -parent_run synth_opt -flow {Vivado Implementation 2019} -strategy Performance_Explore
current_run [get_runs impl_opt]
launch_runs impl_opt -to_step write_bitstream -jobs 4
#wait on implementation
wait_on_run impl_opt
puts "*****************************************************"
puts "* Sinteza i implementacija zavrseni! *"
puts "*****************************************************"
update_compile_order -fileset sources_1

write_hw_platform -fixed -force -include_bit -file $releaseDir/riscv_axi_bd_wrapper.xsa


