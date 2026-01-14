--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

--entity RGB is
--    Port ( Din      : in  STD_LOGIC_VECTOR (11 downto 0);
--           Nblank   : in  STD_LOGIC;
--           CLK      : in  STD_LOGIC;
--           Hsync    : in  STD_LOGIC;
--           Vsync    : in  STD_LOGIC;
--           x_center : in  STD_LOGIC_VECTOR(9 downto 0);
--           y_center : in  STD_LOGIC_VECTOR(9 downto 0);
--           target_x : in  STD_LOGIC_VECTOR(9 downto 0);
--           target_y : in  STD_LOGIC_VECTOR(9 downto 0);
           
--           -- [NEW] 메시지 코드 입력 (0:None, 1:Success)
--           msg_code : in  STD_LOGIC_VECTOR(2 downto 0);
           
--           R,G,B    : out STD_LOGIC_VECTOR (7 downto 0));
--end RGB;

--architecture Behavioral of RGB is
--    signal x_cnt, y_cnt : integer range 0 to 1023 := 0;
--    constant MARKER_SIZE : integer := 10; 
    
--    signal xc_int, yc_int : integer range 0 to 1023;
--    signal dx_100, dx_10, dx_1 : integer range 0 to 9;
--    signal dy_100, dy_10, dy_1 : integer range 0 to 9;

--    signal xt_int, yt_int : integer range 0 to 1023;
--    signal tx_100, tx_10, tx_1 : integer range 0 to 9;
--    signal ty_100, ty_10, ty_1 : integer range 0 to 9;

--    -- 폰트 함수
--    function get_font_pixel(char_code : integer; row : integer; col : integer) return std_logic is
--        variable line_data : std_logic_vector(7 downto 0);
--    begin
--        case char_code is
--            when 0 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 1 => case row is when 0=>line_data:=x"08"; when 1=>line_data:=x"18"; when 2=>line_data:=x"28"; when 3=>line_data:=x"08"; when 4=>line_data:=x"08"; when 5=>line_data:=x"08"; when 6=>line_data:=x"3E"; when others=>line_data:=x"00"; end case;
--            when 2 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"02"; when 3=>line_data:=x"0C"; when 4=>line_data:=x"30"; when 5=>line_data:=x"40"; when 6=>line_data:=x"7E"; when others=>line_data:=x"00"; end case;
--            when 3 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"02"; when 3=>line_data:=x"1C"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 4 => case row is when 0=>line_data:=x"0C"; when 1=>line_data:=x"14"; when 2=>line_data:=x"24"; when 3=>line_data:=x"44"; when 4=>line_data:=x"7E"; when 5=>line_data:=x"04"; when 6=>line_data:=x"04"; when others=>line_data:=x"00"; end case;
--            when 5 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"02"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 6 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 7 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"02"; when 2=>line_data:=x"04"; when 3=>line_data:=x"08"; when 4=>line_data:=x"10"; when 5=>line_data:=x"10"; when 6=>line_data:=x"10"; when others=>line_data:=x"00"; end case;
--            when 8 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"3C"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 9 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"3E"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
--            when 10 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"24"; when 2=>line_data:=x"18"; when 3=>line_data:=x"18"; when 4=>line_data:=x"24"; when 5=>line_data:=x"42"; when 6=>line_data:=x"00"; when others=>line_data:=x"00"; end case; -- X
--            when 11 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"42"; when 2=>line_data:=x"24"; when 3=>line_data:=x"18"; when 4=>line_data:=x"10"; when 5=>line_data:=x"10"; when 6=>line_data:=x"10"; when others=>line_data:=x"00"; end case; -- Y
--            when 12 => case row is when 2=>line_data:=x"18"; when 4=>line_data:=x"18"; when others=>line_data:=x"00"; end case; -- :
--            when 14 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"18"; when 2=>line_data:=x"18"; when 3=>line_data:=x"18"; when 4=>line_data:=x"18"; when 5=>line_data:=x"18"; when 6=>line_data:=x"18"; when others=>line_data:=x"00"; end case; -- T
--            when 15 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"3C"; when 3=>line_data:=x"02"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- S
--            when 16 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"42"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- U
--            when 17 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"40"; when 3=>line_data:=x"40"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- C
--            when 18 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"40"; when 4=>line_data:=x"7E"; when others=>line_data:=x"00"; end case; -- E
--            when others => line_data := x"00";
--        end case;
--        return line_data(7 - col);
--    end function;

