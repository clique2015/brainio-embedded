--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    Modified Stack Ram - Data_memory.vhd
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

entity data_memory is

  generic (
    addr_width : integer := 8;
    data_width : integer := 16 
  );

	port(
	  CLK, RESET, RAM_CS    : in  std_logic ;
	  RAM_SEL               : in  unsigned(1 downto 0);	  
	  RAM_ADDR              : in  unsigned(addr_width-1 downto 0);
	  RAM_DATA_IN           : in  unsigned(15 downto 0);
	  FULL		 			   : out std_logic;
	  RAM_DATA_OUT          : out unsigned(15 downto 0));

end entity;

architecture structure of data_memory is

type ram_type is array (2**addr_width-1 downto 0) of unsigned (data_width-1 downto 0);
signal ram_single_port : ram_type;

signal peek, man_sel, pop, push, push_ram, pop_ram, sig_full, sig_empty: std_logic;
signal addr_reg, addr : unsigned(7 downto 0);

begin

    process(RAM_SEL)
    begin
        if(RAM_SEL = "00") then
            peek  <= '1';
			else
				peek  <= '0';
			end if;
			
        if(RAM_SEL = "01") then
            man_sel  <= '1';
			else
				man_sel  <= '0';
			end if;

        if(RAM_SEL = "10") then
            pop  <= '1';
			else
				pop  <= '0';
			end if;			

        if(RAM_SEL = "11") then
            push  <= '1';
			else
				push  <= '0';
			end if;	
    end process;

    process(peek)
    begin
        if(peek = '1') then
            addr <= RAM_ADDR;
	     else
				 addr <= addr_reg;
        end if;
    end process;

    process(addr_reg)
    begin
        if(addr_reg = x"00") then
            sig_empty <= '1';
	     elsif(addr_reg = x"1f") then
				 sig_full <= '1';
        end if;
    end process;
	 
	 
	push_ram  <= push and not sig_full; 
	pop_ram   <= pop and not sig_empty;

	process (CLK, RESET)
   begin
	  if (reset = '1') then
			addr_reg <= (others => '0');
	  elsif (CLK'event and CLK = '1') then 
			if (man_sel = '1') then
				addr_reg <= RAM_ADDR;
				
			elsif (pop_ram = '1') then
				addr_reg <= addr_reg - 1;
				
			elsif (push_ram = '1') then
				addr_reg <= addr_reg + 1;
			end if;
			
        if RAM_CS = '1' then
            ram_single_port(to_integer(unsigned(addr))) <= RAM_DATA_IN;
			end if;
	 end if;
  end process;
	FULL 			<= sig_full;
	RAM_DATA_OUT<= ram_single_port(to_integer(unsigned(addr)));
	
end structure;