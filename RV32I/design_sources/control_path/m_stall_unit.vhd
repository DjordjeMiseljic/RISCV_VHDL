library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

-- This unit is used for stalling the PC for 3 cycles when  M type operations are calculated in ALU (requirement of DSP).
-- M type operations are multiplication, divison and reminder. 
-- These operations are not stalled when consecutive M type operations need to be calculated.

entity m_stall_unit is
    Port ( 
        clk            : in std_logic;
        ce             : in std_logic;
        reset          : in std_logic;
        instruction_i  : in std_logic_vector(31 downto 0);
        alu_op_i       : in alu_op_t;
        pc_en_o        : out std_logic;
        if_id_en_o     : out std_logic;
        id_ex_en_o     : out std_logic;
        control_pass_o : out std_logic
    );
end m_stall_unit;

architecture Behavioral of m_stall_unit is
    type state_t is (idle, delay1, delay2, delay3);
    signal state_r, state_n : state_t;
    signal opcode_s, funct7_s : std_logic_vector(6 downto 0);
    signal en_s : std_logic;
    constant m_opcode_c : std_logic_vector(6 downto 0) := "0110011";
    constant m_funct7_c : std_logic_vector(6 downto 0) := "0000001";
begin
    opcode_s <= instruction_i(6 downto 0);
    funct7_s <= instruction_i(31 downto 25);

    seq_proc: process (clk, ce) is begin
        if rising_edge(clk) and ce = '1' then
            if reset = '0' then
                state_r <= idle;
            else
                state_r <= state_n;
            end if;
        end if;
    end process;
    
    comb_proc: process (state_r, alu_op_i, opcode_s, funct7_s) is begin
        en_s <= '0';
        state_n <= idle;
        
        case state_r is 
            when idle =>
                case alu_op_i is
                    when mul_op|mulh_op|mulhsu_op|mulhu_op|div_op|divu_op|rem_op|remu_op =>
--                        if opcode_s = m_opcode_c and funct7_s = m_funct7_c then
--                            en_s <= '1';
--                        else
--                            state_n <= delay1;
--                        end if;
                        state_n <= delay1;
                    when others =>
                        en_s <= '1';
                end case;
            when delay1 =>
                state_n <= delay2;
            when delay2 =>
                state_n <= delay3;
            when delay3 =>
                en_s <= '1';
            when others =>
        end case;
    end process;
    
    pc_en_o <= en_s;
    if_id_en_o <= en_s;
    id_ex_en_o <= en_s;
    control_pass_o <= en_s;
    
end Behavioral;
