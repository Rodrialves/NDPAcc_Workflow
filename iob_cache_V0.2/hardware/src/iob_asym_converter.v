// SPDX-FileCopyrightText: 2024 IObundle
//
// SPDX-License-Identifier: MIT

`timescale 1ns / 1ps

module iob_asym_converter #(
   parameter W_DATA_W = 21,
   parameter R_DATA_W = 21,
   parameter ADDR_W = 3,  //higher ADDR_W lower DATA_W
   //determine W_ADDR_W and R_ADDR_W
   parameter MAXDATA_W = iob_max(W_DATA_W, R_DATA_W),
   parameter MINDATA_W = iob_min(W_DATA_W, R_DATA_W),
   parameter R = MAXDATA_W / MINDATA_W,
   parameter MINADDR_W = ADDR_W - $clog2(R),  //lower ADDR_W (higher DATA_W)
   parameter W_ADDR_W = (W_DATA_W == MAXDATA_W) ? MINADDR_W : ADDR_W,
   parameter R_ADDR_W = (R_DATA_W == MAXDATA_W) ? MINADDR_W : ADDR_W
) (
   // clk_en_rst_s
   input                  clk_i,
   input                  cke_i,
   input                  arst_i,
   // rst_i
   input                  rst_i,
   // write_i
   input                  w_en_i,
   input  [ W_ADDR_W-1:0] w_addr_i,
   input  [ W_DATA_W-1:0] w_data_i,
   // read_io
   input                  r_en_i,
   input  [ R_ADDR_W-1:0] r_addr_i,
   output [ R_DATA_W-1:0] r_data_o,
   // extmem_io
   output [        R-1:0] ext_mem_w_en_o,
   output [MINADDR_W-1:0] ext_mem_w_addr_o,
   output [MAXDATA_W-1:0] ext_mem_w_data_o,
   output [        R-1:0] ext_mem_r_en_o,
   output [MINADDR_W-1:0] ext_mem_r_addr_o,
   input  [MAXDATA_W-1:0] ext_mem_r_data_i
);

   // SPDX-FileCopyrightText: 2024 IObundle
   //
   // SPDX-License-Identifier: MIT

   function [31:0] iob_max;
      input [31:0] a;
      input [31:0] b;
      begin
         if (a > b) iob_max = a;
         else iob_max = b;
      end
   endfunction

   function [31:0] iob_min;
      input [31:0] a;
      input [31:0] b;
      begin
         if (a < b) iob_min = a;
         else iob_min = b;
      end
   endfunction

   function [31:0] iob_cshift_left;
      input [31:0] DATA;
      input integer DATA_W;
      input integer SHIFT;
      begin
         iob_cshift_left = (DATA << SHIFT) | (DATA >> (DATA_W - SHIFT));
      end
   endfunction

   function [31:0] iob_cshift_right;
      input [31:0] DATA;
      input integer DATA_W;
      input integer SHIFT;
      begin
         iob_cshift_right = (DATA >> SHIFT) | (DATA << (DATA_W - SHIFT));
      end
   endfunction
   //Data is valid after read enable
   wire r_data_valid_reg;
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) r_data_valid_reg_inst (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rst_i),
      .data_i(r_en_i),
      .data_o(r_data_valid_reg)
   );

   //Register read data from the memory
   wire [MAXDATA_W-1:0] r_data_reg;
   iob_reg_re #(
      .DATA_W (MAXDATA_W),
      .RST_VAL({MAXDATA_W{1'd0}})
   ) r_data_reg_inst (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rst_i),
      .en_i  (r_data_valid_reg),
      .data_i(ext_mem_r_data_i),
      .data_o(r_data_reg)
   );

   reg [MAXDATA_W-1:0] r_data_int;
   always @* begin
      if (r_data_valid_reg) begin
         r_data_int = ext_mem_r_data_i;
      end else begin
         r_data_int = r_data_reg;
      end
   end

   //Generate the RAM based on the parameters
   generate
      if (W_DATA_W > R_DATA_W) begin : g_write_wider
         //memory write port
         assign ext_mem_w_en_o   = {R{w_en_i}};
         assign ext_mem_w_addr_o = w_addr_i;
         assign ext_mem_w_data_o = w_data_i;

         //register to hold the LSBs of r_addr
         wire [$clog2(R)-1:0] r_addr_lsbs_reg;
         iob_reg_e #(
            .DATA_W ($clog2(R)),
            .RST_VAL({$clog2(R) {1'd0}})
         ) r_addr_reg_inst (
            .clk_i (clk_i),
            .cke_i (cke_i),
            .arst_i(arst_i),
            .en_i  (r_en_i),
            .data_i(r_addr_i[$clog2(R)-1:0]),
            .data_o(r_addr_lsbs_reg)
         );

         //memory read port
         assign ext_mem_r_en_o   = {{(R - 1) {1'd0}}, r_en_i} << r_addr_i[$clog2(R)-1:0];
         assign ext_mem_r_addr_o = r_addr_i[R_ADDR_W-1:$clog2(R)];

         wire [W_DATA_W-1:0] r_data;
         assign r_data   = r_data_int >> (r_addr_lsbs_reg * R_DATA_W);
         assign r_data_o = r_data[R_DATA_W-1:0];

      end else if (W_DATA_W < R_DATA_W) begin : g_read_wider
         //memory write port
         assign ext_mem_w_en_o = {{(R - 1) {1'd0}}, w_en_i} << w_addr_i[$clog2(R)-1:0];
         assign ext_mem_w_data_o = {{(R_DATA_W - W_DATA_W) {1'd0}}, w_data_i} << (w_addr_i[$clog2(
             R
         )-1:0] * W_DATA_W);
         assign ext_mem_w_addr_o = w_addr_i[W_ADDR_W-1:$clog2(R)];

         //memory read port
         assign ext_mem_r_en_o = {R{r_en_i}};
         assign ext_mem_r_addr_o = r_addr_i;
         assign r_data_o = r_data_int;

      end else begin : g_same_width
         //W_DATA_W == R_DATA_W
         //memory write port
         assign ext_mem_w_en_o   = w_en_i;
         assign ext_mem_w_addr_o = w_addr_i;
         assign ext_mem_w_data_o = w_data_i;

         //memory read port
         assign ext_mem_r_en_o   = r_en_i;
         assign ext_mem_r_addr_o = r_addr_i;
         assign r_data_o         = r_data_int;
      end
   endgenerate
endmodule

