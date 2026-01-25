************************************
*  LASQER SQUAD MSX DISK VERSION   *
*        v1.2, June 2016           *
************************************


************************************
           Requirements
************************************

Any MSX machine with 64KB RAM and a
disk drive. No memory mapper
required.

MSX 2 computers will benefit from an
enhanced screen 8 intro screen.


************************************
               Usage
************************************

Boot your MSX computer with disk
inserted or type LSQUAD from MSX-DOS
command line to launch the game.

Following options are available:
    /T1  MSX1 title (default on MSX1)
    /TS  Spectrum title
    /?   Show this help

MSX2-only options:
    /T2  MSX2 title (default on MSX2)
    /TA  Amiga title
    /PC  CoolColors palette
    /P1  MSX1 palette
	/H50 50Hz display
	/H60 60Hz display 

Press joystick button 1 or [Space]
key to skip title screen.

You have a single save slot in the
game, that will be placed in file
MAP08.TZX.

See MANUAL.TXT or QUICK.TXT (shorter
version) for in-game instructions.


************************************
  Changes compared to original MSX
           tape version
************************************

* Two extra levels from Spectrum's
"Laser Squad Expansion Kit Two" have
been ported and added.

* Removed "port FE" bug causing
crashes on various MSX machines.

* Fixed display bugs in status bars
and "PRESS FIRE TO END SELECTION"
message.

* Use cursor keys instead of Q,A,O,P
keys to move cursor and units.

* Fixed a bug allowing units to walk
through obstacles when loading
another scenario after scenario "The
Stardrive" (this is also happening
on Spectrum version).


************************************
              Misc.
************************************

* All .TZX files on this disk are
original and unmodified dumps of the
MSX tape version, except for
MAP06.TZX and MAP07.TZX which are
the original and unmodified dumps of
the Spectrum "Laser Squad Expansion
Kit Two".

* MSX palette is not modified if you
do not specify a /Px option, this
allows you to set your own palette
with tools like SofaRun before
launching the game.


************************************
             Credits
************************************

Code:       Louthrax
Title GFX:  FRS

BitBuster unpacking routine by Team
Bomba.

Thanks to Montagut for providing the
original MSX tape of the game.
