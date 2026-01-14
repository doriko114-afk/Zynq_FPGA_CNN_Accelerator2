module CAMERA2HDMI(	
    input clk125, input btnl, input btn0, input btnr, input [1:0] sw,
    output config_finished, output [2:0] TMDSp, TMDSn, output TMDSp_clock, TMDSn_clock,
    
    input [9:0] target_x, input [9:0] target_y,
    output [9:0] x_pos_out, output [9:0] y_pos_out,
    
    // [NEW] 메시지 코드 입력
    input [2:0] msg_code,

    input ov7670_pclk, output ov7670_xclk, input ov7670_vsync, input ov7670_href,
    input [7:0] ov7670_data, output ov7670_sioc, inout ov7670_siod, output ov7670_pwdn, output ov7670_reset
);
    wire clk100, clk25;
    clk_wiz_0 c2(.clk_in1(clk125), .clk_out1(clk100), .clk_out2(clk25));
    wire vga_hsync, vga_vsync, vga_active;
    wire [3:0] vga_r, vga_g, vga_b;

    camera2vga c2v0(
        .clk100(clk100), .btnl(btnl), .btnc(btn0), .btnr(btnr), .sw(sw), 
        .config_finished(config_finished),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync), .vga_active(vga_active), 
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .target_x_in(target_x), .target_y_in(target_y),
        .x_pos_out(x_pos_out), .y_pos_out(y_pos_out), // current x, y
        
        // 연결
        .msg_code_in(msg_code),
        
        .ov7670_pclk(ov7670_pclk), .ov7670_xclk(ov7670_xclk), .ov7670_vsync(ov7670_vsync), 
        .ov7670_href(ov7670_href), .ov7670_data(ov7670_data), .ov7670_sioc(ov7670_sioc),
        .ov7670_siod(ov7670_siod), .ov7670_pwdn(ov7670_pwdn), .ov7670_reset(ov7670_reset)
    );

    wire [7:0] red = {vga_r, 4'b0000}; wire [7:0] green = {vga_g, 4'b0000}; wire [7:0] blue = {vga_b, 4'b0000};
    VGA2HDMI v2h0(.pixclk(clk25), .VSYNC(vga_vsync), .HSYNC(vga_hsync), .ACTIVE(vga_active), .red(red), .green(green), .blue(blue), .TMDSp(TMDSp), .TMDSn(TMDSn), .TMDSp_clock(TMDSp_clock), .TMDSn_clock(TMDSn_clock));
endmodule