
--  Xilinx True Dual Port RAM Byte Write Read First Single Clock
--  This code implements a parameterizable true dual port memory (both ports can read and write).
--  The behavior of this RAM is when data is written, the prior memory contents at the write
--  address are presented on the output port.  If the output data is
--  not needed during writes or the last read value is desired to be retained,
--  it is suggested to use a no change RAM as it is more power efficient.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.
--  Modify the parameters for the desired RAM characteristics.
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cache_pkg.all;
USE std.textio.all;

entity RAM_sdp_ar is
generic (
    RAM_WIDTH : integer := 8;                       -- Specify column width (byte width, typically 8 or 9)
    RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
    INIT_FILE : string := ""            -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );

port (
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        addrb : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port A RAM input data
        clk  : in std_logic;                       			  -- Clock
        wea   : in std_logic;	  -- Port A Write enable
        ena   : in std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        enb   : in std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0);   --  Port A RAM output data
        doutb : out std_logic_vector(RAM_WIDTH-1 downto 0)   	--  Port B RAM output data
    );

end RAM_sdp_ar;

architecture rtl of RAM_tdp_ar is

constant C_RAM_WIDTH : integer := RAM_WIDTH;
constant C_RAM_DEPTH : integer := RAM_DEPTH;
constant C_INIT_FILE : string := INIT_FILE;

type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal

-- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware
impure function initramfromfile (ramfilename : in string) return ram_type is
file ramfile	: text is in ramfilename;
variable ramfileline : line;
variable ram_s	: ram_type;
variable bitvec : bit_vector(C_RAM_WIDTH-1 downto 0);
begin
    for i in ram_type'range loop
        readline (ramfile, ramfileline);
        read (ramfileline, bitvec);
        ram_s(i) := to_stdlogicvector(bitvec);
    end loop;
    return ram_s;
end function;

impure function init_from_file_or_zeroes(ramfile : string) return ram_type is
begin
    if ramfile = "" then
        return (others => (others => '0'));
    else
        return InitRamFromFile(ramfile) ;
    end if;
end;

-- Following code defines RAM
signal ram_s : ram_type := init_from_file_or_zeroes(C_INIT_FILE);
attribute ram_style : string;
attribute ram_style of ram_s : signal is "distributed";

begin

	process(clk)
	begin
		 if(clk'event and clk = '1') then
			  if(ena = '1') then
					if(wea = '1') then
						 ram_s(to_integer(unsigned(addra))) <= dina;
					end if;
			  end if;


		 end if;
	end process;

	 douta <= ram_s(to_integer(unsigned(addra)));
	 doutb <= ram_s(to_integer(unsigned(addrb)));


end rtl;


							
							