--begin
--    -- 좌표 변환
--    xc_int <= to_integer(unsigned(x_center)); 
--    yc_int <= to_integer(unsigned(y_center));
--    xt_int <= to_integer(unsigned(target_x)); 
--    yt_int <= to_integer(unsigned(target_y)); 

--    -- 자릿수 분리
--    dx_100 <= xc_int/100; dx_10 <= (xc_int/10) mod 10; dx_1 <= xc_int mod 10;
--    dy_100 <= yc_int/100; dy_10 <= (yc_int/10) mod 10; dy_1 <= yc_int mod 10;
--    tx_100 <= xt_int/100; tx_10 <= (xt_int/10) mod 10; tx_1 <= xt_int mod 10;
--    ty_100 <= yt_int/100; ty_10 <= (yt_int/10) mod 10; ty_1 <= yt_int mod 10;

--    -- 카운터
--    process(CLK) begin
--        if rising_edge(CLK) then
--            if Nblank='1' then x_cnt <= x_cnt+1; else x_cnt<=0; end if;
--            if Vsync='0' then y_cnt<=0; elsif (x_cnt=639 and Nblank='1') then y_cnt<=y_cnt+1; end if;
--        end if;
--    end process;

--    -- 픽셀 출력
--    process(CLK)
--        variable char_to_draw : integer;
--        variable text_x_start : integer := 510;
--        variable text_y_suc   : integer := 50;  
--        variable x_rel, y_rel, slot, grid_slot : integer;
--        variable bit_on_green, bit_on_red, bit_on_blue, bit_on_white : std_logic;
--    begin
--        if rising_edge(CLK) then
--            if Nblank = '1' then
--                bit_on_green := '0'; bit_on_red := '0'; bit_on_blue := '0'; bit_on_white := '0';

--                -- 1. 현재 좌표 (Green)
--                if (y_cnt >= 20 and y_cnt < 28) and (x_cnt >= 510 and x_cnt < 598) then
--                    x_rel := x_cnt - 510; y_rel := y_cnt - 20; slot := x_rel / 8;     
--                    case slot is
--                        when 0=>char_to_draw:=10; when 1=>char_to_draw:=12; when 2=>char_to_draw:=dx_100; when 3=>char_to_draw:=dx_10; when 4=>char_to_draw:=dx_1;
--                        when 5=>char_to_draw:=13; when 6=>char_to_draw:=11; when 7=>char_to_draw:=12; when 8=>char_to_draw:=dy_100; when 9=>char_to_draw:=dy_10; when 10=>char_to_draw:=dy_1;
--                        when others=>char_to_draw:=13;
--                    end case;
--                    bit_on_green := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
--                end if;

--                -- 2. 목표 좌표 (Red)
--                if (y_cnt >= 32 and y_cnt < 40) and (x_cnt >= 502 and x_cnt < 614) then
--                    x_rel := x_cnt - 502; y_rel := y_cnt - 32; slot := x_rel / 8;     
--                    case slot is
--                        when 0=>char_to_draw:=14; when 1=>char_to_draw:=10; when 2=>char_to_draw:=12; 
--                        when 3=>char_to_draw:=tx_100; when 4=>char_to_draw:=tx_10; when 5=>char_to_draw:=tx_1;
--                        when 6=>char_to_draw:=13; 
--                        when 7=>char_to_draw:=14; when 8=>char_to_draw:=11; when 9=>char_to_draw:=12; 
--                        when 10=>char_to_draw:=ty_100; when 11=>char_to_draw:=ty_10; when 12=>char_to_draw:=ty_1;
--                        when others=>char_to_draw:=13;
--                    end case;
--                    bit_on_red := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
--                end if;

