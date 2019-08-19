/*
 *  cnnip_fifo.sv -- basic FIFO module with single clock
 *  ETRI <SW-SoC AI Deep Learning HW Accelerator RTL Design> course material
 *
 *  first draft by Junyoung Park
 */

`timescale 1ns / 1ps

module cnnip_fifo #(
  parameter WIDTH = 32,
  parameter DEPTH = 4
) (
  input  wire             clk_a,
  input  wire             arstz_aq,
  input  wire             push_a,
  input  wire             pop_a,
  input  wire [WIDTH-1:0] din_a,
  output wire             empty_a,
  output wire             full_a,
  output wire [WIDTH-1:0] dout_a
);

  localparam addr_width = $clog2(DEPTH);

  // support multi-depth only (write your own code if you need 1-depth fifo)
  reg  [WIDTH-1:0]      mem[DEPTH-1:0];
  reg  [addr_width-1:0] in_ptr;
  reg  [addr_width-1:0] out_ptr;
  wire [addr_width-1:0] in_ptr_next;
  wire [addr_width-1:0] out_ptr_next;
  wire                  out_ptr_reset;
  wire                  in_ptr_reset;
  reg                   not_empty;
  reg                   not_empty_next;
  reg                   full_aq;
  reg                   empty_aq;

  // assignments
  assign empty_a = empty_aq;
  assign full_a  = full_aq;

  always @(posedge clk_a, negedge arstz_aq)
    if (arstz_aq == 1'b0) empty_aq <= 1;
    else empty_aq <= (in_ptr_next == out_ptr_next) && !not_empty_next;

  always @(posedge clk_a, negedge arstz_aq)
    if (arstz_aq == 1'b0) full_aq <= 1;
    else full_aq <= (in_ptr_next == out_ptr_next) && not_empty_next;

  assign dout_a = mem[out_ptr];

  assign out_ptr_next = (pop_a   == 1'b0)    ? out_ptr :
                        (out_ptr == DEPTH-1) ? 0       : out_ptr + 1'b1;

  assign in_ptr_next = (push_a == 1'b0)    ? in_ptr :
                       (in_ptr == DEPTH-1) ? 0      : in_ptr + 1'b1;

  // sequential blocks
  always @(posedge clk_a, negedge arstz_aq)
    if (arstz_aq == 1'b0) out_ptr <= 0;
    else out_ptr <= out_ptr_next;

  always @(posedge clk_a, negedge arstz_aq)
    if (arstz_aq == 1'b0) in_ptr <= 0;
    else in_ptr <= in_ptr_next;

  assign out_ptr_reset = ((out_ptr == DEPTH-1) & pop_a);
  assign in_ptr_reset  = ((in_ptr == DEPTH-1) & push_a);

  always @(posedge clk_a, negedge arstz_aq)
    if (arstz_aq == 1'b0) not_empty <= 0;
    else not_empty <= not_empty_next;

  always @(*)
    if (out_ptr_reset & in_ptr_reset)   not_empty_next = not_empty;
    else if (out_ptr_reset | in_ptr_reset) not_empty_next = ~not_empty;
    else not_empty_next = not_empty;

  always @(posedge clk_a)
    if (push_a) mem[in_ptr] <= din_a;

endmodule // cnnip_fifo