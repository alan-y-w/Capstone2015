    reg [1:0] mst_exec_state;


	reg  	axi_rready;
	reg  	axi_bready;
	wire  	write_resp_error;
	wire  	read_resp_error;
	
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	start_single_write;
	reg  	start_single_read;
	reg     txn_done;
	
	reg  	write_issued;
	reg  	read_issued;
	
	
	