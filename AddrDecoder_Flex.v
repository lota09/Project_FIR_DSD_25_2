/*******************************************************************
  - Project          : 2025 Team Project Flex
  - File name        : AddrDecoder_Flex.v
  - Description      : AddrDecoder -> iAddr signal
  - Owner            : Flex
  - Revision history : 1) 2025.11.28 : Initial release
                       2) 2025.11.30 : 
*******************************************************************/

`timescale 1ns/10ps

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