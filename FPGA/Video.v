module Video
( input Clk_48MHz,
  output [3:0] tmds_out_p,
  output [3:0] tmds_out_n,
  inout [15:0] SDRAM_D,
  output [1:0] SDRAM_BA,
  output [11:0] SDRAM_A,
  output SDRAM_CK,
  output SDRAM_CKE,
  output SDRAM_CS,
  output SDRAM_CAS,
  output SDRAM_RAS,
  output SDRAM_WE,
  output SDRAM_LDQM,
  output SDRAM_UDQM
);

  wire         PixClk;
  wire         PixClk5;
  wire         MemClk;
  wire         SlowMemClk;
  reg          ScreenStop;
  wire         SS0;
  reg          SS1;
  wire         FF_wrfull;
  wire [23:0]  FF_data;
  wire         FF_wrreq;
  wire [18:0]  P1_Address;
  wire [127:0] P1_DataRead;
  wire [35:0]  BLKREQ_data;
  wire         BLKREQ_wrreq;
  wire         BLKREQ_wrfull;
  wire [135:0] BLKANS_q;
  wire         BLKANS_rdreq;
  wire         BLKANS_rdempty;
  wire [35:0]  PIXREQ_data;
  wire         PIXREQ_wrreq;
  wire         PIXREQ_wrfull;
  wire [135:0] PIXANS_q;
  wire         PIXANS_rdreq;
  wire         PIXANS_rdempty;
  wire         Reset;
  wire [21:0]  P0_Address;
  wire [1:0]   P0_DQmask;
  wire [15:0]  P0_DataWrite;
  wire [15:0]  P0_DataRead;
  wire [7:0]   PAL_wraddress;
  wire [23:0]  PAL_data;
  wire         PAL_wren;
  wire [22:0]  BaseAddress;
  wire [15:0]  DeltaAddress;
  wire [7:0]   PIX_data;
  wire         PIX_wrreq;
  wire         PIX_wrfull;
  wire [22:0]  TileAddress;
  wire [3:0]   Yoffset;
  wire [3:0]   Xoffset;
  wire         Blank;
  wire [23:0]  BlankColor;
  
  DVI_PLL             ClockDVI(.inclk0(Clk_48MHz), .c0(MemClk), .c1(PixClk5), .c2(PixClk));
  
  DVI_Out             DVI(.PixClk(PixClk),   .PixClk5(PixClk5), .tmds_out_p(tmds_out_p), .tmds_out_n(tmds_out_n), 
                          .ScreenStop(SS0),  .Reset(Reset),     .Blank(Blank),           .BlankColor(BlankColor),
                          .FF_wrclk(MemClk), .FF_data(FF_data), .FF_wrreq(FF_wrreq),     .FF_wrfull(FF_wrfull));

  SDRAM_StatusMachine SM(.MemClk(MemClk), .Reset(Reset), .SlowMemClk(SlowMemClk),
								 .P0_Address(P0_Address), .P0_DQmask(P0_DQmask), .P0_DataWrite(P0_DataWrite), .P0_DataRead(P0_DataRead), 
								 .P1_Address(P1_Address), .P1_DataRead(P1_DataRead), 
								 .SDRAM_D(SDRAM_D), .SDRAM_BA(SDRAM_BA),
							 	 .SDRAM_A(SDRAM_A), .SDRAM_CK(SDRAM_CK), .SDRAM_CKE(SDRAM_CKE), .SDRAM_CS(SDRAM_CS), .SDRAM_CAS(SDRAM_CAS),
								 .SDRAM_RAS(SDRAM_RAS), .SDRAM_WE(SDRAM_WE), .SDRAM_LDQM(SDRAM_LDQM), .SDRAM_UDQM(SDRAM_UDQM));

  JTAG_PortAdapter    JPA(.Clk_143MHz(MemClk), .Reset(Reset), .SlowMemClk(SlowMemClk), .MemClk(MemClk), .Blank(Blank), .BlankColor(BlankColor),
                          .P0_Address(P0_Address),   .P0_DQmask(P0_DQmask),       .P0_DataWrite(P0_DataWrite), .P0_DataRead(P0_DataRead),
								  .BaseAddress(BaseAddress), .DeltaAddress(DeltaAddress),
								  .TileAddress(TileAddress), .Yoffset(Yoffset),           .Xoffset(Xoffset),
								  .PAL_data(PAL_data),       .PAL_wraddress(PAL_wraddress), .PAL_wren(PAL_wren));
			
