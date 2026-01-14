`timescale 1 ns / 1 ps

module myip_single_ov7670_v1_0 #
(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
)
(
    // [사용자 추가 포트] 외부 하드웨어 제어
    input wire [1:0] sw,
    input wire btn0, // Reset
    input wire btnl, // Threshold Down
    input wire btnr, // Threshold Up
    output wire config_finished, // LED 확인용

    // [사용자 추가 포트] 1. 시스템 클럭 & 타겟 좌표
    input wire clk125,
    input wire [9:0] target_x,
    input wire [9:0] target_y,

    // [사용자 추가 포트] 2. HDMI Interface
    output wire [2:0] TMDSp,
    output wire [2:0] TMDSn,
    output wire TMDSp_clock,
    output wire TMDSn_clock,

    // [사용자 추가 포트] 3. OV7670 Camera Interface
    input wire ov7670_pclk,
    output wire ov7670_xclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    output wire ov7670_sioc,
    inout wire ov7670_siod,
    output wire ov7670_pwdn,
    output wire ov7670_reset,

    // Ports of Axi Slave Bus Interface S00_AXI
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

    // Instantiation of Axi Bus Interface S00_AXI
    myip_single_ov7670_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) myip_single_ov7670_v1_0_S00_AXI_inst (
        // [사용자 포트 연결]
        .sw(sw),
        .btn0(btn0),
        .btnl(btnl),
        .btnr(btnr),
        .config_finished(config_finished),
        .target_x(target_x),
        .target_y(target_y),

        .clk125(clk125),
        .TMDSp(TMDSp),
        .TMDSn(TMDSn),
        .TMDSp_clock(TMDSp_clock),
        .TMDSn_clock(TMDSn_clock),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_xclk(ov7670_xclk),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_href(ov7670_href),
        .ov7670_data(ov7670_data),
        .ov7670_sioc(ov7670_sioc),
        .ov7670_siod(ov7670_siod),
        .ov7670_pwdn(ov7670_pwdn),
        .ov7670_reset(ov7670_reset),
        
        // AXI Ports
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

endmodule