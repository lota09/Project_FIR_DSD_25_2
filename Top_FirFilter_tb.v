`timescale 1ns/10ps

module Top_FirFilter_tb;

    // === 1. 로봇의 손 (입력 신호: reg) ===
    // 칩에 신호를 '넣어줘야' 하므로 값을 저장할 수 있는 reg를 씁니다.
    reg iClk12M;
    reg iRsn;
    reg iEnSample600k;
    reg iCoeffUpdateFlag; // (다이어그램 이름 반영)

    reg iCsnRam;
    reg iWrnRam;
    reg [5:0]  iAddrRam;
    reg [15:0] iWrDtRam;

    reg [2:0]  iFirIn;

    // === 2. 로봇의 눈 (출력 신호: wire) ===
    // 칩에서 나오는 신호를 '지켜봐야' 하므로 전선인 wire를 씁니다.
    wire [15:0] oFirOut;

    // === 3. 정답지 및 테스트 변수 ===
    integer i; // 반복문용 변수
    reg [15:0] answer_sheet [0:63]; // 내가 쓴 계수를 기억해둘 공책

    // === 4. 칩(DUT) 가져와서 연결하기 ===
    Top_FirFilter_Flex u_DUT (
        .iClk12M(iClk12M), 
        .iRsn(iRsn), 
        .iEnSample600k(iEnSample600k), 
        .iCoeffUpdateFlag(iCoeffUpdateFlag),

        .iCsnRam(iCsnRam), 
        .iWrnRam(iWrnRam), 
        .iAddrRam(iAddrRam), 
        .iWrDtRam(iWrDtRam),

        .iFirIn(iFirIn), 
        .oFirOut(oFirOut)
    );

    // === 5. 심장 박동(Clock) 만들기 ===
    // 12MHz = 83.33ns 주기 -> 절반인 41.67ns마다 뒤집기
    initial iClk12M = 0;
    always #41.67 iClk12M = ~iClk12M;

    // === 6. 600kHz 타이밍 신호 만들기 ===
    // 12MHz / 600kHz = 20. 즉, 20박자마다 한 번씩 신호를 줍니다.
    reg [4:0] cnt;
    always @(posedge iClk12M) begin
        if(!iRsn) begin 
            cnt <= 0; iEnSample600k <= 0; 
        end
        else begin
            if(cnt == 19) begin 
                cnt <= 0; iEnSample600k <= 1; // 20번째 박자에서 '톡'하고 칩니다.
            end
            else begin 
                cnt <= cnt + 1; iEnSample600k <= 0; 
            end
        end
    end

    // === 7. 테스트 시나리오 (여기가 진짜!) ===
    initial begin
        // (1) 초기화 (Reset)
        iRsn = 0; 
        iCoeffUpdateFlag = 0;
        iAddrRam = 0; iCsnRam = 1; iWrnRam = 1; iWrDtRam = 0; 
        iFirIn = 0;
        
        repeat(5) @(posedge iClk12M); // 5박자 대기
        iRsn = 1; // 리셋 해제 (전원 ON!)
        repeat(5) @(posedge iClk12M);

       // ============================================================
        // (2) 계수 쓰기 (Write Mode) - 진짜 필터 계수 입력!
        // ============================================================
        $display("=== [Step 1] Writing REAL Coefficients (Kaiser Window) ===");
        iCoeffUpdateFlag = 1; 

        for(i=0; i<40; i=i+1) begin
            // 1. 진짜 계수 값 설정 (문서의 소수점 값을 16비트 정수로 변환한 값)
            // 필터의 중심(Center)에서 값이 제일 크고, 양옆으로 물결치는 형태입니다.
            case(i)
                0:  answer_sheet[i] = 16'd146;   // 0.00446...
                1:  answer_sheet[i] = 16'd0;     // -0.0000...
                2:  answer_sheet[i] = -16'd242;  // -0.00739... (음수는 2의 보수로 들어감)
                3:  answer_sheet[i] = 16'd302;   // 0.00928...
                4:  answer_sheet[i] = 16'd0;
                5:  answer_sheet[i] = -16'd463;
                6:  answer_sheet[i] = 16'd567;
                7:  answer_sheet[i] = 16'd0;
                8:  answer_sheet[i] = -16'd844;
                9:  answer_sheet[i] = 16'd1034;
                // --- 10번 인덱스부터 RAM2 ---
                10: answer_sheet[i] = 16'd0;
                11: answer_sheet[i] = -16'd1616;
                12: answer_sheet[i] = 16'd2104;
                13: answer_sheet[i] = 16'd0;
                14: answer_sheet[i] = -16'd4438;
                15: answer_sheet[i] = 16'd8993;  
                16: answer_sheet[i] = 16'd21845; // Center Peak! (가장 큰 값)
                17: answer_sheet[i] = 16'd8993;  // 대칭 시작
                18: answer_sheet[i] = -16'd4438;
                19: answer_sheet[i] = 16'd0;
                // --- 20번 인덱스부터 RAM3 ---
                20: answer_sheet[i] = 16'd2104;
                21: answer_sheet[i] = -16'd1616;
                22: answer_sheet[i] = 16'd0;
                23: answer_sheet[i] = 16'd1034;
                24: answer_sheet[i] = -16'd844;
                25: answer_sheet[i] = 16'd0;
                26: answer_sheet[i] = 16'd567;
                27: answer_sheet[i] = -16'd463;
                28: answer_sheet[i] = 16'd0;
                29: answer_sheet[i] = 16'd302;
                // --- 30번 인덱스부터 RAM4 ---
                30: answer_sheet[i] = -16'd242;
                31: answer_sheet[i] = 16'd0;
                32: answer_sheet[i] = 16'd146;
                default: answer_sheet[i] = 16'd0; // 나머지는 0으로 채움
            endcase

            @(negedge iClk12M);
            
            // [주소 매핑 보정] 아까 해결했던 그 로직 그대로!
            if (i < 10)      iAddrRam = i;           
            else if (i < 20) iAddrRam = i + 6;       
            else if (i < 30) iAddrRam = i + 12;      
            else             iAddrRam = i + 18;      

            iWrDtRam = answer_sheet[i];
            iCsnRam = 0; iWrnRam = 0;  
            @(negedge iClk12M);
            iCsnRam = 1; iWrnRam = 1;  
        end
        repeat(10) @(posedge iClk12M);

//         // (3) 필터 동작 (Run Mode)
//         $display("=== [Step 2] Running Filter (Input Impulse) ===");
//         iCoeffUpdateFlag = 0; // "동작해" 모드 설정

//         // 600kHz 타이밍이 올 때까지 기다림 (박자 맞추기)
//         wait(iEnSample600k); 
//         @(negedge iClk12M);
        
//         // 입력 Impulse '1' (3'b001) 투입!
//         iFirIn = 3'b001; 
        
//         // 다음 박자에 바로 입력 끔 (Impulse는 순간적인 충격이니까)
//         @(negedge iClk12M); 
//         wait(!iEnSample600k); // 타이밍 신호가 꺼질 때까지 대기
//         iFirIn = 3'b000;

//         // (4) 결과 채점 (Check)
//         // 입력이 1이니까, 출력은 계수값(1, 2, 3...)이 순서대로 나와야 정답!
//         for(i=0; i<40; i=i+1) begin
            
//             // [핵심] 칩 내부의 "계산 시작 신호(oEnDelay)"를 훔쳐봅니다.
//             // 이게 1이 됐다는 건 계산 준비가 됐다는 뜻!
//             wait(u_DUT.inst_FSM_Top.oEnDelay == 1); 
            
//             // 계산이 끝나고 데이터가 나올 때까지 2박자 정도 여유를 줍니다.
//             repeat(2) @(posedge iClk12M); 

//             // 값 비교
//             if(oFirOut == answer_sheet[i]) begin
//                 $display("[PASS] Index %0d: Output = %d", i, oFirOut);
//             end else begin
//                 $display("[FAIL] Index %0d: Output = %d (Expected: %d)", i, oFirOut, answer_sheet[i]);
//             end

//             // 이번 출력이 끝날 때까지(신호가 꺼질 때까지) 기다림
//             wait(u_DUT.inst_FSM_Top.oEnDelay == 0);
//         end

//         $display("=== Test Finished ===");
//         $stop; // 시뮬레이션 종료
//     end

// endmodule

// ... (앞부분: 초기화 및 계수 쓰기는 기존과 동일하게 유지) ...

        // ============================================================
        // (3) 필터 동작 (Run Mode) - [수정됨] 랜덤 심볼 입력 테스트!
        // ============================================================
        $display("=== [Step 2] Running Filter with Random Symbols ===");
        iCoeffUpdateFlag = 0; // 동작 모드

        // 4가지 심볼 정의 (Source 44 참조)
        // 0: +1 (001), 1: +3 (011), 2: -1 (111), 3: -3 (101)
        // (Verilog에서 배열로 미리 만들어두지 않고 case문으로 처리하겠습니다)
        
        // 500개의 랜덤 데이터를 연속으로 넣어봅시다!
        for(i=0; i<500; i=i+1) begin
            
            // 1. 타이밍 기다리기 (600kHz)
            wait(iEnSample600k); 
            @(negedge iClk12M);

            // 2. 랜덤 심볼 생성 ($urandom 사용)
            // 0~3 사이의 난수를 뽑아서 그에 맞는 심볼을 입력
            case($urandom % 4)
                0: iFirIn = 3'b001; // +1
                1: iFirIn = 3'b011; // +3
                2: iFirIn = 3'b111; // -1
                3: iFirIn = 3'b101; // -3
            endcase

            // 3. 입력 유지 및 제거
            @(negedge iClk12M); 
            
            // (옵션) 펄스 형태로 주고 싶으면 여기서 0으로 끄고, 
            // 꽉 찬 데이터를 주고 싶으면 끄지 않고 다음 데이터가 올 때까지 유지합니다.
            // 보통 통신 테스트에선 0으로 끄지 않고 유지하기도 하지만,
            // 앞선 Impulse 테스트와 조건을 맞추기 위해 여기선 한 클럭 뒤에 끄겠습니다.
            wait(!iEnSample600k);
            iFirIn = 3'b000; // 0으로 복귀 (Impulse Train 형태)
            
            // *만약 파형이 너무 듬성듬성하다면 위 iFirIn = 0; 줄을 주석 처리해보세요.
        end

        $display("=== Random Test Finished ===");
        $stop;
    end
endmodule
