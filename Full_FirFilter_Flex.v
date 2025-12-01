// ============================================================================
// Full_FirFilter_Flex.v - Complete FIR Filter Design Concatenation
// All modules combined in single file for AI analysis
// Date: 2025.12.01
// ============================================================================

`timescale 1ns/10ps

// ============================================================================
// TOP MODULE: Top_FirFilter_Flex
// ============================================================================
module Top_FirFilter_Flex (
    // === 1. External Inputs (Diagram Left) ===
    input  wire        iClk12M,
    input  wire        iRsn, 

    input  wire        iEnSample600k,
    input  wire        iCoeffUpdateFlag, // (FSM의 iUpdateFlag)

    // SRAM Interface Inputs
    input  wire        iCsnRam,
    input  wire        iWrnRam,
    input  wire [5:0]  iAddrRam,
    input  wire [15:0] iWrDtRam,

    // Filter Input
    input  wire [2:0]  iFirIn,

    // === 2. External Output (Diagram Right) ===
    output wire [15:0] oFirOut
);

    // ====================================================
    // Internal Wires (Diagram Naming)
    // ====================================================
    
    // --- 1. Controller(FSM) to RAM wires ---
    // RAM #1
    wire        wCsnRam1;
    wire        wWrnRam1;
    wire [3:0]  wAddrRam1;
    wire [15:0] wWtDtRam1;
    wire [15:0] wRdDtRam1; // RAM에서 읽은 데이터
    
    // RAM #2
    wire        wCsnRam2;
    wire        wWrnRam2;
    wire [3:0]  wAddrRam2;
    wire [15:0] wWtDtRam2;
    wire [15:0] wRdDtRam2;

    // RAM #3
    wire        wCsnRam3;
    wire        wWrnRam3;
    wire [3:0]  wAddrRam3;
    wire [15:0] wWtDtRam3;
    wire [15:0] wRdDtRam3;

    // RAM #4
    wire        wCsnRam4;
    wire        wWrnRam4;
    wire [3:0]  wAddrRam4;
    wire [15:0] wWtDtRam4;
    wire [15:0] wRdDtRam4;


    // --- 2. Controller to MAC/Delay/Sum Control wires ---
    wire        wEnDelay; // Sum 및 Delay Chain으로 가는 Enable 신호
    wire [3:0]  wInSel;   // (다이어그램엔 없지만 Mux 제어용 필수 신호)
    
    // *참고: 다이어그램의 wEnMul, wEnAdd, wEnAcc는 
    // 실제 하위 모듈(MAC)에 포트가 없으므로 wEnDelay와 wInSel로 대체하여 동작시킴


    // --- 3. Delay Chain Interconnects (Delay -> MAC) ---
    wire [2:0]  wDelay1_10;  // 1st Delay Chain output
    wire [2:0]  wDelay11_20; // 2nd Delay Chain output
    wire [2:0]  wDelay21_30; // 3rd Delay Chain output
    wire [2:0]  wDelay31_40; // 4th Delay Chain output (MAC #4 Input)

    // Delay Chain끼리 이어주는 체인(기차) 연결선
    wire [2:0]  wChain_1, wChain_2, wChain_3, wChain_4;


    // --- 4. RAM to Multiplier (Coefficient) ---
    // 다이어그램상 RAM 출력(wRdDt)이 곧 계수(wCoeff)입니다.
    // 이름을 맞추기 위해 alias(별칭) 전선을 만듭니다.
    wire [15:0] wCoeff1_10;
    wire [15:0] wCoeff11_20;
    wire [15:0] wCoeff21_30;
    wire [15:0] wCoeff31_40;

    assign wCoeff1_10  = wRdDtRam1;
    assign wCoeff11_20 = wRdDtRam2;
    assign wCoeff21_30 = wRdDtRam3;
    assign wCoeff31_40 = wRdDtRam4;


    // --- 5. MAC Outputs (to Sum) ---
    wire [15:0] wMac1;
    wire [15:0] wMac2;
    wire [15:0] wMac3;
    wire [15:0] wMac4;
    

    // ====================================================
    // Wiring Assignments (Data Distribution)
    // ====================================================
    // 외부에서 들어온 쓰기 데이터(iWrDtRam)를 각 뱅크의 입력 와이어에 연결
    assign wWtDtRam1 = iWrDtRam;
    assign wWtDtRam2 = iWrDtRam;
    assign wWtDtRam3 = iWrDtRam;
    assign wWtDtRam4 = iWrDtRam;


    // ====================================================
    // Module Instantiation
    // ====================================================

    // 1. Controller (FSM)
    // FSM은 공유 주소(Mux Address)를 내보내므로, 이를 각 wAddrRam에 연결해줍니다.
    wire [3:0] wAddr_Mux_Shared; 
    assign wAddrRam1 = wAddr_Mux_Shared;
    assign wAddrRam2 = wAddr_Mux_Shared;
    assign wAddrRam3 = wAddr_Mux_Shared;
    assign wAddrRam4 = wAddr_Mux_Shared;

    FSM_Top_Flex inst_FSM_Top (
        .iClk_12M       (iClk12M),
        .iRsn           (iRsn),
        .iEnSample600k  (iEnSample600k),
        .iUpdateFlag    (iCoeffUpdateFlag),

        .iAddr          (iAddrRam),
        .iCsn           (iCsnRam),
        .iWrn           (iWrnRam),

        .oEnDelay       (wEnDelay),
        .oInSel         (wInSel),
        .oAddr_Mux      (wAddr_Mux_Shared), // 공유 주소 출력

        // Diagram Names Matching
        .oCsn_Mux_1(wCsnRam1), .oWrn_Mux_1(wWrnRam1),
        .oCsn_Mux_2(wCsnRam2), .oWrn_Mux_2(wWrnRam2),
        .oCsn_Mux_3(wCsnRam3), .oWrn_Mux_3(wWrnRam3),
        .oCsn_Mux_4(wCsnRam4), .oWrn_Mux_4(wWrnRam4)
    );

    // 2. RAM Banks (Coefficient RAMs)
    SpSram #(.SRAM_DEPTH(16), .DATA_WIDTH(16)) inst_Sram_1 (
        .iClk(iClk12M), .iRsn(iRsn), 
        .iCsn(wCsnRam1), .iWrn(wWrnRam1), .iAddr(wAddrRam1), 
        .iWrDt(wWtDtRam1), .oRdDt(wRdDtRam1) 
    );
    SpSram #(.SRAM_DEPTH(16), .DATA_WIDTH(16)) inst_Sram_2 (
        .iClk(iClk12M), .iRsn(iRsn), 
        .iCsn(wCsnRam2), .iWrn(wWrnRam2), .iAddr(wAddrRam2), 
        .iWrDt(wWtDtRam2), .oRdDt(wRdDtRam2) 
    );
    SpSram #(.SRAM_DEPTH(16), .DATA_WIDTH(16)) inst_Sram_3 (
        .iClk(iClk12M), .iRsn(iRsn), 
        .iCsn(wCsnRam3), .iWrn(wWrnRam3), .iAddr(wAddrRam3), 
        .iWrDt(wWtDtRam3), .oRdDt(wRdDtRam3) 
    );
    SpSram #(.SRAM_DEPTH(16), .DATA_WIDTH(16)) inst_Sram_4 (
        .iClk(iClk12M), .iRsn(iRsn), 
        .iCsn(wCsnRam4), .iWrn(wWrnRam4), .iAddr(wAddrRam4), 
        .iWrDt(wWtDtRam4), .oRdDt(wRdDtRam4) 
    );

    // 3. Delay Chain
    // (wDelay1_10 등 다이어그램 이름으로 매칭)
    DelayChainTop_Flex inst_Delay_1 (.iClk(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(iFirIn),      .iInSel(wInSel), .oTap_Mux(wDelay1_10),  .oChain(wChain_1));
    DelayChainTop_Flex inst_Delay_2 (.iClk(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(wChain_1),    .iInSel(wInSel), .oTap_Mux(wDelay11_20), .oChain(wChain_2));
    DelayChainTop_Flex inst_Delay_3 (.iClk(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(wChain_2),    .iInSel(wInSel), .oTap_Mux(wDelay21_30), .oChain(wChain_3));
    DelayChainTop_Flex inst_Delay_4 (.iClk(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(wChain_3),    .iInSel(wInSel), .oTap_Mux(wDelay31_40), .oChain(wChain_4));

    // 4. Multiplier & Adder & Acc
    // (wCoeff1_10 과 wDelay1_10 사용)
    MACTop_Flex inst_MAC_1 (.iClk_12M(iClk12M), .iRsn(iRsn), .iCoeff(wCoeff1_10),  .iFIRin(wDelay1_10),  .iInSel(wInSel), .iEnDelay(wEnDelay), .oMac(wMac1));
    MACTop_Flex inst_MAC_2 (.iClk_12M(iClk12M), .iRsn(iRsn), .iCoeff(wCoeff11_20), .iFIRin(wDelay11_20), .iInSel(wInSel), .iEnDelay(wEnDelay), .oMac(wMac2));
    MACTop_Flex inst_MAC_3 (.iClk_12M(iClk12M), .iRsn(iRsn), .iCoeff(wCoeff21_30), .iFIRin(wDelay21_30), .iInSel(wInSel), .iEnDelay(wEnDelay), .oMac(wMac3));
    MACTop_Flex inst_MAC_4 (.iClk_12M(iClk12M), .iRsn(iRsn), .iCoeff(wCoeff31_40), .iFIRin(wDelay31_40), .iInSel(wInSel), .iEnDelay(wEnDelay), .oMac(wMac4));

    // 5. Sum
    MacFinalSum_Flex inst_FinalSum (
        .iClk_12M(iClk12M), .iRsn(iRsn), 
        .iEnDelay(wEnDelay), .iEnSample_600k(iEnSample600k),
        .iMac_1(wMac1), .iMac_2(wMac2), .iMac_3(wMac3), .iMac_4(wMac4),
        .oFirOut(oFirOut)
    );

endmodule

// ============================================================================
// MODULE: FSM_Top_Flex
// ============================================================================
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

  output wire                    oCsn_Mux_1,
  output wire                    oWrn_Mux_1,
  
  output wire                    oCsn_Mux_2,
  output wire                    oWrn_Mux_2,

  output wire                    oCsn_Mux_3,
  output wire                    oWrn_Mux_3,

  output wire                    oCsn_Mux_4,
  output wire                    oWrn_Mux_4,

  output wire [3:0]  oAddr_Mux
  );

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
    .oInSel(oInSel)
  );

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

 AccessMux_Flex inst_AccessMux_Flex_1 (
    .iUpdateFlag(iUpdateFlag),
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
    .iCsn(wCsn_2),
    .iWrn(wWrn_2),
    .iAddr(wAddr),
    .iCsn_Fsm(wCsn_Fsm_2),
    .iWrn_Fsm(wWrn_Fsm_2),
    .iAddr_Fsm(wAddr_Fsm),
    .oCsn_Mux(oCsn_Mux_2),
    .oWrn_Mux(oWrn_Mux_2),
    .oAddr_Mux()
 );

AccessMux_Flex inst_AccessMux_Flex_3 (
    .iUpdateFlag(iUpdateFlag),
    .iCsn(wCsn_3),
    .iWrn(wWrn_3),
    .iAddr(wAddr),
    .iCsn_Fsm(wCsn_Fsm_3),
    .iWrn_Fsm(wWrn_Fsm_3),
    .iAddr_Fsm(wAddr_Fsm),
    .oCsn_Mux(oCsn_Mux_3),
    .oWrn_Mux(oWrn_Mux_3),
    .oAddr_Mux()
 );

AccessMux_Flex inst_AccessMux_Flex_4 (
    .iUpdateFlag(iUpdateFlag),
    .iCsn(wCsn_4),
    .iWrn(wWrn_4),
    .iAddr(wAddr),
    .iCsn_Fsm(wCsn_Fsm_4),
    .iWrn_Fsm(wWrn_Fsm_4),
    .iAddr_Fsm(wAddr_Fsm),
    .oCsn_Mux(oCsn_Mux_4),
    .oWrn_Mux(oWrn_Mux_4),
    .oAddr_Mux()
 );

endmodule

// ============================================================================
// MODULE: Fsm_Flex
// ============================================================================
module Fsm_Flex (

  input                 iClk_12M,
  input                 iRsn,
  input                 iEnSample600k,
  input                 iUpdateFlag,

  output wire           oCsn_Fsm_1,
  output wire           oWrn_Fsm_1,
  
  output wire           oCsn_Fsm_2,
  output wire           oWrn_Fsm_2,
  
  output wire           oCsn_Fsm_3,
  output wire           oWrn_Fsm_3,
  
  output wire           oCsn_Fsm_4,
  output wire           oWrn_Fsm_4,
  
  output reg  [3:0]     oAddr_Fsm,
  output wire           oEnDelay, 
  output reg [3:0]      oInSel

  );

  parameter   p_Idle   = 2'b00,
              p_Update = 2'b01,
              p_MemRd  = 2'b10;

  reg    [1:0]     rCurState;
  reg    [1:0]     rNxtState;
  wire             wLastRd;

  always @(posedge iEnSample600k)
  begin
    if (!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[1:0];
  end

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

  assign oCsn_Fsm_1 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;
  assign oCsn_Fsm_2 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;
  assign oCsn_Fsm_3 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;
  assign oCsn_Fsm_4 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;
  
  assign oEnDelay = (iUpdateFlag == 0) ? iEnSample600k : 1'b0;

  assign oWrn_Fsm_1  = 1'b1;
  assign oWrn_Fsm_2  = 1'b1;
  assign oWrn_Fsm_3  = 1'b1;
  assign oWrn_Fsm_4  = 1'b1;
  
  always @(posedge iClk_12M)
  begin
    if (!iRsn)
    begin
      oAddr_Fsm <= 4'b0;
    end
    else if (oEnDelay)
    begin
      oAddr_Fsm <= 4'h0;
    end
    else if (oCsn_Fsm_1 == 1'b0 || oCsn_Fsm_2 == 1'b0 || oCsn_Fsm_3 == 1'b0 || oCsn_Fsm_4 == 1'b0 )
    begin
      if (oAddr_Fsm == 4'b1001)
        oAddr_Fsm <= oAddr_Fsm[3:0];
      else 
        oAddr_Fsm <= oAddr_Fsm[3:0] + 1'b1;
    end
  end

  always @(posedge iClk_12M)
  begin
    if (!iRsn)
      oInSel <= 4'h0;
    else if (oEnDelay == 1'b1)
      oInSel <= 4'h0;
    else
      oInSel <= oAddr_Fsm[3:0];
  end

endmodule

// ============================================================================
// MODULE: AddrDecoder_Flex
// ============================================================================
module AddrDecoder_Flex  (

    input       [5:0]           iAddr,
    input                       iCsn,
    input                       iWrn,

    output  wire [3:0]          oAddr,
    
    output  reg                 oCsn_1,
    output  reg                 oCsn_2,
    output  reg                 oCsn_3,
    output  reg                 oCsn_4,
    
    output  reg                 oWrn_1,
    output  reg                 oWrn_2,
    output  reg                 oWrn_3,
    output  reg                 oWrn_4

);

always @(*)
begin
    if(iCsn==1)
    begin
            oCsn_1 <= 1'b1;
            oCsn_2 <= 1'b1;
            oCsn_3 <= 1'b1;
            oCsn_4 <= 1'b1;

            oWrn_1 <= 1'b1;
            oWrn_2 <= 1'b1;
            oWrn_3 <= 1'b1;
            oWrn_4 <= 1'b1;      
    end
    else
    begin
        if(iWrn==1)
        begin
            oCsn_1 <= 1'b1;
            oCsn_2 <= 1'b1;
            oCsn_3 <= 1'b1;
            oCsn_4 <= 1'b1;

            oWrn_1 <= 1'b1;
            oWrn_2 <= 1'b1;
            oWrn_3 <= 1'b1;
            oWrn_4 <= 1'b1; 
        end
        else
        begin
            case (iAddr[5:4])
                2'b00 : begin
                    oCsn_1 <= 1'b0;
                    oCsn_2 <= 1'b1;
                    oCsn_3 <= 1'b1;
                    oCsn_4 <= 1'b1;

                    oWrn_1 <= 1'b0;
                    oWrn_2 <= 1'b1;
                    oWrn_3 <= 1'b1;
                    oWrn_4 <= 1'b1;
                end

                2'b01 : begin
                    oCsn_1 <= 1'b1;
                    oCsn_2 <= 1'b0;
                    oCsn_3 <= 1'b1;
                    oCsn_4 <= 1'b1;

                    oWrn_1 <= 1'b1;
                    oWrn_2 <= 1'b0;
                    oWrn_3 <= 1'b1;
                    oWrn_4 <= 1'b1;
                end

                2'b10 : begin
                    oCsn_1 <= 1'b1;
                    oCsn_2 <= 1'b1;
                    oCsn_3 <= 1'b0;
                    oCsn_4 <= 1'b1;

                    oWrn_1 <= 1'b1;
                    oWrn_2 <= 1'b1;
                    oWrn_3 <= 1'b0;
                    oWrn_4 <= 1'b1;
                end

                2'b11 : begin
                    oCsn_1 <= 1'b1;
                    oCsn_2 <= 1'b1;
                    oCsn_3 <= 1'b1;
                    oCsn_4 <= 1'b0;

                    oWrn_1 <= 1'b1;
                    oWrn_2 <= 1'b1;
                    oWrn_3 <= 1'b1;
                    oWrn_4 <= 1'b0;
                end
            endcase
        end
    end
end

assign oAddr = iAddr[3:0];
    
endmodule

// ============================================================================
// MODULE: AccessMux_Flex
// ============================================================================
module AccessMux_Flex (

  input            iUpdateFlag,
  input            iCsn,
  input            iWrn,
  input  [3:0]     iAddr,
  input            iCsn_Fsm,
  input            iWrn_Fsm,
  input  [3:0]     iAddr_Fsm,

  output            oCsn_Mux,
  output            oWrn_Mux,
  output  [3:0]     oAddr_Mux

  );

  assign oCsn_Mux  = (iUpdateFlag == 1'b1) ? iCsn : iCsn_Fsm;
  assign oWrn_Mux  = (iUpdateFlag == 1'b1) ? iWrn : iWrn_Fsm;
  assign oAddr_Mux = (iUpdateFlag == 1'b1) ? iAddr[3:0] : iAddr_Fsm[3:0];

endmodule

// ============================================================================
// MODULE: SpSram
// ============================================================================
module SpSram #(

  parameter SRAM_DEPTH = 10,
  parameter DATA_WIDTH = 16 ) (

  input                             iClk,
  input                             iRsn,
  input                             iCsn,
  input                             iWrn,
  input  [log_b2(SRAM_DEPTH-1)-1:0] iAddr,
  input  [DATA_WIDTH-1:0]           iWrDt,
  output [DATA_WIDTH-1:0]           oRdDt

  );

  integer          i;
  reg  [DATA_WIDTH-1:0] rMem[0:SRAM_DEPTH-1];
  reg  [DATA_WIDTH-1:0] rRdDt;

  function integer log_b2(input integer iDepth);
  begin
    log_b2 = 0;
    while (iDepth)
    begin
      log_b2 = log_b2  + 1;
      iDepth = iDepth >> 1;
    end
  end
  endfunction
  
  always @(posedge iClk)
  begin
    if (!iRsn)
    begin
      for (i=0 ; i<SRAM_DEPTH ; i=i+1)
      begin
        rMem[i] <= {DATA_WIDTH{1'b0}};
      end
    end
    else if (iCsn == 1'b0 && iWrn == 1'b0)
    begin
      rMem[iAddr] <= iWrDt[DATA_WIDTH-1:0];
    end
  end

  always @(posedge iClk)
  begin
    if (!iRsn)
    begin
      rRdDt <= {DATA_WIDTH{1'b0}};
    end
    else if (iCsn == 1'b0 && iWrn == 1'b1)
    begin
      rRdDt <= rMem[iAddr][DATA_WIDTH-1:0];
    end
  end

  assign oRdDt = rRdDt[DATA_WIDTH-1:0];

endmodule

// ============================================================================
// MODULE: DelayChainTop_Flex
// ============================================================================
module DelayChainTop_Flex (

  input                     iClk,
  input                     iRsn,
  
  input                     iEnDelay,
  input      [2:0]          iFirIn,
  input      [3:0]          iInSel,

  output wire [2:0]         oTap_Mux,
  output wire[2:0]          oChain
  );

  wire   [2:0]          wTap_0;
  wire   [2:0]          wTap_1;
  wire   [2:0]          wTap_2;
  wire   [2:0]          wTap_3;
  wire   [2:0]          wTap_4;
  wire   [2:0]          wTap_5;
  wire   [2:0]          wTap_6;
  wire   [2:0]          wTap_7;
  wire   [2:0]          wTap_8;
  wire   [2:0]          wTap_9;

  DelayChain_Flex inst_DelayChain (
    .iClk               (iClk),
    .iRsn               (iRsn),
    .iEnDelay           (iEnDelay),
    .iFirIn             (iFirIn),
    .oTap_0             (wTap_0),
    .oTap_1             (wTap_1),
    .oTap_2             (wTap_2),
    .oTap_3             (wTap_3),
    .oTap_4             (wTap_4),
    .oTap_5             (wTap_5),
    .oTap_6             (wTap_6),
    .oTap_7             (wTap_7),
    .oTap_8             (wTap_8),
    .oTap_9             (wTap_9),
    .oTap               (oChain)    
  );

  DelayMux_Flex inst_DelayMux (
    .iInSel             (iInSel),
    .iTap_0             (wTap_0),
    .iTap_1             (wTap_1),
    .iTap_2             (wTap_2),
    .iTap_3             (wTap_3),
    .iTap_4             (wTap_4),
    .iTap_5             (wTap_5),
    .iTap_6             (wTap_6),
    .iTap_7             (wTap_7),
    .iTap_8             (wTap_8),
    .iTap_9             (wTap_9),
    .oTap_Mux           (oTap_Mux)
  );

endmodule

// ============================================================================
// MODULE: DelayChain_Flex
// ============================================================================
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

// ============================================================================
// MODULE: DelayMux_Flex
// ============================================================================
module DelayMux_Flex (

  input   [3:0]    iInSel,
  input   [2:0]    iTap_0,
  input   [2:0]    iTap_1,
  input   [2:0]    iTap_2,
  input   [2:0]    iTap_3,
  input   [2:0]    iTap_4,
  input   [2:0]    iTap_5,
  input   [2:0]    iTap_6,
  input   [2:0]    iTap_7,
  input   [2:0]    iTap_8,
  input   [2:0]    iTap_9,
  output  [2:0]    oTap_Mux
  );

 assign oTap_Mux = (iInSel == 4'd0) ? iTap_0 :
                  (iInSel == 4'd1) ? iTap_1 :
                  (iInSel == 4'd2) ? iTap_2 :
                  (iInSel == 4'd3) ? iTap_3 :
                  (iInSel == 4'd4) ? iTap_4 :
                  (iInSel == 4'd5) ? iTap_5 :
                  (iInSel == 4'd6) ? iTap_6 :
                  (iInSel == 4'd7) ? iTap_7 :
                  (iInSel == 4'd8) ? iTap_8 :
                  (iInSel == 4'd9) ? iTap_9 :
                  3'b000;

endmodule

// ============================================================================
// MODULE: MACTop_Flex
// ============================================================================
module MACTop_Flex (

  input                iClk_12M,
  input                iRsn,
  input  [15:0]        iCoeff,
  input  [2:0]         iFIRin,
  input  [3:0]         iInSel,
  input                iEnDelay,

  output wire [15:0]    oMac

  );

  wire   [15:0]        wMulOut;
  wire   [3:0]         wInSel;

  Multiplier_16x3_Flex inst_Multiplier_16x3 (
    .iClk_12M           (iClk_12M),
    .iRsn               (iRsn),
    .ia                 (iCoeff),
    .ib                 (iFIRin),
    .iInSel             (iInSel[3:0]),
    .oInSel             (wInSel[3:0]),
    .oMulOut            (wMulOut[15:0]) 
  );

  Accumulator_Flex inst_Accumulator (
    .iClk               (iClk_12M),
    .iRsn               (iRsn),
    .iRdDt              (wMulOut[15:0]),
    .iInSel             (wInSel[3:0]),
    .iEnDelay           (iEnDelay),
    .oAccOut            (oMac)
  );

endmodule

// ============================================================================
// MODULE: Multiplier_16x3_Flex
// ============================================================================
module  Multiplier_16x3_Flex (
    input                        iClk_12M,
    input                        iRsn,
    input       [3:0]            iInSel,   
    input       [15:0]           ia,
    input       [2:0]            ib,

    output reg  [15:0]           oMulOut,
    output reg  [3:0]            oInSel

);

wire              [15:0]         abs_a; 
wire              [2:0]          abs_b;
wire                             sBitSum;    

assign  abs_a = (ia[15]==1) ? ~ia + 1'b1 : ia;
assign  abs_b = (ib[2]==1) ? ~ib + 1'b1 : ib;
assign  sBitSum = (ia[15]==ib[2]) ? 1'b0 : 1'b1;

wire    signed    [15:0]         partial_0 = abs_b[0] ? abs_a : 16'b0 ;
wire    signed    [16:0]         partial_1 = abs_b[1] ? (abs_a << 1) : 17'b0;
wire    signed    [17:0]         partial_2 = abs_b[2] ? (abs_a << 2) : 18'b0;  
wire    signed    [18:0]         wSum = partial_0 + partial_1 + partial_2;

wire                             wSatCon;
wire     signed    [15:0]        wSatSum;

assign wSatCon =  (wSum >= 18'b00_0111_1111_1111_1111) ? 1'b1 : 1'b0;

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

// ============================================================================
// MODULE: Accumulator_Flex
// ============================================================================
module Accumulator_Flex (

  input                 iClk,
  input                 iRsn,
  input       [15:0]    iRdDt,
  input       [3:0]     iInSel,
  input                 iEnDelay,

  output reg  [15:0]    oAccOut

  );

  wire   [15:0]         wAccInA;
  wire   [15:0]         wAccInB;
  wire signed  [20:0]   wAccSum;

  wire                  wSatCon_1;
  wire                  wSatCon_2;
  wire   [15:0]         wAccSumSat;

  reg    [15:0]         rAccDt;

  assign wAccInA = (iInSel == 4'b0000) ? 16'h0 : rAccDt[15:0];
  assign wAccInB = iRdDt[15:0];

  assign wAccSum = {{5{wAccInA[15]}}, wAccInA[15:0]} + {{5{wAccInB[15]}}, wAccInB[15:0]};

  assign wSatCon_1 =  (iInSel==4'b1001) ? (( wAccSum > 20'sb0000_0111_1111_1111_1111 ) ?  1'b1 : 1'b0) : 1'b0;
  assign wSatCon_2 =  (iInSel==4'b1001) ? (( wAccSum < 20'sb1111_1000_0000_0000_0000 ) ?  1'b1 : 1'b0) : 1'b0;

  assign wAccSumSat = (wSatCon_1 == 1'b1) ? 16'h7FFF :
                      (wSatCon_2 == 1'b1) ? 16'h8000 : wAccSum[15:0];

  always @(posedge iClk)
  begin
    if (!iRsn)
      rAccDt <= 16'h0;
    else if (iInSel[3:0] != 4'b1001)
      rAccDt <= wAccSumSat[15:0];
  end

  always @(posedge iClk)
  begin
    if (!iRsn)
      oAccOut <= 16'h0;
    else if (iInSel[3:0]==4'b1001)
      oAccOut <= wAccSumSat[15:0];
  end

endmodule

// ============================================================================
// MODULE: MacFinalSum_Flex
// ============================================================================
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

assign wSatCon_1 =  (wMacSum >= 18'sb00_0111_1111_1111_1111) ? 1'b1 : 1'b0;
assign wSatCon_2 =  (wMacSum <= 18'sb11_1000_0000_0000_0000) ? 1'b1 : 1'b0;

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

