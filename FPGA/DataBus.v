module DataBus
( input [15:0] DataOut,
  input OutputEnable,
  inout [15:0] SDRAM_D,
  output [15:0] DataIn
);

  wire [15:0] OE = {OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,
                    OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable,OutputEnable};
						  
  TriStateIO BUF(.datain(DataOut), .oe(OE), .dataio(SDRAM_D), .dataout(DataIn));
  
endmodule
