# === apply_NCO_patch.tcl ===

# Helper routines

# Disconnect an INTERFACE pin from its current interface net
proc _disc_intf {ipin_path} {
  set ap    [get_bd_intf_pins $ipin_path]
  set inet [get_bd_intf_nets -of_objects $ap]
  puts "interface net = $inet"
  puts "calling disconnect_bd_intf_net  $inet $ap"  
  disconnect_bd_intf_net $inet $ap
}

# Disconnect a regular (scalar) pin from whatever net it’s on
proc _disc_sig {pin_path} {
  set p [get_bd_pins $pin_path]
  if {![llength $p]} { 
  puts "no pins"
  return }
  set n [get_bd_nets -of_objects $p]
  if {[llength $n]} {
    # GUI-style: net then pin
    disconnect_bd_net [lindex $n 0] $p 
  }
}

# Assumes: your BD (e.g. 'mts') is open. No checks, one-shot patch.




# Open the BD if needed (adjust the name if not 'mts')
open_bd_design [get_bd_designs mts]
current_bd_instance /

# -----------------------------------------------------------------------------
# Root-level IP/property changes (axis_broadcaster, smartconnect rename, comb_IQ_*,
# clocktreeMTS params, RFDC params, top-level wiring changes)
# -----------------------------------------------------------------------------

# axis_broadcaster_0 width and remap updates
set_property -dict [list \
  CONFIG.HAS_TREADY {1} \
  CONFIG.M00_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M01_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M02_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M03_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M04_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M05_TDATA_REMAP {tdata[255:0]} \
  CONFIG.M_TDATA_NUM_BYTES {32} \
  CONFIG.NUM_MI {6} \
  CONFIG.S_TDATA_NUM_BYTES {32} \
] [get_bd_cells axis_broadcaster_0]

# Rename smartconnect_0 -> smartconnect_ddr
set_property NAME smartconnect_ddr [get_bd_cells smartconnect_0]
set_property -dict [list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {2}] [get_bd_cells smartconnect_ddr]

# Create 4x I/Q combiners for ADC lanes
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc3

# clocktreeMTS/MTSclkwiz changes (fabric rates now ~31.25/15.625 MHz)
set cw [get_bd_cells clocktreeMTS/MTSclkwiz]
set_property -dict [list \
  CONFIG.CLKOUT1_JITTER {114.922} \
  CONFIG.CLKOUT1_PHASE_ERROR {70.309} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {31.250} \
  CONFIG.CLKOUT2_JITTER {131.463} \
  CONFIG.CLKOUT2_PHASE_ERROR {70.309} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {15.625} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {6.375} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {51.000} \
  CONFIG.MMCM_CLKOUT1_DIVIDE {102} \
  CONFIG.MMCM_DIVCLK_DIVIDE {2} \
] $cw

