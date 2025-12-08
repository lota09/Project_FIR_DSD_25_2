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
  
  // Current FSM state
  input  [1:0]     iCurState,


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

  // FSM state parameters (must match FSM_Flex.v)
  localparam p_Idle   = 2'b00;
  localparam p_Update = 2'b01;
  localparam p_MemRd  = 2'b10;


  /*************************************************************/
  // Mux. function
  // Use FSM state instead of iUpdateFlag to avoid timing issue
  // SRAM access is controlled only when FSM is in Update state
  /*************************************************************/
  // Csn mux
  assign oCsn_Mux  = (iCurState == p_Update) ? iCsn : iCsn_Fsm;

  // Wrn mux
  assign oWrn_Mux  = (iCurState == p_Update) ? iWrn : iWrn_Fsm;

  // Addr mux
  assign oAddr_Mux = (iCurState == p_Update) ? iAddr[3:0] : iAddr_Fsm[3:0];


endmodule
