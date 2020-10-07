`default_nettype none
`timescale 1 ns / 1 ps

module byteswap_top #(
    parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12,
    parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32,
    parameter integer C_M00_AXI_ADDR_WIDTH       = 64,
    parameter integer C_M00_AXI_DATA_WIDTH       = 512,
    parameter integer C_XFER_SIZE_WIDTH          = 32,
    parameter integer C_WORD_BIT_WIDTH           = 32,
    parameter integer C_BYTE_BIT_WIDTH           = 8
)
(
    // System signals
    input  wire ap_clk,
    input  wire ap_rst_n,

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
    output wire                                    interrupt,

    // AXI4 master data interface
    output wire                              m00_axi_awvalid,
    input  wire                              m00_axi_awready,
    output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_awaddr,
    output wire [8-1:0]                      m00_axi_awlen,
    output wire                              m00_axi_wvalid,
    input  wire                              m00_axi_wready,
    output wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_wdata,
    output wire [C_M00_AXI_DATA_WIDTH/8-1:0] m00_axi_wstrb,
    output wire                              m00_axi_wlast,
    input  wire                              m00_axi_bvalid,
    output wire                              m00_axi_bready,
    output wire                              m00_axi_arvalid,
    input  wire                              m00_axi_arready,
    output wire [C_M00_AXI_ADDR_WIDTH-1:0]   m00_axi_araddr,
    output wire [8-1:0]                      m00_axi_arlen,
    input  wire                              m00_axi_rvalid,
    output wire                              m00_axi_rready,
    input  wire [C_M00_AXI_DATA_WIDTH-1:0]   m00_axi_rdata,
    input  wire                              m00_axi_rlast
);

// Wires and variables
reg areset = 1'b0;
wire ap_start;
wire ap_idle;
wire ap_done;
wire ap_ready;
wire [32-1:0] scalar00;
wire [64-1:0] axi00_ptr0;

// Register and invert reset signal.
always @(posedge ap_clk) begin
    areset <= ~ap_rst_n;
end

// Control interface slave
byteswap_control_s_axi #(
    .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
    .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_slave (
    .ACLK       ( ap_clk ),
    .ARESET     ( areset ),
    .ACLK_EN    ( 1'b1 ),
    .interrupt  ( interrupt ),
    .ap_start   ( ap_start ),
    .ap_done    ( ap_done ),
    .ap_ready   ( ap_ready ),
    .ap_idle    ( ap_idle ),
    .scalar00   ( scalar00 ),
    .axi00_ptr0 ( axi00_ptr0 ),
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
    .BRESP      ( s_axi_control_bresp )
);

// Controller
byteswap #(
    .C_M00_AXI_ADDR_WIDTH ( C_M00_AXI_ADDR_WIDTH ),
    .C_M00_AXI_DATA_WIDTH ( C_M00_AXI_DATA_WIDTH ),
    .C_XFER_SIZE_WIDTH    ( C_XFER_SIZE_WIDTH ),
    .C_WORD_BIT_WIDTH     ( C_WORD_BIT_WIDTH ),
    .C_BYTE_BIT_WIDTH     ( C_BYTE_BIT_WIDTH )
)
inst_byteswap (
    .ap_clk          ( ap_clk ),
    .ap_rst_n        ( ap_rst_n ),
    .m00_axi_awvalid ( m00_axi_awvalid ),
    .m00_axi_awready ( m00_axi_awready ),
    .m00_axi_awaddr  ( m00_axi_awaddr ),
    .m00_axi_awlen   ( m00_axi_awlen ),
    .m00_axi_wvalid  ( m00_axi_wvalid ),
    .m00_axi_wready  ( m00_axi_wready ),
    .m00_axi_wdata   ( m00_axi_wdata ),
    .m00_axi_wstrb   ( m00_axi_wstrb ),
    .m00_axi_wlast   ( m00_axi_wlast ),
    .m00_axi_bvalid  ( m00_axi_bvalid ),
    .m00_axi_bready  ( m00_axi_bready ),
    .m00_axi_arvalid ( m00_axi_arvalid ),
    .m00_axi_arready ( m00_axi_arready ),
    .m00_axi_araddr  ( m00_axi_araddr ),
    .m00_axi_arlen   ( m00_axi_arlen ),
    .m00_axi_rvalid  ( m00_axi_rvalid ),
    .m00_axi_rready  ( m00_axi_rready ),
    .m00_axi_rdata   ( m00_axi_rdata ),
    .m00_axi_rlast   ( m00_axi_rlast ),
    .ap_start        ( ap_start ),
    .ap_done         ( ap_done ),
    .ap_idle         ( ap_idle ),
    .ap_ready        ( ap_ready ),
    .scalar00        ( scalar00 ),
    .axi00_ptr0      ( axi00_ptr0 )
);

endmodule
`default_nettype wire
