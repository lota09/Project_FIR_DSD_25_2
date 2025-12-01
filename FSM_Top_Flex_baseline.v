/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : FSM_Top.v
  - Description      : Top FSM wrapper for coefficient RAM access
                       (baseline version)
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module FSM_Top (

  input         iClk_12M,
  input         iRsn,

  input         iEnSample600k,
  input         iUpdateFlag,      // coefficient update phase flag

  input  [5:0]  iAddr,            // external address (0~63)
  input         iCsn,             // external chip select
  input         iWrn,             // external write enable (active low)

  output wire        oEnDelay,    // delay-chain enable
  output wire [3:0]  oInSel,      // FSM output selection for datapath
  //output wire      oEnOut,      // (optional) output valid flag, not used now

  // per-bank CS / WR after arbitration
  output wire        oCsn_Mux_1,
  output wire        oWrn_Mux_1,

  output wire        oCsn_Mux_2,
  output wire        oWrn_Mux_2,

  output wire        oCsn_Mux_3,
  output wire        oWrn_Mux_3,

  output wire        oCsn_Mux_4,
  output wire        oWrn_Mux_4,

  // shared 4-bit address bus to coefficient RAMs
  output wire [3:0]  oAddr_Mux
);

  /*********************************************/
  // Internal wires
  /*********************************************/
  // decoded external address (bank-local addr)
  wire [3:0] wAddr;

  // external access decoded per bank
  wire wCsn_1, wCsn_2, wCsn_3, wCsn_4;
  wire wWrn_1, wWrn_2, wWrn_3, wWrn_4;

  // FSM-generated access per bank
  wire wCsn_Fsm_1, wCsn_Fsm_2, wCsn_Fsm_3, wCsn_Fsm_4;
  wire wWrn_Fsm_1, wWrn_Fsm_2, wWrn_Fsm_3, wWrn_Fsm_4;
  wire [3:0] wAddr_Fsm;

  /*********************************************/
  // FSM : generate RAM access pattern & FIR control
  /*********************************************/
  Fsm_Flex u_fsm (
    .iClk_12M      (iClk_12M),
    .iRsn          (iRsn),
    .iEnSample600k (iEnSample600k),
    .iUpdateFlag   (iUpdateFlag),

    .oCsn_Fsm_1    (wCsn_Fsm_1),
    .oCsn_Fsm_2    (wCsn_Fsm_2),
    .oCsn_Fsm_3    (wCsn_Fsm_3),
    .oCsn_Fsm_4    (wCsn_Fsm_4),

    .oWrn_Fsm_1    (wWrn_Fsm_1),
    .oWrn_Fsm_2    (wWrn_Fsm_2),
    .oWrn_Fsm_3    (wWrn_Fsm_3),
    .oWrn_Fsm_4    (wWrn_Fsm_4),

    .oAddr_Fsm     (wAddr_Fsm),

    .oEnDelay      (oEnDelay),
    .oInSel        (oInSel)
    // .oEnOut      (oEnOut)   // 필요 시 FSM에서 valid 플래그 뽑아서 사용
  );

  /*********************************************/
  // Address decoder : external bus → per-bank CS/WR + local addr
  /*********************************************/
  AddrDecoder_Flex u_addr_decoder (
    .iAddr   (iAddr),
    .iCsn    (iCsn),
    .iWrn    (iWrn),

    .oAddr   (wAddr),

    .oCsn_1  (wCsn_1),
    .oCsn_2  (wCsn_2),
    .oCsn_3  (wCsn_3),
    .oCsn_4  (wCsn_4),

    .oWrn_1  (wWrn_1),
    .oWrn_2  (wWrn_2),
    .oWrn_3  (wWrn_3),
    .oWrn_4  (wWrn_4)
  );

  /*********************************************/
  // Access MUX : external vs FSM access arbitration
  /*********************************************/

  // Bank #1 : 이 뱅크에서 나온 주소를 공유 주소 버스로 사용
  AccessMux_Flex u_access_mux_1 (
    .iUpdateFlag (iUpdateFlag),

    .iCsn        (wCsn_1),
    .iWrn        (wWrn_1),
    .iAddr       (wAddr),

    .iCsn_Fsm    (wCsn_Fsm_1),
    .iWrn_Fsm    (wWrn_Fsm_1),
    .iAddr_Fsm   (wAddr_Fsm),

    .oCsn_Mux    (oCsn_Mux_1),
    .oWrn_Mux    (oWrn_Mux_1),
    .oAddr_Mux   (oAddr_Mux)
  );

  // Bank #2
  AccessMux_Flex u_access_mux_2 (
    .iUpdateFlag (iUpdateFlag),

    .iCsn        (wCsn_2),
    .iWrn        (wWrn_2),
    .iAddr       (wAddr),

    .iCsn_Fsm    (wCsn_Fsm_2),
    .iWrn_Fsm    (wWrn_Fsm_2),
    .iAddr_Fsm   (wAddr_Fsm),

    .oCsn_Mux    (oCsn_Mux_2),
    .oWrn_Mux    (oWrn_Mux_2),
    .oAddr_Mux   ()            // 주소는 공유 버스 사용, 이 뱅크에선 미사용
  );

  // Bank #3
  AccessMux_Flex u_access_mux_3 (
    .iUpdateFlag (iUpdateFlag),

    .iCsn        (wCsn_3),
    .iWrn        (wWrn_3),
    .iAddr       (wAddr),

    .iCsn_Fsm    (wCsn_Fsm_3),
    .iWrn_Fsm    (wWrn_Fsm_3),
    .iAddr_Fsm   (wAddr_Fsm),

    .oCsn_Mux    (oCsn_Mux_3),
    .oWrn_Mux    (oWrn_Mux_3),
    .oAddr_Mux   ()            // unused
  );

  // Bank #4
  AccessMux_Flex u_access_mux_4 (
    .iUpdateFlag (iUpdateFlag),

    .iCsn        (wCsn_4),
    .iWrn        (wWrn_4),
    .iAddr       (wAddr),

    .iCsn_Fsm    (wCsn_Fsm_4),
    .iWrn_Fsm    (wWrn_Fsm_4),
    .iAddr_Fsm   (wAddr_Fsm),

    .oCsn_Mux    (oCsn_Mux_4),
    .oWrn_Mux    (oWrn_Mux_4),
    .oAddr_Mux   ()            // unused
  );

endmodule
