`default_nettype none
`timescale 1 ns / 1 ps

module vadd_float #(
    parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12,
    parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32,
    parameter integer C_M_AXI_ADDR_WIDTH         = 64,
    parameter integer C_M_AXI_DATA_WIDTH         = 32,
    parameter integer C_M_AXI_ID_WIDTH           = 1,
    parameter integer C_XFER_SIZE_WIDTH          = 32
)
(
    // System Signals
    input  wire ap_clk,
    input  wire ap_rst_n,

    // AXI4 master interface
    output wire                                 m_axi_a_AWVALID,
    input  wire                                 m_axi_a_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_a_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_AWID,
    output wire [7:0]                           m_axi_a_AWLEN,
    output wire [2:0]                           m_axi_a_AWSIZE,
    output wire [1:0]                           m_axi_a_AWBURST,
    output wire [1:0]                           m_axi_a_AWLOCK,
    output wire [3:0]                           m_axi_a_AWCACHE,
    output wire [2:0]                           m_axi_a_AWPROT,
    output wire [3:0]                           m_axi_a_AWQOS,
    output wire [3:0]                           m_axi_a_AWREGION,
    output wire                                 m_axi_a_WVALID,
    input  wire                                 m_axi_a_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_a_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_a_WSTRB,
    output wire                                 m_axi_a_WLAST,
    output wire                                 m_axi_a_ARVALID,
    input  wire                                 m_axi_a_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_a_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_a_ARID,
    output wire [7:0]                           m_axi_a_ARLEN,
    output wire [2:0]                           m_axi_a_ARSIZE,
    output wire [1:0]                           m_axi_a_ARBURST,
    output wire [1:0]                           m_axi_a_ARLOCK,
    output wire [3:0]                           m_axi_a_ARCACHE,
    output wire [2:0]                           m_axi_a_ARPROT,
    output wire [3:0]                           m_axi_a_ARQOS,
    output wire [3:0]                           m_axi_a_ARREGION,
    input  wire                                 m_axi_a_RVALID,
    output wire                                 m_axi_a_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_a_RDATA,
    input  wire                            m_axi_a_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_RID,
    input  wire [1:0]                      m_axi_a_RRESP,
    input  wire                            m_axi_a_BVALID,
    output wire                            m_axi_a_BREADY,
    input  wire [1:0]                      m_axi_a_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_BID,

    // AXI4 master interface
    output wire                                 m_axi_b_AWVALID,
    input  wire                                 m_axi_b_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_b_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_AWID,
    output wire [7:0]                           m_axi_b_AWLEN,
    output wire [2:0]                           m_axi_b_AWSIZE,
    output wire [1:0]                           m_axi_b_AWBURST,
    output wire [1:0]                           m_axi_b_AWLOCK,
    output wire [3:0]                           m_axi_b_AWCACHE,
    output wire [2:0]                           m_axi_b_AWPROT,
    output wire [3:0]                           m_axi_b_AWQOS,
    output wire [3:0]                           m_axi_b_AWREGION,
    output wire                                 m_axi_b_WVALID,
    input  wire                                 m_axi_b_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_b_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_b_WSTRB,
    output wire                                 m_axi_b_WLAST,
    output wire                                 m_axi_b_ARVALID,
    input  wire                                 m_axi_b_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_b_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_b_ARID,
    output wire [7:0]                           m_axi_b_ARLEN,
    output wire [2:0]                           m_axi_b_ARSIZE,
    output wire [1:0]                           m_axi_b_ARBURST,
    output wire [1:0]                           m_axi_b_ARLOCK,
    output wire [3:0]                           m_axi_b_ARCACHE,
    output wire [2:0]                           m_axi_b_ARPROT,
    output wire [3:0]                           m_axi_b_ARQOS,
    output wire [3:0]                           m_axi_b_ARREGION,
    input  wire                                 m_axi_b_RVALID,
    output wire                                 m_axi_b_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_b_RDATA,
    input  wire                                 m_axi_b_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_RID,
    input  wire [1:0]                           m_axi_b_RRESP,
    input  wire                                 m_axi_b_BVALID,
    output wire                                 m_axi_b_BREADY,
    input  wire [1:0]                           m_axi_b_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_BID,

    // AXI4 master interface
    output wire                                 m_axi_result_AWVALID,
    input  wire                                 m_axi_result_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_result_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_AWID,
    output wire [7:0]                           m_axi_result_AWLEN,
    output wire [2:0]                           m_axi_result_AWSIZE,
    output wire [1:0]                           m_axi_result_AWBURST,
    output wire [1:0]                           m_axi_result_AWLOCK,
    output wire [3:0]                           m_axi_result_AWCACHE,
    output wire [2:0]                           m_axi_result_AWPROT,
    output wire [3:0]                           m_axi_result_AWQOS,
    output wire [3:0]                           m_axi_result_AWREGION,
    output wire                                 m_axi_result_WVALID,
    input  wire                                 m_axi_result_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_result_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_result_WSTRB,
    output wire                                 m_axi_result_WLAST,
    output wire                                 m_axi_result_ARVALID,
    input  wire                                 m_axi_result_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_result_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_result_ARID,
    output wire [7:0]                           m_axi_result_ARLEN,
    output wire [2:0]                           m_axi_result_ARSIZE,
    output wire [1:0]                           m_axi_result_ARBURST,
    output wire [1:0]                           m_axi_result_ARLOCK,
    output wire [3:0]                           m_axi_result_ARCACHE,
    output wire [2:0]                           m_axi_result_ARPROT,
    output wire [3:0]                           m_axi_result_ARQOS,
    output wire [3:0]                           m_axi_result_ARREGION,
    input  wire                                 m_axi_result_RVALID,
    output wire                                 m_axi_result_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_result_RDATA,
    input  wire                                 m_axi_result_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_RID,
    input  wire [1:0]                           m_axi_result_RRESP,
    input  wire                                 m_axi_result_BVALID,
    output wire                                 m_axi_result_BREADY,
    input  wire [1:0]                           m_axi_result_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_BID,

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
    output wire                                    interrupt
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* DONT_TOUCH = "yes" *)
reg  areset = 1'b0;
wire ap_start;
wire ap_idle;
wire ap_done;
wire ap_ready;

