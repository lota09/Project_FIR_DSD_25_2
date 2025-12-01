/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : DelayChainTop_Flex.v
  - Description      : DelayChain Top file
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

`timescale 1ns/10ps

module DelayChainTop_Flex (

  input                     iClk,
  input                     iRsn,
  
  input                     iEnDelay,
  input      [2:0]          iFirIn,

  input      [3:0]          iInSel,

  output wire [2:0]         oTap_Mux,
  output wire[2:0]          oChain
  );



  /*********************************************/
  // wire & reg
  /*********************************************/
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

  /*********************************************/
  // AccessMux.v instantiation
  /*********************************************/
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



  /*********************************************/
  // CtrlFsm.v instantiation
  /*********************************************/
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