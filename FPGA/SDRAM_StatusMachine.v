module SDRAM_StatusMachine
( input              MemClk,
  input              Reset,
  output reg         SlowMemClk,
  input  [21:0]      P0_Address,
  input  [1:0]       P0_DQmask,
  input  [15:0]      P0_DataWrite,
  output reg [15:0]  P0_DataRead,
  input  [18:0]      P1_Address,
  output reg [127:0] P1_DataRead,
  inout  [15:0]      SDRAM_D,
  output reg [1:0]   SDRAM_BA,
  output reg [11:0]  SDRAM_A,
  output             SDRAM_CK,
  output reg         SDRAM_CKE,
  output reg         SDRAM_CS,
  output reg         SDRAM_CAS,
  output reg         SDRAM_RAS,
  output reg         SDRAM_WE,
  output reg         SDRAM_LDQM,
  output reg         SDRAM_UDQM
);

  reg [4:0]  Status;
  reg [15:0] StartupTimer;
  reg [3:0]  WaitCounter;
  reg        FWR;
  reg        DataAvailable;

  reg [21:0] P0Address;
  reg [1:0]  P0DQmask;
  reg [15:0] P0DataWrite;
  reg [18:0] P1Address;
  
  reg [15:0] DataWrite;
  wire [15:0] DataRead;
  
  DataBus   BUS(.DataOut(DataWrite), .OutputEnable(FWR), .SDRAM_D(SDRAM_D), .DataIn(DataRead));		
  CLKOUT    CLKBUF(.datain_h(1'b1), .datain_l(1'b0), .outclock(MemClk), .dataout(SDRAM_CK));  

  initial
    begin
	   Status = 5'h00;
	 end
  
  always @(posedge SlowMemClk)
    begin
      P0Address   = P0_Address;
      P0DQmask    = P0_DQmask;
      P0DataWrite = P0_DataWrite;
      P1Address   = P1_Address;
	 end
  
  always @(negedge MemClk)
    begin
	   if (Reset == 1'b0) Status = 0;
	   case(Status)
		  5'h00: begin                                                // NOP  (CKE disabled)
		           StartupTimer = 16'h0000;                           // DEBUG
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b0;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  Status = 5'h01;
		         end
		  5'h01: begin                                                // NOP * 0x8000  --> Wait +200us
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b0;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
		           if (StartupTimer[15] == 1'b1) 
					     begin
						    StartupTimer = 16'h0000;                      // DEBUG
						    Status = 5'h02;
						  end
					  else StartupTimer = StartupTimer + 16'h0001;
		         end
		  5'h02: begin                                                // NOP * 0x8000  --> Wait +200us  (CKE enabled)
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (StartupTimer[15] == 1'b1) Status = 5'h03; 
					  else StartupTimer = StartupTimer + 16'h0001;
		         end
		  5'h03: begin                                                // PRECHARGE ALL
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h400;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b0;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  WaitCounter = 1;
					  Status = 5'h04;
		         end
		  5'h04: begin                                                // NOP * 2
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h05; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h05: begin                                                // Extended Mode Register Set
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b01;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b0;
					  SDRAM_WE = 1'b0;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  WaitCounter = 1;
					  Status = 5'h06;
		         end
		  5'h06: begin                                                // NOP * 2
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h07; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h07: begin                                                // Mode Register Set - CAS=3 BURST=8
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h233;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b0;
					  SDRAM_WE = 1'b0;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  WaitCounter = 1;
					  Status = 5'h08;
		         end
		  5'h08: begin                                                // NOP * 2
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h09; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h09: begin                                                // AUTOREFRESH
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b0;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  WaitCounter = 8;
					  Status = 5'h0A;
		         end
		  5'h0A: begin                                                // NOP * 9
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h0B; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h0B: begin                                                // AUTOREFRESH
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b0;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  WaitCounter = 8;
					  Status = 5'h0C;
		         end
		  5'h0C: begin                                                // NOP * 9
					  SlowMemClk = 1'b0;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h0D; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h0D: begin                                                // NOP
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b1;
					  SDRAM_UDQM = 1'b1;
					  if (WaitCounter == 4'h0) Status = 5'h0E; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h0E: begin                                                // BANK ACTIVATE
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = P0Address[21:20];
					  SDRAM_A = P0Address[19:8];
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  WaitCounter = 2;
					  Status = 5'h0F;
		         end
		  5'h0F: begin                                                // NOP * 3
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h10; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h10: begin                                                // WRITE or READ
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  DataWrite = P0DataWrite;
					  SDRAM_BA = P0Address[21:20];
					  SDRAM_A = {4'h0,P0Address[7:0]};
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b0;
					  if (P0DQmask == 2'b11)
					     begin
					       FWR = 1'b0;
					       SDRAM_WE = 1'b1;
					       SDRAM_LDQM = 1'b0;
  					       SDRAM_UDQM = 1'b0;
						  end
					  else
					     begin
					       FWR = 1'b1;
					       SDRAM_WE = 1'b0;
					       SDRAM_LDQM = P0DQmask[0];
  					       SDRAM_UDQM = P0DQmask[1];
						  end
					  WaitCounter = 1;
					  Status = 5'h11;
		         end
		  5'h11: begin                                                // NOP * 2
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h12; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h12: begin                                                // NOP  (if READ then DataAvailable)
					  SlowMemClk = 1'b1;
					  DataAvailable = (P0DQmask == 2'b11) ? 1'b1 : 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  Status = 5'h13; 
		         end
		  5'h13: begin                                                // PRECHARGE ALL
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h400;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b0;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  WaitCounter = 1;
					  Status = 5'h14;
		         end
		  5'h14: begin                                                // NOP * 2
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h15; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h15: begin                                                // BANK ACTIVATE
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = P1Address[18:17];
					  SDRAM_A = P1Address[16:5];
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  WaitCounter = 2;
					  Status = 5'h16;
		         end
		  5'h16: begin                                                // NOP * 3
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h17; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h17: begin                                                // READ
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  SDRAM_BA = P1Address[18:17];
					  SDRAM_A = {4'h0,P1Address[4:0],3'b000};
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b0;
			        FWR = 1'b0;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
  					  SDRAM_UDQM = 1'b0;
					  WaitCounter = 1;
					  Status = 5'h18;
		         end
		  5'h18: begin                                                // NOP * 2
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) 
					     begin
						    WaitCounter = 7;
						    Status = 5'h19; 
						  end
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h19: begin                                                // NOP * 8 (DataAvailable)
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b1;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h1A; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		  5'h1A: begin                                                // PRECHARGE ALL
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h400;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b0;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b0;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  WaitCounter = 1;
					  Status = 5'h1B;
		         end
		  5'h1B: begin                                                // NOP * 2
					  SlowMemClk = 1'b1;
					  DataAvailable = 1'b0;
					  FWR = 1'b0;
					  SDRAM_BA = 2'b00;
					  SDRAM_A = 12'h000;
					  SDRAM_CKE = 1'b1;
					  SDRAM_CS = 1'b0;
					  SDRAM_RAS = 1'b1;
					  SDRAM_CAS = 1'b1;
					  SDRAM_WE = 1'b1;
					  SDRAM_LDQM = 1'b0;
					  SDRAM_UDQM = 1'b0;
					  if (WaitCounter == 4'h0) Status = 5'h0B; 
					  else WaitCounter = WaitCounter - 4'h1;
		         end
		endcase
	 end

  always @(negedge MemClk)
    begin
	   case(Status)
		  5'h13: begin
		           if (DataAvailable == 1'b1) P0_DataRead = DataRead;
		         end
		  5'h19: begin
		           if (DataAvailable == 1'b1) P1_DataRead = {P1_DataRead[111:0],DataRead};
		         end
		  5'h1A: begin
		           if (DataAvailable == 1'b1) P1_DataRead = {P1_DataRead[111:0],DataRead};
		         end
		endcase
    end	 
endmodule
