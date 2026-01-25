# Debugger DEBUG.COM for MSX

Msx DOS Debugger inspired to msdos DEBUG.EXE. This software is a code resurrect from old project in 1993.

Thanks to [Ariakirasoft](http://www.kawa.net/msx/download-e.html) for releasing source code and to Guyver800 from #msxdev for his support and suggestions.

![Screenshot](img/screenshot1.jpg)
![Screenshot](img/screenshot2.png)

**Assemble source code**

Type 

	sjasmplus debug.asm

A file named "debug.com" will be created, ready to be used in your beloved MSX!

**What has been done**

I implemented the assemble command that was missing in original software, then i fixed various bugs in disassembly and added support for R800 IXH,IXL,IYH,IYL registers.
R800 MULUB and MULUW instructions are supported!

To fill data use 'DB' for bytes and 'DW' for words. You can use strings so DB 'Test',13,10 works!
I added also another data fill instruction, 'DS'.
Example: DS 'A',0A

It will fill memory with 10 'A' characters.

**Notes**

For 'IN' and 'OUT' instructions, if your port is 'C' (hex number) its mandatory to use 2 digits to avoid ambiguity with the instructions using (C) register.

Example:

`IN A,(C)` means **Read 1 byte from port in register C**

`IN A,(0C)` means **Read 1 byte from port number C (port 12)**

**Help File**
If you want to install help file in your MSX-DOS installation, copy 'debug.hlp' to 'HELP' folder.
