`timescale 1ns / 1ps
`default_nettype wire 

module ov7670_registers_2(
    input wire clk,
    input wire resend,
    input wire advance,
    output wire [15:0] command,
    output wire finished
);

    reg [15:0] sreg;
    reg finished_temp;
    reg [7:0] address = {8{1'b0}};
    
    assign command = sreg;
    assign finished = finished_temp;
    
    always @ (sreg) begin
        if(sreg == 16'hFFFF) begin
            finished_temp <= 1;
        end
        else begin
            finished_temp <= 0;
        end
    end
    
    always @ (posedge clk) begin
        if(resend == 1) begin
            address <= {8{1'b0}};
        end
        else if(advance == 1) begin
            address <= address+1;
        end
            
        case (address)
                0:  sreg <= 16'h12_80; // Reset
                1:  sreg <= 16'hFF_F0; // Delay
                
                // [핵심 수정 1] COM7: YUV 모드로 설정
                2:  sreg <= 16'h12_00; // COM7, YUV mode (bit 2=0, bit 0=0)
                
                3:  sreg <= 16'h11_80; // CLKRC
                4:  sreg <= 16'h0C_00; // COM3
                5:  sreg <= 16'h3E_00; // COM14
                6:  sreg <= 16'h04_00; // COM1
                
                // [핵심 수정 2] COM15: YUV 출력 범위 설정 (RGB565 해제)
                // 0xC0 = [1100 0000] -> Output range: Full range (00 to FF)
                7:  sreg <= 16'h40_C0; 
                
                8:  sreg <= 16'h3a_04; // TSLB (YUYV sequence)
                9:  sreg <= 16'h14_18; // COM9
                // ... 아래 매트릭스 설정은 YUV 변환용이지만 YUV 출력 시엔 내부 처리됨 ...
                10: sreg <= 16'h4F_B3; 
                11: sreg <= 16'h50_B3; 
                12: sreg <= 16'h51_00; 
                13: sreg <= 16'h52_3d; 
                14: sreg <= 16'h53_A7; 
                15: sreg <= 16'h54_E4; 
                16: sreg <= 16'h58_9E; 
                17: sreg <= 16'h3D_C0; 
                18: sreg <= 16'h17_14; 
                19: sreg <= 16'h18_02; 
                20: sreg <= 16'h32_80; 
                21: sreg <= 16'h19_03; 
                22: sreg <= 16'h1A_7B; 
                23: sreg <= 16'h03_0A; 
                24: sreg <= 16'h0F_41; 
                25: sreg <= 16'h1E_00; 
                26: sreg <= 16'h33_0B; 
                27: sreg <= 16'h3C_78; 
                28: sreg <= 16'h69_0a; 
                29: sreg <= 16'h74_00; 
                30: sreg <= 16'hB0_84; 
                31: sreg <= 16'hB1_0c; 
                32: sreg <= 16'hB2_0e; 
                33: sreg <= 16'hB3_80; 
                34: sreg <= 16'h70_3a;
                35: sreg <= 16'h71_35;
                36: sreg <= 16'h72_11;
                37: sreg <= 16'h73_f0;
                38: sreg <= 16'ha2_02;
                39: sreg <= 16'h7a_20;
                40: sreg <= 16'h7b_10;
                41: sreg <= 16'h7c_1e;
                42: sreg <= 16'h7d_35;
                43: sreg <= 16'h7e_5a;
                44: sreg <= 16'h7f_69;
                45: sreg <= 16'h80_76;
                46: sreg <= 16'h81_80;
                47: sreg <= 16'h82_88;
                48: sreg <= 16'h83_8f;
                49: sreg <= 16'h84_96;
                50: sreg <= 16'h85_a3;
                51: sreg <= 16'h86_af;
                52: sreg <= 16'h87_c4;
                53: sreg <= 16'h88_d7;
                54: sreg <= 16'h89_e8;
                55: sreg <= 16'h13_e0; 
                56: sreg <= 16'h00_00; 
                57: sreg <= 16'h10_00; 
                58: sreg <= 16'h0d_40; 
                59: sreg <= 16'h14_18; 
                60: sreg <= 16'ha5_05; 
                61: sreg <= 16'hab_07; 
                62: sreg <= 16'h24_95; 
                63: sreg <= 16'h25_33; 
                64: sreg <= 16'h26_e3; 
                65: sreg <= 16'h9f_78; 
                66: sreg <= 16'ha0_68; 
                67: sreg <= 16'ha1_03; 
                68: sreg <= 16'ha6_d8; 
                69: sreg <= 16'ha7_d8; 
                70: sreg <= 16'ha8_f0; 
                71: sreg <= 16'ha9_90; 
                72: sreg <= 16'haa_94; 
                73: sreg <= 16'h13_e5; 
                default : sreg <= 16'hFFFF;
        endcase
    end
endmodule