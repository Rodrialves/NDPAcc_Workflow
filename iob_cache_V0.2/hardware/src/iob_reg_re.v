`timescale 1ns / 1ps
`include "iob_bsp.vh"
`include "iob_reg_re_conf.vh"

module iob_reg_re #(
   parameter DATA_W  = `IOB_REG_RE_DATA_W,
   parameter RST_VAL = `IOB_REG_RE_RST_VAL
) (
   // clk_en_rst_s
   input               clk_i,
   input               cke_i,
   input               arst_i,
   // en_rst_i
   input               en_i,
   input               rst_i,
   // data_i
   input  [DATA_W-1:0] data_i,
   // data_o
   output [DATA_W-1:0] data_o
);
   // data_int
   wire [DATA_W-1:0] data_int;


   // Default description
   iob_reg_r #(
      .DATA_W (DATA_W),
      .RST_VAL(RST_VAL)
   ) reg0 (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // rst_i port
      .rst_i (rst_i),
      // data_i port
      .data_i(data_int),
      // data_o port
      .data_o(data_o)
   );




   assign data_int = en_i ? data_i : data_o;




endmodule
