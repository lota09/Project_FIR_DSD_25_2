/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : Accumulator_Flex.v
  - Description      : Accumulator
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

`timescale 1ns/10ps

module Accumulator_Flex (

  // Clock & reset
  input                 iClk,     // Rising edge
  input                 iRsn,     // Sync. & low reset

  // SpSram read data from SpSram.v
  input       [15:0]    iRdDt,

  // Accumulator's input selection from CtrlFsm.v
  input       [3:0]     iInSel,

  // Final out enable form CtrlFsm.v
  input                 iEnDelay,   // 2'b00: iRdDt & 16'h0
                                  // else : iRdDt & rAccDt[15:0]

  // Final out
  output reg  [15:0]    oAccOut

  );



  // wire & reg declaration
  wire   [15:0]         wAccInA;
  wire   [15:0]         wAccInB;
  wire signed  [20:0]   wAccSum;
 // wAccSum 왜 signed 임?? -> A,B 둘다 signed 로 확장해서 더했기 때문
 // wAccInA, wAccInB 실제로 FIR 필터 계수(coefficient) × 데이터(sample) 결과

  wire                  wSatCon_1;
  wire                  wSatCon_2;
  wire   [15:0]         wAccSumSat;

  reg    [15:0]         rAccDt;



  /*************************************************************/
  // Accumulator function
  /*************************************************************/
  // wAccInA : 16'h0        @ iInSel == 2'b00
  //           rAccDt[15:0] @ else
  //A는 계속 축적되는 값(피드백들어오는곳) B는 read 해온 데이터값

  assign wAccInA = (iInSel == 4'b0000) ? 16'h0 : rAccDt[15:0];


  // wAccInB : iRdDt[15:0]
  assign wAccInB = iRdDt[15:0];


  // wAccOut
  assign wAccSum = {{5{wAccInA[15]}}, wAccInA[15:0]} + {{5{wAccInB[15]}}, wAccInB[15:0]};



  /*************************************************************/
  // Saturation condition check
  /*************************************************************/
  // Condition #1 양수 오버플로우
  assign wSatCon_1 =  (iInSel==4'b1001) ? (( wAccSum > 20'sb0000_0111_1111_1111_1111 ) ?  1'b1 : 1'b0) : 1'b0;

  // Condition #2 음수 오버플로우
  assign wSatCon_2 =  (iInSel==4'b1001) ? (( wAccSum < 20'sb1111_1000_0000_0000_0000 ) ?  1'b1 : 1'b0) : 1'b0;


  // Output decision @ saturation condition
  // Condition #1 -> + Max
  // Condition #2 -> - Min
  // else         -> Normal result
  assign wAccSumSat = (wSatCon_1 == 1'b1) ? 16'h7FFF :
                      (wSatCon_2 == 1'b1) ? 16'h8000 : wAccSum[15:0];



  /*************************************************************/
  // Accumulator update
  /*************************************************************/
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      rAccDt <= 16'h0;
    else if (iInSel[3:0] != 4'b1001)
      rAccDt <= wAccSumSat[15:0];

  end
    


  /*************************************************************/
  // Final output
  /*************************************************************/
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      oAccOut <= 16'h0;
    else if (iInSel[3:0]==4'b1001)
      oAccOut <= wAccSumSat[15:0];

  end


endmodule
