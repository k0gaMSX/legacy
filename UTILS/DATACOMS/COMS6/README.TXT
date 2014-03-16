                                   C O M S 6
                                   ---------



Description:
------------

    COMS6 is a communications program with ANSI color terminal and file
transfer protocol YMODEM-B. With this program you can to access to all
services which BBSs can to offer to you. Like: electronic mail, public echo
conferences, games on-line, file transfers, etc...



Hardware requeriments:
----------------------

    System: MSX2, 2+, Turbo-R.
    MSX-DOS 2.0 or later.
    Hard disk or Ramdisk for the transfers.
    64K RAM.
    128K VRAM.
    Serial interface: ACCNET or SVI compatible.



Installation:
-------------

    COMS6 supports the serial interfaces: ACCNET and compatibles with the
original standard MSX RS-232C. The interfaces compatibles more knowed are:
SVI and Mitsubishi.

    COMS6 requires MSX-DOS 2.0 or later. If you don't have this operating
systen, You can to use the terminal but not the YMODEM.

    If you have hard disk, copy all files into a directory (in example:
A:\COMS6\). Else you can run the program from the floppy disk but you must to
use the ramdisk for the transfers. See the configuration process below.

    Description of the files of COMS6:

        COMS6ACC.COM -> Executable for interface ACCNET.
        COMS6SVI.COM -> Executable for interfaces SVI compatibles.
        COMS6.COM    -> Loader (detects the interface).
        COMS6.CFG    -> Config file. COMS6 creates it.
        COMS6.PHN    -> Data base for the phone directory.
        FILES.COM    -> Module for the file selection. COMS6 executes it
                        internally.
        AGENDA.COM   -> Module for the phone directory. Internal usage too.
        GRPTEXT.FNT  -> Loadable character font (IBM-PC ASCII).
        FILELIST.ACC -> List of files to send. Internal use.

    When you are running COMS6, press <F1> for the menu bar and <F5> for the
help window. Use the "Agenda" option for to call your favourite BBSs.



Configuration:
--------------

    There are two configurable options in the menu bar. The first are the
communications parameters "Puerto". His options are:

    Velocidad: This is the speed. You ought to select the more high that
               works without errors in your system.

    Bits     : Bits per word. Normally "8".

    Parity   : Parity control. Normally "N".

    FIFO     : This option is only for the ACCNET. Tells how many characters
               will hold in his internal buffer before to do the interruption.
               If you have transmition errors, modify this option untill to
               find the best result in your computer.

    The other configurable thing are some system strings "Cadenas". These
strings are:

    Modem ini: This is the modem initialization string. COMS6 sends it when
               starts. Do not modify this string if you are not sure of you
               will to do.

    Comando  : Dial command for the "Agenda" module. The original command
    marcar     dials by pulses. If your phone line supports dialing by tones
               then exchange this string by "ATDT".

    Directorio Tells the default directory for the file transfers. If you
    TX/RX    : have hard disk, is a good idea to config a directory for the
               transfers (in example: "A:\COMS6\FILES\"). Else You must put
               the ramdisk unit ("H:\");



Distribution of COMS6:
----------------------

    This software has shareware distribution (test it before to buy). You can
to copy and to use this program for a try time. Then, if you like, you ought
to contact the author for to register your copy and to be a full right user.
Registered users will receive information for future releases and will have
after-sales assistance. The price of the registration is 1500 pesetas (about
$10 US).

    Remember that to register the programs that you use habitually, contributes
to the maintenance of this distribution system so profitable for every one.



                The author:   Angel Cull  Castany
                              E-mail: aculla@ctv.es
                              FidoNet: 2:343/163.9

                              (C) 1997 by ACC

