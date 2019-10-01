library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controlpath_signals_pkg.all;

entity control_path is
   port (
         -- global synchronization signals
         clk                : in std_logic;
         reset              : in std_logic;
         -- instruction is read from memory
         instruction_i      : in std_logic_vector (31 downto 0);
         -- from data_path comparator
         branch_condition_i : in std_logic;
         -- control signals forwarded to datapath and memory
         mem_to_reg_o: out std_logic_vector(1 downto 0);
         alu_op_o: out std_logic_vector(4 downto 0);
         alu_src_b_o: out std_logic;
         rd_we_o: out std_logic;
         pc_next_sel_o: out std_logic;
         data_mem_we_o: out std_logic_vector(3 downto 0);
         -- control singals for forwarding
         alu_forward_a_o: out std_logic_vector (1 downto 0);
         alu_forward_b_o: out std_logic_vector (1 downto 0);
         branch_forward_a_o: out std_logic_vector (1 downto 0); -- mux a 
         branch_forward_b_o: out std_logic_vector(1 downto 0); -- mux b
         -- control singals for flushing
         if_id_flush_o: out std_logic;
         -- control signals for stalling
         pc_en_o : out std_logic;
         if_id_en_o : out std_logic
         );  
end entity;


architecture behavioral of control_path is
begin


   --*********** Combinational logic ******************

   -- extract operation and operand data from instruction
   rs1_address_id_s <= instruction_i(19 downto 15);
   rs2_address_id_s <= instruction_i(24 downto 20);
   rd_address_id_s <= instruction_i(11 downto 7);

   funct7_id_s <= instruction_i(31 downto 25);
   funct3_id_s <= instruction_i(14 downto 12);

   -- this is decoder that decides which bytes are written to memory
   data_mem_write_decoder:
   data_mem_we_o <= "1111" when data_mem_we_mem_s = '1' else
                    "0000";

   -- this process covers conditional and unconditional branches
   -- base on which branch is executing: 
   --    control pc_next mux
   --    flush appropriate registers in pipeline
   pc_next_if_s:process(branch_id_s,branch_condition_i,bcc_id_s)
   begin
      if_id_flush_s <= '0';
      pc_next_sel_o <= '0';
      if (branch_id_s = '1' and branch_condition_i = '1')then --branch
         pc_next_sel_o <= '1';
         if_id_flush_s <= '1';
      end if;
   end process;
   


   --*********** Sequential logic ******************
   --ID/EX register
   id_ex:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0' or control_pass_s = '0')then
            branch_ex_s      <= '0';
            funct3_ex_s      <= (others => '0');
            funct7_ex_s      <= (others => '0');
            alu_src_b_ex_s   <= '0';
            mem_to_reg_ex_s  <= (others => '0');
            alu_2bit_op_ex_s <= (others => '0');
            rs1_address_ex_s <= (others => '0');
            rs2_address_ex_s <= (others => '0');
            rd_address_ex_s  <= (others => '0');
            rd_we_ex_s       <= '0';
            data_mem_we_ex_s <= '0';
         else
            branch_ex_s      <= branch_id_s;
            funct7_ex_s      <= funct7_id_s;
            funct3_ex_s      <= funct3_id_s;
            alu_src_b_ex_s   <= alu_src_b_id_s;
            mem_to_reg_ex_s  <= mem_to_reg_id_s;
            alu_2bit_op_ex_s <= alu_2bit_op_id_s;
            rs1_address_ex_s <= rs1_address_id_s; rs2_address_ex_s <= rs2_address_id_s;
            rd_address_ex_s  <= rd_address_id_s;
            rd_we_ex_s       <= rd_we_id_s;
            data_mem_we_ex_s <= data_mem_we_id_s;
         end if;
      end if;      
   end process;

   --EX/MEM register
   ex_mem:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            data_mem_we_mem_s <= '0';
            rd_we_mem_s       <= '0';
            mem_to_reg_mem_s  <= (others => '0');
            rd_address_mem_s  <= (others => '0');
         else
            data_mem_we_mem_s <= data_mem_we_ex_s;
            rd_we_mem_s       <= rd_we_ex_s;
            mem_to_reg_mem_s  <= mem_to_reg_ex_s;
            rd_address_mem_s  <= rd_address_ex_s;
         end if;
      end if;      
   end process;

   --MEM/WB register
   mem_wb:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            rd_we_wb_s      <= '0';
            mem_to_reg_wb_s <= (others => '0');
            rd_address_wb_s <= (others => '0');
         else
            rd_we_wb_s      <= rd_we_mem_s;
            mem_to_reg_wb_s <= mem_to_reg_mem_s;
            rd_address_wb_s <= rd_address_mem_s;
         end if;
      end if;      
   end process;



   --*********** Instantiation ******************

   -- Control decoder
   ctrl_dec: entity work.ctrl_decoder(behavioral)
      port map(
         opcode_i       => instruction_i(6 downto 0),
         branch_o       => branch_id_s,
         mem_to_reg_o   => mem_to_reg_id_s,
         data_mem_we_o  => data_mem_we_id_s,
         alu_src_b_o    => alu_src_b_id_s,
         rd_we_o        => rd_we_id_s,
         rs1_in_use_o   => rs1_in_use_id_s,
         rs2_in_use_o   => rs2_in_use_id_s,
         alu_2bit_op_o  => alu_2bit_op_id_s);

   -- ALU decoder
   alu_dec: entity work.alu_decoder(behavioral)
      port map(
         alu_2bit_op_i  => alu_2bit_op_ex_s,
         funct3_i       => funct3_ex_s,
         funct7_i       => funct7_ex_s,
         alu_op_o       => alu_op_o);

   -- Forwarding_unit
   forwarding_u: entity work.forwarding_unit(behavioral)
      port map (
         rd_we_mem_i        => rd_we_mem_s,
         rd_address_mem_i   => rd_address_mem_s,
         rd_we_wb_i         => rd_we_wb_s,
         rd_address_wb_i    => rd_address_wb_s,
         rs1_address_ex_i   => rs1_address_ex_s,
         rs2_address_ex_i   => rs2_address_ex_s,
         rs1_address_id_i   => rs1_address_id_s,
         rs2_address_id_i   => rs2_address_id_s,
         alu_forward_a_o    => alu_forward_a_o,
         alu_forward_b_o    => alu_forward_b_o,
         branch_forward_a_o => branch_forward_a_o,
         branch_forward_b_o => branch_forward_b_o);

   -- Hazard unit
   hazard_u: entity work.hazard_unit(behavioral)
      port map (
         rs1_address_id_i => rs1_address_id_s,
         rs2_address_id_i => rs2_address_id_s,
         rs1_in_use_i     => rs1_in_use_id_s,
         rs2_in_use_i     => rs2_in_use_id_s,
         branch_id_i      => branch_id_s,

         rd_address_ex_i  => rd_address_ex_s,
         mem_to_reg_ex_i  => mem_to_reg_ex_s,
         rd_we_ex_i       => rd_we_ex_s,

         rd_address_mem_i => rd_address_mem_s,
         mem_to_reg_mem_i => mem_to_reg_mem_s,

         pc_en_o          => pc_en_o,
         if_id_en_o       => if_id_en_s,
         control_pass_o   => control_pass_s);



   --********** Outputs **************

   -- forward control signals to datapath
   if_id_en_o <= if_id_en_s;
   mem_to_reg_o <= mem_to_reg_wb_s;
   alu_src_b_o <= alu_src_b_ex_s;
   rd_we_o <= rd_we_wb_s;
   if_id_flush_o <= if_id_flush_s;



end architecture;

