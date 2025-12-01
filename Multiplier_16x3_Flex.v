/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : Multiplier_16x3_Flex.v
  - Description      : 16비트(ia) × 3비트 곱셈기(ib, 계수) + 포화(saturation) 기능
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.00 : 
*******************************************************************/



`timescale 1ns/10ps

module  Multiplier_16x3_Flex (
    input                        iClk_12M,
    input                        iRsn,
    input       [3:0]            iInSel,   

    input       [15:0]           ia,
    input       [2:0]            ib,


    output reg  [15:0]           oMulOut,
    output reg  [3:0]            oInSel

);


//wire    signed    [15:0]         b_ext = {{13{b[2]}},b};

wire              [15:0]         abs_a; 
wire              [2:0]          abs_b;
wire                             sBitSum;    

assign  abs_a = (ia[15]==1) ? ~ia + 1'b1 : ia;
assign  abs_b = (ib[2]==1) ? ~ib + 1'b1 : ib;
assign  sBitSum = (ia[15]==ib[2]) ? 1'b0 : 1'b1;


//shift & add
wire    signed    [15:0]         partial_0 = abs_b[0] ? abs_a : 16'b0 ;
wire    signed    [16:0]         partial_1 = abs_b[1] ? (abs_a << 1) : 17'b0;
wire    signed    [17:0]         partial_2 = abs_b[2] ? (abs_a << 2) : 18'b0;  
wire    signed    [18:0]         wSum = partial_0 + partial_1 + partial_2;

wire                             wSatCon;
//wire                             wSatCon_2;

wire     signed    [15:0]        wSatSum;



//overflow detection
// Condition #1 양수 오버플로우

assign wSatCon =  (wSum >= 18'b00_0111_1111_1111_1111) ? 1'b1 : 1'b0;

// Condition #2 음수 오버플로우
//assign wSatCon_2 =  (wSum <= 18'b11_1000_0000_0000_0000) ? 1'b1 : 1'b0;

  // Output decision @ saturation condition
  // Condition #1 -> + Max
  // Condition #2 -> - Min
  // else         -> Normal result
assign wSatSum = (wSatCon == 1'b1 && sBitSum == 0) ? 16'h7FFF : 
                 (wSatCon == 1'b1 && sBitSum == 1) ? 16'h8000 :
                 (wSatCon == 1'b0 && sBitSum == 0) ? wSum : ~wSum + 1'b1;
            
                    

always @(posedge iClk_12M)
begin

    if (!iRsn)begin
        oMulOut <= 16'h0;
        oInSel <= 4'h0;
    end
    else begin
        oMulOut <= wSatSum[15:0];
        oInSel <= iInSel;
    end
end


endmodule