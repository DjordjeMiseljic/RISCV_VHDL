library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cache_pkg.all;

entity RISCV_AXI_v2_0 is
	generic (
		-- Users to add parameters here
        C_PHY_ADDR_WIDTH : integer := 32;
		C_TS_BRAM_TYPE : string := "HIGH_PERFORMANCE"; 
		C_BLOCK_SIZE : integer := 64;
		C_LVL1_CACHE_SIZE : integer := 1024*1;  -- 1KB
		C_LVL2_CACHE_SIZE : integer := 1024*4;  -- 4KB
		C_LVL2C_ASSOCIATIVITY : natural := 4;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

        
		-- Parameters of Axi Slave Bus Interface AXIL_S
		C_AXIL_S_DATA_WIDTH	: integer	:= 32;
		C_AXIL_S_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Master Bus Interface AXIF_M
		C_AXIF_M_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
		C_AXIF_M_ID_WIDTH	: integer	:= 1;
		C_AXIF_M_ADDR_WIDTH	: integer	:= 32;
		C_AXIF_M_DATA_WIDTH	: integer	:= 32;
		C_AXIF_M_AWUSER_WIDTH	: integer	:= 0;
		C_AXIF_M_ARUSER_WIDTH	: integer	:= 0;
		C_AXIF_M_WUSER_WIDTH	: integer	:= 0;
		C_AXIF_M_RUSER_WIDTH	: integer	:= 0;
		C_AXIF_M_BUSER_WIDTH	: integer	:= 0
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface AXIL_S
		axil_s_aclk	: in std_logic;
		axil_s_aresetn	: in std_logic;
		axil_s_awaddr	: in std_logic_vector(C_AXIL_S_ADDR_WIDTH-1 downto 0);
		axil_s_awprot	: in std_logic_vector(2 downto 0);
		axil_s_awvalid	: in std_logic;
		axil_s_awready	: out std_logic;
		axil_s_wdata	: in std_logic_vector(C_AXIL_S_DATA_WIDTH-1 downto 0);
		axil_s_wstrb	: in std_logic_vector((C_AXIL_S_DATA_WIDTH/8)-1 downto 0);
		axil_s_wvalid	: in std_logic;
		axil_s_wready	: out std_logic;
		axil_s_bresp	: out std_logic_vector(1 downto 0);
		axil_s_bvalid	: out std_logic;
		axil_s_bready	: in std_logic;
		axil_s_araddr	: in std_logic_vector(C_AXIL_S_ADDR_WIDTH-1 downto 0);
		axil_s_arprot	: in std_logic_vector(2 downto 0);
		axil_s_arvalid	: in std_logic;
		axil_s_arready	: out std_logic;
		axil_s_rdata	: out std_logic_vector(C_AXIL_S_DATA_WIDTH-1 downto 0);
		axil_s_rresp	: out std_logic_vector(1 downto 0);
		axil_s_rvalid	: out std_logic;
		axil_s_rready	: in std_logic;

		-- Ports of Axi Master Bus Interface AXIF_M
		axif_m_aclk	: in std_logic;
		axif_m_aresetn	: in std_logic;
		axif_m_awid	: out std_logic_vector(C_AXIF_M_ID_WIDTH-1 downto 0);
		axif_m_awaddr	: out std_logic_vector(C_AXIF_M_ADDR_WIDTH-1 downto 0);
		axif_m_awlen	: out std_logic_vector(7 downto 0);
		axif_m_awsize	: out std_logic_vector(2 downto 0);
		axif_m_awburst	: out std_logic_vector(1 downto 0);
		axif_m_awlock	: out std_logic;
		axif_m_awcache	: out std_logic_vector(3 downto 0);
		axif_m_awprot	: out std_logic_vector(2 downto 0);
		axif_m_awqos	: out std_logic_vector(3 downto 0);
		axif_m_awuser	: out std_logic_vector(C_AXIF_M_AWUSER_WIDTH-1 downto 0);
		axif_m_awvalid	: out std_logic;
		axif_m_awready	: in std_logic;
		axif_m_wdata	: out std_logic_vector(C_AXIF_M_DATA_WIDTH-1 downto 0);
		axif_m_wstrb	: out std_logic_vector(C_AXIF_M_DATA_WIDTH/8-1 downto 0);
		axif_m_wlast	: out std_logic;
		axif_m_wuser	: out std_logic_vector(C_AXIF_M_WUSER_WIDTH-1 downto 0);
		axif_m_wvalid	: out std_logic;
		axif_m_wready	: in std_logic;
		axif_m_bid	: in std_logic_vector(C_AXIF_M_ID_WIDTH-1 downto 0);
		axif_m_bresp	: in std_logic_vector(1 downto 0);
		axif_m_buser	: in std_logic_vector(C_AXIF_M_BUSER_WIDTH-1 downto 0);
		axif_m_bvalid	: in std_logic;
		axif_m_bready	: out std_logic;
		axif_m_arid	: out std_logic_vector(C_AXIF_M_ID_WIDTH-1 downto 0);
		axif_m_araddr	: out std_logic_vector(C_AXIF_M_ADDR_WIDTH-1 downto 0);
		axif_m_arlen	: out std_logic_vector(7 downto 0);
		axif_m_arsize	: out std_logic_vector(2 downto 0);
		axif_m_arburst	: out std_logic_vector(1 downto 0);
		axif_m_arlock	: out std_logic;
		axif_m_arcache	: out std_logic_vector(3 downto 0);
		axif_m_arprot	: out std_logic_vector(2 downto 0);
		axif_m_arqos	: out std_logic_vector(3 downto 0);
		axif_m_aruser	: out std_logic_vector(C_AXIF_M_ARUSER_WIDTH-1 downto 0);
		axif_m_arvalid	: out std_logic;
		axif_m_arready	: in std_logic;
		axif_m_rid	: in std_logic_vector(C_AXIF_M_ID_WIDTH-1 downto 0);
		axif_m_rdata	: in std_logic_vector(C_AXIF_M_DATA_WIDTH-1 downto 0);
		axif_m_rresp	: in std_logic_vector(1 downto 0);
		axif_m_rlast	: in std_logic;
		axif_m_ruser	: in std_logic_vector(C_AXIF_M_RUSER_WIDTH-1 downto 0);
		axif_m_rvalid	: in std_logic;
		axif_m_rready	: out std_logic
	);
