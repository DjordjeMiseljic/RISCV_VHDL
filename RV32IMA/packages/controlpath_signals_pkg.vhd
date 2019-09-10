library ieee;
use ieee.std_logic_1164.all;

package controlpath_signals_pkg is

   -- register control signals for stalling and flushing
   signal if_id_write_s : std_logic;   
   signal id_ex_write_s : std_logic;   
   signal if_id_flush_s : std_logic;   
   signal id_ex_flush_s : std_logic;   

   --*********  INSTRUCTION DECODE **************
   signal branch_id_s : std_logic_vector(1 downto 0);
   signal funct3_id_s : std_logic_vector(2 downto 0);
   signal funct7_id_s : std_logic_vector(6 downto 0);
   signal alu_2bit_op_id_s: std_logic_vector(1 downto 0);
   signal alu_a_zero_id_s : std_logic;   
   
   signal control_stall_s: std_logic;

   signal alu_src_a_id_s : std_logic;
   signal alu_src_b_id_s : std_logic;

   signal mem_write_id_s : std_logic;
   signal reg_write_id_s : std_logic;
   signal mem_to_reg_id_s : std_logic_vector(1 downto 0);
   --signal mem_read_id_s : std_logic;
   --register addresses
   signal rs1_address_id_s: std_logic_vector (4 downto 0);
   signal rs2_address_id_s: std_logic_vector (4 downto 0);
   signal rd_address_id_s: std_logic_vector (4 downto 0);
   signal bcc_id_s : std_logic;
   --*********       EXECUTE       **************

   signal branch_ex_s : std_logic_vector(1 downto 0);
   signal funct3_ex_s : std_logic_vector(2 downto 0);
   signal funct7_ex_s : std_logic_vector(6 downto 0);
   signal alu_2bit_op_ex_s: std_logic_vector(1 downto 0);
   signal alu_a_zero_ex_s : std_logic;

   signal alu_src_a_ex_s : std_logic;
   signal alu_src_b_ex_s : std_logic;

   signal mem_write_ex_s : std_logic;
   signal reg_write_ex_s : std_logic;
   signal mem_to_reg_ex_s : std_logic_vector(1 downto 0);
   --signal mem_read_ex_s : std_logic;


   signal rs1_address_ex_s: std_logic_vector (4 downto 0);
   signal rs2_address_ex_s: std_logic_vector (4 downto 0);
   signal rd_address_ex_s: std_logic_vector (4 downto 0);

   --*********       MEMORY        **************

   signal funct3_mem_s : std_logic_vector(2 downto 0);
   signal mem_write_mem_s : std_logic;
   signal reg_write_mem_s : std_logic;
   signal mem_to_reg_mem_s : std_logic_vector(1 downto 0);
   --signal mem_read_mem_s : std_logic;

   signal rd_address_mem_s: std_logic_vector (4 downto 0);

   --*********      WRITEBACK      **************

   signal funct3_wb_s : std_logic_vector(2 downto 0);
   signal reg_write_wb_s : std_logic;
   signal mem_to_reg_wb_s : std_logic_vector(1 downto 0);
   signal rd_address_wb_s: std_logic_vector (4 downto 0);



--********************************************************

end package controlpath_signals_pkg;
