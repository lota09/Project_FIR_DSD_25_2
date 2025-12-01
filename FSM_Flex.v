/*******************************************************************
  - Project          : 2025 Team Project Flex
  - File name        : FSM_Flex.v
  - Description      : FSM(Finite State Machine)
  - Owner            : Flex Team
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

// 상태 전환은 600kHz 샘플 구동 신호의 활성 시점(iEnSample600k)이 기준이 됨
// Accumulator 초기화용 oEnDelay 역시 해당 샘플 트리거에 동기화되어 출력됨

`timescale 1ns/10ps

module Fsm_Flex (

  // Clock & reset
  input                 iClk_12M,      // Clk Rising edge
  input                 iRsn,          // Sync. & active low

  input                 iEnSample600k,


  // Update flag
  input                 iUpdateFlag,   // 1'b1: Write, 1'b0: Accmulation


  // SP-SRAM access output to SpSram.v
  // MUX에 들어가는 select 신호를 늘리는 게 좋을지? output wire를 늘리는 게 좋을지?
  output wire           oCsn_Fsm_1,
  output wire           oWrn_Fsm_1,
  
  output wire           oCsn_Fsm_2,
  output wire           oWrn_Fsm_2,
  
  output wire           oCsn_Fsm_3,
  output wire           oWrn_Fsm_3,
  
  output wire           oCsn_Fsm_4,
  output wire           oWrn_Fsm_4,
  
  output reg  [3:0]     oAddr_Fsm,


  // Accumulator control output to Accumulator.v
  output wire           oEnDelay, 
  output reg [3:0]      oInSel

  // FIR output valid (optional 사용 가능)
  // output wire           oEnOut

  );



  // Parameter
  parameter   p_Idle   = 2'b00,

              p_Update = 2'b01,
              p_MemRd  = 2'b10;



  // wire & reg
  reg    [1:0]     rCurState;     // Current state
  reg    [1:0]     rNxtState;     // Next    state

  wire             wLastRd;



  /*************************************************************/
  // FSM(Finite State Machine)
  /*************************************************************/
  // Part 1: Current state update
  //여기에서 sample 600k posedge에만 변하게 해야함
  always @(posedge iEnSample600k)
  begin

    if (!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[1:0];

  end



  // Part 2: Next state decision
  
  always @(*)
  begin

    case (rCurState)

      p_Idle     :
        if (iUpdateFlag == 1'b1)
          rNxtState <= p_Update;
        else
          rNxtState <= p_Idle;


      p_Update   :
        if (iUpdateFlag == 1'b0)
          rNxtState <= p_MemRd;
        else
          rNxtState <= p_Update;


      p_MemRd  :
        if (iUpdateFlag==1)
          rNxtState <= p_Update;
        else
          rNxtState <= p_MemRd;


      default    :
        rNxtState <= p_Idle;

    endcase

  end



  // Part 3: Output & enable making
  // oCsn_Fsm
  // _FSM 접미사가 붙은 output들은 MemRd state에서만 유효
  assign oCsn_Fsm_1 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;    // iAddr[5:4] == 00 and read mode  
  assign oCsn_Fsm_2 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;    // iAddr[5:4] == 01 and read mode
  assign oCsn_Fsm_3 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;    // iAddr[5:4] == 10 and read mode
  assign oCsn_Fsm_4 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;    // iAddr[5:4] == 11 and read mode
  // oEnOut
  
  assign oEnDelay = (iUpdateFlag == 0) ? iEnSample600k : 1'b0;
  
  //assign oEnOut   = (rCurState == p_Out)   ? 1'b1 : 1'b0;



  /*************************************************************/
  // Extra output making
  /*************************************************************/
  // oWrn_Fsm
  assign oWrn_Fsm_1  = 1'b1;     // iAddr[5:4] == 00
  assign oWrn_Fsm_2  = 1'b1;     // iAddr[5:4] == 01 
  assign oWrn_Fsm_3  = 1'b1;     // iAddr[5:4] == 10 
  assign oWrn_Fsm_4  = 1'b1;     // iAddr[5:4] == 11 
  
  
  // oAddr_Fsm[3:0]
  always @(posedge iClk_12M)
  begin

    // Reset condition
    if (!iRsn)
    begin
      oAddr_Fsm <= 4'b0;
    end
    // Initial condition
    else if (oEnDelay)
    begin
      oAddr_Fsm <= 4'h0;
    end
    // Increase condition
    else if (oCsn_Fsm_1 == 1'b0 || oCsn_Fsm_2 == 1'b0 || oCsn_Fsm_3 == 1'b0 || oCsn_Fsm_4 == 1'b0 )
    begin
          //1010 까지 가야할듯 그래야 값을 안받아감
      if (oAddr_Fsm == 4'b1001)
        oAddr_Fsm <= oAddr_Fsm[3:0];
      
      //else if(oAddr_Fsm > 4'b1001)
      //x 남는 6개의 값에 대한 예외처리 필요

      else 
        oAddr_Fsm <= oAddr_Fsm[3:0] + 1'b1;

    end

  end


  // oInSel[1:0]
  always @(posedge iClk_12M)
  begin

    // Reset condition
    if (!iRsn)
      oInSel <= 4'h0;
    // Initial condition
    else if (oEnDelay == 1'b1)
      oInSel <= 4'h0;
    else
      oInSel <= oAddr_Fsm[3:0];

  end

endmodule




















