library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity alu_decoder is
	port (
		-- from data_path
		alu_2bit_op_i : in std_logic_vector (1 downto 0);
		funct3_i      : in std_logic_vector (2 downto 0);
		funct7_i      : in std_logic_vector (6 downto 0);
		-- to data_path
		alu_op_o : out alu_op_t);
end entity;

architecture behavioral of alu_decoder is
	signal funct7_5_s, funct7_0_s : std_logic;
begin

	funct7_5_s <= funct7_i(5);
	funct7_0_s <= funct7_i(0);
	--finds appropriate alu operation from control_decoder output and funct fields
	alu_dec : process (alu_2bit_op_i, funct3_i, funct7_5_s, funct7_0_s) is
	begin
		--default
		alu_op_o <= add_op;
		case alu_2bit_op_i is
			when "00" =>
				alu_op_o <= add_op;
				--when "01" =>
				--case(funct3_i(2 downto 1))is
				--when "00" =>
				--alu_op_o <= eq_op;
				--when "10" =>
				--alu_op_o <= lts_op;
				--when others =>
				--alu_op_o <= ltu_op;
				--end case;
			when "10" =>
				case funct3_i is
					when "000" =>
						alu_op_o <= add_op;
						if (funct7_5_s = '1') then
							alu_op_o <= sub_op;
					   end if;
						if (funct7_0_s = '1') then
							alu_op_o <= mul_op;
						end if;
					when "001" =>
						alu_op_o <= sll_op;
						if (funct7_0_s = '1') then
							alu_op_o <= mulh_op;
						end if;
					when "010" =>
						alu_op_o <= lts_op;
						if (funct7_0_s = '1') then
							alu_op_o <= mulhsu_op;
						end if;
					when "011" =>
						alu_op_o <= ltu_op;
						if (funct7_0_s = '1') then
							alu_op_o <= mulhu_op;
						end if;
					when "100" =>
						alu_op_o <= xor_op;
						if (funct7_0_s = '1') then
							alu_op_o <= div_op;
						end if;
					when "101" =>
						alu_op_o <= srl_op;
						if (funct7_5_s = '1') then
							alu_op_o <= sra_op;
						end if;
						if (funct7_0_s = '1') then
							alu_op_o <= divu_op;
						end if;
					when "110" =>
						alu_op_o <= or_op;
						if (funct7_0_s = '1') then
							alu_op_o <= rem_op;
						end if;
					when others =>
						alu_op_o <= and_op;
						if (funct7_0_s = '1') then
							alu_op_o <= remu_op;
						end if;
				end case;
			when others => -- immediate
				case funct3_i is
					when "000" =>
						alu_op_o <= add_op;
					when "001" =>
						alu_op_o <= sll_op;
					when "010" =>
						alu_op_o <= lts_op;
					when "011" =>
						alu_op_o <= ltu_op;
					when "100" =>
						alu_op_o <= xor_op;
					when "101" =>
						alu_op_o <= srl_op;
					when "110" =>
						alu_op_o <= or_op;
					when others =>
						alu_op_o <= and_op;
				end case;
		end case;
	end process;

end architecture;