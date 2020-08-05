library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity cache_contr_nway_vnv is
generic (PHY_ADDR_SPACE : natural := 512*1024*1024; -- 512 MB
			BLOCK_SIZE : natural := 64;
			LVL1_CACHE_SIZE : natural := 1048;
			LVL2_CACHE_SIZE : natural := 4096;
			LVL2C_ASSOCIATIVITY : natural := 4);
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
         we_phy_o				: out std_logic_vector(3 downto 0);
			-- Level 1 caches
			-- Instruction cache
			--rst_instr_cache_i : in std_logic;
			--en_instr_cache_i  : in std_logic;
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

	-- DERIVE 2nd ORDER CONSTANTS
	constant PHY_ADDR_WIDTH : integer := clogb2(PHY_ADDR_SPACE);
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL1C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL1C_ADDR_WIDTH;
	constant LVL1DC_BKK_WIDTH : integer := 2;
	constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL2C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL2C_ADDR_WIDTH;
	constant LVL2C_BKK_WIDTH : integer := 4;


	-- SIGNALS FOR INTERACTION WITH RAMS
	--*******************************************************************************************
	-- Level 1 cache signals


	-- Instruction cache signals
	signal addra_instr_cache_s : std_logic_vector((LVL1C_ADDR_WIDTH-3) downto 0); --(-2 bits because byte in 32-bit word is not adressible) 
	signal dwritea_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dreada_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal wea_instr_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal ena_instr_cache_s : std_logic;
	signal rsta_instr_cache_s : std_logic;
	signal regcea_instr_cache_s : std_logic;

	-- Instruction cache tag store singals
	-- port A
	signal dwritea_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH - 1 downto 0);
	signal dreada_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH - 1 downto 0);
	signal addra_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_instr_tag_s : std_logic;
	signal wea_instr_tag_s : std_logic;
	-- port B TODO left here if needed
	--signal dwriteb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH - 1 downto 0);
	--signal dreadb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH - 1 downto 0);
	--signal addrb_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	--signal enb_instr_tag_s : std_logic;
	--signal web_instr_tag_s : std_logic;


	-- Data cache signals
	signal clk_data_cache_s : std_logic;
	signal addra_data_cache_s : std_logic_vector((LVL1C_ADDR_WIDTH-3) downto 0); --(-2 bits because byte in 32-bit word is not adressible)
	signal dwritea_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dreada_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0); 
	signal wea_data_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal ena_data_cache_s : std_logic; 
	signal rsta_data_cache_s : std_logic; 
	signal regcea_data_cache_s : std_logic;

	-- Data cache tag store singals
	-- port A
	signal dwritea_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal dreada_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal addra_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_data_tag_s : std_logic;
	signal regcea_data_tag_s : std_logic;
	signal rsta_data_tag_s : std_logic;
	signal wea_data_tag_s : std_logic;
	-- port B
	--signal dwriteb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	--signal dreadb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	--signal addrb_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	--signal enb_data_tag_s : std_logic;
	--signal regceb_data_tag_s : std_logic;
	--signal rstb_data_tag_s : std_logic;
	--signal web_data_tag_s : std_logic;


	-- Level 2 cache signals
	-- port A
	--(-2 bits because byte in 32-bit word is not adressible)
	type lvl2_addr_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector((LVL2C_ADDR_WIDTH-3) downto 0); 
	type lvl2_data_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
	type lvl2_we_c_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_NUM_COL-1 downto 0);
	type lvl2_addr_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	type lvl2_data_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH + LVL2C_NWAY_BKK_WIDTH - 1 downto 0);
	type lvl2_we_ts_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic;

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
	signal addra_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0); -- lvl2_addr_ts_t;
	signal ena_lvl2_tag_s : std_logic;
	signal rsta_lvl2_tag_s : std_logic;
	signal wea_lvl2_tag_s : std_logic_vector(0 to LVL2C_ASSOCIATIVITY-1);
	signal regcea_lvl2_tag_s : std_logic;
	-- port B
	signal dwriteb_lvl2_tag_s : lvl2_data_ts_t;
	signal dreadb_lvl2_tag_s : lvl2_data_ts_t;
	signal addrb_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0); -- lvl2_addr_ts_t; 
	signal enb_lvl2_tag_s : std_logic;
	signal rstb_lvl2_tag_s : std_logic;
	signal web_lvl2_tag_s : std_logic_vector(0 to LVL2C_ASSOCIATIVITY-1);
	signal regceb_lvl2_tag_s : std_logic;

