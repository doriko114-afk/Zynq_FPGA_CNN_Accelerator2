--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;

--entity camera2vga is
--    Port ( clk100          : in  STD_LOGIC;
--           btnl            : in  STD_LOGIC; 
--           btnc            : in  STD_LOGIC; 
--           btnr            : in  STD_LOGIC; 
--           sw              : in  STD_LOGIC_VECTOR(1 downto 0); 
--           config_finished : out STD_LOGIC;
--           vga_hsync, vga_vsync, vga_active : out STD_LOGIC;
--           vga_r, vga_g, vga_b : out STD_LOGIC_vector(3 downto 0);
           
--           ov7670_pclk, ov7670_vsync, ov7670_href : in STD_LOGIC;
--           ov7670_data : in STD_LOGIC_vector(7 downto 0);
--           ov7670_xclk, ov7670_sioc, ov7670_pwdn, ov7670_reset : out STD_LOGIC;
--           ov7670_siod : inout STD_LOGIC;
           
--           target_x_in  : in STD_LOGIC_VECTOR(9 downto 0);
--           target_y_in  : in STD_LOGIC_VECTOR(9 downto 0);
--           x_pos_out    : out STD_LOGIC_VECTOR(9 downto 0);
--           y_pos_out    : out STD_LOGIC_VECTOR(9 downto 0);
           
--           -- [NEW] 메시지 입력
--           msg_code_in  : in STD_LOGIC_VECTOR(2 downto 0)
--           );
--end camera2vga;

--architecture Behavioral of camera2vga is
--    -- Component 선언부 (생략 없이 RGB 부분 수정됨)
--    COMPONENT VGA PORT(CLK25, rez_160x120, rez_320x240 : IN std_logic; Hsync, Vsync, Nblank, clkout, activeArea, Nsync : OUT std_logic); END COMPONENT;
--    COMPONENT ov7670_controller PORT(clk, resend : IN std_logic; siod : INOUT std_logic; config_finished, sioc, reset, pwdn, xclk : OUT std_logic); END COMPONENT;
--    COMPONENT debounce PORT(clk, i : IN std_logic; o : OUT std_logic); END COMPONENT;
--    COMPONENT frame_buffer PORT (clka : IN STD_LOGIC; wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0); addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0); dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0); clkb : IN STD_LOGIC; addrb : IN STD_LOGIC_VECTOR(18 DOWNTO 0); doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)); END COMPONENT;
--    COMPONENT ov7670_capture PORT(rez_160x120, rez_320x240 : IN std_logic; sw : IN std_logic_vector(1 downto 0); btn_up, btn_down : IN std_logic; pclk, vsync, href : IN std_logic; d : IN std_logic_vector(7 downto 0); addr : OUT std_logic_vector(18 downto 0); dout : OUT std_logic_vector(11 downto 0); we : OUT std_logic; x_center, y_center : OUT std_logic_vector(9 downto 0)); END COMPONENT;
--    COMPONENT Address_Generator PORT(CLK25, rez_160x120, rez_320x240, enable, vsync : IN std_logic; address : OUT std_logic_vector(18 downto 0)); END COMPONENT;
--    component clocking port (CLK_100 : in std_logic; CLK_50, CLK_25 : out std_logic); end component;

--    -- [RGB Component 수정]
--    COMPONENT RGB
--    PORT(
--        Din : IN std_logic_vector(11 downto 0); Nblank, CLK, Hsync, Vsync : IN std_logic;
--        x_center, y_center, target_x, target_y : in STD_LOGIC_VECTOR(9 downto 0);
--        msg_code : in STD_LOGIC_VECTOR(2 downto 0); -- 추가됨
--        R, G, B : OUT std_logic_vector(7 downto 0)
--        );
--    END COMPONENT;

--   signal clk_camera, clk_vga, resend, nBlank, vSync_int, hSync_int, nSync, activeArea, rez_160x120, rez_320x240 : std_logic;
--   signal wren : std_logic_vector(0 downto 0);
--   signal wraddress, rdaddress : std_logic_vector(18 downto 0);
--   signal wrdata, rddata : std_logic_vector(11 downto 0);
--   signal red, green, blue : std_logic_vector(7 downto 0);
--   signal center_x, center_y : std_logic_vector(9 downto 0);

--begin
--   vga_r <= red(7 downto 4); vga_g <= green(7 downto 4); vga_b <= blue(7 downto 4);
--   x_pos_out <= center_x; y_pos_out <= center_y;
--   rez_160x120 <= '0'; rez_320x240 <= '0'; 
--   vga_vsync <= vSync_int; vga_hsync <= hSync_int; vga_active <= nBlank;
   
