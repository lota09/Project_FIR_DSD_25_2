/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : SpSram_Flex.v
  - Description      : M-Depth & N-Width SPSRAM modeling
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.00 : 
*******************************************************************/

`timescale 1ns/10ps

module SpSram #(

  // Parameter
  parameter SRAM_DEPTH = 10,
  parameter DATA_WIDTH = 16 ) (


  // Clock & reset
  input                             iClk,     // Rising edge
  input                             iRsn,     // Sync. & low reset


  // SP-SRAM Input & Output
  input                             iCsn,     // Chip selected @ Low
  input                             iWrn,     // 0:Write, 1:Read
  input  [log_b2(SRAM_DEPTH-1)-1:0] iAddr,    // 32bit data address

  input  [DATA_WIDTH-1:0]           iWrDt,    // Write data
  output [DATA_WIDTH-1:0]           oRdDt     // Read data

  );



  // Integer declaration
  integer          i;

  // wire & reg declaration
  reg  [DATA_WIDTH-1:0] rMem[0:SRAM_DEPTH-1];    // SRAM_DEPTH*DATA_WIDTH array
  reg  [DATA_WIDTH-1:0] rRdDt;



  /*************************************************************/
  // Function for caculation iAddr bit width
  /*************************************************************/
  // log_b2 (base 2 log function)
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
  


  /*************************************************************/
  // SP-SRAM function
  /*************************************************************/
  // rMem write operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      for (i=0 ; i<SRAM_DEPTH ; i=i+1)
      begin
        rMem[i] <= {DATA_WIDTH{1'b0}};
      end
    end

    // Write condition
    else if (iCsn == 1'b0 && iWrn == 1'b0)
    begin
      rMem[iAddr] <= iWrDt[DATA_WIDTH-1:0];
    end

  end


  // rMem read operation
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
    begin
      rRdDt <= {DATA_WIDTH{1'b0}};
    end

    // Read codition
    else if (iCsn == 1'b0 && iWrn == 1'b1)
    begin
      rRdDt <= rMem[iAddr][DATA_WIDTH-1:0];
    end

  end


  // Output mapping
  assign oRdDt = rRdDt[DATA_WIDTH-1:0];


endmodule
