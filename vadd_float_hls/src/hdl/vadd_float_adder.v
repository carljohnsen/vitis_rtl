`default_nettype none
`timescale 1ps / 1ps

module vadd_float_adder #(
    parameter integer C_AXIS_TDATA_WIDTH = 32
)
(
    input wire ap_aclk,
    input wire ap_areset,

    input wire                             s_axis_a_tvalid,
    output wire                            s_axis_a_tready,
    input wire  [C_AXIS_TDATA_WIDTH-1:0]   s_axis_a_tdata,
    input wire  [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_a_tkeep,
    input wire                             s_axis_a_tlast,

    input wire                             s_axis_b_tvalid,
    output wire                            s_axis_b_tready,
    input wire  [C_AXIS_TDATA_WIDTH-1:0]   s_axis_b_tdata,
    input wire  [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_b_tkeep,
    input wire                             s_axis_b_tlast,

    output wire                            m_axis_c_tvalid,
    input  wire                            m_axis_c_tready,
    output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_c_tdata,
    output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_c_tkeep,
    output wire                            m_axis_c_tlast
);

localparam integer LP_FIFO_DEPTH = 16;
localparam integer LP_FIFO_COUNT_WIDTH = $clog2(LP_FIFO_DEPTH)+1;
localparam integer LP_FIFO_READ_LATENCY = 2; // 2: Registered output on BRAM, 1: Registered output on LUTRAM

assign s_axis_a_tready = ~fifoa_full;
assign s_axis_b_tready = ~fifob_full;
wire fifoa_full;
wire fifob_full;

xpm_fifo_sync # (
  .FIFO_MEMORY_TYPE    ( "auto"               ) , // string; "auto", "block", "distributed", or "ultra";
  .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
  .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
  .WRITE_DATA_WIDTH    ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
  .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
  .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
  .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
  .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
  .READ_DATA_WIDTH     ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
  .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
  .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
)
inst_fifo_a (
  .sleep         ( 1'b0                        ) ,
  .rst           ( ap_areset                      ) ,
  .wr_clk        ( ap_aclk                        ) ,
  .wr_en         ( s_axis_a_tvalid                ) ,
  .din           ( {s_axis_a_tlast, s_axis_a_tdata}   ) ,
  .full          ( fifoa_full                  ) ,
  .overflow      (                             ) ,
  .prog_full     (                             ) ,
  .wr_data_count (                             ) ,
  .almost_full   (                             ) ,
  .wr_ack        (                             ) ,
  .wr_rst_busy   (                             ) ,
  .rd_en         ( fla_tready               ) ,
  .dout          ( {fla_tlast,fla_tdata} ) ,
  .empty         (                             ) ,
  .prog_empty    (                             ) ,
  .rd_data_count (                             ) ,
  .almost_empty  (                             ) ,
  .data_valid    ( fla_tvalid               ) ,
  .underflow     (                             ) ,
  .rd_rst_busy   (                             ) ,
  .injectsbiterr ( 1'b0                        ) ,
  .injectdbiterr ( 1'b0                        ) ,
  .sbiterr       (                             ) ,
  .dbiterr       (                             )
);

xpm_fifo_sync # (
  .FIFO_MEMORY_TYPE    ( "auto"               ) , // string; "auto", "block", "distributed", or "ultra";
  .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
  .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
  .WRITE_DATA_WIDTH    ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
  .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
  .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
  .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
  .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
  .READ_DATA_WIDTH     ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
  .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
  .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
)
inst_fifo_b (
  .sleep         ( 1'b0                        ) ,
  .rst           ( ap_areset                      ) ,
  .wr_clk        ( ap_aclk                        ) ,
  .wr_en         ( s_axis_b_tvalid                ) ,
  .din           ( {s_axis_b_tlast, s_axis_b_tdata}   ) ,
  .full          ( fifob_full                  ) ,
  .overflow      (                             ) ,
  .prog_full     (                             ) ,
  .wr_data_count (                             ) ,
  .almost_full   (                             ) ,
  .wr_ack        (                             ) ,
  .wr_rst_busy   (                             ) ,
  .rd_en         ( flb_tready               ) ,
  .dout          ( {flb_tlast,flb_tdata} ) ,
  .empty         (                             ) ,
  .prog_empty    (                             ) ,
  .rd_data_count (                             ) ,
  .almost_empty  (                             ) ,
  .data_valid    ( flb_tvalid               ) ,
  .underflow     (                             ) ,
  .rd_rst_busy   (                             ) ,
  .injectsbiterr ( 1'b0                        ) ,
  .injectdbiterr ( 1'b0                        ) ,
  .sbiterr       (                             ) ,
  .dbiterr       (                             )
);

wire                         fla_tvalid;
wire                         fla_tready;
wire [C_AXIS_TDATA_WIDTH-1:0] fla_tdata;
wire                         fla_tlast;

wire                         flb_tvalid;
wire                         flb_tready;
wire [C_AXIS_TDATA_WIDTH-1:0] flb_tdata;
wire                         flb_tlast;

floating_point_0 inst_float_add (
    .aclk            (ap_aclk),
    .s_axis_a_tvalid (fla_tvalid),
    .s_axis_a_tready (fla_tready),
    .s_axis_a_tdata  (fla_tdata),
    .s_axis_a_tlast  (fla_tlast),

    .s_axis_b_tvalid (flb_tvalid),
    .s_axis_b_tready (flb_tready),
    .s_axis_b_tdata  (flb_tdata),
    .s_axis_b_tlast  (flb_tlast),

    .m_axis_result_tvalid (flc_tvalid),
    .m_axis_result_tready (flc_tready),
    .m_axis_result_tdata  (flc_tdata),
    .m_axis_result_tlast  (flc_tlast)
);

wire                         flc_tvalid;
wire                         flc_tready;
wire [C_AXIS_TDATA_WIDTH-1:0] flc_tdata;
wire                         flc_tlast;

assign flc_tready = ~fifoc_full;
wire fifoc_full;

xpm_fifo_sync # (
  .FIFO_MEMORY_TYPE    ( "auto"               ) , // string; "auto", "block", "distributed", or "ultra";
  .ECC_MODE            ( "no_ecc"             ) , // string; "no_ecc" or "en_ecc";
  .FIFO_WRITE_DEPTH    ( LP_FIFO_DEPTH        ) , // positive integer
  .WRITE_DATA_WIDTH    ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .WR_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_FULL_THRESH    ( 10                   ) , // positive integer, not used
  .FULL_RESET_VALUE    ( 1                    ) , // positive integer; 0 or 1
  .USE_ADV_FEATURES    ( "1F1F"               ) , // string; "0000" to "1F1F";
  .READ_MODE           ( "fwft"               ) , // string; "std" or "fwft";
  .FIFO_READ_LATENCY   ( LP_FIFO_READ_LATENCY ) , // positive integer;
  .READ_DATA_WIDTH     ( C_AXIS_TDATA_WIDTH+1 ) , // positive integer
  .RD_DATA_COUNT_WIDTH ( LP_FIFO_COUNT_WIDTH  ) , // positive integer, not used
  .PROG_EMPTY_THRESH   ( 10                   ) , // positive integer, not used
  .DOUT_RESET_VALUE    ( "0"                  ) , // string, don't care
  .WAKEUP_TIME         ( 0                    ) // positive integer; 0 or 2;
)
inst_fifo_c (
  .sleep         ( 1'b0                        ) ,
  .rst           ( ap_areset                      ) ,
  .wr_clk        ( ap_aclk                        ) ,
  .wr_en         ( flc_tvalid                ) ,
  .din           ( {flc_tlast, flc_tdata}   ) ,
  .full          ( fifoc_full                  ) ,
  .overflow      (                             ) ,
  .prog_full     (                             ) ,
  .wr_data_count (                             ) ,
  .almost_full   (                             ) ,
  .wr_ack        (                             ) ,
  .wr_rst_busy   (                             ) ,
  .rd_en         ( m_axis_c_tready               ) ,
  .dout          ( {m_axis_c_tlast,m_axis_c_tdata} ) ,
  .empty         (                             ) ,
  .prog_empty    (                             ) ,
  .rd_data_count (                             ) ,
  .almost_empty  (                             ) ,
  .data_valid    ( m_axis_c_tvalid               ) ,
  .underflow     (                             ) ,
  .rd_rst_busy   (                             ) ,
  .injectsbiterr ( 1'b0                        ) ,
  .injectdbiterr ( 1'b0                        ) ,
  .sbiterr       (                             ) ,
  .dbiterr       (                             )
);


endmodule

`default_nettype wire

