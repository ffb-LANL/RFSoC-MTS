# -------------------------------------------------------------------------------------------------
# Copyright (C) 2023 Advanced Micro Devices, Inc
# SPDX-License-Identifier: MIT
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- --
# -------------- -------------- -------------- -------------- -------------- -------------- -------
# Pin Assignments -- all other pins handled by board BSP
# -------------- -------------- -------------- -------------- -------------- -------------- -------
set_property PACKAGE_PIN B10 [get_ports PL_SYSREF_clk_p]
set_property PACKAGE_PIN B8  [get_ports PL_CLK_clk_p]
set_property PACKAGE_PIN C11 [get_ports {clk104_clk_spi_mux_sel_tri_o[0]}]
set_property PACKAGE_PIN B12 [get_ports {clk104_clk_spi_mux_sel_tri_o[1]}]

set_property IOSTANDARD LVDS_25 [get_ports PL_CLK_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports PL_CLK_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports PL_SYSREF_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports PL_SYSREF_clk_n]
set_property IOSTANDARD LVCMOS12 [get_ports {clk104_clk_spi_mux_sel_tri_o[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {clk104_clk_spi_mux_sel_tri_o[0]}]

# DACIO
set_property PACKAGE_PIN A9       [get_ports "DACIO_00"] ;# Bank  87 VCCO - VCC1V8   - IO_L12N_AD8N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_00"] ;# Bank  87 VCCO - VCC1V8   - IO_L12N_AD8N_87
set_property SLEW FAST            [get_ports "DACIO_00"]
set_property PACKAGE_PIN A10      [get_ports "DACIO_01"] ;# Bank  87 VCCO - VCC1V8   - IO_L12P_AD8P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_01"] ;# Bank  87 VCCO - VCC1V8   - IO_L12P_AD8P_87
set_property SLEW FAST            [get_ports "DACIO_01"]
set_property PACKAGE_PIN A6       [get_ports "DACIO_02"] ;# Bank  87 VCCO - VCC1V8   - IO_L11N_AD9N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_02"] ;# Bank  87 VCCO - VCC1V8   - IO_L11N_AD9N_87
set_property SLEW FAST            [get_ports "DACIO_02"]
set_property PACKAGE_PIN A7       [get_ports "DACIO_03"] ;# Bank  87 VCCO - VCC1V8   - IO_L11P_AD9P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_03"] ;# Bank  87 VCCO - VCC1V8   - IO_L11P_AD9P_87
set_property SLEW FAST            [get_ports "DACIO_03"]
set_property PACKAGE_PIN A5       [get_ports "DACIO_04"] ;# Bank  87 VCCO - VCC1V8   - IO_L10N_AD10N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_04"] ;# Bank  87 VCCO - VCC1V8   - IO_L10N_AD10N_87
set_property SLEW FAST            [get_ports "DACIO_04"]
set_property PACKAGE_PIN B5       [get_ports "DACIO_05"] ;# Bank  87 VCCO - VCC1V8   - IO_L10P_AD10P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_05"] ;# Bank  87 VCCO - VCC1V8   - IO_L10P_AD10P_87
set_property SLEW FAST            [get_ports "DACIO_05"]
set_property PACKAGE_PIN C5       [get_ports "DACIO_06"] ;# Bank  87 VCCO - VCC1V8   - IO_L9N_AD11N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_06"] ;# Bank  87 VCCO - VCC1V8   - IO_L9N_AD11N_87
set_property SLEW FAST            [get_ports "DACIO_06"]
set_property PACKAGE_PIN C6       [get_ports "DACIO_07"] ;# Bank  87 VCCO - VCC1V8   - IO_L9P_AD11P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_07"] ;# Bank  87 VCCO - VCC1V8   - IO_L9P_AD11P_87
set_property SLEW FAST            [get_ports "DACIO_07"]
set_property PACKAGE_PIN C10      [get_ports "DACIO_08"] ;# Bank  87 VCCO - VCC1V8   - IO_L4N_AD12N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_08"] ;# Bank  87 VCCO - VCC1V8   - IO_L4N_AD12N_87
set_property PACKAGE_PIN D10      [get_ports "DACIO_09"] ;# Bank  87 VCCO - VCC1V8   - IO_L4P_AD12P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_09"] ;# Bank  87 VCCO - VCC1V8   - IO_L4P_AD12P_87
set_property PACKAGE_PIN D6       [get_ports "DACIO_10"] ;# Bank  87 VCCO - VCC1V8   - IO_L3N_AD13N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_10"] ;# Bank  87 VCCO - VCC1V8   - IO_L3N_AD13N_87
set_property PACKAGE_PIN E7       [get_ports "DACIO_11"] ;# Bank  87 VCCO - VCC1V8   - IO_L3P_AD13P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_11"] ;# Bank  87 VCCO - VCC1V8   - IO_L3P_AD13P_87
set_property PACKAGE_PIN E8       [get_ports "DACIO_12"] ;# Bank  87 VCCO - VCC1V8   - IO_L2N_AD14N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_12"] ;# Bank  87 VCCO - VCC1V8   - IO_L2N_AD14N_87
set_property PACKAGE_PIN E9       [get_ports "DACIO_13"] ;# Bank  87 VCCO - VCC1V8   - IO_L2P_AD14P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_13"] ;# Bank  87 VCCO - VCC1V8   - IO_L2P_AD14P_87
set_property PACKAGE_PIN E6       [get_ports "DACIO_14"] ;# Bank  87 VCCO - VCC1V8   - IO_L1N_AD15N_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_14"] ;# Bank  87 VCCO - VCC1V8   - IO_L1N_AD15N_87
set_property PACKAGE_PIN F6       [get_ports "DACIO_15"] ;# Bank  87 VCCO - VCC1V8   - IO_L1P_AD15P_87
set_property IOSTANDARD  LVCMOS18 [get_ports "DACIO_15"] ;# Bank  87 VCCO - VCC1V8   - IO_L1P_AD15P_87


# -------------- -------------- -------------- -------------- -------------- -------------- -------
# Synthesis Guidance
# -------------- -------------- -------------- -------------- -------------- -------------- -------
set_property BLOCK_SYNTH.RETIMING 1 [get_cells mts_i/ddr4_0]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells mts_i/ddr4_0]
set_property MAX_FANOUT 32 [get_cells {mts_i/ddr4_0/inst/u_ddr4_mem_intfc/u_ddr_mc/bgr[1].u_ddr_mc_group/txn_fifo_output_reg[*]}]
set_property MAX_FANOUT 32 [get_cells {mts_i/ddr4_0/inst/u_ddr4_mem_intfc/u_ddr_mc/bgr[1].u_ddr_mc_group/cas_fifo_wptr[*]*}]
set_property LOC MMCM_X0Y2 [get_cells -hier -filter {NAME =~ */u_ddr4_infrastructure/gen_mmcme*.u_mmcme_adv_inst}]

set_property BLOCK_SYNTH.RETIMING 1 [get_cells mts_i/usp_rf_data_converter_1/*]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells mts_i/usp_rf_data_converter_1/*]
set_property BLOCK_SYNTH.RETIMING 1 [get_cells mts_i/hier_adc2_cap/axis_dwidth_converter_0/*]
set_property BLOCK_SYNTH.STRATEGY {PERFORMANCE_OPTIMIZED} [get_cells mts_i/hier_adc2_cap/axis_dwidth_converter_0/*]

# -------------- -------------- -------------- -------------- -------------- -------------- -------
# Timing Constraints
# -------------- -------------- -------------- -------------- -------------- -------------- -------
create_clock -period 2.000 -name PL_CLK_clk -waveform {0.000 1.000} [get_ports {PL_CLK_clk_p}]

# Input Delay for PL_SYSREF to ensure MTS requirements via PG269
set_input_delay -clock [get_clocks PL_CLK_clk] -min -add_delay 2.000 [get_ports PL_SYSREF_clk_p]
set_input_delay -clock [get_clocks PL_CLK_clk] -max -add_delay 2.031 [get_ports PL_SYSREF_clk_p]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets mts_i/clocktreeMTS/IBUFDS_PL_CLK/U0/USE_IBUFDS.GEN_IBUFDS[0].IBUFDS_I/O]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets mts_i/clocktreeMTS/BUFG_PL_CLK/U0/BUFG_O[0]]

set_false_path -from [get_ports reset]
set_false_path -from [get_pins {mts_i/gpio_control/axi_gpio_dac/U0/gpio_core_1/Not_Dual.gpio_Data_Out_reg[*]/C}]
set_false_path -from [get_pins {mts_i/clocktreeMTS/RFegressReset/U0/ACTIVE_LOW_PR_OUT_DFF[*].*/C}]

# -------------- -------------- -------------- -------------- -------------- -------------- -------
# Debug / Chipscope
# -------------- -------------- -------------- -------------- -------------- -------------- -------
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

# -------------- -------------- -------------- -------------- -------------- -------------- -------
# Bitstream Generation
# -------------- -------------- -------------- -------------- -------------- -------------- -------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [get_designs impl_1]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [get_designs impl_1]
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [get_designs impl_1]
set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [get_design impl_1]

