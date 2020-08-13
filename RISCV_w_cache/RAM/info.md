Zybo has 240KB of block RAM memory, distributed in 60 equal blocks of 4.5KB.

In this directory there will be multiple synthesizable versions of RAM vhdl code, some for distributed (LUTRAM) use, others for BRAM.

# PORTS
sp - single port
sdp - simple dual port
tdp - true dual port

# TYPE OF READ
ar - asynchronous read
wf - write first synchronous
rf - read first synchronous
nc - no change synchronous

# WRITE ENABLE
bw - byte write


