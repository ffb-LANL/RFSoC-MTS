# ==========================================================
# patch_merged.tcl — single patch to apply after mts.tcl
# Combines:
#  • DACIO ports + counter/NOT in hier_dac_play
#  • axi_gpio_dacio on S_AXI4 (M07) + address 0x800A0000
#  • External trigger path:
#      - top input ADCIO_00
#      - trig_sync (xpm_cdc SINGLE) PL→PL
#      - FIFO_cdc (xpm_cdc ASYNC_RST active-low) PL→RF stream clock
#      - trigger_core RTL instance
#      - axi_gpio_software_trig (dual) on S_AXI5 (M08) + address 0x800B0000
# Usage:
#   source ./mts.tcl
#   open_bd_design [get_bd_designs mts]   ;# or set BD_NAME below
#   source ./patch_merged.tcl
# ==========================================================

# ----------------- helpers -----------------
proc _exists {cmd} { expr {[llength [eval $cmd]] > 0} }
# Evaluate in caller scope so $vars expand
proc _try {script} { set rc [catch { uplevel 1 $script } msg]; if {$rc} { puts "NOTE: $msg" } }
proc _ensure_cell {path vlnv} {
  if {![_exists "get_bd_cells -quiet $path"]} {
    set parent [file dirname $path]
    if {$parent ne "/" && ![_exists "get_bd_cells -quiet $parent"]} {
      error "Hierarchy $parent not found. Edit PATHS below."
    }
    create_bd_cell -type ip -vlnv $vlnv $path
  }
}
# xpm_cdc IP has shipped as xilinx.com:ip:xpm_cdc:1.0 and as xilinx.com:ip:xpm_cdc_gen:1.0 across releases.
# This helper will create whichever is available and apply common params.
proc _ensure_cdc {path cdc_type param_dict} {
  if {[_exists "get_bd_cells -quiet $path"]} { return }
  set ok 0
  foreach vlnv {xilinx.com:ip:xpm_cdc:1.0 xilinx.com:ip:xpm_cdc_gen:1.0} {
    if {$ok} { break }
    if {![catch { create_bd_cell -type ip -vlnv $vlnv $path } emsg]} {
      set ok 1
    }
  }
  if {!$ok} { error "Unable to create XPM CDC at $path; add xpm_cdc to IP catalog." }
  # Set type first if the IP exposes CDC_TYPE
  catch { set_property -dict [list CONFIG.CDC_TYPE $cdc_type] [get_bd_cells $path] }
  if {[llength $param_dict]} {
    catch { set_property -dict $param_dict [get_bd_cells $path] }
  }
}
proc _ensure_port {name dir args} {
  if {![_exists "get_bd_ports -quiet $name"]} {
    create_bd_port -dir $dir {*}$args $name
  }
}
proc _ensure_hier_pin {hier name dir args} {
  if {![_exists "get_bd_pins -quiet $hier/$name"]} {
    set saveInst [current_bd_instance]
    current_bd_instance [get_bd_cells $hier]
    create_bd_pin -dir $dir {*}$args $name
    current_bd_instance $saveInst
  }
}
proc _connect {args} { catch { connect_bd_net -quiet {*}$args } }
proc _connect_intf {a b} { catch { connect_bd_intf_net -quiet $a $b } }
proc _disconnect_pin {pin} { catch { disconnect_bd_net [get_bd_pins -quiet $pin] } }
proc _assign_addr {aspace seg off range} { catch { assign_bd_address -offset $off -range $range -target_address_space $aspace $seg -force } }

# ---------- choose/open your BD ----------
set BD_NAME mts   ;# change if your BD has a different name
set bds [get_bd_designs]
if {[lsearch -exact $bds $BD_NAME] >= 0} {
  open_bd_design [get_bd_designs $BD_NAME]
} elseif {[llength $bds] == 1} {
  open_bd_design $bds
} else {
  puts "Available block designs: $bds"
  error "Multiple BDs found. Set BD_NAME at top of patch_merged.tcl (e.g., set BD_NAME mts)."
}
current_bd_instance [get_bd_cells /]