wire [C_XFER_SIZE_WIDTH-1:0]  xfer_size;
wire [C_M_AXI_ADDR_WIDTH-1:0] a;
wire [C_M_AXI_ADDR_WIDTH-1:0] b;
wire [C_M_AXI_ADDR_WIDTH-1:0] c;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

///////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.
///////////////////////////////////////////////////////////////////////////////

// AXI4-Lite slave interface
vadd_float_control #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control (
  .ACLK    ( ap_clk ),
  .ARESET  ( areset ),
  .ACLK_EN ( 1'b1 ),

  .AWVALID ( s_axi_control_awvalid ),
  .AWREADY ( s_axi_control_awready ),
  .AWADDR  ( s_axi_control_awaddr ),
  .WVALID  ( s_axi_control_wvalid ),
  .WREADY  ( s_axi_control_wready ),
  .WDATA   ( s_axi_control_wdata ),
  .WSTRB   ( s_axi_control_wstrb ),
  .ARVALID ( s_axi_control_arvalid ),
  .ARREADY ( s_axi_control_arready ),
  .ARADDR  ( s_axi_control_araddr ),
  .RVALID  ( s_axi_control_rvalid ),
  .RREADY  ( s_axi_control_rready ),
  .RDATA   ( s_axi_control_rdata ),
  .RRESP   ( s_axi_control_rresp ),
  .BVALID  ( s_axi_control_bvalid ),
  .BREADY  ( s_axi_control_bready ),
  .BRESP   ( s_axi_control_bresp ),

  .interrupt ( interrupt ),
  .ap_start  ( ap_start ),
  .ap_done   ( ap_done ),
  .ap_ready  ( ap_ready ),
  .ap_idle   ( ap_idle ),

  .xfer_size ( xfer_size ),
  .a ( a ),
  .b ( b ),
  .c ( c )
);

///////////////////////////////////////////////////////////////////////////////
// Add kernel logic here.
///////////////////////////////////////////////////////////////////////////////

