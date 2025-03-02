\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADDI, x0, x0, 1)              // Make x0 a non-zero value                     
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   // PC logic
   $next_pc[31:0] = $reset ? 32'b0 :
                    $taken_br ? $br_tgt_pc:
                    >>1$next_pc[31:0] + 4'h4;
   $pc[31:0] = >>1$next_pc;
   // Isntantiate READONLY_MEM macro after PC Logic
   `READONLY_MEM($pc, $$instr[31:0])
   // Decode logic for instruction types (R, I, S, B, U, J)
   // U Type Instruction
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   // I Type Instruction
   $is_i_instr = $instr[6:2] ==? 5'b0000x|| $instr[6:2] ==? 5'b001x0 || $instr[6:2] == 5'b11001;
   // S Type Instruction
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   // R Type Instruction
   $is_r_instr = $instr[6:2] == 5'b01011 || $instr[6:2] == 5'b01100 || $instr[6:2] == 5'b01110 || $instr[6:2] == 5'b10100;
   // J Type Instruction
   $is_j_instr = $instr[6:2] == 5'b11011;
   // B Type Instruction
   $is_b_instr = $instr[6:2] == 5'b11000;
   // Extract fields
   $opcode[6:0] = $instr[6:0];
   $rd[4:0] = $instr[11:7];
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $func3[2:0] = $instr[14:12];
   // Determine valid fields
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $rd_valid = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $imm_valid = $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   $func3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   // Ignore warnings
   `BOGUS_USE($rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $imm_valid...)
   // Extract imm
   $imm[31:0] = $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
                $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                $is_u_instr ? {$instr[31:12], 12'b0} :
                $is_j_instr ? {{11{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                32'b0;

   // Decode Logic
   $dec_bits[10:0] = {$instr[30], $func3, $opcode};
   $is_beq = $dec_bits ==? 11'bx_000_1100011;   // BEQ
   $is_bne = $dec_bits ==? 11'bx_001_1100011;   // BNE
   $is_blt = $dec_bits ==? 11'bx_100_1100011;   // BLT
   $is_bge = $dec_bits ==? 11'bx_101_1100011;   // BGE
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;   // BLTU
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;   // BGEU
   $is_addi = $dec_bits ==? 11'bx_000_0010011;   // ADDI
   $is_add = $dec_bits ==? 11'b0_000_0110011;   // ADD

   // Complete the decode instruction list for chapter 5
   $is_lui = $dec_bits ==? 11'bx_xxx_0110111;   //LUI
   $is_auipic = $dec_bits ==? 11'bx_xxx_0010111;   //AUIPC
   $is_jal = $dec_bits ==? 11'bx_xxx_1101111;   //JAL
   $is_jalr = $dec_bits ==? 11'bx_000_1101111;  //JALR
   $is_slti = $dec_bits ==? 11'bx_010_0010011;  //SLTI
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;  //SLTIU
   $is_xori = $dec_bits ==? 11'bx_100_0010011;  //XORI
   $is_ori = $dec_bits ==? 11'bx_110_0010011;  //ORI
   $is_andi = $dec_bits ==? 11'bx_111_0010011;  //ANDI
   $is_slli = $dec_bits ==? 11'b0_001_0010011;  //SLLI
   $is_slri = $dec_bits ==? 11'b0_101_0010011;  //SRLI
   $is_srai = $dec_bits ==? 11'b1_101_0010011;  //SRAI
   $is_sub = $dec_bits ==? 11'b1_000_0110011;  //SUB
   $is_sll = $dec_bits ==? 11'b0_001_0110011;  //SLL
   $is_slt = $dec_bits ==? 11'b0_010_0010011;  //SLT
   $is_sltu = $dec_bits ==? 11'b0_011_0010011;  //SLTU
   $is_xor = $dec_bits ==? 11'b0_100_0110011;  //XOR
   $is_srl = $dec_bits ==? 11'b0_101_0110011;  //SRL
   $is_sra = $dec_bits ==? 11'b1_101_0110011;  //SRA
   $is_or = $dec_bits ==? 11'b0_110_0110011;  //OR
   $is_and = $dec_bits ==? 11'b0_111_0110011;  //AND

   // Load and Store
   $is_load = $opcode == 7'b0000011;   // Load instructions are found in the opcode [LB, LH, LW, LBU, LHU]
   $is_store = $is_s_instr;            // Save instructions are identified by $is_s_instr [SB, SH, SW]

   // Ignore warnings
   `BOGUS_USE($imm $is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add ...)
   // ...
   
   // ALU (Arithmetic Logic Unit)
   $result[31:0] = $is_addi ? $src1_value + $imm:
                   $is_add ? $src1_value + $src2_value:
                   32'b0;
   
   //Register Wite
   $result_write[31:0] = $result;
   
   // Branch Logic
   $taken_br = $is_beq ? $src1_value == $src2_value :
               $is_bne ? $src1_value != $src2_value :
               $is_blt ? ($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) :
               $is_bge ? ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]):
               $is_bltu ? $src1_value < $src2_value :
               $is_bgeu ? $src1_value >= $src2_value :
                          1'b0;

   $br_tgt_pc[31:0] = $pc[31:0] + $imm;

   // Assert these to end simulation (before Makerchip cycle limit).
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   
   // Macro to instantiate register
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result_write[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   endmodule