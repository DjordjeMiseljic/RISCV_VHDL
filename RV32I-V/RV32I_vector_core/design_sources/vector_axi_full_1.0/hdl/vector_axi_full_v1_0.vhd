library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vector_axi_full_v1_0 is
   generic (
      -- Users to add parameters here

      -- User parameters ends
      -- Do not modify the parameters beyond this line


      -- Parameters of Axi Master Bus Interface M00_AXI
      C_M00_AXI_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
      C_M00_AXI_BURST_LEN	: integer	:= 16;
      C_M00_AXI_ID_WIDTH	: integer	:= 1;
      C_M00_AXI_ADDR_WIDTH	: integer	:= 32;
      C_M00_AXI_DATA_WIDTH	: integer	:= 32;
      C_M00_AXI_AWUSER_WIDTH	: integer	:= 0;
      C_M00_AXI_ARUSER_WIDTH	: integer	:= 0;
      C_M00_AXI_WUSER_WIDTH	: integer	:= 0;
      C_M00_AXI_RUSER_WIDTH	: integer	:= 0;
      C_M00_AXI_BUSER_WIDTH	: integer	:= 0
      );
   port (
      -- Users to add ports here
      base_address_i: in std_logic_vector(31 downto 0);
      --store_pulse_i: in std_logic;
      --load_pulse_i: in std_logic;
      --load_address: in std_logic_vector(31 downto 0);
      -- User ports ends
      -- Do not modify the ports beyond this line


      -- Ports of Axi Master Bus Interface M00_AXI		
      m00_axi_aclk	: in std_logic;
      m00_axi_aresetn	: in std_logic;
      m00_axi_awid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
      m00_axi_awaddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
      m00_axi_awlen	: out std_logic_vector(7 downto 0);
      m00_axi_awsize	: out std_logic_vector(2 downto 0);
      m00_axi_awburst	: out std_logic_vector(1 downto 0);
      m00_axi_awlock	: out std_logic;
      m00_axi_awcache	: out std_logic_vector(3 downto 0);
      m00_axi_awprot	: out std_logic_vector(2 downto 0);
      m00_axi_awqos	: out std_logic_vector(3 downto 0);
      m00_axi_awuser	: out std_logic_vector(C_M00_AXI_AWUSER_WIDTH-1 downto 0);
      m00_axi_awvalid	: out std_logic;
      m00_axi_awready	: in std_logic;
      m00_axi_wdata	: out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
      m00_axi_wstrb	: out std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0);
      m00_axi_wlast	: out std_logic;
      m00_axi_wuser	: out std_logic_vector(C_M00_AXI_WUSER_WIDTH-1 downto 0);
      m00_axi_wvalid	: out std_logic;
      m00_axi_wready	: in std_logic;
      m00_axi_bid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
      m00_axi_bresp	: in std_logic_vector(1 downto 0);
      m00_axi_buser	: in std_logic_vector(C_M00_AXI_BUSER_WIDTH-1 downto 0);
      m00_axi_bvalid	: in std_logic;
      m00_axi_bready	: out std_logic;
      m00_axi_arid	: out std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
      m00_axi_araddr	: out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
      m00_axi_arlen	: out std_logic_vector(7 downto 0);
      m00_axi_arsize	: out std_logic_vector(2 downto 0);
      m00_axi_arburst	: out std_logic_vector(1 downto 0);
      m00_axi_arlock	: out std_logic;
      m00_axi_arcache	: out std_logic_vector(3 downto 0);
      m00_axi_arprot	: out std_logic_vector(2 downto 0);
      m00_axi_arqos	: out std_logic_vector(3 downto 0);
      m00_axi_aruser	: out std_logic_vector(C_M00_AXI_ARUSER_WIDTH-1 downto 0);
      m00_axi_arvalid	: out std_logic;
      m00_axi_arready	: in std_logic;
      m00_axi_rid	: in std_logic_vector(C_M00_AXI_ID_WIDTH-1 downto 0);
      m00_axi_rdata	: in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
      m00_axi_rresp	: in std_logic_vector(1 downto 0);
      m00_axi_rlast	: in std_logic;
      m00_axi_ruser	: in std_logic_vector(C_M00_AXI_RUSER_WIDTH-1 downto 0);
      m00_axi_rvalid	: in std_logic;
      m00_axi_rready	: out std_logic
      );
end vector_axi_full_v1_0;

