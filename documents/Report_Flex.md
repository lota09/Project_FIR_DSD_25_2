# Reconfigurable FIR Filter 설계 및 구현 보고서

---

**팀명**: Flex  
**작성일**: 2025년 12월 1일  
**프로젝트**: Reconfigurable FIR Filter

---

## 1. 개요

### 1.1 프로젝트 목표

본 프로젝트의 목표는 디지털 통신 시스템에서 사용되는 40-tap FIR(Finite Impulse Response) 필터를 Verilog HDL로 설계하고 검증하는 것이다. 특히, 제한된 하드웨어 리소스를 효율적으로 활용하기 위해 Time-Multiplexing과 Spatial-Multiplexing을 결합한 하이브리드 아키텍처를 구현하였다.

### 1.2 핵심 요구사항

#### 1.2.1 필터 사양
- **Tap 수**: 40-tap (Kaiser Window 적용)
- **샘플링 주파수**: 600kHz
- **심볼 레이트**: 200kHz (3× oversampling)
- **시스템 클럭**: 12MHz
- **대역폭**: 400kHz

#### 1.2.2 입출력 신호
- **입력 신호**: `iFirIn[2:0]` - 3-bit signed 입력 (4-PAM: -3, -1, +1, +3)
- **출력 신호**: `oFirOut[15:0]` - 16-bit signed 출력 (saturation 적용)

#### 1.2.3 필터 계수
- Kaiser Window 기반 Raised-Cosine 계수 40개
- 계수 범위: -16'd4438 ~ +16'd21845 (16-bit signed)
- 중심 대칭 구조 (h[0]=h[39], h[1]=h[38], ...)

#### 1.2.4 성능 요구사항
- **처리 시간**: 600kHz 샘플링 주기(1.667μs) 내 40번 MAC 연산 완료
- **리소스 효율**: 4개 MAC 유닛 × 10회 Time-Multiplexing = 40번 연산
- **메모리 구조**: 4개 SP-SRAM (각 10개 계수 저장)

#### 1.2.5 Reconfigurable 기능
- 동적 계수 업데이트 기능 (`iCoeffUpdateFlag` 신호)
- 외부에서 SRAM 직접 접근 가능
- Update 모드와 Filter 모드 간 전환 가능

#### 1.2.6 타이밍 제약
- **샘플링 주기**: 1.667μs (600kHz)
- **가용 클럭**: 20 clocks @ 12MHz
- **MAC 연산 시간**: 각 MAC당 10 clocks (4개 병렬 = 총 40 연산)

---

## 2. 프로젝트 진행 계획 및 역할 분담

### 2.1 진행 계획

(추후 추가 예정)

### 2.2 역할 분담

본 프로젝트는 3명의 팀원(A, B, C)이 다음과 같이 역할을 분담하여 진행하였다.

| 팀원 | 담당 업무 | 세부 내용 |
|------|----------|----------|
| **A** | FSM 설계 | - FSM_Flex.v 설계 및 구현<br>- FSM_Top_Flex.v 통합<br>- 상태 전환 로직 설계<br>- 제어 신호 생성 (oEnDelay, oInSel, oCsn, oWrn, oAddr) |
| **B** | Peripheral 설계 | - Delay Chain (DelayChain_Flex.v, DelayMux_Flex.v)<br>- MAC 유닛 (Multiplier_16x3_Flex.v, Accumulator_Flex.v)<br>- SRAM 인터페이스 (SpSRAM_Flex.v, AccessMux_Flex.v, AddrDecoder_Flex.v)<br>- Final Sum (MacFinalSum_Flex.v)<br>- Top-level 통합 (Top_FirFilter_Flex.v) |
| **C** | Testbench 설계 | - Top_FirFilter_tb.v 작성<br>- 계수 검증 시나리오 작성<br>- 랜덤 입력 테스트 구현<br>- 파형 분석 및 검증 |

### 2.3 역할 분담 이유

본 프로젝트에서 회로 설계 담당자(A, B)와 테스트벤치 설계 담당자(C)를 명확히 분리한 이유는 **검증력 향상**에 있다. 

- **독립적 검증**: 회로 설계자가 아닌 제3자가 테스트벤치를 작성함으로써, 설계자의 선입견이나 암묵적 가정이 배제된 객관적 검증이 가능하다.

- **다각적 분석**: 테스트벤치 설계자는 회로 동작을 외부 관점에서 분석하므로, 설계 단계에서 간과할 수 있는 엣지 케이스나 타이밍 이슈를 발견할 가능성이 높다.

- **교차 검증**: 설계 의도와 실제 구현이 일치하는지 확인하는 과정에서, 요구사항에 대한 상호 이해도를 높이고 설계 오류를 조기에 발견할 수 있다.

특히 FSM 설계(A)와 Peripheral 설계(B)를 분리한 것은 제어 로직과 데이터패스를 독립적으로 구현하여 모듈화를 극대화하기 위함이다. 이를 통해 각 모듈의 단위 테스트가 용이하며, 인터페이스가 명확해져 통합 과정에서의 오류를 최소화할 수 있다.

---

## 3. 회로 설계

### 3.1 전체 시스템 구조

