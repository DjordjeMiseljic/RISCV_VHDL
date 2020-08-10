library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vector_axi_full_v1_0_M00_AXI is
   generic (
      -- Users to add parameters here

      -- User parameters ends
      -- Do not modify the parameters beyond this line

      -- Base address of targeted slave
      C_M_TARGET_SLAVE_BASE_ADDR	: std_logic_vector	:= x"40000000";
      -- Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
      C_M_AXI_BURST_LEN	: integer	:= 16;
      -- Thread ID Width
      C_M_AXI_ID_WIDTH	: integer	:= 1;
      -- Width of Address Bus
      C_M_AXI_ADDR_WIDTH	: integer	:= 32;
      -- Width of Data Bus
      C_M_AXI_DATA_WIDTH	: integer	:= 32;
      -- Width of User Write Address Bus
      C_M_AXI_AWUSER_WIDTH	: integer	:= 0;
      -- Width of User Read Address Bus
      C_M_AXI_ARUSER_WIDTH	: integer	:= 0;
      -- Width of User Write Data Bus
      C_M_AXI_WUSER_WIDTH	: integer	:= 0;
      -- Width of User Read Data Bus
      C_M_AXI_RUSER_WIDTH	: integer	:= 0;
      -- Width of User Response Bus
      C_M_AXI_BUSER_WIDTH	: integer	:= 0
      );
   port (
      -- Users to add ports here
      base_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);

      store_data_i: in std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);
      store_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);         
      store_pulse_i: in std_logic;
      store_ready_o: out std_logic;

      load_data_o: out std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);   
      load_address_i: in std_logic_vector(C_M_AXI_ADDR_WIDTH - 1 downto 0);         
      load_pulse_i: in std_logic;
      load_ready_o: out std_logic;
      
      --load_address: in std_logic_vector(31 downto 0);
      -- User ports ends
      -- Do not modify the ports beyond this line


      -- Global Clock Signal.
      M_AXI_ACLK	: in std_logic;
      -- Global Reset Singal. This Signal is Active Low
      M_AXI_ARESETN	: in std_logic;
      -- Master Interface Write Address ID
      M_AXI_AWID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
      -- Master Interface Write Address
      M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      -- Burst length. The burst length gives the exact number of transfers in a burst
      M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
      -- Burst size. This signal indicates the size of each transfer in the burst
      M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
      -- Burst type. The burst type and the size information, 
      -- determine how the address for each transfer within the burst is calculated.
      M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
      -- Lock type. Provides additional information about the
      -- atomic characteristics of the transfer.
      M_AXI_AWLOCK	: out std_logic;
      -- Memory type. This signal indicates how transactions
      -- are required to progress through a system.
      M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
      -- Protection type. This signal indicates the privilege
      -- and security level of the transaction, and whether
      -- the transaction is a data access or an instruction access.
      M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
      -- Quality of Service, QoS identifier sent for each write transaction.
      M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
      -- Optional User-defined signal in the write address channel.
      M_AXI_AWUSER	: out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);
      -- Write address valid. This signal indicates that
      -- the channel is signaling valid write address and control information.
      M_AXI_AWVALID	: out std_logic;
      -- Write address ready. This signal indicates that
      -- the slave is ready to accept an address and associated control signals
      M_AXI_AWREADY	: in std_logic;
      -- Master Interface Write Data.
      M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      -- Write strobes. This signal indicates which byte
      -- lanes hold valid data. There is one write strobe
      -- bit for each eight bits of the write data bus.
      M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
      -- Write last. This signal indicates the last transfer in a write burst.
      M_AXI_WLAST	: out std_logic;
      -- Optional User-defined signal in the write data channel.
      M_AXI_WUSER	: out std_logic_vector(C_M_AXI_WUSER_WIDTH-1 downto 0);
      -- Write valid. This signal indicates that valid write
      -- data and strobes are available
      M_AXI_WVALID	: out std_logic;
      -- Write ready. This signal indicates that the slave
      -- can accept the write data.
      M_AXI_WREADY	: in std_logic;
      -- Master Interface Write Response.
      M_AXI_BID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
      -- Write response. This signal indicates the status of the write transaction.
      M_AXI_BRESP	: in std_logic_vector(1 downto 0);
      -- Optional User-defined signal in the write response channel
      M_AXI_BUSER	: in std_logic_vector(C_M_AXI_BUSER_WIDTH-1 downto 0);
      -- Write response valid. This signal indicates that the
      -- channel is signaling a valid write response.
      M_AXI_BVALID	: in std_logic;
      -- Response ready. This signal indicates that the master
      -- can accept a write response.
      M_AXI_BREADY	: out std_logic;
      -- Master Interface Read Address.
      M_AXI_ARID	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
      -- Read address. This signal indicates the initial
      -- address of a read burst transaction.
      M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      -- Burst length. The burst length gives the exact number of transfers in a burst
      M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
      -- Burst size. This signal indicates the size of each transfer in the burst
      M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
      -- Burst type. The burst type and the size information, 
      -- determine how the address for each transfer within the burst is calculated.
      M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
      -- Lock type. Provides additional information about the
      -- atomic characteristics of the transfer.
      M_AXI_ARLOCK	: out std_logic;
      -- Memory type. This signal indicates how transactions
      -- are required to progress through a system.
      M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
      -- Protection type. This signal indicates the privilege
      -- and security level of the transaction, and whether
      -- the transaction is a data access or an instruction access.
      M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
      -- Quality of Service, QoS identifier sent for each read transaction
      M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
      -- Optional User-defined signal in the read address channel.
      M_AXI_ARUSER	: out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);
      -- Write address valid. This signal indicates that
      -- the channel is signaling valid read address and control information
      M_AXI_ARVALID	: out std_logic;
      -- Read address ready. This signal indicates that
      -- the slave is ready to accept an address and associated control signals
      M_AXI_ARREADY	: in std_logic;
      -- Read ID tag. This signal is the identification tag
      -- for the read data group of signals generated by the slave.
      M_AXI_RID	: in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
      -- Master Read Data
      M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      -- Read response. This signal indicates the status of the read transfer
      M_AXI_RRESP	: in std_logic_vector(1 downto 0);
      -- Read last. This signal indicates the last transfer in a read burst
      M_AXI_RLAST	: in std_logic;
      -- Optional User-defined signal in the read address channel.
      M_AXI_RUSER	: in std_logic_vector(C_M_AXI_RUSER_WIDTH-1 downto 0);
      -- Read valid. This signal indicates that the channel
      -- is signaling the required read data.
      M_AXI_RVALID	: in std_logic;
      -- Read ready. This signal indicates that the master can
      -- accept the read data and response information.
      M_AXI_RREADY	: out std_logic
      );
