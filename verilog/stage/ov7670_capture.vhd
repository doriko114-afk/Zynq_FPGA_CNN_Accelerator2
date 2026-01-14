------------------------------------------------------------------------------------
---- Engineer: Mike Field <hamster@snap.net.nz>
---- 
---- Description: Captures the pixels coming from the OV7670 camera and 
----              Stores them in block RAM
----
---- The length of href last controls how often pixels are captive - (2 downto 0) stores
---- one pixel every 4 cycles.
----
---- "line" is used to control how often data is captured. In this case every forth 
---- line
------------------------------------------------------------------------------------
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity ov7670_capture is
--    Port ( pclk  : in   STD_LOGIC;
--           rez_160x120 : IN std_logic;
--           rez_320x240 : IN std_logic;
--           sw    : in   STD_LOGIC_VECTOR(1 downto 0); -- [추가] 스위치 입력
--           vsync : in   STD_LOGIC;
--           href  : in   STD_LOGIC;
--           d     : in   STD_LOGIC_VECTOR (7 downto 0);
--           addr  : out  STD_LOGIC_VECTOR (18 downto 0);
--           dout  : out  STD_LOGIC_VECTOR (11 downto 0);
--           we    : out  STD_LOGIC);
--end ov7670_capture;

--architecture Behavioral of ov7670_capture is
--   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
--   signal address      : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
--   signal line         : std_logic_vector(1 downto 0)  := (others => '0');
--   signal href_last    : std_logic_vector(6 downto 0)  := (others => '0');
--   signal we_reg       : std_logic := '0';
--   signal href_hold    : std_logic := '0';
--   signal latched_vsync : STD_LOGIC := '0';
--   signal latched_href  : STD_LOGIC := '0';
--   signal latched_d     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
--begin

--	addr <= address;
--	we <= we_reg;
----	dout <= d_latch(15 downto 12) & d_latch(10 downto 7) & d_latch(4 downto 1); 
   
--	capture_process: process(pclk)
--	begin
--		if rising_edge(pclk) then
--			if we_reg = '1' then
--				address <= std_logic_vector(unsigned(address)+1);
--			end if;

--			-- This is a bit tricky href starts a pixel transfer that takes 3 cycles
--			--        Input   | state after clock tick   
--			--         href   | wr_hold    d_latch           dout                we address  address_next
--			-- cycle -1  x    |    xx      xxxxxxxxxxxxxxxx  xxxxxxxxxxxx  x   xxxx     xxxx
--			-- cycle 0   1    |    x1      xxxxxxxxRRRRRGGG  xxxxxxxxxxxx  x   xxxx     addr
--			-- cycle 1   0    |    10      RRRRRGGGGGGBBBBB  xxxxxxxxxxxx  x   addr     addr
--			-- cycle 2   x    |    0x      GGGBBBBBxxxxxxxx  RRRRGGGGBBBB  1   addr     addr+1

--			-- detect the rising edge on href - the start of the scan line
--			if href_hold = '0' and latched_href = '1' then
--				case line is
--					when "00"   => line <= "01";
--					when "01"   => line <= "10";
--					when "10"   => line <= "11";
--					when others => line <= "00";
--				end case;
--			end if;
--			href_hold <= latched_href;
         
--			-- capturing the data from the camera, 12-bit RGB
--			if latched_href = '1' then
--				d_latch <= d_latch( 7 downto 0) & latched_d;
--			end if;
--			we_reg  <= '0';