40-tap FIR 필터는 다음과 같은 계층 구조로 설계되었다.

```
Top_FirFilter_Flex (최상위)
├── FSM_Top_Flex (제어부)
│   ├── FSM_Flex (상태 머신)
│   ├── AddrDecoder_Flex (SRAM 선택)
│   └── AccessMux_Flex (외부/내부 접근 선택)
├── SpSRAM_Flex × 4 (계수 저장)
├── DelayChainTop_Flex × 4 (샘플 저장)
│   ├── DelayChain_Flex (10-tap 지연선)
│   └── DelayMux_Flex (Tap 선택)
├── MacTop_Flex × 4 (MAC 연산)
│   ├── Multiplier_16x3_Flex (승산)
│   └── Accumulator_Flex (누산)
└── MacFinalSum_Flex (최종 합산)
```

#### 3.1.1 아키텍처 핵심 개념

**Spatial-Multiplexing (공간 병렬화)**
- 4개의 MAC 유닛을 병렬로 배치
- 각 MAC은 동시에 서로 다른 계수×샘플 곱셈 수행
- 4개 SRAM 동시 접근으로 대역폭 4배 증가

**Time-Multiplexing (시간 재사용)**
- 각 MAC 유닛을 10회 반복 사용
- 12MHz 클럭으로 주소 카운터(0~9) 순차 증가
- 600kHz 샘플링 주기(20 clocks) 내 10회 연산 완료

**하이브리드 구조**
- 4개 MAC × 10회 = 40번 연산
- 물리적 MAC 유닛: 4개 (리소스 효율 10배)
- 연산 시간: 10 clocks (20 clocks 중 50% 사용, 타이밍 여유 확보)

### 3.2 FSM_Top_Flex (제어부 통합)

#### 3.2.1 모듈 포트 정의

```verilog
module FSM_Top_Flex (
    // Clock & Reset
    input  wire        iClk_12M,
    input  wire        iRsn,
    
    // Control Inputs
    input  wire        iEnSample600k,
    input  wire        iUpdateFlag,
    
    // External SRAM Access
    input  wire        iCsn,
    input  wire        iWrn,
    input  wire [5:0]  iAddr,
    input  wire [15:0] iWrDt,
    
    // SRAM Outputs (4개)
    output wire        oCsn_1, oCsn_2, oCsn_3, oCsn_4,
    output wire        oWrn_1, oWrn_2, oWrn_3, oWrn_4,
    output wire [3:0]  oAddr_1, oAddr_2, oAddr_3, oAddr_4,
    output wire [15:0] oWrDt_1, oWrDt_2, oWrDt_3, oWrDt_4,
    
    // MAC Control Outputs
    output wire        oEnDelay,
    output wire [3:0]  oInSel
);
```

#### 3.2.2 신호 설명

| 신호명 | 방향 | 비트 | 설명 |
|--------|------|------|------|
| `iClk_12M` | 입력 | 1 | 시스템 클럭 (12MHz) |
| `iRsn` | 입력 | 1 | 동기 리셋 (active-low) |
| `iEnSample600k` | 입력 | 1 | 600kHz 샘플링 enable 신호 (1 cycle pulse) |
| `iUpdateFlag` | 입력 | 1 | 모드 선택 (1=Update, 0=Filter) |
| `iCsn` | 입력 | 1 | 외부 SRAM Chip Select (active-low) |
| `iWrn` | 입력 | 1 | 외부 SRAM Write Enable (0=Write, 1=Read) |
| `iAddr[5:0]` | 입력 | 6 | 외부 SRAM 주소 ([5:4]=Bank 선택, [3:0]=내부 주소) |
| `iWrDt[15:0]` | 입력 | 16 | 외부 SRAM 쓰기 데이터 |
| `oCsn_1~4` | 출력 | 1×4 | 각 SRAM Chip Select |
| `oWrn_1~4` | 출력 | 1×4 | 각 SRAM Write Enable |
| `oAddr_1~4[3:0]` | 출력 | 4×4 | 각 SRAM 주소 (0~9) |
| `oWrDt_1~4[15:0]` | 출력 | 16×4 | 각 SRAM 쓰기 데이터 |
| `oEnDelay` | 출력 | 1 | Delay Chain shift enable (1 cycle pulse) |
| `oInSel[3:0]` | 출력 | 4 | Accumulator 제어 (0~9: 누산, 10: 출력) |

#### 3.2.3 내부 구조

FSM_Top_Flex는 3개의 서브모듈로 구성된다.

**1) FSM_Flex (상태 머신)**
- 3개 상태: IDLE, Update, MemRd
- `iEnSample600k` 에지에서 상태 전환
- 제어 신호 생성: `oEnDelay`, `oInSel`, `oCsn_Fsm`, `oWrn_Fsm`, `oAddr_Fsm`

**2) AddrDecoder_Flex (SRAM 선택)**
- 입력: `iAddr[5:4]` (2-bit Bank 선택)
- 출력: `oCsn_1~4` (4개 중 1개만 active)
- 디코딩:
  - `iAddr[5:4]=00` → SRAM1 선택
  - `iAddr[5:4]=01` → SRAM2 선택
  - `iAddr[5:4]=10` → SRAM3 선택
  - `iAddr[5:4]=11` → SRAM4 선택