--                -- 3. SUCCESS 메시지 (Blue) - msg_code가 1일 때만 표시
--                if (msg_code = "001") then 
--                    if (y_cnt >= text_y_suc and y_cnt < text_y_suc + 8) and (x_cnt >= 510 and x_cnt < 566) then
--                        x_rel := x_cnt - 510; y_rel := y_cnt - text_y_suc; slot := x_rel / 8;
--                        case slot is
--                            when 0|5|6 => char_to_draw := 15; -- S
--                            when 1 => char_to_draw := 16; -- U
--                            when 2|3 => char_to_draw := 17; -- C
--                            when 4 => char_to_draw := 18; -- E
--                            when others => char_to_draw := 13;
--                        end case;
--                        bit_on_blue := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
--                    end if;
--                end if;

--                -- 4. 그리드 숫자 (White) - 복구됨
--                if (y_cnt >= 10 and y_cnt < 18) then
--                    if (x_cnt>=162 and x_cnt<186) then x_rel:=x_cnt-162; if x_rel/8=0 then char_to_draw:=1; elsif x_rel/8=1 then char_to_draw:=6; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
--                    elsif (x_cnt>=322 and x_cnt<346) then x_rel:=x_cnt-322; if x_rel/8=0 then char_to_draw:=3; elsif x_rel/8=1 then char_to_draw:=2; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
--                    elsif (x_cnt>=482 and x_cnt<506) then x_rel:=x_cnt-482; if x_rel/8=0 then char_to_draw:=4; elsif x_rel/8=1 then char_to_draw:=8; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
--                    end if;
--                elsif (x_cnt >= 10 and x_cnt < 34) then
--                    if (y_cnt>=122 and y_cnt<130) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=1; elsif x_rel/8=1 then char_to_draw:=2; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-122,x_rel mod 8);
--                    elsif (y_cnt>=242 and y_cnt<250) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=2; elsif x_rel/8=1 then char_to_draw:=4; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-242,x_rel mod 8);
--                    elsif (y_cnt>=362 and y_cnt<370) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=3; elsif x_rel/8=1 then char_to_draw:=6; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-362,x_rel mod 8);
--                    end if;
--                end if;

--                -- [출력 우선순위]
--                if bit_on_blue = '1' then R<=x"00"; G<=x"FF"; B<=x"FF"; -- SUCCESS
--                elsif bit_on_red = '1' then R<=x"FF"; G<=x"00"; B<=x"00"; -- TARGET TEXT
--                elsif bit_on_white = '1' then R<=x"FF"; G<=x"FF"; B<=x"FF"; -- GRID NUM
--                elsif bit_on_green = '1' then R<=x"00"; G<=x"FF"; B<=x"00"; -- CURRENT TEXT
                
--                -- 타겟 박스 (성공시 CYAN, 아니면 RED)
--                elsif ( abs(x_cnt - xt_int) < MARKER_SIZE and abs(y_cnt - yt_int) < MARKER_SIZE ) and
--                      ( abs(x_cnt - xt_int) > (MARKER_SIZE-2) or abs(y_cnt - yt_int) > (MARKER_SIZE-2) ) then
--                    if msg_code = "001" then R<=x"00"; G<=x"FF"; B<=x"FF"; else R<=x"FF"; G<=x"00"; B<=x"00"; end if;
                
--                -- 십자가
--                elsif ( (abs(x_cnt - xc_int) < 2) and (abs(y_cnt - yc_int) < MARKER_SIZE) ) or
--                      ( (abs(y_cnt - yc_int) < 2) and (abs(x_cnt - xc_int) < MARKER_SIZE) ) then
--                    R<=x"00"; G<=x"FF"; B<=x"00";
                
--                -- 그리드 선
--                elsif (x_cnt=160 or x_cnt=320 or x_cnt=480 or y_cnt=120 or y_cnt=240 or y_cnt=360) then
--                    R<=x"FF"; G<=x"FF"; B<=x"00";
                
