module LayerMixer(
        input wire [31:0] FrameBufferValue,
        input wire [31:0] DrawBufferValue,
        output wire [31:0] DisplayBufferValue
        );
    assign DisplayBufferValue = DrawBufferValue[31] ? DrawBufferValue : FrameBufferValue;
endmodule