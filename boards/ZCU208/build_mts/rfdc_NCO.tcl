
# clocktreeMTS/MTSclkwiz changes (fabric rates now ~62.5/31.250 MHz)
set cw [get_bd_cells clocktreeMTS/MTSclkwiz]
set_property -dict [list \
  CONFIG.CLKOUT1_JITTER {114.922} \
  CONFIG.CLKOUT1_PHASE_ERROR {70.309} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {62.50} \
  CONFIG.CLKOUT2_JITTER {131.463} \
  CONFIG.CLKOUT2_PHASE_ERROR {70.309} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {31.250} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {6.375} \
  CONFIG.MMCM_DIVCLK_DIVIDE {2} \
] $cw

set_property -dict [list \
  CONFIG.PL_Clock_Freq {62.5} \
  CONFIG.ADC0_Fabric_Freq {62.500} \
  CONFIG.ADC0_Multi_Tile_Sync {true} \
  CONFIG.ADC_Data_Type00 {1} \
  CONFIG.ADC_Decimation_Mode00 {8} \
  CONFIG.ADC_Mixer_Type00 {2} \
  CONFIG.ADC_Mixer_Mode00 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq00 {0} \
  CONFIG.ADC_NCO_Freq00 {0.5} \
  CONFIG.ADC_RESERVED_1_00 {0} \
  CONFIG.ADC_Data_Type01 {1} \
  CONFIG.ADC_Decimation_Mode01 {8} \
  CONFIG.ADC_Mixer_Type01 {2} \
  CONFIG.ADC_Mixer_Mode01 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq01 {0} \
  CONFIG.ADC_Data_Type02 {1} \
  CONFIG.ADC_Decimation_Mode02 {8} \
  CONFIG.ADC_Mixer_Type02 {2} \
  CONFIG.ADC_Mixer_Mode02 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq02 {0} \
  CONFIG.ADC_NCO_Freq02 {0.5} \
  CONFIG.ADC_RESERVED_1_02 {0} \
  CONFIG.ADC_Data_Type03 {1} \
  CONFIG.ADC_Decimation_Mode03 {8} \
  CONFIG.ADC_Mixer_Type03 {2} \
  CONFIG.ADC_Mixer_Mode03 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq03 {0} \
  CONFIG.ADC1_Fabric_Freq {62.500} \
  CONFIG.ADC1_Multi_Tile_Sync {true} \
  CONFIG.ADC_Data_Type10 {1} \
  CONFIG.ADC_Decimation_Mode10 {8} \
  CONFIG.ADC_Mixer_Type10 {2} \
  CONFIG.ADC_Mixer_Mode10 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq10 {0} \
  CONFIG.ADC_NCO_Freq10 {0.5} \
  CONFIG.ADC_RESERVED_1_10 {0} \
  CONFIG.ADC_Data_Type11 {1} \
  CONFIG.ADC_Decimation_Mode11 {8} \
  CONFIG.ADC_Mixer_Type11 {2} \
  CONFIG.ADC_Mixer_Mode11 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq11 {0} \
  CONFIG.ADC_Data_Type12 {1} \
  CONFIG.ADC_Decimation_Mode12 {8} \
  CONFIG.ADC_Mixer_Type12 {2} \
  CONFIG.ADC_Mixer_Mode12 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq12 {0} \
  CONFIG.ADC_NCO_Freq12 {0.5} \
  CONFIG.ADC_RESERVED_1_12 {0} \
  CONFIG.ADC_Data_Type13 {1} \
  CONFIG.ADC_Decimation_Mode13 {8} \
  CONFIG.ADC_Mixer_Type13 {2} \
  CONFIG.ADC_Mixer_Mode13 {0} \
  CONFIG.ADC_Coarse_Mixer_Freq13 {0} \
  CONFIG.DAC0_Fabric_Freq {62.500} \
  CONFIG.DAC0_Multi_Tile_Sync {true} \
  CONFIG.DAC_Data_Width00 {16} \
  CONFIG.DAC_Interpolation_Mode00 {8} \
  CONFIG.DAC_Mixer_Type00 {2} \
  CONFIG.DAC_Mixer_Mode00 {0} \
  CONFIG.DAC_NCO_Freq00 {0.5} \
  CONFIG.DAC_RESERVED_1_00 {0} \
  CONFIG.DAC_RESERVED_1_01 {0} \
  CONFIG.DAC_Data_Width02 {16} \
  CONFIG.DAC_Interpolation_Mode02 {8} \
  CONFIG.DAC_Mixer_Type02 {2} \
  CONFIG.DAC_Mixer_Mode02 {0} \
  CONFIG.DAC_NCO_Freq02 {0.5} \
  CONFIG.DAC_RESERVED_1_02 {0} \
  CONFIG.DAC_RESERVED_1_03 {0} \
  CONFIG.DAC1_Fabric_Freq {62.500} \
  CONFIG.DAC1_Multi_Tile_Sync {true} \
  CONFIG.DAC_Data_Width10 {16} \
  CONFIG.DAC_Interpolation_Mode10 {8} \
  CONFIG.DAC_Mixer_Type10 {2} \
  CONFIG.DAC_Mixer_Mode10 {0} \
  CONFIG.DAC_NCO_Freq10 {0.5} \
  CONFIG.DAC_RESERVED_1_10 {0} \
  CONFIG.DAC_RESERVED_1_11 {0} \
  CONFIG.DAC_Data_Width12 {16} \
  CONFIG.DAC_Interpolation_Mode12 {8} \
  CONFIG.DAC_Mixer_Type12 {2} \
  CONFIG.DAC_Mixer_Mode12 {0} \
  CONFIG.DAC_NCO_Freq12 {0.5} \
  CONFIG.DAC2_Fabric_Freq {62.500} \
  CONFIG.DAC_Data_Width20 {16} \
  CONFIG.DAC_Interpolation_Mode20 {8} \
  CONFIG.DAC_Mixer_Type20 {2} \
  CONFIG.DAC_Mixer_Mode20 {0} \
  CONFIG.DAC_NCO_Freq20 {0.5} \
  CONFIG.DAC_RESERVED_1_20 {0} \
  CONFIG.DAC_RESERVED_1_21 {0} \
  CONFIG.DAC_RESERVED_1_22 {0} \
  CONFIG.DAC_RESERVED_1_23 {0} \
  CONFIG.DAC_RESERVED_1_12 {0} \
  CONFIG.DAC_RESERVED_1_13 {0} \
] [get_bd_cells usp_rf_data_converter_1]



# RF Data Converter parameter updates (enable DUC/DDC + NCO, I/Q types/widths, decim/interp)
# set rfdc [get_bd_cells usp_rf_data_converter_1]
# ] $rfdc

