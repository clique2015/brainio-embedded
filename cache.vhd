--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    cache.vhd
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

ENTITY cache IS

 PORT( 
	clk, reset, uart_select             : IN	std_logic;
	push, pop, rxbit, cts, rts	         : IN  std_logic;
	data_in                   			   : IN 	std_logic_vector(15 downto 0);
	baud                       			: IN 	std_logic_vector(2 downto 0);
	empty, full, txdone, txbit, error 	: OUT std_logic;
	data_out                   			: OUT std_logic_vector(15 downto 0)
   );
end entity;


ARCHITECTURE behavior OF cache IS

	SIGNAL u1_start_tx, u1_start_rx, u1_rxdone     : std_logic;
	SIGNAL f1_push, f3_push, f1_pop , f2_pop       : std_logic;	
	SIGNAL f1_empty, f1_full, f2_empty,  f3_full   : std_logic;
	SIGNAL f1_data_in, f1_fifo_out    				  : std_logic_vector(15 downto 0);
	SIGNAL f3_data_in, f2_fifo_out                 : std_logic_vector(15 downto 0);	
	SIGNAL   u1_uart_tx_data, u1_uart_rx_data      : std_logic_vector(15 downto 0);		

   -- Component Declarations
   COMPONENT fifo
 PORT( 
      clk, reset, push, pop      : IN		std_logic;
		data_in                    : IN 		std_logic_vector(15 downto 0);
      empty, full             	: OUT    std_logic;
		fifo_out                   : OUT    std_logic_vector(15 downto 0)
   );
   END COMPONENT;
	
	
   COMPONENT uart
 PORT( 
      clk, reset, start_tx       	 : IN		 std_logic;
      rxbit, rts, start_rx	      	 : IN     std_logic;
		uart_tx_data               	 : IN 	 std_logic_vector(15 downto 0);
		baudrate                  		 : IN 	 std_logic_vector(2 downto 0);
      rx_done, txdone, txbit, error  : OUT    std_logic;
		uart_rx_data               	 : OUT    std_logic_vector(15 downto 0)
   );
   END COMPONENT;

BEGIN	
 		f1_push	   <= push    when uart_select = '0' else '0';
 		f3_push	   <= push    when uart_select = '1' else '0';		
		
 		f1_pop	   <= pop     when uart_select = '0' else '0';
 		f2_pop	   <= pop     when uart_select = '1' else '0';			
		
 		f1_data_in	<= data_in when uart_select = '0' else '0';	
 		f3_data_in	<= data_in when uart_select = '1' else '0';			
	
		fifo_out    <= f2_fifo_out when uart_select = '1' else f1_fifo_out;	
		empty       <= f2_empty    when uart_select = '1' else f1_empty;		
		full        <= f3_full     when uart_select = '1' else f1_full;	

   I1 : fifo
      PORT MAP (
      clk			=> clk,
		reset			=> reset,
		push			=> f1_push,
		pop         => f1_pop,
		data_in     => f1_data_in,
      empty			=> f1_empty,
		full		   => f1_full,
		fifo_out    => f1_fifo_out
      );
   I2 : fifo
      PORT MAP (
      clk			=> clk,
		reset			=> reset,
		push			=> u1_rxdone,
		pop         => f2_pop ,
		data_in     => u1_uart_rx_data,
      empty			=> f2_empty,
		full		   => u1_start_rx,
		fifo_out    => f2_fifo_out
      );
   I3 : fifo
      PORT MAP (
      clk			=> clk,
		reset			=> reset,
		push			=> f3_push,
		pop         => rts,
		data_in     => f3_data_in,
      empty			=> u1_start_tx,
		full		   => f3_full,
		fifo_out    => u1_uart_tx_data
      );
   I4 : uart
      PORT MAP (
      clk			=> clk,
		reset			=> reset,
		start_tx		=> u1_start_tx,
      rxbit			=> rxbit,
		cts			=> cts,
		rts			=> rts,
		start_rx		=> u1_start_rx,
		uart_tx_data=> u1_uart_tx_data,
		baudrate		=> baud,
      rx_done		=> u1_rxdone,
		txdone		=> txdone,
		txbit			=> txbit,
		error			=> error,
		uart_rx_data=> u1_uart_rx_data
      );
   
   END behavior;
