/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : MACTop_Flex.v
  - Description      : MAC Top file
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.00 : 
*******************************************************************/

`timescale 1ns/10ps

module MACTop_Flex (

  // Clock & reset
  input                iClk_12M,      // Rising edge
  input                iRsn,          // Sync. & low reset

  // SP-SRAM write input from Top
  input  [15:0]        iCoeff,
  input  [2:0]         iFIRin,

  input  [3:0]         iInSel,
  input                iEnDelay,

  output wire [15:0]    oMac

  );



  /*********************************************/
  // wire & reg
  /*********************************************/

  wire   [15:0]        wMulOut;
  wire   [3:0]         wInSel;


  /*********************************************/
  // Multiplier_16x3.v instantiation
  /*********************************************/
  Multiplier_16x3_Flex inst_Multiplier_16x3 (
    .iClk_12M           (iClk_12M),
    .iRsn               (iRsn),
    .ia                 (iCoeff),
    .ib                 (iFIRin),
    .iInSel             (iInSel[3:0]),
    .oInSel             (wInSel[3:0]),
    .oMulOut            (wMulOut[15:0]) 
  );

  /*********************************************/
  // Accumulator.v instantiation
  /*********************************************/
  Accumulator_Flex inst_Accumulator (
    .iClk               (iClk_12M),
    .iRsn               (iRsn),
    .iRdDt              (wMulOut[15:0]),
    .iInSel             (wInSel[3:0]),
    .iEnDelay           (iEnDelay),
    .oAccOut            (oMac)
  );

endmodule