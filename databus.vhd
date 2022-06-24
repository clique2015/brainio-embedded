--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    databus.vhd
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
use IEEE.numeric_std.all;

entity databus is

port(
  data, timer_data_in, pc, portA_out, portB_out  : in  unsigned(15 downto 0);
  lifo_in, fifo_in, ioREAD, io_data_in, interrupt: in  unsigned(15 downto 0);
  alu_out, fifo_out, lifo_out     			       : in  unsigned(15 downto 0);
  regA_sel, data_sel                             : in  unsigned(3 downto 0);  
  DATAOUT1, regA                                 : out unsigned(15 downto 0));
 
end entity;

architecture structure of databus is

		
begin

    process(data_sel, data, timer_data_in,
	 io_data_in, lifo_in, fifo_in, ioREAD, pc, 
	  alu_out, fifo_out, lifo_out)
    begin
        case data_sel is
				when "0000"  => DATAOUT1 <= data;
				when "0001"  => DATAOUT1 <= timer_data_in;
				when "0010"  => DATAOUT1 <= io_data_in;
				when "0011"  => DATAOUT1 <= lifo_in;
				when "0100"  => DATAOUT1 <= fifo_in;
				when "0101"  => DATAOUT1 <= ioREAD;
				when "0110"  => DATAOUT1 <= pc;
				when "0111"  => DATAOUT1 <= interrupt;
				when "1000"  => DATAOUT1 <= portA_out;				
				when "1001"  => DATAOUT1 <= portB_out;
				when "1010"  => DATAOUT1 <= alu_out;
				when "1011"  => DATAOUT1 <= fifo_out;
				when "1100"  => DATAOUT1 <= lifo_out;				
            when others      => null ;
        end case;
    end process;

    process(regA_sel, data, timer_data_in,
	 io_data_in, lifo_in, fifo_in, ioREAD, pc, 
	 alu_out, fifo_out, lifo_out)
    begin
        case regA_sel is
				when "0000"  => regA <= data;
				when "0001"  => regA <= timer_data_in;
				when "0010"  => regA <= io_data_in;
				when "0011"  => regA <= lifo_in;
				when "0100"  => regA <= fifo_in;
				when "0101"  => regA <= ioREAD;
				when "0110"  => regA <= pc;
				when "0111"  => regA <= interrupt;
				when "1000"  => regA <= portA_out;				
				when "1001"  => regA <= portB_out;
				when "1010"  => regA <= alu_out;
				when "1011"  => regA <= fifo_out;
				when "1100"  => regA <= lifo_out;	
            when others      => null ;
        end case;
    end process;

end structure;