end vector_axi_full_v1_0_M00_AXI;

architecture implementation of vector_axi_full_v1_0_M00_AXI is

   --Debug
   type mem is array (0 to 31) of std_logic_vector(C_M_AXI_DATA_WIDTH - 1 downto 0);
   signal load_mem:mem;
   -- function called clogb2 that returns an integer which has the
   --value of the ceiling of the log base 2

   function clogb2 (bit_depth : integer) return integer is            
      variable depth  : integer := bit_depth;                               
      variable count  : integer := 1;                                       
   begin                                                                   
      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
         if (bit_depth <= 2) then                                           
            count := 1;                                                      
         else                                                               
            if(depth <= 1) then                                              
               count := count;                                                
            else                                                             
               depth := depth / 2;                                            
               count := count + 1;                                            
            end if;                                                          
         end if;                                                            
      end loop;                                                             
      return(count);        	                                              
   end;                                                                    


   -- AXI4FULL signals
   --AXI4 internal temp signals   
   signal axi_awvalid	: std_logic;
   signal axi_wdata	: std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
   signal axi_wlast	: std_logic;
   signal axi_wvalid	: std_logic;
   signal axi_bready	: std_logic;
   signal axi_araddr	: std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
   signal axi_arvalid	: std_logic;
   signal axi_rready	: std_logic;
   --write beat count in a burst
   --***************DEBUG SIGNALS******************************************
   signal write_index	: std_logic_vector(clogb2(C_M_AXI_BURST_LEN)  downto 0);
   --read beat count in a burst
   signal read_index	: std_logic_vector(clogb2(C_M_AXI_BURST_LEN) downto 0);
   --*************************************************************************
   --size of C_M_AXI_BURST_LEN length burst in bytes
   
   --The burst counters are used to track the number of burst transfers of C_M_AXI_BURST_LEN burst length needed to transfer 2^C_MASTER_LENGTH bytes of data.
   

   signal start_single_burst_store	: std_logic;
   signal start_single_burst_load	: std_logic;
   signal store_done_s	: std_logic;
   signal load_done_s	: std_logic;   
      
   --Interface response error flags
   signal write_resp_error	: std_logic;
   signal read_resp_error	: std_logic;
   signal wnext	: std_logic;
   signal rnext	: std_logic;
   
   signal load_pulse_ff	: std_logic;
   signal load_pulse_ff2	: std_logic;
   
   signal load_pulse_s	: std_logic;

   signal store_pulse_ff	: std_logic;
   signal store_pulse_ff2	: std_logic;
   
   signal store_pulse_s	: std_logic;


