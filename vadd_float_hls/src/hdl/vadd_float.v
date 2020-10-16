`default_nettype none
`timescale 1 ns / 1 ps

module vadd_float #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32,
  parameter integer C_AXIS_TDATA_WIDTH          = 32
)
(
  // System Signals
  input  wire                                    ap_clk,
  input  wire                                    ap_rst_n,

  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid,
  output wire                                    s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr,
  input  wire                                    s_axi_control_wvalid,
  output wire                                    s_axi_control_wready,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb,
  input  wire                                    s_axi_control_arvalid,
  output wire                                    s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr,
  output wire                                    s_axi_control_rvalid,
  input  wire                                    s_axi_control_rready,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata,
  output wire [2-1:0]                            s_axi_control_rresp,
  output wire                                    s_axi_control_bvalid,
  input  wire                                    s_axi_control_bready,
  output wire [2-1:0]                            s_axi_control_bresp,

  input  wire                            s_axis_a_tvalid,
  input  wire [C_AXIS_TDATA_WIDTH-1:0]   s_axis_a_tdata,
  output wire                            s_axis_a_tready,
  input  wire [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_a_tkeep,
  input  wire                            s_axis_a_tlast,

  input  wire                            s_axis_b_tvalid,
  input  wire [C_AXIS_TDATA_WIDTH-1:0]   s_axis_b_tdata,
  output wire                            s_axis_b_tready,
  input  wire [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_b_tkeep,
  input  wire                            s_axis_b_tlast,

  output wire                            m_axis_c_tvalid,
  output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_c_tdata,
  input  wire                            m_axis_c_tready,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_c_tkeep,
  output wire                            m_axis_c_tlast
);

(* DONT_TOUCH = "yes" *)
reg                                 areset                         = 1'b0;
//reg ap_idle = 1'b1;
//reg ap_done = 1'b0;
//wire ap_start;
//reg ap_start_r = 1'b0;
//wire ap_start_pulse;

always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

//always @(posedge ap_clk) begin
//    ap_start_r <= ap_start;
//end
//assign ap_start_pulse = ap_start & ~ap_start_r;
//
//always @(posedge ap_clk) begin
//    if (areset) begin
//        ap_idle <= 1'b1;
//    end else begin
//        ap_idle <= ap_done ? 1'b1 : ap_start_pulse ? 1'b0 : ap_idle;
//    end
//end
//
//always @(posedge ap_clk) begin
//    if (areset) begin
//        ap_done <= 1'b0;
//    end else begin
//        ap_done <= ap_done ? 1'b0 : 1'b1;
//    end
//end

vadd_float_control #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_vadd_float_control (
  .ACLK       ( ap_clk ),
  .ARESET     ( areset ),
  .ACLK_EN    ( 1'b1 ),
  .AWVALID    ( s_axi_control_awvalid ),
  .AWREADY    ( s_axi_control_awready ),
  .AWADDR     ( s_axi_control_awaddr ),
  .WVALID     ( s_axi_control_wvalid ),
  .WREADY     ( s_axi_control_wready ),
  .WDATA      ( s_axi_control_wdata ),
  .WSTRB      ( s_axi_control_wstrb ),
  .ARVALID    ( s_axi_control_arvalid ),
  .ARREADY    ( s_axi_control_arready ),
  .ARADDR     ( s_axi_control_araddr ),
  .RVALID     ( s_axi_control_rvalid ),
  .RREADY     ( s_axi_control_rready ),
  .RDATA      ( s_axi_control_rdata ),
  .RRESP      ( s_axi_control_rresp ),
  .BVALID     ( s_axi_control_bvalid ),
  .BREADY     ( s_axi_control_bready ),
  .BRESP      ( s_axi_control_bresp ),
  //.ap_start   ( ap_start ),
  //.ap_done    ( ap_done ),
  //.ap_ready   ( ap_done ),
  //.ap_idle    ( ap_idle )
);

vadd_float_adder #(
    .C_AXIS_TDATA_WIDTH ( C_AXIS_TDATA_WIDTH )
)
inst_adder (
    .ap_aclk   ( ap_clk ),
    .ap_areset ( areset ),

    .s_axis_a_tvalid ( s_axis_a_tvalid ),
    .s_axis_a_tdata  ( s_axis_a_tdata ),
    .s_axis_a_tready ( s_axis_a_tready ),
    .s_axis_a_tkeep  ( s_axis_a_tkeep ),
    .s_axis_a_tlast  ( s_axis_a_tlast ),

    .s_axis_b_tvalid ( s_axis_b_tvalid ),
    .s_axis_b_tdata  ( s_axis_b_tdata ),
    .s_axis_b_tready ( s_axis_b_tready ),
    .s_axis_b_tkeep  ( s_axis_b_tkeep ),
    .s_axis_b_tlast  ( s_axis_b_tlast ),

    .m_axis_c_tvalid ( m_axis_c_tvalid ),
    .m_axis_c_tdata  ( m_axis_c_tdata ),
    .m_axis_c_tready ( m_axis_c_tready ),
    .m_axis_c_tkeep  ( m_axis_c_tkeep ),
    .m_axis_c_tlast  ( m_axis_c_tlast )
);

endmodule
`default_nettype wire