**3) AccessMux_Flex (접근 경로 선택)**
- `iUpdateFlag=1`: 외부 신호를 SRAM에 연결 (계수 업데이트)
- `iUpdateFlag=0`: FSM 신호를 SRAM에 연결 (필터 동작)

#### 3.2.4 동작 원리

**Update 모드 (`iUpdateFlag=1`)**
```
외부 신호 → AccessMux → AddrDecoder → SRAM[Bank]
iAddr[5:4]로 Bank 선택, iAddr[3:0]로 내부 주소 지정
```

**Filter 모드 (`iUpdateFlag=0`)**
```
FSM → AccessMux → 4개 SRAM 모두 동시 활성화
oAddr_Fsm (0~9) 증가 → 4개 SRAM에서 동시 읽기
```

(신호 관찰 파형 - 추후 첨부 예정)

### 3.3 FSM_Flex (유한 상태 머신)

#### 3.3.1 모듈 포트 정의

```verilog
module Fsm_Flex (
    input         iClk_12M,
    input         iRsn,
    input         iEnSample600k,
    input         iUpdateFlag,
    
    output wire   oCsn_Fsm_1, oCsn_Fsm_2, oCsn_Fsm_3, oCsn_Fsm_4,
    output wire   oWrn_Fsm_1, oWrn_Fsm_2, oWrn_Fsm_3, oWrn_Fsm_4,
    output reg [3:0] oAddr_Fsm,
    
    output wire   oEnDelay,
    output reg [3:0] oInSel
);
```

#### 3.3.2 상태 정의

```verilog
parameter p_Idle   = 2'b00,  // 대기 상태
          p_Update = 2'b01,  // 계수 업데이트 상태
          p_MemRd  = 2'b10;  // SRAM 읽기 상태
```

#### 3.3.3 상태 전이도

(상태 전이도 그림 - 추후 첨부 예정)

#### 3.3.4 상태별 동작

**IDLE 상태**
- 초기 상태 (Reset 후)
- `iUpdateFlag=1` 입력 시 Update 상태로 전환
- `iUpdateFlag=0` 입력 시 MemRd 상태로 전환
- 모든 SRAM 비활성화 (`oCsn_Fsm=1`)

**Update 상태**
- 외부에서 계수 쓰기 모드
- FSM은 SRAM 제어권을 외부에 양도 (`oCsn_Fsm=1`)
- AccessMux가 외부 신호를 SRAM에 연결
- `iUpdateFlag=1` 유지 시 Update 상태 유지
- `iUpdateFlag=0` 되면 MemRd로 전환

**MemRd 상태**
- 매 600kHz 샘플링 주기마다 진입
- `iEnSample600k` 상승에지에서:
  - `oEnDelay=1` (1 cycle pulse) 생성 → Delay Chain shift
  - `oAddr_Fsm=0`, `oInSel=0` 초기화
- 이후 12MHz 클럭마다:
  - `oAddr_Fsm`: 0→1→2→...→9 증가
  - `oInSel`: 0→1→2→...→9 증가
  - 4개 SRAM 동시 활성화 (`oCsn_Fsm_1~4=0`)
  - 각 클럭에서 4개 계수 동시 읽기 및 MAC 연산
- `oInSel==9` 완료 후:
  - `oInSel=10` (1 cycle) → Accumulator 출력 활성화
  - 다음 `iEnSample600k`에서:
    * `iUpdateFlag=1`이면 Update로 전환
    * `iUpdateFlag=0`이면 MemRd 반복

#### 3.3.5 주요 제어 신호

**oEnDelay** - Delay Chain과 Accumulator 초기화 신호
```verilog
assign oEnDelay = (rCurState == p_MemRd) && (iEnSample600k == 1'b1);
```
- MemRd 진입 시 1 cycle pulse 생성
- Delay Chain shift 및 Accumulator 초기화 트리거

**oCsn_Fsm / oWrn_Fsm** - SRAM 제어 신호 (Filter 모드)
```verilog
assign oCsn_Fsm_1 = (rCurState == p_MemRd) ? 1'b0 : 1'b1;
assign oWrn_Fsm_1 = 1'b1;  // FSM은 항상 Read만 수행
```
- MemRd 상태에서만 SRAM 활성화
- Write는 외부(Update 모드)에서만 수행

**oAddr_Fsm** - SRAM 주소 카운터 (0~9 순차 증가)
```verilog
always @(posedge iClk_12M) begin
    if (wEnDelay)
        oAddr_Fsm <= 4'h0;
    else if (rCurState == p_MemRd && oInSel < 4'd9)
        oAddr_Fsm <= oAddr_Fsm + 1'b1;
end
```
- `wEnDelay`에서 0으로 초기화
- MemRd 상태에서 매 클럭 증가하여 10개 계수 순차 읽기

**oInSel** - MAC 연산 단계 제어 (0~10)
```verilog
always @(posedge iClk_12M) begin
    if (wEnDelay)
        oInSel <= 4'h0;
    else if (rCurState == p_MemRd && oInSel < 4'd10)
        oInSel <= oInSel + 1'b1;
end
```
- Multiplier와 Accumulator 동기화
- 0~9: MAC 연산 단계, 10: Accumulator 출력 활성화

