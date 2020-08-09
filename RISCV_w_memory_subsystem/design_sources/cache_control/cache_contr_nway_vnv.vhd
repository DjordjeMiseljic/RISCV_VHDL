library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity cache_contr_nway_vnv is
	port (clk : in std_logic;
			reset : in std_logic;
			-- controller drives ce for RISC
			data_ready_o : out std_logic;
			instr_ready_o : out std_logic;
			fencei_i : in std_logic;
			-- NOTE Just for test bench, to simulate real memory
			addr_phy_o 			: out std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
			dread_phy_i 		: in std_logic_vector(31 downto 0);
			dwrite_phy_o		: out std_logic_vector(31 downto 0);
         we_phy_o				: out std_logic;
			-- Level 1 caches
			-- Instruction cache
			addr_instr_i 		: in std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
			dread_instr_o 		: out std_logic_vector(31 downto 0);
			-- Data cache
			addr_data_i			: in std_logic_vector(PHY_ADDR_WIDTH-1 downto 0);
			dread_data_o 		: out std_logic_vector(31 downto 0);
			dwrite_data_i		: in std_logic_vector(31 downto 0);
         we_data_i			: in std_logic_vector(3 downto 0);
         re_data_i			: in std_logic
			);
end entity;

architecture Behavioral of cache_contr_nway_vnv is

	-- SIGNALS FOR INTERACTION WITH RAMS
	--*******************************************************************************************
	-- Level 1 cache signals
	-- Instruction cache signals
	signal addra_instr_cache_s : std_logic_vector((LVL1C_ADDR_WIDTH-3) downto 0); --(-2 bits because byte in 32-bit word is not adressible) 
	signal dwritea_instr_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
	signal dreada_instr_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
	signal wea_instr_cache_s : std_logic;
	signal ena_instr_cache_s : std_logic;
	-- Instruction cache tag store singals
	signal dwritea_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal dreada_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal addra_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_instr_tag_s : std_logic;
	signal wea_instr_tag_s : std_logic;
	-- Data cache signals
	signal clk_data_cache_s : std_logic;
	signal addra_data_cache_s : std_logic_vector((LVL1C_ADDR_WIDTH-3) downto 0); --(-2 bits because byte in 32-bit word is not adressible)
	signal dwritea_data_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
	signal dreada_data_cache_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0); 
	signal wea_data_cache_s : std_logic_vector(C_NUM_COL-1 downto 0);
	signal ena_data_cache_s : std_logic; 
	signal rsta_data_cache_s : std_logic; 
	signal regcea_data_cache_s : std_logic;
	-- Data cache tag store singals
	signal dwritea_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto 0);
	signal dreada_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto 0);
	signal addra_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_data_tag_s : std_logic;
	signal regcea_data_tag_s : std_logic;
	signal rsta_data_tag_s : std_logic;
	signal wea_data_tag_s : std_logic;
	-- Level 2 cache signals
	-- type definitions
	type lvl2_addr_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector((LVL2C_ADDR_WIDTH-3) downto 0); 
	type lvl2_data_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
	type lvl2_we_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic;
	type lvl2_addr_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	type lvl2_data_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH+LVL2C_NWAY_BKK_WIDTH-1 downto 0);
	type lvl2_we_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic;
	-- port A
	signal addra_lvl2_cache_s : lvl2_addr_c_t;
	signal dwritea_lvl2_cache_s : lvl2_data_c_t;
	signal dreada_lvl2_cache_s : lvl2_data_c_t;
	signal wea_lvl2_cache_s : lvl2_we_c_t;
	signal ena_lvl2_cache_s : std_logic;
	signal rsta_lvl2_cache_s : std_logic;
	signal regcea_lvl2_cache_s : std_logic;
	-- port B
	signal addrb_lvl2_cache_s : lvl2_addr_c_t;
	signal dwriteb_lvl2_cache_s : lvl2_data_c_t;
	signal dreadb_lvl2_cache_s : lvl2_data_c_t;
	signal web_lvl2_cache_s : lvl2_we_c_t;
	signal enb_lvl2_cache_s : std_logic;
	signal rstb_lvl2_cache_s : std_logic;
	signal regceb_lvl2_cache_s : std_logic;
	-- Level 2 cache tag store singnals
	-- port A
	signal dwritea_lvl2_tag_s : lvl2_data_ts_t;
	signal dreada_lvl2_tag_s : lvl2_data_ts_t;
	signal addra_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	signal ena_lvl2_tag_s : std_logic;
	signal rsta_lvl2_tag_s : std_logic;
	signal wea_lvl2_tag_s : lvl2_we_ts_t;
	signal regcea_lvl2_tag_s : std_logic;
	-- port B
	signal dwriteb_lvl2_tag_s : lvl2_data_ts_t;
	signal dreadb_lvl2_tag_s : lvl2_data_ts_t;
	signal addrb_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	signal enb_lvl2_tag_s : std_logic;
	signal rstb_lvl2_tag_s : std_logic;
	signal web_lvl2_tag_s : lvl2_we_ts_t;
	signal regceb_lvl2_tag_s : std_logic;