architecture arch_imp of vector_axi_full_v1_0 is

   
   
   -- Vector processor AXI full controller interconnections
   signal store_address_s: std_logic_vector(C_M00_AXI_ADDR_WIDTH - 1 downto 0);
   signal load_address_s: std_logic_vector(C_M00_AXI_ADDR_WIDTH - 1 downto 0);

   signal store_data_s: std_logic_vector(C_M00_AXI_DATA_WIDTH - 1 downto 0);
   signal load_data_s: std_logic_vector(C_M00_AXI_DATA_WIDTH - 1 downto 0);

   signal store_pulse_s: std_logic;
   signal load_pulse_s: std_logic;
   signal store_ready_s: std_logic;
   signal load_ready_s: std_logic;

   signal axi_wvalid_s:std_logic;
   signal axi_wready_s:std_logic;
   signal axi_wdata_s:std_logic_vector(C_M00_AXI_DATA_WIDTH - 1 downto 0);
   -- component declaration
   component vector_axi_full_v1_0_M00_AXI is
      generic (
         C_M_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
         C_M_AXI_BURST_LEN	: integer	:= 16;
         C_M_AXI_ID_WIDTH	: integer	:= 1;
         C_M_AXI_ADDR_WIDTH	: integer	:= 32;
         C_M_AXI_DATA_WIDTH	: integer	:= 32;
         C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
         C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
         C_M_AXI_WUSER_WIDTH	: integer	:= 0;
         C_M_AXI_RUSER_WIDTH	: integer	:= 0;
         C_M_AXI_BUSER_WIDTH	: integer	:= 0
         );
      port (

         base_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);

         store_data_i: in std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);
         store_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);         
         store_pulse_i: in std_logic;
         store_ready_o: out std_logic;

         load_data_o: out std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);   
         load_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);         
         load_pulse_i: in std_logic;
         load_ready_o: out std_logic;


         
         M_AXI_ACLK	: in std_logic;
         M_AXI_ARESETN	: in std_logic;
         M_AXI_AWID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
         M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
         M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
         M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
         M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
         M_AXI_AWLOCK	: out std_logic;
         M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
         M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
         M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
         M_AXI_AWUSER	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
         M_AXI_AWVALID	: out std_logic;
         M_AXI_AWREADY	: in std_logic;
         M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
         M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
         M_AXI_WLAST	: out std_logic;
         M_AXI_WUSER	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
         M_AXI_WVALID	: out std_logic;
         M_AXI_WREADY	: in std_logic;
         M_AXI_BID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
         M_AXI_BRESP	: in std_logic_vector(1 downto 0);
         M_AXI_BUSER	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
         M_AXI_BVALID	: in std_logic;
         M_AXI_BREADY	: out std_logic;
         M_AXI_ARID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
         M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
         M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
         M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
         M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
         M_AXI_ARLOCK	: out std_logic;
         M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
         M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
         M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
         M_AXI_ARUSER	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
         M_AXI_ARVALID	: out std_logic;
         M_AXI_ARREADY	: in std_logic;
         M_AXI_RID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
         M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
         M_AXI_RRESP	: in std_logic_vector(1 downto 0);
         M_AXI_RLAST	: in std_logic;
         M_AXI_RUSER	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
         M_AXI_RVALID	: in std_logic;
         M_AXI_RREADY	: out std_logic
         );
   end component vector_axi_full_v1_0_M00_AXI;

begin


   load_address_s <= (others => '0');
   store_address_s <= std_logic_vector(to_unsigned(128, C_M00_AXI_ADDR_WIDTH));

   m00_axi_wvalid <= axi_wvalid_s;
   m00_axi_wdata <= axi_wdata_s;
   axi_wready_s <= M00_AXI_WREADY;