(신호 관찰 파형 - 추후 첨부 예정)

### 3.4 DelayChainTop_Flex (샘플 지연선)

#### 3.4.1 모듈 포트 정의

```verilog
module DelayChainTop_Flex (
    input        iClk,
    input        iRsn,
    input        iEnDelay,
    input  [2:0] iFirIn,
    input  [3:0] iInSel,
    
    output [2:0] oTap_Mux,   // 선택된 Tap 출력
    output [2:0] oChain      // 다음 Chain으로 전달
);
```

#### 3.4.2 내부 구조

**DelayChain_Flex (10-tap 지연선)**
- 10개의 D-FF로 구성된 shift register
- `iEnDelay=1`일 때 `iFirIn` 샘플을 shift
- 출력: `oTap_0` ~ `oTap_9` (10개 Tap), `oTap` (마지막 샘플)

**DelayMux_Flex (Tap 선택 MUX)**
- 입력: `iTap_0` ~ `iTap_9` (10개 Tap)
- 선택: `iInSel[3:0]` (0~9)
- 출력: `oTap_Mux` (선택된 1개 Tap)

#### 3.4.3 지연선 연결 구조

본 설계에서는 4개의 DelayChainTop 모듈을 직렬로 연결하여 총 40개의 샘플을 저장한다. 각 DelayChainTop은 10개의 샘플을 저장할 수 있으며, 마지막 샘플(`oChain`)을 다음 DelayChainTop의 입력으로 전달한다.
(추후 추가예정)

**동작 원리:**
- 매 600kHz 샘플링 주기(`iEnSample600k` 에지)마다 모든 Chain이 동시에 shift 동작 수행
- DelayChain1: 현재 입력 샘플(`iFirIn`)을 받아 최근 10개 샘플(x[n] ~ x[n-9]) 저장
- DelayChain2: DelayChain1의 마지막 출력(`oChain`)을 받아 x[n-10] ~ x[n-19] 저장
- DelayChain3: DelayChain2의 마지막 출력을 받아 x[n-20] ~ x[n-29] 저장
- DelayChain4: DelayChain3의 마지막 출력을 받아 x[n-30] ~ x[n-39] 저장

각 DelayChainTop 내부의 DelayMux는 `iInSel` 신호(0~9)에 따라 10개 Tap 중 하나를 선택하여 해당 MAC 유닛으로 출력한다. 이를 통해 4개 MAC 유닛이 동시에 서로 다른 시점의 샘플에 접근할 수 있다.

#### 3.4.4 Tap 배치 및 샘플 매칭

`iInSel=0`일 때 각 Delay Chain의 Tap 출력:

| Chain | Tap 선택 | 샘플 | 계수 | MAC 유닛 |
|-------|---------|------|------|---------|
| Chain1 | `oTap_0` | x[n] | h[0] | MAC1 |
| Chain2 | `oTap_0` | x[n-10] | h[10] | MAC2 |
| Chain3 | `oTap_0` | x[n-20] | h[20] | MAC3 |
| Chain4 | `oTap_0` | x[n-30] | h[30] | MAC4 |

`iInSel=1`일 때:

| Chain | Tap 선택 | 샘플 | 계수 | MAC 유닛 |
|-------|---------|------|------|---------|
| Chain1 | `oTap_1` | x[n-1] | h[1] | MAC1 |
| Chain2 | `oTap_1` | x[n-11] | h[11] | MAC2 |
| Chain3 | `oTap_1` | x[n-21] | h[21] | MAC3 |
| Chain4 | `oTap_1` | x[n-31] | h[31] | MAC4 |

**일반화:**
- `iInSel=k` (k=0~9)일 때:
  - MAC1: h[k] × x[n-k]
  - MAC2: h[10+k] × x[n-10-k]
  - MAC3: h[20+k] × x[n-20-k]
  - MAC4: h[30+k] × x[n-30-k]

#### 3.4.5 Time-Multiplexing 구현

10회 반복 연산으로 각 MAC이 10개 Tap 처리:

**MAC1 연산 순서 (iInSel = 0~9):**
```
Cycle 0: h[0] × x[n]
Cycle 1: h[1] × x[n-1]
Cycle 2: h[2] × x[n-2]
...
Cycle 9: h[9] × x[n-9]
```

**전체 FIR 연산:**
```
y[n] = Σ(h[i] × x[n-i])  (i=0 to 39)
     = MAC1 + MAC2 + MAC3 + MAC4
     = Σ(h[k]×x[n-k]) + Σ(h[10+k]×x[n-10-k]) 
       + Σ(h[20+k]×x[n-20-k]) + Σ(h[30+k]×x[n-30-k])
     (k=0 to 9)
```

(신호 관찰 파형 - 추후 첨부 예정)

### 3.5 MacTop_Flex (MAC 연산 유닛)

#### 3.5.1 모듈 포트 정의

