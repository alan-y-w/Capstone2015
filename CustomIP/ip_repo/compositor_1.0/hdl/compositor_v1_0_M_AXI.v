`timescale 1 ps / 1 ps

	module compositor_v1_0_M_AXI #
	(
	// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter integer C_M_AXI_DATA_WIDTH	= 32
	)
	(
	    // Slave Interface
	    input wire [31:0] FrameBufferBaseAddress,
	    input wire [31:0] DrawBufferBaseAddress,
	    input wire [31:0] DispBufferBaseAddress,
	    input wire ready,
	    output reg done,
	    input wire [31:0] threshold,
	    output wire [31:0] x_pos,
	    output wire [31:0] y_pos,
	    
		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
	);


	// State Machine
	parameter [2:0]    IDLE        = 3'b000,   // Compositor not active
	                   READ_FB     = 3'b001,   // Reading frame buffer
	                   READ_DB     = 3'b010,   // Reading drawing buffer
	                   MIXING      = 3'b011,   // Mixing pixel
	                   WRITE       = 3'b100;   // Writing pixel back

    reg [2:0] mst_exec_state;

	// AXI4LITE signals
	//write address valid
	reg  	axi_awvalid;
	//write data valid
	reg  	axi_wvalid;
	//read address valid
	reg  	axi_arvalid;
	//read data acceptance
	reg  	axi_rready;
	//write response acceptance
	reg  	axi_bready;
	//write address
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	//write data
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	//read addresss
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	//Asserts when there is a write response error
	wire  	write_resp_error;
	//Asserts when there is a read response error
	wire  	read_resp_error;
	//A pulse to initiate a write transaction
	reg  	start_single_write;
	//A pulse to initiate a read transaction
	reg  	start_single_read;
	//Asserts when a single beat write transaction is issued and remains asserted till the completion of write trasaction.
	reg  	write_issued;
	//Asserts when a single beat read transaction is issued and remains asserted till the completion of read trasaction.
	reg  	read_issued;


	// I/O Connections assignments

	//Adding the offset address to the base addr of the slave
	assign M_AXI_AWADDR	= axi_awaddr;
	//AXI 4 write data
	assign M_AXI_WDATA	= axi_wdata;
	assign M_AXI_AWPROT	= 3'b001;
	assign M_AXI_AWVALID	= axi_awvalid;
	//Write Data(W)
	assign M_AXI_WVALID	= axi_wvalid;
	//Set all byte strobes
	assign M_AXI_WSTRB	= 4'b1111;
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;
	//Read Address (AR)
	assign M_AXI_ARADDR	= axi_araddr;
	assign M_AXI_ARVALID	= axi_arvalid;
	assign M_AXI_ARPROT	= 3'b000;
	//Read and Read Response (R)
	assign M_AXI_RREADY	= axi_rready;
  


	//--------------------
	//Write Address Channel
	//--------------------

	// The purpose of the write address channel is to request the address and 
	// command information for the entire transaction.  It is a single beat
	// of information.

	// Note for this example the axi_awvalid/axi_wvalid are asserted at the same
	// time, and then each is deasserted independent from each other.
	// This is a lower-performance, but simplier control scheme.

	// AXI VALID signals must be held active until accepted by the partner.

	// A data transfer is accepted by the slave when a master has
	// VALID data and the slave acknoledges it is also READY. While the master
	// is allowed to generated multiple, back-to-back requests by not 
	// deasserting VALID, this design will add rest cycle for
	// simplicity.

	// Since only one outstanding transaction is issued by the user design,
	// there will not be a collision between a new request and an accepted
	// request on the same clock cycle. 

	  always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    //Only VALID signals must be deasserted during reset per AXI spec          
	    //Consider inverting then registering active-low reset for higher fmax     
	    if (M_AXI_ARESETN == 0)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	      end                                                                      
	      //Signal a new address/data command is available by user logic           
	    else                                                                       
	      begin                                                                    
	        if (start_single_write)                                                
	          begin                                                                
	            axi_awvalid <= 1'b1;                                               
	          end                                                                  
	     //Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
	        else if (M_AXI_AWREADY && axi_awvalid)                                 
	          begin                                                                
	            axi_awvalid <= 1'b0;                                               
	          end                                                                  
	      end                                                                      
	  end                                                                                                                                                


	//--------------------
	//Write Data Channel
	//--------------------

	//The write data channel is for transfering the actual data.
	//The data generation is speific to the example design, and 
	//so only the WVALID/WREADY handshake is shown here

	   always @(posedge M_AXI_ACLK)                                        
	   begin                                                                         
	     if (M_AXI_ARESETN == 0)                                                    
	       begin                                                                     
	         axi_wvalid <= 1'b0;                                                     
	       end                                                                       
	     //Signal a new address/data command is available by user logic              
	     else if (start_single_write)                                                
	       begin                                                                     
	         axi_wvalid <= 1'b1;                                                     
	       end                                                                       
	     //Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)      
	     else if (M_AXI_WREADY && axi_wvalid)                                        
	       begin                                                                     
	        axi_wvalid <= 1'b0;                                                      
	       end                                                                       
	   end                                                                           


	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	//The write response channel provides feedback that the write has committed
	//to memory. BREADY will occur after both the data and the write address
	//has arrived and been accepted by the slave, and can guarantee that no
	//other accesses launched afterwards will be able to be reordered before it.

	//The BRESP bit [1] is used indicate any errors from the interconnect or
	//slave for the entire write burst. This example will capture the error.

	//While not necessary per spec, it is advisable to reset READY signals in
	//case of differing reset latencies between master/slave.

	  always @(posedge M_AXI_ACLK)                                    
	  begin                                                                
	    if (M_AXI_ARESETN == 0)                                           
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // accept/acknowledge bresp with axi_bready by the master          
	    // when M_AXI_BVALID is asserted by slave                          
	    else if (M_AXI_BVALID && ~axi_bready)                              
	      begin                                                            
	        axi_bready <= 1'b1;                                            
	      end                                                              
	    // deassert after one clock cycle                                  
	    else if (axi_bready)                                               
	      begin                                                            
	        axi_bready <= 1'b0;                                            
	      end                                                              
	    // retain the previous value                                       
	    else                                                               
	      axi_bready <= axi_bready;                                        
	  end                                                                  
	                                                                       
	//Flag write errors                                                    
	assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);


	//----------------------------
	//Read Address Channel
	//----------------------------
	                                                                                   
	  // A new axi_arvalid is asserted when there is a valid read address              
	  // available by the master. start_single_read triggers a new read                
	  // transaction                                                                   
	  always @(posedge M_AXI_ACLK)                                                     
	  begin                                                                            
	    if (M_AXI_ARESETN == 0)                                                       
	      begin                                                                        
	        axi_arvalid <= 1'b0;                                                       
	      end                                                                          
	    //Signal a new read address command is available by user logic                 
	    else if (start_single_read)                                                    
	      begin                                                                        
	        axi_arvalid <= 1'b1;                                                       
	      end                                                                          
	    //RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)    
	    else if (M_AXI_ARREADY && axi_arvalid)                                         
	      begin                                                                        
	        axi_arvalid <= 1'b0;                                                       
	      end                                                                          
	    // retain the previous value                                                   
	  end                                                                              


	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------

	//The Read Data channel returns the results of the read request 
	//The master will accept the read data by asserting axi_rready
	//when there is a valid read data available.
	//While not necessary per spec, it is advisable to reset READY signals in
	//case of differing reset latencies between master/slave.

	  always @(posedge M_AXI_ACLK)                                    
	  begin                                                                 
	    if (M_AXI_ARESETN == 0)                                            
	      begin                                                             
	        axi_rready <= 1'b0;                                             
	      end                                                               
	    // accept/acknowledge rdata/rresp with axi_rready by the master     
	    // when M_AXI_RVALID is asserted by slave                           
	    else if (M_AXI_RVALID && ~axi_rready)                               
	      begin                                                             
	        axi_rready <= 1'b1;                                             
	      end                                                               
	    // deassert after one clock cycle                                   
	    else if (axi_rready)                                                
	      begin                                                             
	        axi_rready <= 1'b0;                                             
	      end                                                               
	    // retain the previous value                                        
	  end                                                                   
	                                                                        
	//Flag write errors                                                     
	assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);  
	
	wire [31:0] FrBAddr, DrBAddr, DpBAddr;
	reg [31:0] DpBAddrHold;
	reg [31:0] FrBVal, DrBVal;
	wire [31:0] DpBVal;
	wire sweep_complete;
	wire start;
	wire [21:0] index_val;
	reg next_addr;
	
	AddressGenerator AG(
        .FrameBufferAddr(FrBAddr),
        .DrawBufferAddr(DrBAddr),
        .DispBufferAddr(DpBAddr),
        .index_val(index_val),
        .FrameBufferAddrBase(FrameBufferBaseAddress),
        .DrawBufferAddrBase(DrawBufferBaseAddress),
        .DispBufferAddrBase(DispBufferBaseAddress),
        .clk(M_AXI_ACLK),
        .rst(M_AXI_ARESETN),
        .next(next_addr),
        .done(sweep_complete)
        );
    LayerMixer LM(
        .FrameBufferValue(FrBVal),
        .DrawBufferValue(DrBVal),
        .DisplayBufferValue(DpBVal)
        );
    PosEdgeDetector PED(
        .clk(M_AXI_ACLK),
        .rst(M_AXI_RESETN),
        .in(ready),
        .out(start)
        );
        
     PixelFilter PF (
        .clk(M_AXI_ACLK),
        .rst(M_AXI_ARESETN),
        .FrameBufferValue(FrBVal),
        .sweep_complete(sweep_complete&done),
        .FrBAddr(FrBAddr),
        .index_val(index_val),
        .threshold(threshold),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .start(start),
        .valid(next_addr)
        );
// ----------------------------------------------------------------------------
//                  M A I N   C O N T R O L   L O G I C
// ----------------------------------------------------------------------------         
         
  always @ ( posedge M_AXI_ACLK)                                                    
  begin                                                                             
    if (M_AXI_ARESETN == 1'b0)                                                     
      begin                                                                         
      // reset condition (same as IDLE)     
        mst_exec_state  <= IDLE;                                            
        start_single_write <= 1'b0;
        start_single_read  <= 1'b0;                                                   
        write_issued  <= 1'b0;                                                                        
        read_issued   <= 1'b0;                                                        
        done <= 1'b1;    
        axi_awaddr <= axi_awaddr;
        axi_wdata <= axi_wdata;    
        axi_araddr <= axi_araddr;  
        FrBVal <= FrBVal;
        DrBVal <= DrBVal;  
        next_addr <= 1'b0;      
        DpBAddrHold <= DpBAddrHold;
//        threshold_reg <= 0;                                          
      end                                                                           
    else                                                                            
      begin                                                                         
       // state transitions                                                          
        case (mst_exec_state)                                                       
                                                                                    
          IDLE: 
          begin                                                            
            // Wait in this state and do nothing
            // until external ready bit is set
            if(start)
              begin
                mst_exec_state  <= READ_FB;
              end
            else
              begin
                mst_exec_state  <= IDLE;    
              end
            done <= 1'b1;                                                                                 
            start_single_write <= 1'b0;
            start_single_read  <= 1'b0;                                                   
            write_issued  <= 1'b0;                                                                        
            read_issued   <= 1'b0;       
            axi_awaddr <= axi_awaddr;
            axi_wdata <= axi_wdata;    
            axi_araddr <= axi_araddr;  
            FrBVal <= FrBVal;
            DrBVal <= DrBVal;
            next_addr <= 1'b0;
            DpBAddrHold <= DpBAddrHold;
//            threshold_reg <= threshold;
          end
              
                                                                                    
          READ_FB:        
          begin                                                       
            // Initiate and wait for completion 
            // of a frame buffer read                                                    
            if (~read_issued) // issue read
              begin
                start_single_read <= 1'b1;
                read_issued <= 1'b1;
                mst_exec_state <= READ_FB;
                FrBVal <= FrBVal;
                axi_araddr <= FrBAddr;
              end
//            else if (axi_rready) // read done, continue 
              else if (M_AXI_RVALID && ~axi_rready)
              begin
                start_single_read <= 1'b0;
                read_issued <= 1'b0;
                mst_exec_state <= READ_DB;
                FrBVal <= M_AXI_RDATA;
                axi_araddr <= axi_araddr;
              end
            else  // waiting for response
              begin
                start_single_read <= 1'b0;
                read_issued <= 1'b1;
                mst_exec_state <= READ_FB;
                FrBVal <= FrBVal;
                axi_araddr <= axi_araddr;
              end
            start_single_write <= 1'b0;
            write_issued <= 1'b0;
            DrBVal <= DrBVal;    
            axi_awaddr <= axi_awaddr;
            axi_wdata <= axi_wdata;  
            done <= 1'b0; 
            next_addr <= 1'b0;
            DpBAddrHold <= DpBAddr;
//            threshold_reg <= threshold_reg;
          end                                                                         
        
                                                                                    
          READ_DB:     
          begin                                                           
            // Initiate and wait for completion 
            // of a draw buffer read                                                    
            if (~read_issued) // issue read
            begin
              start_single_read <= 1'b1;
              read_issued <= 1'b1;
              mst_exec_state <= READ_DB;
              DrBVal <= DrBVal;
              axi_araddr <= DrBAddr;
            end
//            else if (axi_rready) // read done, continue 
            else if (M_AXI_RVALID && ~axi_rready)
            begin
              start_single_read <= 1'b0;
              read_issued <= 1'b0;
              mst_exec_state <= MIXING;
              DrBVal <= M_AXI_RDATA;
              axi_araddr <= axi_araddr;
            end
            else  // waiting for response
            begin
              start_single_read <= 1'b0;
              read_issued <= 1'b1;
              mst_exec_state <= READ_DB;
              DrBVal <= DrBVal;
              axi_araddr <= axi_araddr;
            end
            start_single_write <= 1'b0;
            write_issued <= 1'b0;
            FrBVal <= FrBVal;   
            axi_awaddr <= axi_awaddr;
            axi_wdata <= axi_wdata; 
            done <= 1'b0;
            next_addr <= 1'b0;
            DpBAddrHold <= DpBAddrHold;
//            threshold_reg <= threshold_reg;
          end                                                    


          MIXING: 
          begin                                                               
            // Combine the pixel                                                  
            mst_exec_state <= WRITE;
            start_single_read <= 1'b0;
            read_issued <= 1'b0;
            start_single_write <= 1'b0;
            write_issued <= 1'b0;
            FrBVal <= FrBVal;
            DrBVal <= DrBVal;
            axi_araddr <= axi_araddr;
            axi_awaddr <= axi_awaddr;
            axi_wdata <= axi_wdata;
            done <= 1'b0;
            DpBAddrHold <= DpBAddrHold;
            next_addr <= 1'b1; // get next address
//            threshold_reg <= threshold_reg;
          end
          
          
          WRITE:   
          begin                                                             
            // Write the pixel back to
            // display buffer
            if (~write_issued) // issue read
            begin
              start_single_write <= 1'b1;
              write_issued <= 1'b1;
              mst_exec_state <= WRITE;
              axi_awaddr <= DpBAddrHold;
              axi_wdata <= DpBVal;
              done <= 1'b0;
            end
            else if (axi_bready) // read done, continue 
            begin
              if (sweep_complete)
                begin
                  mst_exec_state <= IDLE;
                  done <= 1'b1;
                end
              else
                begin
                  mst_exec_state <= READ_FB;
                  done <= 1'b0;
                end
              start_single_write <= 1'b0;
              write_issued <= 1'b0;
              axi_awaddr <= axi_awaddr;
              axi_wdata <= axi_wdata;
            end
            else  // waiting for response
            begin
              start_single_write <= 1'b0;
              write_issued <= 1'b1;
              mst_exec_state <= WRITE;
              axi_awaddr <= axi_awaddr;
              axi_wdata <= axi_wdata;
              done <= 1'b0;
            end
            axi_araddr <= axi_araddr;
            start_single_read <= 1'b0;
            read_issued <= 1'b0;
            FrBVal <= FrBVal;
            DrBVal <= DrBVal;  
//            done <= 1'b0;
            next_addr <= 1'b0;
            DpBAddrHold <= DpBAddrHold;
//            threshold_reg <= threshold_reg;
          end                                    
          
      
          default :     
          begin                                                                                                                             
            mst_exec_state  <= IDLE;                                            
            start_single_write <= 1'b0;
            start_single_read  <= 1'b0;                                                   
            write_issued  <= 1'b0;                                                                        
            read_issued   <= 1'b0;                                                      
            done <= 1'b1;    
            axi_awaddr <= axi_awaddr;
            axi_wdata <= axi_wdata;    
            axi_araddr <= axi_araddr;  
            FrBVal <= FrBVal;
            DrBVal <= DrBVal;  
            next_addr <= 1'b0; 
            DpBAddrHold <= DpBAddrHold; 
//            threshold_reg <= threshold_reg;
          end      
          
                                                 
        endcase                                                                     
    end                                                                             
  end // MASTER CONTROL LOGIC                                                 

endmodule