end RISCV_AXI_v2_0;

architecture arch_imp of RISCV_AXI_v2_0 is
        constant C_AXIF_M_BURST_LEN : integer := C_BLOCK_SIZE / 4;
		
		signal axi_base_address_s : std_logic_vector(31 downto 0);
		signal axi_write_address_s : std_logic_vector(31 downto 0);
		signal axi_write_init_s	: std_logic;
		signal axi_write_data_s : std_logic_vector(31 downto 0);
		signal axi_write_next_s : std_logic;
		signal axi_write_done_s : std_logic;
		signal axi_read_address_s : std_logic_vector(31 downto 0);
		signal axi_read_init_s	: std_logic;
		signal axi_read_data_s	: std_logic_vector(31 downto 0);
		signal axi_read_next_s : std_logic;
		signal ce_s : std_logic;
		signal pc_reg_s : std_logic_vector(31 downto 0);
	-- component declaration
begin

-- Instantiation of Axi Bus Interface AXIL_S
RISCV_AXI_v2_0_AXIL_S_inst : entity work.RISCV_AXI_v2_0_AXIL_S
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_AXIL_S_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_AXIL_S_ADDR_WIDTH
	)
	port map (
	   axi_base_address_o => axi_base_address_s,
		ce_o	=> ce_s,
		pc_reg_i => pc_reg_s,
		S_AXI_ACLK	=> axil_s_aclk,
		S_AXI_ARESETN	=> axil_s_aresetn,
		S_AXI_AWADDR	=> axil_s_awaddr,
		S_AXI_AWPROT	=> axil_s_awprot,
		S_AXI_AWVALID	=> axil_s_awvalid,
		S_AXI_AWREADY	=> axil_s_awready,
		S_AXI_WDATA	=> axil_s_wdata,
		S_AXI_WSTRB	=> axil_s_wstrb,
		S_AXI_WVALID	=> axil_s_wvalid,
		S_AXI_WREADY	=> axil_s_wready,
		S_AXI_BRESP	=> axil_s_bresp,
		S_AXI_BVALID	=> axil_s_bvalid,
		S_AXI_BREADY	=> axil_s_bready,
		S_AXI_ARADDR	=> axil_s_araddr,
		S_AXI_ARPROT	=> axil_s_arprot,
		S_AXI_ARVALID	=> axil_s_arvalid,
		S_AXI_ARREADY	=> axil_s_arready,
		S_AXI_RDATA	=> axil_s_rdata,
		S_AXI_RRESP	=> axil_s_rresp,
		S_AXI_RVALID	=> axil_s_rvalid,
		S_AXI_RREADY	=> axil_s_rready
	);

