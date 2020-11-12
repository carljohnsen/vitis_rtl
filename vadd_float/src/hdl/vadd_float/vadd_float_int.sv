`default_nettype none
module vadd_float_int #(
    parameter integer C_M_AXI_ADDR_WIDTH = 64,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_M_AXI_ID_WIDTH   = 1,
    parameter integer C_M_AXI_NUM_CHANNELS = 1,
    parameter integer C_XFER_SIZE_WIDTH  = 32
)
(
    // System Signals
    input  wire ap_clk,
    input  wire ap_rst_n,

    output wire                            m_axi_a_AWVALID,
    input  wire                            m_axi_a_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_a_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_AWID,
    output wire [7:0]                      m_axi_a_AWLEN,
    output wire [2:0]                      m_axi_a_AWSIZE,
    output wire [1:0]                      m_axi_a_AWBURST,
    output wire [1:0]                      m_axi_a_AWLOCK,
    output wire [3:0]                      m_axi_a_AWCACHE,
    output wire [2:0]                      m_axi_a_AWPROT,
    output wire [3:0]                      m_axi_a_AWQOS,
    output wire [3:0]                      m_axi_a_AWREGION,
    output wire                            m_axi_a_WVALID,
    input  wire                            m_axi_a_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_a_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_a_WSTRB,
    output wire                            m_axi_a_WLAST,
    output wire                            m_axi_a_ARVALID,
    input  wire                            m_axi_a_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_a_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_a_ARID,
    output wire [7:0]                      m_axi_a_ARLEN,
    output wire [2:0]                      m_axi_a_ARSIZE,
    output wire [1:0]                      m_axi_a_ARBURST,
    output wire [1:0]                      m_axi_a_ARLOCK,
    output wire [3:0]                      m_axi_a_ARCACHE,
    output wire [2:0]                      m_axi_a_ARPROT,
    output wire [3:0]                      m_axi_a_ARQOS,
    output wire [3:0]                      m_axi_a_ARREGION,
    input  wire                            m_axi_a_RVALID,
    output wire                            m_axi_a_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_a_RDATA,
    input  wire                            m_axi_a_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_RID,
    input  wire [1:0]                      m_axi_a_RRESP,
    input  wire                            m_axi_a_BVALID,
    output wire                            m_axi_a_BREADY,
    input  wire [1:0]                      m_axi_a_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_a_BID,

    output wire                            m_axi_b_AWVALID,
    input  wire                            m_axi_b_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_b_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_AWID,
    output wire [7:0]                      m_axi_b_AWLEN,
    output wire [2:0]                      m_axi_b_AWSIZE,
    output wire [1:0]                      m_axi_b_AWBURST,
    output wire [1:0]                      m_axi_b_AWLOCK,
    output wire [3:0]                      m_axi_b_AWCACHE,
    output wire [2:0]                      m_axi_b_AWPROT,
    output wire [3:0]                      m_axi_b_AWQOS,
    output wire [3:0]                      m_axi_b_AWREGION,
    output wire                            m_axi_b_WVALID,
    input  wire                            m_axi_b_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_b_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_b_WSTRB,
    output wire                            m_axi_b_WLAST,
    output wire                            m_axi_b_ARVALID,
    input  wire                            m_axi_b_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_b_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_b_ARID,
    output wire [7:0]                      m_axi_b_ARLEN,
    output wire [2:0]                      m_axi_b_ARSIZE,
    output wire [1:0]                      m_axi_b_ARBURST,
    output wire [1:0]                      m_axi_b_ARLOCK,
    output wire [3:0]                      m_axi_b_ARCACHE,
    output wire [2:0]                      m_axi_b_ARPROT,
    output wire [3:0]                      m_axi_b_ARQOS,
    output wire [3:0]                      m_axi_b_ARREGION,
    input  wire                            m_axi_b_RVALID,
    output wire                            m_axi_b_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_b_RDATA,
    input  wire                            m_axi_b_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_RID,
    input  wire [1:0]                      m_axi_b_RRESP,
    input  wire                            m_axi_b_BVALID,
    output wire                            m_axi_b_BREADY,
    input  wire [1:0]                      m_axi_b_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_b_BID,

    output wire                            m_axi_result_AWVALID,
    input  wire                            m_axi_result_AWREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_result_AWADDR,
    output wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_AWID,
    output wire [7:0]                      m_axi_result_AWLEN,
    output wire [2:0]                      m_axi_result_AWSIZE,
    output wire [1:0]                      m_axi_result_AWBURST,
    output wire [1:0]                      m_axi_result_AWLOCK,
    output wire [3:0]                      m_axi_result_AWCACHE,
    output wire [2:0]                      m_axi_result_AWPROT,
    output wire [3:0]                      m_axi_result_AWQOS,
    output wire [3:0]                      m_axi_result_AWREGION,
    output wire                            m_axi_result_WVALID,
    input  wire                            m_axi_result_WREADY,
    output wire [C_M_AXI_DATA_WIDTH-1:0]   m_axi_result_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] m_axi_result_WSTRB,
    output wire                            m_axi_result_WLAST,
    output wire                            m_axi_result_ARVALID,
    input  wire                            m_axi_result_ARREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]   m_axi_result_ARADDR,
    output wire [C_M_AXI_ID_WIDTH-1:0]     m_axi_result_ARID,
    output wire [7:0]                      m_axi_result_ARLEN,
    output wire [2:0]                      m_axi_result_ARSIZE,
    output wire [1:0]                      m_axi_result_ARBURST,
    output wire [1:0]                      m_axi_result_ARLOCK,
    output wire [3:0]                      m_axi_result_ARCACHE,
    output wire [2:0]                      m_axi_result_ARPROT,
    output wire [3:0]                      m_axi_result_ARQOS,
    output wire [3:0]                      m_axi_result_ARREGION,
    input  wire                            m_axi_result_RVALID,
    output wire                            m_axi_result_RREADY,
    input  wire [C_M_AXI_DATA_WIDTH - 1:0] m_axi_result_RDATA,
    input  wire                            m_axi_result_RLAST,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_RID,
    input  wire [1:0]                      m_axi_result_RRESP,
    input  wire                            m_axi_result_BVALID,
    output wire                            m_axi_result_BREADY,
    input  wire [1:0]                      m_axi_result_BRESP,
    input  wire [C_M_AXI_ID_WIDTH - 1:0]   m_axi_result_BID,

    // Control Signals
    input  wire ap_start,
    output wire ap_idle,
    output wire ap_done,
    output wire ap_ready,

    input  wire [C_XFER_SIZE_WIDTH-1:0]  xfer_size,
    input  wire [C_M_AXI_ADDR_WIDTH-1:0] a,
    input  wire [C_M_AXI_ADDR_WIDTH-1:0] b,
    input  wire [C_M_AXI_ADDR_WIDTH-1:0] c
);

timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
localparam integer LP_DW_BYTES           = C_M_AXI_DATA_WIDTH/8;
localparam integer LP_AXI_BURST_LEN      = 4096/LP_DW_BYTES < 256 ? 4096/LP_DW_BYTES : 256;
localparam integer LP_LOG_BURST_LEN      = $clog2(LP_AXI_BURST_LEN);
localparam integer LP_RD_MAX_OUTSTANDING = 3;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic areset     = 1'b0;
logic ap_start_r = 1'b0;
logic ap_idle_r  = 1'b1;
logic ap_start_pulse;

logic                          rd_a_tvalid;
logic                          rd_a_tready;
logic [C_M_AXI_DATA_WIDTH-1:0] rd_a_tdata;
logic                          rd_a_tlast;

logic                          rd_b_tvalid;
logic                          rd_b_tready;
logic [C_M_AXI_DATA_WIDTH-1:0] rd_b_tdata;
logic                          rd_b_tlast;

logic                          wr_c_tvalid;
logic                          wr_c_tready;
logic [C_M_AXI_DATA_WIDTH-1:0] wr_c_tdata;
logic                          wr_c_tlast;

logic read_done;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////
// Tie-off unused AXI protocol features
assign m_axi_a_AWID     = {C_M_AXI_ID_WIDTH{1'b0}};
assign m_axi_a_AWBURST  = 2'b01;
assign m_axi_a_AWLOCK   = 2'b00;
assign m_axi_a_AWCACHE  = 4'b0011;
assign m_axi_a_AWPROT   = 3'b000;
assign m_axi_a_AWQOS    = 4'b0000;
assign m_axi_a_AWREGION = 4'b0000;
assign m_axi_a_ARBURST  = 2'b01;
assign m_axi_a_ARLOCK   = 2'b00;
assign m_axi_a_ARCACHE  = 4'b0011;
assign m_axi_a_ARPROT   = 3'b000;
assign m_axi_a_ARQOS    = 4'b0000;
assign m_axi_a_ARREGION = 4'b0000;

assign m_axi_b_AWID     = {C_M_AXI_ID_WIDTH{1'b0}};
assign m_axi_b_AWBURST  = 2'b01;
assign m_axi_b_AWLOCK   = 2'b00;
assign m_axi_b_AWCACHE  = 4'b0011;
assign m_axi_b_AWPROT   = 3'b000;
assign m_axi_b_AWQOS    = 4'b0000;
assign m_axi_b_AWREGION = 4'b0000;
assign m_axi_b_ARBURST  = 2'b01;
assign m_axi_b_ARLOCK   = 2'b00;
assign m_axi_b_ARCACHE  = 4'b0011;
assign m_axi_b_ARPROT   = 3'b000;
assign m_axi_b_ARQOS    = 4'b0000;
assign m_axi_b_ARREGION = 4'b0000;

assign m_axi_result_AWID     = {C_M_AXI_ID_WIDTH{1'b0}};
assign m_axi_result_AWBURST  = 2'b01;
assign m_axi_result_AWLOCK   = 2'b00;
assign m_axi_result_AWCACHE  = 4'b0011;
assign m_axi_result_AWPROT   = 3'b000;
assign m_axi_result_AWQOS    = 4'b0000;
assign m_axi_result_AWREGION = 4'b0000;
assign m_axi_result_ARBURST  = 2'b01;
assign m_axi_result_ARLOCK   = 2'b00;
assign m_axi_result_ARCACHE  = 4'b0011;
assign m_axi_result_ARPROT   = 3'b000;
assign m_axi_result_ARQOS    = 4'b0000;
assign m_axi_result_ARREGION = 4'b0000;

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

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;

// AXI4 Read Master a
axi_read_master #(
    .C_ADDR_WIDTH        ( C_M_AXI_ADDR_WIDTH ),
    .C_DATA_WIDTH        ( C_M_AXI_DATA_WIDTH ),
    .C_ID_WIDTH          ( C_M_AXI_ID_WIDTH ),
    .C_NUM_CHANNELS      ( C_M_AXI_NUM_CHANNELS ),
    .C_LENGTH_WIDTH      ( C_XFER_SIZE_WIDTH ),
    .C_BURST_LEN         ( LP_AXI_BURST_LEN ),
    .C_LOG_BURST_LEN     ( LP_LOG_BURST_LEN ),
    .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ),
    .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_read_master_a (
    .aclk   ( ap_clk ),
    .areset ( areset ),

    .ctrl_start  ( ap_start_pulse ),
    .ctrl_done   ( read_done ),
    .ctrl_offset ( a ),
    .ctrl_length ( xfer_size ),

    .arvalid ( m_axi_a_ARVALID ),
    .arready ( m_axi_a_ARREADY ),
    .araddr  ( m_axi_a_ARADDR ),
    .arid    ( m_axi_a_ARID ),
    .arlen   ( m_axi_a_ARLEN ),
    .arsize  ( m_axi_a_ARSIZE ),
    .rvalid  ( m_axi_a_RVALID ),
    .rready  ( m_axi_a_RREADY ),
    .rdata   ( m_axi_a_RDATA ),
    .rlast   ( m_axi_a_RLAST ),
    .rid     ( m_axi_a_RID ),
    .rresp   ( m_axi_a_RRESP ),

    .m_tvalid ( rd_a_tvalid ),
    .m_tready ( rd_a_tready ),
    .m_tdata  ( rd_a_tdata )
    //.m_tlast  ( rd_a_tlast )
);

// AXI4 Read Master b
axi_read_master #(
    .C_ADDR_WIDTH        ( C_M_AXI_ADDR_WIDTH ),
    .C_DATA_WIDTH        ( C_M_AXI_DATA_WIDTH ),
    .C_ID_WIDTH          ( C_M_AXI_ID_WIDTH ),
    .C_NUM_CHANNELS      ( 1 ),
    .C_LENGTH_WIDTH      ( C_XFER_SIZE_WIDTH ),
    .C_BURST_LEN         ( LP_AXI_BURST_LEN ),
    .C_LOG_BURST_LEN     ( LP_LOG_BURST_LEN ),
    .C_MAX_OUTSTANDING   ( LP_RD_MAX_OUTSTANDING ),
    .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_read_master_b (
    .aclk   ( ap_clk ),
    .areset ( areset ),

    .ctrl_start  ( ap_start_pulse ),
    .ctrl_done   ( read_done ),
    .ctrl_offset ( b ),
    .ctrl_length ( xfer_size ),

    .arvalid ( m_axi_b_ARVALID ),
    .arready ( m_axi_b_ARREADY ),
    .araddr  ( m_axi_b_ARADDR ),
    .arid    ( m_axi_b_ARID ),
    .arlen   ( m_axi_b_ARLEN ),
    .arsize  ( m_axi_b_ARSIZE ),
    .rvalid  ( m_axi_b_RVALID ),
    .rready  ( m_axi_b_RREADY ),
    .rdata   ( m_axi_b_RDATA ),
    .rlast   ( m_axi_b_RLAST ),
    .rid     ( m_axi_b_RID ),
    .rresp   ( m_axi_b_RRESP ),

    .m_tvalid ( rd_b_tvalid ),
    .m_tready ( rd_b_tready ),
    .m_tdata  ( rd_b_tdata )
    //.m_tlast  ( rd_b_tlast )
);

vadd_float_adder #(
  .C_AXIS_TDATA_WIDTH ( C_M_AXI_DATA_WIDTH )
)
inst_adder  (
  .ap_aclk   ( ap_clk ),
  .ap_areset ( areset ),

  .s_axis_a_tvalid ( rd_a_tvalid ),
  .s_axis_a_tready ( rd_a_tready ),
  .s_axis_a_tdata  ( rd_a_tdata ),
  .s_axis_a_tlast  ( rd_a_tlast ),

  .s_axis_b_tvalid ( rd_b_tvalid ),
  .s_axis_b_tready ( rd_b_tready ),
  .s_axis_b_tdata  ( rd_b_tdata ),
  .s_axis_b_tlast  ( rd_b_tlast ),

  .m_axis_result_tvalid ( wr_c_tvalid ),
  .m_axis_result_tready ( wr_c_tready ),
  .m_axis_result_tdata  ( wr_c_tdata ),
  .m_axis_result_tlast  ( wr_c_tlast )
);

// AXI4 Write Master
axi_write_master #(
    .C_ADDR_WIDTH        ( C_M_AXI_ADDR_WIDTH ),
    .C_DATA_WIDTH        ( C_M_AXI_DATA_WIDTH ),
    .C_MAX_LENGTH_WIDTH  ( C_XFER_SIZE_WIDTH ),
    .C_BURST_LEN         ( LP_AXI_BURST_LEN ),
    .C_LOG_BURST_LEN     ( LP_LOG_BURST_LEN ),
    .C_INCLUDE_DATA_FIFO ( 1 )
)
inst_axi_write_master (
    .aclk   ( ap_clk ),
    .areset ( areset ),

    .ctrl_start  ( ap_start_pulse ),
    .ctrl_offset ( c ),
    .ctrl_length ( xfer_size ),
    .ctrl_done   ( ap_done ),

    .awvalid ( m_axi_result_AWVALID ),
    .awready ( m_axi_result_AWREADY ),
    .awaddr  ( m_axi_result_AWADDR ),
    .awlen   ( m_axi_result_AWLEN ),
    .awsize  ( m_axi_result_AWSIZE ),
    .wvalid  ( m_axi_result_WVALID ),
    .wready  ( m_axi_result_WREADY ),
    .wdata   ( m_axi_result_WDATA ),
    .wstrb   ( m_axi_result_WSTRB ),
    .wlast   ( m_axi_result_WLAST ),
    .bvalid  ( m_axi_result_BVALID ),
    .bready  ( m_axi_result_BREADY ),
    .bresp   ( m_axi_result_BRESP ),

    .s_tvalid ( wr_c_tvalid ),
    .s_tready ( wr_c_tready ),
    .s_tdata  ( wr_c_tdata )
);

endmodule : vadd_float_int
`default_nettype wire