# ==========================================================
# PATHS YOU MAY NEED TO EDIT (match your BD instance names)
# ==========================================================
set HIER_DAC_PLAY         /hier_dac_play
set DAC_STREAM            /hier_dac_play/DACRAMstreamer_0
set HIER_GPIO_CTRL        /gpio_control
set CONTROL_XBAR          /control_interconnect
set PL_CLK                /zynq_ultra_ps_e_0/pl_clk0
set PL_PERIPH_RSTN        /clocktreeMTS/PSreset_control/peripheral_aresetn
# RF stream clock used for deepCapture FIFO (dest clock for async reset CDC)
# Prefer a named RF clock pin; fallback to FIFO's s_axis_aclk if needed.
set RF_AXIS_CLK_PIN       /clocktreeMTS/clkRF

# ==========================================================
# PART A — DACIO ports + counter/NOT + axi_gpio_dacio + M07
# ==========================================================

# 1) Top-level ports
_ensure_port DACIO_00 O -from 0 -to 0 -type data
_ensure_port DACIO_02 O -from 0 -to 0 -type data
_ensure_port DACIO_04 O -from 0 -to 0 -type data

# 2) hier_dac_play: counter + NOT, export pins, wire sync_pulse
if {![_exists "get_bd_cells -quiet $HIER_DAC_PLAY"]} {
  error "Hierarchy $HIER_DAC_PLAY not found. Edit PATHS block."
}
set CNT_PATH       $HIER_DAC_PLAY/c_counter_binary_0
set NOT_RST_PATH   $HIER_DAC_PLAY/util_vector_logic_0
_ensure_cell $CNT_PATH     xilinx.com:ip:c_counter_binary:12.0
_ensure_cell $NOT_RST_PATH xilinx.com:ip:util_vector_logic:2.0
_try { set_property -dict [list CONFIG.CE {true} CONFIG.Output_Width {1} CONFIG.SCLR {true}] [get_bd_cells $CNT_PATH] }
_try { set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.C_SIZE {1}] [get_bd_cells $NOT_RST_PATH] }

_ensure_hier_pin $HIER_DAC_PLAY DACIO_00 O -from 0 -to 0
_ensure_hier_pin $HIER_DAC_PLAY DACIO_02 O

_connect [get_bd_pins $DAC_STREAM/axis_clk] [get_bd_pins $CNT_PATH/CLK]
set _rst_candidate ""
foreach rpin {axis_aresetn s_axi_aresetn aresetn} {
  if {[_exists "get_bd_pins -quiet $DAC_STREAM/$rpin"]} { set _rst_candidate "$DAC_STREAM/$rpin"; break }
}
if {$_rst_candidate ne ""} {
  _connect [get_bd_pins $_rst_candidate] [get_bd_pins $NOT_RST_PATH/Op1]
  _connect [get_bd_pins $NOT_RST_PATH/Res] [get_bd_pins $CNT_PATH/SCLR]
}
if {[_exists "get_bd_pins -quiet $DAC_STREAM/sync_pulse"]} {
  _connect [get_bd_pins $DAC_STREAM/sync_pulse] [get_bd_pins $CNT_PATH/CE]
  _connect [get_bd_pins $DAC_STREAM/sync_pulse] [get_bd_pins $HIER_DAC_PLAY/DACIO_02]
}
_connect [get_bd_pins $CNT_PATH/Q] [get_bd_pins $HIER_DAC_PLAY/DACIO_00]

# 3) gpio_control: add AXI-GPIO for DACIO and export a pin (S_AXI4)
if {![_exists "get_bd_cells -quiet $HIER_GPIO_CTRL"]} {
  error "Hierarchy $HIER_GPIO_CTRL not found. Edit PATHS block."
}
if {![_exists "get_bd_intf_pins -quiet $HIER_GPIO_CTRL/S_AXI4"]} {
  set saveInst [current_bd_instance]
  current_bd_instance [get_bd_cells $HIER_GPIO_CTRL]
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4
  current_bd_instance $saveInst
}
set AXI_GPIO_DACIO $HIER_GPIO_CTRL/axi_gpio_dacio
_ensure_cell $AXI_GPIO_DACIO xilinx.com:ip:axi_gpio:2.0
_try { set_property -dict [list CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_GPIO_WIDTH {1}] [get_bd_cells $AXI_GPIO_DACIO] }
_ensure_hier_pin $HIER_GPIO_CTRL DACIO_02 O -from 0 -to 0
_connect [get_bd_pins $AXI_GPIO_DACIO/gpio_io_o] [get_bd_pins $HIER_GPIO_CTRL/DACIO_02]
_connect_intf [get_bd_intf_pins $HIER_GPIO_CTRL/S_AXI4] [get_bd_intf_pins $AXI_GPIO_DACIO/S_AXI]