--   clk_gen : clocking port map (CLK_100 => CLK100, CLK_50 => CLK_camera, CLK_25 => CLK_vga);
--   Inst_VGA: VGA PORT MAP(CLK25=>clk_vga, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, Hsync=>hSync_int, Vsync=>vSync_int, Nblank=>nBlank, Nsync=>nsync, activeArea=>activeArea);
--   Inst_debounce: debounce PORT MAP(clk=>clk_vga, i=>btnc, o=>resend);
--   Inst_ov7670_controller: ov7670_controller PORT MAP(clk=>clk_camera, resend=>resend, config_finished=>config_finished, sioc=>ov7670_sioc, siod=>ov7670_siod, reset=>ov7670_reset, pwdn=>ov7670_pwdn, xclk=>ov7670_xclk);
--   Inst_frame_buffer: frame_buffer PORT MAP(addrb=>rdaddress, clkb=>clk_vga, doutb=>rddata, clka=>ov7670_pclk, addra=>wraddress, dina=>wrdata, wea=>wren);
--   Inst_ov7670_capture: ov7670_capture PORT MAP(pclk=>ov7670_pclk, sw=>sw, btn_up=>btnr, btn_down=>btnl, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, vsync=>ov7670_vsync, href=>ov7670_href, d=>ov7670_data, addr=>wraddress, dout=>wrdata, we=>wren(0), x_center=>center_x, y_center=>center_y);
--   Inst_Address_Generator: Address_Generator PORT MAP(CLK25=>clk_vga, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, enable=>activeArea, vsync=>vSync_int, address=>rdaddress);

--   -- [RGB 연결 수정]
--   Inst_RGB: RGB PORT MAP(
--        Din => rddata, Nblank => activeArea, CLK => clk_vga, Hsync => hSync_int, Vsync => vSync_int,
--        x_center => center_x, y_center => center_y,
--        target_x => target_x_in, target_y => target_y_in,
--        msg_code => msg_code_in, -- 연결
--        R => red, G => green, B => blue
--    );
--end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity camera2vga is
    Port ( clk100          : in  STD_LOGIC;
           btnl            : in  STD_LOGIC; 
           btnc            : in  STD_LOGIC; 
           btnr            : in  STD_LOGIC; 
           sw              : in  STD_LOGIC_VECTOR(1 downto 0); 
           config_finished : out STD_LOGIC;
           
           -- HDMI/VGA 출력 포트
           vga_hsync, vga_vsync, vga_active : out STD_LOGIC;
           vga_r, vga_g, vga_b : out STD_LOGIC_vector(3 downto 0);
           
           -- 카메라 입력 포트
           ov7670_pclk, ov7670_vsync, ov7670_href : in STD_LOGIC;
           ov7670_data : in STD_LOGIC_vector(7 downto 0);
           ov7670_xclk, ov7670_sioc, ov7670_pwdn, ov7670_reset : out STD_LOGIC;
           ov7670_siod : inout STD_LOGIC;
           
           -- 좌표 관련
           target_x_in  : in STD_LOGIC_VECTOR(9 downto 0);
           target_y_in  : in STD_LOGIC_VECTOR(9 downto 0);
           x_pos_out    : out STD_LOGIC_VECTOR(9 downto 0);
           y_pos_out    : out STD_LOGIC_VECTOR(9 downto 0);
           
           msg_code_in  : in STD_LOGIC_VECTOR(2 downto 0)
           );
end camera2vga;

architecture Behavioral of camera2vga is
    COMPONENT VGA PORT(CLK25, rez_160x120, rez_320x240 : IN std_logic; Hsync, Vsync, Nblank, clkout, activeArea, Nsync : OUT std_logic); END COMPONENT;
    COMPONENT ov7670_controller PORT(clk, resend : IN std_logic; siod : INOUT std_logic; config_finished, sioc, reset, pwdn, xclk : OUT std_logic); END COMPONENT;
    COMPONENT debounce PORT(clk, i : IN std_logic; o : OUT std_logic); END COMPONENT;
    COMPONENT frame_buffer PORT (clka : IN STD_LOGIC; wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0); addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0); dina : IN STD_LOGIC_VECTOR(11 DOWNTO 0); clkb : IN STD_LOGIC; addrb : IN STD_LOGIC_VECTOR(18 DOWNTO 0); doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)); END COMPONENT;
    COMPONENT ov7670_capture PORT(pclk : in STD_LOGIC; rez_160x120, rez_320x240 : IN std_logic; sw : IN std_logic_vector(1 downto 0); btn_up, btn_down : IN std_logic; vsync, href : IN std_logic; d : IN std_logic_vector(7 downto 0); addr : OUT std_logic_vector(18 downto 0); dout : OUT std_logic_vector(11 downto 0); we : OUT std_logic; x_center, y_center : OUT std_logic_vector(9 downto 0)); END COMPONENT;
    COMPONENT Address_Generator PORT(CLK25, rez_160x120, rez_320x240, enable, vsync : IN std_logic; address : OUT std_logic_vector(18 downto 0)); END COMPONENT;
    component clocking port (CLK_100 : in std_logic; CLK_50, CLK_25 : out std_logic); end component;
    
    COMPONENT RGB
    PORT(
        Din : IN std_logic_vector(11 downto 0); Nblank, CLK, Hsync, Vsync : IN std_logic;
        x_center, y_center, target_x, target_y : in STD_LOGIC_VECTOR(9 downto 0);
        msg_code : in STD_LOGIC_VECTOR(2 downto 0);
        R, G, B : OUT std_logic_vector(7 downto 0)
        );
    END COMPONENT;

   signal clk_camera, clk_vga, resend, nBlank, vSync_int, hSync_int, nSync, activeArea, rez_160x120, rez_320x240 : std_logic;
   signal wren : std_logic_vector(0 downto 0);
   signal wraddress, rdaddress : std_logic_vector(18 downto 0);
   signal wrdata, rddata : std_logic_vector(11 downto 0);
   signal red, green, blue : std_logic_vector(7 downto 0);
   signal center_x, center_y : std_logic_vector(9 downto 0);
   
   -- [SYNC FIX] 지연 신호 정의 (BRAM Latency 보상용)
   signal hSync_d1, hSync_d2 : std_logic;
   signal vSync_d1, vSync_d2 : std_logic;
   signal active_d1, active_d2 : std_logic;

