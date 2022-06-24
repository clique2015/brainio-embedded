--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    ALU - Arithmetic and Logic Unit- ALU.vhd
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


entity alu is

port(
  CLK, RESET			                    : in  std_logic;
  ALU_SET   				                 : in  unsigned(0 downto 0);
  regA, regB                             : in  unsigned(15 downto 0);
  OPERAND                                : in  unsigned(3 downto 0);
  GT, LT, EQ                             : out unsigned(0 downto 0);
  ALU_REGISTER                           : out unsigned(15 downto 0));
 
end entity;

architecture structure of alu is
	signal alu_reg, compareG, compareL 	   : unsigned(15 downto 0);
	signal lt_reg, gt_reg, eq_reg          : unsigned(0 downto 0);
	signal alu_out                         : unsigned(15 downto 0);

		
begin
 
 process(regA, regB, OPERAND)
 begin
  case OPERAND is
	when "0001"   => alu_out <=  	not(regA);
	when "0010"   => alu_out <=   0 -regA;
	when "0011"   => alu_out <= 	regA - 1;
	when "0100"   => alu_out <= 	regA - regB ;
	when "0101"	  => alu_out <=   regA + regB;
	when "0110"   => alu_out <=   regA + 1;
	when "1000"	  =>
	alu_out <=   shift_right(regA,	to_integer(regB(3 downto 0)));	
	when "1001"	  =>
	alu_out <=   shift_left(regA,	to_integer(regB(3 downto 0)));
	when "1010"   => alu_out <= 	regA xor regB;
	when "1011"   => alu_out <= 	regA or regB;
	when "1100"	  => alu_out <=   regA and regB;
	when "1101"	  => alu_out <=   compareG; 
	when "1110"   => alu_out <=   compareL;
	when others   => null ;
  end case;
 end process;
   
	compareG <= regA when regA > regB else regB;	 
	compareL <= regA when regA < regB else regB;	 

	-- the flags are exempted, they were not used in the circuit
	process (CLK, RESET)
   begin
        if (reset = '1') then
            lt_reg <= "0";
            gt_reg <= "0";				
	         eq_reg <= "0";			
            alu_reg <= x"0000";	
				
        elsif (CLK'event and CLK = '1') then 
			if(ALU_SET = 1) then	  
				if(regA < regB) then
				lt_reg <= "1";
				else 
				lt_reg <= "0";
			end if; 
				
			if(regA > regB) then
			gt_reg <= "1";
			else 
			gt_reg <= "0";
			end if; 		
				
			if(regA = regB) then
			eq_reg <= "1";
			else 
			eq_reg <= "0";		
			end if; 			
				
			alu_reg <= alu_out;
			else 
				alu_reg <= alu_reg;		
			end if; 
		end if;		
  end process;

   ALU_REGISTER <= alu_reg;
  GT           <= gt_reg;
  LT           <= lt_reg;
  EQ           <= eq_reg;
end structure;