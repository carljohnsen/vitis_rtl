`default_nettype none
`timescale 1 ns / 1 ps

module byteswap_top #(
    parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12,
    parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32,
    parameter integer C_M_AXI_GMEM_ADDR_WIDTH    = 64,
    parameter integer C_M_AXI_GMEM_DATA_WIDTH    = 32,
    parameter integer C_M_AXI_GMEM_ID_WIDTH      = 1,
    parameter integer C_M_AXI_GMEM_NUM_CHANNELS  = 1,
    parameter integer C_XFER_SIZE_WIDTH          = 32,
    parameter integer C_WORD_BIT_WIDTH           = 32,
    parameter integer C_BYTE_BIT_WIDTH           = 8
)
(
    // System signals
    input  wire ap_clk,
    input  wire ap_rst_n,

    // AXI4 master interface
    output wire                                 m_axi_gmem_AWVALID,
    input  wire                                 m_axi_gmem_AWREADY,
    output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]   m_axi_gmem_AWADDR,
    output wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]   m_axi_gmem_AWID,
    output wire [7:0]                           m_axi_gmem_AWLEN,
    output wire [2:0]                           m_axi_gmem_AWSIZE,
    // Tie-off AXI4 transaction options that are not being used.
    output wire [1:0]                           m_axi_gmem_AWBURST,
    output wire [1:0]                           m_axi_gmem_AWLOCK,
    output wire [3:0]                           m_axi_gmem_AWCACHE,
    output wire [2:0]                           m_axi_gmem_AWPROT,
    output wire [3:0]                           m_axi_gmem_AWQOS,
    output wire [3:0]                           m_axi_gmem_AWREGION,
    output wire                                 m_axi_gmem_WVALID,
    input  wire                                 m_axi_gmem_WREADY,
    output wire [C_M_AXI_GMEM_DATA_WIDTH-1:0]   m_axi_gmem_WDATA,
    output wire [C_M_AXI_GMEM_DATA_WIDTH/8-1:0] m_axi_gmem_WSTRB,
    output wire                                 m_axi_gmem_WLAST,
    output wire                                 m_axi_gmem_ARVALID,
    input  wire                                 m_axi_gmem_ARREADY,
    output wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0]   m_axi_gmem_ARADDR,
    output wire [C_M_AXI_GMEM_ID_WIDTH-1:0]     m_axi_gmem_ARID,
    output wire [7:0]                           m_axi_gmem_ARLEN,
    output wire [2:0]                           m_axi_gmem_ARSIZE,
    output wire [1:0]                           m_axi_gmem_ARBURST,
    output wire [1:0]                           m_axi_gmem_ARLOCK,
    output wire [3:0]                           m_axi_gmem_ARCACHE,
    output wire [2:0]                           m_axi_gmem_ARPROT,
    output wire [3:0]                           m_axi_gmem_ARQOS,
    output wire [3:0]                           m_axi_gmem_ARREGION,
    input  wire                                 m_axi_gmem_RVALID,
    output wire                                 m_axi_gmem_RREADY,
    input  wire [C_M_AXI_GMEM_DATA_WIDTH - 1:0] m_axi_gmem_RDATA,
    input  wire                                 m_axi_gmem_RLAST,
    input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]   m_axi_gmem_RID,
    input  wire [1:0]                           m_axi_gmem_RRESP,
    input  wire                                 m_axi_gmem_BVALID,
    output wire                                 m_axi_gmem_BREADY,
    input  wire [1:0]                           m_axi_gmem_BRESP,
    input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]   m_axi_gmem_BID,


    // AXI4-Lite slave control interface
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

// Wires and variables
(* DONT_TOUCH = "yes" *)
reg areset = 1'b0;
wire ap_start;
wire ap_idle;
wire ap_done;
wire ap_ready;
wire [32-1:0] xfer_size;
wire [64-1:0] gmem_ptr;

// Register and invert reset signal.
always @(posedge ap_clk) begin
    areset <= ~ap_rst_n;
end

