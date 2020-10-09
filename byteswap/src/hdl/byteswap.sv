`default_nettype none

module byteswap #(
    parameter integer C_M00_AXI_ADDR_WIDTH = 64,
    parameter integer C_M00_AXI_DATA_WIDTH = 512,
    parameter integer C_XFER_SIZE_WIDTH    = 32,
    parameter integer C_WORD_BIT_WIDTH     = 32,
    parameter integer C_BYTE_BIT_WIDTH     = 8
)
(
    // System Signals
    input wire ap_clk,
    input wire ap_rst_n,

    // Control Signals
    input  wire                            ap_start,
    output wire                            ap_idle,
    output wire                            ap_done,
    output wire                            ap_ready,
    input  wire [C_XFER_SIZE_WIDTH-1:0]    scalar00,
    input  wire [C_M00_AXI_ADDR_WIDTH-1:0] axi00_ptr0,

    // AXI4 master interface m00_axi
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

timeunit 1ps;
timeprecision 1ps;

// Local Parameters
localparam integer LP_NUM_EXAMPLES       = 1;
localparam integer LP_DW_BYTES           = C_M00_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN      = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
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

///////////////////////////////////////////////////////////////////////////////
// Begin Controller logic
///////////////////////////////////////////////////////////////////////////////

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

// AXI4 Read Master
axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH ),
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH ),
  .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ),
  .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_read_master (
  .aclk             ( ap_clk ),
  .areset           ( areset ),
  .ctrl_start       ( ap_start_pulse ),
  .ctrl_done        ( read_done ),
  .ctrl_addr_offset ( axi00_ptr0 ),
  .ctrl_xfer_bytes  ( scalar00 ),
  .m_axi_arvalid    ( m00_axi_arvalid ),
  .m_axi_arready    ( m00_axi_arready ),
  .m_axi_araddr     ( m00_axi_araddr ),
  .m_axi_arlen      ( m00_axi_arlen ),
  .m_axi_rvalid     ( m00_axi_rvalid ),
  .m_axi_rready     ( m00_axi_rready ),
  .m_axi_rdata      ( m00_axi_rdata ),
  .m_axi_rlast      ( m00_axi_rlast ),
  .m_axis_aclk      ( ap_clk ),
  .m_axis_areset    ( areset ),
  .m_axis_tvalid    ( rd_tvalid ),
  .m_axis_tready    ( rd_tready ),
  .m_axis_tlast     ( rd_tlast ),
  .m_axis_tdata     ( rd_tdata )
);

// Intermediate signals
wire                            rd_tvalid;
wire                            rd_tready;
wire                            rd_tlast;
wire [C_M00_AXI_DATA_WIDTH-1:0] rd_tdata;

// RTL Core
byteswap_swapper #(
  .C_AXIS_TDATA_WIDTH ( C_M00_AXI_DATA_WIDTH ),
  .C_WORD_BIT_WIDTH   ( C_WORD_BIT_WIDTH ),
  .C_BYTE_BIT_WIDTH   ( C_BYTE_BIT_WIDTH )
)
inst_swapper  (
  .s_axis_aclk   ( ap_clk ),
  .s_axis_areset ( areset ),
  .s_axis_tvalid ( rd_tvalid ),
  .s_axis_tready ( rd_tready ),
  .s_axis_tdata  ( rd_tdata ),
  .s_axis_tkeep  ( {C_M00_AXI_DATA_WIDTH/8{1'b1}} ),
  .s_axis_tlast  ( rd_tlast ),
  .m_axis_aclk   ( ap_clk ),
  .m_axis_tvalid ( wr_tvalid ),
  .m_axis_tready ( wr_tready ),
  .m_axis_tdata  ( wr_tdata ),
  .m_axis_tkeep  ( ), // Not used
  .m_axis_tlast  ( wr_tlast )
);

// Intermediate signals
wire                            wr_tvalid;
wire                            wr_tready;
wire                            wr_tlast;
wire [C_M00_AXI_DATA_WIDTH-1:0] wr_tdata;

// AXI4 Write Master
axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_M00_AXI_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH  ( C_M00_AXI_DATA_WIDTH ),
  .C_XFER_SIZE_WIDTH   ( C_XFER_SIZE_WIDTH ),
  .C_MAX_OUTSTANDING   ( LP_WR_MAX_OUTSTANDING ),
  .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_write_master (
  .aclk             ( ap_clk ),
  .areset           ( areset ),
  .ctrl_start       ( ap_start_pulse ),
  .ctrl_done        ( write_done ),
  .ctrl_addr_offset ( axi00_ptr0 ),
  .ctrl_xfer_bytes  ( scalar00 ),
  .m_axi_awvalid    ( m00_axi_awvalid ),
  .m_axi_awready    ( m00_axi_awready ),
  .m_axi_awaddr     ( m00_axi_awaddr ),
  .m_axi_awlen      ( m00_axi_awlen ),
  .m_axi_wvalid     ( m00_axi_wvalid ),
  .m_axi_wready     ( m00_axi_wready ),
  .m_axi_wdata      ( m00_axi_wdata ),
  .m_axi_wstrb      ( m00_axi_wstrb ),
  .m_axi_wlast      ( m00_axi_wlast ),
  .m_axi_bvalid     ( m00_axi_bvalid ),
  .m_axi_bready     ( m00_axi_bready ),
  .s_axis_aclk      ( ap_clk ),
  .s_axis_areset    ( areset ),
  .s_axis_tvalid    ( wr_tvalid ),
  .s_axis_tready    ( wr_tready ),
  .s_axis_tdata     ( wr_tdata )
);

assign ap_done_i[0] = write_done;

endmodule : byteswap
`default_nettype wire
