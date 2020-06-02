module JTAG_PortAdapter
( input              Clk_143MHz,
  output             Reset, 
  input              SlowMemClk,
  input              MemClk,
  output             Blank,
  output [23:0]      BlankColor,
  output reg [21:0]  P0_Address, 
  output reg [1:0]   P0_DQmask,
  output reg [15:0]  P0_DataWrite, 
  input      [15:0]  P0_DataRead,
  output [22:0]      BaseAddress,
  output [15:0]      DeltaAddress,
  output [22:0]      TileAddress,
  output [3:0]       Yoffset,
  output [3:0]       Xoffset,
  output [23:0]      PAL_data,
  output [7:0]       PAL_wraddress,
  output             PAL_wren
  
);

  wire tck;
  wire tdi;
  wire [3:0] ir_in;
  wire vJTAG_cdr;
  wire vJTAG_sdr;
  wire vJTAG_udr;
  wire vJTAG_e1dr;
  wire vJTAG_pdr;
  wire tdo;

  MyJTAG JT(.tdi(tdi), .tdo(tdo), .ir_in(ir_in), .ir_out(), .virtual_state_cdr(vJTAG_cdr), .virtual_state_sdr(vJTAG_sdr),
            .virtual_state_e1dr(vJTAG_e1dr), .virtual_state_pdr(vJTAG_pdr), .virtual_state_e2dr(), .virtual_state_udr(vJTAG_udr), .virtual_state_cir(),
				.virtual_state_uir(), .tck(tck));
				
  localparam VIR_BYPASS  = 4'b0000;
  localparam VIR_CTRL    = 4'b0001;
  localparam VIR_0OUTPUT = 4'b0010;
  localparam VIR_0INPUT  = 4'b0011;
  localparam VIR_FWADDR  = 4'b0100;
  localparam VIR_FWDATA  = 4'b0101;
  localparam VIR_GEOM    = 4'b0110;
  localparam VIR_BKCOLOR = 4'b0111;
  localparam VIR_PALETTE = 4'b1000;
  localparam VIR_DEBUG   = 4'b1111;
  
  reg         sh_BYPASS;
  reg [2:0]   sh_CTRL;
  reg [39:0]  sh_0OUTPUT; // {Address*22, DMask*2, DataWrite*16}
  reg [16:0]  sh_0INPUT;  // {Valid*1,DataRead*16}
  reg [21:0]  sh_FWADDR;  // {FastWrite Address*22}
  reg [15:0]  sh_FWDATA;  // {FastWrite Data*16}
  reg [53:0]  sh_GEOM;    // {Yoff*4, Xoff*4, Tiles*7, Delta*16, BaseAddress*23}
  reg [23:0]  sh_BKCOLOR; // {Red*8, Green*8, Blue*8}
  reg [32:0]  sh_PALETTE; // {WrEn, Index*8, Red*8, Green*8, Blue*8}
  reg [23:0]  sh_DEBUG;

  reg [2:0]   r_CTRL;
  reg [39:0]  r_0OUTPUT;
  reg [16:0]  r_0INPUT;
  reg [21:0]  r_FWADDR;
  reg [15:0]  r_FWDATA;
  reg [53:0]  r_GEOM;
  reg [23:0]  r_BKCOLOR;
  reg [32:0]  r_PALETTE;
  
  reg [39:0]  FW_OPDATA;  // {Address*22, Mask*2, Data*16}
  reg [15:0]  FW_SHIFT;
  reg         FW_WRREQ;
  reg         FW_RDREQ;
  wire        FW_RDEMPTY;
  wire        FW_WRFULL;
  wire [39:0] FW_Q;

  JTAG_FIFO      JFF(.aclr(!Reset), .data(FW_OPDATA), .rdclk(SlowMemClk), .rdreq(FW_RDREQ), .wrclk(!tck), .wrreq(FW_WRREQ), .q(FW_Q), .rdempty(FW_RDEMPTY), .wrfull(FW_WRFULL));

  reg [15:0]  JRF_DATA;
  reg         JRF_WRREQ;
  reg         JRF_RDREQ;
  wire        JRF_RDEMPTY;
  wire        JRF_WRFULL;
  wire [15:0] JRF_Q;

  JTAG_READ_FIFO JRF(.aclr(!Reset), .data(JRF_DATA), .rdclk(tck), .rdreq(JRF_RDREQ), .wrclk(SlowMemClk), .wrreq(JRF_WRREQ), .q(JRF_Q), .rdempty(JRF_RDEMPTY), .wrfull(JRF_WRFULL));

  reg [1:0] JRF_Status;
  reg [1:0] JRF_Flag;
  reg [1:0] FW_Flag;

  always @(negedge tck)
    begin
	   if (Reset == 1'b0)
		   begin
			  JRF_Status = 2'h0;
			  JRF_RDREQ = 1'b0;
			  JRF_Flag[1] = 1'b0;
			  r_0INPUT = 17'h00000;
			end
	   else case(JRF_Status)
		       2'h0: begin
				         r_0INPUT = 17'h00000;
				         if (JRF_RDEMPTY == 1'b1) 
							   begin
								  JRF_RDREQ = 1'b0;
								  JRF_Status = 2'h0;
								end
						   else begin
							       JRF_RDREQ = 1'b1;
							       JRF_Status = 2'h1;
						        end	
				       end
		       2'h1: begin
				         JRF_RDREQ = 1'b0;
							JRF_Flag[1] = !JRF_Flag[0];
							r_0INPUT = {1'b1, JRF_Q};
							JRF_Status = 2'h2;
				       end
		       2'h2: begin
				         if (JRF_Flag[1] != JRF_Flag[0]) JRF_Status = 2'h2;
							else begin
							       r_0INPUT = 17'h00000;
							       JRF_Status = 2'h0;
								  end
				       end
		       2'h3: begin
				         JRF_Status = 2'h3;
				       end
				 default: JRF_Status = 2'h3;
		     endcase
    end
  
  always @(posedge tck)
    begin
	   if (Reset == 1'b0)
		   begin
			  FW_WRREQ = 1'b0;
			  FW_Flag = 2'b00;
			  JRF_Flag[0] = 1'b0;
			end
	   else if (FW_Flag[0] == FW_Flag[1]) FW_WRREQ = 1'b0;
			  else begin
				      FW_WRREQ = 1'b1;
				  	   FW_Flag[0] = FW_Flag[1];
			       end
	   case(ir_in)
		  VIR_0OUTPUT: begin
		                 if (vJTAG_sdr == 1'b1) sh_0OUTPUT = {tdi,sh_0OUTPUT[39:1]};
					 	     if (vJTAG_e1dr == 1'b1) 
							     begin
									 FW_OPDATA = sh_0OUTPUT;
									 r_0OUTPUT = sh_0OUTPUT;
									 FW_Flag[1] = !FW_Flag[0];
								  end
		               end
		  VIR_0INPUT:  begin
		                 if (vJTAG_cdr == 1'b1) 
							     begin
									 sh_0INPUT = r_0INPUT;
									 JRF_Flag[0] = JRF_Flag[1];
								  end
		                 if (vJTAG_sdr == 1'b1) sh_0INPUT = {tdi,sh_0INPUT[16:1]};
		               end
		  VIR_FWADDR:  begin
		                 if (vJTAG_sdr == 1'b1) sh_FWADDR = {tdi,sh_FWADDR[21:1]};
					 	     if (vJTAG_udr == 1'b1) r_FWADDR = sh_FWADDR;
		               end
		  VIR_FWDATA:  begin
		                 if (vJTAG_cdr == 1'b1) FW_SHIFT = 16'h8000;
		                 if (vJTAG_sdr == 1'b1) 
							     begin
								    sh_FWDATA = {tdi,sh_FWDATA[15:1]};
									 FW_SHIFT = {FW_SHIFT[14:0],FW_SHIFT[15]};
									 if (FW_SHIFT[15] == 1'b1)
									    begin
										   FW_OPDATA = {r_FWADDR,2'b00,sh_FWDATA};
											FW_Flag[1] = !FW_Flag[0];
											r_FWADDR = r_FWADDR + 1;
										 end
								  end
		               end
		  VIR_CTRL:    begin
		                 if (vJTAG_sdr == 1'b1) sh_CTRL = {tdi,sh_CTRL[2:1]};
						     if (vJTAG_udr == 1'b1) r_CTRL = sh_CTRL;
		               end
		  VIR_GEOM:    begin
		                 if (vJTAG_sdr == 1'b1) sh_GEOM = {tdi,sh_GEOM[53:1]};
						     if (vJTAG_udr == 1'b1) r_GEOM = sh_GEOM;
		               end
		  VIR_BKCOLOR: begin
		                 if (vJTAG_sdr == 1'b1) sh_BKCOLOR = {tdi,sh_BKCOLOR[23:1]};
						     if (vJTAG_udr == 1'b1) r_BKCOLOR = sh_BKCOLOR;
		               end
		  VIR_PALETTE: begin
		                 if (vJTAG_sdr == 1'b1) sh_PALETTE = {tdi,sh_PALETTE[32:1]};
						     if (vJTAG_udr == 1'b1) r_PALETTE = sh_PALETTE;
		               end
		  VIR_DEBUG:   begin
		                 if (vJTAG_cdr == 1'b1) sh_DEBUG = 24'h123456;
		                 if (vJTAG_sdr == 1'b1) sh_DEBUG = {tdi,sh_DEBUG[23:1]};
		               end
		  default:     begin
		                 if (vJTAG_sdr == 1'b1) sh_BYPASS = tdi;
		               end
		endcase
	 end

  assign tdo = (ir_in == VIR_CTRL)    ? sh_CTRL[0]
             : (ir_in == VIR_0OUTPUT) ? sh_0OUTPUT[0]
             : (ir_in == VIR_0INPUT)  ? sh_0INPUT[0]
             : (ir_in == VIR_FWADDR)  ? sh_FWADDR[0]
             : (ir_in == VIR_FWDATA)  ? sh_FWDATA[0]
             : (ir_in == VIR_GEOM)    ? sh_GEOM[0]
             : (ir_in == VIR_BKCOLOR) ? sh_BKCOLOR[0]
             : (ir_in == VIR_PALETTE) ? sh_PALETTE[0]
             : (ir_in == VIR_DEBUG)   ? sh_DEBUG[0]
 	          : sh_BYPASS;

  assign Reset         = r_CTRL[2];
  assign Blank         = r_CTRL[0];
  assign BlankColor    = r_BKCOLOR;
  assign BaseAddress   = r_GEOM[22:0];
  assign DeltaAddress  = r_GEOM[38:23];
  assign TileAddress   = {r_GEOM[45:39],16'h0000};
  assign Xoffset       = r_GEOM[49:46];
  assign Yoffset       = r_GEOM[53:50];
  assign PAL_data      = r_PALETTE[23:0];
  assign PAL_wraddress = r_PALETTE[31:24];
  assign PAL_wren      = r_PALETTE[32];

  reg ReadReq;
  
  always @(negedge SlowMemClk)
    begin
	   if (Reset == 1'b0)
		   begin
			  JRF_WRREQ = 1'b0;
			  FW_RDREQ = 1'b0;
			  ReadReq = 1'b0;
			end
		else begin
	          if (ReadReq == 1'b1)
		          begin
			         JRF_DATA = P0_DataRead;
			         JRF_WRREQ = 1'b1;
			       end
		       else begin
		              JRF_WRREQ = 1'b0;
	               end	
		       if (FW_RDREQ == 1'b1)
			       begin
			         P0_Address   = FW_Q[39:18];
			         P0_DQmask    = FW_Q[17:16];
			         P0_DataWrite = FW_Q[15:0];
			         ReadReq = (FW_Q[17:16] == 2'b11) ? 1'b1 : 1'b0;
			       end
		       else begin 
			           P0_DQmask = 2'b11;
			           ReadReq = 1'b0;
			         end
		       FW_RDREQ = !FW_RDEMPTY;
			  end	 
 	 end
	 
endmodule
