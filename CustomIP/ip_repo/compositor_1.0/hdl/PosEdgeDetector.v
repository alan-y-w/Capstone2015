module PosEdgeDetector(
    input in,
    output out,
    input clk,
    input rst
    );
    // State Machine
    parameter   S0 = 1'b0,
                S1 = 1'b1;
    reg state;
    
    always@(posedge clk)
    begin
        if(~rst) begin
            state <= S0;
        end else begin
            if(in) begin
                state <= S1;
            end else begin
                state <= S0;
            end
        end
    end
    assign out = ((state==S0) & (in==1'b1));
endmodule
