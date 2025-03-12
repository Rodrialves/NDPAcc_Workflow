// SPDX-FileCopyrightText: 2024 IObundle
//
// SPDX-License-Identifier: MIT

`timescale 1ns / 10ps
`include "iob_cache_conf.vh"
`include "iob_cache_csrs_def.vh"

module iob_cache_tb;

   //clock
   parameter clk_per = 10;
   reg clk = 1;
   always #clk_per clk = ~clk;

   parameter FE_ADDR_W = `IOB_CACHE_FE_ADDR_W;
   parameter FE_DATA_W = `IOB_CACHE_FE_DATA_W;
   parameter FE_NBYTES = FE_DATA_W / 8;
   parameter FE_NBYTES_W = $clog2(FE_NBYTES);
   parameter USE_CTRL = `IOB_CACHE_USE_CTRL;
   parameter USE_CTRL_CNT = `IOB_CACHE_USE_CTRL_CNT;

   parameter ADDR_W = USE_CTRL + FE_ADDR_W - FE_NBYTES_W;
   parameter DATA_W = `IOB_CACHE_DATA_W;


   reg                 rst = 1;

   //frontend signals
   reg  [       1-1:0] iob_valid_i;
   reg  [  ADDR_W-1:0] iob_addr_i;
   reg  [  DATA_W-1:0] iob_wdata_i;
   reg  [DATA_W/8-1:0] iob_wstrb_i;
   wire [       1-1:0] iob_rvalid_o;
   wire [  DATA_W-1:0] iob_rdata_o;
   wire [       1-1:0] iob_ready_o;
   reg                 ctrl = 0;

   //iterator
   integer i, fd, failed = 0;

   reg [DATA_W-1:0] rdata;


   //test process
   initial begin

`define VCD = 1;

`ifdef VCD
      $dumpfile("uut.vcd");
      $dumpvars(0, iob_cache_tb);
`endif
      iob_valid_i = 0;
      iob_addr_i  = 0;
      iob_wdata_i = 0;
      iob_wstrb_i = 0;

      repeat (5) @(posedge clk);
      rst = 0;
      #10;

      $display("Writing data to frontend");
      for (i = 0; i < 5 * 4; i = i + 4) begin
         iob_write(i, (3 * i), `IOB_CACHE_DATA_W);
      end

      #80 @(posedge clk);

      $display("Reading data from frontend");
      for (i = 0; i < 5 * 4; i = i + 4) begin
         iob_read(i, rdata, `IOB_CACHE_DATA_W);
         //Write "Test passed!" to a file named "test.log"
         if (rdata !== (3 * i)) begin
            $display("ERROR at address %d: got 0x%0h, expected 0x%0h", i, rdata, 3 * i);
            failed = failed + 1;
         end
      end

      #100;

      fd = $fopen("test.log", "w");

      if (failed == 0) begin
         $display("%c[1;34m", 27);
         $display("Test completed successfully.");
         $display("%c[0m", 27);
         $fwrite(fd, "Test passed!");
      end else begin
         $display("Test failed!");
         $fwrite(fd, "Test failed!");
      end
      $fclose(fd);
      $finish();
   end

   //Unit Under Test (simulation wrapper)
   iob_cache_sim_wrapper uut (
      //frontend
      .iob_valid_i (iob_valid_i),
      .iob_addr_i  (iob_addr_i),
      .iob_wdata_i (iob_wdata_i),
      .iob_wstrb_i (iob_wstrb_i),
      .iob_rvalid_o(iob_rvalid_o),
      .iob_rdata_o (iob_rdata_o),
      .iob_ready_o (iob_ready_o),
      //invalidate / wtb empty
      .invalidate_i(1'b0),
      .invalidate_o(),
      .wtb_empty_i (1'b1),
      .wtb_empty_o (),

      .clk_i (clk),
      .arst_i(rst)
   );

   // SPDX-FileCopyrightText: 2024 IObundle
   //
   // SPDX-License-Identifier: MIT

   //
   // Tasks for the IOb Native protocol
   //

   `define IOB_NBYTES (DATA_W/8)
   `define IOB_GET_NBYTES(WIDTH) (WIDTH/8 + |(WIDTH%8))
   `define IOB_NBYTES_W $clog2(`IOB_NBYTES)
   `define IOB_WORD_ADDR(ADDR) ((ADDR>>`IOB_NBYTES_W)<<`IOB_NBYTES_W)

   `define IOB_BYTE_OFFSET(ADDR) (ADDR%(DATA_W/8))

   `define IOB_GET_WDATA(ADDR, DATA) (DATA<<(8*`IOB_BYTE_OFFSET(ADDR)))
   `define IOB_GET_WSTRB(ADDR, WIDTH) (((1<<`IOB_GET_NBYTES(WIDTH))-1)<<`IOB_BYTE_OFFSET(ADDR))
   `define IOB_GET_RDATA(ADDR, DATA, WIDTH) ((DATA>>(8*`IOB_BYTE_OFFSET(ADDR)))&((1<<WIDTH)-1))

   // Write data to IOb Native slave
   task iob_write;
      input [ADDR_W-1:0] addr;
      input [DATA_W-1:0] data;
      input [$clog2(DATA_W):0] width;

      begin
         @(posedge clk) #1 iob_valid_i = 1;  //sync and assign
         iob_addr_i  = `IOB_WORD_ADDR(addr);
         iob_wdata_i = `IOB_GET_WDATA(addr, data);
         iob_wstrb_i = `IOB_GET_WSTRB(addr, width);

         #1 while (!iob_ready_o) #1;

         @(posedge clk) iob_valid_i = 0;
         iob_wstrb_i = 0;
      end
   endtask

   // Read data from IOb Native slave
   task iob_read;
      input [ADDR_W-1:0] addr;
      output [DATA_W-1:0] data;
      input [$clog2(DATA_W):0] width;

      begin
         @(posedge clk) #1 iob_valid_i = 1;
         iob_addr_i  = `IOB_WORD_ADDR(addr);
         iob_wstrb_i = 0;

         #1 while (!iob_ready_o) #1;
         @(posedge clk) #1 iob_valid_i = 0;

         while (!iob_rvalid_o) #1;
         data = #1 `IOB_GET_RDATA(addr, iob_rdata_o, width);
      end
   endtask

endmodule