```verilog
module MACTop_Flex (
    input         iClk_12M,
    input         iRsn,
    input  [15:0] iCoeff,      // SRAM에서 읽은 계수
    input  [2:0]  iFIRin,      // Delay Chain에서 선택된 샘플
    input  [3:0]  iInSel,      // FSM 제어 신호
    input         iEnDelay,    // Accumulator 초기화 신호
    
    output [15:0] oMac         // MAC 연산 결과
);
```

#### 3.5.2 내부 구조

**Multiplier_16x3_Flex (승산기)**
- 16-bit signed 계수 × 3-bit signed 샘플
- 1 cycle latency (pipeline register)
- `iInSel` 신호도 1 cycle 지연하여 `oInSel` 출력 (Accumulator 동기화)

**Accumulator_Flex (누산기)**
- 입력: `iRdDt[15:0]` (Multiplier 출력)
- 동작:
  - `iInSel=0`: 누산기 초기화 (0 + `iRdDt`)
  - `iInSel=1~9`: 누산 (이전 값 + `iRdDt`)
  - `iInSel=10`: 출력 활성화 (`oAccOut` 업데이트)
- Saturation: 17-bit 연산 후 overflow 검사

#### 3.5.3 Pipeline 타이밍

(Pipeline 타이밍 파형 - 추후 첨부 예정)

**파형 관찰 항목:**
- `iInSel` 신호 변화 (0→1→2→...→10)
- SRAM 계수 읽기 타이밍 (h[0], h[1], h[2], ...)
- Delay Chain Mux 샘플 선택 (x[n], x[n-1], x[n-2], ...)
- Multiplier 출력 타이밍 (1 cycle latency)
- Multiplier `oInSel` 지연 전파 (Accumulator 동기화)
- Accumulator 누산 과정 (`rAccDt` 변화)
- Accumulator 출력 업데이트 (`oAccOut`)

**핵심 동작:**
- Multiplier가 `iInSel`을 1 cycle 지연시켜 `oInSel` 출력
- Accumulator는 `oInSel`을 기준으로 누산 시작 판단
- `oInSel=0`일 때 첫 번째 곱셈 결과가 도착하여 0으로 초기화 후 누산 시작

#### 3.5.4 Accumulator 상세 동작

```verilog
// 입력 선택: 첫 번째 연산(iInSel=0)이면 0, 아니면 이전 누산값
assign wAccInA = (iInSel == 4'h0) ? 16'h0 : rAccDt;
assign wAccInB = iRdDt;  // Multiplier 출력

// 덧셈 (17-bit signed): overflow 검출을 위해 1-bit 확장
assign wAccSum = {wAccInA[15], wAccInA} + {wAccInB[15], wAccInB};

// Saturation: overflow 발생 시 최대/최소값으로 제한
// wAccSum[16]!=wAccSum[15] 이면 overflow
assign wAccSumSat = (wAccSum[16] != wAccSum[15]) ? 
                    {wAccSum[16], {15{~wAccSum[16]}}} : wAccSum[15:0];

// 누산 레지스터 업데이트
always @(posedge iClk) begin
    if (!iRsn)
        rAccDt <= 16'h0;              // Reset
    else if (iEnDelay)
        rAccDt <= 16'h0;              // 새 샘플 시작 시 초기화
    else if (iInSel != 4'd9)
        rAccDt <= wAccSumSat;         // iInSel=0~8: 누산 진행
end

// 출력 레지스터 업데이트
always @(posedge iClk) begin
    if (!iRsn)
        oAccOut <= 16'h0;             // Reset
    else if (iInSel == 4'd9)
        oAccOut <= wAccSumSat;        // iInSel=9: 최종 누산 결과 출력
end
```

**iInSel=0~8**: `rAccDt`에 누산 값 저장 (중간 결과)  
**iInSel=9**: 마지막 누산 후 `oAccOut`에 최종 결과 저장  
**iInSel=10**: 출력 유지 (다음 샘플까지)

(신호 관찰 파형 - 추후 첨부 예정)

### 3.6 SpSRAM_Flex (계수 저장 메모리)

#### 3.6.1 모듈 포트 정의

```verilog
module SpSRAM_Flex #(
    parameter SRAM_DEPTH = 16,
    parameter DATA_WIDTH = 16
)(
    input         iClk,
    input         iRsn,
    input         iCsn,        // Chip Select (active-low)
    input         iWrn,        // Write Enable (0=Write, 1=Read)
    input  [3:0]  iAddr,       // 주소 (0~15, 실제 사용 0~9)
    input  [15:0] iWrDt,       // 쓰기 데이터
    output [15:0] oRdDt        // 읽기 데이터
);
```

#### 3.6.2 동작 원리

**Write 동작 (`iCsn=0`, `iWrn=0`)**
```verilog
if (!iCsn && !iWrn)
    mem[iAddr] <= iWrDt;
```

**Read 동작 (`iCsn=0`, `iWrn=1`)**
```verilog
assign oRdDt = (!iCsn && iWrn) ? mem[iAddr] : 16'h0;
```

#### 3.6.3 계수 배치

4개 SRAM에 40개 계수 분산 저장:

| SRAM | 주소 0 | 주소 1 | ... | 주소 9 |
|------|--------|--------|-----|--------|
| SRAM1 | h[0] | h[1] | ... | h[9] |
| SRAM2 | h[10] | h[11] | ... | h[19] |
| SRAM3 | h[20] | h[21] | ... | h[29] |
| SRAM4 | h[30] | h[31] | ... | h[39] |

**주소 매핑 (외부 접근 시):**
- `iAddr[5:4]=00, iAddr[3:0]=k` → SRAM1[k] = h[k]
- `iAddr[5:4]=01, iAddr[3:0]=k` → SRAM2[k] = h[10+k]
- `iAddr[5:4]=10, iAddr[3:0]=k` → SRAM3[k] = h[20+k]
- `iAddr[5:4]=11, iAddr[3:0]=k` → SRAM4[k] = h[30+k]

### 3.7 MacFinalSum_Flex (최종 합산)

#### 3.7.1 모듈 포트 정의

```verilog
module MacFinalSum_Flex (
    input  [15:0] iMac1,
    input  [15:0] iMac2,
    input  [15:0] iMac3,
    input  [15:0] iMac4,
    
    output [15:0] oFirOut
);
```

#### 3.7.2 동작 원리

4개 MAC 유닛의 누산 결과를 최종 합산:

```verilog
wire [17:0] wMacSum;
assign wMacSum = {iMac1[15], iMac1[15], iMac1} 
               + {iMac2[15], iMac2[15], iMac2}
               + {iMac3[15], iMac3[15], iMac3}
               + {iMac4[15], iMac4[15], iMac4};

// Saturation
assign oFirOut = (wMacSum[17] != wMacSum[16]) ?
                 {wMacSum[17], {15{~wMacSum[17]}}} : wMacSum[15:0];
```

**Saturation 처리:**
- `wMacSum[17:16] = 01` (양수 overflow) → `oFirOut = 16'h7FFF`
- `wMacSum[17:16] = 10` (음수 overflow) → `oFirOut = 16'h8000`
- `wMacSum[17:16] = 00 또는 11` (정상) → `oFirOut = wMacSum[15:0]`

(신호 관찰 파형 - 추후 첨부 예정)

---

## 4. Testbench 설계

### 4.1 검증 목표

본 테스트벤치는 다음 기능들을 검증하도록 설계되었다.

#### 4.1.1 계수 쓰기 검증
- 40개 Kaiser Window 계수를 4개 SRAM에 정확히 저장
- 주소 매핑 정확성 확인 (6-bit → 4개 Bank × 4-bit 내부 주소)
- Update 모드 (`iCoeffUpdateFlag=1`) 동작 확인

#### 4.1.2 Delay Chain 동작 검증
- 600kHz 샘플링마다 shift 동작 확인
- 40-tap cascade 구조 정상 동작 확인
- Tap Mux 선택 (`iInSel=0~9`) 정확성 검증

#### 4.1.3 MAC 연산 검증
- Time-Multiplexing 동작 확인 (각 MAC 10회 반복)
- Multiplier pipeline 타이밍 검증
- Accumulator 누산 정확성 확인
- Saturation 동작 확인

#### 4.1.4 전체 FIR 필터 검증
- 랜덤 4-PAM 심볼 입력 (-3, -1, +1, +3)
- 200kHz 심볼 레이트 + 3× oversampling (600kHz)
- 출력 파형 분석 및 대역 제한 특성 확인

### 4.2 테스트 시나리오

#### 4.2.1 Phase 1: 초기화

```verilog
initial begin
    // 신호 초기화
    iRsn = 0;
    iCoeffUpdateFlag = 0;
    iCsnRam = 1;
    iWrnRam = 1;
    iFirIn = 3'b000;
    
    // 리셋 해제
    repeat(5) @(posedge iClk12M);
    iRsn = 1;
end
```

**검증 항목:**
- 모든 Delay Tap: 0
- 모든 Accumulator: 0
- FSM: IDLE 상태

#### 4.2.2 Phase 2: 계수 쓰기

```verilog
iCoeffUpdateFlag = 1;  // Update 모드 진입

for(i=0; i<40; i=i+1) begin
    // 주소 매핑
    if (i < 10)      iAddrRam = i;          // SRAM1: 0~9
    else if (i < 20) iAddrRam = i + 6;      // SRAM2: 16~25
    else if (i < 30) iAddrRam = i + 12;     // SRAM3: 32~41
    else             iAddrRam = i + 18;     // SRAM4: 48~57
    
    iWrDtRam = answer_sheet[i];  // Kaiser 계수
    iCsnRam = 0; iWrnRam = 0;    // Write enable
    
    @(negedge iClk12M);
    iCsnRam = 1; iWrnRam = 1;    // Write disable
end

iCoeffUpdateFlag = 0;  // Filter 모드 전환
```

**검증 항목:**
- SRAM1[0~9] = h[0~9]
- SRAM2[0~9] = h[10~19]
- SRAM3[0~9] = h[20~29]
- SRAM4[0~9] = h[30~39]
- AddrDecoder 동작 (iAddr[5:4]로 Bank 선택)

#### 4.2.3 Phase 3: 필터 동작 (랜덤 입력)