// Control interface slave
byteswap_control #(
    .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
    .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_slave (
    .ACLK      ( ap_clk ),
    .ARESET    ( areset ),
    .ACLK_EN   ( 1'b1 ),
    .interrupt ( interrupt ),
    .ap_start  ( ap_start ),
    .ap_done   ( ap_done ),
    .ap_ready  ( ap_ready ),
    .ap_idle   ( ap_idle ),
    .xfer_size ( xfer_size ),
    .gmem_ptr  ( gmem_ptr ),
    .AWVALID   ( s_axi_control_awvalid ),
    .AWREADY   ( s_axi_control_awready ),
    .AWADDR    ( s_axi_control_awaddr ),
    .WVALID    ( s_axi_control_wvalid ),
    .WREADY    ( s_axi_control_wready ),
    .WDATA     ( s_axi_control_wdata ),
    .WSTRB     ( s_axi_control_wstrb ),
    .ARVALID   ( s_axi_control_arvalid ),
    .ARREADY   ( s_axi_control_arready ),
    .ARADDR    ( s_axi_control_araddr ),
    .RVALID    ( s_axi_control_rvalid ),
    .RREADY    ( s_axi_control_rready ),
    .RDATA     ( s_axi_control_rdata ),
    .RRESP     ( s_axi_control_rresp ),
    .BVALID    ( s_axi_control_bvalid ),
    .BREADY    ( s_axi_control_bready ),
    .BRESP     ( s_axi_control_bresp )
);

// Controller
byteswap_int #(
    .C_M_AXI_GMEM_ADDR_WIDTH   ( C_M_AXI_GMEM_ADDR_WIDTH ),
    .C_M_AXI_GMEM_DATA_WIDTH   ( C_M_AXI_GMEM_DATA_WIDTH ),
    .C_M_AXI_GMEM_ID_WIDTH     ( C_M_AXI_GMEM_ID_WIDTH ),
    .C_M_AXI_GMEM_NUM_CHANNELS ( C_M_AXI_GMEM_NUM_CHANNELS ),
    .C_XFER_SIZE_WIDTH         ( C_XFER_SIZE_WIDTH ),
    .C_WORD_BIT_WIDTH          ( C_WORD_BIT_WIDTH ),
    .C_BYTE_BIT_WIDTH          ( C_BYTE_BIT_WIDTH )
)
inst_byteswap (
    .ap_clk          ( ap_clk ),
    .ap_rst_n        ( ap_rst_n ),

    .m_axi_gmem_AWVALID    ( m_axi_gmem_AWVALID ),
    .m_axi_gmem_AWREADY    ( m_axi_gmem_AWREADY ),
    .m_axi_gmem_AWADDR     ( m_axi_gmem_AWADDR ),
    .m_axi_gmem_AWID       ( m_axi_gmem_AWID ),
    .m_axi_gmem_AWLEN      ( m_axi_gmem_AWLEN ),
    .m_axi_gmem_AWSIZE     ( m_axi_gmem_AWSIZE ),
    .m_axi_gmem_AWBURST    ( m_axi_gmem_AWBURST ),
    .m_axi_gmem_AWLOCK     ( m_axi_gmem_AWLOCK ),
    .m_axi_gmem_AWCACHE    ( m_axi_gmem_AWCACHE ),
    .m_axi_gmem_AWPROT     ( m_axi_gmem_AWPROT ),
    .m_axi_gmem_AWQOS      ( m_axi_gmem_AWQOS ),
    .m_axi_gmem_AWREGION   ( m_axi_gmem_AWREGION ),
    .m_axi_gmem_WVALID     ( m_axi_gmem_WVALID ),
    .m_axi_gmem_WREADY     ( m_axi_gmem_WREADY ),
    .m_axi_gmem_WDATA      ( m_axi_gmem_WDATA ),
    .m_axi_gmem_WSTRB      ( m_axi_gmem_WSTRB ),
    .m_axi_gmem_WLAST      ( m_axi_gmem_WLAST ),
    .m_axi_gmem_ARVALID    ( m_axi_gmem_ARVALID ),
    .m_axi_gmem_ARREADY    ( m_axi_gmem_ARREADY ),
    .m_axi_gmem_ARADDR     ( m_axi_gmem_ARADDR ),
    .m_axi_gmem_ARID       ( m_axi_gmem_ARID ),
    .m_axi_gmem_ARLEN      ( m_axi_gmem_ARLEN ),
    .m_axi_gmem_ARSIZE     ( m_axi_gmem_ARSIZE ),
    .m_axi_gmem_ARBURST    ( m_axi_gmem_ARBURST ),
    .m_axi_gmem_ARLOCK     ( m_axi_gmem_ARLOCK ),
    .m_axi_gmem_ARCACHE    ( m_axi_gmem_ARCACHE ),
    .m_axi_gmem_ARPROT     ( m_axi_gmem_ARPROT ),
    .m_axi_gmem_ARQOS      ( m_axi_gmem_ARQOS ),
    .m_axi_gmem_ARREGION   ( m_axi_gmem_ARREGION ),
    .m_axi_gmem_RVALID     ( m_axi_gmem_RVALID ),
    .m_axi_gmem_RREADY     ( m_axi_gmem_RREADY ),
    .m_axi_gmem_RDATA      ( m_axi_gmem_RDATA ),
    .m_axi_gmem_RLAST      ( m_axi_gmem_RLAST ),
    .m_axi_gmem_RID        ( m_axi_gmem_RID ),
    .m_axi_gmem_RRESP      ( m_axi_gmem_RRESP ),
    .m_axi_gmem_BVALID     ( m_axi_gmem_BVALID ),
    .m_axi_gmem_BREADY     ( m_axi_gmem_BREADY ),
    .m_axi_gmem_BRESP      ( m_axi_gmem_BRESP ),
    .m_axi_gmem_BID        ( m_axi_gmem_BID ),

    .ap_start  ( ap_start ),
    .ap_done   ( ap_done ),
    .ap_idle   ( ap_idle ),
    .ap_ready  ( ap_ready ),
    .xfer_size ( xfer_size ),
    .gmem_ptr  ( gmem_ptr )
);

endmodule
`default_nettype wire
