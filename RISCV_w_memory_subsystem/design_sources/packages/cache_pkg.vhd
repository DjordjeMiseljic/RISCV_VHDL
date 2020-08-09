library ieee;
use ieee.std_logic_1164.all;

-- TODO RAM initialization functions need to be defined in this package
-- TODO Paths in RAM initialization function need to be relative, so tcl scripting will work
package cache_pkg is
	
	-- Integer log2 function
   function clogb2 (depth: in natural) return integer;

	-- *************** CONSTANTS / PARAMETERS ***************

	-- Physical adress size and width
	constant PHY_ADDR_SPACE : integer := 512*1024*1024;
	constant PHY_ADDR_WIDTH : integer := clogb2(PHY_ADDR_SPACE);
	constant TS_BRAM_TYPE : string := "LOW_LATENCY";

	-- 
	-- Block size in bytes, this can be changed, as long as it is power of 2
	constant BLOCK_SIZE : integer := 32;
	-- Number of bits needed to address all bytes inside the block
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	-- Width of data bus
	constant C_NUM_COL : integer := 4; -- fixed, word is 4 bytes
	constant C_COL_WIDTH : integer := 8; -- fixed, byte is 8 bits

	-- Basic Level 1 cache parameters:
	-- This will be size of both instruction and data caches in bytes
	constant LVL1_CACHE_SIZE : integer := 1024*8; 
	-- Derived cache parameters:
	-- Number of blocks in cache
	constant LVL1C_NB_BLOCKS : integer := LVL1_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth - number of words in cache - size in bytes divided by word size in bytes
	constant LVL1C_DEPTH : integer := LVL1_CACHE_SIZE/4; 
	-- Number of bits needed to address all bytes inside the cache
	constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
	constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	-- Number of bits needed to represent which block is currently in cache
	constant LVL1C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL1C_ADDR_WIDTH;
	-- Number of bits needed to save bookkeeping, 1 for valid, 1 for dirty
	constant LVL1DC_BKK_WIDTH : integer := 2;

	-- Basic Level 2 cache parameters:
	-- This will be size of both instruction and data caches in bytes
	constant LVL2_CACHE_SIZE : integer := 1024*16; 
	-- Derived cache parameters:
	-- Number of blocks in cache
	constant LVL2C_NB_BLOCKS : integer := LVL2_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth is size in bytes divided by word size in bytes
	constant LVL2C_DEPTH : integer := LVL2_CACHE_SIZE/4; 
	-- Number of bits needed to address all bytes inside the cache
	constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
	constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	-- Number of bits needed to represent which block is currently in cache
	constant LVL2C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL2C_ADDR_WIDTH;
	-- Number of bits needed to save bookkeeping, 1 for data flag, 1 for instr flag, 1 for dirty, 1 for valid,
	constant LVL2C_BKK_WIDTH : integer := 4;

	-- Bit ordering in bookkeeping of tag store (not recommended to modify : not tested)
	constant LVL2C_BKK_VALID : integer := 0; -- MSB-5
	constant LVL2C_BKK_DIRTY : integer := 1; -- MSB-4
	constant LVL2C_BKK_INSTR : integer := 2; -- MSB-3
	constant LVL2C_BKK_DATA : integer := 3; -- MSB-2
	constant LVL2C_BKK_NEXTV : integer := 0; -- MSB-1
	constant LVL2C_BKK_VICTIM : integer := 1; -- MSB 

	-- Associativity of Level2 cache - number of ways
	constant	LVL2C_ASSOCIATIVITY : natural := 4;
	constant	LVL2C_ASSOC_LOG2 : natural := clogb2(LVL2C_ASSOCIATIVITY);
	-- Number of bits needed to save bookkeeping, 1 for victim, 1 for nextvictim
	constant LVL2C_NWAY_BKK_WIDTH : integer := 2;
		

	-- Records to be used as interface with RAMs
	type ram_port_type is record
		addra_lvl2_tag_s : std_logic_vector((LVL2C_ADDR_WIDTH-3) downto 0);
		wea_lvl2_tag_s : std_logic;
		dwritea_lvl2_tag_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
		dreada_lvl2_tag_s : std_logic_vector(C_NUM_COL*C_COL_WIDTH-1 downto 0);
		ena_lvl2_tag_s : std_logic;
		rsta_lvl2_tag_s : std_logic;
		regcea_lvl2_tag_s : std_logic;
	end record;


end cache_pkg;

package body cache_pkg is

	function clogb2 (depth: in natural) return integer is
	variable temp    : integer := depth;
	variable ret_val : integer := 0;
	begin
		 while temp > 1 loop
			  ret_val := ret_val + 1;
			  temp    := temp / 2;
		 end loop;
		 return ret_val;
	end function;

end package body cache_pkg;