/*  Ctrl_Fifo_1         CTRL(.MemClk(MemClk),         .SlowMemClk(SlowMemClk), .P1_Address(P1_Address), .P1_DataRead(P1_DataRead),
                           .ScreenStop(ScreenStop), .REQ_data(REQ_data),     .REQ_wrreq(REQ_wrreq),   .REQ_wrfull(REQ_wrfull),
									.ANS_q(ANS_q),           .ANS_rdreq(ANS_rdreq),   .ANS_rdempty(ANS_rdempty));
*/
				  
  Ctrl_Fifo_2         CTRL(.MemClk(MemClk),           .SlowMemClk(SlowMemClk),     .P1_Address(P1_Address), .P1_DataRead(P1_DataRead),
                           .ScreenStop(ScreenStop),   .Reset(Reset),
									.BLKREQ_data(BLKREQ_data), .BLKREQ_wrreq(BLKREQ_wrreq), .BLKREQ_wrfull(BLKREQ_wrfull),
									.BLKANS_q(BLKANS_q),       .BLKANS_rdreq(BLKANS_rdreq), .BLKANS_rdempty(BLKANS_rdempty),
									.PIXREQ_data(PIXREQ_data), .PIXREQ_wrreq(PIXREQ_wrreq), .PIXREQ_wrfull(PIXREQ_wrfull),
									.PIXANS_q(PIXANS_q),       .PIXANS_rdreq(PIXANS_rdreq), .PIXANS_rdempty(PIXANS_rdempty));
				  
/*  Mode16bpp           MODE(.MemClk(MemClk), .ScreenStop(ScreenStop), .BaseAddress(BaseAddress), .DeltaAddress(DeltaAddress),
                           .REQ_data(REQ_data), .REQ_wrreq(REQ_wrreq), .REQ_wrfull(REQ_wrfull),
                           .ANS_q(ANS_q), .ANS_rdreq(ANS_rdreq), .ANS_rdempty(ANS_rdempty),
									.FF_data(FF_data), .FF_wrreq(FF_wrreq), .FF_wrfull(FF_wrfull));
*/

  Palette             PAL(.MemClk(MemClk),       .ScreenStop(ScreenStop),       .Reset(Reset),
                          .PIX_data(PIX_data),   .PIX_wrreq(PIX_wrreq),         .PIX_wrfull(PIX_wrfull),
                          .FF_wrfull(FF_wrfull), .FF_data(FF_data),             .FF_wrreq(FF_wrreq),
                          .PAL_data(PAL_data),   .PAL_wraddress(PAL_wraddress), .PAL_wren(PAL_wren));
				  
/*  Mode8bpp            MODE(.MemClk(MemClk), .ScreenStop(ScreenStop), .BaseAddress(BaseAddress), .DeltaAddress(DeltaAddress),
                           .REQ_data(REQ_data), .REQ_wrreq(REQ_wrreq), .REQ_wrfull(REQ_wrfull),
                           .ANS_q(ANS_q), .ANS_rdreq(ANS_rdreq), .ANS_rdempty(ANS_rdempty),
									.PIX_data(PIX_data), .PIX_wrreq(PIX_wrreq), .PIX_wrfull(PIX_wrfull));
*/
				  
  Mode8bppTiled       MODE(.MemClk(MemClk),           .ScreenStop(ScreenStop),     .Reset(Reset),
                           .BaseAddress(BaseAddress), .DeltaAddress(DeltaAddress),
                           .TileAddress(TileAddress), .Yoffset(Yoffset),           .Xoffset(Xoffset),
                           .BLKREQ_data(BLKREQ_data), .BLKREQ_wrreq(BLKREQ_wrreq), .BLKREQ_wrfull(BLKREQ_wrfull),
									.BLKANS_q(BLKANS_q),       .BLKANS_rdreq(BLKANS_rdreq), .BLKANS_rdempty(BLKANS_rdempty),
									.PIXREQ_data(PIXREQ_data), .PIXREQ_wrreq(PIXREQ_wrreq), .PIXREQ_wrfull(PIXREQ_wrfull),
									.PIXANS_q(PIXANS_q),       .PIXANS_rdreq(PIXANS_rdreq), .PIXANS_rdempty(PIXANS_rdempty),
									.PIX_data(PIX_data),       .PIX_wrreq(PIX_wrreq),       .PIX_wrfull(PIX_wrfull));

  always @(posedge MemClk)
    begin
	   {ScreenStop,SS1} = {SS1,SS0};
    end	 
			
endmodule