--*******************************************************************************************


	-- SIGNALS FOR SEPARATING INPUT ADRESS PORTS INTO FIELDS
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for data cache
	signal lvl1da_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1da_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1da_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1da_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from data tag store
	signal lvl1da_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1da_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal lvl1ia_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ia_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1ia_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1ia_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from instruction tag store
	signal lvl1ia_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ia_ts_valid_reg, lvl1ia_ts_valid_next : std_logic_vector(LVL1C_NB_BLOCKS-1 downto 0);

	-- 'tag', 'index' level2 cache
	signal lvl2a_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2a_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for level2 cache
	-- For level2 from data adress
	signal lvl2ia_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2ia_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2ia_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- For level2 from instrucion adress
	signal lvl2da_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2da_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2da_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- These are needed for flushing and invalidating previously stored blocks 
	-- For level2 from data adress
	signal lvl2dl_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2dl_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2dl_c_addr_s : std_logic_vector(LVL1C_INDEX_WIDTH+LVL1C_TAG_WIDTH-1 downto 0);
	-- For level2 from instrucion adress
	signal lvl2il_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2il_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2il_c_addr_s : std_logic_vector(LVL1C_INDEX_WIDTH+LVL1C_TAG_WIDTH-1 downto 0);

	-- SIGNALS FOR SEPARATING LEVEL2 TAG STORE DATA INTO USEFULL FIELDS
	type lvl2_ts_tag_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	type lvl2_ts_bkk_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);
	type lvl2_ts_nbkk_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_NWAY_BKK_WIDTH-1 downto 0);
	-- port A
	signal lvl2a_ts_tag_s : lvl2_ts_tag_t; -- stored tag
	signal lvl2a_ts_bkk_s : lvl2_ts_bkk_t; -- bookkeeping, 4 bits : [Data,Instr,Dirty,Valid]
	signal lvl2a_ts_nbkk_s : lvl2_ts_nbkk_t; -- nway bookkeeping, 2 bits : [Victim, NextVictim]
	-- port B
	signal lvl2b_ts_tag_s : lvl2_ts_tag_t; -- stored tag
	signal lvl2b_ts_bkk_s : lvl2_ts_bkk_t; -- bookkeeping, 4 bits : [Data,Instr,Dirty,Valid]
	signal lvl2b_ts_nbkk_s : lvl2_ts_nbkk_t; -- nway bookkeeping, 2 bits : [Victim, NextVictim]

	-- Singals for indexing one of N ways in associative level2 cache
	signal lvl2_hit_index : integer;
	signal lvl2_dflush_index : integer;
	signal lvl2_iflush_index : integer;
	signal lvl2_invalid_index : integer;
	signal lvl2_victim_index : integer;
	signal lvl2_nextv_index : integer;
	signal lvl2_rando_index : integer;
	-- Invalid found flag, no need to evict block that is valid if there is invalid one
	signal lvl2_invalid_found_s : std_logic;

	-- Maps - specific bits from tag store, extracted into single vector - for easier use
	signal lvl2_victim_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_nextv_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_vnv_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);

	-- NOTE Design For Simulation signals : use only when debugging, remove for release
	-- They are not connected to anything and will probably be trimmed during synthesis
	signal lvl2_d4s_valid_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_d4s_dirty_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_d4s_data_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_d4s_instr_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);


	-- Signals for comparing tag values
	signal lvl1ii_tag_cmp_s  : std_logic; -- incoming instruction address VS instruction tag store (hit in instruction cache)
	signal lvl1dd_tag_cmp_s  : std_logic; -- incoming data address VS data tag store (hit in data cache)
	signal lvl2a_tag_cmp_s  : std_logic; -- incoming address from missed lvl1 i/d cache VS lvl2 tag store
	-- Signals to indicate cache hits/misses
	signal lvl1da_c_hit_s  : std_logic; -- hit in data cache
	signal lvl1ia_c_hit_s  : std_logic; -- hit in instruction cache
	signal lvl2a_c_hit_s  : std_logic; -- hit in lvl 2 cache

	-- Additional signals for communicating with core
	signal lvl1_valid_s  : std_logic; -- hit in instruction cache
	signal data_access_s  : std_logic; -- data adress coming from processor is actual memory acess instruction
	signal data_ready_s  : std_logic; -- requested data is in data cache, processor can continue executing
	signal instr_ready_s  : std_logic; -- requested data is in instruction cache, processor can continue executing
	-- Additional signals for communicating between lvl1FSM and lvl2FSM
	signal check_lvl2_s  : std_logic; -- miss in lvl1, tell lvl2FSM to check in lvl2
	signal flush_lvl1d_s  : std_logic; -- lvl2FSM is signaling lvl1FSM to flush data to lvl2
	signal invalidate_lvl1d_s  : std_logic; -- lvl2FSM is signaling lvl1FSM to invalidate block
	signal invalidate_lvl1i_s  : std_logic; -- lvl2FSM is signaling lvl1FSM to invalidate block

	signal bram_read_rdy_reg  : std_logic := '0'; -- lvl2FSM is signaling lvl1FSM to invalidate block
	signal bram_read_rdy_next  : std_logic := '0'; -- lvl2FSM is signaling lvl1FSM to invalidate block
	-- Cache controler state 
	-- LVL1 FSM - "cache controller" - communication between lvl1 and lvl2 caches
	type cc_state is (idle, set_dirty, check_lvl2_instr, check_lvl2_data,
		 fetch_instr, fetch_data, flush_data, flush_dependent_data, update_data_ts, update_instr_ts, invalidate_data);
	signal cc_state_reg, cc_state_next: cc_state;
	-- LVL2 FSM - "memory controller" - communication between lvl2 and physical memory (DDR RAM)
	type mc_state is (idle, flush, fetch); 
	signal mc_state_reg, mc_state_next: mc_state;
	-- Counters for indexing bytes in block when transfering block
	-- (-2) because 4 bytes are written at once, 32 bit bus - 4 bytes 
	signal cc_counter_reg, cc_counter_incr, cc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	signal mc_counter_reg, mc_counter_incr, mc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	-- Signals for "evictor" counter that chooses next victim randomly
	signal evictor_reg, evictor_next, evictor_rotr1, evictor_rotr2, evictor_rotr3 : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	-- Usefull constants for checking end and begining of bloc transfer
	constant COUNTER_MAX : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'1');
	constant COUNTER_MIN : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'0');
	constant COUNTER_ONE : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := std_logic_vector(to_unsigned(1,BLOCK_ADDR_WIDTH-2));

