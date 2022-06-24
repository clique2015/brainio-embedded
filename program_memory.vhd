--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    Modified Stack Ram - program_memory.vhd
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

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity programMemory is

  generic (
    addr_width : integer := 16;
    data_width : integer := 16 
  );

port(
  CLK, WE, rst, data_sig: in  std_logic ;
  PC,IN_DATA,LOAD_ADDR  : in  unsigned(addr_width-1 downto 0);
  DATA_OUT, DATA_reg    : out unsigned(data_width-1 downto 0));
end entity;

architecture structure of programMemory is

type ram_type is array (2**addr_width-1 downto 0) of unsigned (data_width-1 downto 0);
signal ram_single_port : ram_type;
SIGNAL dataout : unsigned(15 downto 0);	
begin
	process (CLK)
   begin			
		if (rst = '1') then 			
			DATA_reg <= x"0000";
		elsif (CLK'event and CLK = '1') then 
		
        if WE = '1' then
			ram_single_port(to_integer(unsigned(LOAD_ADDR))) <= IN_DATA;
			end if;
						
			if (data_sig = '1')  then 			
				DATA_reg <= dataout;
			end if;
		end if;
  end process;			
			dataout <= ram_single_port(to_integer(unsigned(PC)));	
			DATA_OUT  <= dataout;
end structure;