begin
   -- USER ADDED I/O PORTS
   store_ready_o <= store_done_s;
   load_ready_o <= load_done_s;
   --I/O Connections. Write Address (AW)
   M_AXI_AWID	<= (others => '0');
   --The AXI address is a concatenation of the target base address + active offset range
   -- M_AXI_AWADDR	<= std_logic_vector( unsigned(C_M_TARGET_SLAVE_BASE_ADDR) + unsigned(axi_awaddr) );
   M_AXI_AWADDR	<= std_logic_vector(unsigned(store_address_i) + unsigned(base_address_i));
   --Burst LENgth is number of transaction beats, minus 1
   M_AXI_AWLEN	<= std_logic_vector( to_unsigned(C_M_AXI_BURST_LEN - 1, 8) );
   --Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
   M_AXI_AWSIZE	<= std_logic_vector( to_unsigned(clogb2((C_M_AXI_DATA_WIDTH/8)-1), 3) );
   --INCR burst type is usually used, except for keyhole bursts
   M_AXI_AWBURST	<= "01";
   M_AXI_AWLOCK	<= '0';
   --Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
   M_AXI_AWCACHE	<= "0010";
   M_AXI_AWPROT	<= "000";
   M_AXI_AWQOS	<= x"0";
   M_AXI_AWUSER	<= (others => '1');
   M_AXI_AWVALID	<= axi_awvalid;
   --Write Data(W)
   M_AXI_WDATA	<= axi_wdata;
   --All bursts are complete and aligned in this example
   M_AXI_WSTRB	<= (others => '1');
   M_AXI_WLAST	<= axi_wlast;
   M_AXI_WUSER	<= (others => '0');
   M_AXI_WVALID	<= axi_wvalid;
   --Write Response (B)
   M_AXI_BREADY	<= axi_bready;
   --Read Address (AR)
   M_AXI_ARID	<= (others => '0');
   -- M_AXI_ARADDR	<= std_logic_vector( unsigned( C_M_TARGET_SLAVE_BASE_ADDR ) + unsigned( axi_araddr ) );

   M_AXI_ARADDR	<= std_logic_vector(unsigned(load_address_i) + unsigned(base_address_i));
   --Burst LENgth is number of transaction beats, minus 1
   M_AXI_ARLEN	<= std_logic_vector( to_unsigned(C_M_AXI_BURST_LEN - 1, 8) );
   --Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
   M_AXI_ARSIZE	<= std_logic_vector( to_unsigned( clogb2((C_M_AXI_DATA_WIDTH/8)-1),3 ));
   --INCR burst type is usually used, except for keyhole bursts
   M_AXI_ARBURST	<= "01";
   M_AXI_ARLOCK	<= '0';
   --Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
   M_AXI_ARCACHE	<= "0010";
   M_AXI_ARPROT	<= "000";
   M_AXI_ARQOS	<= x"0";
   M_AXI_ARUSER	<= (others => '1');
   M_AXI_ARVALID	<= axi_arvalid;
   --Read and Read Response (R)
   M_AXI_RREADY	<= axi_rready;
   --Example design I/O
   --Burst size in    
   load_pulse_s	<= ( not load_pulse_ff2)  and  load_pulse_ff;
   store_pulse_s	<= ( not store_pulse_ff2)  and  store_pulse_ff;


   --Generate a pulse to initiate AXI transaction.
   process(M_AXI_ACLK)                                                          
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         -- Initiates AXI transaction delay        
         if (M_AXI_ARESETN = '0' ) then                                                
            load_pulse_ff <= '0';                                                   
            load_pulse_ff2 <= '0';                                                          
         else                                                                                       
            load_pulse_ff <= load_pulse_i;
            load_pulse_ff2 <= load_pulse_ff;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;

   process(M_AXI_ACLK)                                                          
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         -- Initiates AXI transaction delay        
         if (M_AXI_ARESETN = '0' ) then                                                
            store_pulse_ff <= '0';                                                   
            store_pulse_ff2 <= '0';                                                          
         else                                                                                       
            store_pulse_ff <= store_pulse_i;
            store_pulse_ff2 <= store_pulse_ff;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;


   ----------------------
   --Write Address Channel
   ----------------------

   -- The purpose of the write address channel is to request the address and 
   -- command information for the entire transaction.  It is a single beat
   -- of information.

   -- The AXI4 Write address channel in this example will continue to initiate
   -- write commands as fast as it is allowed by the slave/interconnect.
   -- The address will be incremented on each accepted address transaction,
   -- by burst_size_byte to point to the next address. 

   process(M_AXI_ACLK)                                            
   begin                                                                
      if (rising_edge (M_AXI_ACLK)) then                                 
         if (M_AXI_ARESETN = '0' or store_pulse_s = '1') then                                   
            axi_awvalid <= '0';                                            
         else                                                             
            -- If previously not valid , start next transaction            
            if (axi_awvalid = '0' and start_single_burst_store = '1') then 
               axi_awvalid <= '1';                                          
            -- Once asserted, VALIDs cannot be deasserted, so axi_awvalid
            -- must wait until transaction is accepted                   
            elsif (M_AXI_AWREADY = '1' and axi_awvalid = '1') then         
               axi_awvalid <= '0';                                          
            else                                                           
               axi_awvalid <= axi_awvalid;                                  
            end if;                                                        
         end if;                                                          
      end if;                                                            
   end process;                                                         
   
   
                                                     


   ----------------------
   --Write Data Channel
   ----------------------

   --The write data will continually try to push write data across the interface.

   --The amount of data accepted will depend on the AXI slave and the AXI
   --Interconnect settings, such as if there are FIFOs enabled in interconnect.

   --Note that there is no explicit timing relationship to the write address channel.
   --The write channel has its own throttling flag, separate from the AW channel.

   --Synchronization between the channels must be determined by the user.

   --The simpliest but lowest performance would be to only issue one address write
   --and write data burst at a time.

   --In this example they are kept in sync by using the same address increment
   --and burst sizes. Then the AW and W channels have their transactions measured
   --with threshold counters as part of the user logic, to make sure neither 
   --channel gets too far ahead of each other.

   --Forward movement occurs when the write channel is valid and ready

   wnext <= M_AXI_WREADY and axi_wvalid;                                       
   
   -- WVALID logic, similar to the axi_awvalid always block above                      
   process(M_AXI_ACLK)                                                               
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         if (M_AXI_ARESETN = '0' or store_pulse_s = '1') then
            axi_wvalid <= '0';                                                          
         else                                                                          
            if (axi_wvalid = '0' and start_single_burst_store = '1') then               
               -- If previously not valid, start next transaction                        
               axi_wvalid <= '1';                                                        
            --     /* If WREADY and too many writes, throttle WVALID                  
            --      Once asserted, VALIDs cannot be deasserted, so WVALID             
            --      must wait until burst is complete with WLAST */                   
            elsif (wnext = '1' and axi_wlast = '1') then                                
               axi_wvalid <= '0';                                                        
            else                                                                        
               axi_wvalid <= axi_wvalid;                                                 
            end if;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;                                                                      
   
   --WLAST generation on the MSB of a counter underflow                                
   -- WVALID logic, similar to the axi_awvalid always block above                      
   process(M_AXI_ACLK)                                                               
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         if (M_AXI_ARESETN = '0' or store_pulse_s = '1') then                                                
            axi_wlast <= '0';                                                           
         -- axi_wlast is asserted when the write index                               
         -- count reaches the penultimate count to synchronize                       
         -- with the last write data when write_index is b1111                       
         else                                                                          
            if ((((write_index = std_logic_vector(to_unsigned(C_M_AXI_BURST_LEN-2, clogb2(C_M_AXI_BURST_LEN) - 1))) and
                  C_M_AXI_BURST_LEN >= 2) and wnext = '1') or (C_M_AXI_BURST_LEN = 1)) then
               axi_wlast <= '1';                                                         
            -- Deassrt axi_wlast when the last write data has been                    
            -- accepted by the slave with a valid response                            
            elsif (wnext = '1') then                                                    
               axi_wlast <= '0';                                                         
            elsif (axi_wlast = '1' and C_M_AXI_BURST_LEN = 1) then                      
               axi_wlast <= '0';                                                         
            end if;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;                                                                      


   --*****************REMOVE WRITE_INDEX COUNTER IN FINAL CUT, THIS IS DEBUG LOGIC !!!!!
   -- Burst length counter. Uses extra counter register bit to indicate terminal       
   -- count to reduce decode logic */
   
   process(M_AXI_ACLK)                                                               
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         if (M_AXI_ARESETN = '0' or start_single_burst_store = '1' or store_pulse_s = '1') then               
            write_index <= (others => '0');                                             
         else                                                                          
            if (wnext = '1' and (write_index /= std_logic_vector(to_unsigned(C_M_AXI_BURST_LEN-1,clogb2(C_M_AXI_BURST_LEN) - 1)))) then                
               write_index <= std_logic_vector(unsigned(write_index) + 1);                                         
            end if;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;                                                                      
   --*****************************************************************************************
   -- Write Data Generator                                                             
   -- Put data that needs to be stored to wdata port
   process(M_AXI_ACLK)                                                               
      variable  sig_one : integer := 1;                                                 
   begin                                                                             
      if (rising_edge (M_AXI_ACLK)) then                                              
         if (M_AXI_ARESETN = '0' or store_pulse_s = '1') then                                                
            axi_wdata <= std_logic_vector (to_unsigned(sig_one, C_M_AXI_DATA_WIDTH));
         else                                                                          
            if (wnext = '1') then
               -- Chenge axi_wdata <= store_data_i;
               axi_wdata <= load_mem(to_integer(unsigned(write_index)));
            end if;                                                                     
         end if;                                                                       
      end if;                                                                         
   end process;                                                                      


   ------------------------------
   --Write Response (B) Channel
   ------------------------------

   --The write response channel provides feedback that the write has committed
   --to memory. BREADY will occur when all of the data and the write address
   --has arrived and been accepted by the slave.

   --The write issuance (number of outstanding write addresses) is started by 
   --the Address Write transfer, and is completed by a BREADY/BRESP.

   --While negating BREADY will eventually throttle the AWREADY signal, 
   --it is best not to throttle the whole data channel this way.

   --The BRESP bit [1] is used indicate any errors from the interconnect or
   --slave for the entire write burst. This example will capture the error 
   --into the ERROR output. 

   process(M_AXI_ACLK)                                             
   begin                                                                 
      if (rising_edge (M_AXI_ACLK)) then                                  
         if (M_AXI_ARESETN = '0' or store_pulse_s = '1') then                                    
            axi_bready <= '0';                                              
         -- accept/acknowledge bresp with axi_bready by the master       
         -- when M_AXI_BVALID is asserted by slave                       
         else                                                              
            if (M_AXI_BVALID = '1' and axi_bready = '0') then               
               axi_bready <= '1';                                            
            -- deassert after one clock cycle                             
            elsif (axi_bready = '1') then                                   
               axi_bready <= '0';                                            
            end if;                                                         
         end if;                                                           
      end if;                                                             
   end process;                                                          
   
   
   --Flag any write response errors                                        
   write_resp_error <= axi_bready and M_AXI_BVALID and M_AXI_BRESP(1);   


   ------------------------------
   --Read Address Channel
   ------------------------------

      
   process(M_AXI_ACLK)										  
   begin                                                              
      if (rising_edge (M_AXI_ACLK)) then                               
         if (M_AXI_ARESETN = '0' or load_pulse_s = '1') then                                 
            axi_arvalid <= '0';                                          
         -- If previously not valid , start next transaction             
         else                                                           
            if (axi_arvalid = '0' and start_single_burst_load = '1') then
               axi_arvalid <= '1';                                        
            elsif (M_AXI_ARREADY = '1' and axi_arvalid = '1') then       
               axi_arvalid <= '0';                                        
            end if;                                                      
         end if;                                                        
      end if;                                                          
   end process;                                                       
   

   ----------------------------------
   --Read Data (and Response) Channel
   ----------------------------------

   -- Forward movement occurs when the channel is valid and ready   
   rnext <= M_AXI_RVALID and axi_rready;                                 
   

   --*****************REMOVE READ_INDEX COUNTER IN FINAL CUT, THIS IS DEBUG LOGIC !!!!!
   
   -- Burst length counter. Uses extra counter register bit to indicate    
   -- terminal count to reduce decode logic                  
   process(M_AXI_ACLK)                                                   
   begin                                                                 
      if (rising_edge (M_AXI_ACLK)) then                                  
         if (M_AXI_ARESETN = '0' or start_single_burst_load = '1' or load_pulse_s = '1') then    
            read_index <= (others => '0');                                  
         else                                                              
            if (rnext = '1' and (read_index <= std_logic_vector(to_unsigned(C_M_AXI_BURST_LEN-1,clogb2(C_M_AXI_BURST_LEN) - 1)))) then   
               read_index <= std_logic_vector(unsigned(read_index) + 1);                               
            end if;                                                         
         end if;                                                           
      end if;                                                             
   end process;                                                          
   --*******************************************************************************************
   --/*                                                                    
   -- The Read Data channel returns the results of the read request        
   --                                                                      
   -- In this example the data checker is always able to accept            
   -- more data, so no need to throttle the RREADY signal                  
   -- */                                                                   
   process(M_AXI_ACLK)                                                   
   begin                                                                 
      if (rising_edge (M_AXI_ACLK)) then                                  
         if (M_AXI_ARESETN = '0' or load_pulse_s = '1') then             
            axi_rready <= '0';                                              
         -- accept/acknowledge rdata/rresp with axi_rready by the master    
         -- when M_AXI_RVALID is asserted by slave                         
         else                                                   
            if (M_AXI_RVALID = '1') then                         
               if (M_AXI_RLAST = '1' and axi_rready = '1') then   
                  axi_rready <= '0';                               
               else                                              
                  axi_rready <= '1';                              
               end if;                                            
            end if;                                              
         end if;                                                
      end if;                                                  
   end process;                                               
      
   --Flag any read response errors                                         
   read_resp_error <= axi_rready and M_AXI_RVALID and M_AXI_RRESP(1);    


  
   --------------------------------------------------------------------------------------------------
   -- This process is used to kick of read or write burst if load or store pulse
   -- appear
   MASTER_EXECUTION_PROC:process(M_AXI_ACLK)                                                                  
   begin                                                                                                      
      if (rising_edge(M_AXI_ACLK)) then
         if (M_AXI_ARESETN = '0') then
            start_single_burst_store <= '0';
            start_single_burst_load <= '0';
         else
            if (store_pulse_s = '1') then
               start_single_burst_store <= '1';
            else
               start_single_burst_store <= '0';
            end if;

            if (load_pulse_s = '1') then
               start_single_burst_load <= '1';
            else
               start_single_burst_load <= '0';
            end if;
         end if;         
      end if;
   end process;                                                                                               
      
   -- Check for last write completion.                                                                         
   
   -- This logic is to qualify the last write count with the final write                                       
   -- response. This demonstrates how to confirm that a write has been                                         
   -- committed.                                                                                               
   
   process(M_AXI_ACLK)                                                                                        
   begin                                                                                                      
      if (rising_edge (M_AXI_ACLK)) then                                                                       
         if (M_AXI_ARESETN = '0' ) then
            store_done_s <= '1';  
         elsif (store_pulse_s = '1') then
            store_done_s <= '0';
         --The store_done_s should be associated with a rready response
         else
            if (axi_bready = '1' and M_AXI_BVALID = '1') then 
               store_done_s <= '1';                                                                                
            end if; 
         end if;                                                                                                
      end if;
   end process;                                                                                               
   
   
   -- Check for last read completion.                                                                          
   
   -- This logic is to qualify the last read count with the final read                                         
   -- response. This demonstrates how to confirm that a read has been                                          
   -- committed.                                                                                               
   
      process(M_AXI_ACLK)                                                                                        
   begin                                                                                                      
      if (rising_edge (M_AXI_ACLK)) then                                                                       
         if (M_AXI_ARESETN = '0' ) then
            load_done_s <= '1';  
         elsif (load_pulse_s = '1') then
            load_done_s <= '0';
         --The load_done_s should be associated with a rready response
         else
            if (M_AXI_RLAST = '1') then
               load_done_s <= '1';                                                                                
            end if; 
         end if;                                                                                                
      end if;
   end process;                              

   -- Add user logic here

   ---------------------------------------------------------------------------
   --Debug logic used to test READ/WRITE, will be removed
      process (m_axi_aclk) is
   begin
      if (rising_edge(m_axi_aclk))then
         if (m_axi_aresetn = '0')then
            load_mem <= (others => (others => '0'));
         else
            if (M_AXI_RVALID = '1') then
               load_mem(to_integer(unsigned(read_index))) <= M_AXI_RDATA;
            end if;
         end if;
      end if;
   end process;
   -- User logic ends

end implementation;
