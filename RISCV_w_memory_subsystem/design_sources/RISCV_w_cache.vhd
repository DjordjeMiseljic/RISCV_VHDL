library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity RISCV_w_cache is
	port (clk : in std_logic;
			reset : in std_logic;
			-- NOTE Just for test bench, to simulate real memory
			addr_phy_o 		: out std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
			dread_phy_i 		: in std_logic_vector(31 downto 0);
			dwrite_phy_o		: out std_logic_vector(31 downto 0);
         we_phy_o			: out std_logic_vector(3 downto 0)
			);
end entity;

architecture Behavioral of RISCV_w_cache is

   -- Instruction cache signals
	signal addr_instr_cache_s : std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
	signal addr_instr_cache_32_s : std_logic_vector(31 downto 0);
	signal dread_instr_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);

	-- Data cache signals
	signal addr_data_cache_s : std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
	signal addr_data_cache_32_s : std_logic_vector(31 downto 0);
	signal dwrite_data_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
	signal dread_data_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0); 
	signal we_data_cache_s : std_logic_vector(C_NUM_COL-1 downto 0);
	signal en_data_cache_s : std_logic;
	signal rst_data_cache_s : std_logic;
	signal re_data_cache_s : std_logic; 

	-- Other signals
	signal instr_ready_s : std_logic;
	signal data_ready_s : std_logic;
	signal fencei_s : std_logic;


	-- NOTE Just for test bench, to simulate real memory, additional signals needed
	signal addr_phy_s 		: std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
	signal dread_phy_s 	: std_logic_vector(31 downto 0);
	signal dwrite_phy_s		: std_logic_vector(31 downto 0);
	signal we_phy_s			: std_logic_vector(3 downto 0);

begin

	--********** PROCESSOR CORE **************
	-- Top Moule - RISCV processsor core instance
   TOP_RISCV_1 : entity work.TOP_RISCV
      port map (
         clk => clk,
         reset => reset,
         instr_ready_i => instr_ready_s,
			data_ready_i => data_ready_s,
			fencei_o => fencei_s,

         instr_mem_read_i    => dread_instr_cache_s,
         instr_mem_address_o => addr_instr_cache_32_s,
         --instr_mem_flush_o   => rst_instr_cache_s,
         --instr_mem_en_o      => en_instr_cache_s,

         data_mem_we_o      => we_data_cache_s,
         data_mem_re_o      => re_data_cache_s,
         data_mem_address_o => addr_data_cache_32_s,
         data_mem_read_i    => dread_data_cache_s,
         data_mem_write_o   => dwrite_data_cache_s);



	-- Convert 32 bit adress to exact size based on CACHE SIZE parameter
	addr_data_cache_s <= addr_data_cache_32_s((PHY_ADDR_WIDTH-1) downto 0);
	addr_instr_cache_s <= addr_instr_cache_32_s((PHY_ADDR_WIDTH-1) downto 0);

	--********** Memory subsystem **************
	-- 2 levels of caches + required controllers
	cc_nway: entity work.cache_contr_nway_vnv(behavioral)
		port map(
			clk => clk,
			reset => reset,
			data_ready_o => data_ready_s,
			instr_ready_o => instr_ready_s,
			fencei_i => fencei_s,
			-- NOTE Just for test bench, to simulate real memory
			addr_phy_o => addr_phy_s,
			dread_phy_i => dread_phy_s,
			dwrite_phy_o => dwrite_phy_s,
			we_phy_o => we_phy_s,
			-- Instruction cache
			addr_instr_i => addr_instr_cache_s,
			dread_instr_o => dread_instr_cache_s,
			-- Data cache
			addr_data_i => addr_data_cache_s,
			dread_data_o => dread_data_cache_s,
			dwrite_data_i => dwrite_data_cache_s,
			we_data_i => we_data_cache_s,
			re_data_i => re_data_cache_s
		);

--	Dummy ports so Vivado wouldn't "optimize" the entire design for now
	--dread_instr <= dread_instr_cache_s;
	--dread_data <= dread_data_cache_s;

-- Physical memory interface
	addr_phy_o <= addr_phy_s;
	dread_phy_s <= dread_phy_i;
	dwrite_phy_o <= dwrite_phy_s;
	we_phy_o <= we_phy_s;

end architecture;
