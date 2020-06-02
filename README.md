# TiledScreen
Video Controller Library for Arduino MKR Vidor 4000 -- Tiled Mode

TiledScreen is a library for Arduino MKR Vidor 4000 that implements a video controller in tiled mode, with 16x16 pixel tiles.

This mode was chosen because the JTAG interface is too slow to manage bitmap video memory from the MCU. With the tiled mode, changing a single byte of video memory corresponds to changing a region of 16x16 pixels, so it is suitable for a low speed interface.

To use the library, simply download the TiledScreen.zip file in the libraries folder and install it in the Arduino IDE.

The TiledScreen class encapsulates the interface via JTAG with the hardware synthesized in the FPGA and exposes the following methods:

- getInstance():

  Obviously there is only one instance of the video controller, so even the TiledScreen class foresees the existence of only one instance. The method in question allows to obtain the pointer to this instance, to use it in the calls of the other methods.

- setReset():

  Allows you to activate and deactivate the Reset signal.

- setBlank():

  Allows you to activate and deactivate the BlankScreen signal. When BlankScreen is active, the contents of RAM are ignored and a monochrome video signal is generated.
  
- setBlankColor():

  Allows you to choose the color that will be displayed on the screen when the BlankScreen signal is active.
  
- writeByte():

  It allows to write a single byte in the SDRAM memory managed by the FPGA. There are 8MB of memory, so only the least significant 23 bits of the address are valid.

- readByte():

  It allows to read a single byte in the SDRAM memory managed by the FPGA. There are 8MB of memory, so only the least significant 23 bits of the address are valid.

- writeWord():

  It allows to write a single word (16 bit) in the SDRAM memory managed by the FPGA. The 8MB of memory are seen as 4MW, but for consistency a 23-bit address is considered, but the least significant bit is ignored. That is, only even addresses are used.
  
- readWord():

  It allows to read a single word (16 bit) in the SDRAM memory managed by the FPGA. The 8MB of memory are seen as 4MW, but for consistency a 23-bit address is considered, but the least significant bit is ignored. That is, only even addresses are used.
  
- fastWrite():

  It allows you to write any number of words in memory sequentially. Useful for loading images of tiles. Here too, only even addresses make sense.
  
- setAddress():

  Allows you to set the start address of the video memory. Since each tile corresponds to a single byte, the odd addresses also apply here.

- setDimension():

  Set the size, in tiles, of the virtual screen. They cannot be smaller than the size of the physical screen (40x23).
  
- setView():

  Sets the starting pixel for the screen display. Attention it is the single pixel, not the tile.
  
- setTileMap():

  Set the address where the Tile Map is located. The least significant 16 bits are ignored. The default is 0x010000.
  
- setColor():

  Sets the RGB values (888) of one of the 256 colors available in the palette.