--                -- 영상
--                else
--                    R <= Din(11 downto 8) & Din(11 downto 8);
--                    G <= Din(7 downto 4)  & Din(7 downto 4);
--                    B <= Din(3 downto 0)  & Din(3 downto 0);
--                end if;
--            else
--                R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
--            end if;
--        end if;
--    end process;
--end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RGB is
    Port ( Din      : in  STD_LOGIC_VECTOR (11 downto 0);
           Nblank   : in  STD_LOGIC;
           CLK      : in  STD_LOGIC;
           Hsync    : in  STD_LOGIC;
           Vsync    : in  STD_LOGIC;
           x_center : in  STD_LOGIC_VECTOR(9 downto 0);
           y_center : in  STD_LOGIC_VECTOR(9 downto 0);
           target_x : in  STD_LOGIC_VECTOR(9 downto 0);
           target_y : in  STD_LOGIC_VECTOR(9 downto 0);
           msg_code : in  STD_LOGIC_VECTOR(2 downto 0);
           R,G,B    : out STD_LOGIC_VECTOR (7 downto 0));
end RGB;

architecture Behavioral of RGB is
    signal x_cnt, y_cnt : integer range 0 to 1023 := 0;
    constant MARKER_SIZE : integer := 10; 
    
    signal xc_int, yc_int : integer range 0 to 1023;
    signal dx_100, dx_10, dx_1 : integer range 0 to 9;
    signal dy_100, dy_10, dy_1 : integer range 0 to 9;
    signal xt_int, yt_int : integer range 0 to 1023;
    signal tx_100, tx_10, tx_1 : integer range 0 to 9;
    signal ty_100, ty_10, ty_1 : integer range 0 to 9;

    function get_font_pixel(char_code : integer; row : integer; col : integer) return std_logic is
        variable line_data : std_logic_vector(7 downto 0);
    begin
        case char_code is
            when 0 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 1 => case row is when 0=>line_data:=x"08"; when 1=>line_data:=x"18"; when 2=>line_data:=x"28"; when 3=>line_data:=x"08"; when 4=>line_data:=x"08"; when 5=>line_data:=x"08"; when 6=>line_data:=x"3E"; when others=>line_data:=x"00"; end case;
            when 2 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"02"; when 3=>line_data:=x"0C"; when 4=>line_data:=x"30"; when 5=>line_data:=x"40"; when 6=>line_data:=x"7E"; when others=>line_data:=x"00"; end case;
            when 3 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"02"; when 3=>line_data:=x"1C"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 4 => case row is when 0=>line_data:=x"0C"; when 1=>line_data:=x"14"; when 2=>line_data:=x"24"; when 3=>line_data:=x"44"; when 4=>line_data:=x"7E"; when 5=>line_data:=x"04"; when 6=>line_data:=x"04"; when others=>line_data:=x"00"; end case;
            when 5 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"02"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 6 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 7 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"02"; when 2=>line_data:=x"04"; when 3=>line_data:=x"08"; when 4=>line_data:=x"10"; when 5=>line_data:=x"10"; when 6=>line_data:=x"10"; when others=>line_data:=x"00"; end case;
            when 8 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"3C"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 9 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"3E"; when 4=>line_data:=x"02"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case;
            when 10 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"24"; when 2=>line_data:=x"18"; when 3=>line_data:=x"18"; when 4=>line_data:=x"24"; when 5=>line_data:=x"42"; when 6=>line_data:=x"00"; when others=>line_data:=x"00"; end case; -- X
            when 11 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"42"; when 2=>line_data:=x"24"; when 3=>line_data:=x"18"; when 4=>line_data:=x"10"; when 5=>line_data:=x"10"; when 6=>line_data:=x"10"; when others=>line_data:=x"00"; end case; -- Y
            when 12 => case row is when 2=>line_data:=x"18"; when 4=>line_data:=x"18"; when others=>line_data:=x"00"; end case; -- :
            when 14 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"18"; when 2=>line_data:=x"18"; when 3=>line_data:=x"18"; when 4=>line_data:=x"18"; when 5=>line_data:=x"18"; when 6=>line_data:=x"18"; when others=>line_data:=x"00"; end case; -- T
            when 15 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"3C"; when 3=>line_data:=x"02"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- S
            when 16 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"42"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- U
            when 17 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"40"; when 2=>line_data:=x"40"; when 3=>line_data:=x"40"; when 4=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; -- C
            when 18 => case row is when 0=>line_data:=x"7E"; when 1=>line_data:=x"40"; when 2=>line_data:=x"7C"; when 3=>line_data:=x"40"; when 4=>line_data:=x"7E"; when others=>line_data:=x"00"; end case; -- E
            when others => line_data := x"00";
        end case;
        return line_data(7 - col);
    end function;

