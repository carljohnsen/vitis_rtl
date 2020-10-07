`default_nettype none
`timescale 1ps / 1ps

module byteswap_swapper #(
    parameter integer C_AXIS_TDATA_WIDTH = 512,
    parameter integer C_WORD_BIT_WIDTH   = 32,
    parameter integer C_BYTE_BIT_WIDTH   = 8
)
(
    input  wire                            s_axis_aclk,
    input  wire                            s_axis_areset,
    input  wire                            s_axis_tvalid,
    output wire                            s_axis_tready,
    input  wire [C_AXIS_TDATA_WIDTH-1:0]   s_axis_tdata,
    input  wire [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tkeep,
    input  wire                            s_axis_tlast,

    input  wire                            m_axis_aclk,
    output wire                            m_axis_tvalid,
    input  wire                            m_axis_tready,
    output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_tdata,
    output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tkeep,
    output wire                            m_axis_tlast
);

// Local parameters
localparam integer LP_NUM_LOOPS = C_AXIS_TDATA_WIDTH/C_WORD_BIT_WIDTH;
localparam integer LP_NUM_BYTES = C_WORD_BIT_WIDTH / C_BYTE_BIT_WIDTH;

/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////
reg                              d1_tvalid = 1'b0;
reg                              d1_tready = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d1_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tkeep;
reg                              d1_tlast;

reg                              d2_tvalid = 1'b0;
reg                              d2_tready;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d2_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tkeep;
reg                              d2_tlast;

integer i;
integer j;

/////////////////////////////////////////////////////////////////////////////
// RTL Logic
/////////////////////////////////////////////////////////////////////////////

// Register s_axis_interface
always @(posedge s_axis_aclk) begin
  d1_tvalid <= s_axis_tvalid;
  d1_tready <= d2_tready;
  d1_tdata  <= s_axis_tdata;
  d1_tkeep  <= s_axis_tkeep;
  d1_tlast  <= s_axis_tlast;
end

// Swapper function
always @(posedge s_axis_aclk) begin
    for (i = 0; i < LP_NUM_LOOPS; i = i + 1) begin
        for (j = 0; j < LP_NUM_BYTES;  j = j + 1) begin
            d2_tdata[(i*C_WORD_BIT_WIDTH)+(j*C_BYTE_BIT_WIDTH)+:C_BYTE_BIT_WIDTH] <=
                d1_tdata[(C_WORD_BIT_WIDTH*(i+1))-((j+1)*C_BYTE_BIT_WIDTH)+:C_BYTE_BIT_WIDTH];
        end
    end
end

// Register for m_axis_interface
always @(posedge s_axis_aclk) begin
    d2_tvalid <= d1_tvalid & d1_tready;
    d2_tready <= m_axis_tready;
    d2_tkeep  <= d1_tkeep;
    d2_tlast  <= d1_tlast;
end

assign s_axis_tready = d1_tready;
assign m_axis_tvalid = d2_tvalid;
assign m_axis_tdata  = d2_tdata;
assign m_axis_tkeep  = d2_tkeep;
assign m_axis_tlast  = d2_tlast;

endmodule

`default_nettype wire

