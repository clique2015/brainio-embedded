
--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME:    register.vhd
--------------------------------------------------------------------------------
-- AUTHORS: Ezeuko Emmanuel <ezeuko.arinze@projectfpga.com>
--------------------------------------------------------------------------------
-- WEBSITE: https://projectfpga.com/iosoc
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- brainio
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


entity registers is

port(
  CLK, RESET															 : in std_logic;
  REG_MSEL, PUSHFIFO_IN, PUSHLIFO_IN							 : in  unsigned(0 downto 0);
  F_LIFO, E_LIFO, F_FIFO, E_FIFO									 : in  unsigned(0 downto 0);
  INTR0, INTR1, INTR2, TON, GT, LT, EQ, REG_RSEL	   	 : in  unsigned(0 downto 0);
  LOAD_FETCH, IO_CSIN, TIMER_CSIN, INTR_RETURN		 	    : in  unsigned(1 downto 0);
  REG_SEL, JUMP_SEL                                       : in  unsigned(2 downto 0);  
  INTR_SET, BAUD_SET                                      : in  unsigned(3 downto 0); 
  JUMP     														       : in  unsigned(7 downto 0); 
  RAM_OUT, MULT_OUT                                       : in  unsigned(15 downto 0);
  PUSH_FIFO, PUSH_LIFO, FREQ_PIN, CACHE_SET				    : out unsigned(0 downto 0); 
  IO_CS, TIMER_CS, READ_CS 								       : out unsigned(1 downto 0);
  BAUD															       : out unsigned(2 downto 0);  
  TIMER_DATA_IN, IO_DATA_IN, FIFO_IN, LIFO_IN  				 : out unsigned(15 downto 0);
  ioREAD, PROGRAM_COUNTER, INTERUPT 							 : out unsigned(15 downto 0));
end entity;

architecture structure of registers is
	signal timer_datain_reg, io_datain_reg, lifoin_reg 	  : unsigned(15 downto 0);
	signal fifoin_reg, ioread_reg, program_counter_reg 	  : unsigned(15 downto 0);
	signal freq_reg, freq_counter_reg, intr_data_reg        : unsigned(15 downto 0);
	signal int0_data_reg, int1_data_reg, int2_data_reg      : unsigned(15 downto 0);	
	signal intr_return_reg, pc_reg, pc_out 				 	  : unsigned(15 downto 0);	
	signal s_timer_datain, s_pc, s_lifoin					 	  : unsigned(15 downto 0);
	signal s_fifoin, s_io_datain, s_ioread, s_intr_data 	  : unsigned(15 downto 0);
	signal baud_reg					                          : unsigned(2 downto 0);	
	signal iocs_reg, timercs_reg, load_fetch_reg, read_cs_reg: unsigned(1 downto 0);
	signal timer_delay_reg, io_delay_reg, lifo_delay_reg	  : unsigned(0 downto 0);
	signal fifo_delay_reg, ioread_delay_reg, pc_delay_reg   : unsigned(0 downto 0);
	signal msel_reg, intr_start, pc_rset, f_pinset_reg		  : unsigned(0 downto 0);
	signal intr0_debounce_reg, cache_set_reg, intr_delay_reg: unsigned(0 downto 0);
	signal intr1_debounce_reg, p_fifo_reg, int0_on, int1_on : unsigned(0 downto 0); 
	signal intr2_debounce_reg, int_set0_reg, int_set1_reg   : unsigned(0 downto 0);
	signal pwm_pin, int_set2_reg, p_lifo_reg, int2_on, int_on, pc_mset,jump_out	  : unsigned(0 downto 0);
	
begin

