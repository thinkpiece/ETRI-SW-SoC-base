/*
 *  blk_mem_wrapper.v -- true 2-port block ram with parameterized read latency
 *  ETRI <SW-SoC AI Deep Learning HW Accelerator RTL Design> course material
 *
 *  history:
 *    first drafted by Junyoung Park
 *    behaviour model added by Junyoung Park
 *    1-clock throughput read operations supported by Junyoung Park
 */
`timescale 1ns / 1ps

module blk_mem_wrapper #(
  parameter ADDR_WIDTH   = 10,
  parameter READ_LATENCY = 3
  )(
  // clock and resetn from domain a
  input wire                   clk_a,
  input wire                   arstz_aq,

  // block memory control signals for port a
  cnnip_mem_if.slave           mem_if_a,

  // clock and resetn from domain b
  input wire                   clk_b,
  input wire                   arstz_bq,
  // block memory control signals for port b
  cnnip_mem_if.slave           mem_if_b
  );

  // control signals
  logic en_to_blkmem_a;
  logic en_to_blkmem_b;
  // logic valid_to_ext_a;
  // logic valid_to_ext_b;

  logic read_a_flag;
  logic read_b_flag;

  assign read_a_flag = mem_if_a.en && ((|mem_if_a.we) == 1'b0);
  assign read_b_flag = mem_if_b.en && ((|mem_if_b.we) == 1'b0);

  genvar idx;
  generate
    if (READ_LATENCY == 1)
    begin: read_latency_single

      // control all signals with simple assignments
      // for domain a
      assign en_to_blkmem_a = mem_if_a.en;
      assign mem_if_a.valid = read_a_flag;
      // for domain b
      assign en_to_blkmem_b = mem_if_b.en;
      assign mem_if_b.valid = read_b_flag;

    end
    else
    begin: read_latency_multi

      // Xilinx's block memory has output register options. Users must hold
      // the enable signal high for enabling the output registers. The output
      // registers are up to 2 stages, which means the read latency will be
      // up to 3 clock cycles.

      // for domain a ----------------------------------------------------------
      logic [READ_LATENCY-2:0] en_hold_a;

      // prologue
      always_ff @(posedge clk_a, negedge arstz_aq)
        if (arstz_aq == 1'b0) en_hold_a[0] <= 1'b0;
        else en_hold_a[0] <= read_a_flag;
      // body
      for (idx=1; idx<READ_LATENCY-2; idx=idx+1)
      begin
        always_ff @(posedge clk_a, negedge arstz_aq)
          if (arstz_aq == 1'b0) en_hold_a[idx]<= 1'b0;
          else en_hold_a[idx] <= en_hold_a[idx-1];
      end
      // epilogue
      assign en_to_blkmem_a = mem_if_a.en || (|en_hold_a);
      assign mem_if_a.valid = en_hold_a[READ_LATENCY-2];

      // for domain a ----------------------------------------------------------
      logic [READ_LATENCY-2:0] en_hold_b;

      // prologue
      always_ff @(posedge clk_b, negedge arstz_bq)
        if (arstz_bq == 1'b0) en_hold_b[0] <= 1'b0;
        else en_hold_b[0] <= read_b_flag;
      // body
      for (idx=1; idx<READ_LATENCY-2; idx=idx+1)
      begin
        always_ff @(posedge clk_b, negedge arstz_bq)
          if (arstz_bq == 1'b0) en_hold_b[idx]<= 1'b0;
          else en_hold_b[idx] <= en_hold_b[idx-1];
      end
      // epilogue
      assign en_to_blkmem_b = mem_if_b.en || (|en_hold_b);
      assign mem_if_b.valid = en_hold_b[READ_LATENCY-2];

    end
  endgenerate

`ifdef SIM_VER

  blk_mem_sim #(
    .DATA_WIDTH  (32),
    .DATA_DEPTH  (256),
    .READ_LATENCY(READ_LATENCY)
  ) i_blk_mem (
    .clka(clk_a),
    .ena(en_to_blkmem_a),
    .wea(mem_if_a.we),
    .addra(mem_if_a.addr[ADDR_WIDTH-1:2]),
    .dina(mem_if_a.din),
    .douta(mem_if_a.dout),

    .clkb(clk_b),
    .enb(en_to_blkmem_b),
    .web(mem_if_b.we),
    .addrb(mem_if_b.addr[ADDR_WIDTH-1:2]),
    .dinb(mem_if_b.din),
    .doutb(mem_if_b.dout)
  );


`else

  // native block memory connections -------------------------------------------
  blk_mem_gen_0 i_blk_mem (
    .clka(clk_a),
    .ena(en_to_blkmem_a),
    .wea(mem_if_a.we),
    .addra(mem_if_a.addr[ADDR_WIDTH-1:2]),
    .dina(mem_if_a.din),
    .douta(mem_if_a.dout),

    .clkb(clk_b),
    .enb(en_to_blkmem_b),
    .web(mem_if_b.we),
    .addrb(mem_if_b.addr[ADDR_WIDTH-1:2]),
    .dinb(mem_if_b.din),
    .doutb(mem_if_b.dout)
  );
  // ---------------------------------------------------------------------------

`endif

endmodule
