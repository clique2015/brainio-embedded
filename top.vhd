--------------------------------------------------------------------------------
-- PROJECTFPGA.COM
--------------------------------------------------------------------------------
-- NAME: TOP.vhd
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


ENTITY example1 IS

 PORT( 
	clock, reset								  : in  std_logic; 
	WE, INTR0, INTR1, INTR2               : in  unsigned(0 downto 0);
	IN_DATA, LOAD_ADDR          			  : in  unsigned(15 downto 0);
	RAM_FULL, FREQ_PIN 						  : out unsigned(0 downto 0);	
	PORTA, PORTB, PORTC, PORTD 			  : inout  unsigned(7 downto 0)
   );
end entity;

ARCHITECTURE behavior OF example1 IS

	SIGNAL ton, pop_fifo, push_fifo, fifo_full, fifo_empty	 : unsigned(0 downto 0);
	SIGNAL data_sig, push_lifo, pop_lifo, lifo_full           : unsigned(0 downto 0);	
	SIGNAL GT, LT, EQ, ram_cs, alu_set, reg_msel, lifo_empty  : unsigned(0 downto 0);
	SIGNAL push_fifo_in, push_lifo_in, reg_rsel				    : unsigned(0 downto 0);	
	SIGNAL io_cs_in, timer_cs_in, load_fetch, intr_return	    : unsigned(1 downto 0);	
	SIGNAL timer_cs, ram_sel, io_cs, read_cs				       : unsigned(1 downto 0);		
	SIGNAL jmp_pc_sel, reg_sel, baudrate           				 : unsigned(2 downto 0);	
	SIGNAL opcode, Mult_sel, regA_sel, intr_ctrl, baud 		 : unsigned(3 downto 0);
	SIGNAL ram_addr, jmp_pc_data			                      : unsigned(7 downto 0);		
	SIGNAL timer_data_in, DATA_reg, fifo_in, registerA 		 : unsigned(15 downto 0);
	SIGNAL alu_reg, ram_out, pc, ram_in, interrupt            : unsigned(15 downto 0);	
	SIGNAL fifo_out, progmem_out, lifo_out, Mult_out          : unsigned(15 downto 0);		
	SIGNAL ioREAD, io_data_in, portA_out, portB_out, lifo_in  : unsigned(15 downto 0);		 


   COMPONENT REGISTERS
	port(
	  CLK, RESET															 : in  std_logic; 
	  REG_MSEL, PUSHFIFO_IN, PUSHLIFO_IN							 : in  unsigned ;	  
	  F_LIFO, E_LIFO, F_FIFO, E_FIFO									 : in  unsigned ;
	  INTR0, INTR1, INTR2, TON, GT, LT, EQ, REG_RSEL	   	 : in  unsigned ;
	  LOAD_FETCH, IO_CSIN, TIMER_CSIN, INTR_RETURN			    : in  unsigned(1 downto 0);
	  REG_SEL, JUMP_SEL                                       : in  unsigned(2 downto 0);  
	  INTR_SET, BAUD_SET                                      : in  unsigned(3 downto 0); 
	  JUMP     														       : in  unsigned(7 downto 0); 
	  RAM_OUT, MULT_OUT                                       : in  unsigned(15 downto 0);
	  PUSH_FIFO, PUSH_LIFO, FREQ_PIN, CACHE_SET				    : out unsigned(0 downto 0); 
	  IO_CS, TIMER_CS, READ_CS 								       : out unsigned(1 downto 0);
	  BAUD															       : out unsigned(2 downto 0);  
	  TIMER_DATA_IN, IO_DATA_IN, FIFO_IN, LIFO_IN  				 : out unsigned(15 downto 0);
	  ioREAD, PROGRAM_COUNTER, INTERUPT 							 : out unsigned(15 downto 0));
   END COMPONENT;
	
   COMPONENT IOPORT
	port (	
	 clk                                                      : in  std_logic; 
    reset                                                    : in  std_logic; 
    IO_CS                                                    : in  unsigned(1 downto 0);
    READ_CS                                                  : in  unsigned(1 downto 0);	 
    DATA_IN                                                  : in  unsigned(15 downto 0);
	 IOREAD                                                   : in  unsigned(15 downto 0);	 
	 PORTAOUT                                                 : out unsigned(15 downto 0);
	 PORTBOUT                                                 : out unsigned(15 downto 0);	 	 
	 porta_io                                                 : inout unsigned(7 downto 0);
	 portb_io                                                 : inout unsigned(7 downto 0);
	 portc_io                                                 : inout unsigned(7 downto 0);
    portd_io                                                 : inout unsigned(7 downto 0));
   END COMPONENT;
	
   COMPONENT DECODE
	port(
	  regA, instr_mem_out, MULT_OUT                           : in  unsigned(15 downto 0);
	  ALU_SET, REG_RSEL, REG_MSEL, POP_LIFO, POP_FIFO			 : out unsigned(0 downto 0); 
	  PUSH_FIFO, PUSH_LIFO, RAM_CS, DATA_SIG					    : out unsigned(0 downto 0);   
	  LOAD_FETCH, RAM_ADDR_SEL, TIMER_CS, IO_CS, INTR_RETURN	 : out unsigned(1 downto 0);  
	  REG_SEL, JMP_PC_SEL												 : out unsigned(2 downto 0);
	  MULT_SEL, OPCODE, regA_SEL, BAUD_SET, INTERRUPT_CTRL	 : out unsigned(3 downto 0);  
	  JMP_PC_DATA, RAM_ADDR								  				 : out unsigned(7 downto 0);
	  RAM_DATAIN		      											 : out unsigned(15 downto 0));	
   END COMPONENT;	
	
   COMPONENT DATABUS
	port(
	  data, timer_data_in, pc, portA_out, portB_out           : in  unsigned(15 downto 0);
	  lifo_in, fifo_in, ioREAD, io_data_in, interrupt	       : in  unsigned(15 downto 0);
	  alu_out, fifo_out, lifo_out                             : in  unsigned(15 downto 0);
	  regA_sel, data_sel                                      : in  unsigned(3 downto 0);  
	  DATAOUT1, regA                                          : out unsigned(15 downto 0));
   END COMPONENT;		
	
	COMPONENT DATA_MEMORY
  generic (
    addr_width : integer := 8;
    data_width : integer := 16 
  );
	port(
	  CLK, RESET 			  												 : in  std_logic; 
	  RAM_CS   																 : in  unsigned ;	  
	  RAM_SEL             											    : in  unsigned(1 downto 0);	  
	  RAM_ADDR             											    : in  unsigned(addr_width-1 downto 0);
	  RAM_DATA_IN         											    : in  unsigned(15 downto 0);
	  FULL		 			 											    : out unsigned(0 downto 0);
	  RAM_DATA_OUT        											    : out unsigned(15 downto 0));
   END COMPONENT;	
	
	COMPONENT ALU
	port(
	  CLK, RESET 				                                  : in  std_logic; 
	  ALU_SET         				                            : in  unsigned ;	  
	  regA, regB                                              : in  unsigned(15 downto 0);
	  OPERAND                                                 : in  unsigned(3 downto 0);
	  GT, LT, EQ                                              : out unsigned(0 downto 0);
	  ALU_REGISTER                                            : out unsigned(15 downto 0));
   END COMPONENT;	
	
	COMPONENT LIFO
	port(
	  CLK, RESET 				                                  : in  std_logic; 	
	  PUSH_LIFO, POP_LIFO 				                         : in  unsigned ;
	  LIFO_IN                                                 : in  unsigned(15 downto 0);
	  LIFO_FULL, LIFO_EMPTY                                   : out unsigned(0 downto 0);
	  LIFO_OUT                                                : out unsigned(15 downto 0));
   END COMPONENT;	
	
	COMPONENT programMemory
   generic (
	 addr_width : integer := 16;
	 data_width : integer := 16 
   );
	port(
	  CLK, rst 			                                   		    : in  std_logic; 
	  WE, data_sig             			                         : in  unsigned ;	  
	  PC,IN_DATA,LOAD_ADDR                                       : in  unsigned(addr_width-1 downto 0);
	  DATA_OUT, DATA_reg                                         : out unsigned(data_width-1 downto 0));
   END COMPONENT;		
	
	COMPONENT FIFO
	port(
	  CLK, RESET 				                                     : in  std_logic; 		
	  PUSH_FIFO, POP_FIFO  				                            : in  unsigned ;
	  FIFO_IN                                                    : in  unsigned(15 downto 0);
	  FIFO_FULL, FIFO_EMPTY                                      : out unsigned(0 downto 0);
	  FIFO_OUT                                                   : out unsigned(15 downto 0));
   END COMPONENT;	
	
	COMPONENT TIMER
	port(
	  CLK, RESET 				                                  : in  std_logic; 	
	  Timer_data_in                                           : in  unsigned(15 downto 0);
	  timer_cs                                                : in  unsigned(1 downto 0);
	  TON                                                     : out unsigned);
   END COMPONENT;		
	
 
	
	
