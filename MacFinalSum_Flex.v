/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : MACFinalSum_Flex.v
  - Description      : MAC Final Sum with Saturation
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.00 : 
*******************************************************************/

`timescale 1ns/10ps

module  MacFinalSum_Flex (

input                   iClk_12M,
input                   iRsn,

input                   iEnDelay,
input                   iEnSample_600k,



input       [15:0]      iMac_1,
input       [15:0]      iMac_2,
input       [15:0]      iMac_3,
input       [15:0]      iMac_4,


output  reg [15:0]      oFirOut

);




wire    signed  [17:0]    wMacSum;


wire                      wSatCon_1;
wire                      wSatCon_2;


wire        [15:0]        wMacSumSat;

assign wMacSum = {{2{iMac_1[15]}}, iMac_1} + {{2{iMac_2[15]}}, iMac_2} + {{2{iMac_3[15]}}, iMac_3} + {{2{iMac_4[15]}}, iMac_4};

  /*************************************************************/
  // Saturation condition check
  /*************************************************************/
  // Condition #1 양수 오버플로우
  assign wSatCon_1 =  (wMacSum >= 18'sb00_0111_1111_1111_1111) ? 1'b1 : 1'b0;

  // Condition #2 음수 오버플로우
  assign wSatCon_2 =  (wMacSum <= 18'sb11_1000_0000_0000_0000) ? 1'b1 : 1'b0;

  // Output decision @ saturation condition
  // Condition #1 -> + Max
  // Condition #2 -> - Min
  // else         -> Normal result
  assign wMacSumSat = (wSatCon_1 == 1'b1) ? 16'h7FFF :
                      (wSatCon_2 == 1'b1) ? 16'h8000 : wMacSum[15:0];


always @(posedge iClk_12M)
begin


    if (!iRsn)
        oFirOut <= 16'h0;
    else if (iEnDelay == 1'b1)
        oFirOut <= wMacSumSat[15:0];


end


endmodule