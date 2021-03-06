
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
constant c_CLOCK_PERIOD		: time := 15 ns;
signal   tb_done		: std_logic;
signal   mem_address		: std_logic_vector (15 downto 0) := (others => '0');
signal   tb_rst		    : std_logic := '0';
signal   tb_start		: std_logic := '0';
signal   tb_clk		    : std_logic := '0';
signal   mem_o_data,mem_i_data		: std_logic_vector (7 downto 0);
signal   enable_wire  		: std_logic;
signal   mem_we		: std_logic;

type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);



signal RAM: ram_type := (2 => std_logic_vector(to_unsigned( 205 , 8)),
                         3 => std_logic_vector(to_unsigned( 153 , 8)),
                         4 => std_logic_vector(to_unsigned( 36 , 8)),
                         
  18995  => std_logic_vector(to_unsigned( 46 , 8)), 
-- PosX= 131  PosY= 92  --
  19538  => std_logic_vector(to_unsigned( 131 , 8)), 
 -- PosX= 59  PosY= 95  --
  9873  => std_logic_vector(to_unsigned( 70 , 8)), 
 -- PosX= 29  PosY= 48  --
  29982  => std_logic_vector(to_unsigned( 116 , 8)), 
 -- PosX= 48  PosY= 146  --
  29465  => std_logic_vector(to_unsigned( 86 , 8)), 
 -- PosX= 146  PosY= 143  --
 -- MaxX= 146  MinX= 29 --
 -- MaxY= 146  MinY= 48 --
  1381  => std_logic_vector(to_unsigned( 33 , 8)), 
  909  => std_logic_vector(to_unsigned( 21 , 8)), 
  2562  => std_logic_vector(to_unsigned( 11 , 8)), 
 others => (others =>'0'));

component project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data       : in  std_logic_vector(7 downto 0); --1 byte
      o_address     : out std_logic_vector(15 downto 0); --16 bit addr: max size is 255*255 + 3 more for max x and y and thresh.
      o_done            : out std_logic;
      o_en         : out std_logic;
      o_we       : out std_logic;
      o_data            : out std_logic_vector (7 downto 0)
      );
end component project_reti_logiche;


begin
UUT: project_reti_logiche
port map (
          i_clk      	=> tb_clk,
          i_start       => tb_start,
          i_rst      	=> tb_rst,
          i_data    	=> mem_o_data,
          o_address  	=> mem_address,
          o_done      	=> tb_done,
          o_en   	=> enable_wire,
          o_we 	=> mem_we,
          o_data    => mem_i_data
          );

p_CLK_GEN : process is
begin
wait for c_CLOCK_PERIOD/2;
tb_clk <= not tb_clk;
end process p_CLK_GEN;


MEM : process(tb_clk)
begin
    if tb_clk'event and tb_clk = '1' then
        if enable_wire = '1' then
            if mem_we = '1' then
                RAM(conv_integer(mem_address))              <= mem_i_data;
                mem_o_data                      <= mem_i_data;
            else
                mem_o_data <= RAM(conv_integer(mem_address));
            end if;
        end if;
    end if;
end process;


test : process is
begin 
    wait for 100 ns;
    wait for c_CLOCK_PERIOD;
    tb_rst <= '1';
    wait for c_CLOCK_PERIOD;
    tb_rst <= '0';
    wait for c_CLOCK_PERIOD;
    tb_start <= '1';
    wait for c_CLOCK_PERIOD;
    tb_start <= '0';
    wait until tb_done = '1';
    wait until tb_done = '0';
    wait until rising_edge(tb_clk);

    -- area =  11682 
    assert RAM(1) = std_logic_vector(to_unsigned( 45 , 8)) report "FAIL high bits" severity failure;
    assert RAM(0) = std_logic_vector(to_unsigned( 162 , 8)) report "FAIL low bits" severity failure;


    assert false report "Simulation Ended!, test passed" severity failure;
end process test;

end projecttb; 
