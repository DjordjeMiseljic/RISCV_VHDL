library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_RISCV is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;
      -- ********* INSTRUCTION memory i/o *******************       
      instr_mem_read_i: in std_logic_vector(31 downto 0);
      instr_mem_address_o: out std_logic_vector(31 downto 0);
      instruction_mem_flush_o:out std_logic;
      -- ********* DATA memory i/o **************************
      mem_write_o: out std_logic;  
      data_mem_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_mem_read_i: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_mem_write_o: out std_logic_vector(DATA_WIDTH - 1 downto 0));
   

end entity;

architecture structural of TOP_RISCV is
   signal branch_s: std_logic_vector(1 downto 0);
   signal mem_read_s: std_logic; --TODO where should this signal go, should it exist?
   signal mem_to_reg_s: std_logic_vector(1 downto 0);
   signal alu_op_s: std_logic_vector (4 downto 0);
   signal mem_write_s: std_logic;
   signal alu_src_b_s: std_logic;
   signal alu_src_a_s: std_logic;
   signal alu_a_zero_s: std_logic;
   signal reg_write_s: std_logic;


   signal alu_forward_a_s    : std_logic_vector (1 downto 0);
   signal alu_forward_b_s    : std_logic_vector (1 downto 0);
   signal branch_forward_a_s : std_logic_vector (1 downto 0);
   signal branch_forward_b_s : std_logic_vector(1 downto 0);

   signal pc_write_s:  std_logic;--controls program counter
   signal if_id_reg_en_s:  std_logic;--controls istruction fetch 
   signal control_stall_s:  std_logic; -- controls mux that sets all the
         
   
begin
   -- Data_path will be instantiated here
   --************************************
   data_path_1: entity work.data_path
      generic map (
         DATA_WIDTH => DATA_WIDTH)
      port map (
         clk                => clk,
         reset              => reset,
         instr_mem_address_o    => instr_mem_address_o,
         instr_mem_read_i      => instr_mem_read_i,
         data_mem_address_o => data_mem_address_o,
         data_mem_write_o   => data_mem_write_o,
         data_mem_read_i    => data_mem_read_i,
         branch_i           => branch_s,
         alu_a_zero_i   => alu_a_zero_s,
         mem_read_i         => mem_read_s,
         mem_to_reg_i       => mem_to_reg_s,
         alu_op_i           => alu_op_s,
         alu_src_b_i          => alu_src_b_s,
         alu_src_a_i          => alu_src_a_s,
         reg_write_i        => reg_write_s,
         alu_forward_a_i => alu_forward_a_s,
         alu_forward_b_i => alu_forward_b_s,
         branch_forward_a_i => branch_forward_a_s,
         branch_forward_b_i => branch_forward_b_s,
         instruction_mem_flush_o => instruction_mem_flush_o
         --pc_write_i => pc_write_s,
         --if_id_reg_en_i => if_id_reg_en_s,         
       --control_stall_i => control_stall_s
         );
   -- Control_path will be instantiated here
   control_path_1: entity work.control_path
      port map (
         clk           => clk,
         reset         => reset,
         instruction_i => instr_mem_read_i,
         branch_o      => branch_s,
         alu_a_zero_o   => alu_a_zero_s,
         mem_read_o    => mem_read_s,
         mem_to_reg_o  => mem_to_reg_s,
         mem_write_o   => mem_write_o,
         alu_src_b_o     => alu_src_b_s,
         alu_src_a_o     => alu_src_a_s,
         reg_write_o   => reg_write_s,
         alu_op_o      => alu_op_s,
         alu_forward_a_o => alu_forward_a_s,
         alu_forward_b_o => alu_forward_b_s,
         branch_forward_a_o => branch_forward_a_s,
         branch_forward_b_o => branch_forward_b_s
         --pc_write_o => pc_write_s,
         --if_id_reg_en_o => if_id_reg_en_s,
       --control_stall_o => control_stall_s
         );
   

   

--************************************
   
end architecture;