```verilog
// 200kHz 심볼 레이트 = 3× oversampling at 600kHz
for(i=0; i<500; i=i+1) begin
    // 1번째 600kHz: 실제 심볼
    wait(iEnSample600k);
    @(negedge iClk12M);
    case($urandom % 4)
        0: iFirIn = 3'b001;  // +1
        1: iFirIn = 3'b011;  // +3
        2: iFirIn = 3'b111;  // -1
        3: iFirIn = 3'b101;  // -3
    endcase
    wait(!iEnSample600k);
    
    // 2번째 600kHz: 0 (Oversampling)
    wait(iEnSample600k);
    @(negedge iClk12M);
    iFirIn = 3'b000;
    wait(!iEnSample600k);
    
    // 3번째 600kHz: 0 (Oversampling)
    wait(iEnSample600k);
    @(negedge iClk12M);
    iFirIn = 3'b000;
    wait(!iEnSample600k);
end
```

**검증 항목:**
- 심볼 간격: 5μs (= 200kHz)
- Oversampling: 매 심볼당 3개 샘플 (심볼, 0, 0)
- Delay Chain shift 타이밍
- MAC Time-Multiplexing 동작
- 출력 파형의 대역 제한 특성

### 4.3 예상 결과

#### 4.3.1 Impulse 응답 (이론값)
입력: `iFirIn = 3'b001` (1회), 이후 모두 0

예상 출력:
```
샘플 0: h[0] = 146
샘플 1: h[1] = 0
샘플 2: h[2] = -242
샘플 3: h[3] = 302
...
샘플 39: h[39] = 146
```

#### 4.3.2 랜덤 입력 파형 특성
- 200kHz 심볼 성분 통과
- 400kHz 이상 고주파 성분 감쇠
- Kaiser Window에 의한 Gibbs 현상 억제

(테스트 결과 파형 - 추후 첨부 예정)

---

## 5. Trouble Shooting

### 5.1 문제 1: Reset 신호 600kHz 동기화

#### 5.1.1 문제 발견

**증상:**
- Reset 신호 (`iRsn=0`) 입력 후 최대 1.667μs (20 clocks) 동안 필터가 계속 동작
- Reset 타이밍이 예측 불가능

**원인 코드:**
```verilog
// FSM_Flex.v Line 78 (수정 전)
always @(posedge iEnSample600k)
begin
    if (!iRsn)
        rCurState <= p_Idle;
    else
        rCurState <= rNxtState[1:0];
end
```

#### 5.1.2 문제 분석

**타이밍 시나리오:**
```
T=0μs:     iEnSample600k ↑  → rCurState = MemRd (필터 동작 시작)
T=0.5μs:   iRsn = 0 (Reset 활성화)
           문제: rCurState 변화 없음 (다음 600kHz 에지 대기 중)
           결과: 필터는 계속 SRAM 읽기 및 MAC 연산 수행
T=1.667μs: iEnSample600k ↑  → rCurState = p_Idle (Reset 적용)
```

**심각도: 치명적 (Critical)**
- Reset 신호 무시로 인한 예측 불가능한 동작
- 시스템 안정성 저하 (Reset 타이밍 불확실)
- 디버깅 극도로 어려움

#### 5.1.3 해결 방안

**수정된 코드:**
```verilog
// FSM_Flex.v Line 78 (수정 후)
always @(posedge iClk_12M)
begin
    if (!iRsn)
        rCurState <= p_Idle;
    else if (iEnSample600k == 1'b1)
        rCurState <= rNxtState[1:0];
end
```

**개선 효과:**

| 항목 | 수정 전 | 수정 후 | 개선율 |
|-----|---------|---------|-------|
| Reset 응답 시간 | 최대 1.667μs | 83ns | 20배 개선 |
| UpdateFlag 응답 시간 | 최대 1.667μs | 83ns | 20배 개선 |
| 상태 전환 타이밍 | 600kHz 에지 | 600kHz 에지 | 동일 (의도 유지) |
| 시스템 안정성 | 낮음 (예측 불가) | 높음 (동기화) | 대폭 개선 |

**핵심 개선:**
1. Reset 즉시 적용 (83ns): 데이터 손상 방지
2. Mode 전환 즉시: Dead time 제거
3. 기존 의도 유지: 상태는 여전히 600kHz 에지에만 변경 (`iEnSample600k==1` 조건)
4. 코드 수정 최소: 단 1줄 변경

#### 5.1.4 검증 방법

**테스트 코드:**
```verilog
// Reset 응답 시간 측정
wait(rCurState == p_MemRd);  // 필터 동작 중
#500ns;                      // 600kHz 에지 중간
iRsn = 0;                    // Reset 활성화

// 측정: rCurState가 p_Idle로 변경되는 시간
// 수정 전: 최대 1.667μs
// 수정 후: 83ns (1 clock)
```

### 5.2 문제 2: 200kHz 심볼을 600kHz로 업샘플링하지 않음

#### 5.2.1 문제 발견

**증상:**
- 테스트벤치가 매 600kHz마다 새로운 심볼 입력
- 실제 심볼 레이트: 600kHz (요구사항의 3배)
- 필터 출력이 설계 의도와 다르게 동작