begin
   -- [SYNC FIX] 최종 출력은 2클럭 지연된 신호 사용
   vga_r <= red(7 downto 4); 
   vga_g <= green(7 downto 4); 
   vga_b <= blue(7 downto 4);
   
   vga_vsync <= vSync_d2; 
   vga_hsync <= hSync_d2;
   vga_active <= active_d2;

   x_pos_out <= center_x; 
   y_pos_out <= center_y;
   rez_160x120 <= '0'; 
   rez_320x240 <= '0'; 

   -- [SYNC FIX] 동기 신호 지연 프로세스
   process(clk_vga)
   begin
      if rising_edge(clk_vga) then
          -- 1 Stage Delay
          hSync_d1 <= hSync_int;
          vSync_d1 <= vSync_int;
          active_d1 <= nBlank;
          
          -- 2 Stage Delay (여기가 최종 사용)
          hSync_d2 <= hSync_d1;
          vSync_d2 <= vSync_d1;
          active_d2 <= active_d1;
      end if;
   end process;

   clk_gen : clocking port map (CLK_100 => CLK100, CLK_50 => CLK_camera, CLK_25 => CLK_vga);
   
   -- VGA는 원본 신호를 생성
   Inst_VGA: VGA PORT MAP(CLK25=>clk_vga, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, Hsync=>hSync_int, Vsync=>vSync_int, Nblank=>nBlank, Nsync=>nsync, activeArea=>activeArea);
   
   Inst_debounce: debounce PORT MAP(clk=>clk_vga, i=>btnc, o=>resend);
   Inst_ov7670_controller: ov7670_controller PORT MAP(clk=>clk_camera, resend=>resend, config_finished=>config_finished, sioc=>ov7670_sioc, siod=>ov7670_siod, reset=>ov7670_reset, pwdn=>ov7670_pwdn, xclk=>ov7670_xclk);
   Inst_frame_buffer: frame_buffer PORT MAP(addrb=>rdaddress, clkb=>clk_vga, doutb=>rddata, clka=>ov7670_pclk, addra=>wraddress, dina=>wrdata, wea=>wren);
   Inst_ov7670_capture: ov7670_capture PORT MAP(pclk=>ov7670_pclk, sw=>sw, btn_up=>btnr, btn_down=>btnl, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, vsync=>ov7670_vsync, href=>ov7670_href, d=>ov7670_data, addr=>wraddress, dout=>wrdata, we=>wren(0), x_center=>center_x, y_center=>center_y);
   
   -- [SYNC FIX] Address Generator는 지연되지 않은 원본 activeArea 사용 (메모리 미리 읽기)
   Inst_Address_Generator: Address_Generator PORT MAP(CLK25=>clk_vga, rez_160x120=>rez_160x120, rez_320x240=>rez_320x240, enable=>activeArea, vsync=>vSync_int, address=>rdaddress);

   -- [SYNC FIX] RGB 모듈은 2클럭 지연된 신호(_d2) 사용 (메모리 데이터 도착 시점과 동기화)
   Inst_RGB: RGB PORT MAP(
        Din => rddata, 
        Nblank => active_d2, -- 지연된 신호
        CLK => clk_vga, 
        Hsync => hSync_d2,   -- 지연된 신호
        Vsync => vSync_d2,   -- 지연된 신호
        x_center => center_x, 
        y_center => center_y,
        target_x => target_x_in, 
        target_y => target_y_in,
        msg_code => msg_code_in,
        R => red, 
        G => green, 
        B => blue
    );
end Behavioral;