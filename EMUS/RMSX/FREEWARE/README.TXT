
rMSX - MSX emulator for MSX tR version: 1.3
-------------------------------------------
Made By: NYYRIKKI 2009


General information:

To use this program you need MSX tR and dump of MSX1 or MSX2 system ROM.
MSX1 system ROM should be named "MSX.ROM" and MSX2 sytem ROMs should be
named "MSX2.ROM" and "MSX2SUB.ROM".

By default emulator searches these files from same directory where the
emulator is installed, but this can be changed using EMUROMS variable.

Example: SET EMUROMS=A:\ROM\SYSTEM

To enjoy all the features harddisk / CD / CF or similar is recommended.
Saving to emulated media is not supported, so if you want to save your
work, you need to use real disk or cassette. This program requires DOS2
and it has been confirmed that Nextor is not compatible with this program.

This emulator now also supports MSX tR internal memorymapper. Maximum
space that can be used from the mapper can be calculated using formula
"DOS2 free memory - 16KB" How ever space above 1MB can not be used even
if it exists.

Commandline parameters and keyboard shortcuts can be used to access most
important features, but many of the features are available only from BASIC.

Please note, that all of the MSX1 and MSX2 ROMs do not work. If your MSX
does not boot, try another set of ROM's.

This program is freeware since 2015 and from this version all protections
and limitations have been removed.

-----------------------------------------------------------------------------

Commandline parameters:

	? | /? | HELP
		Mini help of commandline options and keyboard shortcuts

	MSX1	
		Start emulator in MSX1 mode. (Default)

	MSX2	
		Start emulator in MSX2 mode.

	IOSOUND
		Enable I/O sounds

	NODISK
		Disable diskdrive of emulated MSX.

	DSK: [<drive>:][<path>]<filename.DSK>[,<disk number>]
		Mounts disk image. Disk number can be selected form 0-9
		There can be multiple "DSK:" commands on same commandline.
		When emulator starts disk number 0 is always selected.

	CAS: [<drive>:][<path>]<filename.CAS>
		Mount cassette image to virtual cassettedrive

	CASRUN: [<drive>:][<path>]<filename.CAS>
		This command disables diskdrive and executes automatically
		first file from cassette image.

	NOMENU
		Disables keyboard menu (for debugging purposes only)

-----------------------------------------------------------------------------

Keyboard shortcuts:

To access built in shortcut menu, you need to press "YES-key". (on the right side
of SPACE) You will know that you are in the menu, when Pause and Turbo leds starts
blinking. Normally these are used to indicate cassette relay and virtual diskdrive
status.

When you are in the menu you can use number keyboard to activate disk number. (0-9)

Also following keys can be used:

	Esc	= Exit menu
	DEL	= Hard reset
	R	= Soft reset
	H       = Change Hz rate 
	X	= Exit emulator



-----------------------------------------------------------------------------

List of supported BASIC commands:


	_CHDIR ("[<drive>:]<path>")
		Set default drive & path on host OS.

	_FILES [("[<drive>:][<path>][<filename>]")]
		List files from host OS.

	_CHCAS ("[<drive>:][<path>]<filename.CAS>")
		Mount cassette image to virtual cassettedrive

	_CASREW
		Rewind cassette back to beginning

	_CASAUTOREW [ON|OFF]
		Select if cassette should be rewound automatically.
		At least Gauntlet(*) requires this... maybe also some other?

	_CASRUN [("[<drive>:][<path>]<filename.CAS>")]
		Good option for people, who are not too familiar with cassettes...
		This will start first program on cassette image. If started without
		parameters, this will run first program from currently inserted cassette.

	_CHDSK (<disk number>)
		Activate disk number <disk number> (integer between 0-9) 

	_CHDSK [("[<drive>:][<path>]<filename.DSK>")]
		Mount disk image for current disk number. If parameter is not 
		given or it is empty real disk drive will be used.

	_CHDSK ("[<drive>:][<path>]<filename.DSK>",<disk number>)
		Mount disk image to disk number <disk number>
		(Does not activate disk number)

	_CHDSK (<disk number>,"[<drive>:][<path>]<filename.DSK>")
		Activate disk number <disk number> and mount disk image to it.


	_IOSOUND [ON|OFF]
		Enable / Disable emulated cassette & disk sounds. By default I/O
		sounds are off. Please note that disk spinning sounds will not
		work on games that use MSX-Music.

	_MUTE [ON|OFF]
		Enable / Disable all sounds.

	_LICENSE
		Display license information

	_EXIT
		Exit from emulator

	_RESET
		Reboot MSX

	_HZ [50|60]
		Select screen refresh rate

	_PALETTE [MSX1|MSX2|GREEN|GRAY]
		Select what palette / monitor emulation should be used.
		Note: This commands has no effect on MSX2 emulation, but it
		will not cause error, if used on listing.

	_?
	CALL HELP
		Print available commands to screen. (Use cursor keys to access)	


