library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.util_pkg.all;
entity ALU is
	generic (
		WIDTH : natural := 32);
	port (
	    clk   : in  std_logic;
		a_i   : in  std_logic_vector(WIDTH - 1 downto 0); --first input
		b_i   : in  std_logic_vector(WIDTH - 1 downto 0); --second input
		op_i  : in  alu_op_t; --operation select
		res_o : out std_logic_vector(WIDTH - 1 downto 0)); --result
	--zero_o : out STD_LOGIC; --zero flag
	--of_o   : out STD_LOGIC; --overflow flag
end ALU;

architecture behavioral of ALU is
	attribute use_dsp : string;
	attribute use_dsp of behavioral : architecture is "yes";

	constant l2WIDTH : natural := integer(ceil(log2(real(WIDTH))));
	signal lts_res, ltu_res, add_res, sub_res, or_res, and_res, res_s, xor_res : std_logic_vector(WIDTH - 1 downto 0);
	signal eq_res, sll_res, srl_res, sra_res : std_logic_vector(WIDTH - 1 downto 0);
	signal divu_res, divs_res, rems_res, remu_res : std_logic_vector(WIDTH - 1 downto 0);
	signal muls_res, mulu_res : std_logic_vector(2 * WIDTH - 1 downto 0);
	signal mulsu_res : std_logic_vector(2 * WIDTH + 1 downto 0);
	signal m1_r, m2_r, m3_r, mu1_r, mu2_r, mu3_r : std_logic_vector(2 * WIDTH - 1 downto 0); 
    signal m1_n, m2_n, m3_n, mu1_n, mu2_n, mu3_n : std_logic_vector(2 * WIDTH - 1 downto 0); 
	signal msu1_r, msu2_r, msu3_r : std_logic_vector(2 * WIDTH + 1 downto 0); 
    signal msu1_n, msu2_n, msu3_n : std_logic_vector(2 * WIDTH + 1 downto 0); 
    signal d1_r, d2_r, d3_r : std_logic_vector(WIDTH - 1 downto 0);
    signal d1_n, d2_n, d3_n : std_logic_vector(WIDTH - 1 downto 0);
    signal du1_r, du2_r, du3_r : std_logic_vector(WIDTH - 1 downto 0);
    signal du1_n, du2_n, du3_n : std_logic_vector(WIDTH - 1 downto 0);
    signal r1_r, r2_r, r3_r : std_logic_vector(WIDTH - 1 downto 0); 
    signal r1_n, r2_n, r3_n : std_logic_vector(WIDTH - 1 downto 0);
    signal ru1_r, ru2_r, ru3_r : std_logic_vector(WIDTH - 1 downto 0);
    signal ru1_n, ru2_n, ru3_n : std_logic_vector(WIDTH - 1 downto 0);
