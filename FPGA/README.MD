This folder contains the source files to create the image to be inserted into the FPGA.

If you are not interested in modifying the hardware synthesized in the FPGA, you can ignore the contents of the folder.

To compile the image file, proceed as follows:

- Open the TiledScreen.qpf project file with Quartus Prime.

- Make the changes you intend to make.

- Compile the project and you will get the Video.sof file in the output_file folder.

- Use the quartus_cpf command to transform the Video.sof file into Video.ttf:

  */quartus/bin/quartus_cpf -c -q 10MHz -g 3.3 -n v Video.sof Video.ttf
  
- If you don't already have it, generate the makeCompositeBinary executable from the sources in this repository:

  https://github.com/vidor-libraries/VidorBitstream/tree/release/TOOLS/makeCompositeBinary

- Run the makeCompositeBinary command to generate the app.h and signature.h files:

  makeCompositeBinary -i ./Video.ttf:1:512 -o ./app.h -t 1 > signature.h
  
- Copy the two files, app.h and signature.h, into the Arduino library folder:

  ~/Arduino/libraries/TiledScreen/src/utils/