**원인 코드:**
```verilog
// Top_FirFilter_tb.v (수정 전)
for(i=0; i<500; i=i+1) begin
    wait(iEnSample600k);
    iFirIn = 랜덤심볼;  // 매 600kHz마다 새 심볼
    wait(!iEnSample600k);
    iFirIn = 3'b000;
end
```

#### 5.2.2 문제 분석

**현재 타이밍 (잘못됨):**
```
t=0.00μs: 심볼 +1   (600kHz #1)  ← 새 심볼
t=1.67μs: 심볼 -3   (600kHz #2)  ← 새 심볼 (문제!)
t=3.33μs: 심볼 +1   (600kHz #3)  ← 새 심볼 (문제!)
t=5.00μs: 심볼 -1   (600kHz #4)  ← 새 심볼 (문제!)
```
심볼 간격 = 1.67μs = **600kHz**

**요구사항:**
- 심볼 레이트: 200kHz
- 샘플링 레이트: 600kHz
- Oversampling: 3배 (3 샘플 / 1 심볼)

**심각도: 치명적 (Critical)**
- Oversampling 없음 → 대역폭 특성 검증 불가능
- Kaiser Window 효과 검증 불가능
- 실제 통신 시스템과 불일치

#### 5.2.3 해결 방안

**수정된 코드:**
```verilog
// 200kHz 심볼 레이트 = 3× oversampling at 600kHz
for(i=0; i<500; i=i+1) begin
    // 1번째 600kHz: 실제 심볼
    wait(iEnSample600k);
    @(negedge iClk12M);
    case($urandom % 4)
        0: iFirIn = 3'b001;  // +1
        1: iFirIn = 3'b011;  // +3
        2: iFirIn = 3'b111;  // -1
        3: iFirIn = 3'b101;  // -3
    endcase
    wait(!iEnSample600k);
    
    // 2번째 600kHz: 0 (Oversampling)
    wait(iEnSample600k);
    @(negedge iClk12M);
    iFirIn = 3'b000;
    wait(!iEnSample600k);
    
    // 3번째 600kHz: 0 (Oversampling)
    wait(iEnSample600k);
    @(negedge iClk12M);
    iFirIn = 3'b000;
    wait(!iEnSample600k);
end
```

**올바른 타이밍:**
```
t=0.00μs: 심볼 +1   (600kHz #1)  ← 실제 데이터
t=1.67μs: 0        (600kHz #2)  ← Oversampling
t=3.33μs: 0        (600kHz #3)  ← Oversampling
t=5.00μs: 심볼 -3   (600kHz #4)  ← 다음 실제 데이터
t=6.67μs: 0        (600kHz #5)  ← Oversampling
t=8.33μs: 0        (600kHz #6)  ← Oversampling
```
심볼 간격 = 5μs = **200kHz**

**개선 효과:**

| 항목 | 수정 전 | 수정 후 | 상태 |
|-----|---------|---------|------|
| 심볼 레이트 | 600kHz | 200kHz | 요구사항 충족 |
| Oversampling | 없음 | 3배 | 대역폭 제한 동작 |
| 필터 검증 | 불가능 | 가능 | 정상 테스트 |
| 실제 시스템 일치 | 불일치 | 일치 | 설계 의도 반영 |

#### 5.2.4 검증 방법

**파형 관찰:**
```
iFirIn:     +1  0  0  -3  0  0  +1  0  0  ...
            ↑       ↑       ↑
            5μs     5μs     5μs  (200kHz)
            
iEnSample600k: ↑  ↑  ↑  ↑  ↑  ↑  ...
               1.67μs간격 (600kHz)
```
(테스트 결과 파형 - 추후 첨부 예정)

**FFT 분석:**
- 수정 전: 600kHz 주변 에너지 집중
- 수정 후: 200kHz 주변 에너지 집중 + 400kHz 이상 감쇠

---

## 6. 결론

본 프로젝트에서는 40-tap FIR 필터를 Time-Multiplexing과 Spatial-Multiplexing을 결합한 하이브리드 아키텍처로 구현하였다. 4개의 MAC 유닛을 각각 10회 반복 사용하여 총 40번의 연산을 수행하며, 600kHz 샘플링 주기(20 clocks) 내에 모든 연산을 완료한다.

설계 과정에서 두 가지 치명적인 문제를 발견하고 해결하였다. 첫째, FSM의 Reset 신호가 600kHz에 동기화되어 최대 1.667μs 지연이 발생하는 문제를 12MHz 클럭 동기화로 개선하여 응답 시간을 20배 단축하였다. 둘째, 테스트벤치에서 200kHz 심볼을 600kHz로 업샘플링하지 않는 문제를 발견하여, 3× oversampling 구조로 수정하였다.

최종 설계는 모든 요구사항을 충족하며, 리소스 효율과 타이밍 제약을 만족하는 검증된 구현을 달성하였다.

---

**참고 문헌**
- 팀 프로젝트 요구사항 명세서
- Verilog HDL 설계 가이드
- Kaiser Window FIR Filter Design

**부록**
- (추후 추가 예정) 파형 관찰 결과
- (추후 추가 예정) 시뮬레이션 로그