# 4) Top wiring
_connect [get_bd_ports DACIO_02] [get_bd_pins $HIER_DAC_PLAY/DACIO_02]
_connect [get_bd_ports DACIO_04] [get_bd_pins $HIER_DAC_PLAY/DACIO_00]
_connect [get_bd_ports DACIO_00] [get_bd_pins $HIER_GPIO_CTRL/DACIO_02]

# 5) Interconnect M07 + clocks/resets
if {[_exists "get_bd_cells -quiet $CONTROL_XBAR"]} {
  set curmi [get_property CONFIG.NUM_MI [get_bd_cells $CONTROL_XBAR]]
  if {$curmi < 8} {
    _try { set_property -dict [list CONFIG.NUM_MI {8}] [get_bd_cells $CONTROL_XBAR] }
  }
  if {[_exists "get_bd_intf_pins -quiet $CONTROL_XBAR/M07_AXI"]} {
    _connect_intf [get_bd_intf_pins $CONTROL_XBAR/M07_AXI] [get_bd_intf_pins $HIER_GPIO_CTRL/S_AXI4]
    _connect [get_bd_pins $PL_CLK] [get_bd_pins $CONTROL_XBAR/M07_ACLK]
    if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
      _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $CONTROL_XBAR/M07_ARESETN]
    }
  }
  _connect [get_bd_pins $PL_CLK] [get_bd_pins $CONTROL_XBAR/ACLK]
  if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
    _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $CONTROL_XBAR/ARESETN]
  }
}
_connect [get_bd_pins $PL_CLK] [get_bd_pins $AXI_GPIO_DACIO/s_axi_aclk]
if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
  _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $AXI_GPIO_DACIO/s_axi_aresetn]
}

# 6) Address map for axi_gpio_dacio
set PS_DATA_AS  [get_bd_addr_spaces zynq_ultra_ps_e_0/Data]
set DACIO_SEG   [get_bd_addr_segs $AXI_GPIO_DACIO/S_AXI/Reg]
_assign_addr $PS_DATA_AS $DACIO_SEG 0x800A0000 0x00010000

# ==========================================================
# PART B — External trigger path (ADCIO_00 + CDCs + trigger_core + S_AXI5 M08)
# ==========================================================

# 1) gpio_control: S_AXI5 + dual GPIO for software trigger + pins
if {![_exists "get_bd_intf_pins -quiet $HIER_GPIO_CTRL/S_AXI5"]} {
  set save2 [current_bd_instance]
  current_bd_instance [get_bd_cells $HIER_GPIO_CTRL]
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5
  current_bd_instance $save2
}
_ensure_hier_pin $HIER_GPIO_CTRL soft_trig O -from 0 -to 0
_ensure_hier_pin $HIER_GPIO_CTRL gpio2_io_i I -from 0 -to 0

set AXI_GPIO_SWTRIG $HIER_GPIO_CTRL/axi_gpio_software_trig
_ensure_cell $AXI_GPIO_SWTRIG xilinx.com:ip:axi_gpio:2.0
_try { set_property -dict [list \
  CONFIG.C_IS_DUAL {1} \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_GPIO_WIDTH {1} \
  CONFIG.C_ALL_INPUTS_2 {1} \
  CONFIG.C_GPIO2_WIDTH {1} \
  CONFIG.C_DOUT_DEFAULT {0x00000000} \
] [get_bd_cells $AXI_GPIO_SWTRIG] }
_connect [get_bd_pins $AXI_GPIO_SWTRIG/gpio_io_o]  [get_bd_pins $HIER_GPIO_CTRL/soft_trig]
_connect [get_bd_pins $HIER_GPIO_CTRL/gpio2_io_i] [get_bd_pins $AXI_GPIO_SWTRIG/gpio2_io_i]
_connect_intf [get_bd_intf_pins $HIER_GPIO_CTRL/S_AXI5] [get_bd_intf_pins $AXI_GPIO_SWTRIG/S_AXI]
_connect [get_bd_pins $PL_CLK] [get_bd_pins $AXI_GPIO_SWTRIG/s_axi_aclk]
if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
  _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $AXI_GPIO_SWTRIG/s_axi_aresetn]
}

