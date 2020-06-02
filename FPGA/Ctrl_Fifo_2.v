module Ctrl_Fifo_2
( input             MemClk,
  input             SlowMemClk,
  output reg [18:0] P1_Address,
  input  [127:0]    P1_DataRead,
  input             ScreenStop,
  input             Reset,
  input  [35:0]     BLKREQ_data,
  input             BLKREQ_wrreq,
  output            BLKREQ_wrfull,
  output [135:0]    BLKANS_q,
  input             BLKANS_rdreq,
  output            BLKANS_rdempty,
  input  [35:0]     PIXREQ_data,
  input             PIXREQ_wrreq,
  output            PIXREQ_wrfull,
  output [135:0]    PIXANS_q,
  input             PIXANS_rdreq,
  output            PIXANS_rdempty
);

  wire        FIFOCLEAR;
  assign FIFOCLEAR = ((ScreenStop == 1'b1) || (Reset == 1'b0)) ? 1'b1 : 1'b0;

  reg          BLKREQ_rdreq;
  wire [35:0]  BLKREQ_q;
  wire         BLKREQ_rdempty;
  reg  [135:0] BLKANS_data;
  reg          BLKANS_wrreq;
  wire         BLKANS_wrfull;

  REQ_FIFO     BLKREQ(.aclr(FIFOCLEAR),    .rdclk(SlowMemClk),       .wrclk(MemClk),            
                      .rdreq(BLKREQ_rdreq), .rdempty(BLKREQ_rdempty), .q(BLKREQ_q),
                      .wrreq(BLKREQ_wrreq), .wrfull(BLKREQ_wrfull),   .data(BLKREQ_data));								 

  ANS_FIFO     BLKANS(.aclr(FIFOCLEAR),    .rdclk(MemClk),           .wrclk(SlowMemClk),       
                      .rdreq(BLKANS_rdreq), .rdempty(BLKANS_rdempty), .q(BLKANS_q),    
                      .wrreq(BLKANS_wrreq), .wrfull(BLKANS_wrfull),   .data(BLKANS_data));

  reg          PIXREQ_rdreq;
  wire [35:0]  PIXREQ_q;
  wire         PIXREQ_rdempty;
  reg  [135:0] PIXANS_data;
  reg          PIXANS_wrreq;
  wire         PIXANS_wrfull;

  REQ_FIFO     PIXREQ(.aclr(FIFOCLEAR),    .rdclk(SlowMemClk),       .wrclk(MemClk),            
                      .rdreq(PIXREQ_rdreq), .rdempty(PIXREQ_rdempty), .q(PIXREQ_q),
                      .wrreq(PIXREQ_wrreq), .wrfull(PIXREQ_wrfull),   .data(PIXREQ_data));								 

  ANS_FIFO     PIXANS(.aclr(FIFOCLEAR),    .rdclk(MemClk),           .wrclk(SlowMemClk),       
                      .rdreq(PIXANS_rdreq), .rdempty(PIXANS_rdempty), .q(PIXANS_q),    
                      .wrreq(PIXANS_wrreq), .wrfull(PIXANS_wrfull),   .data(PIXANS_data));

  reg [1:0]   MemFlag;
  reg [7:0]   MemAux;  
  reg         PIX_Pending;
  reg [135:0] PIX_Value;
  reg         BLK_Pending;
  reg [135:0] BLK_Value;
  reg         PIXREQ_Pending;
  reg         BLKREQ_Pending;
							 
  always @(negedge SlowMemClk)
    begin
	   if ((ScreenStop == 1'b1) || (Reset == 1'b0))
		   begin
			  BLKREQ_rdreq = 1'b0;
			  BLKANS_wrreq = 1'b0;
			  PIXREQ_rdreq = 1'b0;
			  PIXANS_wrreq = 1'b0;
			  PIX_Pending = 1'b0;
			  BLK_Pending = 1'b0;
			  PIXREQ_Pending = 1'b0;
			  BLKREQ_Pending = 1'b0;
			  MemFlag = 2'b00;
			end
		else begin
		       if (PIX_Pending == 1'b1)
				    begin
					   if (PIXANS_wrfull == 1'b1) 
						   begin
							  PIX_Pending = 1'b1;
							  PIXANS_wrreq = 1'b0;
							end
						else begin
						       PIX_Pending = 1'b0;
								 PIXANS_wrreq = 1'b1;
								 PIXANS_data = PIX_Value;
						     end
					 end
				 else begin
				        if (MemFlag == 2'b10)
						     begin
							    if (PIXANS_wrfull == 1'b1)
								    begin
									   PIX_Pending = 1'b1;
										PIXANS_wrreq = 1'b0;
										PIX_Value = {MemAux,P1_DataRead};
									 end
								 else
								    begin
									   PIX_Pending = 1'b0;
										PIXANS_wrreq = 1'b1;
										PIXANS_data = {MemAux,P1_DataRead};
									 end
							  end
						  else
					        begin
							    PIX_Pending = 1'b0;
								 PIXANS_wrreq = 1'b0;
						     end	  
				      end
		       if (BLK_Pending == 1'b1)
				    begin
					   if (BLKANS_wrfull == 1'b1) 
						   begin
							  BLK_Pending = 1'b1;
							  BLKANS_wrreq = 1'b0;
							end
						else begin
						       BLK_Pending = 1'b0;
								 BLKANS_wrreq = 1'b1;
								 BLKANS_data = BLK_Value;
						     end
					 end
				 else begin
				        if (MemFlag == 2'b11)
						     begin
							    if (BLKANS_wrfull == 1'b1)
								    begin
									   BLK_Pending = 1'b1;
										BLKANS_wrreq = 1'b0;
										BLK_Value = {MemAux,P1_DataRead};
									 end
								 else
								    begin
									   BLK_Pending = 1'b0;
										BLKANS_wrreq = 1'b1;
										BLKANS_data = {MemAux,P1_DataRead};
									 end
							  end
						  else
					        begin
							    BLK_Pending = 1'b0;
								 BLKANS_wrreq = 1'b0;
						     end	  
				      end
				 if (PIXREQ_Pending == 1'b1)
				    begin
					   if ((PIXANS_wrfull == 1'b0) && (PIX_Pending == 1'b0))
						   begin
							  P1_Address = PIXREQ_q[18:0];
							  MemAux = PIXREQ_q[26:19];
							  MemFlag = 2'b10;
							  PIXREQ_Pending = 1'b0;
							end
					   else PIXREQ_Pending = 1'b1;
					 end
		       else if (PIXREQ_rdreq == 1'b1)
				         begin
					        if ((PIXANS_wrfull == 1'b0) && (PIX_Pending == 1'b0))
						        begin
							       P1_Address = PIXREQ_q[18:0];
							       MemAux = PIXREQ_q[26:19];
							       MemFlag = 2'b10;
							       PIXREQ_Pending = 1'b0;
							     end
					        else PIXREQ_Pending = 1'b1;
					      end
				      else begin
						       if (BLKREQ_Pending == 1'b1)
								    begin
					               if ((BLKANS_wrfull == 1'b0) && (BLK_Pending == 1'b0))
						               begin
							              P1_Address = BLKREQ_q[18:0];
							              MemAux = BLKREQ_q[26:19];
							              MemFlag = 2'b11;
							              BLKREQ_Pending = 1'b0;
							            end
					               else BLKREQ_Pending = 1'b1;
									 end
				             else if (BLKREQ_rdreq == 1'b1)
						               begin
					                    if ((BLKANS_wrfull == 1'b0) && (BLK_Pending == 1'b0))
						                    begin
							                   P1_Address = BLKREQ_q[18:0];
							                   MemAux = BLKREQ_q[26:19];
							                   MemFlag = 2'b11;
							                   BLKREQ_Pending = 1'b0;
							                 end
					                    else BLKREQ_Pending = 1'b1;
							            end
						            else begin
										       PIXREQ_Pending = 1'b0;
												 BLKREQ_Pending = 1'b0;
						                   MemFlag = 2'b00;
						                 end
			              end	 
		       if ((PIXREQ_rdempty == 1'b0) && (PIXANS_wrfull == 1'b0) && (PIX_Pending == 1'b0) && (PIXREQ_Pending == 1'b0)) PIXREQ_rdreq = 1'b1;
				 else PIXREQ_rdreq = 1'b0;
				 if ((BLKREQ_rdempty == 1'b0) && (BLKANS_wrfull == 1'b0) && (BLK_Pending == 1'b0) && (BLKREQ_Pending == 1'b0) && (PIXREQ_Pending == 1'b0) && (PIXREQ_rdreq == 1'b0)) BLKREQ_rdreq = 1'b1;
				 else BLKREQ_rdreq = 1'b0;
 		     end
    end	 
								 
endmodule
