Copyright 1999-2000 By Alexandre M. Maoski

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.





                                Power MSX  0.07
                               ßßßßßßßßßßßßßßßßß

Date: 21/06/2000
Author: Alexandre M. Maoski


        Power MSX is a MSX emulator that runs on DOS and emulates a MSX1.
It features a ZEXALL Z80 and a perfect PSG. It emulates tapes and drives.
A user-friendly GUI is also included, which configures almost all the
functionality of the emulator.


Things to be done:
        SCC emulation. FMPAC emulation.
        Acurate PPI sound. MSX2.
        Better overall timing.
        Support PSG samples.

Usage: pmsx [options] [carta.rom]

Options:
	-ifreq <num>	The number of interrupts that
			the VDP generates in a second. In europe, to
			have the correct speed of your MSXs, you should
			set -ifreq 50, and the others should set -ifreq 60,
			which is the default setting.
        -diska <file>   The file that will be Drive A.
        -diskb <file>   The file that will be Drive B.
        -fs <num>       Number of frames that will be cutted. 0 means
                        that all frames are displayed. 1 means that 30
                        in 60 frames are rendered. 2 that 20. And so on...
                        The default is 0.
        -sr <num>       Sample Rate. It goes from 5000 to 45100.
                        Default is 44100
        -tape <file>    The file that will serve as tape.
        -sound <num>    sound 0 : No sound.
                        sound 1 : Soundblasters
        -320x200        Begins the emulation in this resolution.
                        In this way, any resolution that your
                        card/monitor accepts, will be accepted.
                        These resolutions are opened in VESA2L.
                        If you don't have VESA2 builted in your
                        board, go and get at www.scitech.com
                        Scitech Display Doctor.
        -debug          Enter the emulator right into the debugger.

Keys in emulation:

        F12 quits emulation.
        F11 enters GUI.
        F8  rewinds the tape.
        F6 Debugger
        PAGEUP is STOP.
        PAGEDOWN is SELECT.
        Left ALT is GRAPH(LGRA)
        Right ALT is CODE(RGRA)
        F7,F9,F10,PRINTSCREEN,SCROLLLOCK,PAUSE aren't used yet.
        The other keys work as in a MSX.

PMSX 0.07:
   Changed:
   -Z80 fixed. Now it passes all the ZEXALL tests.
   -VDP now is emulating some strange features. Now it runs Thing
Bounces Back perfectly!
   -Added a frame counter.
   -Corrected some sprite bugs.
   -Fixed a disk offline bug.
   -Implemented -ifreq, so our european fellow can run the emulator at
their perfect speed, while we, here in 60Hz, can run those classic european
games as they were programmed to behave.

PMSX 0.06:
   The VDP was entirely rewritten. Now the graphics engine is line
based, providing a very precise emulation. Sprites 8x8, and Magnified
sprites were also emulated. The fifth sprite in a row is disappearing,
as it is supposed to happen.
   Sprite colision bit is also emulated. So, I think this VDP should
run perfectly 99% of MSX-1 software! If something works strange,
please e-mail me.

Previous Versions:

In this version, you have also some extended video modes. If you have
VESA2, you can try (320x480, Intensity 75%), is almost like TV. I have
added also Interpolation X, Scanlines, and Double modes.

In this version, MEGARAM and MEMORY MAPPER are implemented, and can
be used by setting them in MSX.CFG.
The first line in MSX.CFG should be mapslots=a,b,c,d
        where the letters must be 0 or 1, whether the slot is expanded
        or not. mapslots=1,0,0,0 means that only slot 0 is expanded.
Then you should have the structure: slot a,b { ... }
        to specify what you want in that slot. a,b is slot,subslot. If
        that slot isn't expanded, put simply a,0.
Inside the slot structure:
        You can reserve RAM (in PACKS of 8Kb): RAM 64
        You can set memory unused (in PACKS of 8Kb): UNUSED 8
        You can load a ROM: ROM "\roms\msx.rom" 32 --> 32 is the size(Kb)
        Memory Mapper: MAPPER <size> in blocks of 16Kb
        Megaram: MEGARAM <size> in blocks of 8Kb
        Patch a ROM: patch {adress:aa,bb,...;}

        For example: slot 0,0{rom "msx.rom" 32} will load the MSXROM
                slot 1,0{unused 16 rom "disk.rom" 16} will load DISK.ROM,
                starting in page 1, or adress 4000h
        Comments are standard C, /* and */

Other aspects of the emulation
can be setted in the PMSX.INI.

Inside the DEBUGGER, you can walk through the assembly code with UP and
DOWN, and faster with PGUP and PGDN. To execute the current instruction
press ENTER. To set a BREAKPOINT, type B <number>, where number is the
hexadecimal address you want to be breakpointed. Type V to see the current
output of the VDP. You can swap the windows with TAB. When the window is
in the REGISTERS, you can alter them directly with cursor key + numbers.
The MEMORY window can be navigated with PGDN/PGUP, UP/DOWN, and also can
be changed, just like the REGISTER window.

Thanks:
        All MSX emulators, especially BRMSX for being so perfect!
        Marat Fayzullin for his portable Z80, which I'm using here.
        Shawn Hargreaves for the Allegro Library.
        Carlos Hassan for the Sound Library, SEAL.
        The people producing MSX Software and scanning technical docs.
        This emulator would not be possible without these online resources.
        All the MSX users worldwide, ASCII and Microsoft.
        Michel Kerkhoven and Mauricio Braga for reporting bugs and sending
sugestions.


Please e-mail me with ideas, comments, bugs or info about software
        that doesn't work.



Alexandre M. Maoski, amaoski@ig.com.br
You can check for new versions on my site: http://www.geocities.com/ammaoski
There you can find the sources too.
To be compiled you need DJGPP + ALLEGRO + SEAL
Thanks


