library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;
entity vector_register_file is
   generic (DATA_WIDTH    : natural := 32;
            VECTOR_LENGTH : natural := 1024
            );
   port (clk   : in std_logic;
         reset : in std_logic;

         -- Control_signals
         vrf_type_of_access_i : in std_logic_vector(1 downto 0);  --there are r/w, r, w,and /

         vector_length_i : in std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) downto 0);
         alu_exe_time_i  : in std_logic_vector (2 downto 0);
         vmul_i          : in std_logic_vector(1 downto 0);
         vm_i            : in std_logic;
         
         -- input data
         vs1_address_i   : in std_logic_vector(4 downto 0);  --number of vector registers is 32
         vs2_address_i   : in std_logic_vector(4 downto 0);
         vd_address_i    : in std_logic_vector(4 downto 0);

         vd_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);

         -- output data        
         vs1_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);
         vs2_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);

         ready_o : out std_logic
         );
end entity;

architecture structural of vector_register_file is


   component VRF_BRAM_addr_generator is
      generic(VECTOR_LENGTH : natural := 1024;
              DATA_WIDTH    : natural := 32
              );
      port (
         clk                  : in std_logic;
         reset                : in std_logic;
         -- control signals
         vrf_type_of_access_i : in std_logic_vector(1 downto 0);  --there are r/w, r, w,and /
         alu_exe_time_i       : in std_logic_vector (2 downto 0);
         vmul_i               :    std_logic_vector(1 downto 0);
         -- input signals
         vs1_address_i        : in std_logic_vector(4 downto 0);
         vs2_address_i        : in std_logic_vector(4 downto 0);
         vd_address_i         : in std_logic_vector(4 downto 0);

         vector_length_i   : in  std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) downto 0);
         -- output signals
         BRAM1_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
         BRAM2_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
         BRAM_re_o        : out std_logic;

         mask_BRAM_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
         mask_BRAM_re_o        : out std_logic;
         
         BRAM_w_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
         BRAM_we_o        : out std_logic;

         
         ready_o : out std_logic

         
         
         );


   end component;
   --***************VRF_BRAM_addr_generator signals ***************************
   -- input signals 

   -- output signals   
   signal BRAM_we_s         : std_logic;
   signal mask_BRAM_we_s      : std_logic;
   signal mask_BRAM_re_s      : std_logic;
   signal BRAM_re_s         : std_logic;

   -- Signals coming out of mask BRAM
   signal mask_s : std_logic;
   signal VRF_mask_BRAM_re_s: std_logic;
   
   signal mask_BRAM_write_data_s: std_logic;
   -- Signals coming out of VRF_generator
   signal BRAM2_r_address_s : std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal mask_BRAM_r_address_s : std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal BRAM1_r_address_s : std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal BRAM_w_address_s  : std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal VRF_mask_BRAM_we_s      : std_logic;
   signal VRF_BRAM_re_s      : std_logic;
   --*************************************************************************

   
                                                     

begin

   --Generating control signals for mask bram
   mask_BRAM_we_s <= VRF_mask_BRAM_we_s when vd_address_i = "00000"  else
                   '0';
   mask_BRAM_re_s <= VRF_mask_BRAM_re_s when vm_i = '0' else
                     '0';

   -- Generating control signals for vector BRAM's
   BRAM_we_s <= VRF_mask_BRAM_we_s when mask_s = '1' and vm_i = '1' else
                '0';
   
   mask_reg : entity work.BRAM_18KB
      generic map (
         RAM_WIDTH       => 1,
         RAM_DEPTH       => VECTOR_LENGTH/DATA_WIDTH * 8, -- times 8 because of
                                                                                                    -- lmul
         RAM_PERFORMANCE => "LOW_LATENCY",
         INIT_FILE       => "")
      port map (
         clk             => clk,
         write_addr_i(clogb2(VECTOR_LENGTH/DATA_WIDTH * 8) - 1 downto 0)    => BRAM_w_address_s (clogb2(VECTOR_LENGTH/DATA_WIDTH * 8) - 1 downto 0),
         read_addr_i(clogb2(VECTOR_LENGTH/DATA_WIDTH * 8) - 1 downto 0)     => mask_BRAM_r_address_s(clogb2(VECTOR_LENGTH/DATA_WIDTH * 8) - 1 downto 0),      
         write_data_i(0)    => vd_data_i(0),
         we_i            => mask_BRAM_we_s,
         re_i            => mask_BRAM_re_s,
         rst_read_i      => '0',
         output_reg_en_i => '0',
         read_data_o(0)     => mask_s);


   VRF_BRAM_addr_generator_1 : VRF_BRAM_addr_generator
      generic map (VECTOR_LENGTH => VECTOR_LENGTH,
                   DATA_WIDTH    => DATA_WIDTH)
      port map (
         clk                  => clk,
         reset                => reset,
         vrf_type_of_access_i => vrf_type_of_access_i,
         alu_exe_time_i       => alu_exe_time_i,
         vmul_i               => vmul_i,    
         vs1_address_i        => vs1_address_i,
         vs2_address_i        => vs2_address_i,
         vd_address_i         => vd_address_i,
         vector_length_i      => vector_length_i,
         BRAM1_r_address_o    => BRAM1_r_address_s,
         BRAM2_r_address_o    => BRAM2_r_address_s,
         BRAM_re_o            => BRAM_re_s,

         BRAM_w_address_o     => BRAM_w_address_s,
         BRAM_we_o            => VRF_mask_BRAM_we_s,
         
         mask_BRAM_r_address_o => mask_BRAM_r_address_s,
         mask_BRAM_re_o => VRF_mask_BRAM_re_s,
         ready_o              => ready_o);


   BRAM_18KB_1 : entity work.BRAM_18KB
      generic map (
         RAM_WIDTH       => DATA_WIDTH,
         RAM_DEPTH       => VECTOR_LENGTH,
         RAM_PERFORMANCE => "LOW_LATENCY",
         INIT_FILE       => "")
      port map (
         clk             => clk,
         write_addr_i    => BRAM_w_address_s,
         read_addr_i     => BRAM1_r_address_s,
         write_data_i    => vd_data_i,
         we_i            => BRAM_we_s,
         re_i            => BRAM_re_s,
         rst_read_i      => '0',
         output_reg_en_i => '0',
         read_data_o     => vs1_data_o);

   BRAM_18KB_2 : entity work.BRAM_18KB
      generic map (
         RAM_WIDTH       => DATA_WIDTH,
         RAM_DEPTH       => VECTOR_LENGTH,
         RAM_PERFORMANCE => "LOW_LATENCY",
         INIT_FILE       => "")
      port map (
         clk             => clk,
         write_addr_i    => BRAM_w_address_s,
         read_addr_i     => BRAM2_r_address_s,
         write_data_i    => vd_data_i,
         we_i            => BRAM_we_s,
         re_i            => BRAM_re_s,
         rst_read_i      => '0',
         output_reg_en_i => '0',
         read_data_o     => vs2_data_o);


end structural;