# 2) Interconnect M08 and NUM_MI >= 9
if {[_exists "get_bd_cells -quiet $CONTROL_XBAR"]} {
  set curmi2 [get_property CONFIG.NUM_MI [get_bd_cells $CONTROL_XBAR]]
  if {$curmi2 < 9} {
    _try { set_property -dict [list CONFIG.NUM_MI {9}] [get_bd_cells $CONTROL_XBAR] }
  }
  if {[_exists "get_bd_intf_pins -quiet $CONTROL_XBAR/M08_AXI"]} {
    _connect_intf [get_bd_intf_pins $CONTROL_XBAR/M08_AXI] [get_bd_intf_pins $HIER_GPIO_CTRL/S_AXI5]
    _connect [get_bd_pins $PL_CLK] [get_bd_pins $CONTROL_XBAR/M08_ACLK]
    if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
      _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $CONTROL_XBAR/M08_ARESETN]
    }
  }
}

# Address map for axi_gpio_software_trig
set PS_DATA_AS2  [get_bd_addr_spaces zynq_ultra_ps_e_0/Data]
set SWTRIG_SEG   [get_bd_addr_segs $AXI_GPIO_SWTRIG/S_AXI/Reg]
_assign_addr $PS_DATA_AS2 $SWTRIG_SEG 0x800B0000 0x00010000

# 3) Top-level external trigger input
_ensure_port ADCIO_00 I -type data

# 4) trig_sync CDC: SINGLE (PL->PL)
set TRIG_SYNC /trig_sync
_ensure_cdc $TRIG_SYNC xpm_cdc_single [list CONFIG.DEST_SYNC_FF {3} CONFIG.SRC_INPUT_REG {false} CONFIG.INIT_SYNC_FF {false} CONFIG.WIDTH {1}]
_connect [get_bd_pins $PL_CLK] [get_bd_pins $TRIG_SYNC/src_clk]
_connect [get_bd_pins $PL_CLK] [get_bd_pins $TRIG_SYNC/dest_clk]
_connect [get_bd_ports ADCIO_00] [get_bd_pins $TRIG_SYNC/src_in]

# 5) FIFO_cdc CDC: ASYNC_RST active-low (PL -> RF stream)
set FIFO_CDC /FIFO_cdc
_ensure_cdc $FIFO_CDC xpm_cdc_async_rst [list CONFIG.DEST_SYNC_FF {3} CONFIG.RST_ACTIVE_HIGH {false}]
# dest clock: RF axis clock if present, else deepCapture s_axis_aclk
if {[_exists "get_bd_pins -quiet $RF_AXIS_CLK_PIN"]} {
  _connect [get_bd_pins $RF_AXIS_CLK_PIN] [get_bd_pins $FIFO_CDC/dest_clk]
} elseif {[_exists "get_bd_pins -quiet /deepCapture/s_axis_aclk"]} {
  _connect [get_bd_pins /deepCapture/s_axis_aclk] [get_bd_pins $FIFO_CDC/dest_clk]
}