# RF Data Converter parameter updates (enable DUC/DDC + NCO, I/Q types/widths, decim/interp)
set rfdc [get_bd_cells usp_rf_data_converter_1]
set_property -dict [list \
  CONFIG.ADC0_Clock_Source {1} \
  CONFIG.ADC0_Enable {1} \
  CONFIG.ADC0_Fabric_Freq {31.250} \
  CONFIG.ADC0_Multi_Tile_Sync {false} \
  CONFIG.ADC0_Outclk_Freq {250.000} \
  CONFIG.ADC0_Refclk_Freq {4000.000} \
  CONFIG.ADC0_Sampling_Rate {4} \
  CONFIG.ADC1_Clock_Dist {1} \
  CONFIG.ADC1_Clock_Source {1} \
  CONFIG.ADC1_Enable {1} \
  CONFIG.ADC1_Fabric_Freq {31.250} \
  CONFIG.ADC1_Multi_Tile_Sync {false} \
  CONFIG.ADC1_Outclk_Freq {250.000} \
  CONFIG.ADC1_Refclk_Freq {4000.000} \
  CONFIG.ADC1_Sampling_Rate {4} \
  CONFIG.ADC2_Clock_Dist {1} \
  CONFIG.ADC2_Clock_Source {1} \
  CONFIG.ADC2_Enable {1} \
  CONFIG.ADC2_Fabric_Freq {15.625} \
  CONFIG.ADC2_Outclk_Freq {15.625} \
  CONFIG.ADC2_Refclk_Freq {2000.000} \
  CONFIG.ADC2_Sampling_Rate {2.0} \
  CONFIG.ADC3_Clock_Dist {1} \
  CONFIG.ADC3_Clock_Source {1} \
  CONFIG.ADC3_Enable {1} \
  CONFIG.ADC3_Fabric_Freq {15.625} \
  CONFIG.ADC3_Outclk_Freq {15.625} \
  CONFIG.ADC3_Refclk_Freq {2000.000} \
  CONFIG.ADC3_Sampling_Rate {2.0} \
  CONFIG.ADC_Coarse_Mixer_Freq00 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq01 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq02 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq03 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq10 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq11 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq12 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq13 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq20 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq21 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq30 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq31 {0} \
  CONFIG.ADC_Data_Type00 {1} \
  CONFIG.ADC_Data_Type01 {1} \
  CONFIG.ADC_Data_Type02 {1} \
  CONFIG.ADC_Data_Type03 {1} \
  CONFIG.ADC_Data_Type10 {1} \
  CONFIG.ADC_Data_Type11 {1} \
  CONFIG.ADC_Data_Type12 {1} \
  CONFIG.ADC_Data_Type13 {1} \
  CONFIG.ADC_Data_Width00 {8} \
  CONFIG.ADC_Data_Width01 {8} \
  CONFIG.ADC_Data_Width10 {8} \
  CONFIG.ADC_Data_Width11 {8} \
  CONFIG.ADC_Data_Width20 {8} \
  CONFIG.ADC_Data_Width21 {8} \
  CONFIG.ADC_Data_Width30 {8} \
  CONFIG.ADC_Data_Width31 {8} \
  CONFIG.ADC_Decimation_Mode00 {16} \
  CONFIG.ADC_Decimation_Mode01 {16} \
  CONFIG.ADC_Decimation_Mode02 {16} \
  CONFIG.ADC_Decimation_Mode03 {16} \
  CONFIG.ADC_Decimation_Mode10 {16} \
  CONFIG.ADC_Decimation_Mode11 {16} \
  CONFIG.ADC_Decimation_Mode12 {16} \
  CONFIG.ADC_Decimation_Mode13 {16} \
  CONFIG.ADC_Dither00 {true} \
  CONFIG.ADC_Dither01 {true} \
  CONFIG.ADC_Dither10 {true} \
  CONFIG.ADC_Dither11 {true} \
  CONFIG.ADC_Dither20 {true} \
  CONFIG.ADC_Dither21 {true} \
  CONFIG.ADC_Dither30 {true} \
  CONFIG.ADC_Dither31 {true} \
  CONFIG.ADC_Mixer_Mode00 {0} \
  CONFIG.ADC_Mixer_Mode01 {0} \
  CONFIG.ADC_Mixer_Mode02 {0} \
  CONFIG.ADC_Mixer_Mode03 {0} \
  CONFIG.ADC_Mixer_Mode10 {0} \
  CONFIG.ADC_Mixer_Mode11 {0} \
  CONFIG.ADC_Mixer_Mode12 {0} \
  CONFIG.ADC_Mixer_Mode13 {0} \
  CONFIG.ADC_Mixer_Type00 {2} \
  CONFIG.ADC_Mixer_Type01 {2} \
  CONFIG.ADC_Mixer_Type02 {2} \
  CONFIG.ADC_Mixer_Type03 {2} \
  CONFIG.ADC_Mixer_Type10 {2} \
  CONFIG.ADC_Mixer_Type11 {2} \
  CONFIG.ADC_Mixer_Type12 {2} \
  CONFIG.ADC_Mixer_Type13 {2} \
  CONFIG.ADC_Mixer_Type20 {3} \
  CONFIG.ADC_Mixer_Type21 {3} \
  CONFIG.ADC_Mixer_Type30 {3} \
  CONFIG.ADC_Mixer_Type31 {3} \
  CONFIG.ADC_NCO_Freq00 {0.5} \
  CONFIG.ADC_NCO_Freq02 {0.5} \
  CONFIG.ADC_NCO_Freq10 {0.5} \
  CONFIG.ADC_NCO_Phase12 {0} \
  CONFIG.DAC0_Clock_Dist {0} \
  CONFIG.DAC0_Clock_Source {6} \
  CONFIG.DAC0_Enable {1} \
  CONFIG.DAC0_Fabric_Freq {31.250} \
  CONFIG.DAC0_Multi_Tile_Sync {false} \
  CONFIG.DAC0_Outclk_Freq {500.000} \
  CONFIG.DAC0_PLL_Enable {false} \
  CONFIG.DAC0_Refclk_Freq {4000.000} \
  CONFIG.DAC0_Sampling_Rate {4} \
  CONFIG.DAC1_Clock_Source {6} \
  CONFIG.DAC1_Enable {1} \
  CONFIG.DAC1_Fabric_Freq {31.250} \
  CONFIG.DAC1_Multi_Tile_Sync {false} \
  CONFIG.DAC1_Outclk_Freq {500.000} \
  CONFIG.DAC1_PLL_Enable {false} \
  CONFIG.DAC1_Refclk_Freq {4000.000} \
  CONFIG.DAC1_Sampling_Rate {4} \
  CONFIG.DAC2_Clock_Dist {1} \
  CONFIG.DAC2_Enable {1} \
  CONFIG.DAC2_Fabric_Freq {31.250} \
  CONFIG.DAC2_Outclk_Freq {500.000} \
  CONFIG.DAC2_PLL_Enable {false} \
  CONFIG.DAC2_Refclk_Freq {4000.000} \
  CONFIG.DAC2_Sampling_Rate {4} \
  CONFIG.DAC_Coarse_Mixer_Freq00 {3} \
  CONFIG.DAC_Coarse_Mixer_Freq02 {0} \
  CONFIG.DAC_Coarse_Mixer_Freq10 {3} \
  CONFIG.DAC_Coarse_Mixer_Freq12 {0} \
  CONFIG.DAC_Coarse_Mixer_Freq20 {0} \
  CONFIG.DAC_Coarse_Mixer_Freq22 {0} \
  CONFIG.DAC_Coarse_Mixer_Freq30 {0} \
  CONFIG.DAC_Coarse_Mixer_Freq32 {0} \
  CONFIG.DAC_Data_Type00 {0} \
  CONFIG.DAC_Data_Type02 {0} \
  CONFIG.DAC_Data_Width00 {16} \
  CONFIG.DAC_Data_Width02 {16} \
  CONFIG.DAC_Data_Width10 {16} \
  CONFIG.DAC_Data_Width12 {16} \
  CONFIG.DAC_Data_Width20 {16} \
  CONFIG.DAC_Data_Width22 {16} \
  CONFIG.DAC_Data_Width30 {16} \
  CONFIG.DAC_Data_Width32 {16} \
  CONFIG.DAC_Interpolation_Mode00 {16} \
  CONFIG.DAC_Interpolation_Mode02 {16} \
  CONFIG.DAC_Interpolation_Mode10 {16} \
  CONFIG.DAC_Interpolation_Mode12 {16} \
  CONFIG.DAC_Interpolation_Mode20 {16} \
  CONFIG.DAC_Interpolation_Mode22 {0} \
  CONFIG.DAC_Interpolation_Mode30 {0} \
  CONFIG.DAC_Interpolation_Mode32 {0} \
  CONFIG.DAC_Mixer_Mode00 {0} \
  CONFIG.DAC_Mixer_Mode02 {0} \
  CONFIG.DAC_Mixer_Mode10 {0} \
  CONFIG.DAC_Mixer_Mode12 {0} \
  CONFIG.DAC_Mixer_Mode20 {0} \
  CONFIG.DAC_Mixer_Type00 {2} \
  CONFIG.DAC_Mixer_Type02 {2} \
  CONFIG.DAC_Mixer_Type10 {2} \
  CONFIG.DAC_Mixer_Type12 {2} \
  CONFIG.DAC_Mixer_Type20 {2} \
  CONFIG.DAC_Mixer_Type22 {3} \
  CONFIG.DAC_Mixer_Type30 {3} \
  CONFIG.DAC_Mixer_Type32 {3} \
  CONFIG.DAC_NCO_Freq00 {0.5} \
  CONFIG.DAC_NCO_Freq02 {0.5} \
  CONFIG.DAC_NCO_Freq10 {0.5} \
  CONFIG.DAC_NCO_Freq12 {0.5} \
  CONFIG.DAC_NCO_Freq20 {0.5} \
] $rfdc

