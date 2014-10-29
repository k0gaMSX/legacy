
Z80/R800 emulator for Z80/R800 Ver: 2.0 Made By: NYYRIKKI (2003)
----------------------------------------------------------------

This is a free Z80 & R800 emulator for Z80 / R800 You can use these sources freely
for any purpose if you just mention authors name (NYYRIKKI) in your product.
It would be nice also if you would tell me for what purpose you used these sources. :-)

This packet should include following files:

Filename:       Filetype:               Explanation:
--------------------------------------------------------
Z80.ASM         Source                  Main code (compile this) This file includes configuration.
IO.INC          Include                 All I/O commands are linked to these routines.
MEM.INC	        Include	                All memory usage is linked to these routines.
Z80DD.INC       Include                 Emulation routines for #DD starting commands
Z80ED.INC       Include                 Emulation routines for #ED starting commands
Z80FD.INC       Include                 Emulation routines for #FD starting commands
EmuR800.INC     Selectable Include      Use this to emulate R800 on Z80
RealR800.INC    Selectable Include      Use this to emulate R800 commands on R800
NoR800.INC      Selectable Include      Use this, if you don't want R800 commands emulated
Z80DDtbl.INC    Include                 Table of #DD starting commands emulation addresses
Z80EDtbl.INC    Include                 Table of #ED starting commands emulation addresses
Z80FDtbl.INC    Include                 Table of #FD starting commands emulation addresses
Z80Tbl.INC      Include                 Table of other commands emulation addresses
zDDund.INC      Include                 #DD starting commands, that are not used
zEDund.INC      Include                 #ED starting commands, that are not used
zFDund.INC      Include                 #FD starting commands, that are not used
Z80.BIN         MSX BLOAD binary        Compiled Example binary.
DataBus.ASM     Test Program source     With this program you can test your computers databus value
ReadMe.TXT      Document                This file
--------------------------------------------------------

These sources can be compiled at least with:
XAsmWin32 (c) FireWorkS Super Deformed Cyberlabs 1997

This source should anyway be quite a standard Z80 assembler, so you can 
probabbly compile these files with other compilers as well.

Updates since V1.0:

- Stack pointer is now virtual
- Memory usage is virtual
- Bugs fixed in #FD, #XD commands
- CPI command, that was accidentally not implemented is now emulated
- Interrupt enabled / disabled detection at startup
- Real interrupts don't anymore mess up memory under stack pointer

Please read z80.ASM for details about emulation...

			    ,_____.
		    _=_=_=_=!_MSX_!=_=_=_=_=_=_=_=_,
		   ! A1GT ~--- - I  ( o o o o o o )i
		  /--------------------------------`,
		 / .::::::::::::::::::::::;::;	::::.,
		/ :::.:.:.:::____________:::::!.  -=- `,
		~======================================
		                NYYRIKKI