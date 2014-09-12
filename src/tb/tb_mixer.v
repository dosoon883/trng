//======================================================================
//
// tb_mixer.v
// -----------
// Testbench for the mixer module in the trng.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, Secworks Sweden AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/100ps


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_mixer();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 1;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;
  reg            tb_enable;
  reg            tb_more_seed;

  reg            tb_entropy0_enabled;
  reg            tb_entropy0_syn;
  reg [31 : 0]   tb_entropy0_data;
  wire           tb_entropy0_ack;

  reg            tb_entropy1_enabled;
  reg            tb_entropy1_syn;
  reg [31 : 0]   tb_entropy1_data;
  wire           tb_entropy1_ack;

  reg            tb_entropy2_enabled;
  reg            tb_entropy2_syn;
  reg [31 : 0]   tb_entropy2_data;
  wire           tb_entropy2_ack;

  wire [511 : 0] tb_seed_data;
  wire           tb_syn;
  reg            tb_ack;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  trng_mixer dut(
                 .clk(tb_clk),
                 .reset_n(tb_reset_n),

                 .enable(tb_enable),
                 .more_seed(tb_more_seed),

                 .entropy0_enabled(tb_entropy0_enabled),
                 .entropy0_syn(tb_entropy0_syn),
                 .entropy0_data(tb_entropy0_data),
                 .entropy0_ack(tb_entropy0_ack),

                 .entropy1_enabled(tb_entropy1_enabled),
                 .entropy1_syn(tb_entropy1_syn),
                 .entropy1_data(tb_entropy1_data),
                 .entropy1_ack(tb_entropy1_ack),

                 .entropy2_enabled(tb_entropy2_enabled),
                 .entropy2_syn(tb_entropy2_syn),
                 .entropy2_data(tb_entropy2_data),
                 .entropy2_ack(tb_entropy2_ack),

                 .seed_data(tb_seed_data),
                 .seed_syn(tb_syn),
                 .seed_ack(tb_ack)
                );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;

      #(CLK_PERIOD);

      if (DEBUG)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state();
    begin
      $display("cycle: 0x%016x", cycle_ctr);
      $display("State of DUT");
      $display("------------");
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut();
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;

      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
      $display("");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results();
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim();
    begin
      cycle_ctr           = 0;
      error_ctr           = 0;
      tc_ctr              = 0;

      tb_clk              = 0;
      tb_reset_n          = 1;

      tb_enable           = 0;
      tb_more_seed        = 0;

      tb_entropy0_enabled = 0;
      tb_entropy0_syn     = 0;
      tb_entropy0_data    = 32'h00000000;

      tb_entropy1_enabled = 0;
      tb_entropy1_syn     = 0;
      tb_entropy1_data    = 32'h00000000;

      tb_entropy2_enabled = 0;
      tb_entropy2_syn     = 0;
      tb_entropy2_data    = 32'h00000000;

      tb_ack              = 0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // tc1_gen_seeds()
  //
  // A simple first testcase that tries to make the DUT generate
  // a number of seeds based on entropy from source 0 and 2.
  //----------------------------------------------------------------
  task tc1_gen_seeds();
    begin
      $display("*** Starting TC1: Setting continious seed generation.");
      tb_entropy0_enabled = 1;
      tb_entropy0_syn     = 1;
      tb_entropy0_data    = 32'h01010202;

      tb_entropy2_enabled = 1;
      tb_entropy2_syn     = 1;
      tb_entropy2_data    = 32'haa55aa55;

      tb_enable           = 1;
      tb_more_seed        = 1;
      tb_ack              = 1;

      #(50000 * CLK_PERIOD);
      $display("*** TC1 done.");
    end
  endtask // tc1_gen_seeds


  //----------------------------------------------------------------
  // mixer_test
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : mixer_test

      $display("   -= Testbench for mixer started =-");
      $display("    ================================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

      tc1_gen_seeds();

      display_test_results();

      $display("");
      $display("*** Mixer simulation done. ***");
      $finish;
    end // mixer_test
endmodule // tb_mixer

//======================================================================
// EOF tb_mixer.v
//======================================================================