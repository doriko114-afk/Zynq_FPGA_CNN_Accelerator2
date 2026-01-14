library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RGB is
    Port ( Din         : in  STD_LOGIC_VECTOR (11 downto 0);
           Nblank      : in  STD_LOGIC;
           CLK         : in  STD_LOGIC;
           Hsync       : in  STD_LOGIC;
           Vsync       : in  STD_LOGIC;
           msg_code    : in  STD_LOGIC_VECTOR(2 downto 0);
           sw          : in  STD_LOGIC_VECTOR(3 downto 0);
           debug_pixel : in STD_LOGIC;
           score_c, score_t, score_s : in STD_LOGIC_VECTOR(31 downto 0);
           R,G,B       : out STD_LOGIC_VECTOR (7 downto 0);
           target_x    : in  STD_LOGIC_VECTOR(9 downto 0); 
           target_y    : in  STD_LOGIC_VECTOR(9 downto 0);
           x_center, y_center : in STD_LOGIC_VECTOR(9 downto 0));
end RGB;

architecture Behavioral of RGB is
    signal x_cnt, y_cnt : integer range 0 to 1023 := 0;
    signal t_x, t_y : integer range 0 to 1023;

    function get_font_pixel(char_code : integer; row : integer; col : integer) return std_logic is
        variable line_data : std_logic_vector(7 downto 0);
    begin
        case char_code is
            when 13 => line_data:=x"00"; 
            when 20 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"18"; when 2=>line_data:=x"18"; when 3=>line_data:=x"18"; when 4=>line_data:=x"18"; when 5=>line_data:=x"18"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; 
            when 22 => case row is when 0=>line_data:=x"3C"; when 1=>line_data:=x"42"; when 2=>line_data:=x"42"; when 3=>line_data:=x"42"; when 4=>line_data:=x"42"; when 5=>line_data:=x"42"; when 6=>line_data:=x"3C"; when others=>line_data:=x"00"; end case; 
            when 29 => case row is when 0=>line_data:=x"42"; when 1=>line_data:=x"42"; when 2=>line_data:=x"5A"; when 3=>line_data:=x"5A"; when 4=>line_data:=x"66"; when 5=>line_data:=x"42"; when 6=>line_data:=x"42"; when others=>line_data:=x"00"; end case; 
            when others => line_data := x"00";
        end case;
        return line_data(7 - col);
    end function;

