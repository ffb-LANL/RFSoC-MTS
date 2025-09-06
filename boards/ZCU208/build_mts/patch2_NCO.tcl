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

source ./rfdc_NCO.tcl

# Create 4x I/Q combiners for ADC lanes
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc0
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc1
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc2
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_combiner:1.1 comb_IQ_adc3


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
_disc_intf axis_data_fifo_adc/S_AXIS
_disc_sig  axis_data_fifo_adc/s_axis_tvalid
_disc_sig  axis_data_fifo_adc/s_axis_tdata
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
