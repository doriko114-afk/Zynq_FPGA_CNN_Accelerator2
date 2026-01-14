library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_capture is
    Port ( pclk        : in    STD_LOGIC;
           rez_160x120 : IN std_logic;
           rez_320x240 : IN std_logic;
           sw          : in    STD_LOGIC_VECTOR(1 downto 0); 
           
           -- 임계값 조절용 버튼 포트
           btn_up      : in STD_LOGIC; -- 임계값 증가
           btn_down    : in STD_LOGIC; -- 임계값 감소
           btn_reset   : in STD_LOGIC; -- 임계값 초기화
           
           vsync       : in    STD_LOGIC;
           href        : in    STD_LOGIC;
           d           : in    STD_LOGIC_VECTOR (7 downto 0);
           addr        : out   STD_LOGIC_VECTOR (18 downto 0);
           dout        : out   STD_LOGIC_VECTOR (11 downto 0);
           we          : out   STD_LOGIC;
           x_center    : out STD_LOGIC_VECTOR(9 downto 0);
           y_center    : out STD_LOGIC_VECTOR(9 downto 0)
           );
end ov7670_capture;

architecture Behavioral of ov7670_capture is
   signal d_latch         : std_logic_vector(15 downto 0) := (others => '0');
   signal address         : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
   signal href_last       : std_logic_vector(6 downto 0)  := (others => '0');
   signal we_reg          : std_logic := '0';
   signal latched_vsync   : STD_LOGIC := '0';
   signal latched_href    : STD_LOGIC := '0';
   signal latched_d       : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

   signal sum_x : unsigned(31 downto 0) := (others => '0');
   signal sum_y : unsigned(31 downto 0) := (others => '0');
   signal pixel_cnt : unsigned(19 downto 0) := (others => '0');
   signal x_curr : unsigned(9 downto 0) := (others => '0');
   signal y_curr : unsigned(9 downto 0) := (others => '0');
   signal x_result : std_logic_vector(9 downto 0) := (others => '0');
   signal y_result : std_logic_vector(9 downto 0) := (others => '0');

   -- 초기 임계값 (120 유지)
   signal threshold_val : unsigned(7 downto 0) := to_unsigned(120, 8); 
   
   -- Gap Filler
   signal prev_pixel_detected : std_logic := '0';

   -- 버튼 채터링 방지용
   signal btn_up_prev   : std_logic := '0';
   signal btn_down_prev : std_logic := '0';

begin
   addr <= address;
   we <= we_reg;
   x_center <= x_result;
   y_center <= y_result;
   
   capture_process: process(pclk)
      variable temp_x : integer;
      variable temp_y : integer;
      variable is_object : std_logic;
   begin
      if rising_edge(pclk) then
         if we_reg = '1' then
            address <= std_logic_vector(unsigned(address)+1);
         end if;

         if latched_href = '1' then
            d_latch <= d_latch( 7 downto 0) & latched_d;
         end if;
         we_reg  <= '0';

         if latched_vsync = '1' then 
            address       <= (others => '0');
            href_last     <= (others => '0');
            x_curr <= (others => '0');
            y_curr <= (others => '0');
            prev_pixel_detected <= '0';

            -- 버튼 로직
            if btn_reset = '1' then
                threshold_val <= to_unsigned(120, 8); 
            elsif (btn_up = '1' and btn_up_prev = '0') then
                if threshold_val < 250 then threshold_val <= threshold_val + 5; end if;
            elsif (btn_down = '1' and btn_down_prev = '0') then
                if threshold_val > 10 then threshold_val <= threshold_val - 5; end if;
            end if;
            
            btn_up_prev   <= btn_up;
            btn_down_prev <= btn_down;

            if pixel_cnt > 50 then 
               temp_x := to_integer(sum_x / pixel_cnt);
               temp_y := to_integer(sum_y / pixel_cnt);

               -- 좌표 안정화 (범위 제한)
               if temp_x < 56 then temp_x := 56; end if;
               if temp_x > 583 then temp_x := 583; end if;
               if temp_y < 56 then temp_y := 56; end if;
               if temp_y > 423 then temp_y := 423; end if;

               x_result <= std_logic_vector(to_unsigned(temp_x, 10));
               y_result <= std_logic_vector(to_unsigned(temp_y, 10));
            end if;

            sum_x <= (others => '0'); sum_y <= (others => '0'); pixel_cnt <= (others => '0');
         else
            if href_last(0) = '1' then 
               we_reg <= '1';
               href_last <= (others => '0');
               
               x_curr <= x_curr + 1;
               if x_curr = 639 then 
                  x_curr <= (others => '0'); y_curr <= y_curr + 1;
                  prev_pixel_detected <= '0';
               end if;

               -- [핵심 수정] Dead Zone (인식 제외 구역) 설정
               -- 1. y_curr < 478 : 하단 2픽셀 제외 (기존)
               -- 2. x_curr >= 5  : 왼쪽 5픽셀 제외 (흰색 줄 노이즈 제거)
               -- 3. x_curr < 590 : 오른쪽 50픽셀 제외 (UI 영역 및 노이즈 제거, 640-50=590)
               
               is_object := '0';
               
               if (y_curr < 478) and (x_curr >= 5) and (x_curr < 590) then
                   
                   -- 반전 로직 (<) 유지
                   if (unsigned(d) < threshold_val) or (unsigned(latched_d) < threshold_val) or (prev_pixel_detected = '1') then
                       
                       if (unsigned(d) < threshold_val) or (unsigned(latched_d) < threshold_val) then
                           is_object := '1';
                           prev_pixel_detected <= '1'; 
                       elsif (prev_pixel_detected = '1') then
                           is_object := '1';
                           prev_pixel_detected <= '0';
                       else
                           is_object := '0';
                           prev_pixel_detected <= '0';
                       end if;
                   else
                       is_object := '0';
                       prev_pixel_detected <= '0';
                   end if;
               else
                   -- Dead Zone 영역은 무조건 배경(검은색) 처리
                   is_object := '0';
                   prev_pixel_detected <= '0';
               end if;

               if is_object = '1' then
                  dout <= x"FFF"; -- 물체 (흰색)
                  sum_x <= sum_x + x_curr; -- 여기서 좌표가 누적되는데, Dead Zone은 제외됨
                  sum_y <= sum_y + y_curr;
                  pixel_cnt <= pixel_cnt + 1;
               else
                  dout <= x"000"; -- 배경 (검은색)
               end if;

            else
               we_reg <= '0';
               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
            end if;
         end if;
      end if;
      if falling_edge(pclk) then
         latched_d <= d; latched_href <= href; latched_vsync <= vsync;
      end if;      
   end process;
end Behavioral;