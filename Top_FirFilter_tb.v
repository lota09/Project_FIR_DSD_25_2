`timescale 1ns/10ps

module Top_FirFilter_tb;

    //===========================
    // 1. DUT 입·출력 신호
    //===========================
    reg         iClk12M;
    reg         iRsn;

    reg         iEnSample600k;      // 600 kHz 샘플 구동 펄스
    reg         iCoeffUpdateFlag;   // 1: 계수 업데이트, 0: 필터 동작

    reg         iCsnRam;
    reg         iWrnRam;
    reg  [5:0]  iAddrRam;
    reg  signed [15:0] iWrDtRam;

    reg  [2:0]  iFirIn;
    wire [15:0] oFirOut;

    //===========================
    // DUT
    //===========================
    Top_FirFilter_Flex u_DUT (
        .iClk12M          (iClk12M),
        .iRsn             (iRsn),
        .iEnSample600k    (iEnSample600k),
        .iCoeffUpdateFlag (iCoeffUpdateFlag),

        .iCsnRam          (iCsnRam),
        .iWrnRam          (iWrnRam),
        .iAddrRam         (iAddrRam),
        .iWrDtRam         (iWrDtRam),

        .iFirIn           (iFirIn),
        .oFirOut          (oFirOut)
    );

    //===========================
    // 2. 12 MHz clock
    //===========================
    initial iClk12M = 1'b0;
    always #41.67 iClk12M = ~iClk12M;   // 83.33ns period → 12 MHz

    //===========================
    // 3. 600 kHz Enable (20 clk 마다 1펄스)
    //===========================
    reg [4:0] rSampleCnt;

    always @(posedge iClk12M) begin
        if (!iRsn) begin
            rSampleCnt    <= 5'd0;
            iEnSample600k <= 1'b0;
        end
        else begin
            if (rSampleCnt == 5'd19) begin
                rSampleCnt    <= 5'd0;
                iEnSample600k <= 1'b1;   // one-shot pulse
            end
            else begin
                rSampleCnt    <= rSampleCnt + 1'b1;
                iEnSample600k <= 1'b0;
            end
        end
    end

    //===========================
    // 4. 계수 테이블 (33-tap Kaiser)
    //===========================
    localparam NUM_TAPS = 33;   // Kaiser window 33 taps
    integer k;
    reg signed [15:0] coeff [0:NUM_TAPS-1];

    initial begin
        coeff[0]  =  16'sd3;
        coeff[1]  =  16'sd0;
        coeff[2]  = -16'sd6;
        coeff[3]  =  16'sd7;
        coeff[4]  =  16'sd0;
        coeff[5]  = -16'sd11;
        coeff[6]  =  16'sd13;
        coeff[7]  =  16'sd0;
        coeff[8]  = -16'sd19;
        coeff[9]  =  16'sd24;
        coeff[10] =  16'sd0;
        coeff[11] = -16'sd37;
        coeff[12] =  16'sd48;
        coeff[13] =  16'sd0;
        coeff[14] = -16'sd102;
        coeff[15] =  16'sd206;

        coeff[16] =  16'sd500;   // 중심 tap

        coeff[17] =  16'sd206;
        coeff[18] = -16'sd102;
        coeff[19] =  16'sd0;
        coeff[20] =  16'sd48;
        coeff[21] = -16'sd37;
        coeff[22] =  16'sd0;
        coeff[23] =  16'sd24;
        coeff[24] = -16'sd19;
        coeff[25] =  16'sd0;
        coeff[26] =  16'sd13;
        coeff[27] = -16'sd11;
        coeff[28] =  16'sd0;
        coeff[29] =  16'sd7;
        coeff[30] = -16'sd6;
        coeff[31] =  16'sd0;
        coeff[32] =  16'sd3;
    end

    //===========================
    // 5. Transcript용 모니터
    //===========================
    always @(iAddrRam or iWrDtRam or iCsnRam or iWrnRam) begin
        if (!iCsnRam && !iWrnRam) begin
            $display("SPSRAM : %0d, Address : %0d, Data : %0d",
                     iAddrRam[5:4], iAddrRam[3:0], $signed(iWrDtRam));
        end
    end

    initial begin
        $monitor($realtime, " ns, oFirOut = %0d", $signed(oFirOut));
    end

    //===========================
    // 6. 메인 시나리오
    //===========================
    initial begin
        // (1) Reset
        iRsn             = 1'b0;
        iCoeffUpdateFlag = 1'b0;

        iCsnRam   = 1'b1;
        iWrnRam   = 1'b1;
        iAddrRam  = 6'd0;
        iWrDtRam  = 16'sd0;
        iFirIn    = 3'b000;

        repeat (5) @(posedge iClk12M);
        iRsn = 1'b1;
        repeat (5) @(posedge iClk12M);

        //--------------------------------------
        // (2) Coefficient Update Phase
        //--------------------------------------
        $display("--------------------------------------------------");
        $display("********* SPSRAM Data Update Start !! ************");
        $display("--------------------------------------------------");

        iCoeffUpdateFlag = 1'b1;   // coefficient update phase 진입

        // FSM이 p_Update 상태로 진입할 수 있도록 몇 클럭 대기
        repeat (25) @(posedge iClk12M);  // 600kHz 펄스 1회 발생 보장

        // 다이어그램처럼, SPSRAM Write 구간 전체에서
        // wCsnRam1, wWmRam1를 연속으로 Low 로 유지
        @(negedge iClk12M);      // 시작 위치를 한 클럭 경계에 맞춤
        iCsnRam = 1'b0;
        iWrnRam = 1'b0;

        for (k = 0; k < NUM_TAPS; k = k + 1) begin
            if (k == 0 ) $display("*** SPSRAM #0 Update ***");
            if (k == 10) $display("*** SPSRAM #1 Update ***");
            if (k == 20) $display("*** SPSRAM #2 Update ***");
            if (k == 30) $display("*** SPSRAM #3 Update ***");

            // bank / local address 매핑
            if      (k < 10)  iAddrRam = 6'd0  + k;        // bank0: addr[3:0] = 0~9
            else if (k < 20)  iAddrRam = 6'd16 + (k-10);   // bank1: addr[3:0] = 0~9
            else if (k < 30)  iAddrRam = 6'd32 + (k-20);   // bank2: addr[3:0] = 0~9
            else              iAddrRam = 6'd48 + (k-30);   // bank3: addr[3:0] = 0~9

            iWrDtRam = coeff[k];

            // 주소/데이터를 네거티브 엣지에 바꾸고,
            // 포지티브 엣지에서 SPSRAM이 write 하도록 구성
            @(posedge iClk12M);
        end

        // 마지막 write 이후 한 클럭 더 지나고 High 로 복귀
        @(negedge iClk12M);
        iCsnRam = 1'b1;
        iWrnRam = 1'b1;

        $display("--------------------------------------------------");
        $display("********* SPSRAM Data Update Finish !! ***********");
        $display("--------------------------------------------------");

        //--------------------------------------
        //--------------------------------------
        // (3) FIR operation phase
        //--------------------------------------
        iCoeffUpdateFlag = 1'b0;   // FirFilter operation phase 진입

        $display("=== [Step 2] Running Filter with Random 4-PAM Symbols ===");
        // 4-PAM 랜덤 심볼 200개, 3× oversampling
        for (k = 0; k < 200; k = k + 1) begin
            @(posedge iEnSample600k);
            case ($urandom % 4)
                0: iFirIn = 3'b001; // +1
                1: iFirIn = 3'b011; // +3
                2: iFirIn = 3'b111; // -1
                3: iFirIn = 3'b101; // -3
            endcase

            @(posedge iEnSample600k); iFirIn = 3'b000;
            @(posedge iEnSample600k); iFirIn = 3'b000;
        end

        $display("=== Random Test Finished ===");
        #1000;
        $stop;
    end

endmodule
