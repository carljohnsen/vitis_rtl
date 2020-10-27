`default_nettype none
`timescale 1ps / 1ps

module vadd_float_adder #(
  parameter integer C_AXIS_TDATA_WIDTH = 512
)
(
  input wire ap_aclk,
  input wire ap_areset,

  input  wire                          s_axis_a_tvalid,
  output wire                          s_axis_a_tready,
  input  wire [C_AXIS_TDATA_WIDTH-1:0] s_axis_a_tdata,
  input  wire                          s_axis_a_tlast,

  input wire                           s_axis_b_tvalid,
  output wire                          s_axis_b_tready,
  input wire  [C_AXIS_TDATA_WIDTH-1:0] s_axis_b_tdata,
  input wire                           s_axis_b_tlast,

  output wire                          m_axis_result_tvalid,
  input  wire                          m_axis_result_tready,
  output wire [C_AXIS_TDATA_WIDTH-1:0] m_axis_result_tdata,
  output wire                          m_axis_result_tlast
);

/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// RTL Logic
/////////////////////////////////////////////////////////////////////////////

(* DONT_TOUCH = "yes" *)
reg aresetn = 1'b1;
always @(posedge ap_aclk) begin
    aresetn = ~ap_areset;
end

floating_point_0 inst_float_add (
    .aclk (ap_aclk),
    .aresetn (aresetn),

    .s_axis_a_tvalid (s_axis_a_tvalid),
    .s_axis_a_tready (s_axis_a_tready),
    .s_axis_a_tdata  (s_axis_a_tdata),
    .s_axis_a_tlast  (s_axis_a_tlast),

    .s_axis_b_tvalid (s_axis_b_tvalid),
    .s_axis_b_tready (s_axis_b_tready),
    .s_axis_b_tdata  (s_axis_b_tdata),
    .s_axis_b_tlast  (s_axis_b_tlast),

    .m_axis_result_tvalid (m_axis_result_tvalid),
    .m_axis_result_tready (m_axis_result_tready),
    .m_axis_result_tdata  (m_axis_result_tdata),
    .m_axis_result_tlast  (m_axis_result_tlast)
);

endmodule

`default_nettype wire

