--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    timer.vhd
--------------------------------------------------------------------------------
-- AUTHORS: Ezeuko Emmanuel <ezeuko.arinze@projectfpga.com>
--------------------------------------------------------------------------------
-- WEBSITE: https://projectfpga.com/iosoc
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- BrainIO
--------------------------------------------------------------------------------
-- Copyright (C) 2020 projectfpga.com
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity timer is

port(
  CLK, RESET         : in  std_logic ;
  Timer_data_in      : in  std_logic_vector(15 downto 0);
  timer_cs           : in  std_logic_vector(1 downto 0);
  TON                : out std_logic);
 
end entity;

architecture structure of timer is
	signal datain_reg, counter_reg    : std_logic_vector(15 downto 0);
	signal up_down_count, down_count  : std_logic;
	signal down_compare, up_compare   : std_logic;
	signal downcount_select, upcount_select, up_count : std_logic;
	
		
begin

	
	up_compare      <= '1' when datain_reg  = counter_reg else '0';
	down_compare    <= '1' when counter_reg = x"0001"     else '0';
	up_count        <= upcount_select   AND  up_compare ;
	down_count      <= downcount_select AND  down_compare;
	up_down_count   <= up_count OR   down_count ;
	
	process (CLK, RESET)
   begin
        if (reset = '1') then
            datain_reg  <= x"0000";
            counter_reg <= x"0000";				
	         downcount_select    <= '0';			
            upcount_select      <= '0';	
				
        elsif (CLK'event and CLK = '1') then 
			   if (timer_cs(0) = '1') then 
					datain_reg <= Timer_data_in;
					
					if (timer_cs(1) = '0') then
						counter_reg <= x"0000";
						upcount_select      <= '1';
						
					elsif (timer_cs(1) = '1') then 
						counter_reg  <= Timer_data_in;
						downcount_select     <= '1';
						
					end if;							
					end if;	
				
				if (up_down_count = '1') then 
					upcount_select    <= '0';
					downcount_select  <= '0';
				end if;
				
				if (downcount_select = '1') then 
					counter_reg    <= counter_reg - 1;
				elsif (upcount_select = '1') then  
					counter_reg    <= counter_reg + 1;				
				end if;	
				end if;		
				
  end process;
  TON <= downcount_select OR upcount_select;
	
end structure;