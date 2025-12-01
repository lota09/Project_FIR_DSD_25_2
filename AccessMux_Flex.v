/*******************************************************************
  - Project          : 2025 Team Project Flex
  - File name        : AccssMux_Flex.v
  - Description      : RAM read & write access multiplexer
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

`timescale 1ns/10ps

module AccessMux_Flex (

  // Update flag
  input            iUpdateFlag,


  // SP-SRAM write input from Top
  input            iCsn,
  input            iWrn,
  input  [3:0]     iAddr,


  // SP-SRAM read input form FSM
  input            iCsn_Fsm,
  input            iWrn_Fsm,
  input  [3:0]     iAddr_Fsm,


  // SpSram.v access output to SpSram.v
  output            oCsn_Mux,
  output            oWrn_Mux,
  output  [3:0]     oAddr_Mux

  );


  /*************************************************************/
  // Mux. function
  /*************************************************************/
  // Csn mux
  assign oCsn_Mux  = (iUpdateFlag == 1'b1) ? iCsn : iCsn_Fsm;

  // Wrn mux
  assign oWrn_Mux  = (iUpdateFlag == 1'b1) ? iWrn : iWrn_Fsm;

  // Addr mux
  assign oAddr_Mux = (iUpdateFlag == 1'b1) ? iAddr[3:0] : iAddr_Fsm[3:0];


endmodule
