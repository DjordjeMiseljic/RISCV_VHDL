variable dispScriptFile [file normalize [info script]]

proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

set sdir [getScriptDirectory]
cd [getScriptDirectory]

# KORAK#1: Definisanje direktorijuma u kojima ce biti smesteni projekat i konfiguracioni fajl
set rootDir ..\/..\/..
set resultDir $rootDir\/result\/RISCV_AXI_IP
set releaseDir $rootDir\/release\/RISCV_AXI_IP
file mkdir $resultDir
file mkdir $releaseDir

create_project RISCV_AXI_project $resultDir -part xc7z010clg400-1 -force

add_files -norecurse $rootDir\/RV32I\/design_sources\/packages\/util_pkg.vhd 

add_files -norecurse $rootDir\/RV32I\/design_sources\/TOP_RISCV.vhd

add_files -norecurse $rootDir\/RV32I\/design_sources\/data_path\/ALU.vhd
add_files -norecurse $rootDir\/RV32I\/design_sources\/data_path\/immediate.vhd
add_files -norecurse $rootDir\/RV32I\/design_sources\/data_path\/register_bank.vhd
add_files -norecurse $rootDir\/RV32I\/design_sources\/data_path\/data_path.vhd

add_files -norecurse $rootDir\/RV32I\/design_sources\/control_path\/hazard_unit.vhd 
add_files -norecurse $rootDir\/RV32I\/design_sources\/control_path\/forwarding_unit.vhd 
add_files -norecurse $rootDir\/RV32I\/design_sources\/control_path\/control_path.vhd
add_files -norecurse $rootDir\/RV32I\/design_sources\/control_path\/ctrl_decoder.vhd
add_files -norecurse $rootDir\/RV32I\/design_sources\/control_path\/alu_decoder.vhd

add_files -norecurse ..\/packages\/cache_axi_pkg.vhd

add_files -norecurse $rootDir\/RISCV_w_cache\/RAM/RAM_sp_ar/RAM_sp_ar.vhd
add_files -norecurse $rootDir\/RISCV_w_cache\/RAM/RAM_sp_ar_bw/RAM_sp_ar_bw.vhd
add_files -norecurse $rootDir\/RISCV_w_cache\/RAM/RAM_tdp_rf/RAM_tdp_rf.vhd

add_files -norecurse ..\/cache_control\/cache_contr_nway_vnv_axi.vhd
add_files -norecurse ..\/RISCV_w_cache_axi.vhd

add_files -norecurse ..\/ip_axi_interface\/RISCV_AXI_v2_0.vhd
add_files -norecurse ..\/ip_axi_interface\/RISCV_AXI_v2_0_AXIF_M.vhd
add_files -norecurse ..\/ip_axi_interface\/RISCV_AXI_v2_0_AXIL_S.vhd


update_compile_order -fileset sources_1

# POKRETANJE SINTEZE
#launch_runs synth_1
#wait_on_run synth_1
#puts "*****************************************************"
#puts "* Sinteza zavrsena! *"
#puts "*****************************************************"

#ipx::package_project -root_dir $rootDir -vendor xilinx.com -library user -taxonomy /UserIP -force
ipx::package_project -root_dir $releaseDir -vendor user.org -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $releaseDir\/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $releaseDir $releaseDir\/component.xml
update_compile_order -fileset sources_1

# POSTAVLJANJE POLJA PARAMETARA

set_property vendor FTN [ipx::current_core]
set_property name RISCV_AXI [ipx::current_core]
set_property display_name RISCV_AXI_v2_0 [ipx::current_core]
set_property description {RV32I core with two levels of cache, communicationg wia AXI interface} [ipx::current_core]
set_property company_url http://www.fnt.uns.ac.rs [ipx::current_core]
set_property vendor_display_name FTN [ipx::current_core]
set_property taxonomy {/Embedded_Processing/AXI_Peripheral /UserIP} [ipx::current_core]
set_property supported_families {zynq Production} [ipx::current_core]


# POSTAVLJANJE VREDNOSTI PARAMETARA

set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_TS_BRAM_TYPE" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters C_TS_BRAM_TYPE -of_objects [ipx::current_core]]
set_property value_validation_list {{"HIGH_PERFORMANCE"} {"LOW_LATENCY"}} [ipx::get_user_parameters C_TS_BRAM_TYPE -of_objects [ipx::current_core]]

set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_BLOCK_SIZE" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters C_BLOCK_SIZE -of_objects [ipx::current_core]]
set_property value_validation_list {16 32 64 128} [ipx::get_user_parameters C_BLOCK_SIZE -of_objects [ipx::current_core]]

set_property widget {comboBox} [ipgui::get_guiparamspec -name "C_LVL2C_ASSOCIATIVITY" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters C_LVL2C_ASSOCIATIVITY -of_objects [ipx::current_core]]
set_property value_validation_list {2 4 8 16} [ipx::get_user_parameters C_LVL2C_ASSOCIATIVITY -of_objects [ipx::current_core]]

ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "C_AXIL_S_DATA_WIDTH" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "C_AXIL_S_ADDR_WIDTH" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "C_PHY_ADDR_WIDTH" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "C_AXIF_M_TARGET_SLAVE_BASE_ADDR" -component [ipx::current_core]]

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

set_property  ip_repo_paths $releaseDir  [current_project]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core $releaseDir\/FTN_user_RISCV_AXI_1.0.zip [ipx::current_core]
close_project
close_project