begin
    xc_int <= to_integer(unsigned(x_center));
    yc_int <= to_integer(unsigned(y_center));
    xt_int <= to_integer(unsigned(target_x)); 
    yt_int <= to_integer(unsigned(target_y)); 

    dx_100 <= xc_int/100; dx_10 <= (xc_int/10) mod 10; dx_1 <= xc_int mod 10;
    dy_100 <= yc_int/100; dy_10 <= (yc_int/10) mod 10; dy_1 <= yc_int mod 10;
    tx_100 <= xt_int/100; tx_10 <= (xt_int/10) mod 10; tx_1 <= xt_int mod 10;
    ty_100 <= yt_int/100; ty_10 <= (yt_int/10) mod 10; ty_1 <= yt_int mod 10;

    process(CLK) begin
        if rising_edge(CLK) then
            if Nblank='1' then x_cnt <= x_cnt+1; else x_cnt<=0; end if;
            if Vsync='0' then y_cnt<=0; elsif (x_cnt=639 and Nblank='1') then y_cnt<=y_cnt+1; end if;
        end if;
    end process;

    process(CLK)
        variable char_to_draw : integer;
        variable text_y_suc   : integer := 50;
        variable x_rel, y_rel, slot : integer;
        variable bit_on_green, bit_on_red, bit_on_blue, bit_on_white : std_logic;
    begin
        if rising_edge(CLK) then
            if Nblank = '1' then
                bit_on_green := '0'; bit_on_red := '0'; bit_on_blue := '0'; bit_on_white := '0';

                -- 1. 현재 좌표 (Green)
                if (y_cnt >= 20 and y_cnt < 28) and (x_cnt >= 510 and x_cnt < 598) then
                    x_rel := x_cnt - 510; y_rel := y_cnt - 20; slot := x_rel / 8;
                    case slot is
                        when 0=>char_to_draw:=10; when 1=>char_to_draw:=12; when 2=>char_to_draw:=dx_100; when 3=>char_to_draw:=dx_10; when 4=>char_to_draw:=dx_1;
                        when 5=>char_to_draw:=13; when 6=>char_to_draw:=11; when 7=>char_to_draw:=12; when 8=>char_to_draw:=dy_100; when 9=>char_to_draw:=dy_10; when 10=>char_to_draw:=dy_1;
                        when others=>char_to_draw:=13;
                    end case;
                    bit_on_green := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
                end if;
                
                -- 2. 목표 좌표 (Red)
                if (y_cnt >= 32 and y_cnt < 40) and (x_cnt >= 502 and x_cnt < 614) then
                    x_rel := x_cnt - 502; y_rel := y_cnt - 32; slot := x_rel / 8;
                    case slot is
                        when 0=>char_to_draw:=14; when 1=>char_to_draw:=10; when 2=>char_to_draw:=12; 
                        when 3=>char_to_draw:=tx_100; when 4=>char_to_draw:=tx_10; when 5=>char_to_draw:=tx_1;
                        when 6=>char_to_draw:=13; 
                        when 7=>char_to_draw:=14; when 8=>char_to_draw:=11; when 9=>char_to_draw:=12; 
                        when 10=>char_to_draw:=ty_100; when 11=>char_to_draw:=ty_10; when 12=>char_to_draw:=ty_1;
                        when others=>char_to_draw:=13;
                    end case;
                    bit_on_red := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
                end if;
                
                -- 3. SUCCESS 메시지 (Blue)
                if (msg_code = "001") then 
                    if (y_cnt >= text_y_suc and y_cnt < text_y_suc + 8) and (x_cnt >= 510 and x_cnt < 566) then
                        x_rel := x_cnt - 510; y_rel := y_cnt - text_y_suc; slot := x_rel / 8;
                        case slot is
                            when 0|5|6 => char_to_draw := 15; -- S
                            when 1 => char_to_draw := 16; -- U
                            when 2|3 => char_to_draw := 17; -- C
                            when 4 => char_to_draw := 18; -- E
                            when others => char_to_draw := 13;
                        end case;
                        bit_on_blue := get_font_pixel(char_to_draw, y_rel, x_rel mod 8);
                    end if;
                end if;
                
                -- 4. 그리드 숫자 (White)
                if (y_cnt >= 10 and y_cnt < 18) then
                    if (x_cnt>=162 and x_cnt<186) then x_rel:=x_cnt-162; if x_rel/8=0 then char_to_draw:=1; elsif x_rel/8=1 then char_to_draw:=6; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
                    elsif (x_cnt>=322 and x_cnt<346) then x_rel:=x_cnt-322; if x_rel/8=0 then char_to_draw:=3; elsif x_rel/8=1 then char_to_draw:=2; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
                    elsif (x_cnt>=482 and x_cnt<506) then x_rel:=x_cnt-482; if x_rel/8=0 then char_to_draw:=4; elsif x_rel/8=1 then char_to_draw:=8; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-10,x_rel mod 8);
                    end if;
                elsif (x_cnt >= 10 and x_cnt < 34) then
                    if (y_cnt>=122 and y_cnt<130) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=1; elsif x_rel/8=1 then char_to_draw:=2; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-122,x_rel mod 8);
                    elsif (y_cnt>=242 and y_cnt<250) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=2; elsif x_rel/8=1 then char_to_draw:=4; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-242,x_rel mod 8);
                    elsif (y_cnt>=362 and y_cnt<370) then x_rel:=x_cnt-10; if x_rel/8=0 then char_to_draw:=3; elsif x_rel/8=1 then char_to_draw:=6; else char_to_draw:=0; end if; bit_on_white:=get_font_pixel(char_to_draw,y_cnt-362,x_rel mod 8);
                    end if;
                end if;

                -- [출력 우선순위]
                if bit_on_blue = '1' then R<=x"00"; G<=x"FF"; B<=x"FF"; -- SUCCESS
                elsif bit_on_red = '1' then R<=x"FF"; G<=x"00"; B<=x"00"; -- TARGET TEXT
                elsif bit_on_white = '1' then R<=x"FF"; G<=x"FF"; B<=x"FF"; -- GRID NUM
                elsif bit_on_green = '1' then R<=x"00"; G<=x"FF"; B<=x"00"; -- CURRENT TEXT
                
                -- 타겟 박스
                elsif ( abs(x_cnt - xt_int) < MARKER_SIZE and abs(y_cnt - yt_int) < MARKER_SIZE ) and
                      ( abs(x_cnt - xt_int) > (MARKER_SIZE-2) or abs(y_cnt - yt_int) > (MARKER_SIZE-2) ) then
                    if msg_code = "001" then R<=x"00"; G<=x"FF"; B<=x"FF"; else R<=x"FF"; G<=x"00"; B<=x"00"; end if;
                
                -- 십자가
                elsif ( (abs(x_cnt - xc_int) < 2) and (abs(y_cnt - yc_int) < MARKER_SIZE) ) or
                      ( (abs(y_cnt - yc_int) < 2) and (abs(x_cnt - xc_int) < MARKER_SIZE) ) then
                    R<=x"00"; G<=x"FF"; B<=x"00";
                
                -- 그리드 선
                elsif (x_cnt=160 or x_cnt=320 or x_cnt=480 or y_cnt=120 or y_cnt=240 or y_cnt=360) then
                    R<=x"FF"; G<=x"FF"; B<=x"00";
                
                -- 영상
                else
                    -- [VISUAL FIX] 상단 및 하단 노이즈 마스킹 (478로 수정됨)
                    if (y_cnt < 2) or (y_cnt > 478) then
                        R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
                    else
                        R <= Din(11 downto 8) & Din(11 downto 8);
                        G <= Din(7 downto 4)  & Din(7 downto 4);
                        B <= Din(3 downto 0)  & Din(3 downto 0);
                    end if;
                end if;
            else
                R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;