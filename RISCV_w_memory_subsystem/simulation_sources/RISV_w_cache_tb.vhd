---------------------------------------------------------------------------------
-- Created by		: 
-- Filename			: tb_RISCV_w_cache.vhd
-- Author			: ChenYong
-- Created On		: 2020-06-22 17:47
-- Last Modified	: 2020-06-24 02:57
-- Version			: v1.0
-- Description		: 
--						
--						
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.cache_pkg.all;

entity tb_RISCV_w_cache is
end tb_RISCV_w_cache;

architecture behavior of tb_RISCV_w_cache is

	-- Component Declaration for the Unit Under Test (UUT)
	component RISCV_w_cache is
	port (
		clk				: in	std_logic;
		reset			: in	std_logic;
		addr_phy_o		: out	std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
		dread_phy_i		: in	std_logic_vector(31 downto 0);
		dwrite_phy_o	: out	std_logic_vector(31 downto 0);
		we_phy_o		: out	std_logic_vector(3 downto 0);
		dread_instr		: out	std_logic_vector(31 downto 0);
		dread_data		: out	std_logic_vector(31 downto 0)
	);
	end component;
	    
	constant C_SHRINK_ADDR_WIDTH : integer := 10;
    constant C_SHRINK_ADDR_SPACE    : integer := 2**C_SHRINK_ADDR_WIDTH;
	-- Inputs
	signal	clk				: std_logic:='0';
	signal	reset			: std_logic:='0';
	signal	dread_phy_i		: std_logic_vector(31 downto 0):=(others=>'0');

	-- Outputs
	signal	addr_phy_s		: std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
    signal	addr_phy_short_s: std_logic_vector(PHY_ADDR_WIDTH-C_SHRINK_ADDR_WIDTH-3 downto 0);

	signal	dwrite_phy_s	: std_logic_vector(31 downto 0);
	signal	we_phy_s		: std_logic_vector(3 downto 0);
	signal	dread_phy_s		: std_logic_vector(31 downto 0);
	signal	en_phy_s		: std_logic;
	signal	regce_phy_s		: std_logic;
	signal	rst_phy_s		: std_logic;

    signal	dread_data_s		: std_logic_vector(31 downto 0);
	signal	dread_instr_s		: std_logic_vector(31 downto 0);

	-- Clock period definitions
	constant clk_period : time := 10 ns;
   

begin
	
	
	RISCV_w_cache_inst : RISCV_w_cache
	port map(
		clk				=>	clk,
		reset			=>	reset,
		addr_phy_o		=>	addr_phy_s,
		dread_phy_i		=>	dread_phy_s,
		dwrite_phy_o	=>	dwrite_phy_s,
		we_phy_o		=>	we_phy_s,
		dread_instr		=>	dread_instr_s,
		dread_data		=>	dread_data_s
	);

	-- Clock process definitions
	process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process;

    addr_phy_short_s <= addr_phy_s(PHY_ADDR_WIDTH-C_SHRINK_ADDR_WIDTH-1 downto 2);
	rst_phy_s <= '0';
	en_phy_s <= '1';
	regce_phy_s <= '1';
	physical_memory : entity work.RAM_sp_rf_bw(rtl)
		generic map (
				NB_COL => 4,
				COL_WIDTH => 8,
				RAM_DEPTH => ((2**(PHY_ADDR_WIDTH-C_SHRINK_ADDR_WIDTH))/4), -- -2 to address 4 bytes in a word
				RAM_PERFORMANCE => "LOW_LATENCY",
				INIT_FILE => "/home/fouste/Uni/RISCV_VHDL/RV32I/simulation_sources/assembly_code.txt" 
		)
		port map  (
				clk   => clk,
				addra  => addr_phy_short_s,
				dina   => dwrite_phy_s,
				wea    => we_phy_s,
				ena    => en_phy_s,
				rsta   => rst_phy_s,
				regcea => regce_phy_s,
				douta  => dread_phy_s
		);

	-- Stimulus process
	process
	begin
		-- hold reset state for 100 ns
		wait for 15 ns;
		reset <= '1';

		wait for 10000 ns;

		-- Add stimulus here

		wait;
	end process;

end behavior;

