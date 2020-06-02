// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module DVI_Out
( input        PixClk,
  input        PixClk5,
  output [3:0] tmds_out_p,
  output [3:0] tmds_out_n,
  output       ScreenStop,
  input        Reset,
  input        Blank,
  input [23:0] BlankColor,
  input        FF_wrclk,
  input [23:0] FF_data,
  input        FF_wrreq,
  output       FF_wrfull
);

  wire        HSync;
  wire        VSync;
  wire        Video;
  wire [9:0]  encRed;
  wire [9:0]  encGreen;
  wire [9:0]  encBlue;
  wire [3:0]  tmds_out;
  reg  [23:0] Pixel;
  reg         HS0;
  reg         VS0;
  reg         VE0;
  reg         HS1;
  reg         VS1;
  reg         VE1;
  reg         FF_rdreq;
  wire [23:0] FF_q;
  wire        FF_rdempty;
  reg         VideoDisable;
  reg [23:0]  EmptyColor;
  
  Syncro          SYN(.PixClk(PixClk), .HSync(HSync), .VSync(VSync), .Video(Video));
  
  TMDS_encoder    ENC(.inRed(Pixel[23:16]), .inGreen(Pixel[15:8]), .inBlue(Pixel[7:0]), .Hsync(HS1), .Vsync(VS1), .PixClk(PixClk), 
                      .Video(VE1), .outRed(encRed), .outGreen(encGreen), .outBlue(encBlue));
							 
  TMDS_Serializer SER(.RedEncoded(encRed), .BlueEncoded(encBlue), .GreenEncoded(encGreen), 
                      .PixClk(PixClk), .PixClk5(PixClk5), .TMDS(tmds_out));
							 
  DiffBuf         B_DB(.datain(tmds_out[0]), .dataout(tmds_out_p[0]), .dataout_b(tmds_out_n[0]));							 
  DiffBuf         G_DB(.datain(tmds_out[1]), .dataout(tmds_out_p[1]), .dataout_b(tmds_out_n[1]));							 
  DiffBuf         R_DB(.datain(tmds_out[2]), .dataout(tmds_out_p[2]), .dataout_b(tmds_out_n[2]));							 
  DiffBuf         C_DB(.datain(tmds_out[3]), .dataout(tmds_out_p[3]), .dataout_b(tmds_out_n[3]));							 

  wire        FIFOCLEAR;
  assign FIFOCLEAR = ((ScreenStop == 1'b1) || (Reset == 1'b0)) ? 1'b1 : 1'b0;
  
  DVI_FIFO        FF(.aclr(FIFOCLEAR), .data(FF_data), .rdclk(PixClk), .rdreq(FF_rdreq), .wrclk(FF_wrclk), .wrreq(FF_wrreq), .q(FF_q), 
                     .rdempty(FF_rdempty), .wrfull(FF_wrfull));

  assign ScreenStop = !VSync;
  
  always @(posedge ScreenStop)
    begin
	   VideoDisable = Blank;
		EmptyColor = BlankColor;
    end	 
					
  always @(negedge PixClk)
    begin
	   HS0 = HSync;
		VS0 = VSync;
		VE0 = Video;
		FF_rdreq = (FF_rdempty == 1'b1) ? 1'b0 : Video;
	 end
	 
  always @(negedge PixClk)
    begin
	   HS1 = HS0;
		VS1 = VS0;
		VE1 = VE0;
		Pixel = ((FF_rdreq == 1'b1) && (VideoDisable == 1'b0)) ? FF_q : EmptyColor;
	 end

endmodule
