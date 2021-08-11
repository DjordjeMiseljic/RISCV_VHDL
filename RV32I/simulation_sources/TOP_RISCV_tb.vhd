library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.txt_util.all;

entity TOP_RISCV_tb is
-- port ();
end entity;


architecture Behavioral of TOP_RISCV_tb is
   -- File operands   
   file RISCV_instructions             : text open read_mode is "../../../../../simulation_sources/assembly_code_M2.txt";
   -- Signals
   signal clk                          : std_logic;
   signal ce                          : std_logic;

   signal reset                        : std_logic;
   -- Instruction memory signals
   signal rsta_instr_s, rstb_instr_s   : std_logic;
   signal ena_instr_s, enb_instr_s     : std_logic;
   signal wea_instr_s, web_instr_s     : std_logic_vector(3 downto 0);
   signal addra_instr_s, addrb_instr_s : std_logic_vector(9 downto 0);
   signal dina_instr_s, dinb_instr_s   : std_logic_vector(31 downto 0);
   signal douta_instr_s, doutb_instr_s : std_logic_vector(31 downto 0);
   signal addrb_instr_32_s             : std_logic_vector(31 downto 0);
   -- Data memory signals
   signal rsta_data_s, rstb_data_s     : std_logic;
   signal ena_data_s, enb_data_s       : std_logic;
   signal wea_data_s, web_data_s       : std_logic_vector(3 downto 0);
   signal addra_data_s, addrb_data_s   : std_logic_vector(9 downto 0);
   signal dina_data_s, dinb_data_s     : std_logic_vector(31 downto 0);
   signal douta_data_s, doutb_data_s   : std_logic_vector(31 downto 0);
   signal addra_data_32_s              : std_logic_vector(31 downto 0);

begin

   -- Instruction Memory
   -- PORT A : test bench instruction initializationa
   -- PORT B : cpu reads instructions
   -- Constants:
   ce <= '1';
   ena_instr_s   <= '1';
   rsta_instr_s  <= '0';
   addrb_instr_s <= addrb_instr_32_s(9 downto 0);
   web_instr_s   <= (others => '0');
   dinb_instr_s  <= (others => '0');
   -- Instance:
   instruction_mem : entity work.BRAM(behavioral)
      generic map(WADDR => 10)
      port map (clk       => clk,
                -- port A
                en_a_i    => ena_instr_s,
                reset_a_i => rsta_instr_s,
                we_a_i    => wea_instr_s,
                addr_a_i  => addra_instr_s,
                data_a_i  => dina_instr_s,
                data_a_o  => douta_instr_s,
                -- port B
                en_b_i    => enb_instr_s,
                reset_b_i => rstb_instr_s,
                we_b_i    => web_instr_s,
                addr_b_i  => addrb_instr_s,
                data_b_i  => dinb_instr_s,
                data_b_o  => doutb_instr_s);


   -- Data memory
   -- PORT A : cpu writes and reads data
   -- PORT B : dummy
   -- Constants:
   addra_data_s <= addra_data_32_s(9 downto 0);
   addrb_data_s <= (others => '0');
   dinb_data_s  <= (others => '0');
   ena_data_s   <= '1';
   enb_data_s   <= '1';
   rsta_data_s  <= '0';
   rstb_data_s  <= '0';
   -- Instance:
   data_mem : entity work.BRAM(behavioral)
      generic map(WADDR => 10)
      port map (clk       => clk,
                -- port A
                en_a_i    => ena_data_s,
                reset_a_i => rsta_data_s,
                we_a_i    => wea_data_s,
                addr_a_i  => addra_data_s,
                data_a_i  => dina_data_s,
                data_a_o  => douta_data_s,
                -- port B
                en_b_i    => enb_data_s,
                reset_b_i => rstb_data_s,
                we_b_i    => web_data_s,
                addr_b_i  => addrb_data_s,
                data_b_i  => dinb_data_s,
                data_b_o  => doutb_data_s);


   -- Top Moule - RISCV processsor core instance
   TOP_RISCV_1 : entity work.TOP_RISCV
      port map (
         clk   => clk,
         ce => ce,
         reset => reset,

         instr_mem_read_i    => doutb_instr_s,
         instr_mem_address_o => addrb_instr_32_s,
         instr_mem_flush_o   => rstb_instr_s,
         instr_mem_en_o      => enb_instr_s,

         data_mem_we_o      => wea_data_s,
         data_mem_address_o => addra_data_32_s,
         data_mem_read_i    => douta_data_s,
         data_mem_write_o   => dina_data_s);

   -- Initialisation of instruction memory
   read_file_proc : process
      variable row : line;
      variable i   : integer := 0;
   begin
      reset       <= '0';
      wea_instr_s <= (others => '1');
      while (not endfile(RISCV_instructions))loop
         readline(RISCV_instructions, row);
         addra_instr_s <= std_logic_vector(to_unsigned(i, 10));
         dina_instr_s  <= to_std_logic_vector(string(row));
         i             := i + 4;
         wait until rising_edge(clk);
      end loop;
      wea_instr_s <= (others => '0');
      reset       <= '1' after 20 ns;
      wait;
   end process;

   -- clk generator
   clk_proc : process
   begin
      clk <= '1', '0' after 100 ns;
      wait for 200 ns;
   end process;

end architecture;