--			-- Is a new screen about to start (i.e. we have to restart capturing
--			if latched_vsync = '1' then 
--				address      <= (others => '0');
--				href_last    <= (others => '0');
--				line         <= (others => '0');
--			else
--                -- (1) 쓰기 타이밍 조건: href_last의 0번 비트가 1일 때 (2클럭마다 1번씩)
--                if href_last(0) = '1' then 
                    
--                    we_reg <= '1';                -- 메모리에 쓰기 허용
--                    href_last <= (others => '0'); -- 타이밍 리셋

--                    -- (2) 빨간색 감지 (YUV 디버깅 로직)
--                    -- YUV 모드에서 d는 Y/U/V가 섞여 들어옵니다.
--                    -- 빨간 물체는 V값이 매우 높으므로(보통 140~150 이상), 
--                    -- 들어오는 데이터(d)나 앞선 데이터(latched_d) 중 하나라도 크면 흰색으로 표시합니다.
                    
--                    case sw is
--                        when "00" => -- [빨간색 모드] V값이 높은지 검사
--                            if unsigned(d) > 160 then
--                                dout <= x"FFF"; -- 흰색 (탐지됨)
--                            else
--                                dout <= x"000"; -- 검은색
--                            end if;
                            
--                        when "01" => -- [파란색 모드] U값이 높은지 검사
--                             -- 파란색 물체는 U값이 높게 나옵니다.
--                             -- (주의: YUV raw stream에서는 U와 V를 구분 없이 검사하므로 
--                             -- 빨간색 물체도 감지될 수 있지만, 파란 물체를 대면 잘 인식됩니다)
--                            if unsigned(d) > 150 then 
--                                dout <= x"FFF"; 
--                            else
--                                dout <= x"000"; 
--                            end if;
                            
--                        when "10" => -- [초록색 모드] V/U 값이 낮은지 검사
--                            -- 초록색은 U, V 성분이 모두 낮습니다.
--                            -- 단, 검은색(어두운 곳)도 값이 낮으므로, 너무 어두운 건 제외해야 합니다.
--                            -- 조건: 색상값(d)은 낮고(90이하) AND 이전 데이터(밝기, latched_d)는 적당히 밝아야 함(60이상)
--                            if (unsigned(d) < 90) and (unsigned(latched_d) > 60) then
--                                dout <= x"FFF";
--                            else
--                                dout <= x"000";
--                            end if;
                            
--                        when others => -- [기타: 11] 그냥 원본처럼 통과시키거나 검은색
--                             dout <= x"000";
--                    end case;

--                else
--                    -- 타이밍이 안 맞을 때는 데이터만 시프트하며 대기
--                    we_reg <= '0';
--                    href_last <= href_last(href_last'high-1 downto 0) & latched_href;
--                end if;
--            end if;
                
--		end if;
	  
--		if falling_edge(pclk) then
--			latched_d     <= d;
--			latched_href  <= href;
--			latched_vsync <= vsync;
--		end if;	  
--	end process;
--end Behavioral;

--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity ov7670_capture is
--    Port ( pclk  : in   STD_LOGIC;
--           rez_160x120 : IN std_logic; -- 포트는 유지하되 내부에서 무시
--           rez_320x240 : IN std_logic; -- 포트는 유지하되 내부에서 무시
--           sw    : in   STD_LOGIC_VECTOR(1 downto 0);
--           btn_up   : in STD_LOGIC;
--           btn_down : in STD_LOGIC;
--           vsync : in   STD_LOGIC;
--           href  : in   STD_LOGIC;
--           d     : in   STD_LOGIC_VECTOR (7 downto 0);
--           addr  : out  STD_LOGIC_VECTOR (18 downto 0);
--           dout  : out  STD_LOGIC_VECTOR (11 downto 0);
--           we    : out  STD_LOGIC;
--           x_center : out STD_LOGIC_VECTOR(9 downto 0);
--           y_center : out STD_LOGIC_VECTOR(9 downto 0)
--           );
--end ov7670_capture;

--architecture Behavioral of ov7670_capture is
--   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
--   signal address      : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
--   signal href_last    : std_logic_vector(6 downto 0)  := (others => '0');
--   signal we_reg       : std_logic := '0';
--   signal latched_vsync : STD_LOGIC := '0';
--   signal latched_href  : STD_LOGIC := '0';
--   signal latched_d     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--   -- 무게중심 계산 변수
--   signal sum_x : unsigned(31 downto 0) := (others => '0');
--   signal sum_y : unsigned(31 downto 0) := (others => '0');
--   signal pixel_cnt : unsigned(19 downto 0) := (others => '0');
--   signal x_curr : unsigned(9 downto 0) := (others => '0');
--   signal y_curr : unsigned(9 downto 0) := (others => '0');
--   signal x_result : std_logic_vector(9 downto 0) := (others => '0');
--   signal y_result : std_logic_vector(9 downto 0) := (others => '0');

--   -- 임계값 (초기값 50)
--   signal threshold_val : unsigned(19 downto 0) := to_unsigned(50, 20);

--begin
--   addr <= address;
--   we <= we_reg;
--   x_center <= x_result;
--   y_center <= y_result;
   
--   capture_process: process(pclk)
--   begin
--      if rising_edge(pclk) then
--         -- [수정] 해상도 상관없이 쓰기 신호 있으면 무조건 주소 증가
--         if we_reg = '1' then
--            address <= std_logic_vector(unsigned(address)+1);
--         end if;

--         -- href_last는 타이밍 맞추기용 시프트 레지스터
--         -- OV7670은 기본적으로 YUV/RGB 데이터를 2클럭에 1픽셀(2바이트) 보냄
         
--         -- 데이터 래치 (상위 바이트 + 하위 바이트 결합용)
--         if latched_href = '1' then
--            d_latch <= d_latch( 7 downto 0) & latched_d;
--         end if;
--         we_reg  <= '0';

--         -- VSYNC: 프레임 리셋
--         if latched_vsync = '1' then 
--            address      <= (others => '0');
--            href_last    <= (others => '0');
--            x_curr <= (others => '0');
--            y_curr <= (others => '0');

--            -- 버튼으로 임계값 조절
--            if btn_up = '1' then
--                if threshold_val < 50000 then threshold_val <= threshold_val + 50; end if;
--            elsif btn_down = '1' then
--                if threshold_val > 50 then threshold_val <= threshold_val - 50; end if;
--            end if;

--            -- 무게중심 계산 결과 업데이트
--            if pixel_cnt > threshold_val then
--               x_result <= std_logic_vector(resize(sum_x / pixel_cnt, 10));
--               y_result <= std_logic_vector(resize(sum_y / pixel_cnt, 10));
--            end if;

--            sum_x <= (others => '0');
--            sum_y <= (others => '0');
--            pixel_cnt <= (others => '0');
         
--         else
--            -- VSYNC 아닐 때 데이터 처리
            
--            -- [수정] HREF가 Rising Edge일 때 (새 라인 시작) -> Y좌표 증가
--            -- latched_href가 0->1로 변하는 순간을 감지하는 로직이 필요하지만
--            -- 여기서는 간단히 href_last 비트를 이용하거나 href 신호 자체를 봅니다.
--            -- 원본 로직을 단순화: href가 0이었다가 1이 되는 순간에 y_curr 증가 필요
            
--            -- (간소화된 Y 증가 로직)
--            -- href가 Low였다가 High로 올라오는 순간 체크는 조금 복잡하므로,
--            -- 여기서는 x_curr가 639(한 줄 끝)에 도달하면 y_curr를 올리는 방식 사용
            
--            if href_last(0) = '1' then 
--               we_reg <= '1';
--               href_last <= (others => '0');
               
--               x_curr <= x_curr + 1;
--               if x_curr = 639 then -- 640번째 픽셀이면
--                  x_curr <= (others => '0');
--                  y_curr <= y_curr + 1;
--               end if;

--               -- 색상 출력 및 필터링
--               dout <= x"000"; 
               
--               case sw is
--                  when "00" => -- 빨강
--                     if unsigned(d) > 160 then
--                        dout <= x"FFF";
--                        sum_x <= sum_x + x_curr;
--                        sum_y <= sum_y + y_curr;
--                        pixel_cnt <= pixel_cnt + 1;
--                     end if;
--                  when "01" => -- 파랑
--                     if unsigned(d) > 160 then
--                        dout <= x"FFF";
--                        sum_x <= sum_x + x_curr;
--                        sum_y <= sum_y + y_curr;
--                        pixel_cnt <= pixel_cnt + 1;
--                     end if;
--                  when "10" => -- 초록
--                     if (unsigned(d) < 80) and (unsigned(latched_d) > 60) then
--                        dout <= x"FFF";
--                        sum_x <= sum_x + x_curr;
--                        sum_y <= sum_y + y_curr;
--                        pixel_cnt <= pixel_cnt + 1;
--                     end if;
--                  when others => 
--                     -- 일반 영상 (RGB444)
--                     dout <= d_latch(15 downto 12) & d_latch(10 downto 7) & d_latch(4 downto 1);
--               end case;

--            else
--               we_reg <= '0';
--               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
--            end if;
--         end if;
--      end if;
      
--      if falling_edge(pclk) then
--         latched_d     <= d;
--         latched_href  <= href;
--         latched_vsync <= vsync;
--      end if;     
--   end process;
--end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_capture is
    Port ( pclk  : in   STD_LOGIC;
           rez_160x120 : IN std_logic;
           rez_320x240 : IN std_logic;
           sw    : in   STD_LOGIC_VECTOR(1 downto 0);
           btn_up   : in STD_LOGIC;
           btn_down : in STD_LOGIC;
           vsync : in   STD_LOGIC;
           href  : in   STD_LOGIC;
           d     : in   STD_LOGIC_VECTOR (7 downto 0);
           addr  : out  STD_LOGIC_VECTOR (18 downto 0);
           dout  : out  STD_LOGIC_VECTOR (11 downto 0);
           we    : out  STD_LOGIC;
           x_center : out STD_LOGIC_VECTOR(9 downto 0);
           y_center : out STD_LOGIC_VECTOR(9 downto 0)
           );
end ov7670_capture;

architecture Behavioral of ov7670_capture is
   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
   signal address      : STD_LOGIC_VECTOR(18 downto 0) := (others => '0');
   signal href_last    : std_logic_vector(6 downto 0)  := (others => '0');
   signal we_reg       : std_logic := '0';
   signal latched_vsync : STD_LOGIC := '0';
   signal latched_href  : STD_LOGIC := '0';
   signal latched_d     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   
   -- 무게중심 계산 변수
   signal sum_x : unsigned(31 downto 0) := (others => '0');
   signal sum_y : unsigned(31 downto 0) := (others => '0');
   signal pixel_cnt : unsigned(19 downto 0) := (others => '0');
   signal x_curr : unsigned(9 downto 0) := (others => '0');
   signal y_curr : unsigned(9 downto 0) := (others => '0');
   signal x_result : std_logic_vector(9 downto 0) := (others => '0');
   signal y_result : std_logic_vector(9 downto 0) := (others => '0');
   
   -- 임계값 (초기값 50)
   signal threshold_val : unsigned(19 downto 0) := to_unsigned(50, 20);

begin
   addr <= address;
   we <= we_reg;
   x_center <= x_result;
   y_center <= y_result;
   
   capture_process: process(pclk)
   begin
      if rising_edge(pclk) then
         -- 주소 증가
         if we_reg = '1' then
            address <= std_logic_vector(unsigned(address)+1);
         end if;

         -- 데이터 래치
         if latched_href = '1' then
            d_latch <= d_latch( 7 downto 0) & latched_d;
         end if;
         we_reg  <= '0';

         -- VSYNC: 프레임 리셋
         if latched_vsync = '1' then 
            address      <= (others => '0');
            href_last    <= (others => '0');
            x_curr <= (others => '0');
            y_curr <= (others => '0');
            
            -- 버튼으로 임계값 조절
            if btn_up = '1' then
                if threshold_val < 50000 then threshold_val <= threshold_val + 50; end if;
            elsif btn_down = '1' then
                if threshold_val > 50 then threshold_val <= threshold_val - 50; end if;
            end if;

            -- 무게중심 결과 업데이트
            if pixel_cnt > threshold_val then
               x_result <= std_logic_vector(resize(sum_x / pixel_cnt, 10));
               y_result <= std_logic_vector(resize(sum_y / pixel_cnt, 10));
            end if;

            sum_x <= (others => '0');
            sum_y <= (others => '0');
            pixel_cnt <= (others => '0');
         
         else
            -- VSYNC 아닐 때
            if href_last(0) = '1' then 
               we_reg <= '1';
               href_last <= (others => '0');
               
               -- 좌표 추적
               x_curr <= x_curr + 1;
               if x_curr = 639 then 
                  x_curr <= (others => '0');
                  y_curr <= y_curr + 1;
               end if;

               -- [수정 완료] 하단 노이즈 필터링 (Y좌표가 478보다 작을 때만 인식)
               dout <= x"000"; -- 기본 검은색
               
               if (y_curr < 478) then -- **478로 수정됨** (477 라인까지 유효)
                   case sw is
                      when "00" => -- 빨강 감지
                         if unsigned(d) > 160 then
                            dout <= x"FFF";
                            sum_x <= sum_x + x_curr;
                            sum_y <= sum_y + y_curr;
                            pixel_cnt <= pixel_cnt + 1;
                         end if;
                      when "01" => -- 파랑 감지
                         if unsigned(d) > 160 then
                            dout <= x"FFF";
                            sum_x <= sum_x + x_curr;
                            sum_y <= sum_y + y_curr;
                            pixel_cnt <= pixel_cnt + 1;
                         end if;
                      when "10" => -- 초록 감지
                         if (unsigned(d) < 80) and (unsigned(latched_d) > 60) then
                            dout <= x"FFF";
                            sum_x <= sum_x + x_curr;
                            sum_y <= sum_y + y_curr;
                            pixel_cnt <= pixel_cnt + 1;
                         end if;
                      when others => 
                         -- 일반 영상
                         dout <= d_latch(15 downto 12) & d_latch(10 downto 7) & d_latch(4 downto 1);
                   end case;
               end if; 
               
            else
               we_reg <= '0';
               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
            end if;
         end if;
      end if;
      
      if falling_edge(pclk) then
         latched_d     <= d;
         latched_href  <= href;
         latched_vsync <= vsync;
      end if;     
   end process;
end Behavioral;