BEGIN	
 -- Instance port mappings.
 
    No1: REGISTERS
	PORT MAP(
	  CLK					=> clock,
	  RESET				=>	reset,
	  REG_MSEL			=> reg_msel,
	  PUSHFIFO_IN		=> push_fifo_in,
	  PUSHLIFO_IN		=> push_lifo_in,
	  F_LIFO				=>	lifo_full,
	  E_LIFO				=>lifo_empty,
	  F_FIFO				=> fifo_full,
	  E_FIFO				=> fifo_empty,
	  INTR_RETURN		=> intr_return,
	  INTR0				=> INTR0,
	  INTR1				=> INTR1,
	  INTR2				=> INTR2,
	  TON					=>	ton,
	  GT					=> GT,
	  LT					=> LT,
	  EQ					=> EQ,
	  REG_RSEL			=> reg_rsel,
	  LOAD_FETCH		=> load_fetch,
	  IO_CSIN			=> io_cs_in,
	  TIMER_CSIN		=> timer_cs_in,
	  REG_SEL			=> reg_sel,
	  JUMP_SEL     	=> jmp_pc_sel,
	  INTR_SET			=> intr_ctrl,
	  BAUD_SET     	=> baud,
	  JUMP   			=> jmp_pc_data,
	  RAM_OUT			=> ram_out,
	  MULT_OUT   		=> Mult_out,
	  PUSH_FIFO			=> push_fifo,
	  PUSH_LIFO			=> push_lifo,
	  FREQ_PIN			=> FREQ_PIN,
	  IO_CS				=> io_cs,
	  READ_CS         => read_cs,
	  TIMER_CS			=>	timer_cs,
	  BAUD				=>	baudrate,		 
	  TIMER_DATA_IN	=> timer_data_in,
	  IO_DATA_IN		=> io_data_in,
	  FIFO_IN			=> fifo_in,
	  LIFO_IN  			=> lifo_in,
	  ioREAD				=> ioREAD,
	  PROGRAM_COUNTER	=> pc,
	  INTERUPT 			=> interrupt
     );
 
   No2: IOPORT
	 PORT MAP (	
	 clk			=>  clock,
	 reset		=>  reset,
	 IO_CS		=>  io_cs,
	 READ_CS		=>  read_cs,
	 DATA_IN		=>  io_data_in,
	 IOREAD		=>  ioREAD,
	 PORTAOUT	=>  portA_out,
	 PORTBOUT 	=>  portB_out,
	 porta_io	=>  PORTA,
	 portb_io	=>  PORTB,
	 portc_io   =>  PORTC,
	 portd_io	=>  PORTD
	 );

   No3 : DECODE
	  PORT MAP(
	  DATA_SIG			=>  data_sig,
	  regA				=>  registerA,
	  instr_mem_out	=>  progmem_out,
	  MULT_OUT   		=>  Mult_out,
	  ALU_SET			=>  alu_set,
	  REG_RSEL			=>  reg_rsel,
	  REG_MSEL			=>  reg_msel,
	  POP_LIFO			=>  pop_lifo,
	  POP_FIFO			=>  pop_fifo,
	  PUSH_FIFO			=>  push_fifo_in,
	  PUSH_LIFO			=>  push_lifo_in,
	  RAM_CS				=>  ram_cs,
	  LOAD_FETCH		=>  load_fetch,
	  RAM_ADDR_SEL		=>  ram_sel,
	  TIMER_CS			=>  timer_cs_in,
	  IO_CS				=>  io_cs_in,
	  INTR_RETURN		=>  intr_return,
	  REG_SEL			=>  reg_sel,
	  JMP_PC_SEL		=>  jmp_pc_sel,
	  MULT_SEL			=>  Mult_sel,
	  OPCODE				=>  opcode,
	  regA_SEL			=>  regA_sel, 
	  BAUD_SET			=>  baud,
	  INTERRUPT_CTRL	=>  intr_ctrl,
	  JMP_PC_DATA		=>  jmp_pc_data,
	  RAM_ADDR			=>  ram_addr,
	  RAM_DATAIN		=>  ram_in
	  );

   No4 : DATABUS
	  PORT MAP (
	  data			  => DATA_reg,
	  timer_data_in  => timer_data_in,
	  pc				  => pc,
	  lifo_in		  => lifo_in,
	  fifo_in		  => fifo_in,
	  ioREAD			  => ioREAD,
	  io_data_in	  => io_data_in,
	  portA_out		  => portA_out,
	  portB_out		  => portB_out,
	  alu_out		  => alu_reg,
	  fifo_out		  => fifo_out,
	  lifo_out  	  => lifo_out,
	  regA_sel		  => regA_sel,
	  data_sel 		  => Mult_sel,
	  DATAOUT1		  => Mult_out,
	  regA 			  => registerA,
	  interrupt      => interrupt
      );	
 
 
   No5 : DATA_MEMORY
	  PORT MAP (
	  CLK				 =>  clock,
	  RESET			 =>  reset,
	  RAM_CS			 =>  ram_cs,
	  RAM_ADDR		 =>  ram_addr,
	  RAM_SEL		 =>  ram_sel,
	  RAM_DATA_IN	 =>  ram_in,
	  FULL			 =>  RAM_FULL, 
	  RAM_DATA_OUT	 =>  ram_out
      );	
	
   No6 : ALU
	  PORT MAP (
	  CLK				 =>  clock,
	  RESET			 =>  reset,
	  ALU_SET		 =>  alu_set,
	  regA			 =>  registerA,
	  regB		    =>  Mult_out,
	  OPERAND		 =>  opcode,
	  GT				 =>  GT,
	  LT				 =>  LT,
	  EQ				 =>  EQ,
	  ALU_REGISTER  =>  alu_reg
      );
		
	No7 : LIFO
	  PORT MAP (
	  CLK			  =>	clock,
	  RESET		  =>	reset,
	  PUSH_LIFO	  =>	push_lifo,
	  POP_LIFO 	  =>	pop_lifo,
	  LIFO_IN 	  =>	lifo_in,
	  LIFO_FULL   =>	lifo_full,
	  LIFO_EMPTY  =>	lifo_empty,
	  LIFO_OUT	  =>	lifo_out
      );	
		
   No8 : programMemory
     PORT MAP (
	  CLK       =>	clock,
	  WE   		=> WE,
	  rst			=> reset,
	  data_sig  => data_sig,
	  DATA_reg  => DATA_reg,
	  PC			=> pc,
	  IN_DATA	=> IN_DATA,
	  LOAD_ADDR => LOAD_ADDR,
	  DATA_OUT  => progmem_out
      );
		
   No9 : TIMER
     PORT MAP (
	  CLK				 => clock,
	  RESET			 => reset,
	  Timer_data_in => timer_data_in,
	  timer_cs		 => timer_cs,
	  TON				 => ton
      );

   No10 : FIFO
      PORT MAP (
      CLK			=>	clock,
		RESET			=> reset,
		PUSH_FIFO	=> push_fifo,
		POP_FIFO    => pop_fifo,
		FIFO_IN     => fifo_in,
      FIFO_FULL	=> fifo_full,
		FIFO_EMPTY  => fifo_empty,
		FIFO_OUT    => fifo_out
      );


		
   END behavior;
