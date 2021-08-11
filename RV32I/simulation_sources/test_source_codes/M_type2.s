li a1, 123456
li a2, 234567
li a3, -234567
# 2s complement of a3 (32 bit): 11111111111111000110101110111001, dec: 4294732729
# full multiplication - 28958703552, 35 bits: 11010111110000100101011111111000000
# 31 downto 0: 10111110000100101011111111000000, 3188899776
# 34 downto 32: 110, 6
mul a4, a1, a2 # expected: a4=3188899776 (or -1106067520)
mulh a5, a1, a2 # expected: a5=6
mulhsu a6, a1, a2 # expected: a6=6
mulhu a7, a1, a2 # expected: a7=6

# 123456*-234567 = -28958703552
# lower 32 bits: 01000001111011010100000001000000
# upper 32 bits: 11111111111111111111111111111001 (added ones)
mul a4, a1, a3 # expected: a4=1106067520 (or 0x41ED4040)
mulh a5, a1, a3 # expected: a5=-7 (or 0xFFFFFFF9)
mulhsu a6, a3, a1 # expected: a6=-7 (or 0xFFFFFFF9)