--*******************************************************************************************


	-- SIGNALS FOR SEPARATING INPUT PORTS INTO FIELDS
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for data cache
	signal lvl1d_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1d_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1d_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1d_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from data tag store
	signal lvl1da_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1da_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	--signal lvl1db_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl1db_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal lvl1i_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1i_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1i_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1i_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from instruction tag store
	signal lvl1ia_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ia_ts_valid_reg, lvl1ia_ts_valid_next : std_logic_vector(LVL1C_NB_BLOCKS-1 downto 0); -- NOTE NOTE NOTE no more : lvl1ia_ts_bkk_s
	--signal lvl1ib_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl1ib_ts_bkk_s : std_logic_vector(LVL1IC_BKK_WIDTH-1 downto 0);
	-- TODO check if these will be used, or signal values will be derived directly from some other signal
	signal lvl2a_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2a_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for levelvl2 cache
	--signal lvl2ia_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	--signal lvl2da_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl2ia_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2ia_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2ia_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	signal lvl2da_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2da_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2da_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- these are needed for flushing from lvl1 to lvl2
	signal lvl2dl_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2dl_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2dl_c_addr_s : std_logic_vector(LVL1C_INDEX_WIDTH+LVL1C_TAG_WIDTH-1 downto 0);

	signal lvl2il_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2il_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2il_c_addr_s : std_logic_vector(LVL1C_INDEX_WIDTH+LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl2if_c_addr_s : std_logic_vector(LVL1C_INDEX_WIDTH+LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl2if_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for levelvl2 cache
	signal lvl2b_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2b_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2b_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl2b_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - dirty, LSB - valid' fields from level 2 tag store

	type lvl2_ts_tag_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	type lvl2_ts_bk_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);
	type lvl2_ts_ass_t is array (0 to LVL2C_ASSOCIATIVITY-1) of std_logic_vector(LVL2C_NWAY_BKK_WIDTH-1 downto 0);

	signal lvl2a_ts_tag_s : lvl2_ts_tag_t;
	signal lvl2a_ts_bkk_s : lvl2_ts_bk_t;
	signal lvl2a_ts_nbkk_s : lvl2_ts_ass_t;
	-- 'tag' and 'bookkeeping bits: MSB - dirty, LSB - valid' fields from level 2 tag store
	signal lvl2b_ts_tag_s : lvl2_ts_tag_t;
	signal lvl2b_ts_bkk_s : lvl2_ts_bk_t;
	signal lvl2b_ts_nbkk_s : lvl2_ts_ass_t;


	-- singals that find index of wanted way in n-way level2 cache
	--signal lvl2_hit_index : std_logic_vector(LVL2C_ASSOC_LOG2-1 downto 0);
	--signal lvl2_dirty_index : std_logic_vector(LVL2C_ASSOC_LOG2-1 downto 0);
	--signal lvl2_invalid_index : std_logic_vector(LVL2C_ASSOC_LOG2-1 downto 0);
	--hsignal lvl2_victim_index : std_logic_vector(LVL2C_ASSOC_LOG2-1 downto 0);
	--signal lvl2_nextv_index : std_logic_vector(LVL2C_ASSOC_LOG2-1 downto 0);
	-- TODO Check if i can use integers
	signal lvl2_hit_index : integer;
	signal lvl2_dflush_index : integer;
	signal lvl2_iflush_index : integer;
	signal lvl2_dirty_index : integer;
	signal lvl2_ddirty_index : integer;
	signal lvl2_invalid_index : integer;
	signal lvl2_victim_index : integer;
	signal lvl2_nextv_index : integer;
	signal lvl2_rando_index : integer;

	signal lvl2_invalid_found_s : std_logic;
	signal lvl2_victim_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_nextv_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	signal lvl2_vnv_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0); 

	signal lvl2_d4s_valid_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0); -- invalid
	signal lvl2_d4s_dirty_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0); -- invalid
	signal lvl2_d4s_data_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0); -- invalid
	signal lvl2_d4s_instr_map : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0); -- invalid


	-- SIGNALS FOR COMPARING TAG VALUES
	signal lvl1ii_tag_cmp_s  : std_logic; -- incoming instruction address VS instruction tag store (hit in instruction cache)
	--signal lvl1id_tag_cmp_s  : std_logic; -- incoming instruction address VS data tag store (check for duplicate block in data)
	signal lvl1dd_tag_cmp_s  : std_logic; -- incoming data address VS data tag store (hit in data cache)
	--signal lvl1di_tag_cmp_s  : std_logic; -- incoming data address VS instruction tag store (check for duplicate in instr)
	signal lvl2a_tag_cmp_s  : std_logic; -- incoming address from missed lvl1 i/d cache VS lvl2 tag store
	signal lvl2b_tag_cmp_s  : std_logic; -- interconnect
	-- SIGNALS TO INDICATE CACHE HITS/MISSES
	signal lvl1d_c_hit_s  : std_logic; -- hit in data cache
	--signal lvl1d_c_dup_s  : std_logic; -- addressing block in data cache that has duplicate in instruction cache
	signal lvl1i_c_hit_s  : std_logic; -- hit in instruction cache
	--signal lvl1i_c_dup_s  : std_logic; -- addressing block in instruction cache that has duplicate in data cache
	signal lvl2a_c_hit_s  : std_logic; -- hit in lvl 2 cache
	signal lvl2b_c_hit_s  : std_logic; -- hit in lvl 2 cache
	signal lvl2a_c_dirty_s  : std_logic; -- hit in lvl 2 cache

	signal data_access_s  : std_logic; -- current instr reads or writes to data memory 
	signal data_ready_s  : std_logic; -- hit in lvl 2 cache
	signal instr_ready_s  : std_logic; -- hit in lvl 2 cache

	signal check_lvl2_s  : std_logic; -- hit in instruction cache
	signal flush_lvl1d_s  : std_logic; -- hit in instruction cache
	signal invalidate_lvl1d_s  : std_logic; -- hit in instruction cache
	signal invalidate_lvl1i_s  : std_logic; -- hit in instruction cache
	signal lvl1_valid_s  : std_logic; -- hit in instruction cache

	-- Cache controler state
	type cc_state is (idle, set_dirty, check_lvl2_instr, check_lvl2_data, fetch_instr, fetch_data, flush_data, flush_depandant_data, update_data_ts, update_instr_ts);
	type mc_state is (idle, flush, fetch); 
	-- cc -  cache controller fsm
	signal cc_state_reg, cc_state_next: cc_state;
	signal mc_state_reg, mc_state_next: mc_state;
	-- cc -  cache controller counter 
	-- (-2) because 4 bytes are written at once, 32 bit bus - 4 bytes
	signal cc_counter_reg, cc_counter_incr, cc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	signal mc_counter_reg, mc_counter_incr, mc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	signal evictor_reg, evictor_next, evictor_rotr1, evictor_rotr2, evictor_rotr3 : std_logic_vector(LVL2C_ASSOCIATIVITY-1 downto 0);
	
	constant COUNTER_MAX : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'1');
	constant COUNTER_MIN : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'0');


