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
// Latency: 2: Registered output on BRAM, 1: Registered output on LUTRAM
localparam integer LP_FIFO_READ_LATENCY = 2;

(* DONT_TOUCH = "yes" *)
reg aresetn = 1'b1;
always @(posedge ap_aclk) begin
    aresetn = ~ap_areset;
end

floating_point_0 inst_float_add (
    .aclk    ( ap_aclk ),
    .aresetn ( aresetn ),

    .s_axis_a_tvalid ( s_axis_a_tvalid ),
    .s_axis_a_tready ( s_axis_a_tready ),
    .s_axis_a_tdata  ( s_axis_a_tdata ),
    .s_axis_a_tlast  ( s_axis_a_tlast ),

    .s_axis_b_tvalid ( s_axis_b_tvalid ),
    .s_axis_b_tready ( s_axis_b_tready ),
    .s_axis_b_tdata  ( s_axis_b_tdata ),
    .s_axis_b_tlast  ( s_axis_b_tlast ),

    .m_axis_result_tvalid ( m_axis_c_tvalid ),
    .m_axis_result_tready ( m_axis_c_tready ),
    .m_axis_result_tdata  ( m_axis_c_tdata ),
    .m_axis_result_tlast  ( m_axis_c_tlast )
);

endmodule

`default_nettype wire

