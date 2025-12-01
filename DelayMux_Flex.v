/*******************************************************************
  - Project          : 2025 Team Project ISAC
  - File name        : DelayMux_Flex.v
  - Description      : RAM read & write access multiplexer
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/



`timescale 1ns/10ps

module DelayMux_Flex (

  input   [3:0]    iInSel,
  

  // SP-SRAM write input from Top
  input   [2:0]    iTap_0,
  input   [2:0]    iTap_1,
  input   [2:0]    iTap_2,
  input   [2:0]    iTap_3,
  input   [2:0]    iTap_4,
  input   [2:0]    iTap_5,
  input   [2:0]    iTap_6,
  input   [2:0]    iTap_7,
  input   [2:0]    iTap_8,
  input   [2:0]    iTap_9,

  output  [2:0]    oTap_Mux
  );
  
  


 assign oTap_Mux = (iInSel == 4'd0) ? iTap_0 :
                  (iInSel == 4'd1) ? iTap_1 :
                  (iInSel == 4'd2) ? iTap_2 :
                  (iInSel == 4'd3) ? iTap_3 :
                  (iInSel == 4'd4) ? iTap_4 :
                  (iInSel == 4'd5) ? iTap_5 :
                  (iInSel == 4'd6) ? iTap_6 :
                  (iInSel == 4'd7) ? iTap_7 :
                  (iInSel == 4'd8) ? iTap_8 :
                  (iInSel == 4'd9) ? iTap_9 :
                  3'b000;


endmodule