module AddressGenerator(
        output wire [31:0] FrameBufferAddr,
        output wire [31:0] DrawBufferAddr,
        output wire [31:0] DispBufferAddr,
        output wire [21:0] index_val,
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
    reg [20:0] index;
    always@(posedge clk)
    begin
        if(~rst) begin
            index <= 21'b0; 
        end else begin
            if (next) begin
                if (index == (4*(640-1))) begin
                    index[11:0] <= 12'b0;
                    index[20:12] <= index[20:12] + 1;
                end else begin
                    index <= index + 4;
                end
            end else begin
                index <= index;
            end
        end
    end
    
    // Signal end of generation when index has looped
    assign done = (index==21'b0);
    assign index_val = {1'b0, index};
    // Set output addresses to base + offset
    assign DispBufferAddr  = DispBufferAddrBase  + index;
    assign DrawBufferAddr  = DrawBufferAddrBase  + index;
    assign FrameBufferAddr = FrameBufferAddrBase + index;
    
 endmodule