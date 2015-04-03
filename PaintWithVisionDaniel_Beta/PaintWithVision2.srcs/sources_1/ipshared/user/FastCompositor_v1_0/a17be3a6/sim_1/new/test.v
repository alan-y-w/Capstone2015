module test();

reg clk;
reg resetn;
wire tlast;
initial begin
    clk = 0;
    resetn = 0;
    #20 resetn = 1;
end always begin
    #5 clk = ~clk;
end

reg [31:0] A_data;
reg A_valid;
wire A_ready;
initial begin
    A_data = 32'h00000000;
    A_valid = 1;
end always begin
    #10 A_data = A_data + 1;
end
    
reg [31:0] B_data;
reg B_valid;
wire B_ready;
initial begin
    B_data = 32'hF0001111;
    B_valid = 1;
end always begin
    #10 B_data = B_data + 1;
end
    
wire [31:0] C_data;
wire C_valid;
reg C_ready;
initial begin
    C_ready = 1;
    #100 C_ready = 0;
    #40 C_ready = 1;
    
end

FastCompositor FC0(
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
tlast);

endmodule