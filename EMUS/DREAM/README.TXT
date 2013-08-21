Dreammsx v0.2

Dreammsx is an MSX2 emulator for the Dreamcast
based on fMSX 1.5 by Marat Fayzullin. The
AY8910 and SCC emulation are replaced
for better sound emulation (ripped of
the MESS project).

This is a work-in-progress version, which works
with most MSX1 and some (most Konami) MSX2 roms. 
It has also has full AY8910 and SCC emulation.


Burning Instructions

1.Burn all files in the cdrom dir + your .rom files to cdr root
2.File options: Mode1, ISO level2, joliet. (I use Nero) 
3.Boot with Utopia bootdisc, then swap to Dreammsx disc, Not the DCMP3 disk (stupid typo)
4.Use up/down to select a game. Press Start to configure the iperiod
5.Use up/down to select the Iperiod and press start again
6.Do the same for the frameskip and select the rom-type (needed for the memory-mapper)
7.Press Start to start the game
8.Press 'Y' to get back to the menu
9.Press 'X' from the menu to exit the program, this might be usefull when using a loader.
  When not using a loader program don't use this function, the program will hang.

I have tested the dreammsx emulator with the following roms:
- F1 Spirit
- Maze of Galious
- Metal Gear
- Nemesis1
- Nemesis2
- Nemesis3
- Parodius
- Penant Race 1
- Penguin adventure
- Qbert
- Vampire Killer
- The Threasure of Usas
- Kingsvalley II
- Salamander
- Gryzor
- Goonies 

Enoy it!

Jos Kwanten.

GREETINGS:
 ----------
Marat Fayzullin - for his fMSX emulator.
Sean Young	- for the SCC sound emulation.
Dan Potter	- for the great libdream library

Added in version 0.2b
- Added IPeriod selectio in the menu
- Added Frameskip selection in the menu
- Added Rom-type selection in the menu
- Nero (ver 5.0.1.3) and Diskjuggler (ver 3.00) images 
- Removed stupid bug to print information to the serial port. This was the
  main reason that people thought they could not burn the disk or that it was fake. 
  Acctualy DreamMSX started and wants to print some debug info to the serial port but the
  hardware handshake was not toggled and the result is that is looks like the
  whole program hangs. Sorry that this stupid bug has wasted so much CD's... 