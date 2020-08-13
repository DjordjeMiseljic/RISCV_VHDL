----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/17/2020 02:38:58 AM
-- Design Name: 
-- Module Name: BRAM_tdp_rf_bw_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ram_pkg.all;
USE std.textio.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BRAM_tdp_rf_bw_tb is
--  Port ( );
end BRAM_tdp_rf_bw_tb;

architecture Behavioral of BRAM_tdp_rf_bw_tb is


-- The following is an instantiation template for BRAM_tdp_rf_bw
-- Component Declaration
-- Uncomment the below component declaration when using
constant RAM_DEPTH : integer := 1024;
constant NB_COL : integer := 4;
constant COL_WIDTH : integer := 8;
		  
component RAM_tdp_rf_bw is
generic (
		NB_COL : integer;
		COL_WIDTH : integer;
		RAM_DEPTH : integer;
		RAM_PERFORMANCE : string;
		INIT_FILE : string
		);
port (
		addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);
		addrb : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);
		dina  : in std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
		dinb  : in std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
		clk  : in std_logic;
		wea   : in std_logic_vector(NB_COL-1 downto 0);
		web   : in std_logic_vector(NB_COL-1 downto 0);
		ena   : in std_logic;
		enb   : in std_logic;
		rsta  : in std_logic;
		rstb  : in std_logic;
		regcea: in std_logic;
		regceb: in std_logic;
		douta : out std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);
		doutb : out std_logic_vector(NB_COL*COL_WIDTH-1 downto 0)
		);
end component;
		  

        signal addra_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        signal addrb_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        signal dina_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
        signal dinb_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port B RAM input data
        signal clk_s : std_logic;                       			  -- Clock
        signal wea_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
        signal web_s : std_logic_vector(NB_COL-1 downto 0); 	  -- Port B Write enable
        signal ena_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal enb_s : std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        signal rsta_s : std_logic;                       			  -- Port A Output reset (does not affect memory contents)
        signal rstb_s : std_logic;                       			  -- Port B Output reset (does not affect memory contents)
        signal regcea_s : std_logic;                       			  -- Port A Output register enable
        signal regceb_s : std_logic;                       			  -- Port B Output register enable
        signal douta_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
        signal doutb_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   	--  Port B RAM output data
begin
-- Instantiation
-- Uncomment the instantiation below when using
bram : RAM_tdp_rf_bw
generic map (
		NB_COL => NB_COL,
		COL_WIDTH => COL_WIDTH,
		RAM_DEPTH => RAM_DEPTH,
		RAM_PERFORMANCE => "LOW_LATENCY",
		INIT_FILE => "assembly_code.txt" 
)
port map  (
		addra  => addra_s,
		addrb  => addrb_s,
		dina   => dina_s,
		dinb   => dinb_s,
		clk   => clk_s,
		wea    => wea_s,
		web    => web_s,
		ena    => ena_s,
		enb    => enb_s,
		rsta   => rsta_s,
		rstb   => rstb_s,
		regcea => regcea_s,
		regceb => regceb_s,
		douta  => douta_s,
		doutb  => doutb_s
);


    clk_proc : process
    begin    
        clk_s <= '1', '0' after 100 ns;
        wait for 200 ns;
    end process;

	 ena_s <= '1';
	 rsta_s <= '1';
	 enb_s <= '1';
	 rstb_s <= '0';
	 wea_s <= "0000";
	 web_s <= "0000";

    addra_cycle : process
	 variable i : integer := 0;
    begin    
        addra_s <=std_logic_vector(to_unsigned(i, addra_s'length)); 
		  i := i + 1;
        wait for 400 ns;
    end process;

    addrb_cycle : process
	 variable i : integer := 10;
    begin    
        addrb_s <=std_logic_vector(to_unsigned(i, addrb_s'length)); 
		  i := i + 1;
		  wait for 400 ns;
    end process;

end Behavioral;
