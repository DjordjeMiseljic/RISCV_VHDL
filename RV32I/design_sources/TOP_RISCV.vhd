library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity TOP_RISCV is
   port(
      -- Synchronization ports
      clk                 : in  std_logic;
      ce                  : in  std_logic;
      reset               : in  std_logic;
      -- Instruction memory interface
      instr_mem_address_o : out std_logic_vector(31 downto 0);
      instr_mem_read_i    : in  std_logic_vector(31 downto 0);
      instr_mem_flush_o   : out std_logic;
      instr_mem_en_o      : out std_logic;
      -- Data memory interface
      data_mem_address_o  : out std_logic_vector(31 downto 0);
      data_mem_read_i     : in  std_logic_vector(31 downto 0);
      data_mem_write_o    : out std_logic_vector(31 downto 0);
      data_mem_we_o       : out std_logic_vector(3 downto 0));  
end entity;

architecture structural of TOP_RISCV is
   signal set_a_zero_s       : std_logic;
   signal mem_to_reg_s       : std_logic_vector(1 downto 0);
   signal load_type_s        : std_logic_vector(2 downto 0);
   signal alu_op_s           : alu_op_t;
   signal alu_src_b_s        : std_logic;
   signal alu_src_a_s        : std_logic;
   signal rd_we_s            : std_logic;
   signal pc_next_sel_s      : std_logic;

   signal if_id_flush_s      : std_logic;
   signal id_ex_flush_s      : std_logic;

   signal alu_forward_a_s    : fwd_a_t;
   signal alu_forward_b_s    : fwd_b_t;
   signal branch_condition_s : std_logic;
   signal branch_op_s        : std_logic_vector(1 downto 0);

   signal pc_en_s          : std_logic;
   signal if_id_en_s       : std_logic;
   signal id_ex_en_s       : std_logic;
   
begin
   -- Data_path instance
   data_path_1: entity work.data_path
      port map (
         -- global synchronization signals
         clk                 => clk,
         ce                  => ce,
         reset               => reset,
         -- operands come from instruction memory
         instr_mem_address_o => instr_mem_address_o,
         instr_mem_read_i    => instr_mem_read_i,
         -- interface towards data memory
         data_mem_address_o  => data_mem_address_o,
         data_mem_write_o    => data_mem_write_o,
         data_mem_read_i     => data_mem_read_i,
         -- control signals come from control path
         set_a_zero_i        => set_a_zero_s,
         mem_to_reg_i        => mem_to_reg_s,
         load_type_i         => load_type_s,
         alu_op_i            => alu_op_s,
         alu_src_b_i         => alu_src_b_s,
         alu_src_a_i         => alu_src_a_s,
         rd_we_i             => rd_we_s,
         pc_next_sel_i       => pc_next_sel_s,
		 branch_op_i 		 => branch_op_s,
         -- control signals for forwaring
         alu_forward_a_i     => alu_forward_a_s,
         alu_forward_b_i     => alu_forward_b_s,
         branch_condition_o  => branch_condition_s,
         -- control signals for flushing
         if_id_flush_i       => if_id_flush_s,
         id_ex_flush_i       => id_ex_flush_s,
         -- control signals for stalling
         pc_en_i             => pc_en_s,
         if_id_en_i          => if_id_en_s,
         id_ex_en_i          => id_ex_en_s); 

   --flush current instruction
   instr_mem_flush_o <= if_id_flush_s;

   -- Control_path instance
   control_path_1: entity work.control_path
      port map (
         -- global synchronization signals
         clk                 => clk,
         ce                  => ce,
         reset               => reset,
         -- instruction is read from memory
         instruction_i       => instr_mem_read_i,
         -- control signals are forwarded to data_path
         set_a_zero_o        => set_a_zero_s,
         mem_to_reg_o        => mem_to_reg_s,
         load_type_o         => load_type_s,
         alu_op_o            => alu_op_s,
         alu_src_b_o         => alu_src_b_s,
         alu_src_a_o         => alu_src_a_s,
         rd_we_o             => rd_we_s,
         pc_next_sel_o       => pc_next_sel_s,
		 branch_op_o 		 => branch_op_s,
         -- control signals for forwarding
         alu_forward_a_o     => alu_forward_a_s,
         alu_forward_b_o     => alu_forward_b_s,
         branch_condition_i  => branch_condition_s,
         -- control signals for flushing
         data_mem_we_o       => data_mem_we_o,
         if_id_flush_o       => if_id_flush_s,
         id_ex_flush_o       => id_ex_flush_s,
         -- control signals for stalling
         pc_en_o             => pc_en_s,
         if_id_en_o          => if_id_en_s,
         id_ex_en_o          => id_ex_en_s); 

   -- stall current instruction
   instr_mem_en_o <= if_id_en_s;
end architecture;