begin
    process(CLK) begin
        if rising_edge(CLK) then
            if Nblank='1' then x_cnt <= x_cnt+1; else x_cnt<=0; end if;
            if Vsync='0' then y_cnt<=0; elsif (x_cnt=639 and Nblank='1') then y_cnt<=y_cnt+1; end if;
        end if;
    end process;

    t_x <= to_integer(unsigned(target_x));
    t_y <= to_integer(unsigned(target_y));
    
    process(CLK)
        variable char_to_draw : integer;
        variable bit_on_text : std_logic;
        variable bit_on_label : std_logic;
        variable b_min_x, b_max_x, b_min_y, b_max_y : integer;
        variable l_min_x, l_min_y : integer;
        
        constant TEXT_SCALE    : integer := 14;  
        constant TEXT_SIZE     : integer := 112; 
        constant TEXT_START_X  : integer := 500; 
        constant TEXT_START_Y  : integer := 180; 
        
        constant DBG_WIDTH     : integer := 112; 
        constant DBG_START_X   : integer := 500; 
        constant DBG_START_Y   : integer := 50;

        constant LABEL_SCALE   : integer := 4;   
        constant LABEL_SIZE    : integer := 32;  

    begin
        if rising_edge(CLK) then
            if Nblank = '1' then
                
                -- [수정됨] y가 맨 아래줄이거나, x가 왼쪽 5픽셀(0~4)이면 무조건 검정색 출력
                if y_cnt = 479 or x_cnt < 5 then
                    R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
                else
                    bit_on_text := '0';
                    bit_on_label := '0';
                    
                    if sw(2) = '1' then
                        if (x_cnt >= TEXT_START_X and x_cnt < TEXT_START_X + TEXT_SIZE) and
                           (y_cnt >= TEXT_START_Y and y_cnt < TEXT_START_Y + TEXT_SIZE) then
                             if msg_code = "001" then char_to_draw := 22;    
                             elsif msg_code = "010" then char_to_draw := 29; 
                             elsif msg_code = "011" then char_to_draw := 20; 
                             else char_to_draw := 13; end if;
                             bit_on_text := get_font_pixel(char_to_draw, (y_cnt - TEXT_START_Y)/TEXT_SCALE, (x_cnt - TEXT_START_X)/TEXT_SCALE);
                        end if;
                    end if;

                    b_min_x := t_x - 56; if b_min_x < 0 then b_min_x := 0; end if;
                    b_max_x := t_x + 56; if b_max_x > 639 then b_max_x := 639; end if;
                    b_min_y := t_y - 56; if b_min_y < 0 then b_min_y := 0; end if;
                    b_max_y := t_y + 56; if b_max_y > 479 then b_max_y := 479; end if;

                    if sw(2) = '1' then
                        l_min_x := b_min_x; 
                        l_min_y := b_min_y - LABEL_SIZE;
                        if l_min_y < 0 then l_min_y := b_min_y; end if; 

                        if (x_cnt >= l_min_x and x_cnt < l_min_x + LABEL_SIZE) and
                           (y_cnt >= l_min_y and y_cnt < l_min_y + LABEL_SIZE) then
                             if msg_code = "001" then char_to_draw := 22;    
                             elsif msg_code = "010" then char_to_draw := 29; 
                             elsif msg_code = "011" then char_to_draw := 20; 
                             else char_to_draw := 13; end if;
                             bit_on_label := get_font_pixel(char_to_draw, (y_cnt - l_min_y)/LABEL_SCALE, (x_cnt - l_min_x)/LABEL_SCALE);
                        end if;
                    end if;

                    if bit_on_text = '1' then 
                        R <= x"00"; G <= x"FF"; B <= x"00";
                    elsif bit_on_label = '1' then
                        R <= x"FF"; G <= x"00"; B <= x"00";
                    elsif (
                          ((x_cnt = DBG_START_X or x_cnt = DBG_START_X + DBG_WIDTH - 1) and (y_cnt >= DBG_START_Y and y_cnt < DBG_START_Y + DBG_WIDTH)) or
                          ((y_cnt = DBG_START_Y or y_cnt = DBG_START_Y + DBG_WIDTH - 1) and (x_cnt >= DBG_START_X and x_cnt < DBG_START_X + DBG_WIDTH))
                          ) then
                        R <= x"FF"; G <= x"00"; B <= x"00"; 
                    elsif (sw(3) = '1' and 
                           (x_cnt >= DBG_START_X and x_cnt < DBG_START_X + DBG_WIDTH) and 
                           (y_cnt >= DBG_START_Y and y_cnt < DBG_START_Y + DBG_WIDTH) and
                           debug_pixel = '1') then
                        R <= x"FF"; G <= x"00"; B <= x"FF";
                    else
                        if ((x_cnt >= b_min_x and x_cnt <= b_max_x) and (y_cnt >= b_min_y and y_cnt <= b_max_y)) and
                           ((x_cnt < b_min_x + 2 or x_cnt > b_max_x - 2) or (y_cnt < b_min_y + 2 or y_cnt > b_max_y - 2)) then
                            R <= x"00"; G <= x"FF"; B <= x"00"; 
                        else
                            R <= Din(11 downto 8) & Din(11 downto 8);
                            G <= Din(7 downto 4)  & Din(7 downto 4);
                            B <= Din(3 downto 0)  & Din(3 downto 0);
                        end if;
                    end if;
                end if;
            else
                R <= (others => '0'); G <= (others => '0'); B <= (others => '0');
            end if;
        end if;
    end process;
end Behavioral;