Examples:

  DISK:

	To select directory type:
	  _CHDIR("C:\GAMES\DSK")

	To see what DSK files you have, type:
	  _FILES("*.DSK")

	To set correct disk image type:
	  _CHDSK("A:\DSK\MIU2006.DSK")

	To start the disk image type:
	  _RESET

	If you know BASIC a little you can make loader / game selector 
	with favorite settings quite easily:

	10 _CHDIR("A:\GAMES\DSK\")
	20 FOR D=1 tO 3
	30 N$="ALESTE2"+HEX$(D)
	40 _CHDSK(N$+".DSK",D-1)
	50 NEXT D
	60 _CHDSK(1)
	70 _RESET


  CASETTE:

	To get maximum free memory it is recommended to start the emulator
	SHIFT-key pressed or with "NODISK" parameter.

	To set correct CAS-image type:
	 _CHCAS("A:\GAMES\CAS\GAUNTLET.CAS")

	Games can be usually loaded with one of the following commands:

	BLOAD"CAS:",R
	RUN"CAS:
	CLOAD

	... but you can also use "_CASRUN" if the program you want to load is
	first file in CAS-file.




-----------------------------------------------------------------------------

History of changes:

   Version 1.3 Freeware edition

	- Protections removed

	- Issue with CAS-file loading fixed. (Registered users have received
	  fix for this issue already in 2009)


   Version 1.3

	- MSX2 support added to loading routine

	- Program has changed from freeware to shareware

	- As now also MSX2 is supported, name has been changed from MSX1EMU to rMSX.

	- I/O sounds are now disabled by default

	- New commandline parameters: MSX1 (default), MSX2, IOSOUND, NOMENU

	- Shortcut key to change between 50/60Hz added

	- MSX2 related changes in HZ, PALLETTE and EXIT commands

	- Partial MSX-Music support (without ROM's)

	- Keyboard online menu has been rewritten = Much better compatibility with games

	- New command LICENSE & shareware note added

	- Bug fix: disk LED support works even when IOSOUND is off.

 	- Fixed a bug that caused delay on CALL command handling.

 	- Fixed a bug that caused _SYSTEM not to work


  Version 1.2:

	- Memory mapper (internal) support up to 1MB 
	  (= Possible to play cracked megaROMs)

	- All file access is using DOS2 commands (Now this program
	  can be started directly from CD-ROM)

	- Added possibility to mount up to 10 disks

	- CHDSK command now supports multiple disk images

	- Diskless MSX1 now boots faster

	- Internal memory usage reduced to 16KB (1 mapper page)

	- New BASIC command: MUTE

	- CASREV & CASAUTOREV renamed to CASREW & CASAUTOREW

	- Commandline parameters & internal commandline help
	  implemented.

	- Control menu during emulation implemented

	- Default ROM-loading directory is now executable
	  loading directory (Emulator can be putted to PATH)

	- ROM loading directory can be changed with EMUROMS variable.



  Version 1.1:

	- Now the disk drive actually works on real MSX tR

	- More accurate track seek sound emulation on 360KB & 5.25" disks.

	- Disk drive motor sound now works a bit better

  Version 1.0:

	- First public version


-----------------------------------------------------------------------------


MSX memory layout:

	0-0	MSX-BIOS
	0-1	Not in use
	0-2	Not in use
	0-3	Not in use

	1	Not in use

	2	Not in use

	3-0	RAM
	3-1	Host OS commands (& SUB-ROM on MSX2)
	3-2	DISK ROM
	3-3	Not in use

-----------------------------------------------------------------------------

Tips & tricks:

If you want to transfer files to diskless MSX-computer, first attach the other
computers cassette jack to your MSX tR monitor earplug. Make sure I/O sounds are
disabled from emulator, type load command on other computer and then save
command on emulator.


(*) The mentioned original version of Gauntlet does not work on computers
that have slot 0 expanded. To fix this, dump both sides of the cassette.
Then put #00 to CAS-file offset #5C20 and #D386 Last copy both sides together
as one file and remember to execute "_CASAUTOREW ON"

Happy gaming!

			    ,_____.
		    _=_=_=_=!_MSX_!=_=_=_=_=_=_=_=_,
		   ! A1GT ~--- - I  ( o o o o o o )i
		  /--------------------------------`,
		 / .::::::::::::::::::::::;::;	::::.,
		/ :::.:.:.:::____________:::::!.  -=- `,
		~======================================
		                NYYRIKKI



