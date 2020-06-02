module Palette
( input             MemClk,
  input             ScreenStop,
  input             Reset,
  input [7:0]       PIX_data,
  input             PIX_wrreq,
  output            PIX_wrfull,
  input             FF_wrfull,
  output reg [23:0] FF_data,
  output reg        FF_wrreq,
  input [23:0]      PAL_data,
  input [7:0]       PAL_wraddress,
  input             PAL_wren
);

  wire [7:0]  PIX_q;
  wire        PIX_rdempty;
  reg         PIX_rdreq;
  reg  [7:0]  PAL_rdaddress;
  wire [31:0] PAL_q;
  wire        FIFOCLEAR;
  
  assign FIFOCLEAR = ((ScreenStop == 1'b1) || (Reset == 1'b0)) ? 1'b1 : 1'b0;

  PALETTE_RAM PAL(.clock(MemClk), .data({8'h00,PAL_data}), .rdaddress(PAL_rdaddress), .wraddress(PAL_wraddress), .wren(PAL_wren), .q(PAL_q));
  
  PIX_FIFO PIX(.aclr(FIFOCLEAR), .clock(MemClk), .data(PIX_data), .rdreq(PIX_rdreq), .wrreq(PIX_wrreq), 
               .empty(PIX_rdempty), .full(PIX_wrfull), .q(PIX_q));

  reg [7:0] PIX_Data;
  reg       PIX_Valid;
  reg       PIX_Pending;

  always @(negedge MemClk)
    begin
	   if (FF_wrfull == 1'b1)
		   begin
			  if (PIX_Pending == 1'b0) PIX_Pending = PIX_rdreq;
			  else PIX_Pending = PIX_Pending;
			  PIX_rdreq = 1'b0;
			end
		else begin
		       if ((PIX_Pending == 1'b1) || (PIX_rdreq == 1'b1))
				    begin
					   PIX_Data = PIX_q;
						PIX_Valid = 1'b1;
						PIX_Pending = 1'b0;
					 end
				 else PIX_Valid = 1'b0;
				 PIX_rdreq = !PIX_rdempty;
		     end
    end	 

  reg PAL_Valid;
	 
  always @(negedge MemClk)
    begin
	   if (FF_wrfull == 1'b0)
	      begin
	        PAL_rdaddress = PIX_Data;
		     PAL_Valid = PIX_Valid;
			end
    end

  always @(negedge MemClk)
    begin
	   if ((FF_wrfull == 1'b0) && (PAL_Valid == 1'b1))
	      begin
	        FF_data = PAL_q[23:0];
		     FF_wrreq = 1'b1;
			end
		else FF_wrreq = 1'b0;
    end
	 
endmodule
