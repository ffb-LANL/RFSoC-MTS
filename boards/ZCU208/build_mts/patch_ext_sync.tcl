# boards/ZCU208/build_mts/patch_my_changes.tcl
# Apply GUI-made edits to the RFSoC-MTS BD after sourcing the original mts.tcl.
# Usage:
#   source boards/ZCU208/build_mts/mts.tcl
#   source boards/ZCU208/build_mts/patch_my_changes.tcl
#   validate_bd_design
#   generate_target all [get_files *.bd]
#   make_wrapper -files [get_files *.bd] -top
#   update_compile_order -fileset sources_1

set bd_name [get_bd_designs]
current_bd_design $bd_name

# -------------------------
# hier_dac_play additions
# -------------------------
set _oldInst [current_bd_instance .]
current_bd_instance [get_bd_cells hier_dac_play]

# Create new output pins on the hierarchy
if {![llength [get_bd_pins DACIO_00]]} { create_bd_pin -dir O -from 0 -to 0 DACIO_00 }
if {![llength [get_bd_pins DACIO_02]]} { create_bd_pin -dir O DACIO_02 }

# Counter-as-TFF to make a toggling output; CE will be sync_pulse
if {![llength [get_bd_cells c_counter_binary_0]]} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0
  set_property -dict [list CONFIG.CE {true} CONFIG.Output_Width {1} CONFIG.SCLR {true}] [get_bd_cells c_counter_binary_0]
}

# Inverter to make SCLR active-high from existing aresetn net
if {![llength [get_bd_cells util_vector_logic_0]]} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
  set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}] [get_bd_cells util_vector_logic_0]
}

# Wire sync_pulse to: (a) new pin DACIO_02, (b) CE of the counter
# Also hook the local resets/clock to the new IP pins.
# NOTE: these use existing local nets "Net" (aresetn) and "Net1" (axis_clk) in hier_dac_play.
# If your upstream mts.tcl changes those net names, adjust the net names below accordingly.
if {[llength [get_bd_pins DACRAMstreamer_0/sync_pulse]]} {
  connect_bd_net -net DACRAMstreamer_0_sync_pulse \
    [get_bd_pins DACIO_02] \
    [get_bd_pins DACRAMstreamer_0/sync_pulse] \
    [get_bd_pins c_counter_binary_0/CE]
}

# Add util_vector_logic_0 input to existing aresetn net "Net"
connect_bd_net -net Net [get_bd_pins util_vector_logic_0/Op1]
# Add counter CLK to existing clock net "Net1"
connect_bd_net -net Net1 [get_bd_pins c_counter_binary_0/CLK]
# Connect counter Q to new pin
connect_bd_net -net c_counter_binary_0_Q [get_bd_pins DACIO_00] [get_bd_pins c_counter_binary_0/Q]
# Drive counter SCLR from inverter output
connect_bd_net -net util_vector_logic_0_Res [get_bd_pins c_counter_binary_0/SCLR] [get_bd_pins util_vector_logic_0/Res]

# Restore root
current_bd_instance $_oldInst

# -------------------------
# gpio_control additions
# -------------------------
set _oldInst [current_bd_instance .]
current_bd_instance [get_bd_cells gpio_control]

# Extra AXI-Lite slave for new GPIO and a new 1-bit output pin
if {![llength [get_bd_intf_pins S_AXI4]]} { create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4 }
if {![llength [get_bd_pins DACIO_02]]}  { create_bd_pin -dir O -from 0 -to 0 DACIO_02 }

# New AXI GPIO (all outputs, 1 bit)
if {![llength [get_bd_cells axi_gpio_dacio]]} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_dacio
  set_property -dict [list CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_GPIO_WIDTH {1}] [get_bd_cells axi_gpio_dacio]
}

# Bus & pin connections for the new GPIO
connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI4] [get_bd_intf_pins axi_gpio_dacio/S_AXI]
connect_bd_net -net axi_gpio_dacio_gpio_io_o [get_bd_pins DACIO_02] [get_bd_pins axi_gpio_dacio/gpio_io_o]

# Hook resets/clocks to the new GPIO (use existing local nets)
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axi_gpio_dacio/s_axi_aresetn]
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0           [get_bd_pins axi_gpio_dacio/s_axi_aclk]

current_bd_instance $_oldInst

# -------------------------
# Root design additions
# -------------------------

# Create new top-level ports
if {![llength [get_bd_ports DACIO_00]]} { set DACIO_00 [ create_bd_port -dir O -from 0 -to 0 -type data DACIO_00 ] }
if {![llength [get_bd_ports DACIO_02]]} { set DACIO_02 [ create_bd_port -dir O -from 0 -to 0 -type data DACIO_02 ] }
if {![llength [get_bd_ports DACIO_04]]} { set DACIO_04 [ create_bd_port -dir O -from 0 -to 0 -type data DACIO_04 ] }

# Increase control_interconnect MI count from 7 to 8 (adds M07_* ports)
set_property -dict [list CONFIG.NUM_MI {8}] [get_bd_cells control_interconnect]

# New AXI-Lite connection: control_interconnect M07 -> gpio_control S_AXI4
connect_bd_intf_net -intf_net control_interconnect_M07_AXI \
  [get_bd_intf_pins control_interconnect/M07_AXI] \
  [get_bd_intf_pins gpio_control/S_AXI4]

# Add M07 clock & reset to the existing clock/reset backbones
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0          [get_bd_pins control_interconnect/M07_ACLK]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins control_interconnect/M07_ARESETN]

# Expose hierarchical pins to the top-level ports (note the naming in your diff)
#  - Route gpio_control/DACIO_02 to top DACIO_00
#  - Route hier_dac_play/DACIO_02 (sync) to top DACIO_02
#  - Route hier_dac_play/DACIO_00 (counter Q) to top DACIO_04
connect_bd_net -net gpio_control_DACIO_02      [get_bd_ports DACIO_00] [get_bd_pins gpio_control/DACIO_02]
connect_bd_net -net hier_dac_play_DACIO_02     [get_bd_ports DACIO_02] [get_bd_pins hier_dac_play/DACIO_02]
connect_bd_net -net hier_dac_play_DACIO_00     [get_bd_ports DACIO_04] [get_bd_pins hier_dac_play/DACIO_00]

# Assign address for the new AXI GPIO (axi_gpio_dacio) at 0x800A0000
# (Adjust offset if this collides with your system.)
assign_bd_address -offset 0x800A0000 -range 0x00010000 \
  -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] \
  [get_bd_addr_segs gpio_control/axi_gpio_dacio/S_AXI/Reg] -force

# done (validate/save are usually called by your outer build script)
