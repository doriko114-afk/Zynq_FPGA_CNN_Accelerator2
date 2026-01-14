`timescale 1ns / 1ps
`default_nettype none

module system_top(
    input  wire clk125,        
    input  wire [3:0] sw,        
    input  wire [3:0] btn, 
    output wire [2:0] TMDSp, TMDSn,
    output wire TMDSp_clock, TMDSn_clock,
    input  wire ov7670_pclk, ov7670_vsync, ov7670_href,
    input  wire [7:0] ov7670_data,
    output wire ov7670_xclk, ov7670_sioc, 
    inout  wire ov7670_siod,
    output wire ov7670_pwdn, ov7670_reset,
    output wire [3:0] led
);

    // =========================================================================
    // [1] Hardcore Mode 학습된 Conv Layer 가중치 (I, O, W)
    // =========================================================================
    // Channel 0
    localparam signed [7:0] K00_C0=37, K01_C0=21, K02_C0=-22;
    localparam signed [7:0] K10_C0=-3, K11_C0=26, K12_C0=-1;
    localparam signed [7:0] K20_C0=-5, K21_C0=15, K22_C0=37;
    localparam signed [7:0] B_C0=3;
    // Channel 1
    localparam signed [7:0] K00_C1=-22, K01_C1=-2, K02_C1=32;
    localparam signed [7:0] K10_C1=-18, K11_C1=-1, K12_C1=23;
    localparam signed [7:0] K20_C1=-21, K21_C1=19, K22_C1=27;
    localparam signed [7:0] B_C1=-6;
    // Channel 2
    localparam signed [7:0] K00_C2=-31, K01_C2=-32, K02_C2=-21;
    localparam signed [7:0] K10_C2=21, K11_C2=5, K12_C2=13;
    localparam signed [7:0] K20_C2=37, K21_C2=26, K22_C2=38;
    localparam signed [7:0] B_C2=-10;
    // Channel 3
    localparam signed [7:0] K00_C3=22, K01_C3=16, K02_C3=7;
    localparam signed [7:0] K10_C3=36, K11_C3=-22, K12_C3=26;
    localparam signed [7:0] K20_C3=-8, K21_C3=-24, K22_C3=5;
    localparam signed [7:0] B_C3=1;

    // =========================================================================
    // Clock Generation
    // =========================================================================
    wire clk100, clk25, clk50, clk250, locked;
    assign locked = 1'b1; 
    clk_wiz_0 u_clock_gen (.clk_in1(clk125), .clk_out1(clk100), .clk_out2(clk25), .clk_out3(clk50));
    clk_wiz_1 u_hdmi_clk_gen (.clk_in1(clk25), .clk_out1(clk250));

    // =========================================================================
    // Camera Capture
    // =========================================================================
    wire config_finished;
    ov7670_controller u_cam_ctrl (
        .clk(clk50), .resend(1'b0), .config_finished(config_finished),
        .sioc(ov7670_sioc), .siod(ov7670_siod), .reset(ov7670_reset), 
        .pwdn(ov7670_pwdn), .xclk(ov7670_xclk)      
    );
    assign led[0] = config_finished; 

    wire [18:0] capture_addr;
    wire [11:0] capture_data;
    wire capture_we, capture_we_base;
    wire [9:0] cap_center_x, cap_center_y;
    
    ov7670_capture u_capture (
        .pclk(ov7670_pclk), .rez_160x120(1'b0), .rez_320x240(1'b0), 
        .sw(2'b00), 
        .btn_reset(btn[0]), 
        .btn_down(btn[1]),  
        .btn_up(btn[2]),    
        .vsync(ov7670_vsync), .href(ov7670_href), .d(ov7670_data),
        .addr(capture_addr), .dout(capture_data), .we(capture_we_base),
        .x_center(cap_center_x), .y_center(cap_center_y) 
    );
    assign capture_we = capture_we_base && (sw[0] == 1'b0);

    // =========================================================================
    // Pre-processing
    // =========================================================================
    localparam integer RATIO = 4; 
    wire [9:0] curr_x = capture_addr % 640;
    wire [9:0] curr_y = capture_addr / 640;
    
    wire [9:0] half_window_safe = 60; 
    wire x_in_range_raw = (curr_x > cap_center_x) ? ((curr_x - cap_center_x) < half_window_safe) : ((cap_center_x - curr_x) < half_window_safe);
    wire y_in_range = (curr_y > cap_center_y) ? ((curr_y - cap_center_y) < 14 * RATIO) : ((cap_center_y - curr_y) < 14 * RATIO);
    wire [9:0] roi_start_x = (cap_center_x > half_window_safe) ? (cap_center_x - half_window_safe) : 0;
    wire [9:0] roi_start_y = (cap_center_y > 56) ? (cap_center_y - 56) : 0;
    wire sampling_hit = (((curr_x - roi_start_x) % RATIO) == 0) && (((curr_y - roi_start_y) % RATIO) == 0);

    reg [5:0] samples_per_line;
    always @(posedge ov7670_pclk) begin
        if (curr_x < roi_start_x) samples_per_line <= 0;
        else if (capture_we && x_in_range_raw && sampling_hit) samples_per_line <= samples_per_line + 1;
    end
    wire strict_valid = capture_we && x_in_range_raw && y_in_range && sampling_hit && (samples_per_line < 28);
    wire raw_bin = (capture_data[11] == 1'b1);
    
    // Smear Logic
    reg [2:0] smear_cnt;
    always @(posedge ov7670_pclk) begin
        if (raw_bin) smear_cnt <= 3'd3; 
        else if (smear_cnt > 0) smear_cnt <= smear_cnt - 1; 
    end
    wire filtered_bin = raw_bin | (smear_cnt > 0);
    wire cnn_valid_in = strict_valid; 
    wire [7:0] cnn_pixel_in = filtered_bin ? 8'd1 : 8'd0; 

    // Debug Memory
    reg [0:0] debug_mem [0:783]; 
    reg [9:0] dbg_wr_ptr;
    always @(posedge ov7670_pclk) begin
        if (ov7670_vsync) dbg_wr_ptr <= 0;
        else if (cnn_valid_in && dbg_wr_ptr < 784) begin
            debug_mem[dbg_wr_ptr] <= filtered_bin;
            dbg_wr_ptr <= dbg_wr_ptr + 1;
        end
    end

    // =========================================================================
    // 4. CNN Core Instantiation
    // =========================================================================
    wire conv_valid, class_valid;
    wire signed [19:0] conv_data_0, conv_data_1, conv_data_2, conv_data_3;
    wire signed [31:0] score_o, score_w, score_i; 

    conv_layer_top #(
        .IMG_WIDTH(28), .IMG_HEIGHT(28), .DATA_WIDTH(8)
    ) u_conv_layer (
        .clk(ov7670_pclk), .rst_n(locked),
        .valid_in(cnn_valid_in), .data_in(cnn_pixel_in),
        // Ch0 Params
        .k00_ch0(K00_C0), .k01_ch0(K01_C0), .k02_ch0(K02_C0),
        .k10_ch0(K10_C0), .k11_ch0(K11_C0), .k12_ch0(K12_C0),
        .k20_ch0(K20_C0), .k21_ch0(K21_C0), .k22_ch0(K22_C0), .bias_ch0(B_C0),
        // Ch1 Params
        .k00_ch1(K00_C1), .k01_ch1(K01_C1), .k02_ch1(K02_C1),
        .k10_ch1(K10_C1), .k11_ch1(K11_C1), .k12_ch1(K12_C1),
        .k20_ch1(K20_C1), .k21_ch1(K21_C1), .k22_ch1(K22_C1), .bias_ch1(B_C1),
        // Ch2 Params
        .k00_ch2(K00_C2), .k01_ch2(K01_C2), .k02_ch2(K02_C2),
        .k10_ch2(K10_C2), .k11_ch2(K11_C2), .k12_ch2(K12_C2),
        .k20_ch2(K20_C2), .k21_ch2(K21_C2), .k22_ch2(K22_C2), .bias_ch2(B_C2),
        // Ch3 Params
        .k00_ch3(K00_C3), .k01_ch3(K01_C3), .k02_ch3(K02_C3),
        .k10_ch3(K10_C3), .k11_ch3(K11_C3), .k12_ch3(K12_C3),
        .k20_ch3(K20_C3), .k21_ch3(K21_C3), .k22_ch3(K22_C3), .bias_ch3(B_C3),
        .valid_out(conv_valid),
        .layer_out_0(conv_data_0), .layer_out_1(conv_data_1),
        .layer_out_2(conv_data_2), .layer_out_3(conv_data_3)
    );

    // =========================================================================
    // [BTN3 Logic Fix] "근본 해결": VSYNC를 클럭 대신 데이터로 감지
    // =========================================================================
    reg [1:0] bias_state; // 0~3
    reg btn3_prev;
    reg vsync_prev; // VSYNC Edge 감지용

    // [핵심 변경] 클럭을 VSYNC가 아닌 PCLK로 변경
    always @(posedge ov7670_pclk) begin
        vsync_prev <= ov7670_vsync; // VSYNC 상태 저장

        if (btn[0]) begin
            bias_state <= 0; 
        end else begin
            // VSYNC Rising Edge 감지 (화면 한 프레임 시작될 때)
            // 즉, 60Hz 속도로 이 내부가 실행됨
            if (ov7670_vsync && !vsync_prev) begin 
                // 여기서 버튼 확인 (디바운싱 효과)
                btn3_prev <= btn[3];
                if (btn[3] && !btn3_prev) begin // 버튼 눌림 감지
                    bias_state <= bias_state + 1;
                end
            end
        end
    end

    // 상태에 따른 보정값 할당
    wire signed [31:0] bias_adj_o = (bias_state == 2) ? 32'd20 : 32'd0; 
    wire signed [31:0] bias_adj_w = (bias_state == 3) ? 32'd20 : 32'd0; 
    wire signed [31:0] bias_adj_i = (bias_state == 1) ? 32'd20 : 32'd0; 

    // FC Layer 연결
    fc_layer #(
        .DATA_WIDTH(20), .NUM_INPUTS(676)
    ) u_fc_layer (
        .clk(ov7670_pclk), .rst_n(locked), .en(sw[1]), 
        .valid_in(conv_valid),
        .adj_bias_0(bias_adj_o), .adj_bias_1(bias_adj_w), .adj_bias_2(bias_adj_i), 
        .data_in_0(conv_data_0), .data_in_1(conv_data_1),
        .data_in_2(conv_data_2), .data_in_3(conv_data_3),
        .valid_out(class_valid), 
        .score0(score_o), .score1(score_w), .score2(score_i)
    );

    // =========================================================================
    // Voting Logic
    // =========================================================================
    localparam integer VOTE_PERIOD = 25000000; 
    reg [31:0] vote_timer;
    reg [31:0] cnt_o, cnt_w, cnt_i; 
    reg [2:0]  disp_shape_code; 

    always @(posedge ov7670_pclk) begin
        if (sw[0] == 1'b0) begin 
            if (vote_timer >= VOTE_PERIOD) begin
                if (cnt_o >= cnt_w && cnt_o >= cnt_i) disp_shape_code <= 3'd1; 
                else if (cnt_w >= cnt_o && cnt_w >= cnt_i) disp_shape_code <= 3'd2; 
                else disp_shape_code <= 3'd3; 

                vote_timer <= 0;
                cnt_o <= 0; cnt_w <= 0; cnt_i <= 0;
            end 
            else begin
                vote_timer <= vote_timer + 1;
                if (class_valid) begin
                    if (score_o >= score_w && score_o >= score_i) cnt_o <= cnt_o + 1;
                    else if (score_w >= score_o && score_w >= score_i) cnt_w <= cnt_w + 1;
                    else cnt_i <= cnt_i + 1;
                end
            end
        end
    end
    assign led[3:1] = disp_shape_code; 

    // =========================================================================
    // Video Output & OSD
    // =========================================================================
    wire [18:0] frame_addr_read;
    wire [11:0] frame_pixel_read;
    wire vga_hsync, vga_vsync, vga_active;
    wire [7:0] vga_r, vga_g, vga_b;
    
    frame_buffer u_frame_buffer (
        .clka(ov7670_pclk), .wea(capture_we), .addra(capture_addr), .dina(capture_data),
        .clkb(clk25), .addrb(frame_addr_read), .doutb(frame_pixel_read)
    );
    
    reg [9:0] vga_x = 0, vga_y = 0;
    always @(posedge clk25) begin
        if (vga_active) begin
            if (vga_x == 639) begin vga_x <= 0; if (vga_y == 479) vga_y <= 0; else vga_y <= vga_y + 1; end 
            else vga_x <= vga_x + 1;
        end else if (!vga_vsync) begin vga_x <= 0; vga_y <= 0; end
    end
    assign frame_addr_read = vga_y * 640 + vga_x;

    wire debug_pixel_on;
    wire [9:0] dbg_x_rel = (vga_x >= 500) ? (vga_x - 500) : 0;
    wire [9:0] dbg_y_rel = (vga_y >= 50) ? (vga_y - 50) : 0;
    wire [9:0] dbg_read_addr = (dbg_y_rel[9:2]) * 28 + (dbg_x_rel[9:2]); 
    assign debug_pixel_on = (vga_x >= 500 && vga_x < 500 + 112 && vga_y >= 50 && vga_y < 50 + 112) ? 
                            debug_mem[dbg_read_addr] : 1'b0;

    VGA u_vga_timing (
        .CLK25(clk25), .rez_160x120(1'b0), .rez_320x240(1'b0), 
        .Hsync(vga_hsync), .Vsync(vga_vsync), .Nblank(vga_active)
    );

    wire [3:0] osd_sw_mapped = {sw[3], 1'b1, sw[1], sw[0]};

    RGB u_osd (
        .Din(frame_pixel_read), .Nblank(vga_active), .CLK(clk25),
        .Hsync(vga_hsync), .Vsync(vga_vsync),
        .msg_code(disp_shape_code), .sw(osd_sw_mapped), 
        .debug_pixel(debug_pixel_on),
        .score_c(score_o), .score_t(score_i), .score_s(score_w), 
        .R(vga_r), .G(vga_g), .B(vga_b),
        .target_x(cap_center_x), .target_y(cap_center_y),
        .x_center(10'd0), .y_center(10'd0)
    );

    VGA2HDMI u_hdmi (
        .pixclk(clk25), .clk_TMDS(clk250), 
        .VSYNC(vga_vsync), .HSYNC(vga_hsync), .ACTIVE(vga_active),
        .red(vga_r), .green(vga_g), .blue(vga_b),
        .TMDSp(TMDSp), .TMDSn(TMDSn), 
        .TMDSp_clock(TMDSp_clock), .TMDSn_clock(TMDSn_clock)
    );

endmodule