----------------------------------------------	
-- MEMORY READ
----------------------------------------------	
	process (CLK, RESET)
   begin
	  if (RESET =  '1') then	
		load_fetch_reg 		<= b"00";
		msel_reg 				<= (others => '0');
	  elsif (CLK'event and CLK =  '1') then 
		load_fetch_reg 		<= LOAD_FETCH;
		msel_reg 				<= REG_MSEL;
	end if;
  end process;				
----------------------------------------------	
--TIMER REGISTER
----------------------------------------------	
  process(msel_reg, timer_delay_reg)
  begin
	if ((msel_reg =  1) and (timer_delay_reg = 1)) then
		s_timer_datain <= RAM_OUT;
		TIMER_CS       <= load_fetch_reg;
	else
		s_timer_datain <= timer_datain_reg;	
		TIMER_CS       <= timercs_reg;					
	end if;
  end process;				
----------------------------------------------
	process (CLK, RESET)
   begin
        if (RESET =  '1') then		  
            timer_datain_reg    <= x"0000";
            timercs_reg		     <= b"00";				
            timer_delay_reg     <= (others => '0');	
        elsif (CLK'event and CLK =  '1') then 
			if (REG_SEL = "001") then
				timer_delay_reg <= "1";
				if(REG_RSEL =  1) then				
					timer_datain_reg <= MULT_OUT;
					timercs_reg		  <= LOAD_FETCH;
				else
					timercs_reg		  <= TIMER_CSIN;
				end if;
			else
				timer_datain_reg <= s_timer_datain;					
				timer_delay_reg <= (others => '0');
			end if;
  end if;
  end process;	
----------------------------------------------	
-- IO WRITE REGISTER
----------------------------------------------
  process(msel_reg, io_delay_reg)
  begin
	if ((msel_reg =  1) and (io_delay_reg =  1)) then
		IO_CS       <= load_fetch_reg;
		s_io_datain <= RAM_OUT;	
	else		
		IO_CS       <=	iocs_reg;
		s_io_datain <= io_datain_reg;			
	end if;	
  end process;	
----------------------------------------------
	process (CLK, RESET)
   begin
        if (RESET =  '1') then			
            io_datain_reg       <= x"0000";	
            iocs_reg		        <= b"00";				
            io_delay_reg        <= (others => '0');	
        elsif (CLK'event and CLK =  '1') then 
			if (REG_SEL = "010") then
				io_delay_reg <= "1";
				if(REG_RSEL =  1) then
					io_datain_reg <= MULT_OUT;
					iocs_reg 	  <= LOAD_FETCH;
				else	
					iocs_reg 	  <= IO_CSIN;
				end if;
			else 
				io_datain_reg <= s_io_datain;				
				io_delay_reg <= (others => '0');
			end if;	
		end if;
  end process;				
----------------------------------------------
-- LIFO REGISTER
----------------------------------------------
  process(msel_reg, lifo_delay_reg)
  begin
	if ((msel_reg =  1) and (lifo_delay_reg =  1)) then		
		s_lifoin    <= RAM_OUT;
		PUSH_LIFO   <= load_fetch_reg(0 downto 0);
	else
		s_lifoin    <= lifoin_reg;	
		PUSH_LIFO   <=	p_lifo_reg;				
	end if;	
  end process;	
----------------------------------------------	
	process (CLK, RESET)
   begin
        if (RESET =  '1') then			
	         lifoin_reg          <= x"0000";
	         p_lifo_reg	        <= (others => '0');				
	         lifo_delay_reg      <= (others => '0');					
        elsif (CLK'event and CLK =  '1') then
			if (REG_SEL = "011") then
				lifo_delay_reg <= "1";
				if(REG_RSEL =  "1") then
					lifoin_reg <= MULT_OUT;
					p_lifo_reg <= LOAD_FETCH(0 downto 0);
				else
					p_lifo_reg <= PUSHLIFO_IN;
				end if;
			else 
				lifoin_reg <= s_lifoin;				
				lifo_delay_reg <= (others => '0');
			end if;	
		end if;
  end process;					
----------------------------------------------
-- FIFO REGISTER
----------------------------------------------
  process(msel_reg, fifo_delay_reg)
  begin
	if ((msel_reg =  1) and (fifo_delay_reg =  1)) then		
		s_fifoin    <= RAM_OUT;
		PUSH_FIFO   <= load_fetch_reg(0 downto 0);
	else
		s_fifoin    <= fifoin_reg;	
		PUSH_FIFO   <=	p_fifo_reg;				
	end if;	
  end process;	
----------------------------------------------	
	process (CLK, RESET)
   begin
        if (RESET =  '1') then			
	         fifoin_reg          <= x"0000";
	         p_fifo_reg	        <= (others => '0');				
	         fifo_delay_reg      <= (others => '0');					
        elsif (CLK'event and CLK =  '1') then
			if (REG_SEL = "011") then
				fifo_delay_reg <= "1";
				if(REG_RSEL =  "1") then
					fifoin_reg <= MULT_OUT;
					p_fifo_reg <= LOAD_FETCH(0 downto 0);
				else
					p_fifo_reg <= PUSHFIFO_IN;
				end if;
			else 
				fifoin_reg <= s_fifoin;				
				fifo_delay_reg <= (others => '0');
			end if;	
		end if;
  end process;		
----------------------------------------------	
-- IO READ REGISTER
----------------------------------------------
  process(msel_reg, ioread_delay_reg)
  begin
	if ((msel_reg =  1) and (ioread_delay_reg =  1)) then		
		s_ioread <= RAM_OUT;
		READ_CS  <= load_fetch_reg;
	else
		s_ioread <= ioread_reg;	
		READ_CS  <= read_cs_reg;
	end if;
  end process;	
----------------------------------------------	
	process (CLK, RESET)
   begin
        if (RESET =  '1') then								
				ioread_reg          <= x"0000";
				read_cs_reg         <= "00";
				ioread_delay_reg    <= (others => '0');
        elsif (CLK'event and CLK =  '1') then 
			if (REG_SEL = "101") then
				ioread_delay_reg <=  "1";
				if(REG_RSEL =  "1") then
					ioread_reg  <= MULT_OUT;	
					read_cs_reg <= LOAD_FETCH;					
				end if;
			else 
				ioread_reg <= s_ioread;				
				ioread_delay_reg <= (others => '0');
			end if;
		end if;
  end process;				
----------------------------------------------
--INTERRUPT REGISTER
----------------------------------------------
  process(msel_reg, intr_delay_reg)
  begin
	if ((msel_reg =  1) and (intr_delay_reg =  1)) then		
		s_intr_data <= RAM_OUT;
	else
		s_intr_data <= intr_data_reg;					
	end if;
  end process;	
----------------------------------------------	
	process (CLK, RESET)
   begin
        if (RESET =  '1') then								
				intr_data_reg		  <= x"0000";
				intr_delay_reg      <= (others => '0');				
        elsif (CLK'event and CLK =  '1') then 
			if (REG_SEL = "110") then
				intr_delay_reg <=  "1";
				if(REG_RSEL =  "1") then
					intr_data_reg <= MULT_OUT;			
				end if;
			else 
				intr_data_reg <= s_intr_data;				
				intr_delay_reg <= (others => '0');
			end if;
		end if;
  end process;					
----------------------------------------------
-- PROGRAM COUNTER REGISTER
----------------------------------------------
  process(msel_reg, pc_delay_reg)
  begin
	if ((msel_reg =  1) and (pc_delay_reg =  1)) then		
		s_pc <= RAM_OUT;
	else
		s_pc <= pc_reg;					
	end if;
  end process;	
-------------------------------------------------- 
	process (CLK, RESET)
   begin
        if (RESET =  '1') then								
            pc_reg 				  <= x"0000";
            pc_delay_reg        <= (others => '0');
        elsif (CLK'event and CLK =  '1') then 
			pc_reg  	       <= pc_out;		  
			if (REG_SEL = "111") then
				pc_delay_reg <=  "1";
			else 
				pc_delay_reg <= (others => '0');
			end if;	

  end if;
  end process;			  
----------------------------------------------
	pc_mset				<=  "1"  when pc_delay_reg =  "1" and msel_reg =  1  else (others => '0');	
	pc_rset				<=  "1"  when REG_SEL = "111"     and REG_RSEL =  1  else (others => '0');		
----------------------------------------------
-- NEXT INSTRUCTION
----------------------------------------------	
 	process (INTR_RETURN, int0_on, int1_on, int2_on, TON, pc_rset, jump_out) 
	begin
		if(int0_on =  "1") then
			pc_out <= int0_data_reg;	
		elsif(int1_on =  "1") then
			pc_out <= int1_data_reg;		
		elsif(int2_on =  "1") then
			pc_out <= int2_data_reg;
		elsif(INTR_RETURN(0 downto 0) =  "1") then
			pc_out <= intr_return_reg;
		elsif(TON =  "1") then
			pc_out <= s_pc;		
		elsif(pc_rset =  "1") then
			pc_out <= MULT_OUT;	
		elsif(pc_mset =  "1") then
			pc_out <= RAM_OUT;	
		elsif(jump_out =  "1") then
			if(JUMP(0 downto 0) = "1") then	
				pc_out <= s_pc - ("000000000" & JUMP(7 downto 1));
			else
				pc_out <= s_pc + ("000000000" & JUMP(7 downto 1));
			end if;
		else 
			pc_out <= s_pc + 1;	
			
		end if;
  end process;
 ---------------------------------------------	  
-- INTERRUPT RETURN
----------------------------------------------
	process (CLK, RESET)
   begin
	  if (RESET =  '1') then
			intr_return_reg	  <= x"0000";
			int_on 			     <= (others => '0');
			
	  elsif (CLK'event and CLK =  '1') then 
		if (intr_start =  "1") then
			intr_return_reg <= s_pc + 1;
			int_on          <=  "1";
		elsif(INTR_RETURN(1 downto 1) =  "1") then
			int_on <= (others => '0');		
		end if;
	
  end if;
  end process; 
 -------------------------------------------------
 	intr_start			<=  int0_on OR int1_on OR int2_on;
--------------------------------------------------
-- JUMP SELECT
--------------------------------------------------
 process(JUMP_SEL,E_FIFO,E_LIFO,F_FIFO,F_LIFO,EQ,GT,LT)
 begin
	  case JUMP_SEL is
			when "000" => jump_out <= (others => '0');
			when "001" => jump_out <= GT;
			when "010" => jump_out <= EQ;
			when "011" => jump_out <= LT;
			when "100" => jump_out <= F_LIFO;
			when "101" => jump_out <= E_LIFO;
			when "110" => jump_out <= F_FIFO;
			when "111" => jump_out <= E_FIFO;
			when others => null;
	  end case;
 end process;
--------------------------------------------------
-- INTERRUPT CONTROL
--------------------------------------------------
	process (CLK, RESET)
   begin
	  if (RESET =  '1') then
			intr0_debounce_reg  <= (others => '0');
			intr1_debounce_reg  <= (others => '0');
			intr2_debounce_reg  <= (others => '0');
			int_set0_reg 		  <= (others => '0');
			int_set1_reg 		  <= (others => '0');
			int_set2_reg 		  <= (others => '0');
			f_pinset_reg		  <= (others => '0');					
			int0_data_reg	     <= x"0000";
			int1_data_reg	     <= x"0000";
			int2_data_reg	     <= x"0000";			
			freq_reg 			  <= x"0000";			
	  elsif (CLK'event and CLK =  '1') then 			
			intr0_debounce_reg	<= INTR0;
			intr0_debounce_reg	<= INTR1;
			intr0_debounce_reg	<= INTR2;
		 case INTR_SET is
			when "0001"   => int_set0_reg <= (others => '0');
			when "0010"   => int_set0_reg <=  "1";
			when "0011"   => int_set1_reg <= (others => '0');
			when "0100"   => int_set1_reg <=  "1";	
			when "0101"	  => int_set2_reg <= (others => '0');
			when "0110"   => int_set2_reg <=  "1";	
			when "0111"   => f_pinset_reg <= (others => '0');				
			when "1000"	  => f_pinset_reg <=  "1";	
			when "1001"	  => int0_data_reg <= s_intr_data;
			when "1010"   => int1_data_reg <= s_intr_data;
			when "1011"   => int2_data_reg <= s_intr_data;
			when "1100"	  => freq_reg 		 <= s_intr_data;
			when others   => null ;
		  end case;	
  end if;
  end process;				  
--------------------------------------------------
	int0_on 				<=  INTR0 and int_set0_reg and not intr0_debounce_reg;
	int1_on 				<=  INTR1 and int_set1_reg and not intr1_debounce_reg;
	int2_on 				<=  INTR2 and int_set2_reg and not intr2_debounce_reg;
---------------------------------------------------
-- SET PWM
------------------------------------------------	
	process (CLK, RESET)
   begin
	  if (RESET =  '1') then
			pwm_pin			  <= (others => '0');				
			freq_counter_reg    <= x"0000";
     elsif (CLK'event and CLK =  '1') then 
		if (f_pinset_reg =  "1") then
			if(freq_reg = freq_counter_reg) then
				freq_counter_reg <= x"0000";
			else
				freq_counter_reg <= freq_counter_reg + 1;					
			end if;
		end if;	
		
		if(freq_reg = freq_counter_reg) then
			pwm_pin <= not pwm_pin;			
		end if;
  end if;
  end process;				
--------------------------------------------------
-- BAUD RATE
--------------------------------------------------
	process (CLK, RESET)
   begin
	  if (RESET =  '1') then
			baud_reg 			  <= b"000";
			cache_set_reg 	     <= (others => '0');
	  elsif (CLK'event and CLK =  '1') then 
		  if (BAUD_SET(0 downto 0) =  "1") then
				baud_reg <= BAUD_SET(3 downto 1);
				cache_set_reg <=  "1";						
			elsif ((BAUD_SET(0 downto 0) = "0") and (BAUD_SET(3 downto 1) = "111")) then
				cache_set_reg <= (others => '0');			
			end if;	
  end if;
  end process;			
------------------------------------------------
	
   TIMER_DATA_IN 	  <=	s_timer_datain;
	IO_DATA_IN 		  <=	s_io_datain;
	FIFO_IN			  <=	s_fifoin;
	LIFO_IN   		  <=	s_lifoin;
   ioREAD			  <=	s_ioread;
   PROGRAM_COUNTER  <=	pc_out;
   INTERUPT 	 	  <=	s_intr_data; 
	BAUD 				  <=  baud_reg;
	CACHE_SET 		  <=  cache_set_reg;
	FREQ_PIN         <=  pwm_pin;
end structure;