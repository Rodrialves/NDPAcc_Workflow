`timescale 1ns / 1ps
`include "iob_bsp.vh"
`include "iob_reverse_conf.vh"

module iob_reverse #(
   parameter DATA_W = `IOB_REVERSE_DATA_W
) (
   // data_i
   input  [DATA_W-1:0] data_i,
   // data_o
   output [DATA_W-1:0] data_o
);

   genvar pos;
   generate
      for (pos = 0; pos < DATA_W; pos = pos + 1) begin : reverse
         assign data_o[pos] = data_i[(DATA_W-1)-pos];
      end
   endgenerate




endmodule