vadd_float_int #(
    .C_M_AXI_ADDR_WIDTH ( C_M_AXI_ADDR_WIDTH ),
    .C_M_AXI_DATA_WIDTH ( C_M_AXI_DATA_WIDTH ),
    .C_M_AXI_ID_WIDTH   ( C_M_AXI_ID_WIDTH ),
    .C_XFER_SIZE_WIDTH  ( C_XFER_SIZE_WIDTH )
)
inst_example (
    .ap_clk   ( ap_clk ),
    .ap_rst_n ( ap_rst_n ),

    .m_axi_a_AWVALID  ( m_axi_a_AWVALID ),
    .m_axi_a_AWREADY  ( m_axi_a_AWREADY ),
    .m_axi_a_AWADDR   ( m_axi_a_AWADDR ),
    .m_axi_a_AWID     ( m_axi_a_AWID ),
    .m_axi_a_AWLEN    ( m_axi_a_AWLEN ),
    .m_axi_a_AWSIZE   ( m_axi_a_AWSIZE ),
    .m_axi_a_AWBURST  ( m_axi_a_AWBURST ),
    .m_axi_a_AWLOCK   ( m_axi_a_AWLOCK ),
    .m_axi_a_AWCACHE  ( m_axi_a_AWCACHE ),
    .m_axi_a_AWPROT   ( m_axi_a_AWPROT ),
    .m_axi_a_AWQOS    ( m_axi_a_AWQOS ),
    .m_axi_a_AWREGION ( m_axi_a_AWREGION ),
    .m_axi_a_WVALID   ( m_axi_a_WVALID ),
    .m_axi_a_WREADY   ( m_axi_a_WREADY ),
    .m_axi_a_WDATA    ( m_axi_a_WDATA ),
    .m_axi_a_WSTRB    ( m_axi_a_WSTRB ),
    .m_axi_a_WLAST    ( m_axi_a_WLAST ),
    .m_axi_a_ARVALID  ( m_axi_a_ARVALID ),
    .m_axi_a_ARREADY  ( m_axi_a_ARREADY ),
    .m_axi_a_ARADDR   ( m_axi_a_ARADDR ),
    .m_axi_a_ARID     ( m_axi_a_ARID ),
    .m_axi_a_ARLEN    ( m_axi_a_ARLEN ),
    .m_axi_a_ARSIZE   ( m_axi_a_ARSIZE ),
    .m_axi_a_ARBURST  ( m_axi_a_ARBURST ),
    .m_axi_a_ARLOCK   ( m_axi_a_ARLOCK ),
    .m_axi_a_ARCACHE  ( m_axi_a_ARCACHE ),
    .m_axi_a_ARPROT   ( m_axi_a_ARPROT ),
    .m_axi_a_ARQOS    ( m_axi_a_ARQOS ),
    .m_axi_a_ARREGION ( m_axi_a_ARREGION ),
    .m_axi_a_RVALID   ( m_axi_a_RVALID ),
    .m_axi_a_RREADY   ( m_axi_a_RREADY ),
    .m_axi_a_RDATA    ( m_axi_a_RDATA ),
    .m_axi_a_RLAST    ( m_axi_a_RLAST ),
    .m_axi_a_RID      ( m_axi_a_RID ),
    .m_axi_a_RRESP    ( m_axi_a_RRESP ),
    .m_axi_a_BVALID   ( m_axi_a_BVALID ),
    .m_axi_a_BREADY   ( m_axi_a_BREADY ),
    .m_axi_a_BRESP    ( m_axi_a_BRESP ),
    .m_axi_a_BID      ( m_axi_a_BID ),

    .m_axi_b_AWVALID  ( m_axi_b_AWVALID ),
    .m_axi_b_AWREADY  ( m_axi_b_AWREADY ),
    .m_axi_b_AWADDR   ( m_axi_b_AWADDR ),
    .m_axi_b_AWID     ( m_axi_b_AWID ),
    .m_axi_b_AWLEN    ( m_axi_b_AWLEN ),
    .m_axi_b_AWSIZE   ( m_axi_b_AWSIZE ),
    .m_axi_b_AWBURST  ( m_axi_b_AWBURST ),
    .m_axi_b_AWLOCK   ( m_axi_b_AWLOCK ),
    .m_axi_b_AWCACHE  ( m_axi_b_AWCACHE ),
    .m_axi_b_AWPROT   ( m_axi_b_AWPROT ),
    .m_axi_b_AWQOS    ( m_axi_b_AWQOS ),
    .m_axi_b_AWREGION ( m_axi_b_AWREGION ),
    .m_axi_b_WVALID   ( m_axi_b_WVALID ),
    .m_axi_b_WREADY   ( m_axi_b_WREADY ),
    .m_axi_b_WDATA    ( m_axi_b_WDATA ),
    .m_axi_b_WSTRB    ( m_axi_b_WSTRB ),
    .m_axi_b_WLAST    ( m_axi_b_WLAST ),
    .m_axi_b_ARVALID  ( m_axi_b_ARVALID ),
    .m_axi_b_ARREADY  ( m_axi_b_ARREADY ),
    .m_axi_b_ARADDR   ( m_axi_b_ARADDR ),
    .m_axi_b_ARID     ( m_axi_b_ARID ),
    .m_axi_b_ARLEN    ( m_axi_b_ARLEN ),
    .m_axi_b_ARSIZE   ( m_axi_b_ARSIZE ),
    .m_axi_b_ARBURST  ( m_axi_b_ARBURST ),
    .m_axi_b_ARLOCK   ( m_axi_b_ARLOCK ),
    .m_axi_b_ARCACHE  ( m_axi_b_ARCACHE ),
    .m_axi_b_ARPROT   ( m_axi_b_ARPROT ),
    .m_axi_b_ARQOS    ( m_axi_b_ARQOS ),
    .m_axi_b_ARREGION ( m_axi_b_ARREGION ),
    .m_axi_b_RVALID   ( m_axi_b_RVALID ),
    .m_axi_b_RREADY   ( m_axi_b_RREADY ),
    .m_axi_b_RDATA    ( m_axi_b_RDATA ),
    .m_axi_b_RLAST    ( m_axi_b_RLAST ),
    .m_axi_b_RID      ( m_axi_b_RID ),
    .m_axi_b_RRESP    ( m_axi_b_RRESP ),
    .m_axi_b_BVALID   ( m_axi_b_BVALID ),
    .m_axi_b_BREADY   ( m_axi_b_BREADY ),
    .m_axi_b_BRESP    ( m_axi_b_BRESP ),
    .m_axi_b_BID      ( m_axi_b_BID ),

    .m_axi_result_AWVALID  ( m_axi_result_AWVALID ),
    .m_axi_result_AWREADY  ( m_axi_result_AWREADY ),
    .m_axi_result_AWADDR   ( m_axi_result_AWADDR ),
    .m_axi_result_AWID     ( m_axi_result_AWID ),
    .m_axi_result_AWLEN    ( m_axi_result_AWLEN ),
    .m_axi_result_AWSIZE   ( m_axi_result_AWSIZE ),
    .m_axi_result_AWBURST  ( m_axi_result_AWBURST ),
    .m_axi_result_AWLOCK   ( m_axi_result_AWLOCK ),
    .m_axi_result_AWCACHE  ( m_axi_result_AWCACHE ),
    .m_axi_result_AWPROT   ( m_axi_result_AWPROT ),
    .m_axi_result_AWQOS    ( m_axi_result_AWQOS ),
    .m_axi_result_AWREGION ( m_axi_result_AWREGION ),
    .m_axi_result_WVALID   ( m_axi_result_WVALID ),
    .m_axi_result_WREADY   ( m_axi_result_WREADY ),
    .m_axi_result_WDATA    ( m_axi_result_WDATA ),
    .m_axi_result_WSTRB    ( m_axi_result_WSTRB ),
    .m_axi_result_WLAST    ( m_axi_result_WLAST ),
    .m_axi_result_ARVALID  ( m_axi_result_ARVALID ),
    .m_axi_result_ARREADY  ( m_axi_result_ARREADY ),
    .m_axi_result_ARADDR   ( m_axi_result_ARADDR ),
    .m_axi_result_ARID     ( m_axi_result_ARID ),
    .m_axi_result_ARLEN    ( m_axi_result_ARLEN ),
    .m_axi_result_ARSIZE   ( m_axi_result_ARSIZE ),
    .m_axi_result_ARBURST  ( m_axi_result_ARBURST ),
    .m_axi_result_ARLOCK   ( m_axi_result_ARLOCK ),
    .m_axi_result_ARCACHE  ( m_axi_result_ARCACHE ),
    .m_axi_result_ARPROT   ( m_axi_result_ARPROT ),
    .m_axi_result_ARQOS    ( m_axi_result_ARQOS ),
    .m_axi_result_ARREGION ( m_axi_result_ARREGION ),
    .m_axi_result_RVALID   ( m_axi_result_RVALID ),
    .m_axi_result_RREADY   ( m_axi_result_RREADY ),
    .m_axi_result_RDATA    ( m_axi_result_RDATA ),
    .m_axi_result_RLAST    ( m_axi_result_RLAST ),
    .m_axi_result_RID      ( m_axi_result_RID ),
    .m_axi_result_RRESP    ( m_axi_result_RRESP ),
    .m_axi_result_BVALID   ( m_axi_result_BVALID ),
    .m_axi_result_BREADY   ( m_axi_result_BREADY ),
    .m_axi_result_BRESP    ( m_axi_result_BRESP ),
    .m_axi_result_BID      ( m_axi_result_BID ),

    .ap_start ( ap_start ),
    .ap_done  ( ap_done ),
    .ap_idle  ( ap_idle ),
    .ap_ready ( ap_ready ),

    .xfer_size ( xfer_size ),
    .a ( a ),
    .b ( b ),
    .c ( c )
);

endmodule
`default_nettype wire
