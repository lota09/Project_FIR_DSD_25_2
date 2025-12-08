/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : FSM_Top_Flex.v
  - Description      : FSM_Top file
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.00 : 
*******************************************************************/

`timescale 1ns/10ps

module FSM_Top_Flex (

  input                         iClk_12M,
  input                         iRsn,
  
  input                         iEnSample600k,
  input                         iUpdateFlag,

  input         [5:0]           iAddr,
  input                         iCsn,
  input                         iWrn,

  output wire                   oEnDelay,
  output wire   [3:0]           oInSel,
  //output wire                 oEnOut,

  output wire                    oCsn_Mux_1,
  output wire                    oWrn_Mux_1,
  

  output wire                    oCsn_Mux_2,
  output wire                    oWrn_Mux_2,


  output wire                    oCsn_Mux_3,
  output wire                    oWrn_Mux_3,


  output wire                    oCsn_Mux_4,
  output wire                    oWrn_Mux_4,

  // shared 4-bit address bus to coefficient RAMs
  // 공유 4비트 주소 버스와 계수 RAM
  output wire [3:0]  oAddr_Mux
  );



  /*********************************************/
  // wire & reg
  /*********************************************/
  wire [3:0]       wAddr;

  wire             wCsn_1;
  wire             wCsn_2;
  wire             wCsn_3;
  wire             wCsn_4;

  wire             wWrn_1;
  wire             wWrn_2;
  wire             wWrn_3;
  wire             wWrn_4;

  wire             wCsn_Fsm_1;
  wire             wCsn_Fsm_2;
  wire             wCsn_Fsm_3;
  wire             wCsn_Fsm_4;

  wire             wWrn_Fsm_1;
  wire             wWrn_Fsm_2;
  wire             wWrn_Fsm_3;
  wire             wWrn_Fsm_4;

  wire [3:0]       wAddr_Fsm;
  wire [1:0]       wCurState;  // Current FSM state
 
 
// 일단 그라운드synthesis용
//  wire dummy_addr_2; 
//  wire dummy_addr_3; 
//  wire dummy_addr_4; or 
 // wire         gnd2;
 // wire         gnd3;
 // wire         gnd4;



  /*********************************************/
  // AccessMux.v instantiation
  /*********************************************/
  Fsm_Flex inst_Fsm(
    .iClk_12M(iClk_12M),
    .iRsn(iRsn),
    .iEnSample600k(iEnSample600k),
    .iUpdateFlag(iUpdateFlag),

    .oCsn_Fsm_1(wCsn_Fsm_1),
    .oCsn_Fsm_2(wCsn_Fsm_2),
    .oCsn_Fsm_3(wCsn_Fsm_3),
    .oCsn_Fsm_4(wCsn_Fsm_4),

    .oWrn_Fsm_1(wWrn_Fsm_1),
    .oWrn_Fsm_2(wWrn_Fsm_2),
    .oWrn_Fsm_3(wWrn_Fsm_3),
    .oWrn_Fsm_4(wWrn_Fsm_4),

    .oAddr_Fsm(wAddr_Fsm),

    .oEnDelay(oEnDelay),
    .oInSel(oInSel),
    .oCurState(wCurState)
   // .oEnOut(oEnOut)

  );



  /*********************************************/
  // CtrlFsm.v instantiation
  /*********************************************/
 AddrDecoder_Flex inst_AddrDecoder (
    .iAddr(iAddr),
    .iCsn(iCsn),
    .iWrn(iWrn),

    .oAddr(wAddr),

    .oCsn_1(wCsn_1),
    .oCsn_2(wCsn_2),
    .oCsn_3(wCsn_3),
    .oCsn_4(wCsn_4),

    .oWrn_1(wWrn_1),
    .oWrn_2(wWrn_2),
    .oWrn_3(wWrn_3),
    .oWrn_4(wWrn_4)
 
 );


  /*********************************************/
  // CtrlFsm.v instantiation
  /*********************************************/

 AccessMux_Flex inst_AccessMux_Flex_1 (

    .iUpdateFlag(iUpdateFlag),
    .iCurState(wCurState),

    .iCsn(wCsn_1),
    .iWrn(wWrn_1),
    .iAddr(wAddr),

    .iCsn_Fsm(wCsn_Fsm_1),
    .iWrn_Fsm(wWrn_Fsm_1),
    .iAddr_Fsm(wAddr_Fsm),

    .oCsn_Mux(oCsn_Mux_1),
    .oWrn_Mux(oWrn_Mux_1),
    .oAddr_Mux(oAddr_Mux)

 
 );

 AccessMux_Flex inst_AccessMux_Flex_2 (

    .iUpdateFlag(iUpdateFlag),
    .iCurState(wCurState),

    .iCsn(wCsn_2),
    .iWrn(wWrn_2),
    .iAddr(wAddr),

    .iCsn_Fsm(wCsn_Fsm_2),
    .iWrn_Fsm(wWrn_Fsm_2),
    .iAddr_Fsm(wAddr_Fsm),

    .oCsn_Mux(oCsn_Mux_2),
    .oWrn_Mux(oWrn_Mux_2),
    .oAddr_Mux()             // 주소 안 씀!!
   
 );


AccessMux_Flex inst_AccessMux_Flex_3 (

    .iUpdateFlag(iUpdateFlag),
    .iCurState(wCurState),

    .iCsn(wCsn_3),
    .iWrn(wWrn_3),
    .iAddr(wAddr),

    .iCsn_Fsm(wCsn_Fsm_3),
    .iWrn_Fsm(wWrn_Fsm_3),
    .iAddr_Fsm(wAddr_Fsm),

    .oCsn_Mux(oCsn_Mux_3),
    .oWrn_Mux(oWrn_Mux_3),
    .oAddr_Mux()             // 주소 안 씀!!
 
 );


AccessMux_Flex inst_AccessMux_Flex_4 (

    .iUpdateFlag(iUpdateFlag),
    .iCurState(wCurState),

    .iCsn(wCsn_4),
    .iWrn(wWrn_4),
    .iAddr(wAddr),

    .iCsn_Fsm(wCsn_Fsm_4),
    .iWrn_Fsm(wWrn_Fsm_4),
    .iAddr_Fsm(wAddr_Fsm),

    .oCsn_Mux(oCsn_Mux_4),
    .oWrn_Mux(oWrn_Mux_4),
    .oAddr_Mux()             // 주소 안 씀!!
 
 );

endmodule
