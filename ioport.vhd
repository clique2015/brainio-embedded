--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    IOPORT
--------------------------------------------------------------------------------
-- AUTHORS: Ezeuko Emmanuel <ezeuko.arinze@projectfpga.com>
--------------------------------------------------------------------------------
-- WEBSITE: https://projectfpga.com/iosoc
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


entity ioport is
	port (	
	 clk       : in  std_logic;
    reset     : in  std_logic;
    IO_CS     : in  unsigned(1 downto 0);
    READ_CS   : in  unsigned(1 downto 0);	 
    DATA_IN   : in  unsigned(15 downto 0);
	 IOREAD    : in  unsigned(15 downto 0);	 
	 PORTAOUT  : out unsigned(15 downto 0);
	 PORTBOUT  : out unsigned(15 downto 0);	 
	 
	 porta_io  : inout unsigned(7 downto 0);
	 portb_io  : inout unsigned(7 downto 0);
	 portc_io  : inout unsigned(7 downto 0);
    portd_io  : inout unsigned(7 downto 0));
	 
end entity;

architecture ioport_arch of ioport is
signal porta_ddr : unsigned(7 downto 0);
signal portb_ddr : unsigned(7 downto 0);
signal portc_ddr : unsigned(7 downto 0);
signal portd_ddr : unsigned(7 downto 0);

signal porta_data : unsigned(7 downto 0);
signal portb_data : unsigned(7 downto 0);
signal portc_data : unsigned(7 downto 0);
signal portd_data : unsigned(7 downto 0);

signal data_outa  : unsigned(7 downto 0);
signal data_outb  : unsigned(7 downto 0);
signal data_outc  : unsigned(7 downto 0);
signal data_outd  : unsigned(7 downto 0);

signal data_out1  : unsigned(15 downto 0);
signal data_out0  : unsigned(15 downto 0);
signal in_data    : unsigned(7 downto 0);
signal sel_data   : unsigned(7 downto 0);
signal calc       : unsigned(3 downto 0);

signal finala_data  : unsigned(7 downto 0);
signal finalb_data  : unsigned(7 downto 0);
signal finalc_data  : unsigned(7 downto 0);
signal finald_data  : unsigned(7 downto 0);
signal indata       : unsigned(7 downto 0);

begin
-----------------------------------------------------------		
-- SET PORT DIRECTION	
-----------------------------------------------------------
	process (clk, reset)
   begin
	  if (reset = '1') then			
		porta_ddr  <= "00000000";
		portb_ddr  <= "00000000";
		portc_ddr  <= "00000000";
		portd_ddr  <= "00000000";
	  elsif (CLK'event and CLK = '1') then 
		if (IO_CS = "11") then
			case DATA_IN(1 downto 0) is
			  when "00" =>
				 porta_ddr  <= DATA_IN(15 downto 8);
			  when "01" =>
				 portb_ddr  <= DATA_IN(15 downto 8);
			  when "10" =>
				 portc_ddr  <= DATA_IN(15 downto 8);
			  when "11" =>
				 portd_ddr  <= DATA_IN(15 downto 8);
			  when others =>
				 porta_ddr  <= porta_ddr;
				 portb_ddr  <= portb_ddr;
				 portc_ddr  <= portc_ddr;
				 portd_ddr  <= portd_ddr;
			end case;
		end if;	
	end if;
  end process;				
------------------------------------------------------------	
-- SET PORT DATA Registers	
------------------------------------------------------------
	process (clk, reset)
   begin
	  if (reset = '1') then			
      porta_data <= "00000000";
      portb_data <= "00000000";
      portc_data <= "00000000";
      portd_data <= "00000000";
	  elsif (CLK'event and CLK = '1') then 
		if (IO_CS = "01") then
      case DATA_IN(1 downto 0) is
	     when "00" =>
		    porta_data <= finala_data;
		  when "01" =>
		    portb_data <= finalb_data;
		  when "10" =>
		    portc_data <= finalc_data;
		  when "11" =>
		    portd_data <= finald_data;
		  when others =>
		    porta_data <= porta_data;
		    portb_data <= portb_data;
		    portc_data <= portc_data;
		    portd_data <= portd_data;
		end case;
		end if;	
	end if;
  end process;	
---------------------------------------------------------------
-- SET PORT PIN DATA
---------------------------------------------------------------
 in_data <= shift_left(DATA_IN(15 downto 8), to_integer(DATA_IN(4 downto 2) - DATA_IN(7 downto 5)));
 sel_data   <= shift_right(shift_left(x"ff", to_integer(DATA_IN(4 downto 2))), to_integer(DATA_IN(7 downto 5)));
 
set_port_pin : process(sel_data)
variable cunt : integer;
begin							
	 for cunt in 0 to 7 loop

		if sel_data(cunt) = '1' then
		  finala_data(cunt) <= indata(cunt);
		  finalb_data(cunt) <= indata(cunt);		  
		  finalc_data(cunt) <= indata(cunt);		  
		  finald_data(cunt) <= indata(cunt);		  
		else
		  finala_data(cunt) <= porta_data(cunt);
		  finalb_data(cunt) <= portb_data(cunt);		  
		  finalc_data(cunt) <= portc_data(cunt);		  
		  finald_data(cunt) <= portd_data(cunt);		  		  
		end if;
	end loop;
end process;
-------------------------------------------------------------------  
-- SET BI-DIRECTIONAL PINS
-------------------------------------------------------------------
ioport_read : process(porta_ddr, portb_ddr, portc_ddr, portd_ddr)
variable count : integer;
begin

	 for count in 0 to 7 loop
			if porta_ddr(count) = '1' then
			  data_outa(count) <= porta_data(count);
			  porta_io(count)  <= porta_data(count);				  
			else
			  data_outa(count) <= porta_io(count);				  
			end if;

			if portb_ddr(count) = '1' then
			  data_outb(count) <= portb_data(count);
			  portb_io(count)  <= portb_data(count);				  			  
			else
			  data_outb(count) <= portb_io(count);				
			end if;

			if portc_ddr(count) = '1' then
			  data_outc(count) <= portc_data(count);
			  portc_io(count)  <= portc_data(count);				  
			else
			  data_outc(count) <= portc_io(count);
			end if;


			if portd_ddr(count) = '1' then
			  data_outd(count) <= portd_data(count);
			  portd_io(count)  <= portd_data(count);				  
			else
			  data_outd(count) <= portd_io(count);
			end if;

	end loop;
end process;
---------------------------------------------------------
-- DATAOUT
---------------------------------------------------------

data_out0 <= (porta_data & portb_data) when READ_CS(0) = '0' else (portc_data & portc_data);	
data_out1 <= (porta_data & portb_data) when READ_CS(1) = '0' else (portc_data & portc_data);	
calc      <=  x"f" - IOREAD(11 downto 8);

 PORTBOUT   <= shift_right(
					shift_left(
					data_out1, to_integer(calc)
					),
					to_integer(calc + IOREAD(15 downto 12))
					);
					
 PORTAOUT   <= shift_right(
					shift_left(
					data_out0, to_integer(x"f" - IOREAD(3 downto 0))
								 ),
					to_integer(x"f" - IOREAD(3 downto 0) + IOREAD(8 downto 4))
					);					
------------------------------------------------
end ioport_arch;
------------------------------------------------