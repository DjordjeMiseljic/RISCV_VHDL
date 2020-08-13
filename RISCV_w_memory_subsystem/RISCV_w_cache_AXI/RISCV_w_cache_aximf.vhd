library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity RISCV_w_cache is
	generic (
			C_PHY_ADDR_WIDTH : integer := 32;
			C_TS_BRAM_TYPE : string := "HIGH_PERFORMANCE"; 
			C_BLOCK_SIZE : integer := 64;
			C_LVL1_CACHE_SIZE : integer := 1024*1;  -- 1KB
			C_LVL2_CACHE_SIZE : integer := 1024*4;  -- 4KB
			C_LVL2C_ASSOCIATIVITY : natural := 4
	);
	port (clk : in std_logic;
			ce : in std_logic;
			reset : in std_logic;
			pc_reg_o : out std_logic_vector(31 downto 0);
			--  WRITE CHANNEL
			axi_write_address_o : out std_logic_vector(31 downto 0);
			axi_write_init_o	: out std_logic;
			axi_write_data_o	: out std_logic_vector(31 downto 0);
			axi_write_next_i : in std_logic;
			axi_write_done_i : in std_logic;
			-- READ CHANNEL
			axi_read_address_o : out std_logic_vector(31 downto 0);
			axi_read_init_o	: out std_logic;
			axi_read_data_i	: in std_logic_vector(31 downto 0);
			axi_read_next_i : in std_logic

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

begin

	--********** PROCESSOR CORE **************
	-- Top Moule - RISCV processsor core instance
   TOP_RISCV_1 : entity work.TOP_RISCV
      port map (
         clk => clk,
			ce => ce,
         reset => reset,
         instr_ready_i => instr_ready_s,
		 data_ready_i => data_ready_s,
		 fencei_o => fencei_s,
         pc_reg_o => pc_reg_o,

         instr_mem_read_i    => dread_instr_cache_s,
         instr_mem_address_o => addr_instr_cache_32_s,

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
		generic map(
			C_PHY_ADDR_WIDTH => C_PHY_ADDR_WIDTH,
			C_TS_BRAM_TYPE  => C_TS_BRAM_TYPE,
			C_BLOCK_SIZE  => C_BLOCK_SIZE,
			C_LVL1_CACHE_SIZE => C_LVL1_CACHE_SIZE,
			C_LVL2_CACHE_SIZE => C_LVL2_CACHE_SIZE,
			C_LVL2C_ASSOCIATIVITY => C_LVL2C_ASSOCIATIVITY
		);
		port map(
			clk => clk,
			ce => ce,
			reset => reset,
			data_ready_o => data_ready_s,
			instr_ready_o => instr_ready_s,
			fencei_i => fencei_s,
			-- Interface with Main memory via AXI Full Master
			axi_write_address_o => axi_write_address_o,
			axi_write_init_o	=> axi_write_init_o,
			axi_write_data_o	=> axi_write_data_o,
			axi_write_next_i => axi_write_next_i,
			axi_write_done_i => axi_write_done_i,
			axi_read_address_o => axi_read_address_o,
			axi_read_init_o	=> axi_read_init_o,
			axi_read_data_i	=> axi_read_data_i,
			axi_read_next_i => axi_read_next_i,
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
end architecture;
