--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    Last-In-First-out (stack) LIFO.vhd
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

entity lifo is

port(
  CLK, RESET, PUSH_LIFO, POP_LIFO        : in  std_logic ;
  LIFO_IN                                : in  std_logic_vector(15 downto 0);
  LIFO_FULL, LIFO_EMPTY                  : out std_logic;
  LIFO_OUT                               : out std_logic_vector(15 downto 0));
 
end entity;

architecture structure of lifo is
	signal reg5, reg6, reg7                    : std_logic_vector(15 downto 0);
	signal reg0, reg1, reg2, reg3, reg4        : std_logic_vector(15 downto 0);
	signal Addr_reg                            : std_logic_vector(2 downto 0);
	signal full, empty                         : std_logic;
		
begin

    process(Addr_reg)
    begin
        case Addr_reg is
				when "000" => LIFO_OUT <= reg0;
				when "001" => LIFO_OUT <= reg1;
				when "010" => LIFO_OUT <= reg2;
				when "011" => LIFO_OUT <= reg3;
				when "100" => LIFO_OUT <= reg4;
				when "101" => LIFO_OUT <= reg5;
				when "110" => LIFO_OUT <= reg6;
				when "111" => LIFO_OUT <= reg7;
            when others      => null ;
        end case;
    end process;

	
	process (CLK, RESET)
   begin
        if (reset = '1') then
            reg0 <= x"0000";
            reg1 <= x"0000";				
	         reg2 <= x"0000";			
            reg3 <= x"0000";
				reg4 <= x"0000";
            reg5 <= x"0000";				
	         reg6 <= x"0000";			
            reg7 <= x"0000";	
				
        elsif (CLK'event and CLK = '1') then 
			if (PUSH_LIFO = '1') then
				case Addr_reg is
					when "000" => reg0 <= LIFO_IN;
					when "001" => reg1 <= LIFO_IN;
					when "010" => reg2 <= LIFO_IN;
					when "011" => reg3 <= LIFO_IN;
					when "100" => reg4 <= LIFO_IN;
					when "101" => reg5 <= LIFO_IN;
					when "110" => reg6 <= LIFO_IN;
					when "111" => reg7 <= LIFO_IN;
					when others      => null ;
        end case;
	end if;
	
			if (PUSH_LIFO = '1') then
				if (full = '0') then	
				Addr_reg <= Addr_reg + 1;
			end if;
			end if;
	
			if (POP_LIFO = '1') then
				if (empty = '0') then	
				Addr_reg <= Addr_reg - 1;
			end if;
			end if;	
				
  end if;
  end process;
	 
	empty <= '1' when Addr_reg = "000" else '0';
	full  <= '1' when Addr_reg = "111" else '0';
	
	LIFO_EMPTY <=	empty;
	LIFO_FULL  <=	full;
	
end structure;