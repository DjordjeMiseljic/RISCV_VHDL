LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- Arithmetic Logic Unit (ALU)
-- OP:
-- 00 00 -> bitwise and
-- 00 01 -> bitwise or
-- 00 10 -> bitwise xor
-- 00 11 -> add a_i and b_i 
-- 10 11 -> sub a_i and b_i
-- 11 00 -> set less than signed
-- 11 01 -> set less than unsigned

ENTITY ALU IS
	GENERIC(
		WIDTH : NATURAL := 32);
	PORT(
		a_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		b_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		op_i  :  IN   STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
		res_o   :  OUT  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		zero_o   :  OUT  STD_LOGIC; --zero flag
		of_o   :  OUT  STD_LOGIC); --overflow flag
END ALU;

ARCHITECTURE behavioral OF ALU IS

	SIGNAL    binv_cin_s : STD_LOGIC;
	SIGNAL    op_s      : STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL 	 carry, of_s : STD_LOGIC;
	SIGNAL    lts_res,ltu_res,adder_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL    sll_res,srl_res,sra_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL 	 adder_res_tmp : STD_LOGIC_VECTOR(WIDTH DOWNTO 0);
	SIGNAL    a_s,b_s   :    STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL    nota_s,notb_s   :    STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

BEGIN

	-- control signals
	binv_cin_s<=op_i(4); --signal for inverting b input, and carry_in to adder at the same time
	op_s<=op_i(3 downto 0);
	-- semantics
	a_s <= a_i;
	--invert b_s depending on binv signal
	b_s <= b_i when binv_cin_s = '0' else
			 not b_i;
	

	-- GENERATE ARITHMETIC OPERATIONS
	adder_res_tmp <= unsigned('0' & a_s) + unsigned('0' & b_s) + unsigned(conv_std_logic_vector(0,WIDTH-1)&binv_cin_s);
	carry <= adder_res_tmp(WIDTH);
	adder_res <= adder_res_tmp	(WIDTH-1 downto 0);
	-- and gate
	and_res <= a_s and b_s;
	-- or gate
	or_res <= a_s or b_s;
	-- xor gate
	xor_res <= a_s xor b_s;
	-- a_i is less than b_i if the result of their subtraction is negative and no ovorflow occured [SIGNED]
	lts_res <= conv_std_logic_vector(1,WIDTH) when (adder_res(WIDTH-1) = '1' and of_s = '0') else
					conv_std_logic_vector(0,WIDTH);
	-- a_i is less than b_i if the result of their subtraction is negative [UNSIGNED]
	ltu_res <= conv_std_logic_vector(1,WIDTH) when (adder_res(WIDTH-1) = '1') else
					conv_std_logic_vector(0,WIDTH);

	--shift results
	sll_res <= a_s sll b_s;
	srl_res <= a_s srl b_s;
	sra_res <= a_s sra b_s;
					

	-- SELECT RESULT
	res_o <= res_s;
	with op_s select
		res_s <= and_res when "0000", --and
					or_res when "0001", --or
					xor_res when "0010", --xor
					adder_res when "0011", --add, sub
					lts_res when "0100", -- set less than signed
					ltu_res when "0101", -- set less than unsigned
					sll_res when "0110", -- set less than unsigned
					srl_res when "0111", -- set less than unsigned
					sra_res when others; -- set less than unsigned


	-- FLAG OUTPUTS
	-- set zero output flag when result is zero
	zero_o <= '1' when res_s = conv_std_logic_vector(0,WIDTH) else
				 '0';
	--overflow
	of_o <= of_s;
	-- overflow happens when inputs are of same sign, and output is of different
	of_s <= '1' when ((a_s(WIDTH-1) = b_s(WIDTH-1)) and (a_s(WIDTH-1) xor adder_res(WIDTH-1))='1') else
			  '0';


END behavioral;
