`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// trigger_core.v
//
// Inputs are assumed already synchronous to `clk` (handle CDC in BD).
// aresetn is active-LOW, synchronous to `clk` domain (typical PSR output).
//
// Behavior:
// - When enable=0 -> triggered_q=0 (disarmed, FIFO can be held in reset).
// - When enable=1 -> waits for a rising edge of (soft_trig | hw_trig).
//   On that first rising edge, pulse_out asserts for 1 clk, and triggered_q latches to 1.
// - triggered_q stays 1 until enable goes back to 0 (re-arm cycle).
//////////////////////////////////////////////////////////////////////////////////


module trigger_core(
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_RESET aresetn" *)

    input wire clk,
    // Active-low reset
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    
    input wire aresetn, 
    input wire enable,
    input wire soft_trig,
    input wire hw_trig,
    output reg triggered_q,
    output wire pulse_out
    );

// Combine triggers (levels)
  wire or_sync = soft_trig | hw_trig;

  // Edge detector registers
  reg or_sync_q;
  reg or_sync_dly;

  // 1-clock rising-edge pulse; masked by reset and enable
  assign pulse_out = aresetn & enable & (or_sync_q & ~or_sync_dly);

  always @(posedge clk) begin
    if (~aresetn) begin
      or_sync_q    <= 1'b0;
      or_sync_dly  <= 1'b0;
      triggered_q  <= 1'b0;
    end else begin
      // register combined trigger and its 1-cycle delay
      or_sync_q    <= or_sync;
      or_sync_dly  <= or_sync_q;

      // Latch: Q_next = ((Q | (pulse & enable)) & enable) & rstn
      if (!enable)
        triggered_q <= 1'b0;                 // disarm clears latch
      else if (or_sync_q & ~or_sync_dly)     // rising edge while armed
        triggered_q <= 1'b1;                 // first-wins
      // else: hold previous triggered_q
    end
  end

endmodule
