--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    decode.vhd
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

entity decode is

port(
  regA, instr_mem_out, MULT_OUT                           : in  unsigned(15 downto 0);
  ALU_SET, REG_RSEL, REG_MSEL, POP_LIFO, POP_FIFO			 : out unsigned(0 downto 0); 
  PUSH_FIFO, PUSH_LIFO, RAM_CS, DATA_SIG					    : out unsigned(0 downto 0);   
  LOAD_FETCH, RAM_ADDR_SEL, TIMER_CS, IO_CS, INTR_RETURN	 : out unsigned(1 downto 0);  
  REG_SEL, JMP_PC_SEL												 : out unsigned(2 downto 0);
  MULT_SEL, OPCODE, regA_SEL, BAUD_SET, INTERRUPT_CTRL	 : out unsigned(3 downto 0);  
  JMP_PC_DATA, RAM_ADDR								  				 : out unsigned(7 downto 0);
  RAM_DATAIN		    												 : out unsigned(15 downto 0));
  end entity;

architecture structure of decode is
	signal pop															  : unsigned(0 downto 0);
	
begin
-------------------------------------------------------------
-- POP
-------------------------------------------------------------
process(pop, instr_mem_out)
begin
	if (pop = "1") then
		POP_LIFO     <= instr_mem_out(1 downto 1); 
		POP_FIFO     <= instr_mem_out(0 downto 0);
		if (instr_mem_out(15 downto 14) /= "01") then		 
			if (instr_mem_out(1 downto 1) = "1") then		
				MULT_SEL     <= "1010";
			elsif (instr_mem_out(0 downto 0) = "1") then
				MULT_SEL     <= "1001";
			end if;	
		end if;
	end if;

-------------------------------------------------------------
-- DATA
-------------------------------------------------------------
	if (instr_mem_out(15 downto 14) = "00") then
     DATA_SIG <= "1";
	end if;
	
-------------------------------------------------------------
-- ALU OPERATION
-------------------------------------------------------------
	if (instr_mem_out(15 downto 14) = "01") then
		MULT_SEL     <= instr_mem_out(5 downto 2);
		pop	       <= "1"; 		
		ALU_SET 		 <= "1";
		OPCODE		 <= instr_mem_out(13 downto 10);
		REGA_sel		 <= instr_mem_out(9 downto 6);
	end if;

-------------------------------------------------------------
-- DIRECT MEMORY WRITE FROM REGISTER
-------------------------------------------------------------
	if (instr_mem_out(15 downto 12) = "1000") then
		MULT_SEL     <= instr_mem_out(3 downto 0);
		RAM_ADDR  	 <= instr_mem_out(11 downto 4);
		RAM_CS  		 <= "1";	
		RAM_DATAIN   <= MULT_OUT;
	end if;
	
-------------------------------------------------------------
-- INDIRECT MEMORY WRITE FROM REGISTER
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 10) = "100100") then
		MULT_SEL  	 <= instr_mem_out(3 downto 0);
		RAM_ADDR  	 <= regA(7 downto 0);
		regA_SEL  	 <= instr_mem_out(9 downto 6); 
		RAM_ADDR_SEL <= instr_mem_out(5 downto 4); 		
		RAM_CS  		 <= "1";	
		RAM_DATAIN   <= MULT_OUT;
	end if;

-------------------------------------------------------------
-- INDIRECT MEMORY WRITE FROM POP
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 10) = "100101") then
		pop		  	 <= "1";
		RAM_ADDR  	 <= regA(7 downto 0);
		regA_SEL  	 <= instr_mem_out(9 downto 6); 
		RAM_ADDR_SEL <= instr_mem_out(5 downto 4); 		
		RAM_CS  		 <= "1";	
		RAM_DATAIN   <= MULT_OUT;
	end if;

-------------------------------------------------------------
-- DIRECT MEMORY WRITE FROM POP
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 11) = "10011") then
		pop		  	 <= "1";
		RAM_ADDR  	 <= instr_mem_out(10 downto 3);		
		RAM_CS  		 <= "1";	
		RAM_DATAIN   <= MULT_OUT;
	end if;

-------------------------------------------------------------
-- REGISTER WRITE FROM DIRECT MEMORY ADDRESSING
-------------------------------------------------------------		
	if (instr_mem_out(15 downto 13) = "110") then
		REG_MSEL  		 		 <= "1";	
		REG_SEL      			 <= instr_mem_out(2 downto 0);
		LOAD_FETCH  			 <= instr_mem_out(4 downto 3);
		RAM_ADDR  			 	 <= instr_mem_out(12 downto 5);	
	end if;	
	
-------------------------------------------------------------
-- REGISTER WRITE FROM INDIRECT MEMORY ADDRESSING
-------------------------------------------------------------			
	if (instr_mem_out(15 downto 11) = "11100") then	
		REG_MSEL  		 		 <= "1";		
		REG_SEL      			 <= instr_mem_out(2 downto 0);
		LOAD_FETCH  			 <= instr_mem_out(4 downto 3);	
		RAM_ADDR  	 			 <= regA(7 downto 0);	
		regA_SEL  	 			 <= instr_mem_out(10 downto 7); 		
		RAM_ADDR_SEL			 <= instr_mem_out(6 downto 5);		
	end if;	

-------------------------------------------------------------
-- REGISTER WRITE FROM REGISTER
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 10) = "111010") then			
		REG_SEL      			 <= instr_mem_out(2 downto 0);
		LOAD_FETCH  			 <= instr_mem_out(4 downto 3);	
		REG_RSEL  		 		 <= "1";		
		MULT_SEL 				 <= instr_mem_out(8 downto 5);
	end if;		
	
-------------------------------------------------------------
-- REGISTER WRITE FROM POP
-------------------------------------------------------------			
	if (instr_mem_out(15 downto 9) = "1110110") then			
		REG_SEL      			 <= instr_mem_out(7 downto 5);
		LOAD_FETCH  			 <= instr_mem_out(4 downto 3);	
		REG_RSEL  		 		 <= "1";		
		pop	      			 <= "1";			
	end if;			
	
-------------------------------------------------------------
-- CHIP SELECT CONTROL
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 11) = "10100") then			
		TIMER_CS      			 <= instr_mem_out(3 downto 2);
		IO_CS  			       <= instr_mem_out(5 downto 4);	
		PUSH_FIFO  		 		 <= instr_mem_out(6 downto 6);			
		PUSH_LIFO  		 		 <= instr_mem_out(7 downto 7);			
		INTR_RETURN  		 	 <= instr_mem_out(9 downto 8);
		pop	      			 <= "1";				
	end if;	

-------------------------------------------------------------
-- INTERRUPT AND BAUD CONTROL
-------------------------------------------------------------	
	if (instr_mem_out(15 downto 11) = "10101") then			
		INTERRUPT_CTRL        <= instr_mem_out(3 downto 0);
		BAUD_SET 		       <= instr_mem_out(7 downto 4);			
	end if;	

-------------------------------------------------------------
-- JUMP CONTROL
-------------------------------------------------------------
	if (instr_mem_out(15 downto 12) = "1011") then			
		JMP_PC_SEL     		 <= instr_mem_out(10 downto 8);
		JMP_PC_DATA 		    <= instr_mem_out(7 downto 0);		
	end if;
	
--------------------------------------------------------------
end process;
end structure;
--------------------------------------------------------------