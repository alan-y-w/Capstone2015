module FastCompositor (
    clk,
    resetn,
    A_data,
    A_valid,
    A_ready,
    B_data,
    B_valid,
    B_ready,
    C_data,
    C_valid,
    C_ready,
    tlast,
    tkeep
);
    input clk;
    input resetn;
    output reg tlast;
    output wire [3:0] tkeep;
    assign tkeep = 4'b1111;
    
    input wire [31:0] A_data;
    input wire A_valid;
    output reg A_ready;
    
    input wire [31:0] B_data;
    input wire B_valid;
    output reg B_ready;
    
    output reg [31:0] C_data;
    output reg C_valid;
    input wire C_ready;
    
    // Stream Manipulation
    wire [31:0] MixedValue;
    assign MixedValue = B_data[31] ? B_reg : A_reg;   
    
    
    //Interface A
    reg A_reg_valid;
    reg [31:0] A_reg;
    always@(posedge clk) begin
        if(~resetn) begin
            A_reg <= 32'b0;
            A_reg_valid <= 0;
        end else if(A_valid & B_valid & C_ready) begin
            A_reg <= A_data;
            A_reg_valid <= 1;
        end else begin
            A_reg <= A_reg;
            A_reg_valid <= 0;
        end
        A_ready <= (B_valid & C_ready & resetn);
    end
    
    //Interface B
    reg B_reg_valid;
    reg [31:0] B_reg;
    always@(posedge clk) begin
        if(~resetn) begin
            B_reg <= 32'b0;
            B_reg_valid <= 0;
        end else if(A_valid & B_valid & C_ready) begin
            B_reg <= B_data;
            B_reg_valid <= 1;
        end else begin
            B_reg <= B_reg;
            B_reg_valid <= 0;
        end
        B_ready <= (A_valid & C_ready & resetn);
    end
    
     //Interface C
    always@(posedge clk) begin
        if(~resetn) begin
            C_data <= 32'b0;
            C_valid <= 0;
        end else if(A_reg_valid & B_reg_valid) begin
            C_data <= MixedValue;
            C_valid <= 1;
        end else if(C_valid & C_ready) begin
            C_data <= C_data;
            C_valid <= 0;
        end else begin
            C_data <= C_data;
            C_valid <= 1;
        end
    end
    
    reg [9:0] counter;
    always@(posedge clk)
    begin
        if(~resetn) begin
            counter <= 10'b0;
            tlast <= 0;
        end else if (A_reg_valid & B_reg_valid) begin
            if(counter==639) begin
                counter <= 10'b0;
                tlast <= 1; 
            end else begin
                counter <= counter + 1;
                tlast <= 0;
            end
        end else begin
            counter <= counter;
            tlast <= tlast;
        end
    end 
    

endmodule