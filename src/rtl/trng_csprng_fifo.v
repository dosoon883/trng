//======================================================================
//
// trng_csprng_fifo.v
// ------------------
// Output FIFO for the CSPRNG in the TRNG.
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

module trng_csprng_fifo(
                        // Clock and reset.
                        input wire           clk,
                        input wire           reset_n,

                        input wire [511 : 0] csprng_data,
                        input wire           csprng_data_valid,
                        input wire           discard,
                        output wire          more_data,

                        output wire          rnd_syn,
                        output wire [31 : 0] rnd_data,
                        input wire           rnd_ack
                       );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter FIFO_DEPTH = 32;
  parameter FIFO_MAX = FIFO_DEPTH - 1;

  parameter WR_IDLE    = 0;
  parameter WR_WAIT    = 1;
  parameter WR_WRITE   = 2;
  parameter WR_DISCARD = 7;

  parameter RD_IDLE    = 0;
  parameter RD_ACK     = 1;
  parameter RD_DISCARD = 7;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] fifo_mem [0 : FIFO_MAX];
  reg          fifo_mem_we;

  reg [3 : 0] mux_data_ptr_reg;
  reg [3 : 0] mux_data_ptr_new;
  reg         mux_data_ptr_inc;
  reg         mux_data_ptr_rst;
  reg         mux_data_ptr_we;

  reg [7 : 0] wr_ptr_reg;
  reg [7 : 0] wr_ptr_new;
  reg         wr_ptr_inc;
  reg         wr_ptr_rst;
  reg         wr_ptr_we;

  reg [7 : 0] rd_ptr_reg;
  reg [7 : 0] rd_ptr_new;
  reg         rd_ptr_inc;
  reg         rd_ptr_rst;
  reg         rd_ptr_we;

  reg [31 : 0] rnd_data_reg;

  reg          rnd_syn_reg;
  reg          rnd_syn_new;
  reg          rnd_syn_we;

  reg [2 : 0]  wr_ctrl_reg;
  reg [2 : 0]  wr_ctrl_new;
  reg          wr_ctrl_we;

  reg [2 : 0]  rd_ctrl_reg;
  reg [2 : 0]  rd_ctrl_new;
  reg          rd_ctrl_we;

  reg [5 : 0]  fifo_ctr_reg;
  reg [5 : 0]  fifo_ctr_new;
  reg          fifo_ctr_inc;
  reg          fifo_ctr_dec;
  reg          fifo_ctr_rst;
  reg          fifo_ctr_we;
  reg          fifo_empty;
  reg          fifo_full;

  reg          more_data_reg;
  reg          more_data_new;
  reg          more_data_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0] muxed_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign rnd_data = rnd_data_reg;
  assign rnd_syn  = rnd_syn_reg;
  assign more_data = more_data_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          fifo_mem[00]     <= 32'h00000000;
          fifo_mem[01]     <= 32'h00000000;
          fifo_mem[02]     <= 32'h00000000;
          fifo_mem[03]     <= 32'h00000000;
          fifo_mem[04]     <= 32'h00000000;
          fifo_mem[05]     <= 32'h00000000;
          fifo_mem[06]     <= 32'h00000000;
          fifo_mem[07]     <= 32'h00000000;
          fifo_mem[08]     <= 32'h00000000;
          fifo_mem[09]     <= 32'h00000000;
          fifo_mem[10]     <= 32'h00000000;
          fifo_mem[11]     <= 32'h00000000;
          fifo_mem[12]     <= 32'h00000000;
          fifo_mem[13]     <= 32'h00000000;
          fifo_mem[14]     <= 32'h00000000;
          fifo_mem[15]     <= 32'h00000000;
          fifo_mem[16]     <= 32'h00000000;
          fifo_mem[17]     <= 32'h00000000;
          fifo_mem[18]     <= 32'h00000000;
          fifo_mem[19]     <= 32'h00000000;
          fifo_mem[20]     <= 32'h00000000;
          fifo_mem[21]     <= 32'h00000000;
          fifo_mem[22]     <= 32'h00000000;
          fifo_mem[23]     <= 32'h00000000;
          fifo_mem[24]     <= 32'h00000000;
          fifo_mem[25]     <= 32'h00000000;
          fifo_mem[26]     <= 32'h00000000;
          fifo_mem[27]     <= 32'h00000000;
          fifo_mem[28]     <= 32'h00000000;
          fifo_mem[29]     <= 32'h00000000;
          fifo_mem[30]     <= 32'h00000000;
          fifo_mem[31]     <= 32'h00000000;

          mux_data_ptr_reg <= 4'h0;
          wr_ptr_reg       <= 8'h00;
          rd_ptr_reg       <= 8'h00;
          fifo_ctr_reg     <= 6'h00;
          rnd_data_reg     <= 32'h00000000;
          rnd_syn_reg      <= 0;
          more_data_reg    <= 0;
          wr_ctrl_reg      <= 3'h0;
          rd_ctrl_reg      <= 3'h0;
        end
      else
        begin
          rnd_data_reg <= fifo_mem[rd_ptr_reg];

          if (rnd_syn_we)
            begin
              rnd_syn_reg  <= rnd_syn_new;
            end

          if (fifo_mem_we)
            begin
              fifo_mem[wr_ptr_reg] <= muxed_data;
            end

          if (mux_data_ptr_we)
            begin
              mux_data_ptr_reg <= mux_data_ptr_new;
            end

          if (wr_ptr_we)
            begin
              wr_ptr_reg <= wr_ptr_new;
            end

          if (rd_ptr_we)
            begin
              rd_ptr_reg <= rd_ptr_new;
            end

          if (fifo_ctr_we)
            begin
              fifo_ctr_reg <= fifo_ctr_new;
            end

          if (more_data_we)
            begin
              more_data_reg <= more_data_new;
            end

          if (wr_ctrl_we)
            begin
              wr_ctrl_reg <= wr_ctrl_new;
            end

          if (rd_ctrl_we)
            begin
              rd_ctrl_reg <= rd_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // data_mux
  //----------------------------------------------------------------
  always @*
    begin : data_mux
      case(mux_data_ptr_reg)
        00: muxed_data = csprng_data[031 : 000];
        01: muxed_data = csprng_data[063 : 032];
        02: muxed_data = csprng_data[095 : 064];
        03: muxed_data = csprng_data[127 : 096];
        04: muxed_data = csprng_data[159 : 128];
        05: muxed_data = csprng_data[191 : 160];
        06: muxed_data = csprng_data[223 : 192];
        07: muxed_data = csprng_data[255 : 224];
        08: muxed_data = csprng_data[287 : 256];
        09: muxed_data = csprng_data[313 : 282];
        10: muxed_data = csprng_data[351 : 320];
        11: muxed_data = csprng_data[383 : 351];
        12: muxed_data = csprng_data[415 : 384];
        13: muxed_data = csprng_data[447 : 416];
        14: muxed_data = csprng_data[479 : 448];
        15: muxed_data = csprng_data[511 : 480];
      endcase // case (mux_data_ptr_reg)
    end // data_mux


  //----------------------------------------------------------------
  // mux_data_ptr
  //----------------------------------------------------------------
  always @*
    begin : mux_data_ptr
      mux_data_ptr_new = 4'h0;
      mux_data_ptr_we  = 0;

      if (mux_data_ptr_rst)
        begin
          mux_data_ptr_new = 4'h0;
          mux_data_ptr_we  = 1;
        end

      if (mux_data_ptr_inc)
        begin
          mux_data_ptr_new = mux_data_ptr_reg + 1'b1;
          mux_data_ptr_we  = 1;
        end
    end // mux_data_ptr


  //----------------------------------------------------------------
  // fifo_rd_ptr
  //----------------------------------------------------------------
  always @*
    begin : fifo_rd_ptr
      rd_ptr_new = 8'h00;
      rd_ptr_we  = 0;

      if (rd_ptr_rst)
        begin
          rd_ptr_new = 8'h00;
          rd_ptr_we  = 1;
        end

      if (rd_ptr_inc)
        begin
          if (rd_ptr_reg == FIFO_MAX)
            begin
              rd_ptr_new = 8'h00;
              rd_ptr_we  = 1;
            end
          else
            begin
              rd_ptr_new = rd_ptr_reg + 1'b1;
              rd_ptr_we  = 1;
            end
        end
    end // fifo_rd_ptr


  //----------------------------------------------------------------
  // fifo_wr_ptr
  //----------------------------------------------------------------
  always @*
    begin : fifo_wr_ptr
      wr_ptr_new = 8'h00;
      wr_ptr_we  = 0;

      if (wr_ptr_rst)
        begin
          wr_ptr_new = 8'h00;
          wr_ptr_we  = 1;
        end

      if (wr_ptr_inc)
        begin
          if (wr_ptr_reg == FIFO_MAX)
            begin
              wr_ptr_new = 8'h00;
              wr_ptr_we  = 1;
            end
          else
            begin
              wr_ptr_new = wr_ptr_reg + 1'b1;
              wr_ptr_we  = 1;
            end
        end
    end // fifo_wr_ptr


  //----------------------------------------------------------------
  // fifo_ctr
  //
  // fifo counter tracks the number of elements and provides
  // signals for full and empty fifo.
  //----------------------------------------------------------------
  always @*
    begin : fifo_ctr
      fifo_empty = 0;
      fifo_full = 0;
      fifo_ctr_new = 6'h00;
      fifo_ctr_we  = 0;

      if (fifo_ctr_reg == FIFO_DEPTH)
        begin
          fifo_full = 1;
        end

      if (fifo_ctr_reg < 6'h0f)
        begin
          fifo_empty = 1;
        end

      if (fifo_ctr_inc)
        begin
          fifo_ctr_new = fifo_ctr_reg + 1'b1;
          fifo_ctr_we  = 1;
        end

      if (fifo_ctr_dec)
        begin
          fifo_ctr_new = fifo_ctr_reg - 1'b1;
          fifo_ctr_we  = 1;
        end

      if (fifo_ctr_rst)
        begin
          fifo_ctr_new = 6'h00;
          fifo_ctr_we  = 1;
        end
    end // fifo_ctr


  //----------------------------------------------------------------
  // rd_ctrl
  //----------------------------------------------------------------
  always @*
    begin : rd_ctrl
      fifo_ctr_dec = 0;
      rnd_syn_new  = 0;
      rnd_syn_we   = 0;
      rd_ptr_inc   = 0;
      rd_ptr_rst   = 0;
      rd_ctrl_new  = RD_IDLE;
      rd_ctrl_we   = 0;

      case (rd_ctrl_reg)
        RD_IDLE:
          begin
            if (discard)
              begin
                rd_ctrl_new = RD_DISCARD;
                rd_ctrl_we  = 1;
              end
            else
              begin
                if (!fifo_empty)
                  begin
                    rnd_syn_new = 1;
                    rnd_syn_we  = 1;
                    rd_ctrl_new = RD_ACK;
                    rd_ctrl_we  = 1;
                  end
              end
          end

        RD_ACK:
          begin
            if (discard)
              begin
                rd_ctrl_new = RD_DISCARD;
                rd_ctrl_we  = 1;
              end
            else
              begin
                if (rnd_ack)
                  begin
                    fifo_ctr_dec = 1;
                    rd_ptr_inc   = 1;
                    rnd_syn_new  = 0;
                    rnd_syn_we   = 1;
                    rd_ctrl_new  = RD_IDLE;
                    rd_ctrl_we   = 1;
                  end
              end
          end

        RD_DISCARD:
          begin
            rnd_syn_new = 0;
            rnd_syn_we  = 1;
            rd_ptr_rst  = 1;
            rd_ctrl_new = RD_IDLE;
            rd_ctrl_we  = 1;

          end

      endcase // case (rd_ctrl_reg)

    end // rd_ctrl


  //----------------------------------------------------------------
  // wr_ctrl
  //----------------------------------------------------------------
  always @*
    begin : wr_ctrl
      more_data_new    = 0;
      more_data_we     = 0;
      mux_data_ptr_rst = 0;
      mux_data_ptr_inc = 0;
      wr_ptr_inc       = 0;
      wr_ptr_rst       = 0;
      fifo_mem_we      = 0;
      fifo_ctr_inc     = 0;
      fifo_ctr_rst     = 0;
      wr_ctrl_new      = WR_IDLE;
      wr_ctrl_we       = 0;

      case (wr_ctrl_reg)
        WR_IDLE:
          begin
            if (discard)
              begin
                wr_ctrl_new = WR_DISCARD;
                wr_ctrl_we  = 1;
              end
            else if (!fifo_full)
              begin
                more_data_new = 1;
                more_data_we  = 1;
                wr_ctrl_new   = WR_WAIT;
                wr_ctrl_we    = 1;
              end
          end

        WR_WAIT:
          begin
            if (discard)
              begin
                wr_ctrl_new      = WR_DISCARD;
                wr_ctrl_we       = 1;
              end
            else if (csprng_data_valid)
              begin
                more_data_new    = 0;
                more_data_we     = 1;
                mux_data_ptr_rst = 1;
                wr_ctrl_new      = WR_WRITE;
                wr_ctrl_we       = 1;
              end
          end

        WR_WRITE:
          begin
            if (discard)
              begin
                wr_ctrl_new      = WR_DISCARD;
                wr_ctrl_we       = 1;
              end
            else if (!fifo_full)
              begin
                fifo_mem_we      = 1;
                wr_ptr_inc       = 1;
                mux_data_ptr_inc = 1;
                fifo_ctr_inc     = 1;

                if (mux_data_ptr_new == 4'h0)
                  begin
                    wr_ctrl_new = WR_IDLE;
                    wr_ctrl_we  = 1;
                  end
              end
          end

        WR_DISCARD:
          begin
            fifo_ctr_rst     = 1;
            more_data_new    = 0;
            more_data_we     = 1;
            mux_data_ptr_rst = 1;
            wr_ptr_rst       = 1;
            wr_ctrl_new      = WR_IDLE;
            wr_ctrl_we       = 1;
          end
      endcase // case (wr_ctrl_reg)

    end // wr_ctrl

endmodule // trng_csprng_fifo

//======================================================================
// EOF trng_csprng_fifo.v
//======================================================================