# -----------------------------------------------------------------------------
# hier_dac_play changes (remove dwidth conv, wire directly, constant rename)
# -----------------------------------------------------------------------------
current_bd_instance /hier_dac_play

# Remove axis_dwidth_converter_0 if present (simple, no checks)
delete_bd_objs [get_bd_cells axis_dwidth_converter_0]
delete_bd_objs [get_bd_cells axis_clock_converter_0]

# Replace xlconstant_0 with xlconstant_num_vect
delete_bd_objs [get_bd_cells xlconstant_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_num_vect
set_property -dict [list CONFIG.CONST_VAL {0xFFF} CONFIG.CONST_WIDTH {12}] [get_bd_cells xlconstant_num_vect]
connect_bd_net [get_bd_pins DACRAMstreamer_0/numSampleVectors] [get_bd_pins xlconstant_num_vect/dout]

# Reconnect data path: DACRAMstreamer -> axis_register_slice directly
current_bd_instance /hier_dac_play
# replaces disconnect_bd_intf_net [get_bd_intf_nets -of_objects [get_bd_intf_pins DACRAMstreamer_0/axis]] :
puts [current_bd_instance .]
#_disc_intf DACRAMstreamer_0/axis 
current_bd_instance /hier_dac_play
puts [current_bd_instance .]
connect_bd_intf_net [get_bd_intf_pins DACRAMstreamer_0/axis] [get_bd_intf_pins axis_register_slice_0/S_AXIS]

# Clocks/resets per diff (explicit joins)
_disc_sig DACRAMstreamer_0/axis_clk
_disc_sig c_counter_binary_0/CLK
_disc_sig axi_bram_ctrl_0/s_axi_aclk

connect_bd_net [get_bd_pins aclk] [get_bd_pins DACRAMstreamer_0/axis_clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
               [get_bd_pins c_counter_binary_0/CLK]

current_bd_instance /

# -----------------------------------------------------------------------------
# hier_adc0_cap / hier_adc1_cap / hier_adc2_cap changes (drop dwidth conv, direct S_AXIS to axis_cc)
# -----------------------------------------------------------------------------
foreach H {hier_adc0_cap hier_adc1_cap hier_adc2_cap} {
  current_bd_instance /$H
  delete_bd_objs [get_bd_cells axis_dwidth_converter_0]
  delete_bd_objs [get_bd_cells axis_clock_converter_0]
  # (adc0/1/2 share same wiring lines in diff)
  _disc_sig axi_bram_ctrl_0/s_axi_aclk
  connect_bd_net [get_bd_pins aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
  # connect_bd_net [get_bd_pins s_axi_aresetn] [get_bd_pins ADCRAMcapture_0/axis_aresetn] \
  #               [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axis_clock_converter_0/m_axis_aresetn] \
  #               [get_bd_pins axis_clock_converter_0/s_axis_aresetn]
  connect_bd_intf_net [get_bd_intf_pins S_AXIS] [get_bd_intf_pins ADCRAMcapture_0/CAP_AXIS]
  current_bd_instance /
}


# -----------------------------------------------------------------------------
# deepCapture changes (remove dwidth conv, feed FIFO direct, constants, nets)
# -----------------------------------------------------------------------------
current_bd_instance /deepCapture
delete_bd_objs [get_bd_cells axis_dwidth_converter_0]
delete_bd_objs [get_bd_cells xlconstant_1]
# Rewire S_AXIS directly to axis_data_fifo_adc
connect_bd_intf_net [get_bd_intf_pins S_AXIS] [get_bd_intf_pins axis_data_fifo_adc/S_AXIS]
current_bd_instance /

# -----------------------------------------------------------------------------
# Top-level rewirings for ADC I/Q combiners and DDR smartconnect
# -----------------------------------------------------------------------------

# RF ingress reset also to combiners
connect_bd_net [get_bd_pins clocktreeMTS/ingress_aresetn] \
  [get_bd_pins comb_IQ_adc0/aresetn] [get_bd_pins comb_IQ_adc1/aresetn] \
  [get_bd_pins comb_IQ_adc2/aresetn] [get_bd_pins comb_IQ_adc3/aresetn] \
  [get_bd_pins usp_rf_data_converter_1/m0_axis_aresetn] [get_bd_pins usp_rf_data_converter_1/m1_axis_aresetn] \
  [get_bd_pins usp_rf_data_converter_1/s0_axis_aresetn] [get_bd_pins usp_rf_data_converter_1/s1_axis_aresetn] \
  [get_bd_pins usp_rf_data_converter_1/s2_axis_aresetn]

# RF fabric clock fans out to more sinks incl combiners and axis clocks in hier blocks
connect_bd_net [get_bd_pins clocktreeMTS/clkRF] \
  [get_bd_pins comb_IQ_adc0/aclk] [get_bd_pins comb_IQ_adc1/aclk] \
  [get_bd_pins comb_IQ_adc2/aclk] [get_bd_pins comb_IQ_adc3/aclk]
 
set rfc2 [get_bd_pins /clocktreeMTS/clkRFdiv2]
set rfn2 [get_bd_nets -of_objects $rfc2]
disconnect_bd_net $rfn2 $rfc2
connect_bd_net [get_bd_pins clocktreeMTS/clkRF] [get_bd_pins gpio_control/dest_clk] -boundary_type upper


# Route RFDC ADC I/Q to combiners, and combiner outputs to hier_adc*_cap & deepCapture
_disc_intf /usp_rf_data_converter_1/m00_axis
_disc_intf /usp_rf_data_converter_1/m02_axis
_disc_intf /usp_rf_data_converter_1/m10_axis
_disc_intf /usp_rf_data_converter_1/m12_axis

connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc0/S00_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m00_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc0/S01_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m01_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc1/S00_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m02_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc1/S01_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m03_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc2/S00_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m10_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc2/S01_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m11_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc3/S00_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m12_axis]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc3/S01_AXIS] [get_bd_intf_pins usp_rf_data_converter_1/m13_axis]

connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc0/M_AXIS] [get_bd_intf_pins hier_adc0_cap/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc1/M_AXIS] [get_bd_intf_pins hier_adc1_cap/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc2/M_AXIS] [get_bd_intf_pins hier_adc2_cap/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins comb_IQ_adc3/M_AXIS] [get_bd_intf_pins deepCapture/S_AXIS]


# -----------------------------------------------------------------------------
# Done: validate, save
# -----------------------------------------------------------------------------
#validate_bd_design
#save_bd_design
puts "apply_NCO_patch.tcl: patch complete."