-- Instantiation of Axi Bus Interface M00_AXI
   vector_axi_full_v1_0_M00_AXI_inst : vector_axi_full_v1_0_M00_AXI
      generic map (
         C_M_TARGET_SLAVE_BASE_ADDR	=> C_M00_AXI_TARGET_SLAVE_BASE_ADDR,
         C_M_AXI_BURST_LEN	=> C_M00_AXI_BURST_LEN,
         C_M_AXI_ID_WIDTH	=> C_M00_AXI_ID_WIDTH,
         C_M_AXI_ADDR_WIDTH	=> C_M00_AXI_ADDR_WIDTH,
         C_M_AXI_DATA_WIDTH	=> C_M00_AXI_DATA_WIDTH,
         C_M_AXI_AWUSER_WIDTH	=> C_M00_AXI_AWUSER_WIDTH,
         C_M_AXI_ARUSER_WIDTH	=> C_M00_AXI_ARUSER_WIDTH,
         C_M_AXI_WUSER_WIDTH	=> C_M00_AXI_WUSER_WIDTH,
         C_M_AXI_RUSER_WIDTH	=> C_M00_AXI_RUSER_WIDTH,
         C_M_AXI_BUSER_WIDTH	=> C_M00_AXI_BUSER_WIDTH
         )
      port map (

         store_address_i => store_address_s,
         store_pulse_i => store_pulse_s,
         store_ready_o => store_ready_s,
         store_data_i => store_data_s,
         
         load_data_o => load_data_s,
         load_address_i => load_address_s,
         load_pulse_i => load_pulse_s,
         load_ready_o => load_ready_s,
         
         base_address_i => base_address_i,         
         
         M_AXI_ACLK	=> m00_axi_aclk,
         M_AXI_ARESETN	=> m00_axi_aresetn,
         M_AXI_AWID	=> m00_axi_awid,
         M_AXI_AWADDR	=> m00_axi_awaddr,
         M_AXI_AWLEN	=> m00_axi_awlen,
         M_AXI_AWSIZE	=> m00_axi_awsize,
         M_AXI_AWBURST	=> m00_axi_awburst,
         M_AXI_AWLOCK	=> m00_axi_awlock,
         M_AXI_AWCACHE	=> m00_axi_awcache,
         M_AXI_AWPROT	=> m00_axi_awprot,
         M_AXI_AWQOS	=> m00_axi_awqos,
         M_AXI_AWUSER	=> m00_axi_awuser,
         M_AXI_AWVALID	=> m00_axi_awvalid,
         M_AXI_AWREADY	=> m00_axi_awready,
         M_AXI_WDATA	=> open,
         M_AXI_WSTRB	=> m00_axi_wstrb,
         M_AXI_WLAST	=> m00_axi_wlast,
         M_AXI_WUSER	=> m00_axi_wuser,
         M_AXI_WVALID	=> axi_wvalid_s,
         M_AXI_WREADY	=> m00_axi_wready,
         M_AXI_BID	=> m00_axi_bid,
         M_AXI_BRESP	=> m00_axi_bresp,
         M_AXI_BUSER	=> m00_axi_buser,
         M_AXI_BVALID	=> m00_axi_bvalid,
         M_AXI_BREADY	=> m00_axi_bready,
         M_AXI_ARID	=> m00_axi_arid,
         M_AXI_ARADDR	=> m00_axi_araddr,
         M_AXI_ARLEN	=> m00_axi_arlen,
         M_AXI_ARSIZE	=> m00_axi_arsize,
         M_AXI_ARBURST	=> m00_axi_arburst,
         M_AXI_ARLOCK	=> m00_axi_arlock,
         M_AXI_ARCACHE	=> m00_axi_arcache,
         M_AXI_ARPROT	=> m00_axi_arprot,
         M_AXI_ARQOS	=> m00_axi_arqos,
         M_AXI_ARUSER	=> m00_axi_aruser,
         M_AXI_ARVALID	=> m00_axi_arvalid,
         M_AXI_ARREADY	=> m00_axi_arready,
         M_AXI_RID	=> m00_axi_rid,
         M_AXI_RDATA	=> m00_axi_rdata,
         M_AXI_RRESP	=> m00_axi_rresp,
         M_AXI_RLAST	=> m00_axi_rlast,
         M_AXI_RUSER	=> m00_axi_ruser,
         M_AXI_RVALID	=> m00_axi_rvalid,
         M_AXI_RREADY	=> m00_axi_rready
         );

   -- Add user logic here
   --********************DEBUG LOGIC ************************
   -- this code is used to generate write and read transactions to determine
   -- whether or not axi full controler functions properly.
   -- it generates store_pulse signal to initiate stores, and also implements a
   -- simple counter (cnt_v) whose values are written into DDR.
   process (m00_axi_aclk) is
      variable cnt_v: unsigned(15 downto 0);
   begin
      if (rising_edge(m00_axi_aclk))then
         if (m00_axi_aresetn = '0') then
            cnt_v := (others => '0');
            store_pulse_s <= '0';
         else
            axi_wdata_s <= x"0000"&std_logic_vector(cnt_v);
            if (axi_wready_s = '1') then
               cnt_v := cnt_v + to_unsigned(1, 16);
            end if;
            if (store_ready_s = '1') then
               store_pulse_s <= '1';
            else
               store_pulse_s <= '0';
            end if;
         end if;         
      end if;
   end process;

   process (m00_axi_aclk) is
   begin
      if (rising_edge(m00_axi_aclk))then
         if (m00_axi_aresetn = '0') then
            load_pulse_s <= '0';
         else
            if (load_ready_s = '1') then
               load_pulse_s <= '1';
            else
               load_pulse_s <= '0';
            end if;            
         end if;
      end if;      
   end process;
   -- User logic ends

end arch_imp;
