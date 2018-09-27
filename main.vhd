----------------------------------------------------------------------------------
-- University: Politecnico di Milano
-- Authors: Luca Terracciano, Manuel Trivilino
-- 
-- Create Date: 27.02.2018 10:44:45
-- Module Name: project_reti_logiche - Behavioral
--
-- Description: This is the VHDL code for a chip that, given an image represented 
-- as a matrix and composed by a subject and a background computes the maximum area
-- in which the subject is contained excluding the background.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC ;
           i_start : in STD_LOGIC ;
           i_rst : in STD_LOGIC ;
           i_data : in STD_LOGIC_VECTOR (7 downto 0) ;
           o_address : out STD_LOGIC_VECTOR (15 downto 0) ;
           o_done : out STD_LOGIC ;
           o_en : out STD_LOGIC ;
           o_we : out STD_LOGIC ;
           o_data : out STD_LOGIC_VECTOR (7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is ( INIT, RESET,START, T1,COLUMN_S,T2, LINES_S, T3, TRESHOLD_S, T4, CONTENT_NSEW, CONTENT_SIGNAL, AREA_DIFFERENCE, AREA_PRODUCT, RESULT_FIRST, RESULT_SECOND, DONE);
    signal next_state : state_type := INIT;
    signal current_state: state_type := INIT;
    signal column, lines, treshold, north , east: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal south, west : STD_LOGIC_VECTOR( 7 downto 0) := (others => '1');
    signal column_counter_c : UNSIGNED(7 downto 0) := "00000001";
    signal column_counter_n : UNSIGNED(7 downto 0) := "00000010";
    signal in_address_current: UNSIGNED(15 downto 0) := "0000000000000011";
    signal in_address_next: UNSIGNED(15 downto 0) := "0000000000000110";
    signal o_data_product : STD_LOGIC_VECTOR( 15 downto 0) := (others => '0');
    signal stop_reading : STD_LOGIC := '0';

    begin

    -- state_sequence : Updates the state of the FSM implemented at every clock cycle
    state_sequence: process(i_clk)
    begin
        if rising_edge(i_clk) then
            current_state <= next_state;
        end if;
    end process;

    -- lambda : Given the FSM current state and reading the transistion signals computes the next state 

    lambda: process( i_clk, stop_reading, current_state, i_start, i_rst)
    begin
        if falling_edge(i_clk) then
            case current_state is
                when INIT =>
                	if i_rst = '1' then
                    	next_state <= RESET;
                    end if;
                when RESET =>  
                    if i_start = '1' then
                        next_state <= START;
                    end if;
                when START =>
                    next_state <= T1;
                when T1 =>
                    next_state <= COLUMN_S;
                when COLUMN_S =>
                    next_state <= T2;
                when T2 =>
                    next_state <= LINES_S;
                when LINES_S =>
                    next_state <= T3;
                when T3 =>
                    next_state <= TRESHOLD_S;
                when TRESHOLD_S =>
                    next_state <= T4;
                WHEN T4 =>
                    next_state <= CONTENT_NSEW;
                when CONTENT_NSEW => 
                    next_state <= CONTENT_SIGNAL;
                when CONTENT_SIGNAL =>
                    if (stop_reading = '1') then
                        next_state <= AREA_DIFFERENCE;
                    else
                        next_state <= CONTENT_NSEW;
                    end if;
                when AREA_DIFFERENCE =>
                    next_state <= AREA_PRODUCT;
                when AREA_PRODUCT =>
                    next_state <= RESULT_FIRST;    
                when RESULT_FIRST =>
                    next_state <= RESULT_SECOND;
                when RESULT_SECOND =>
                    next_state <= DONE;
                when DONE => 
                    next_state <= RESET;
            end case;
        end if;
    end process;

    -- main process : Contains the operations that must be done in a specific FSM state
    MAIN_PROCESS : process(i_clk , current_state, i_data, in_address_current, column_counter_n, treshold, north, lines, west, column_counter_c, south, east , in_address_next, column, o_data_product
    )
    begin
    if falling_edge(i_clk) then
        case current_state is
        
            -- init : initialize circuit
            when INIT =>
                stop_reading <= '0';

            -- reset : After receiving the reset signal wait for the start signal

            when RESET =>
            
                o_done <= '0';
                o_en <= '0';
                o_we <= '0';
                column <= "00000000";
                treshold <= "00000000";
                lines <= "00000000";
                north <= "00000000";
                west <= "11111111";
                south <= "11111111";
                east <= "00000000";
                o_address <= "0000000000000000";
            
            -- start : enable o_en in order to begin memory reading

            when START =>
                o_en <= '1';

            -- t1 : reading column dimension
            when T1 =>
                o_address <= "0000000000000010";       

            when COLUMN_S =>
                column <= i_data;

            -- t2 : reading lines dimension
            when T2 =>
                o_address <= "0000000000000011";

            when LINES_S =>
                lines <= i_data;      

            -- t3 : reading treshold
            when T3 =>
                o_address <= "0000000000000100";
               
            when TRESHOLD_S => 
                treshold <= i_data;       
            
            -- t4 : reading first image cell
            when T4 =>
                o_address <= "0000000000000101";
               
            -- content_nsew : update edges of the image. Every value lower than the treshold value
            --                is the image background
            when CONTENT_NSEW =>
        

                if (UNSIGNED(i_data) >= UNSIGNED(treshold) ) then
                    if( UNSIGNED(north) < UNSIGNED(lines)) then
                    north  <= lines; 
                    end if;

                    if( UNSIGNED(south) > UNSIGNED(lines)) then
                        south <= lines;
                    end if;

                    
                    if( UNSIGNED(west) > column_counter_n - 1) then
                        west <= STD_LOGIC_VECTOR(column_counter_n - 1);
                    end if;

                    if( UNSIGNED(east) < column_counter_n -1) then
                        east <= STD_LOGIC_VECTOR(column_counter_n -1);
                    end if;
                end if;

                column_counter_c <= column_counter_n;
                
                in_address_current <= in_address_next;

            -- content_signal : preparing the next memory reading.    
            when CONTENT_SIGNAL =>
        
        
                in_address_next <= in_address_current + 1;
                o_address <= STD_LOGIC_VECTOR( in_address_current);

                
                if (column_counter_c > UNSIGNED(column) or column_counter_c = "00000000") then
                    if ( lines = "00000001") then
                        stop_reading <= '1';
                        o_en <= '0';
                    else
                        column_counter_c <= "00000001";
                        column_counter_n <= "00000010";
                        lines <= STD_LOGIC_VECTOR(UNSIGNED(lines) - 1);
                    end if;
                else
                    column_counter_n <= column_counter_c + 1;
                end if ;

            -- area_difference : compute the rectangle shape
            when AREA_DIFFERENCE =>
                if north >= south then
                    lines <= STD_LOGIC_VECTOR(UNSIGNED(north) - UNSIGNED(south) + 1);
                else
                    lines <= (others => '0');
                end if;
                if east >= west then
                    column <= STD_LOGIC_VECTOR(UNSIGNED(east) - UNSIGNED(west) + 1);
                else 
                    column <= (others => '0'); 
                end if;
                
            
            -- area_product : compute the area
            when AREA_PRODUCT =>
                o_data_product <= STD_LOGIC_VECTOR(UNSIGNED(column) * UNSIGNED(lines));
          
            
            when RESULT_FIRST =>
            
            --split 1
                o_data <= (0 => o_data_product(0) ,1 => o_data_product(1) ,2 => o_data_product(2) ,3 => o_data_product(3) ,4 => o_data_product(4) ,5 => o_data_product(5) ,6 => o_data_product(6) ,7 => o_data_product(7) );
                o_en <= '1';
                o_we <= '1';
                o_address <= "0000000000000000";       
            
            
        
            when RESULT_SECOND =>

                --split 2
                o_data <= (7 => o_data_product(15), 6 => o_data_product(14), 5 => o_data_product(13),4 => o_data_product(12),3 => o_data_product(11),2 => o_data_product(10),1 => o_data_product(9),0 => o_data_product(8) );
                    
                o_address <= "0000000000000001";       
                    
            when DONE =>
                o_we <= '0';
                o_en <= '0';
                o_done <= '1';
            end case;
        end if;
    end process;



end Behavioral;
