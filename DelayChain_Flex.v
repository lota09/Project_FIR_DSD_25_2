/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : DelayChain_Flex.v
  - Description      : MAC Top file
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

`timescale 1ns/10ps

module DelayChain_Flex (

 input                            iClk,
 input                            iRsn,

 input                            iEnDelay,

 input         [2:0]              iFirIn,

 output reg    [2:0]              oTap_0,
 output reg    [2:0]              oTap_1,
 output reg    [2:0]              oTap_2,
 output reg    [2:0]              oTap_3,
 output reg    [2:0]              oTap_4,
 output reg    [2:0]              oTap_5,
 output reg    [2:0]              oTap_6,
 output reg    [2:0]              oTap_7,
 output reg    [2:0]              oTap_8,
 output reg    [2:0]              oTap_9,

 output wire   [2:0]              oTap

 
);

//reg [2:0] dff [0:9];
//integer i;
assign oTap = oTap_9;

always @(posedge iClk) begin
    if(!iRsn) begin
        
        oTap_0 <= 3'd0;
        oTap_1 <= 3'd0;
        oTap_2 <= 3'd0;
        oTap_3 <= 3'd0;
        oTap_4 <= 3'd0;
        oTap_5 <= 3'd0;
        oTap_6 <= 3'd0;
        oTap_7 <= 3'd0;
        oTap_8 <= 3'd0;
        oTap_9 <= 3'd0;
    end   

    else begin
        if (iEnDelay) begin 
        oTap_0 <= iFirIn;
        oTap_1 <= oTap_0;
        oTap_2 <= oTap_1;
        oTap_3 <= oTap_2;
        oTap_4 <= oTap_3;
        oTap_5 <= oTap_4;
        oTap_6 <= oTap_5;
        oTap_7 <= oTap_6;
        oTap_8 <= oTap_7;
        oTap_9 <= oTap_8;
        end
        
    end
end



endmodule