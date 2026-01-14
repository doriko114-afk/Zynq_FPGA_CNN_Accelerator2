`timescale 1 ns / 1 ps

module myip_single_ov7670_v1_0_S00_AXI #
(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    // [사용자 추가 포트] 외부 제어 핀 (Top에서 받아옴)
    input wire [1:0] sw,
    input wire btn0,
    input wire btnl,
    input wire btnr,
    output wire config_finished,

    // 목표 좌표 입력 (Top -> AXI -> CAMERA2HDMI)
    input wire [9:0] target_x,
    input wire [9:0] target_y,

    // [사용자 추가 포트] 외부 하드웨어 핀
    input wire clk125,
    output wire [2:0] TMDSp, 
    output wire [2:0] TMDSn,
    output wire TMDSp_clock, 
    output wire TMDSn_clock,
    input wire ov7670_pclk,
    output wire ov7670_xclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    output wire ov7670_sioc,
    inout wire ov7670_siod,
    output wire ov7670_pwdn,
    output wire ov7670_reset,

    // AXI Ports (기본 제공)
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
    reg     axi_awready;
    reg     axi_wready;
    reg [1 : 0]     axi_bresp;
    reg     axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg     axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata;
    reg [1 : 0]     axi_rresp;
    reg     axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    
    // 레지스터 정의
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg0; // Control (Write Only)
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg1; // Reserved
    // slv_reg2, slv_reg3는 Direct Wire 연결로 대체하여 삭제함 (최적화 방지)
    
    wire     slv_reg_rden;
    wire     slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0]     reg_data_out;
    integer  byte_index;
    reg  aw_en;

    // 내부 와이어 선언 (User Logic 연결용 - 좌표값 전달)
    wire [9:0] x_pos_wire;
    wire [9:0] y_pos_wire;

    // I/O Connections assignments
    assign S_AXI_AWREADY    = axi_awready;
    assign S_AXI_WREADY     = axi_wready;
    assign S_AXI_BRESP      = axi_bresp;
    assign S_AXI_BVALID     = axi_bvalid;
    assign S_AXI_ARREADY    = axi_arready;
    assign S_AXI_RDATA      = axi_rdata;
    assign S_AXI_RRESP      = axi_rresp;
    assign S_AXI_RVALID     = axi_rvalid;

    // Implement axi_awready generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awready <= 1'b0;
          aw_en <= 1'b1;
        end 
      else
        begin    
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
              axi_awready <= 1'b1;
              aw_en <= 1'b0;
            end
            else if (S_AXI_BREADY && axi_bvalid)
                begin
                  aw_en <= 1'b1;
                  axi_awready <= 1'b0;
                end
          else           
            begin
              axi_awready <= 1'b0;
            end
        end 
    end       

    // Implement axi_awaddr latching
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awaddr <= 0;
        end 
      else
        begin    
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
              axi_awaddr <= S_AXI_AWADDR;
            end
        end 
    end       

    // Implement axi_wready generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end 
      else
        begin    
          if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
            begin
              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end 
    end       

    // Implement memory mapped register select and write logic generation
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg0 <= 0;
          slv_reg1 <= 0;
        end 
      else begin
        if (slv_reg_wren)
          begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
              2'h0:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) 
                    slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              2'h1:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) 
                    slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              default : begin
                          slv_reg0 <= slv_reg0;
                          slv_reg1 <= slv_reg1;
                        end
            endcase
          end
      end
    end    

    // Implement write response logic generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_bvalid  <= 0;
          axi_bresp   <= 2'b0;
        end 
      else
        begin    
          if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
            begin
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0;
            end                   
          else
            begin
              if (S_AXI_BREADY && axi_bvalid) 
                begin
                  axi_bvalid <= 1'b0;
                end  
            end
        end
    end   

    // Implement axi_arready generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_arready <= 1'b0;
          axi_araddr  <= 32'b0;
        end 
      else
        begin    
          if (~axi_arready && S_AXI_ARVALID)
            begin
              axi_arready <= 1'b1;
              axi_araddr  <= S_AXI_ARADDR;
            end
          else
            begin
              axi_arready <= 1'b0;
            end
        end 
    end       

    // Implement axi_arvalid generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_rvalid <= 0;
          axi_rresp  <= 0;
        end 
      else
        begin    
          if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
            begin
              axi_rvalid <= 1'b1;
              axi_rresp  <= 2'b0;
            end   
          else if (axi_rvalid && S_AXI_RREADY)
            begin
              axi_rvalid <= 1'b0;
            end                
        end
    end    

    // -------------------------------------------------------------------------
    // [핵심 수정] AXI Read Logic (Direct Wire Connection)
    // -------------------------------------------------------------------------
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*)
    begin
          // Address Decoding for reading registers
          case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            2'h0   : reg_data_out <= slv_reg0; // Control Register
            2'h1   : reg_data_out <= slv_reg1; // Reserved
            
            // [수정 포인트] 레지스터(slv_reg2)를 거치지 않고 Wire 값을 바로 연결!
            // 이렇게 해야 Vivado가 "값이 계속 변하는구나"라고 인식하여 최적화(삭제)하지 않습니다.
            2'h2   : reg_data_out <= {22'b0, x_pos_wire}; // Offset 0x08: X 좌표
            2'h3   : reg_data_out <= {22'b0, y_pos_wire}; // Offset 0x0C: Y 좌표
            
            default : reg_data_out <= 0;
          endcase
    end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_rdata  <= 0;
        end 
      else
        begin    
          if (slv_reg_rden)
            begin
              axi_rdata <= reg_data_out;
            end   
        end
    end    

    // ---------------------------------------------------------------------------------
    // [User Logic] CAMERA2HDMI 모듈 인스턴스화 및 외부 물리 스위치 연결
    // ---------------------------------------------------------------------------------

    CAMERA2HDMI u_camera_system (
        // 1. 외부 하드웨어 포트 연결 (Clock, Camera, HDMI)
        .clk125(clk125),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_xclk(ov7670_xclk),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_href(ov7670_href),
        .ov7670_data(ov7670_data),
        .ov7670_sioc(ov7670_sioc),
        .ov7670_siod(ov7670_siod),
        .ov7670_pwdn(ov7670_pwdn),
        .ov7670_reset(ov7670_reset),
        .TMDSp(TMDSp),
        .TMDSn(TMDSn),
        .TMDSp_clock(TMDSp_clock),
        .TMDSn_clock(TMDSn_clock),
        .config_finished(config_finished),

        // 2. 외부 물리 스위치/버튼 직접 연결
        .sw(sw),     
        .btn0(btn0), // Reset 버튼
        .btnl(btnl), 
        .btnr(btnr), 
        
        // 3. Vitis에서 보낸 목표 좌표 (GPIO 등을 통해 들어오는 값)
        // [중요] 여기 포트는 잘 연결했지만, 위쪽 module 선언부에 없어서 에러가 났었습니다.
        .target_x(target_x), 
        .target_y(target_y),

        // [중요] Vitis에서 보낸 제어 신호 (메시지 코드) 연결
        .msg_code(slv_reg0[2:0]),

        // 4. [핵심] 결과값 출력 (AXI로 읽어갈 값) -> Wire로 연결됨
        .x_pos_out(x_pos_wire),
        .y_pos_out(y_pos_wire)
    );
    // User logic ends

endmodule