# 6) trigger_core RTL instance
set TRIG_CORE /trigger_core_0
if {![_exists "get_bd_cells -quiet $TRIG_CORE"]} {
  if {[catch { create_bd_cell -type module -reference trigger_core $TRIG_CORE } emsg]} {
    puts "ERROR: trigger_core RTL not found in project. Add trigger_core.v then re-source patch_merged.tcl."
  }
}
_connect [get_bd_pins $PL_CLK] [get_bd_pins $TRIG_CORE/clk]
if {[_exists "get_bd_pins -quiet $PL_PERIPH_RSTN"]} {
  _connect [get_bd_pins $PL_PERIPH_RSTN] [get_bd_pins $TRIG_CORE/aresetn]
}
# Connect HW/SW trigger + enable (enable from gpio_control/fifoflush if available)
_connect [get_bd_pins $TRIG_SYNC/dest_out]        [get_bd_pins $TRIG_CORE/hw_trig]
_connect [get_bd_pins $HIER_GPIO_CTRL/soft_trig]  [get_bd_pins $TRIG_CORE/soft_trig]
if {[_exists "get_bd_pins -quiet $HIER_GPIO_CTRL/fifoflush"]} {
  _connect [get_bd_pins $HIER_GPIO_CTRL/fifoflush] [get_bd_pins $TRIG_CORE/enable]
}

# triggered_q -> FIFO CDC (active-low reset assertion) and to GPIO (readback)
_connect [get_bd_pins $TRIG_CORE/triggered_q] [get_bd_pins $FIFO_CDC/src_arst]
_connect [get_bd_pins $TRIG_CORE/triggered_q] [get_bd_pins $HIER_GPIO_CTRL/gpio2_io_i]

# ----- Rewire deepCapture/fifo_flush_n to FIFO_cdc/dest_arst -----

# Locate pins
set _ff_pin  [get_bd_pins -quiet /deepCapture/fifo_flush_n]
set _cdc_pin [get_bd_pins -quiet /FIFO_cdc/dest_arst]
set _old_sw  [get_bd_pins -quiet /gpio_control/fifoflush]

# If fifo_flush_n is already connected to some net, detach it
if {[llength $_ff_pin]} {
  set _ff_net [get_bd_nets -quiet -of_objects $_ff_pin]
  if {[llength $_ff_net]} {
    # First try a clean disconnect; if the net persists, delete it
    catch { disconnect_bd_net $_ff_net }
    catch { delete_bd_objs $_ff_net }
  }
}

# Also make sure gpio_control/fifoflush isn’t still driving anything relevant
if {[llength $_old_sw]} {
  set _sw_net [get_bd_nets -quiet -of_objects $_old_sw]
  if {[llength $_sw_net]} {
    catch { disconnect_bd_net $_sw_net }
  }
}

# Now connect CDC output to FIFO reset (active-low)
if {[llength $_ff_pin] && [llength $_cdc_pin]} {
  connect_bd_net -net fifo_flush_n_from_cdc $_cdc_pin $_ff_pin
} else {
  puts "NOTE: Missing pin(s) for rewire: dest_arst=[llength $_cdc_pin], fifo_flush_n=[llength $_ff_pin]"
}

# --- Ensure trigger_core.enable is tied to gpio_control/fifoflush (arm/reset from SW) ---
set en_pin  [get_bd_pins -quiet /trigger_core_0/enable]
set sw_pin  [get_bd_pins -quiet /gpio_control/fifoflush]

if {[llength $en_pin] && [llength $sw_pin]} {
  set en_net [get_bd_nets -quiet -of_objects $en_pin]
  set sw_net [get_bd_nets -quiet -of_objects $sw_pin]

  # If both pins already sit on the same net, do nothing.
  if {[llength $en_net] && [llength $sw_net] && \
      [string equal [lindex $en_net 0] [lindex $sw_net 0]]} {
    puts "INFO: enable already connected to fifoflush via [lindex $sw_net 0]"
  } else {
    # Otherwise, detach enable from whatever it was on…
    if {[llength $en_net]} {
      catch { disconnect_bd_net [lindex $en_net 0] $en_pin }
    }
    # …and join it to fifoflush’s net if it exists, or create a new net.
    if {[llength $sw_net]} {
      connect_bd_net -net [lindex $sw_net 0] $en_pin
    } else {
      connect_bd_net $sw_pin $en_pin
    }
  }
} else {
  puts "NOTE: Missing pin(s) for enable wiring: fifoflush=[llength $sw_pin] enable=[llength $en_pin]"
}

# ==========================================================
# Finish
# ==========================================================
validate_bd_design
regenerate_bd_layout
save_bd_design
puts {Merged patch applied successfully.}