-- Instantiation of Axi Bus Interface AXIF_M
RISCV_AXI_v2_0_AXIF_M_inst : entity work.RISCV_AXI_v2_0_AXIF_M
	generic map (
	    C_M_AXI_BURST_LEN	=> C_AXIF_M_BURST_LEN,
		C_M_AXI_ID_WIDTH	=> C_AXIF_M_ID_WIDTH,
		C_M_AXI_ADDR_WIDTH	=> C_AXIF_M_ADDR_WIDTH,
		C_M_AXI_DATA_WIDTH	=> C_AXIF_M_DATA_WIDTH,
		C_M_AXI_AWUSER_WIDTH	=> C_AXIF_M_AWUSER_WIDTH,
		C_M_AXI_ARUSER_WIDTH	=> C_AXIF_M_ARUSER_WIDTH,
		C_M_AXI_WUSER_WIDTH	=> C_AXIF_M_WUSER_WIDTH,
		C_M_AXI_RUSER_WIDTH	=> C_AXIF_M_RUSER_WIDTH,
		C_M_AXI_BUSER_WIDTH	=> C_AXIF_M_BUSER_WIDTH
	)
	port map (
	    axi_base_address_i => axi_base_address_s,
		axi_write_address_i => axi_write_address_s,
		axi_write_init_i	=> axi_write_init_s,
		axi_write_data_i	=> axi_write_data_s,
		axi_write_next_o => axi_write_next_s,
		axi_write_done_o => axi_write_done_s,
		axi_read_address_i => axi_read_address_s,
		axi_read_init_i	=> axi_read_init_s,
		axi_read_data_o	=> axi_read_data_s,
		axi_read_next_o => axi_read_next_s,
		M_AXI_ACLK	=> axif_m_aclk,
		M_AXI_ARESETN	=> axif_m_aresetn,
		M_AXI_AWID	=> axif_m_awid,
		M_AXI_AWADDR	=> axif_m_awaddr,
		M_AXI_AWLEN	=> axif_m_awlen,
		M_AXI_AWSIZE	=> axif_m_awsize,
		M_AXI_AWBURST	=> axif_m_awburst,
		M_AXI_AWLOCK	=> axif_m_awlock,
		M_AXI_AWCACHE	=> axif_m_awcache,
		M_AXI_AWPROT	=> axif_m_awprot,
		M_AXI_AWQOS	=> axif_m_awqos,
		M_AXI_AWUSER	=> axif_m_awuser,
		M_AXI_AWVALID	=> axif_m_awvalid,
		M_AXI_AWREADY	=> axif_m_awready,
		M_AXI_WDATA	=> axif_m_wdata,
		M_AXI_WSTRB	=> axif_m_wstrb,
		M_AXI_WLAST	=> axif_m_wlast,
		M_AXI_WUSER	=> axif_m_wuser,
		M_AXI_WVALID	=> axif_m_wvalid,
		M_AXI_WREADY	=> axif_m_wready,
		M_AXI_BID	=> axif_m_bid,
		M_AXI_BRESP	=> axif_m_bresp,
		M_AXI_BUSER	=> axif_m_buser,
		M_AXI_BVALID	=> axif_m_bvalid,
		M_AXI_BREADY	=> axif_m_bready,
		M_AXI_ARID	=> axif_m_arid,
		M_AXI_ARADDR	=> axif_m_araddr,
		M_AXI_ARLEN	=> axif_m_arlen,
		M_AXI_ARSIZE	=> axif_m_arsize,
		M_AXI_ARBURST	=> axif_m_arburst,
		M_AXI_ARLOCK	=> axif_m_arlock,
		M_AXI_ARCACHE	=> axif_m_arcache,
		M_AXI_ARPROT	=> axif_m_arprot,
		M_AXI_ARQOS	=> axif_m_arqos,
		M_AXI_ARUSER	=> axif_m_aruser,
		M_AXI_ARVALID	=> axif_m_arvalid,
		M_AXI_ARREADY	=> axif_m_arready,
		M_AXI_RID	=> axif_m_rid,
		M_AXI_RDATA	=> axif_m_rdata,
		M_AXI_RRESP	=> axif_m_rresp,
		M_AXI_RLAST	=> axif_m_rlast,
		M_AXI_RUSER	=> axif_m_ruser,
		M_AXI_RVALID	=> axif_m_rvalid,
		M_AXI_RREADY	=> axif_m_rready
	);

	-- Add user logic here
RISCV_HART :entity work.RISCV_w_cache(Behavioral)
	generic map(
		C_PHY_ADDR_WIDTH => C_PHY_ADDR_WIDTH,
		C_TS_BRAM_TYPE  => C_TS_BRAM_TYPE,
		C_BLOCK_SIZE  => C_BLOCK_SIZE,
		C_LVL1_CACHE_SIZE => C_LVL1_CACHE_SIZE,
		C_LVL2_CACHE_SIZE => C_LVL2_CACHE_SIZE,
		C_LVL2C_ASSOCIATIVITY => C_LVL2C_ASSOCIATIVITY
	)
	port map(clk => axif_m_aclk,
			ce => ce_s,
			reset => axif_m_aresetn,
			pc_reg_o => pc_reg_s,
			axi_write_address_o => axi_write_address_s,
			axi_write_init_o => axi_write_init_s,
			axi_write_data_o => axi_write_data_s,
			axi_write_next_i => axi_write_next_s,
			axi_write_done_i  => axi_write_done_s,
			axi_read_address_o => axi_read_address_s,
			axi_read_init_o => axi_read_init_s,
			axi_read_data_i => axi_read_data_s,
			axi_read_next_i  => axi_read_next_s
			);
	-- User logic ends

end arch_imp;
