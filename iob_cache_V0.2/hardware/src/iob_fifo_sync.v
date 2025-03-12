// SPDX-FileCopyrightText: 2024 IObundle
//
// SPDX-License-Identifier: MIT

`timescale 1ns / 1ps

module iob_fifo_sync #(
   parameter W_DATA_W = 21,
   R_DATA_W = 21,
   ADDR_W = 21,  //higher ADDR_W lower DATA_W
   //determine W_ADDR_W and R_ADDR_W
   MAXDATA_W = iob_max(W_DATA_W, R_DATA_W),
   MINDATA_W = iob_min(W_DATA_W, R_DATA_W),
   R = MAXDATA_W / MINDATA_W,
   MINADDR_W = ADDR_W - $clog2(R),  //lower ADDR_W (higher DATA_W)
   W_ADDR_W = (W_DATA_W == MAXDATA_W) ? MINADDR_W : ADDR_W,
   R_ADDR_W = (R_DATA_W == MAXDATA_W) ? MINADDR_W : ADDR_W
) (
   // clk_en_rst_s
   input                  clk_i,
   input                  cke_i,
   input                  arst_i,
   // rst_i
   input                  rst_i,
   // write_io
   input                  w_en_i,
   input  [ W_DATA_W-1:0] w_data_i,
   output                 w_full_o,
   // read_io
   input                  r_en_i,
   output [ R_DATA_W-1:0] r_data_o,
   output                 r_empty_o,
   // extmem_io
   output                 ext_mem_clk_o,
   output [        R-1:0] ext_mem_w_en_o,
   output [MINADDR_W-1:0] ext_mem_w_addr_o,
   output [MAXDATA_W-1:0] ext_mem_w_data_o,
   output [        R-1:0] ext_mem_r_en_o,
   output [MINADDR_W-1:0] ext_mem_r_addr_o,
   input  [MAXDATA_W-1:0] ext_mem_r_data_i,
   // fifo_o
   output [ ADDR_W+1-1:0] level_o
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
   localparam ADDR_W_DIFF = $clog2(R);
   localparam [ADDR_W:0] FIFO_SIZE = {1'b1, {ADDR_W{1'b0}}};  //in bytes

   //effective write enable
   wire                w_en_int = (w_en_i & (~w_full_o));

   //write address
   wire [W_ADDR_W-1:0] w_addr;
   iob_counter #(
      .DATA_W (W_ADDR_W),
      .RST_VAL({W_ADDR_W{1'd0}})
   ) w_addr_cnt0 (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),

      .rst_i (rst_i),
      .en_i  (w_en_int),
      .data_o(w_addr)
   );

   //effective read enable
   wire                r_en_int = (r_en_i & (~r_empty_o));

   //read address
   wire [R_ADDR_W-1:0] r_addr;
   iob_counter #(
      .DATA_W (R_ADDR_W),
      .RST_VAL({R_ADDR_W{1'd0}})
   ) r_addr_cnt0 (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),

      .rst_i (rst_i),
      .en_i  (r_en_int),
      .data_o(r_addr)
   );

   //assign according to assymetry type
   localparam [ADDR_W-1:0] W_INCR = (W_DATA_W > R_DATA_W) ?
                  {{ADDR_W-1{1'd0}},{1'd1}} << ADDR_W_DIFF : {{ADDR_W-1{1'd0}},{1'd1}};
   localparam [ADDR_W-1:0] R_INCR = (R_DATA_W > W_DATA_W) ?
                  {{ADDR_W-1{1'd0}},{1'd1}} << ADDR_W_DIFF : {{ADDR_W-1{1'd0}},{1'd1}};

   //FIFO level
   reg  [ADDR_W:0] level_nxt;
   wire [ADDR_W:0] level_int;
   iob_reg_r #(
      .DATA_W (ADDR_W + 1),
      .RST_VAL({(ADDR_W + 1) {1'd0}})
   ) level_reg0 (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),

      .rst_i(rst_i),

      .data_i(level_nxt),
      .data_o(level_int)
   );

   reg [(ADDR_W+1)-1:0] level_incr;
   always @* begin
      level_incr = level_int + W_INCR;
      level_nxt  = level_int;
      if (w_en_int && (!r_en_int))  //write only
         level_nxt = level_incr;
      else if (w_en_int && r_en_int)  //write and read
         level_nxt = level_incr - R_INCR;
      else if (r_en_int)  //read only
         level_nxt = level_int - R_INCR;
   end

   assign level_o = level_int;

   //FIFO empty
   wire r_empty_nxt;
   assign r_empty_nxt = level_nxt < {1'b0, R_INCR};
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL(1'd1)
   ) r_empty_reg0 (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rst_i),
      .data_i(r_empty_nxt),
      .data_o(r_empty_o)
   );

   //FIFO full
   wire w_full_nxt;
   assign w_full_nxt = level_nxt > (FIFO_SIZE - W_INCR);
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL(1'd0)
   ) w_full_reg0 (
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      .rst_i (rst_i),
      .data_i(w_full_nxt),
      .data_o(w_full_o)
   );

   assign ext_mem_clk_o = clk_i;

   iob_asym_converter #(
      .W_DATA_W(W_DATA_W),
      .R_DATA_W(R_DATA_W),
      .ADDR_W  (ADDR_W)
   ) asym_converter (
      .ext_mem_w_en_o  (ext_mem_w_en_o),
      .ext_mem_w_addr_o(ext_mem_w_addr_o),
      .ext_mem_w_data_o(ext_mem_w_data_o),
      .ext_mem_r_en_o  (ext_mem_r_en_o),
      .ext_mem_r_addr_o(ext_mem_r_addr_o),
      .ext_mem_r_data_i(ext_mem_r_data_i),
      .clk_i           (clk_i),
      .cke_i           (cke_i),
      .arst_i          (arst_i),
      .rst_i           (rst_i),
      .w_addr_i        (w_addr),
      .w_en_i          (w_en_int),
      .w_data_i        (w_data_i),
      .r_addr_i        (r_addr),
      .r_en_i          (r_en_int),
      .r_data_o        (r_data_o)
   );

endmodule
