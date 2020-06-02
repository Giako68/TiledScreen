module Mode8bppTiled
( input             MemClk,
  input             ScreenStop,
  input             Reset,
  input [22:0]      BaseAddress,
  input [15:0]      DeltaAddress,
  input [22:0]      TileAddress,
  input [3:0]       Yoffset,
  input [3:0]       Xoffset,
  output reg [35:0] BLKREQ_data,
  output reg        BLKREQ_wrreq,
  input             BLKREQ_wrfull,
  input [135:0]     BLKANS_q,
  output reg        BLKANS_rdreq,
  input             BLKANS_rdempty,
  output reg [35:0] PIXREQ_data,
  output reg        PIXREQ_wrreq,
  input             PIXREQ_wrfull,
  input [135:0]     PIXANS_q,
  output reg        PIXANS_rdreq,
  input             PIXANS_rdempty,
  output reg [7:0]  PIX_data,
  output reg        PIX_wrreq,
  input             PIX_wrfull
);

  /****************************************************************************
    Tiles Request
  ****************************************************************************/

  reg [2:0]  BLK_Status;
  reg [1:0]  BLK_Num;
  reg [4:0]  BLK_Row;
  reg [22:0] BLK_RowAddress;
  reg [22:0] BLK_Delta;
  reg [18:0] BLK_Address;

  always @(negedge MemClk)
    begin
	   if ((ScreenStop == 1'b1) || (Reset == 1'b0))
		   begin
			  BLKREQ_wrreq = 1'b0;
			  BLK_Status = 3'h0;
			end
		else begin
		       case(BLK_Status)
				   3'h0: begin
					        BLK_RowAddress = BaseAddress;
							  BLK_Delta = {7'h0,DeltaAddress};
					        BLK_Address = BLK_RowAddress[22:4];
							  BLK_Num = 2'h0;
							  BLK_Row = 5'h00;
							  BLKREQ_wrreq = 1'b0;
							  BLK_Status = 3'h1;
					      end
				   3'h1: begin
					        if (BLKREQ_wrfull == 1'b1) 
							     begin
								    BLKREQ_wrreq = 1'b0;
								    BLK_Status = 3'h1;
								  end
							  else begin
							         BLKREQ_data = {11'h000,BLK_Num,BLK_RowAddress[3:0],BLK_Address};
							         BLKREQ_wrreq = 1'b1;
								      BLK_Status = 3'h2;
							       end
					      end
				   3'h2: begin
					        BLKREQ_wrreq = 1'b0;
							  BLK_Address = BLK_Address + 19'h00001;
							  if (BLK_Num == 2'h3)
							     begin
								    BLK_Num = 2'h0;
								    BLK_Status = 3'h3;
								  end
							  else begin
							         BLK_Num = BLK_Num + 2'h1;
										BLK_Status = 3'h1;
							       end
					      end
				   3'h3: begin
					        if (BLK_Row == 5'h17) BLK_Status = 3'h7;
							  else
							     begin
								    BLK_RowAddress = BLK_RowAddress + 23'h00028 + BLK_Delta;
					             BLK_Address = BLK_RowAddress[22:4];
								    BLK_Row = BLK_Row + 5'h01;
									 BLK_Status = 3'h1;
								  end
					      end
				   3'h7: begin
					        BLK_Status = 3'h7;
					      end
					default: BLK_Status = 3'h7;
				 endcase
		     end
	 end

  /****************************************************************************
    Tiles Scan and Pixel Request
  ****************************************************************************/

  reg [2:0]   TIL_Status;
  reg         TIL_FirstRow;
  reg [3:0]   TIL_Row;
  reg [511:0] TIL_Buffer;
  reg [3:0]   TIL_Skip;
  reg [5:0]   TIL_Num;
  reg [3:0]   TIL_Y;
  reg [6:0]   TIL_TA;
	 
  always @(negedge MemClk)
    begin
	   if ((ScreenStop == 1'b1) || (Reset == 1'b0))
		   begin
			  BLKANS_rdreq = 1'b0;
			  PIXREQ_wrreq = 1'b0;
			  TIL_Status = 3'h0;
			end
		else begin
		       case(TIL_Status)
				   3'h0: begin
					        TIL_FirstRow = 1'b1;
							  TIL_Row = 4'h0;
							  TIL_Y = Yoffset;
							  TIL_TA = TileAddress[22:16];
							  BLKANS_rdreq = 1'b0;
							  PIXREQ_wrreq = 1'b0;
							  TIL_Status = 3'h1;
					      end
				   3'h1: begin
					        if (BLKANS_rdempty == 1'b1) 
							     begin
								    BLKANS_rdreq = 1'b0;
								    TIL_Status = 3'h1;
								  end
							  else begin
							         BLKANS_rdreq = 1'b1;
								      TIL_Status = 3'h2;
							       end
					      end
				   3'h2: begin
					        BLKANS_rdreq = 1'b0;
							  case(BLKANS_q[133:132])
							    2'b00: begin
								          TIL_Buffer[511:384] = BLKANS_q[127:0];
											 TIL_Status = 3'h1;
								        end
							    2'b01: begin
								          TIL_Buffer[383:256] = BLKANS_q[127:0];
											 TIL_Status = 3'h1;
								        end
							    2'b10: begin
								          TIL_Buffer[255:128] = BLKANS_q[127:0];
											 TIL_Status = 3'h1;
								        end
							    2'b11: begin
								          TIL_Buffer[127:0] = BLKANS_q[127:0];
											 TIL_Skip = BLKANS_q[131:128];
											 TIL_Status = 3'h3;
								        end
							  endcase
					      end
				   3'h3: begin
					        if (TIL_Skip == 4'h0) 
							     begin
								    TIL_Num = 6'h00;
									 TIL_Row = (TIL_FirstRow == 1'b1) ? TIL_Y : 4'h0;
								    TIL_Status = 3'h4;
								  end
							  else begin
							         TIL_Buffer = {TIL_Buffer[503:0],8'h00};
										TIL_Skip = TIL_Skip - 4'h1;
										TIL_Status = 3'h3;
							       end
					      end
				   3'h4: begin
					        if (PIXREQ_wrfull == 1'b1) 
							     begin
								    PIXREQ_wrreq = 1'b0;
								    TIL_Status = 3'h4;
								  end
							  else begin
							         PIXREQ_data = {11'h000,TIL_Num,TIL_TA,TIL_Buffer[511:504],TIL_Row};
										PIXREQ_wrreq = 1'b1;
										TIL_Status = 3'h5;
							       end
					      end
				   3'h5: begin
					        TIL_Buffer = {TIL_Buffer[503:184],TIL_Buffer[511:504],184'h0};
							  PIXREQ_wrreq = 1'b0;
							  if (TIL_Num == 6'h28)
							     begin
								    TIL_Num = 6'h00;
									 TIL_Status = 3'h6;
								  end
							  else begin
							         TIL_Num = TIL_Num + 6'h01;
										TIL_Status = 3'h4;
							       end
					      end
				   3'h6: begin
					        if (TIL_Row == 4'hF) 
							     begin
								    TIL_FirstRow = 1'b0;
									 TIL_Row = 4'h0;
								    TIL_Status = 3'h1;
								  end
							  else begin
							         TIL_Row = TIL_Row + 4'h1;
										TIL_Status = 3'h4;
							       end
					      end
				   3'h7: begin
					        TIL_Status = 3'h7;
					      end
					default: TIL_Status = 3'h7;
				 endcase
		     end
	 end
	 
  /****************************************************************************
    Pixel Dispatch
  ****************************************************************************/

  reg [2:0]   PIX_Status;
  reg [127:0] PIX_Buffer;
  reg [3:0]   PIX_X;
  reg [3:0]   PIX_Num;
  reg [3:0]   PIX_Skip;
  reg [5:0]   PIX_Blk;
  
  always @(negedge MemClk)
    begin
	   if ((ScreenStop == 1'b1) || (Reset == 1'b0))
		   begin
			  PIXANS_rdreq = 1'b0;
			  PIX_wrreq = 1'b0;
			  PIX_Status = 3'h0;
			end
		else begin
		       case(PIX_Status)
				   3'h0: begin
					        PIX_X = Xoffset;
							  PIXANS_rdreq = 1'b0;
							  PIX_wrreq = 1'b0;
							  PIX_Status = 3'h1;
					      end
				   3'h1: begin
					        if (PIXANS_rdempty == 1'b1)
							     begin
								    PIXANS_rdreq = 1'b0;
									 PIX_Status = 3'h1;
								  end
							  else begin
							         PIXANS_rdreq = 1'b1;
									   PIX_Status = 3'h2;
							       end
					      end
				   3'h2: begin
					        PIXANS_rdreq = 1'b0;
							  PIX_Buffer = PIXANS_q[127:0];
							  PIX_Blk = PIXANS_q[133:128];
							  PIX_Num = 4'h0;
							  if (PIX_Blk == 6'h00) 
							     begin
								    PIX_Skip = PIX_X;
								    PIX_Status = 3'h3;
								  end
							  else if (PIX_Blk == 6'h28) PIX_Status = 3'h6;
							       else PIX_Status = 3'h4;
					      end
				   3'h3: begin
					        if (PIX_Skip == 4'h0) PIX_Status = 3'h4;
							  else begin
							         PIX_Skip = PIX_Skip - 4'h1;
										PIX_Num = PIX_Num + 4'h1;
										PIX_Buffer = {PIX_Buffer[119:0],8'h00};
										PIX_Status = 3'h3;
							       end
					      end
				   3'h4: begin
					        if (PIX_wrfull == 1'b1)
							     begin
								    PIX_wrreq = 1'b0;
									 PIX_Status = 3'h4;
								  end
							  else begin
							         PIX_data = PIX_Buffer[127:120];
										PIX_wrreq = 1'b1;
									   PIX_Status = 3'h5;
							       end
					      end
				   3'h5: begin
					        PIX_wrreq = 1'b0;
							  PIX_Buffer = {PIX_Buffer[119:0],8'h00};
							  if (PIX_Num == 4'hF) 
							     begin
								    PIX_Num = 4'h0;
								    PIX_Status = 3'h1;
								  end
							  else begin
							         PIX_Num = PIX_Num + 4'h1;
										PIX_Status = 3'h4;
							       end
					      end
				   3'h6: begin
					        if (PIX_X == 4'h0) PIX_Status = 3'h1;
							  else begin
							         PIX_Num = 4'h0 - PIX_X;
										PIX_Status = 3'h4;
							       end
					      end
				   3'h7: begin
					        PIX_Status = 3'h7;
					      end
					default: PIX_Status = 3'h7;
				 endcase
		     end
	 end
  

endmodule
