`default_nettype none

module byteswap_int #(
    parameter integer C_M_AXI_GMEM_ADDR_WIDTH   = 64,
    parameter integer C_M_AXI_GMEM_DATA_WIDTH   = 512,
    parameter integer C_M_AXI_GMEM_ID_WIDTH     = 1,
    parameter integer C_M_AXI_GMEM_NUM_CHANNELS = 1,
    parameter integer C_XFER_SIZE_WIDTH         = 32,
    parameter integer C_WORD_BIT_WIDTH          = 32,
    parameter integer C_BYTE_BIT_WIDTH          = 8
)
(
    // System Signals
    input wire ap_clk,
    input wire ap_rst_n,

    // Control Signals
    input  wire                               ap_start,
    output wire                               ap_idle,
    output wire                               ap_done,
    output wire                               ap_ready,
    input  wire [C_XFER_SIZE_WIDTH-1:0]       xfer_size,
    input  wire [C_M_AXI_GMEM_ADDR_WIDTH-1:0] gmem_ptr,

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
    input  wire [C_M_AXI_GMEM_ID_WIDTH - 1:0]   m_axi_gmem_BID
);

timeunit 1ps;
timeprecision 1ps;

// Local Parameters
localparam integer LP_NUM_EXAMPLES       = 1;
localparam integer LP_DW_BYTES           = C_M_AXI_GMEM_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN      =
    4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN      = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_BRAM_DEPTH         = 512;
localparam integer LP_RD_MAX_OUTSTANDING = LP_BRAM_DEPTH / LP_AXI_BURST_LEN;
localparam integer LP_WR_MAX_OUTSTANDING = 32;

// Wires and Variables
(* KEEP = "yes" *)
logic                         areset = 1'b0;
logic                         ap_start_r = 1'b0;
logic                         ap_idle_r = 1'b1;
logic                         ap_start_pulse;
logic [LP_NUM_EXAMPLES-1:0]   ap_done_i;
logic [LP_NUM_EXAMPLES-1:0]   ap_done_r = {LP_NUM_EXAMPLES{1'b0}};

// Intermediate signals
wire                               rd_tvalid;
wire                               rd_tready;
wire                               rd_tlast;
wire [C_M_AXI_GMEM_DATA_WIDTH-1:0] rd_tdata;

// Intermediate signals
wire                               wr_tvalid;
wire                               wr_tready;
wire                               wr_tlast;
wire [C_M_AXI_GMEM_DATA_WIDTH-1:0] wr_tdata;

///////////////////////////////////////////////////////////////////////////////
// Begin Controller logic
///////////////////////////////////////////////////////////////////////////////
assign m_axi_gmem_AWID     = {C_M_AXI_GMEM_ID_WIDTH{1'b0}};
assign m_axi_gmem_AWBURST  = 2'b01;
assign m_axi_gmem_AWLOCK   = 2'b00;
assign m_axi_gmem_AWCACHE  = 4'b0011;
assign m_axi_gmem_AWPROT   = 3'b000;
assign m_axi_gmem_AWQOS    = 4'b0000;
assign m_axi_gmem_AWREGION = 4'b0000;
assign m_axi_gmem_ARBURST  = 2'b01;
assign m_axi_gmem_ARLOCK   = 2'b00;
assign m_axi_gmem_ARCACHE  = 4'b0011;
assign m_axi_gmem_ARPROT   = 3'b000;
assign m_axi_gmem_ARQOS    = 4'b0000;
assign m_axi_gmem_ARREGION = 4'b0000;

// Register and invert reset signal.
always @(posedge ap_clk) begin
    areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
    begin
        ap_start_r <= ap_start;
    end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when
// ap_start_pulse is asserted
always @(posedge ap_clk) begin
    if (areset) begin
        ap_idle_r <= 1'b1;
    end
    else begin
        ap_idle_r <= ap_done ?
            1'b1 :
            ap_start_pulse ?
                1'b0 :
                ap_idle;
    end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
    if (areset) begin
        ap_done_r <= '0;
    end
    else begin
        ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
    end
end

assign ap_done = &ap_done_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;

///////////////////////////////////////////////////////////////////////////////
// Begin Core RTL
///////////////////////////////////////////////////////////////////////////////

wire read_done;
wire write_done;

axi_read_master_ch #(
    .C_ADDR_WIDTH        ( C_M_AXI_GMEM_ADDR_WIDTH ),
    .C_DATA_WIDTH        ( C_M_AXI_GMEM_DATA_WIDTH ),
    .C_ID_WIDTH          ( C_M_AXI_GMEM_ID_WIDTH ),
    .C_NUM_CHANNELS      ( C_M_AXI_GMEM_NUM_CHANNELS ),
    .C_LENGTH_WIDTH      ( C_XFER_SIZE_WIDTH ),
    .C_BURST_LEN         ( LP_AXI_BURST_LEN ),
    .C_LOG_BURST_LEN     ( LP_LOG_BURST_LEN ),
    .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ),
    .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_read_master (
    .aclk   ( ap_clk ),
    .areset ( areset ),

    .ctrl_start  ( ap_start_pulse ),
    .ctrl_done   ( read_done ),
    .ctrl_offset ( gmem_ptr ),
    .ctrl_length ( xfer_size ),

    .arvalid ( m_axi_gmem_ARVALID ),
    .arready ( m_axi_gmem_ARREADY ),
    .araddr  ( m_axi_gmem_ARADDR ),
    .arid    ( m_axi_gmem_ARID ),
    .arlen   ( m_axi_gmem_ARLEN ),
    .arsize  ( m_axi_gmem_ARSIZE ),
    .rvalid  ( m_axi_gmem_RVALID ),
    .rready  ( m_axi_gmem_RREADY ),
    .rdata   ( m_axi_gmem_RDATA ),
    .rlast   ( m_axi_gmem_RLAST ),
    .rid     ( m_axi_gmem_RID ),
    .rresp   ( m_axi_gmem_RRESP ),

    .m_tvalid ( rd_tvalid ),
    .m_tready ( rd_tready ),
    .m_tdata  ( rd_tdata )
    //.m_tlast  ( rd_tlast )
);

// RTL Core
byteswap_swapper #(
  .C_AXIS_TDATA_WIDTH ( C_M_AXI_GMEM_DATA_WIDTH ),
  .C_WORD_BIT_WIDTH   ( C_WORD_BIT_WIDTH ),
  .C_BYTE_BIT_WIDTH   ( C_BYTE_BIT_WIDTH )
)
inst_swapper  (
  .s_axis_aclk   ( ap_clk ),
  .s_axis_areset ( areset ),
  .s_axis_tvalid ( rd_tvalid ),
  .s_axis_tready ( rd_tready ),
  .s_axis_tdata  ( rd_tdata ),
  .s_axis_tkeep  ( {C_M_AXI_GMEM_DATA_WIDTH/8{1'b1}} ),
  .s_axis_tlast  ( rd_tlast ),

  .m_axis_aclk   ( ap_clk ),
  .m_axis_tvalid ( wr_tvalid ),
  .m_axis_tready ( wr_tready ),
  .m_axis_tdata  ( wr_tdata ),
  .m_axis_tkeep  ( ), // Not used
  .m_axis_tlast  ( wr_tlast )
);

// AXI4 Write Master
axi_write_master_ch #(
    .C_ADDR_WIDTH        ( C_M_AXI_GMEM_ADDR_WIDTH ),
    .C_DATA_WIDTH        ( C_M_AXI_GMEM_DATA_WIDTH ),
    .C_MAX_LENGTH_WIDTH  ( C_XFER_SIZE_WIDTH ),
    .C_BURST_LEN         ( LP_AXI_BURST_LEN ),
    .C_LOG_BURST_LEN     ( LP_LOG_BURST_LEN ),
    .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_write_master (
    .aclk        ( ap_clk ),
    .areset      ( areset ),

    .ctrl_start  ( ap_start_pulse ),
    .ctrl_offset ( gmem_ptr ),
    .ctrl_length ( xfer_size ),
    .ctrl_done   ( write_done ),

    .awvalid     ( m_axi_gmem_AWVALID ),
    .awready     ( m_axi_gmem_AWREADY ),
    .awaddr      ( m_axi_gmem_AWADDR ),
    .awlen       ( m_axi_gmem_AWLEN ),
    .awsize      ( m_axi_gmem_AWSIZE ),
    .wvalid      ( m_axi_gmem_WVALID ),
    .wready      ( m_axi_gmem_WREADY ),
    .wdata       ( m_axi_gmem_WDATA ),
    .wstrb       ( m_axi_gmem_WSTRB ),
    .wlast       ( m_axi_gmem_WLAST ),
    .bvalid      ( m_axi_gmem_BVALID ),
    .bready      ( m_axi_gmem_BREADY ),
    .bresp       ( m_axi_gmem_BRESP ),

    .s_tvalid     ( wr_tvalid ),
    .s_tready     ( wr_tready ),
    .s_tdata      ( wr_tdata )
);

assign ap_done_i[0] = write_done;

endmodule : byteswap_int
`default_nettype wire
