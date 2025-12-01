/*******************************************************************
  - Project          : 2025 Team Project Flex
  - Module Name      : Top_FirFilter_Flex.v
  - Description      : 블록 다이어그램 Wire Name 100% 매칭 버전
*******************************************************************/

`timescale 1ns/10ps

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