begin


	-- Separate input ports into fields for easier menagment
	-- From data cache
	lvl1d_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1d_c_idx_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1d_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1d_c_addr_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache 
	lvl1i_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1i_c_idx_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1i_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1i_c_addr_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- TODO this will be controlled by FSM
	-- From level1
	--lvl2ia_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	--lvl2da_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl2ia_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2ia_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2ia_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);
	lvl2da_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2da_c_idx_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2da_c_addr_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto 0);
	-- This is for flushing and invalidating, need saved adress not current
	lvl2dl_c_addr_s <= lvl1da_ts_tag_s & lvl1d_c_idx_s;
	lvl2dl_c_idx_s <= lvl2dl_c_addr_s(LVL2C_INDEX_WIDTH-1 downto 0);
	lvl2dl_c_tag_s <= lvl2dl_c_addr_s(LVL2C_INDEX_WIDTH+LVL2C_TAG_WIDTH-1 downto LVL2C_INDEX_WIDTH);

	lvl2il_c_addr_s <= lvl1ia_ts_tag_s & lvl1i_c_idx_s;
	lvl2il_c_idx_s <= lvl2il_c_addr_s(LVL2C_INDEX_WIDTH-1 downto 0);
	lvl2il_c_tag_s <= lvl2il_c_addr_s(LVL2C_INDEX_WIDTH+LVL2C_TAG_WIDTH-1 downto LVL2C_INDEX_WIDTH);
	--lvl2if_c_addr_s <= lvl1ia_ts_tag_s & lvl1i_c_idx_s;
	--lvl2if_c_idx_s <= lvl2if_c_addr_s(LVL2C_INDEX_WIDTH downto 0);

	-- TODO this will be controlled by interprocessor module
	--lvl2b_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	--lvl2b_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	--lvl2b_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	--lvl2b_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);

	-- Forward address and get tag + bookkeeping bits from tag store
	-- Data tag store port A - data address
	lvl1da_ts_tag_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	lvl1da_ts_bkk_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- NOTE uncoment port B if there is a switch to dual port for tag store
	-- Data tag store port B - instruction address 
	--addrb_data_tag_s <= lvl1i_c_idx_s;
	--lvl1db_ts_tag_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	--lvl1db_ts_bkk_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH+LVL1IC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);

	-- Instruction tag store port A - instruction address
	lvl1ia_ts_tag_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	--lvl1ia_ts_bkk_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH+LVL1IC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- NOTE uncoment port B if there is a switch to dual port for tag store
	-- Instruction tag store port B  - data address
	--addrb_instr_tag_s <= lvl1d_c_idx_s;
	--lvl1ib_ts_tag_s <= dread_data_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	--lvl1ib_ts_bkk_s <= dread_data_tag_s(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);

	-- lvl2 tag store, for LVL1
	--addra_lvl2_tag_s <= lvl2a_c_idx_s; -- TODO set either data or instruction cache address in FSM  (the one that missed)

	extract_ts_fields: process (dreada_lvl2_tag_s,dreadb_lvl2_tag_s) is
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

	invalid_pcoder: process (lvl2a_ts_bkk_s,lvl2a_ts_nbkk_s) is
	begin
			--lvl2_invalid_map(i) <= not (lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID) or lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY));
			for i in(LVL2C_ASSOCIATIVITY-1) downto 0 loop
				if (lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='0' and lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='0' and lvl2a_ts_nbkk_s(i) = "00") then
					--lvl2_invalid_index <= std_logic_vector(to_unsigned(i,LVL2C_ASSOC_LOG2));
					lvl2_invalid_index <= i;
					lvl2_invalid_found_s <= '1';
					exit;
				else
					--lvl2_invalid_index <= (others => '0');
					lvl2_invalid_index <= 0;
					lvl2_invalid_found_s <= '0';
				end if;
			end loop;
	end process;
	
	-- Compare tags
	lvl1dd_tag_cmp_s <= '1' when lvl1d_c_tag_s = lvl1da_ts_tag_s else '0';
	--lvl1di_tag_cmp_s <= '1' when lvl1d_c_tag_s = lvl1ib_ts_tag_s else '0';
	lvl1ii_tag_cmp_s <= '1' when lvl1i_c_tag_s = lvl1ia_ts_tag_s else '0';
	--lvl1id_tag_cmp_s <= '1' when lvl1i_c_tag_s = lvl1db_ts_tag_s else '0';
	--lvl2a_tag_cmp_s <= '1' when lvl2a_c_tag_s = lvl2a_ts_tag_s else '0'; 
	--lvl2b_tag_cmp_s <= '1' when lvl2b_c_tag_s = lvl2b_ts_tag_s else '0'; 
	
	-- Cache hit/miss indicator flags => same tag + valid
	lvl1d_c_hit_s <= lvl1dd_tag_cmp_s and lvl1da_ts_bkk_s(0); 
	lvl1i_c_hit_s <= lvl1ii_tag_cmp_s and lvl1ia_ts_valid_reg(to_integer(unsigned(addra_instr_tag_s)));
	-- NOTE uncoment if explicit resolution of self modifying code is needed
	--lvl1d_c_dup_s <= lvl1di_tag_cmp_s and lvl1ib_ts_bkk_s(0);
	--lvl1i_c_dup_s <= lvl1id_tag_cmp_s and lvl1db_ts_bkk_s(0);
	--lvl1i_c_haz_s <= lvl1i_c_dup_s and lvl1db_ts_bkk_s(1);
	--lvl2a_c_hit_s <= lvl2a_tag_cmp_s and lvl2a_ts_bkk_s(0); 
	--lvl2b_c_hit_s <= lvl2b_tag_cmp_s and lvl2b_ts_bkk_s(0);

	-- TODO check if this shit can even work outside of fsm
   data_access_s <= '1' when ((we_data_i /= "0000") or (re_data_i='1')) else '0';

	data_ready_s <= ((lvl1d_c_hit_s or (not data_access_s)) and lvl1_valid_s);
	data_ready_o <= data_ready_s;

	instr_ready_s <= (lvl1i_c_hit_s and lvl1_valid_s);
	instr_ready_o <= instr_ready_s;

	-- Adder for counters 
	cc_counter_incr <= std_logic_vector(unsigned(cc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH-2));
	mc_counter_incr <= std_logic_vector(unsigned(mc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH-2));

	evictor_rotr1 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 1));
	evictor_rotr2 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 2));
	evictor_rotr3 <= std_logic_vector(rotate_right(unsigned(evictor_reg), 3));

	evictor_logic: process(lvl2_vnv_map, evictor_rotr1, evictor_rotr2, evictor_rotr3) is 
	-- TODO please replace this garbage with better solution, NOTE updated to even worse trash
	begin
		if ((evictor_rotr1 and lvl2_vnv_map) = std_logic_vector(to_unsigned(0,LVL2C_ASSOCIATIVITY))) then
			evictor_next <= evictor_rotr1;
		elsif ((evictor_rotr2 and lvl2_vnv_map) = std_logic_vector(to_unsigned(0,LVL2C_ASSOCIATIVITY))) then
			evictor_next <= evictor_rotr2;
		else 
			evictor_next <= evictor_rotr3;
		end if;
		--if (evictor_rotr1 /= std_logic_vector(to_unsigned(lvl2_victim_index,LVL2C_ASSOC_LOG2)) and
		  	 --evictor_rotr1 /= std_logic_vector(to_unsigned(lvl2_nextv_index,LVL2C_ASSOC_LOG2)))then
			--evictor_next <= evictor_reg;
		--elsif (evictor_rotr1 /= std_logic_vector(to_unsigned(lvl2_victim_index,LVL2C_ASSOC_LOG2)) and 
				 --evictor_rotr1 /= std_logic_vector(to_unsigned(lvl2_nextv_index,LVL2C_ASSOC_LOG2)))then
			--evictor_next <= evictor_rotr1;
		--else
			--evictor_next <= evictor_rotr2;
		--end if;
	end process;
	

	-- TODO DESIGN FOR SIMULATION, DELETE LATER
	design_for_simulation_map: process (lvl2a_ts_bkk_s) is 
	begin
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
		   lvl2_d4s_data_map(i) <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_DATA);
			lvl2_d4s_instr_map(i)  <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_INSTR);
		   lvl2_d4s_valid_map(i) <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID);
			lvl2_d4s_dirty_map(i)  <= lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY);
		end loop;
	end process;

	extract_vnv_map: process (lvl2a_ts_nbkk_s) is
	begin
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
		    lvl2_victim_map(i) <= lvl2a_ts_nbkk_s(i)(LVL2C_BKK_VICTIM);
			lvl2_nextv_map(i)  <= lvl2a_ts_nbkk_s(i)(LVL2C_BKK_NEXTV);
		end loop;
	end process;
	
	lvl2_vnv_map <= (lvl2_victim_map or lvl2_nextv_map);

	pcoder_rando_index: process(evictor_reg) is -- Check if this is ok or evictor_next is needed
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

	pcoder_hit_detect: process(lvl2a_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if ((lvl2a_c_tag_s = lvl2a_ts_tag_s(i)) and lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='1') then
				--lvl2_hit_index <= std_logic_vector(to_unsigned(i,LVL2C_ASSOC_LOG2));
				lvl2_hit_index <= i;
				lvl2a_c_hit_s <= '1';
				exit;
			else
				--lvl2_hit_index <= (others => '0');
				lvl2_hit_index <= 0;
				lvl2a_c_hit_s <= '0';
			end if;
		end loop;
	end process;

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

	--pcoder_dirty_detect: process(lvl2dl_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	--begin
		--for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			--if ((lvl2dl_c_tag_s = lvl2a_ts_tag_s(i)) and lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='0' and lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='1') then
				--lvl2_dirty_index <= i;
				--exit;
			--else
				--lvl2_dirty_index <= 0;
			--end if;
		--end loop;
	--end process;
--
	--pcoder_depandant_dirty_detect: process(lvl2ia_c_tag_s,lvl2a_ts_tag_s, lvl2a_ts_bkk_s) is
	--begin
		--for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			--if ((lvl2ia_c_tag_s = lvl2a_ts_tag_s(i)) and lvl2a_ts_bkk_s(i)(LVL2C_BKK_VALID)='0' and lvl2a_ts_bkk_s(i)(LVL2C_BKK_DIRTY)='1') then
				--lvl2_ddirty_index <= i;
				--exit;
			--else
				--lvl2_ddirty_index <= 0;
			--end if;
		--end loop;
	--end process;

	pcoder_victim_detect: process (lvl2a_ts_nbkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if (lvl2a_ts_nbkk_s(i)(LVL2C_BKK_VICTIM)= '1') then
				--lvl2_victim_index <= std_logic_vector(to_unsigned(i,LVL2C_ASSOC_LOG2));
				lvl2_victim_index <= i;
				exit;
			else
				--lvl2_victim_index <= (others => '0');
				lvl2_victim_index <= 0;
			end if;
		end loop;
	end process;

	pcoder_nextv_detect: process (lvl2a_ts_nbkk_s) is
	begin
		for i in (LVL2C_ASSOCIATIVITY-1) downto 0 loop
			if (lvl2a_ts_nbkk_s(i)(LVL2C_BKK_NEXTV)= '1') then
				--lvl2_nextv_index <= std_logic_vector(to_unsigned(i,LVL2C_ASSOC_LOG2));
				lvl2_nextv_index <= i;
				exit;
			else
				--lvl2_nextv_index <= (others => '0');
				lvl2_nextv_index <= 1;
			end if;
		end loop;
	end process;
	
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

	-- Sequential logic - regs
	regs : process(clk)is
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

	-- TODO check this: if processor never writes to instr cache, it doesn't need dirty bit
	-- TODO second to that, level2 cache can leasurly be simple dual port RAM 
	-- TODO as one port will never change the contents of lvl2 Cache
	-- TODO check this: if processor never writes to instr cache, it doesnt need flush state
	-- TODO if this somehow saves logic in end product remove it
	-- FSM that controls communication between lvl1 instruction cache and lvl2 shared cache

	fsm_cache : process(cc_state_reg, lvl1i_c_addr_s, lvl1d_c_addr_s, lvl2ia_c_tag_s, dreada_instr_cache_s, lvl1i_c_tag_s,
		we_data_i, dwrite_data_i, dreada_data_cache_s, lvl1i_c_hit_s, lvl2ia_c_addr_s, lvl2a_c_hit_s,
		lvl1d_c_hit_s, lvl1da_ts_bkk_s, lvl2da_c_idx_s, cc_counter_reg, cc_counter_incr, lvl2ia_c_idx_s, lvl1ia_ts_valid_reg,
		lvl2a_ts_tag_s, lvl1i_c_idx_s, lvl2da_c_tag_s, lvl1d_c_idx_s, dreada_lvl2_cache_s,
		lvl1d_c_tag_s, data_access_s, re_data_i, lvl1da_ts_tag_s,  flush_lvl1d_s, invalidate_lvl1d_s, invalidate_lvl1i_s,
		lvl2il_c_idx_s, lvl2_hit_index, lvl2a_ts_nbkk_s, lvl1ia_ts_tag_s, lvl2dl_c_idx_s, lvl2dl_c_tag_s, 
		lvl2_nextv_index, lvl2_victim_index, lvl2_rando_index,lvl2_dflush_index,lvl2_iflush_index) is
	begin
		check_lvl2_s <= '0';
		lvl1_valid_s <= '1';
		-- for FSM
		cc_state_next <= idle;
		cc_counter_next <= (others => '0');
		-- Misc
		lvl2a_c_idx_s <= lvl2ia_c_idx_s;
		lvl2a_c_tag_s <= lvl2ia_c_tag_s;
		-- LVL1 instruction cache and tag
		lvl1ia_ts_valid_next <= lvl1ia_ts_valid_reg;
		wea_instr_tag_s <= '0';
		addra_instr_tag_s <= lvl1i_c_idx_s;
		dwritea_instr_tag_s <= (others => '0');
		wea_instr_cache_s <= (others => '0');
		addra_instr_cache_s <= lvl1i_c_addr_s((LVL1C_ADDR_WIDTH-1) downto 2);
		dwritea_instr_cache_s <= (others => '0');
		dread_instr_o <= dreada_instr_cache_s;
		-- LVL1 data cache and tag
		addra_data_tag_s <= lvl1d_c_idx_s;
		wea_data_tag_s <= '0';
		dwritea_data_tag_s <= (others => '0');
		wea_data_cache_s <= we_data_i;
		addra_data_cache_s <= lvl1d_c_addr_s((LVL1C_ADDR_WIDTH-1) downto 2);
		dwritea_data_cache_s <= dwrite_data_i;
		dread_data_o <= dreada_data_cache_s;
		-- LVL2 cache and tag
		addra_lvl2_tag_s <= lvl2da_c_idx_s;
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
			addra_lvl2_cache_s(i) <= lvl2ia_c_addr_s((LVL2C_ADDR_WIDTH-1) downto 2);
			wea_lvl2_cache_s(i) <= (others => '0');
			dwritea_lvl2_cache_s(i) <= (others => '0'); 
			wea_lvl2_tag_s(i) <= '0';
			dwritea_lvl2_tag_s(i) <= (others => '0'); 
		end loop;
				
		case (cc_state_reg) is
			when idle =>
				-- ACCESS TO INSTR MEMORY
				if(lvl1i_c_hit_s = '0') then -- instr cache miss
					cc_state_next <= check_lvl2_instr;
					addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				end if;
				-- ACCESS TO DATA MEMORY
				if (data_access_s = '1') then --its only then a data memory access
					if(lvl1d_c_hit_s = '1') then 
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
							addra_data_cache_s <= lvl1d_c_idx_s & cc_counter_reg;
						else
							cc_state_next <= check_lvl2_data;
						end if;
					end if;
				end if;
				
			when set_dirty =>
				cc_state_next <= idle;
				-- invalidate lvl2
				lvl2a_c_tag_s <= lvl2da_c_tag_s;
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				wea_lvl2_tag_s(lvl2_hit_index) <= '1';
				-- dirty but invalid, as the newer data is in data cache
				dwritea_lvl2_tag_s(lvl2_hit_index) <= 
					lvl2a_ts_nbkk_s(lvl2_hit_index) & lvl2a_ts_bkk_s(lvl2_hit_index)(3 downto 2) & "10" & lvl2a_ts_tag_s(lvl2_hit_index);

			when check_lvl2_instr => 
				check_lvl2_s <= '1';
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;

				if (lvl2a_c_hit_s = '1') then
					cc_state_next <= fetch_instr;
					--new block coming, previous block is going to be removed from lvl1ic
					addra_lvl2_tag_s <= lvl2il_c_idx_s;
					addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
				elsif (flush_lvl1d_s = '1') then
					cc_state_next <= flush_depandant_data;
				else
					if(invalidate_lvl1d_s = '1')then
						addra_data_tag_s <= lvl1i_c_idx_s;
						dwritea_data_tag_s <= (others => '0'); -- NOTE this changed to zeros from lvl1da_ts_tag_s;  
						-- TODO check why wait for tag if it's being invalidated
						wea_data_tag_s <= '1';
						lvl1_valid_s <= '0';
					end if;
					if (invalidate_lvl1i_s = '1') then 
						--addra_instr_tag_s <= lvl1i_c_idx_s;
						--dwritea_instr_tag_s <= lvl1ia_ts_tag_s; 
						lvl1ia_ts_valid_next (to_integer(unsigned(lvl1i_c_idx_s))) <= '0';
						--wea_instr_tag_s <= '1';
					end if;

					cc_state_next <= check_lvl2_instr; -- stay here if lvl2 is not ready
				end if;

			when check_lvl2_data => 
				check_lvl2_s <= '1';
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_idx_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s;

				if (lvl2a_c_hit_s = '1') then
					cc_state_next <= fetch_data;
					-- new block coming, previous block is going to be removed from lvl1dc
					addra_lvl2_tag_s <= lvl2dl_c_idx_s;
					addra_lvl2_cache_s(lvl2_hit_index) <= lvl2da_c_idx_s & cc_counter_reg;
				else
					cc_state_next <= check_lvl2_data; -- stay here if lvl2 is not ready
					if (invalidate_lvl1i_s = '1') then
						--addra_instr_tag_s <= lvl1d_c_idx_s;
						--dwritea_instr_tag_s <= "00" & lvl1ia_ts_tag_s; 
						lvl1ia_ts_valid_next (to_integer(unsigned(lvl1d_c_idx_s))) <= '0';
						--wea_instr_tag_s <= '1';
						--lvl1_valid_s <= '0';
					end if;
					if (invalidate_lvl1d_s = '1') then
						addra_data_tag_s <= lvl1d_c_idx_s;
						dwritea_data_tag_s <= (others => '0'); -- NOTE this changed to zeros from lvl1da_ts_tag_s;
						-- TODO check why wait for tag if it's being invalidated
						wea_data_tag_s <= '1';
					end if;
				end if;



			when fetch_instr => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_incr;
				addra_instr_cache_s <= lvl1i_c_idx_s & cc_counter_reg;
				dwritea_instr_cache_s <= dreada_lvl2_cache_s(lvl2_hit_index);
				wea_instr_cache_s <= "1111";

				cc_counter_next <= cc_counter_incr;

				-- TODO depending on mc fsm, see if this is needed or not
				-- NOTE this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;
				lvl2a_c_idx_s <= lvl2ia_c_idx_s;

				if(cc_counter_reg = COUNTER_MIN)then 
					-- block is going to be removed from lvl1ic
					addra_lvl2_tag_s <= lvl2il_c_idx_s;
					dwritea_lvl2_tag_s(lvl2_iflush_index) <= 
						lvl2a_ts_nbkk_s(lvl2_iflush_index) & (lvl2a_ts_bkk_s(lvl2_iflush_index) and "1011") & lvl2a_ts_tag_s(lvl2_iflush_index);
					wea_lvl2_tag_s(lvl2_iflush_index) <= '1';
				end if;

				if(cc_counter_reg = COUNTER_MAX)then 
					cc_state_next <= update_instr_ts;
				else
					cc_state_next <= fetch_instr;
				end if;


			when fetch_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2da_c_idx_s & cc_counter_incr;
				addra_data_cache_s <= lvl1d_c_idx_s & cc_counter_reg;
				dwritea_data_cache_s <= dreada_lvl2_cache_s(lvl2_hit_index);
				wea_data_cache_s <= "1111";

				cc_counter_next <= cc_counter_incr;

				-- TODO depending on mc fsm, see if this is needed or not 
				-- NOTE this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s; 
				lvl2a_c_idx_s <= lvl2da_c_idx_s;

				if(cc_counter_reg = COUNTER_MIN)then 
					-- block is going to be removed from lvl1dc
					addra_lvl2_tag_s <= lvl2dl_c_idx_s;
					dwritea_lvl2_tag_s(lvl2_dflush_index) <=  
						lvl2a_ts_nbkk_s(lvl2_dflush_index) & (lvl2a_ts_bkk_s(lvl2_dflush_index) and "0111") & lvl2a_ts_tag_s(lvl2_dflush_index);
					wea_lvl2_tag_s(lvl2_dflush_index) <= '1';
				end if;

				if(cc_counter_reg = COUNTER_MAX)then 
					-- finished with writing entire block
					cc_state_next <= update_data_ts;
				else
					cc_state_next <= fetch_data;
				end if;

			when flush_depandant_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				-- lvl1i cache is asking for this data from level 2
				addra_lvl2_cache_s(lvl2_hit_index) <= lvl2ia_c_idx_s & cc_counter_reg;
				addra_data_cache_s <= lvl1i_c_idx_s & cc_counter_reg;
				-- self - flush
				-- NOTE depending on mc fsm, see if this is needed or not
				-- NOTE this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				--lvl2a_c_tag_s <= lvl2ia_c_tag_s;
				--lvl2a_c_idx_s <= lvl2ia_c_idx_s;

				dwritea_lvl2_cache_s(lvl2_hit_index) <= dreada_data_cache_s;
				wea_lvl2_cache_s(lvl2_hit_index)<= "1111";

				cc_counter_next <= cc_counter_incr;

				if(cc_counter_reg = COUNTER_MAX)then 
					cc_state_next <= check_lvl2_instr;
					addra_lvl2_tag_s <= lvl2ia_c_idx_s;
					-- write new tag to tag store, set valid, reset dirty
					dwritea_lvl2_tag_s(lvl2_hit_index) <= 
						lvl2a_ts_nbkk_s(lvl2_hit_index) & (lvl2a_ts_bkk_s(lvl2_hit_index) or "0011") & lvl2a_ts_tag_s(lvl2_hit_index); 
					wea_lvl2_tag_s(lvl2_hit_index) <= '1';
				else
					cc_state_next <= flush_depandant_data;
				end if;

			when flush_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				-- this block in lvl2 is being evicted
				addra_lvl2_cache_s(lvl2_dflush_index) <= lvl2dl_c_idx_s & cc_counter_reg;
				addra_data_cache_s <= lvl1d_c_idx_s & cc_counter_reg;
				-- NOTE depending on mc fsm, see if this is needed or not
				-- NOTE this is needed because fetching in cc and mc are overlapped
				addra_lvl2_tag_s <= lvl2dl_c_idx_s;
				--lvl2a_c_tag_s <= lvl2dl_c_tag_s;
				--lvl2a_c_idx_s <= lvl2dl_c_idx_s;

				dwritea_lvl2_cache_s(lvl2_dflush_index) <= dreada_data_cache_s;
				wea_lvl2_cache_s(lvl2_dflush_index)<= "1111";

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
				-- NOTE this is needed because fetching in cc and mc are overlapped
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
				lvl1ia_ts_valid_next (to_integer(unsigned(lvl1i_c_idx_s))) <= '1';
				dwritea_instr_tag_s <= lvl1i_c_tag_s; 
				wea_instr_tag_s <= '1';

			when update_data_ts => 
				-- NOTE this is needed because fetching in cc and mc are overlapped
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
				dwritea_data_tag_s <= "01" & lvl1d_c_tag_s; 
				wea_data_tag_s <= '1';

			when others =>
		end case;
	end process;

	fsm_inter_proc : process(mc_state_reg, mc_counter_reg, mc_counter_incr, dread_phy_i,
									lvl2a_c_idx_s, lvl2a_c_tag_s, lvl2a_c_hit_s, lvl2a_ts_bkk_s, lvl2a_ts_tag_s,
									check_lvl2_s, lvl2b_ts_tag_s, lvl2b_ts_bkk_s, dreadb_lvl2_cache_s, lvl2b_ts_nbkk_s,
									lvl2_victim_index, lvl2_nextv_index, lvl2_rando_index, lvl2_invalid_found_s, lvl2_invalid_index) is
	begin
		-- for FSM
		mc_state_next <= idle;
		mc_counter_next <= (others => '0');
		-- LVL 2 signals ports B
		for i in 0 to (LVL2C_ASSOCIATIVITY-1) loop
			addrb_lvl2_cache_s(i) <= (others => '0');
			web_lvl2_cache_s(i) <= (others => '0');
			dwriteb_lvl2_cache_s(i) <= (others => '0'); 
			web_lvl2_tag_s(i) <= '0';
			dwriteb_lvl2_tag_s(i) <= (others => '0'); 
		end loop;
		addrb_lvl2_tag_s <= lvl2a_c_idx_s; -- NOTE can remove this signal as it's the same as addra_lvl2_tag_s ? is this version more readable?
		-- MEMORY interface signals (bus)
		-- dread_phy_i -> use this to read data from bus
		addr_phy_o <= (others => '0');
		dwrite_phy_o <= (others => '0');
		we_phy_o <= (others => '0');
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
							end if;
							-- when evicting block, invalidate if block is in lvl1 instr cache
							if (lvl2a_ts_bkk_s(lvl2_victim_index)(LVL2C_BKK_INSTR)='1')then 
								invalidate_lvl1i_s <= '1';
							end if;
					end case;
				end if;

			when flush =>
				addr_phy_o <= lvl2b_ts_tag_s(lvl2_victim_index) & lvl2a_c_idx_s & mc_counter_reg & "00";
				addrb_lvl2_cache_s(lvl2_victim_index) <= lvl2a_c_idx_s & mc_counter_incr;
				dwrite_phy_o <= dreadb_lvl2_cache_s(lvl2_victim_index);
				we_phy_o <= "1111";

				mc_counter_next <= mc_counter_incr;

				addrb_lvl2_tag_s <= lvl2a_c_idx_s;
				if(mc_counter_reg = COUNTER_MIN)then  -- because of read first mode
					-- invalidate so the next state after idle is fetch
					-- NOTE: when invalidating, tag doesn't matter? 
					--UPDATE NOTE: Yes it does, cunt.
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
				web_lvl2_cache_s(lvl2_victim_index) <= "1111";

				mc_counter_next <= mc_counter_incr;

				addrb_lvl2_tag_s <= lvl2a_c_idx_s;
				if(mc_counter_reg = COUNTER_MIN) then  -- because of the read first mode
					dwriteb_lvl2_tag_s(lvl2_victim_index) <= lvl2b_ts_nbkk_s(lvl2_victim_index) & "0001" & lvl2a_c_tag_s;
					web_lvl2_tag_s(lvl2_victim_index) <= '1';
				end if;

				if(mc_counter_reg = COUNTER_MAX)then 
					mc_state_next <= idle;
					-- victim becomes ordinary block
					dwriteb_lvl2_tag_s(lvl2_victim_index) <= "00" & lvl2b_ts_bkk_s(lvl2_victim_index) & lvl2b_ts_tag_s(lvl2_victim_index); 
					web_lvl2_tag_s(lvl2_victim_index) <= '1';
					-- nextvictim becomes victim
					dwriteb_lvl2_tag_s(lvl2_nextv_index) <=  "10" & lvl2b_ts_bkk_s(lvl2_nextv_index) & lvl2b_ts_tag_s(lvl2_nextv_index); 
					web_lvl2_tag_s(lvl2_nextv_index) <= '1';
					
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

	--********** LEVEL 1 CACHE  **************
	-- INSTRUCTION CACHE
	-- TODO double check this address logic, change if unaligned accesses are implemented
	-- TODO 32 bit address will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	--we_instr_cache_s <= "0000"; NOTE nah
	regcea_instr_cache_s <= '0';
	ena_instr_cache_s <= '1';
	rsta_instr_cache_s <= '0';
	-- TODO make a driver for dina, wea, douta
	-- Instantiation of instruction cache
	instruction_cache : entity work.RAM_sp_ar_bw(rtl)
		generic map (
			NB_COL => LVL1C_NUM_COL,
			COL_WIDTH => LVL1C_COL_WIDTH,
			RAM_DEPTH => LVL1C_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "" 
		)
		port map  (
			clk   => clk,
			addra  => addra_instr_cache_s,
			dina   => dwritea_instr_cache_s,
			wea    => wea_instr_cache_s,
			ena    => ena_instr_cache_s,
			rsta   => rsta_instr_cache_s,
			regcea => regcea_instr_cache_s,
			douta  => dreada_instr_cache_s
		);

 -- TAG STORE FOR INSTRUCTION CACHE
 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
 --	rst_instr_tag_s <= reset;
	--instantiation of tag store
	ena_instr_tag_s <= '1'; --NOTE right?
	instruction_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => LVL1C_TAG_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			--global
			clk => clk,
			--port a
			addra => addra_instr_tag_s,
			dina => dwritea_instr_tag_s,
			ena => ena_instr_tag_s,
			douta => dreada_instr_tag_s,
			wea => wea_instr_tag_s
			--port b
			--addrb => addrb_instr_tag_s,
			--dinb => dwriteb_instr_tag_s,
			--enb => enb_instr_tag_s,
			--doutb => dreadb_instr_tag_s,
			--web => web_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	-- TODO double check this address logic!, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit address if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	rsta_data_cache_s <= '0';
	-- TODO check if this can be just data_access? Can there be flush while data acess is zero?
	ena_data_cache_s <= '1'; -- data_access_s; -- check if this shit works *thought* enable only on data acess
	regcea_data_cache_s <= '0';
	-- Instantiation of data cache
	data_cache : entity work.RAM_sp_ar_bw(rtl)
		generic map (
				NB_COL => LVL1C_NUM_COL,
				COL_WIDTH => LVL1C_COL_WIDTH,
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
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			--global
			clk => clk,
			--port a
			addra => addra_data_tag_s,
			dina => dwritea_data_tag_s,
			douta => dreada_data_tag_s,
			wea => wea_data_tag_s,
			ena => ena_data_tag_s
			--port b
			--doutb => dreadb_data_tag_s,
			--addrb => addrb_data_tag_s,
			--dinb => dwriteb_data_tag_s,
			--web => web_data_tag_s,
			--enb => ena_data_tag_s
		);



	--********** LEVEL 2 CACHE  **************
	-- Port A signals
	rsta_lvl2_cache_s <= reset; -- TODO is it needed? this is not a real reset signal, more like output enable
	rstb_lvl2_cache_s <= reset; -- TODO is it needed?
	ena_lvl2_cache_s <= '1';
	enb_lvl2_cache_s <= '1';
	regcea_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	regceb_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	-- TODO in this type of bram, 2 LSB bits are removed, implement this here or in cache controller!!!
	-- Instantiation of level 2 cache
	lvl2_cache_generate:
	for i in 0 to LVL2C_ASSOCIATIVITY-1 generate

	level_2_cache : entity work.RAM_tdp_rf_bw(rtl)
		generic map (
			NB_COL => LVL2C_NUM_COL,
			COL_WIDTH => LVL2C_COL_WIDTH,
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
			 RAM_DEPTH => LVL2C_NB_BLOCKS
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
