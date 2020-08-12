library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity caching_subsystem_only is
	port (clk : in std_logic;
			reset : in std_logic;
			-- just for timing
			instr_o	: out std_logic_vector(31 downto 0);
			data_o	: out std_logic_vector(31 downto 0);
			-- NOTE Just for test bench, to simulate real memory
			addr_phy_o 		: out std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
			dread_phy_i 	: in std_logic_vector(31 downto 0);
			dwrite_phy_o	: out std_logic_vector(31 downto 0);
         we_phy_o			: out std_logic
			);
end entity;

architecture Behavioral of caching_subsystem_only is

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
	signal we_phy_s			: std_logic;

	-- DUMMY SINGALS
	signal counter1_next,counter1_reg : std_logic_vector(31 downto 0);
	signal counter2_next,counter2_reg : std_logic_vector(31 downto 0);
	signal counter3_next,counter3_reg : std_logic_vector(31 downto 0);

begin

	--********** FAKE PROCESSOR CORE FOR TIMING ANALYSIS**************

	instr_o <= dread_instr_cache_s;
	data_o <= dread_data_cache_s;

	addr_instr_cache_32_s <= counter1_reg;
	we_data_cache_s <= counter3_reg(4 downto 1);
	re_data_cache_s <= counter3_reg(0);
	addr_data_cache_32_s <= counter2_reg;
	dwrite_data_cache_s <= counter3_reg;
	fencei_s <= counter3_reg(10);

	garbage : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset= '0')then
				counter1_reg <= (others=>'0');
				counter2_reg <= (others=>'0');
				counter3_reg <= (others=>'0');
			else
				counter1_reg <= counter1_next;
				counter2_reg <= counter2_next;
				counter3_reg <= counter3_next;
			end if;
		end if;
	end process;
	counter1_next <= std_logic_vector(unsigned(counter1_reg) + to_unsigned(4,PHY_ADDR_WIDTH));
	counter2_next <= std_logic_vector(unsigned(counter2_reg) + to_unsigned(3,PHY_ADDR_WIDTH));
	counter3_next <= std_logic_vector(unsigned(counter3_reg) + to_unsigned(1,PHY_ADDR_WIDTH));

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
