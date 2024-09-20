\m5_TLV_version 1d: tl-x.org
\m5
   
   // =================================================
   // Welcome!  New to Makerchip? Try the "Learn" menu.
   // =================================================
   
   //use(m5-1.0)   /// uncomment to use M5 macro library.
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
	m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/calc_viz.tlv'])
\TLV
   m4+calc_viz()
   $reset = *reset;
   
   $val1_upper[25:0] = 0;
   $val1[31:0] = {$val1_upper, $val1_lower[5:0]};
   
   $val2_upper[27:0] = 0;
   $val2[31:0] = {$val2_upper, $val2_lower[3:0]};
   
   $sum[31:0] = $val1 + $val2[31:0]; // Case 1
   $dif[31:0] = $val1 - $val2;             // Case 2
   $prod[31:0] = $val1 * $val2;            // Case 3
   $quot[31:0] = $val1 / $val2;            // Case 4
   $out[31:0] = $op[1:0] == 2'b00 ? $sum:
                $op[1:0] == 2'b01 ? $dif:
                $op[1:0] == 2'b10 ? $prod:
                $quot;
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
