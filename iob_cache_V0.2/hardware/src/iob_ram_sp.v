`timescale 1ns / 1ps
`include "iob_bsp.vh"
`include "iob_ram_sp_conf.vh"

module iob_ram_sp #(
   parameter HEXFILE = `IOB_RAM_SP_HEXFILE,
   parameter DATA_W = `IOB_RAM_SP_DATA_W,
   parameter ADDR_W = `IOB_RAM_SP_ADDR_W,
   parameter MEM_INIT_FILE_INT =
   `IOB_RAM_SP_MEM_INIT_FILE_INT  // Don't change this parameter value!
) (
   // clk_i
   input               clk_i,
   // en_i
   input               en_i,
   // we_i
   input               we_i,
   // addr_i
   input  [ADDR_W-1:0] addr_i,
   // d_o
   output [DATA_W-1:0] d_o,
   // d_i
   input  [DATA_W-1:0] d_i
);



   // Declare the RAM
   reg [DATA_W-1:0] ram     [2**ADDR_W-1:0];
   reg [DATA_W-1:0] d_o_reg;
   assign d_o = d_o_reg;

   // Initialize the RAM
   initial if (MEM_INIT_FILE_INT != "none") $readmemh(MEM_INIT_FILE_INT, ram, 0, 2 ** ADDR_W - 1);

   // Operate the RAM
   always @(posedge clk_i)
      if (en_i)
         if (we_i) ram[addr_i] <= d_i;
         else d_o_reg <= ram[addr_i];




endmodule
