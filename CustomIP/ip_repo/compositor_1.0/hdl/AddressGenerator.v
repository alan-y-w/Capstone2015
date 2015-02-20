module AddressGenerator(
        output wire [31:0] FrameBufferAddr,
        output wire [31:0] DrawBufferAddr,
        output wire [31:0] DispBufferAddr,
        input wire [31:0] FrameBufferAddrBase,
        input wire [31:0] DrawBufferAddrBase,
        input wire [31:0] DispBufferAddrBase,
        input clk,
        input rst,
        input next,
        output done
        );
        
    // Calculate index for use as base-relative
    // address offset
    // - only increment when next signal asserted
    // - increment by one pixel (4B) at a time 
    // - increment 640 times, then skip to next line
    reg [21:0] index;
    always@(posedge clk)
    begin
        if(~rst) begin
            index <= 22'b0; 
        end else begin
            if (next) begin
                if (index == (4*(640-1))) begin
                    index[11:0] <= 12'b0;
                    index[21:12] <= index[21:12] + 1;
                end else begin
                    index <= index + 4;
                end
            end else begin
                index <= index;
            end
        end
    end
    
    // Signal end of generation when index has looped
    assign done = (index==22'b0);
    
    // Set output addresses to base + offset
    assign DispBufferAddr  = DispBufferAddrBase  + index;
    assign DrawBufferAddr  = DrawBufferAddrBase  + index;
    assign FrameBufferAddr = FrameBufferAddrBase + index;
    
 endmodule