begin

	-- Separate input adresses into fields for easier menagment
	-- Signals for level 1 cache
	-- From processor data address
	lvl1da_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1da_c_idx_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1da_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1da_c_addr_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From processor instruction address
	lvl1ia_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1ia_c_idx_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1ia_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1ia_c_addr_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- Signals for level 2 cache
	-- From processor data address
	lvl2da_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2da_c_idx_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2da_c_addr_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto 0);
	-- From processor instruction address
	lvl2ia_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2ia_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2ia_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);
	-- These are for flushing and invalidating, need saved address not current
	-- From data tag store / data address
	lvl2dl_c_addr_s <= lvl1da_ts_tag_s & lvl1da_c_idx_s;
	lvl2dl_c_idx_s <= lvl2dl_c_addr_s(LVL2C_INDEX_WIDTH-1 downto 0);
	lvl2dl_c_tag_s <= lvl2dl_c_addr_s(LVL2C_INDEX_WIDTH+LVL2C_TAG_WIDTH-1 downto LVL2C_INDEX_WIDTH);
	-- From instruction tag store / instruction address
	lvl2il_c_addr_s <= lvl1ia_ts_tag_s & lvl1ia_c_idx_s;
	lvl2il_c_idx_s <= lvl2il_c_addr_s(LVL2C_INDEX_WIDTH-1 downto 0);
	lvl2il_c_tag_s <= lvl2il_c_addr_s(LVL2C_INDEX_WIDTH+LVL2C_TAG_WIDTH-1 downto LVL2C_INDEX_WIDTH);
	-- Forward address and get tag + bookkeeping bits from tag store
	-- Data tag store port A - data address
	lvl1da_ts_tag_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	lvl1da_ts_bkk_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- Instruction tag store port A - instruction address
	lvl1ia_ts_tag_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH-1 downto 0);

	-- Process for extracting feilds for all N ways of lvl2 tag store
	extract_lvl2_ts_fields: process (dreada_lvl2_tag_s, dreadb_lvl2_tag_s) is
	begin
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
			-- PORT A
			lvl2a_ts_tag_s(i) <= dreada_lvl2_tag_s(i)(LVL2C_TAG_WIDTH-1 downto 0); 
			lvl2a_ts_bkk_s(i) <= dreada_lvl2_tag_s(i)(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH); 
			lvl2a_ts_nbkk_s(i) <= dreada_lvl2_tag_s(i)(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH+LVL2C_NWAY_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH);
			-- PORT B
			lvl2b_ts_tag_s(i) <= dreadb_lvl2_tag_s(i)(LVL2C_TAG_WIDTH-1 downto 0); 
			lvl2b_ts_bkk_s(i) <= dreadb_lvl2_tag_s(i)(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH); 
			lvl2b_ts_nbkk_s(i) <= dreadb_lvl2_tag_s(i)(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH+LVL2C_NWAY_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH);
		end loop;
	end process;

	extract_vnv_map: process (lvl2a_ts_nbkk_s) is
	begin
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
		   lvl2_victim_map(i) <= lvl2a_ts_nbkk_s(i)(LVL2C_BKK_VICTIM);
			lvl2_nextv_map(i)  <= lvl2a_ts_nbkk_s(i)(LVL2C_BKK_NEXTV);
		end loop;
	end process;

	--************************* SEQUENTIAL LOGIC - REGISTERS *************************
	lvl1i_ts_valid : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset = '0' or fencei_i = '1')then --or "FENCE.I SIGNAL COMING FROM CONTROL FLOW" 
				lvl1ia_ts_valid_reg <= (others => '0');
			else
				lvl1ia_ts_valid_reg <= lvl1ia_ts_valid_next;
			end if;
		end if;
	end process;

	registers : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset= '0')then
				cc_state_reg <= idle;
				cc_counter_reg <= (others => '0');
				mc_state_reg <= idle;
				mc_counter_reg <= (others => '0');
				evictor_reg <= std_logic_vector(to_unsigned(1,LVL2C_ASSOCIATIVITY));
			else
				cc_state_reg <= cc_state_next;
				cc_counter_reg <=  cc_counter_next;
				mc_state_reg <= mc_state_next;
				mc_counter_reg <=  mc_counter_next;
				evictor_reg <= evictor_next;
			end if;
		end if;
	end process;
	

	hp_bram_reg : if TS_BRAM_TYPE = "HIGH_PERFORMANCE" generate
	bram_read_clk_delay : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset= '0')then
				bram_read_rdy_reg <= '0';
			else
				bram_read_rdy_reg <= bram_read_rdy_next;
			end if;
		end if;
	end process;
	end generate;
	

	--************************* COMBINATIONAL LOGIC *************************
	-- Compare tags for lvl1 caches
	lvl1dd_tag_cmp_s <= '1' when lvl1da_c_tag_s = lvl1da_ts_tag_s else '0';
	lvl1ii_tag_cmp_s <= '1' when lvl1ia_c_tag_s = lvl1ia_ts_tag_s else '0';

	-- Cache hit/miss indicator flags => same tag + valid
	lvl1da_c_hit_s <= lvl1dd_tag_cmp_s and lvl1da_ts_bkk_s(0); 
	lvl1ia_c_hit_s <= lvl1ii_tag_cmp_s and lvl1ia_ts_valid_reg(to_integer(unsigned(addra_instr_tag_s)));

	-- Data acess indicator, 1 if instruction is data access
   data_access_s <= '1' when ((we_data_i /= "0000") or (re_data_i='1')) else '0';

	-- Indicates if requiered data is in lvl1 cache
	-- 1 => processor continues
	-- 0 => processor stalls until data ready
	--data_ready_s <= ((lvl1da_c_hit_s or (not data_access_s)) and lvl1_valid_s);
	data_ready_s <= (lvl1da_c_hit_s or (not data_access_s)) when lvl1_valid_s = '1' else '0';
	data_ready_o <= data_ready_s;
	--instr_ready_s <= (lvl1ia_c_hit_s and lvl1_valid_s);
	instr_ready_s <= lvl1ia_c_hit_s; --  when lvl1_valid_s ='1' else '0';
	instr_ready_o <= instr_ready_s;

	-- Adders for byte in block counters 
	cc_counter_incr <= std_logic_vector(unsigned(cc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH-2));
	mc_counter_incr <= std_logic_vector(unsigned(mc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH-2));


	-- Evictor logic: Swich trough ordinary blocks every clock cycle
	-- Implemented as shift rather than addition to propagation time
	-- Actual index is found using priority coder labeled as: pcoder_rando_index 
	evictor_rotr1 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 1));
	evictor_rotr2 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 2));
	evictor_rotr3 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 3));
	lvl2_vnv_map <= (lvl2_victim_map or lvl2_nextv_map);
	evictor_logic: process(lvl2_vnv_map, evictor_rotr1, evictor_rotr2, evictor_rotr3) is 
	begin
		if ((evictor_rotr1 and lvl2_vnv_map) = std_logic_vector(to_unsigned(0,LVL2C_ASSOCIATIVITY))) then
			evictor_next <= evictor_rotr1;
		elsif ((evictor_rotr2 and lvl2_vnv_map) = std_logic_vector(to_unsigned(0,LVL2C_ASSOCIATIVITY))) then
			evictor_next <= evictor_rotr2;
		else 
			evictor_next <= evictor_rotr3;
		end if;
	end process;

	-- Priority coder to find index of random ordinary block based on evictor map
	pcoder_rando_index: process(evictor_reg) is 
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if (evictor_reg(i) = '1') then
				lvl2_rando_index <= i;
				exit;
			else
				lvl2_rando_index <= 0;
			end if;
		end loop;
	end process;

	-- Priority coder to find index of invalid block if it exists
	invalid_pcoder: process (lvl2a_ts_bkk_s,lvl2a_ts_nbkk_s) is
	begin
			for i in(LVL2C_ASSOCIATIVITY-1) downto 0 loop
				if (lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='0' and lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='0' and lvl2a_ts_nbkk_s(i) = "00") then
					lvl2_invalid_index <= i;
					lvl2_invalid_found_s <= '1';
					exit;
				else
					lvl2_invalid_index <= 0;
					lvl2_invalid_found_s <= '0';
				end if;
			end loop;
	end process;

	-- Priority coder to find index of hit block (that contains required data) if it exists
	pcoder_hit_detect: process(lvl2a_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if ((lvl2a_c_tag_s = lvl2a_ts_tag_s(i)) and lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='1') then
				lvl2_hit_index <= i;
				lvl2a_c_hit_s <= '1';
				exit;
			else
				lvl2_hit_index <= 0;
				lvl2a_c_hit_s <= '0';
			end if;
		end loop;
	end process;

	-- Priority coder to find index of blocks used for flushing and invalidating
	dflush: process(lvl2dl_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if ((lvl2dl_c_tag_s = lvl2a_ts_tag_s(i)) and (lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='1' or lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='1')) then
				lvl2_dflush_index <= i;
				exit;
			else
				lvl2_dflush_index <= 0;
			end if;
		end loop;
	end process;
	iflush: process(lvl2il_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if ((lvl2il_c_tag_s = lvl2a_ts_tag_s(i)) and (lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='1' or lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='1')) then
				lvl2_iflush_index <= i;
				exit;
			else
				lvl2_iflush_index <= 0;
			end if;
		end loop;
	end process;

	-- Priority coder to find index of victim block
	pcoder_victim_detect: process (lvl2a_ts_nbkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if (lvl2a_ts_nbkk_s(i)(LVL2C_BKK_VICTIM)= '1') then
				lvl2_victim_index <= i;
				exit;
			else
				lvl2_victim_index <= 0;
			end if;
		end loop;
	end process;

	-- Priority coder to find index of nextvictim block
	pcoder_nextv_detect: process (lvl2a_ts_nbkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if (lvl2a_ts_nbkk_s(i)(LVL2C_BKK_NEXTV)= '1') then
				lvl2_nextv_index <= i;
				exit;
			else
				lvl2_nextv_index <= 1;
			end if;
		end loop;
	end process;
	
	-- NOTE Design For Simulation, Use only for debugging. DELETE BEFORE RELEASE
	design_for_simulation_map: process (lvl2a_ts_bkk_s) is 
	begin
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
		   lvl2_d4s_data_map(i) <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_DATA);
			lvl2_d4s_instr_map(i)  <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_INSTR);
		   lvl2_d4s_valid_map(i) <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID);
			lvl2_d4s_dirty_map(i)  <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY);
		end loop;
	end process;


	-- TODO check this: if processor never writes to instr cache, it doesn't need dirty bit
	-- Cache controller
	-- FSM that controls communication between lvl1 instruction/data caches and lvl2 shared cache
	cc_fsm_proc : process(cc_state_reg, cc_counter_reg, cc_counter_incr, we_data_i, re_data_i, data_access_s, dwrite_data_i, 
		lvl1ia_c_addr_s, lvl1ia_c_idx_s, lvl1ia_c_tag_s, lvl1ia_c_hit_s, lvl1ia_ts_valid_reg, dreada_instr_cache_s,
		lvl1da_c_addr_s, lvl1da_c_idx_s, lvl1da_c_tag_s, lvl1da_c_hit_s, lvl1da_ts_tag_s, lvl1da_ts_bkk_s, dreada_data_cache_s,
		lvl2ia_c_idx_s, lvl2ia_c_tag_s, lvl2da_c_idx_s, lvl2da_c_tag_s, lvl2il_c_idx_s, lvl2dl_c_idx_s, lvl2dl_c_tag_s, 
		lvl2a_c_hit_s, lvl2a_ts_tag_s, lvl2a_ts_bkk_s, lvl2a_ts_nbkk_s,  dreada_lvl2_cache_s, 
		flush_lvl1d_s, invalidate_lvl1d_s, invalidate_lvl1i_s, bram_read_rdy_reg,
		lvl2_hit_index, lvl2_nextv_index, lvl2_victim_index, lvl2_rando_index, lvl2_dflush_index, lvl2_iflush_index) is
	begin
		check_lvl2_s <= '0';
		lvl1_valid_s <= '1';
		if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
			bram_read_rdy_next <= '0';
		end if;
		-- for FSM
		cc_state_next <= idle;
		cc_counter_next <= (others => '0');
		-- Misc
		lvl2a_c_idx_s <= lvl2ia_c_idx_s;
		lvl2a_c_tag_s <= lvl2ia_c_tag_s;
		-- LVL1 instruction cache and tag
		lvl1ia_ts_valid_next <= lvl1ia_ts_valid_reg;
		wea_instr_tag_s <= '0';
		addra_instr_tag_s <= lvl1ia_c_idx_s;
		dwritea_instr_tag_s <= (others => '0');
		wea_instr_cache_s <= '0';
		addra_instr_cache_s <= lvl1ia_c_addr_s((LVL1C_ADDR_WIDTH-1) downto 2);
		dwritea_instr_cache_s <= (others => '0');
		dread_instr_o <= dreada_instr_cache_s;
		-- LVL1 data cache and tag
		addra_data_tag_s <= lvl1da_c_idx_s;
		wea_data_tag_s <= '0';
		dwritea_data_tag_s <= (others => '0');
		wea_data_cache_s <= we_data_i;
		addra_data_cache_s <= lvl1da_c_addr_s((LVL1C_ADDR_WIDTH-1) downto 2);
		dwritea_data_cache_s <= dwrite_data_i;
		dread_data_o <= dreada_data_cache_s;
		-- LVL2 cache and tag
		addra_lvl2_tag_s <= lvl2da_c_idx_s;
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
			addra_lvl2_cache_s(i) <= (others => '0'); -- lvl2ia_c_addr_s((LVL2C_ADDR_WIDTH-1) downto 2);
			wea_lvl2_cache_s(i) <= '0';
			dwritea_lvl2_cache_s(i) <= (others => '0'); 
			wea_lvl2_tag_s(i) <= '0';
			dwritea_lvl2_tag_s(i) <= (others => '0'); 
		end loop;
				
		case (cc_state_reg) is
			when idle =>
				-- ACCESS TO INSTR MEMORY
				if(lvl1ia_c_hit_s = '0') then -- instr cache miss
					cc_state_next <= check_lvl2_instr;
					addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				end if;
				-- ACCESS TO DATA MEMORY
				if (data_access_s = '1') then --its only then a data memory access
					if(lvl1da_c_hit_s = '1') then 
						if(re_data_i = '0')then -- this means instruction is a write, better to check one bit than 4 bits for we_data_i signal
							if(lvl1da_ts_bkk_s(1) = '0')then --if not dirty update
								-- set dirty in lvl1d
								lvl1_valid_s <= '0';
								wea_data_tag_s <= '1';
								dwritea_data_tag_s <= "11" & lvl1da_ts_tag_s; --data written, dirty + valid
								addra_lvl2_tag_s <= lvl2da_c_idx_s;
								cc_state_next <= set_dirty;
							end if;
						end if;
					else -- data cache miss
						addra_lvl2_tag_s <= lvl2da_c_idx_s;
						if(lvl1da_ts_bkk_s(1) = '1')then -- data in lvl1 is dirty
							-- flush needed, prepare address one clk before
							cc_state_next <= flush_data;
							addra_lvl2_tag_s <= lvl2dl_c_idx_s;
							--addra_data_cache_s <= lvl1da_c_idx_s & cc_counter_reg; -- NOTE retardu retardu
						else
							cc_state_next <= check_lvl2_data;
						end if;
					end if;
				end if;
			

			when set_dirty =>

				lvl2a_c_tag_s <= lvl2da_c_tag_s;
				addra_lvl2_tag_s <= lvl2da_c_idx_s;

				if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
					if(bram_read_rdy_reg = '1') then
						cc_state_next <= idle;
						wea_lvl2_tag_s(lvl2_hit_index) <= '1';
						-- dirty but invalid, as the newer data is in data cache
						dwritea_lvl2_tag_s(lvl2_hit_index) <= 
							lvl2a_ts_nbkk_s(lvl2_hit_index) & lvl2a_ts_bkk_s(lvl2_hit_index)(3 downto 2) & "10" & lvl2a_ts_tag_s(lvl2_hit_index);
					else
						lvl1_valid_s <= '0';
						cc_state_next <= set_dirty;
						bram_read_rdy_next<='1';
					end if;

				else -- LOW_LATENCY - ONE CLK DELAY
					cc_state_next <= idle;
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
					-- dirty but invalid, as the newer data is in data cache
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						lvl2a_ts_nbkk_s(lvl2_hit_index) & lvl2a_ts_bkk_s(lvl2_hit_index)(3 downto 2) & "10" & lvl2a_ts_tag_s(lvl2_hit_index);
				end if;


			when invalidate_data => 

				check_lvl2_s <= '1';
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;

				addra_data_tag_s <= lvl1ia_c_idx_s; 
				dwritea_data_tag_s <= (others => '0');
				lvl1_valid_s <= '0';

				if (lvl2a_c_hit_s = '1') then
					cc_state_next <= fetch_instr;
					--new block coming, previous block is going to be removed from lvl1ic
					addra_lvl2_tag_s <= lvl2il_c_idx_s;
					addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
				else
					cc_state_next <= check_lvl2_instr;
				end if;
				
			when check_lvl2_instr => 

				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;

				if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
					if(bram_read_rdy_reg = '1') then

						if (lvl2a_c_hit_s = '1') then
							cc_state_next <= fetch_instr;
							--new block coming, previous block is going to be removed from lvl1ic
							addra_lvl2_tag_s <= lvl2il_c_idx_s;
							addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
						elsif (flush_lvl1d_s = '1') then
							cc_state_next <= flush_dependent_data;
						else
							if(invalidate_lvl1d_s = '1' )then
								cc_state_next <= invalidate_data;
							end if;
							if (invalidate_lvl1i_s = '1') then 
								lvl1ia_ts_valid_next (to_integer(unsigned(lvl1ia_c_idx_s))) <= '0';
							end if;
							cc_state_next <= check_lvl2_instr; -- stay here if lvl2 is not ready
						end if;
						bram_read_rdy_next<='1';
						check_lvl2_s <= '1';
					else
						bram_read_rdy_next<='1';
						check_lvl2_s <= '0';
					end if;

				else -- LOW LATENCY
					check_lvl2_s <= '1';
					if (lvl2a_c_hit_s = '1') then
						cc_state_next <= fetch_instr;
						--new block coming, previous block is going to be removed from lvl1ic
						addra_lvl2_tag_s <= lvl2il_c_idx_s;
						addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
					elsif (flush_lvl1d_s = '1') then
						cc_state_next <= flush_dependent_data;
					else
						if(invalidate_lvl1d_s = '1' )then
							cc_state_next <= invalidate_data;
						end if;
						if (invalidate_lvl1i_s = '1') then 
							lvl1ia_ts_valid_next (to_integer(unsigned(lvl1ia_c_idx_s))) <= '0';
						end if;
						cc_state_next <= check_lvl2_instr; -- stay here if lvl2 is not ready
					end if;
				end if;



			when check_lvl2_data => 
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_idx_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s;

				if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
					if(bram_read_rdy_reg = '1') then
						if (lvl2a_c_hit_s = '1') then
							cc_state_next <= fetch_data;
							-- new block coming, previous block is going to be removed from lvl1dc
							addra_lvl2_tag_s <= lvl2dl_c_idx_s;
							addra_lvl2_cache_s(lvl2_hit_index) <= lvl2da_c_idx_s & cc_counter_reg;
						else
							cc_state_next <= check_lvl2_data; -- stay here if lvl2 is not ready
							if (invalidate_lvl1i_s = '1') then
								lvl1ia_ts_valid_next (to_integer(unsigned(lvl1da_c_idx_s))) <= '0';
							end if;
							if (invalidate_lvl1d_s = '1') then
								--addra_data_tag_s <= lvl1da_c_idx_s; -- not necessairy, it's default
								dwritea_data_tag_s <= (others => '0'); 
								wea_data_tag_s <= '1';
							end if;
						end if;
						bram_read_rdy_next<='1';
						check_lvl2_s <= '1';
					else
						bram_read_rdy_next<='1';
						check_lvl2_s <= '0';
					end if;
				else -- LOW LATENCY
					check_lvl2_s <= '1';
					if (lvl2a_c_hit_s = '1') then
						cc_state_next <= fetch_data;
						-- new block coming, previous block is going to be removed from lvl1dc
						addra_lvl2_tag_s <= lvl2dl_c_idx_s;
						addra_lvl2_cache_s(lvl2_hit_index) <= lvl2da_c_idx_s & cc_counter_reg;
					else
						cc_state_next <= check_lvl2_data; -- stay here if lvl2 is not ready
						if (invalidate_lvl1i_s = '1') then
							lvl1ia_ts_valid_next (to_integer(unsigned(lvl1da_c_idx_s))) <= '0';
						end if;
						if (invalidate_lvl1d_s = '1') then
							--addra_data_tag_s <= lvl1da_c_idx_s; -- not necessairy, it's default
							dwritea_data_tag_s <= (others => '0'); 
							wea_data_tag_s <= '1';
						end if;
					end if;
				end if;


			when fetch_instr => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_incr;
				addra_instr_cache_s <= lvl1ia_c_idx_s & cc_counter_reg;
				dwritea_instr_cache_s <= dreada_lvl2_cache_s(lvl2_hit_index);
				wea_instr_cache_s <= '1';

				cc_counter_next <= cc_counter_incr;

				-- these next lines are needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;

				if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
					if(cc_counter_reg = COUNTER_MIN)then 
						addra_lvl2_tag_s <= lvl2il_c_idx_s;
					elsif(cc_counter_reg = COUNTER_ONE)then 
						addra_lvl2_tag_s <= lvl2il_c_idx_s;
						dwritea_lvl2_tag_s(lvl2_iflush_index) <= 
							lvl2a_ts_nbkk_s(lvl2_iflush_index) & (lvl2a_ts_bkk_s(lvl2_iflush_index) and "1011") & lvl2a_ts_tag_s(lvl2_iflush_index);
						wea_lvl2_tag_s(lvl2_iflush_index) <= '1';
					end if;
				else --LOW_LATENECY
					if(cc_counter_reg = COUNTER_MIN)then 
						-- block is going to be removed from lvl1ic
						addra_lvl2_tag_s <= lvl2il_c_idx_s;
						dwritea_lvl2_tag_s(lvl2_iflush_index) <= 
							lvl2a_ts_nbkk_s(lvl2_iflush_index) & (lvl2a_ts_bkk_s(lvl2_iflush_index) and "1011") & lvl2a_ts_tag_s(lvl2_iflush_index);
						wea_lvl2_tag_s(lvl2_iflush_index) <= '1';
					end if;
				end if;

				if(cc_counter_reg = COUNTER_MAX)then 
					cc_state_next <= update_instr_ts;
				else
					cc_state_next <= fetch_instr;
				end if;


			when fetch_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2da_c_idx_s & cc_counter_incr;
				addra_data_cache_s <= lvl1da_c_idx_s & cc_counter_reg;
				dwritea_data_cache_s <= dreada_lvl2_cache_s(lvl2_hit_index);
				wea_data_cache_s <= "1111";

				cc_counter_next <= cc_counter_incr;

				-- these next lines are needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s; 
				lvl2a_c_idx_s <= lvl2da_c_idx_s;

				if(TS_BRAM_TYPE = "HIGH_PERFORMANCE")then
					if(cc_counter_reg = COUNTER_MIN)then 
						addra_lvl2_tag_s <= lvl2dl_c_idx_s;
					elsif(cc_counter_reg = COUNTER_ONE)then 
						-- block is going to be removed from lvl1dc
						addra_lvl2_tag_s <= lvl2dl_c_idx_s;
						dwritea_lvl2_tag_s(lvl2_dflush_index) <=  
							lvl2a_ts_nbkk_s(lvl2_dflush_index) & (lvl2a_ts_bkk_s(lvl2_dflush_index) and "0111") & lvl2a_ts_tag_s(lvl2_dflush_index);
						wea_lvl2_tag_s(lvl2_dflush_index) <= '1';
					end if;
				else -- LOW_LATENCY
					if(cc_counter_reg = COUNTER_MIN)then 
						-- block is going to be removed from lvl1dc
						addra_lvl2_tag_s <= lvl2dl_c_idx_s;
						dwritea_lvl2_tag_s(lvl2_dflush_index) <=  
							lvl2a_ts_nbkk_s(lvl2_dflush_index) & (lvl2a_ts_bkk_s(lvl2_dflush_index) and "0111") & lvl2a_ts_tag_s(lvl2_dflush_index);
						wea_lvl2_tag_s(lvl2_dflush_index) <= '1';
					end if;
				end if;

				if(cc_counter_reg = COUNTER_MAX)then 
					-- finished with writing entire block
					cc_state_next <= update_data_ts;
				else
					cc_state_next <= fetch_data;
				end if;


			when flush_dependent_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				-- lvl1i cache is asking for this data from level 2
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
				addra_data_cache_s <= lvl1ia_c_idx_s & cc_counter_reg;
				lvl1_valid_s <= '0';

				-- this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;

				dwritea_lvl2_cache_s(lvl2_hit_index) <= dreada_data_cache_s;
				wea_lvl2_cache_s(lvl2_hit_index)<= '1';

				cc_counter_next <= cc_counter_incr;

				if(cc_counter_reg = COUNTER_MAX)then 
					cc_state_next <= check_lvl2_instr;
					addra_lvl2_tag_s <= lvl2ia_c_idx_s;
					-- write new tag to tag store, set valid, reset dirty
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						lvl2a_ts_nbkk_s(lvl2_hit_index) & (lvl2a_ts_bkk_s(lvl2_hit_index) or "0011") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
				else
					cc_state_next <= flush_dependent_data;
				end if;


			when flush_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				-- this block in lvl2 is being evicted
				addra_lvl2_cache_s(lvl2_dflush_index) <= lvl2dl_c_idx_s & cc_counter_reg;
				addra_data_cache_s <= lvl1da_c_idx_s & cc_counter_reg;

				-- this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2dl_c_idx_s;

				dwritea_lvl2_cache_s(lvl2_dflush_index) <= dreada_data_cache_s;
				wea_lvl2_cache_s(lvl2_dflush_index)<= '1';

				cc_counter_next <= cc_counter_incr;

				if(cc_counter_reg = COUNTER_MAX)then 
					-- finished with writing entire block
					cc_state_next <= check_lvl2_data;
					addra_lvl2_tag_s <= lvl2dl_c_idx_s;
					-- write new tag to tag store, set valid, reset dirty
					dwritea_lvl2_tag_s(lvl2_dflush_index) <= 
						lvl2a_ts_nbkk_s(lvl2_dflush_index) & (lvl2a_ts_bkk_s(lvl2_dflush_index) or "0011") & lvl2a_ts_tag_s(lvl2_dflush_index);
					wea_lvl2_tag_s(lvl2_dflush_index) <= '1';
				else
					cc_state_next <= flush_data;
				end if;


			when update_instr_ts => 
				-- these next lines are needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;

				case lvl2a_ts_nbkk_s(lvl2_hit_index) is
				when "00" => -- hit to ordinary block : V/NV stay the same
					-- V/NV stays the same; set INSTR bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						lvl2a_ts_nbkk_s(lvl2_hit_index) & (lvl2a_ts_bkk_s(lvl2_hit_index) or "0100") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
				when "01" => -- hit to next victim block : NV -> O, rand O -> NV
					-- Hit NV becomes ordinary; set INSTR bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						"00" & (lvl2a_ts_bkk_s(lvl2_hit_index) or "0100") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
					-- Random ordinary becomes NV;
					dwritea_lvl2_tag_s(lvl2_rando_index) <= 
						"01" & lvl2a_ts_bkk_s(lvl2_rando_index) & lvl2a_ts_tag_s(lvl2_rando_index); 
					wea_lvl2_tag_s(lvl2_rando_index) <= '1';
				when others => -- hit to victim block : V -> O, NV -> V, rand O -> NV
					-- Hit V becomes ordinary; set INSTR bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						"00" & (lvl2a_ts_bkk_s(lvl2_hit_index) or "0100") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
					-- NV becomes V
					dwritea_lvl2_tag_s(lvl2_nextv_index) <= 
						"10" & lvl2a_ts_bkk_s(lvl2_nextv_index) & lvl2a_ts_tag_s(lvl2_nextv_index); 
					wea_lvl2_tag_s(lvl2_nextv_index) <= '1';
					-- Random ordinary becomes NV;
					dwritea_lvl2_tag_s(lvl2_rando_index) <= 
						"01" & lvl2a_ts_bkk_s(lvl2_rando_index) & lvl2a_ts_tag_s(lvl2_rando_index); 
					wea_lvl2_tag_s(lvl2_rando_index) <= '1';
				end case;

				cc_state_next <= idle;
				-- write new tag to tag store, set valid, reset dirty
				lvl1ia_ts_valid_next (to_integer(unsigned(lvl1ia_c_idx_s))) <= '1';
				dwritea_instr_tag_s <= lvl1ia_c_tag_s; 
				wea_instr_tag_s <= '1';


			when update_data_ts => 
				-- these next lines are needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s;
				lvl2a_c_idx_s <= lvl2da_c_idx_s;

				-- update tag stores on lvl2 cache
				case lvl2a_ts_nbkk_s(lvl2_hit_index) is
				when "00" => -- hit to ordinary block : V/NV stay the same
					-- V/NV stays the same; set DATA bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						lvl2a_ts_nbkk_s(lvl2_hit_index) & (lvl2a_ts_bkk_s(lvl2_hit_index) or "1000") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
				when "01" => -- hit to next victim block : NV -> O, rand O -> NV
					-- Hit NV becomes ordinary; set DATA bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						"00" & (lvl2a_ts_bkk_s(lvl2_hit_index) or "1000") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
					-- Random ordinary becomes NV;
					dwritea_lvl2_tag_s(lvl2_rando_index) <= 
						"01" & lvl2a_ts_bkk_s(lvl2_rando_index) & lvl2a_ts_tag_s(lvl2_rando_index); 
					wea_lvl2_tag_s(lvl2_rando_index) <= '1';
				when others => -- hit to victim block : V -> O, NV -> V, rand O -> NV
					-- Hit V becomes ordinary; set DATA bit;
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						"00" & (lvl2a_ts_bkk_s(lvl2_hit_index) or "1000") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
					-- NV becomes V
					dwritea_lvl2_tag_s(lvl2_nextv_index) <= 
						"10" & lvl2a_ts_bkk_s(lvl2_nextv_index) & lvl2a_ts_tag_s(lvl2_nextv_index); 
					wea_lvl2_tag_s(lvl2_nextv_index) <= '1';
					-- Random ordinary becomes NV;
					dwritea_lvl2_tag_s(lvl2_rando_index) <= 
						"01" & lvl2a_ts_bkk_s(lvl2_rando_index) & lvl2a_ts_tag_s(lvl2_rando_index); 
					wea_lvl2_tag_s(lvl2_rando_index) <= '1';
				end case;

				cc_state_next <= idle;
				-- write new tag to tag store, set valid, reset dirty
				dwritea_data_tag_s <= "01" & lvl1da_c_tag_s; 
				wea_data_tag_s <= '1';

			when others =>
		end case;
	end process;




   
	-- Memory controller
	-- FSM that controls communication between lvl2 cache and main memory (DDR RAM)
	mc_fsm_proc : process(mc_state_reg, mc_counter_reg, mc_counter_incr, dread_phy_i, check_lvl2_s,
								lvl2a_c_idx_s, lvl2a_c_tag_s, lvl2a_c_hit_s, lvl2a_ts_bkk_s, lvl2a_ts_tag_s,
								lvl2b_ts_tag_s, lvl2b_ts_bkk_s, lvl2b_ts_nbkk_s, dreadb_lvl2_cache_s,
								lvl2_victim_index, lvl2_nextv_index, lvl2_rando_index, lvl2_invalid_found_s, lvl2_invalid_index) is
	begin
		-- for FSM
		mc_state_next <= idle;
		mc_counter_next <= (others => '0');
		-- LVL 2 signals ports B
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
			addrb_lvl2_cache_s(i) <= (others => '0');
			web_lvl2_cache_s(i) <= '0';
			dwriteb_lvl2_cache_s(i) <= (others => '0'); 
			web_lvl2_tag_s(i) <= '0';
			dwriteb_lvl2_tag_s(i) <= (others => '0'); 
		end loop;
		addrb_lvl2_tag_s <= lvl2a_c_idx_s; 
		-- MEMORY interface signals (bus)
		-- dread_phy_i -> use this to read data from bus
		addr_phy_o <= (others => '0');
		dwrite_phy_o <= (others => '0');
		we_phy_o <= '0';
		-- coherency
		flush_lvl1d_s <= '0';
		invalidate_lvl1d_s <= '0';
		invalidate_lvl1i_s <= '0';

		case (mc_state_reg) is
			when idle =>
				if(lvl2a_c_hit_s = '0' and check_lvl2_s = '1')then
					case (lvl2a_ts_bkk_s(lvl2_victim_index)(1 downto 0)) is 
						when "10" => -- dirty but not valid lvl2, data lvl1 has updated values
							mc_state_next <= idle; 
							flush_lvl1d_s <= '1';
						when "11" => -- dirty and valid lvl2, flush to physical
							mc_state_next <= flush; 
							addrb_lvl2_tag_s <= lvl2a_c_idx_s;
							addrb_lvl2_cache_s(lvl2_victim_index) <= lvl2a_c_idx_s & mc_counter_reg;
						when others => -- not initialized / valid but not dirty data
							mc_state_next <= fetch;
							addrb_lvl2_tag_s <= lvl2a_c_idx_s;
							addr_phy_o <= lvl2a_c_tag_s & lvl2a_c_idx_s & mc_counter_reg & "00";
							-- when evicting block, invalidate if block is in lvl1 data cache
							if (lvl2a_ts_bkk_s(lvl2_victim_index)(LVL2C_BKK_DATA)='1')then 
								invalidate_lvl1d_s <= '1';
								dwriteb_lvl2_tag_s(lvl2_victim_index) <= "10" & (lvl2a_ts_bkk_s(lvl2_victim_index) and "0111") & lvl2a_ts_tag_s(lvl2_victim_index); 
								web_lvl2_tag_s(lvl2_victim_index) <= '1';
							end if;
							-- when evicting block, invalidate if block is in lvl1 instr cache
							if (lvl2a_ts_bkk_s(lvl2_victim_index)(LVL2C_BKK_INSTR)='1')then 
								invalidate_lvl1i_s <= '1';
							end if;
							-- NOTE CODE SEGMENT A taken from fetch state
							dwriteb_lvl2_tag_s(lvl2_victim_index) <= "10" & "0001" & lvl2a_c_tag_s; 
							web_lvl2_tag_s(lvl2_victim_index) <= '1';
							-- NOTE NOTE check : use victim "10" instead of using nbkk_s
					end case;
				end if;

			when flush =>
				addr_phy_o <= lvl2b_ts_tag_s(lvl2_victim_index) & lvl2a_c_idx_s & mc_counter_reg & "00";
				addrb_lvl2_cache_s(lvl2_victim_index) <= lvl2a_c_idx_s & mc_counter_incr;
				dwrite_phy_o <= dreadb_lvl2_cache_s(lvl2_victim_index);
				we_phy_o <= '1';

				mc_counter_next <= mc_counter_incr;

				addrb_lvl2_tag_s <= lvl2a_c_idx_s;
				if(mc_counter_reg = COUNTER_MIN)then  -- because of read first mode
					-- invalidate so the next state after idle is fetch
					dwriteb_lvl2_tag_s(lvl2_victim_index) <= 
						lvl2b_ts_nbkk_s(lvl2_victim_index) & (lvl2b_ts_bkk_s(lvl2_victim_index) and "1100") & lvl2b_ts_tag_s(lvl2_victim_index); 
					web_lvl2_tag_s(lvl2_victim_index) <= '1';
				end if;

				if(mc_counter_reg = COUNTER_MAX)then 
					mc_state_next <= idle;
				else
					mc_state_next <= flush;
				end if;

			when fetch =>
				addr_phy_o <= lvl2a_c_tag_s & lvl2a_c_idx_s & mc_counter_incr & "00";
				addrb_lvl2_cache_s(lvl2_victim_index) <= lvl2a_c_idx_s & mc_counter_reg;
				dwriteb_lvl2_cache_s(lvl2_victim_index) <= dread_phy_i;
				web_lvl2_cache_s(lvl2_victim_index) <= '1';

				mc_counter_next <= mc_counter_incr;

				addrb_lvl2_tag_s <= lvl2a_c_idx_s;

				--if(mc_counter_reg = COUNTER_MIN) then  -- because of the read first mode
					-- NOTE code segment A was taken from here 
				--end if;

				if(mc_counter_reg = COUNTER_MAX)then 
					mc_state_next <= idle;
					-- victim becomes ordinary block
					dwriteb_lvl2_tag_s(lvl2_victim_index) <= "00" & lvl2b_ts_bkk_s(lvl2_victim_index) & lvl2b_ts_tag_s(lvl2_victim_index); 
					web_lvl2_tag_s(lvl2_victim_index) <= '1';
					-- nextvictim becomes victim
					dwriteb_lvl2_tag_s(lvl2_nextv_index) <=  "10" & lvl2b_ts_bkk_s(lvl2_nextv_index) & lvl2b_ts_tag_s(lvl2_nextv_index); 
					web_lvl2_tag_s(lvl2_nextv_index) <= '1';
					-- check if there are any invalid blocks to use as nextvictim
					 if(lvl2_invalid_found_s = '1')then -- if there is invalid block, set it as next victim
						dwriteb_lvl2_tag_s(lvl2_invalid_index) <=  "01" & lvl2b_ts_bkk_s(lvl2_invalid_index) & lvl2b_ts_tag_s(lvl2_invalid_index); 
						web_lvl2_tag_s(lvl2_invalid_index) <= '1';
					else -- if all blocks are valid, random ordinary block becomes nextvictim
						dwriteb_lvl2_tag_s(lvl2_rando_index) <=  "01" & lvl2b_ts_bkk_s(lvl2_rando_index) & lvl2b_ts_tag_s(lvl2_rando_index); 
						web_lvl2_tag_s(lvl2_rando_index) <= '1';
					end if;
				else
					mc_state_next <= fetch;
				end if;
				
			when others =>
		end case;
	end process;



	--************************* INSTANTIATION OF CACHES *************************

	--********** LEVEL 1 CACHES  **************
	-- INSTRUCTION CACHE
	ena_instr_cache_s <= '1';
	-- Instantiation of instruction cache
	instruction_cache : entity work.RAM_sp_ar(rtl)
		generic map (
			RAM_WIDTH => C_NUM_COL*C_COL_WIDTH,
			RAM_DEPTH => LVL1C_DEPTH,
			INIT_FILE => "" 
		)
		port map  (
			clk   => clk,
			addra  => addra_instr_cache_s,
			dina   => dwritea_instr_cache_s,
			ena    => ena_instr_cache_s,
			douta  => dreada_instr_cache_s,
			wea    => wea_instr_cache_s
		);
	-- TAG STORE FOR INSTRUCTION CACHE
	-- TODO @ system boot this entire memory needs to be set to 0
	-- TODO either implement reset and test its timing or make cc handle it @ boot
	-- rst_instr_tag_s <= reset;
	-- instantiation of tag store
	ena_instr_tag_s <= '1'; --NOTE right?
	instruction_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => LVL1C_TAG_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS,
			INIT_FILE => "" 
		)
		port map(
			clk => clk,
			addra => addra_instr_tag_s,
			dina => dwritea_instr_tag_s,
			ena => ena_instr_tag_s,
			douta => dreada_instr_tag_s,
			wea => wea_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	rsta_data_cache_s <= '0';
	-- TODO check if this can be just data_access? Can there be flush while data acess is zero?
	ena_data_cache_s <= '1'; -- data_access_s; -- check if this shit works *thought* enable only on data acess
	regcea_data_cache_s <= '0';
	-- Instantiation of data cache
	data_cache : entity work.RAM_sp_ar_bw(rtl)
		generic map (
				NB_COL => C_NUM_COL,
				COL_WIDTH => C_COL_WIDTH,
				RAM_DEPTH => LVL1C_DEPTH,
				RAM_PERFORMANCE => "LOW_LATENCY",
				INIT_FILE => "" 
		)
		port map  (
				clk   => clk,
				addra  => addra_data_cache_s,
				dina   => dwritea_data_cache_s,
				wea    => wea_data_cache_s,
				ena    => ena_data_cache_s,
				rsta   => rsta_data_cache_s,
				regcea => regcea_data_cache_s,
				douta  => dreada_data_cache_s
		);
	-- TAG STORE FOR DATA CACHE
	 -- TODO @ system boot this entire memory needs to be set to 0
	 -- TODO either implement reset and test its timing or make cc handle it @ boot
	--rst_data_tag_s <= reset;
	-- Instantiation of tag store
	ena_data_tag_s <= '1'; -- NOTE i think
	data_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS,
			INIT_FILE => "" 
		)
		port map(
			clk => clk,
			addra => addra_data_tag_s,
			dina => dwritea_data_tag_s,
			douta => dreada_data_tag_s,
			wea => wea_data_tag_s,
			ena => ena_data_tag_s
		);


	--********** LEVEL 2 CACHE  **************
	rsta_lvl2_cache_s <= reset; -- TODO is it needed? this is not a real reset signal, more like output enable
	rstb_lvl2_cache_s <= reset; -- TODO same
	ena_lvl2_cache_s <= '1';
	enb_lvl2_cache_s <= '1';
	regcea_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	regceb_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	-- Instantiation of level 2 caches
	lvl2_cache_generate:
	for i in 0 to LVL2C_ASSOCIATIVITY-1 generate
		level_2_cache : entity work.RAM_tdp_rf(rtl)
			generic map (
				RAM_WIDTH => C_NUM_COL*C_COL_WIDTH,
				RAM_DEPTH => LVL2C_DEPTH,
				RAM_PERFORMANCE => "LOW_LATENCY",
				INIT_FILE => "" 
			)
			port map  (
				--global
				clk    => clk,
				--port a
				addra  => addra_lvl2_cache_s(i),
				dina   => dwritea_lvl2_cache_s(i),
				douta  => dreada_lvl2_cache_s(i),
				wea    => wea_lvl2_cache_s(i),
				ena    => ena_lvl2_cache_s,
				rsta   => rsta_lvl2_cache_s,
				regcea => regcea_lvl2_cache_s,
				--port b
				addrb  => addrb_lvl2_cache_s(i),
				dinb   => dwriteb_lvl2_cache_s(i),
				web    => web_lvl2_cache_s(i),
				enb    => enb_lvl2_cache_s,
				rstb   => rstb_lvl2_cache_s,
				regceb => regceb_lvl2_cache_s,
				doutb  => dreadb_lvl2_cache_s(i)
			);
		end generate;

	-- TODO @ system boot this entire memory needs to be set to 0
	-- TODO either implement reset and test its timing or make cc handle it @ boot
	-- tag store for Level 2 cache
	ena_lvl2_tag_s <= '1';
	enb_lvl2_tag_s <= '1';
	rsta_lvl2_tag_s <= '0';
	rstb_lvl2_tag_s <= '0';
	regcea_lvl2_tag_s <= '0'; -- TODO remove these if Vivado doesnt
	regceb_lvl2_tag_s <= '0'; -- TODO remove these if Vivado doesnt
	lvl2_tag_store_generate:
	for i in 0 to LVL2C_ASSOCIATIVITY-1 generate
		level_2_tag_store: entity work.ram_tdp_rf(rtl)
			generic map (
				 RAM_WIDTH => LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH + LVL2C_NWAY_BKK_WIDTH,
				 RAM_DEPTH => LVL2C_NB_BLOCKS,
				 RAM_PERFORMANCE => TS_BRAM_TYPE      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
			)
			port map(
				--global
				clk => clk,
				--port a
				addra => addra_lvl2_tag_s,
				dina => dwritea_lvl2_tag_s(i),
				douta => dreada_lvl2_tag_s(i),
				wea => wea_lvl2_tag_s(i),
				rsta   => rsta_lvl2_tag_s,
				regcea => regcea_lvl2_tag_s,
				ena => ena_lvl2_tag_s,
				--port b
				addrb => addrb_lvl2_tag_s,
				dinb => dwriteb_lvl2_tag_s(i),
				doutb => dreadb_lvl2_tag_s(i),
				web => web_lvl2_tag_s(i),
				rstb   => rstb_lvl2_tag_s,
				regceb => regceb_lvl2_tag_s,
				enb => enb_lvl2_tag_s
			);
		end generate;
end architecture;