begin

	alu : process (a_i, b_i) is begin
		-- addition
		add_res <= std_logic_vector(unsigned(a_i) + unsigned(b_i));
		-- subtraction
		sub_res <= std_logic_vector(unsigned(a_i) - unsigned(b_i));
		-- and gate
		and_res <= a_i and b_i;
		-- or gate
		or_res <= a_i or b_i;
		-- xor gate
		xor_res <= a_i xor b_i;
		-- equal
		  --eq_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) = signed(b_i)) else
		  --std_logic_vector(to_unsigned(0,WIDTH));
		-- less then signed && less then unsigned
		if (a_i < b_i) then
			lts_res <= std_logic_vector(to_unsigned(1, WIDTH));
			ltu_res <= std_logic_vector(to_unsigned(1, WIDTH));
		else
			lts_res <= std_logic_vector(to_unsigned(0, WIDTH));
			ltu_res <= std_logic_vector(to_unsigned(0, WIDTH));
		end if;
		--shift results
		sll_res <= std_logic_vector(shift_left(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
		srl_res <= std_logic_vector(shift_right(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
		sra_res <= std_logic_vector(shift_right(signed(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
--		--multiplication
--		muls_res <= std_logic_vector(signed(a_i) * signed(b_i));
--		mulsu_res <= std_logic_vector(signed(a_i(WIDTH - 1) & a_i) * signed('0' & b_i));
--		mulu_res <= std_logic_vector(unsigned(a_i) * unsigned(b_i));
--		--division && mode
--		if (b_i /= std_logic_vector(to_unsigned(0, WIDTH))) then
--		  divs_res <= std_logic_vector(signed(a_i)/signed(b_i));
--		  divu_res <= std_logic_vector(unsigned(a_i)/unsigned(b_i));
--		  rems_res <= std_logic_vector(signed(a_i) rem signed(b_i));
--		  remu_res <= std_logic_vector(unsigned(a_i) rem unsigned(b_i));
--		else
--          divs_res <= (others => '1');
--          divu_res <= (others => '1');
--          rems_res <= (others => '1');
--          remu_res <= (others => '1');
--		end if;
	end process;
	
	m1_n <= muls_res;
	mu1_n <= mulu_res;
	msu1_n <= mulsu_res;
	d1_n <= divs_res;
	du1_n <= divu_res;
	dsp: process (clk) is begin 
	   if rising_edge(clk) then
    	   m1_r <= std_logic_vector(signed(a_i) * signed(b_i));--muls_res;
    	   m2_r <= m1_r;
    	   m3_r <= m2_r;
           
           mu1_r <= std_logic_vector(unsigned(a_i) * unsigned(b_i));--mulu_res;
           mu2_r <= mu1_r;
           mu3_r <= mu2_r;
           
    	   msu1_r <= std_logic_vector(signed(a_i(WIDTH - 1) & a_i) * signed('0' & b_i));--mulsu_res;
    	   msu2_r <= msu1_r;
    	   msu3_r <= msu2_r;
    	   
--    	   if (b_i /= std_logic_vector(to_unsigned(0, WIDTH))) then
--              d1_r <= std_logic_vector(signed(a_i)/signed(b_i));
--              du1_r <= std_logic_vector(unsigned(a_i)/unsigned(b_i));
--              r1_r <= std_logic_vector(signed(a_i) rem signed(b_i));
--              ru1_r <= std_logic_vector(unsigned(a_i) rem unsigned(b_i));
--            else
--              d1_r <= (others => '1');
--              du1_r <= (others => '1');
--              r1_r <= (others => '1');
--              ru1_r <= (others => '1');
--            end if;
           
----           d1_r <= divs_res;
--           d2_r <= d1_r;
--           d3_r <= d2_r;
           
----           du1_r <= divu_res;
--           du2_r <= du1_r;
--           du3_r <= du2_r;
           
----           r1_r <= rems_res;
--           r2_r <= r1_r;
--           r3_r <= r2_r;
           
----           ru1_r <= remu_res;
--           ru2_r <= ru1_r;
--           ru3_r <= ru2_r;
	   end if;
	end process;

	-- SELECT RESULT
	res_o <= res_s;
	with op_i select
		res_s <=
		and_res when and_op, --and
		or_res when or_op, --or
		xor_res when xor_op, --xor
		add_res when add_op, --add (changed opcode)
		sub_res when sub_op, --sub
		--eq_res when eq_op, -- set equal
		lts_res when lts_op, -- set less than signed
		ltu_res when ltu_op, -- set less than unsigned
		sll_res when sll_op, -- shift left logic
		srl_res when srl_op, -- shift right logic
		sra_res when sra_op, -- shift right arithmetic
		m3_r(WIDTH - 1 downto 0) when mul_op, -- multiply lower
		m3_r(2 * WIDTH - 1 downto WIDTH) when mulh_op, -- multiply higher signed
		msu3_r(2 * WIDTH - 1 downto WIDTH) when mulhsu_op, -- multiply higher signed and unsigned
		mu3_r(2 * WIDTH - 1 downto WIDTH) when mulhu_op, -- multiply higher unsigned
		d3_r when div_op, -- divide unsigned
		du3_r when divu_op, -- divide signed
		r3_r when rem_op, -- reminder signed
		ru3_r when remu_op, -- reminder signed
		
--		mulu_res(WIDTH - 1 downto 0) when mul_op, -- multiply lower
--		muls_res(2 * WIDTH - 1 downto WIDTH) when mulh_op, -- multiply higher signed
--		mulsu_res(2 * WIDTH - 1 downto WIDTH) when mulhsu_op, -- multiply higher signed and unsigned
--		mulu_res(2 * WIDTH - 1 downto WIDTH) when mulhu_op, -- multiply higher unsigned
--		divs_res when div_op, -- divide unsigned
--		divu_res when divu_op, -- divide signed
--		rems_res when rem_op, -- reminder signed
--		remu_res when remu_op, -- reminder signed
		(others => '1') when others;
	-- flag outputs
	-- set zero output flag when result is zero
	--zero_o <= '1' when res_s = std_logic_vector(to_unsigned(0,WIDTH)) else
	--'0';
	-- overflow happens when inputs have same sign, and output has different
	--of_o <= '1' when ((op_i=add_op and (a_i(WIDTH-1)=b_i(WIDTH-1)) and ((a_i(WIDTH-1) xor res_s(WIDTH-1))='1')) or (op_i=sub_op and (a_i(WIDTH-1)=res_s(WIDTH-1)) and ((a_i(WIDTH-1) xor b_i(WIDTH-1))='1'))) else '0';
end behavioral;