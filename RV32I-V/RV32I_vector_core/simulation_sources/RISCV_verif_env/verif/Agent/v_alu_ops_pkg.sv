`ifndef ALU_OPS_PKG_SV
`define ALU_OPS_PKG_SV


package v_alu_ops_pkg;
   
   

   // ALU OP CODE
   const logic [4 : 0] and_op= 5'b00000; //-> bitwise and
   const logic [4 : 0] or_op= 5'b00001; //-> bitwise or
   const logic [4 : 0] add_op= 5'b00010; //-> add a_i and b_i
   const logic [4 : 0] xor_op= 5'b00011; //-> bitwise xor   
   const logic [4 : 0] sub_op= 5'b00110; //-> sub a_i and b_i
   const logic [4 : 0] srl_op= 5'b00111; //-> shift right logic
   const logic [4 : 0] sra_op= 5'b01000; //-> shift right arithmetic
   const logic [4 : 0] mulu_op= 5'b01001; //-> multiply lower
   const logic [4 : 0] mulhs_op= 5'b01010; //-> multiply higher signed
   const logic [4 : 0] mulhsu_op= 5'b01011; //-> multiply higher signed and unsigned
   const logic [4 : 0] mulhu_op= 5'b01100; //-> multiply higher unsigned
   const logic [4 : 0] divu_op= 5'b01101; //-> divide unsigned
   const logic [4 : 0] divs_op= 5'b01110; //-> divide signed
   const logic [4 : 0] remu_op= 5'b01111; //-> reminder unsigned
   const logic [4 : 0] rems_op= 5'b10000; //-> reminder signed
   const logic [4 : 0] lts_op= 5'b10100; //-> set less than signed
   const logic [4 : 0] ltu_op= 5'b10101; //-> set less than unsigned
   const logic [4 : 0] sll_op= 5'b10110; //-> shift left logic      
   const logic [4 : 0] eq_op= 5'b10111; //->  set equal
endpackage: v_alu_ops_pkg

`endif