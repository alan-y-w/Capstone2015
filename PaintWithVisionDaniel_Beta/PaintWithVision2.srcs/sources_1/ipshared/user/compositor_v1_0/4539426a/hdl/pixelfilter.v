`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Daniel Di Felice
// 
// Create Date: 03/05/2015 12:40:37 PM
// Design Name: 
// Module Name: pixelfilter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
 

module PixelFilter(
        clk,
        rst,
        FrameBufferValue,
        FrBAddr,
        sweep_complete,
        index_val,
        x_pos,
        y_pos,
        start,
        threshold,
        valid
    );
    
        input clk;
        input rst;
        input wire [31:0] FrameBufferValue;
        input wire [21:0] index_val;
        input wire [31:0] FrBAddr;
        input sweep_complete;
        output wire [31:0] x_pos;
        output wire [31:0] y_pos;
        input start;
        input wire [31:0] threshold;
        input valid;
        
        reg [31:0] counter;
        reg [31:0] x_total;
        reg [31:0] y_total;
        reg [31:0] x_average;
        reg [31:0] y_average;
        reg within_threshold;
        reg dividebynonzero;
        reg [1:0] curstate;
        
        wire [10:0] y;
        wire [10:0] x;
        
        assign y = index_val[21:12];
//        assign x = index_val[11:0]; // X is mulitplied by 4.
        assign x = index_val[11:2];
        
        parameter   Reset = 2'b00,
                    Running = 2'b01, 
                    Done = 2'b10;
        
        always @(*)
        begin
        if ((threshold[19:16] <= FrameBufferValue[7:4]) & (threshold[23:20] <= FrameBufferValue[15:12]) & (threshold[27:24] <= FrameBufferValue[23:20]) & (threshold [3:0] >= FrameBufferValue[7:4]) & (threshold [7:4] >= FrameBufferValue[15:12]) & (threshold [11:8] >= FrameBufferValue[23:20]))
            within_threshold <= 1'b1;
        else
            within_threshold <= 1'b0;
        end
        
        always @(*)
        begin
        if (counter >= 1)
            dividebynonzero <= 1'b1;
        else
            dividebynonzero <= 1'b0;
        end
        
        always @ (posedge clk)
        begin
            if (rst == 1'b0)
            begin
                counter <= 0;
                x_total <= 0;
                y_total <= 0;
                x_average <= 0;
                y_average <= 0;
                curstate <= Reset;
            end
            else
            begin 
                case (curstate)
                Reset: 
                begin
                    if (start) 
                    begin
                        curstate <= Running;
                        x_total <= 0;
                        y_total <= 0;
                        counter <= 0;
                    end
                    else
                    begin
                        curstate <= Reset;
                        x_total <= x_total;
                        y_total <= y_total;
                        counter <= counter;
                    end
                    x_average <= x_average;
                    y_average <= y_average;
                end
                Running:
                begin
                if (valid & within_threshold)
                     begin
                         x_total <= x_total + x;
//                         x_total <= FrameBufferValue;
                         y_total <= y_total + y;
//                         y_total <= FrBAddr;
                         counter <= counter + 1;
                     end
                     else
                     begin
                        counter <= counter;
                        x_total <= x_total;
                        y_total <= y_total;
                     end
                     if (sweep_complete == 1'b1) //Max value of the pixels ((480-1)*4096 + 640) - 1
                     begin
                         curstate <= Done;
                     end
                     else
                     begin
                         curstate <= Running;
                     end
                     x_average <= x_average;
                     y_average <= y_average;
                end
                Done:
                begin
                    if (dividebynonzero)
                    begin
                        x_average <= x_total / counter;
                        y_average <= y_total / counter;
                    end
                    else
                    begin
                        x_average <= 32'hffffffff;
                        y_average <= 32'hffffffff;
                    end
                    curstate <= Reset;
                    counter <= counter;
                    x_total <= x_total;
                    y_total <= y_total;
                end
                default:
                begin
                    counter <= 0;
                    x_total <= 0;
                    y_total <= 0;
                    x_average <= 0;
                    y_average <= 0;
                    curstate <= Reset;
                end
                endcase                   
            end
         end
 
 assign x_pos = x_total;
 assign y_pos = y_total;
        
endmodule
