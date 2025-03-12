`timescale 1ns / 1ps
`include "iob_bsp.vh"
`include "iob_ram_sp_be_conf.vh"

module iob_ram_sp_be #(
   parameter HEXFILE = `IOB_RAM_SP_BE_HEXFILE,
   parameter ADDR_W  = `IOB_RAM_SP_BE_ADDR_W,
   parameter DATA_W  = `IOB_RAM_SP_BE_DATA_W,
   parameter COL_W   = `IOB_RAM_SP_BE_COL_W,    // Don't change this parameter value!
   parameter NUM_COL = `IOB_RAM_SP_BE_NUM_COL   // Don't change this parameter value!
) (
   // clk_i
   input                 clk_i,
   // mem_if_io
   input                 en_i,
   input  [DATA_W/8-1:0] we_i,
   input  [  ADDR_W-1:0] addr_i,
   input  [  DATA_W-1:0] d_i,
   output [  DATA_W-1:0] d_o
);




   // Operation
`ifdef IOB_MEM_NO_READ_ON_WRITE
   localparam file_suffix = {"7", "6", "5", "4", "3", "2", "1", "0"};

   genvar i;
   generate
      for (i = 0; i < NUM_COL; i = i + 1) begin : ram_col
         localparam mem_init_file_int = (HEXFILE != "none") ?
             {HEXFILE, "_", file_suffix[8*(i+1)-1-:8], ".hex"} : "none";

         iob_ram_sp #(
            .HEXFILE(mem_init_file_int),
            .ADDR_W (ADDR_W),
            .DATA_W (COL_W)
         ) ram (
            .clk_i(clk_i),

            .en_i  (en_i),
            .addr_i(addr_i),
            .d_i   (d_i[i*COL_W+:COL_W]),
            .we_i  (we_i[i]),
            .d_o   (d_o[i*COL_W+:COL_W])
         );
      end
   endgenerate
`else  // !IOB_MEM_NO_READ_ON_WRITE
   // this allows ISE 14.7 to work; do not remove
   localparam mem_init_file_int = {HEXFILE, ".hex"};

   // Core Memory
   reg [DATA_W-1:0] ram_block[(2**ADDR_W)-1:0];

   // Initialize the RAM
   initial
      if (mem_init_file_int != "none.hex")
         $readmemh(mem_init_file_int, ram_block, 0, 2 ** ADDR_W - 1);

   reg     [DATA_W-1:0] d_o_int;
   integer              i;
   always @(posedge clk_i) begin
      if (en_i) begin
         for (i = 0; i < NUM_COL; i = i + 1) begin
            if (we_i[i]) begin
               ram_block[addr_i][i*COL_W+:COL_W] <= d_i[i*COL_W+:COL_W];
            end
         end
         d_o_int <= ram_block[addr_i];  // Send Feedback
      end
   end

   assign d_o = d_o_int;
`endif




endmodule
