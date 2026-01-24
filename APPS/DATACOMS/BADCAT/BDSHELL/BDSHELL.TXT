----------------------------
BDShell BadCat Terminal v1.0 
(c) 2020 Armando Perez

Based on previous work of:
    Andres Ortiz
    Oduvaldo Pavan Junior
----------------------------


---- CONTENTS ----

1.- INTRODUCTION AND FEATURES

2.- BINARY FILES. 

3.- SETUP BADCAT WIFI CONNECTION

4.- CONNECT TO A BBS.

5.- FILESYSTEM AND INTERNET REPOSITORY
    5.1.- CONFIGURE INTERNET REPOSITORY
    5.2.- DOWNLOAD FILES FROM INTERNET REPOSITORY

6.- LOAD ROM FILES

7.- BADCAT OTA UPDATES

8.- RS232 PORT

9.- SUMMARY OF BADCAT COMMANDS

10.- SOURCE FILES / ASSEMBLING BDSHELL

11.- THANKS TO...

---- CONTENTS ----




1.- INTRODUCTION AND FEATURES

BDShell is a shell/terminal program intented for programming and handling the
MSX BaDCat Wifi Cards. 

It includes next features:

    * Mininum requirements: MSX with 8k RAM. 
    * Presented in 4 formats: DOS command (.COM), ROM version, MSX-BASIC BLOAD
      Binary version (.BIN) and cassette version (.CAS).
    * Fast and compatible telnet terminal program.  




2.- BINARY FILES. 

BDShell is presented in several formats:
    
    - BDSHELL.BIN: Basic Binary file. Needs 16k of RAM to run.  Type

    - BDSHELL.COM: MSX-DOS Command. Needs 64k of RAM to run. 

    - BDSHELL.ROM: ROM file. Needs 8k of RAM to run. 

    - BDSHELL.CAS: Cassette file. Similar to BDSHELL.BIN 


Choose your favorite format to run BDShell.  Welcome screen will be displayed
(40 columns on first generation MSX and 80 columns on MSX2 or higher). 

------------------------------------------------------------------------------

BaDCaT Shell Terminal v1.0. 
(c) 2020 by Armando Perez

Based on the original work of:
Andres Ortiz & Oduvaldo Pavan Junior

- System:
- Ram:
- Disk System:
- BaDCat:

- Initializing interrupt
- Initializing UART

Ready

------------------------------------------------------------------------------


Note: BDShell forces screen 0 and 40/80 columns but always keeps user colors.
Please ensure your color configuration allow you read displayed texts. 




3.- SETUP BADCAT WIFI CONNECTION

Ensure the wifi switch is in the "ON" position. 

With BDShell running:

    - Type AT+CONFIG and press ENTER. The configuration menu will appear. 
    - Then type WIFI and press ENTER. Wait until the received wifi networks
      appear. 
    - Choose a wifi network.
    - Type the password of the wifi network and press ENTER
    - Press ENTER again an say YES to store changes. After a while this will
      exit the config mode and return to command mode. 


In command mode you can see your wifi network and the assigned IP by typing ATI
and pressing ENTER. 




4.- CONNECT TO A BBS.

This section is an example on how to connect to a BBS using BDShell. For the
example we will use Sotano MSX BBS. 

Ensure you're in command mode and:

    - Type ATD "sotanomsxbbsorg:23".    
    - Choose the appropiate BBS profile. BDShell does not support ANSI:


        (0) Ascii (No Color) 
        [0] MS-DOS CP437
    
    - Choose the profile:

        1 (MSX2...) if you're running BDShell with MSX2 computer.
        2 (MSX1...) if you're running BDShell with first generation MSX. 




5.- FILESYSTEM AND INTERNET REPOSITORY

BaDCat provides an extra local storage (ESP's flash) and the commands to handle
it. Also we can configure an internet repository to load ROM files (Section 6)
or download those files to the local storage. At this time you can only load ROM
files from this local repository. More actions and commands will be added in the
future, for example, load/save files from / to local storage or internet
repository from / to local MSX storage (cassette, FDD, HD, SD...), read or edit
local storage .TXT files, etc...


5.1.- CONFIGURE INTERNET REPOSITORY

BadCat local storage filesystem comes factory configured. Internet repository
needs and extra user configuration:
    
        - From BDShell command line type ATZ to ensure BaDCat is ready. "OK"
          should appear. 
        - Type AT+CONFIG and press ENTER
        - Type repo and press ENTER
        - Enter the repository url and press ENTER. Warning: Only http (not
          https) is supported
        - Press ENTER again and accept changes. 

At this moment BaDCaT firmware needs and extra file configuration on your
internet repository to be able to access files. This file must be named
"filelist.txt". The filename will contain the files you want access from BaDCat
as well as their length in following format:

    FILE1.EXT<TAB><TAB>size 
    FILE2.EXT<TAB><TAB>size 
    ...
    FILEX.EXT<TAB><TAB>size 

    - FILEX.ROM is the name of file. 
    - <TAB><TAB> are two TABs (09)
    - size in bytes. 

Example:

HERO16K.ROM		16384
YIEARE.ROM		16384
ALIBABA.ROM		16384
BBOY.ROM		32768
HERO.ROM		32768
YIEARE2.ROM		32768
ZANAC.ROM		32768
EGGER.ROM		32768
OPWOLF.ROM		49152
MAJI.ROM		49152
RLV933.ROM		49152
TRITON.ROM		49152


Now BaDCaT will be able to access those files both for download to local
repository filesystem and load (simulate) ROM file. 


5.2.- DOWNLOAD FILES FROM INTERNET REPOSITORY

To enjoy the features of local filesytem firtly we need transfer files to this
local repository. At this moment you can only transfer the files from your
internet repository (above section). To transfer file from your internet
repository follow this steps:

    - Type lfiles to ensure you've enough free space to download file
    - Type delete command if necessary to save and free space. 
    - Type dload FILE.EXT to download file from your internet repository. Fille
      will transfer automatically from your internet repository to your local
      storage filesystem. 
    - Type lfiles again to check if your file is correctly transfered to your
      local storage. 


6.- LOAD ROM FILES
   
One the most important BadCat features is the posibility of load ROMs files from
internet repository simulating ROM cartridge on RAM memory. The feature
downloads the ROM file data from internet (or local storage) to RAM and executes
the RAM file. 

The feature works with ROM files from 8k up to 48k non-mapped (linear). Any
other type of ROM file (custom mapper, megarom files, etc...) can't be
simulated. 

There are, however, limitations to the simulation:

    - You need at least 64K of RAM to simulate the ROM files. Yes, you could run
      8/16k ROM files with 32k of RAM but just a few 8/16k ROM files would work
      properly. 

    - Since is a RAM simulation not all ROM files could be executed. The
      simulation could have problems to run or glitches in its execution. 

    - Simulation of ROM files > 16k needs an specific memory environment: all
      pages of RAM must be on the same slot. For example: You've an MSX computer
      with 64k of RAM distributed in four 16k pages each of them in one
      different slot. Hypothetically your MSX has enough memory to emulate a 48k
      ROM file but a real ROM cartridge has *always* its pages in the same slot
      therefore the game would never work.

    - BaDCat Shell ROM version can't handle ROMs with disk access (like
      EGGERLAND MYSTERY or PERFECT FIT). Will be fixed in next version. If you
      want play these games and to use disk access, please, load binary, command
      or cassette version. 

Before load ROM file or download file to local storate we need access to
internet ROM repository. See Section 5 on how to configure your local and internet
repository. To load ROM file BaDCaT needs be able to access to this file from
local storage filesystem or internet repository. 

Continuing with the example of internet repository (Section 5.1) let's start with
the ROM simulation. 

    * From internet repository:

    Warning: BaDCat needs be configured to access WIFI network to use this
    feature.  

        - Type rload FILEX.EXT (eg: rload HERO.ROM)
        - "Press F1 to start download" message will appear in the screen. 
        - Press <F1> to load ROM file or any command to continue and cancel. 
        - If you press <F1> then next messages will appear in the screen:

            "Get file info..."
            "Loading xxxx bytes"

        - The file will load automatically. 


    * From local storage filesystem:
    
    Warning: The file must be present in your local filesystem. (Section 5.2). You
    don't need internet connection to enjoy this feature. 

        - Type load FILEX.EXT (eg: load MAJI.ROM)
        - "Press F1 to start download" message will appear in the screen. 
        - Press <F1> to load ROM file or any command to continue and cancel. 
        - If you press <F1> then next messages will appear in the screen:

            "Get file info..."
            "Loading xxxx bytes"

        - The file will load automatically. 




7.- BADCAT OTA UPDATES

From version 1.3 (comes factory configured) it's possible to upgrade BaDCaT
firmware directly from internet


    - In command BDShell mode type AT&U. The version of the lastest available
      firmware will appear. 
    - To upgrade type AT&U=<version> and press ENTER (eg. AT&U=1.3)
    - This will take some time. After that, the BaDCaT will reboot and show the
      upgraded firmware (you can check with the ATI command). 




8.- RS232 PORT

BaDCaT provides a standard RS232 port mapped at #80 I/O port to provide
compatibility with standard software such as Eric Mass Fossil Driver. 

To use the RS232 port, the wifi switch MUST BE IN THE OFF POSITION!!
Hereafter, standard software can be used. Eric Maas ERIX terminal, is
recommended, which works with his Fossil drive




9.- SUMMARY OF BADCAT COMMANDS

Summary of commands you can introduce in command mode.

    - help: Show the help.

* Related to connection:


    - AT+CONFIG: Enter configuration menu. 

    - ATD"[HOSTNAME]:[PORT]": Open streaming connnection. 

    - ATDT"[HOSTNAME]:[PORT]": Open TELNET connection
    
    - +++: With one second pause -> enter command mode. 

    - ATZ: Close all open socket connections.
    
    - A/: Repeats previous command. 

    - ATI2: Show modem's current IP address.

    - ATI3: Show modem's current wireless router connection

    - ATBn: Sets a new serial baud rate. Takes effect inmediately.

    - AT&W: Write changes to modem flash. BE SURE BEFORE DOING THIS!

    - ATC: Shows information about the curent network connection

    - ATH: Disconnect from the hosst. 


* Related to internet repository:

    - rfiles: Show files from internet repository

    - rload <file>: load ROM file directly from internet repository

* Related to local storage:

    - lfiles: Show the files in the storage system and the current free space

    - delete <filename>: Remove a file from local storage. 

    - dload <file>: Download a file from internet repository to the local storage

    - load <file>: load ROM from local storage. 




10.- SOURCE FILES / ASSEMBLING BDSHELL

To assemble BDShell project you need Pipa Gerardo's SjasmPG assembler:

https://github.com/pipagerardo/sjasmpg

Also an *NIX environment system that support "make" build automation tool. For
Windows you can install Cygwin or MinGW. 

The project is presented with this organization:

Makefile
|
+-- DOC
+-- OUTPUT
+-- SRC

    - Makefile: Rules and directives for make tool. 
    - DOC: Directory that contains this file. 
    - OUTPUT: directory has preassembled / assembled binary BDShell files. 
    - SRC: Source files. 

To assemble type "make". The binary files will be assembled automatically and
stored in OUTPUT directory.

An extra TMP folder will be created when you assemble the project. This temporal
directory has intermediate files and typical output assembler files like .lst,
lab... 

Type "make clean" to clean temporal files. 
Type "make cleanall" to clean temporal files and output files. 




11.- THANKS TO...

    - Andrés Ortiz: For develop and build the awesome BadCaT card and help me with
    BDShell

    - Oduvaldo Pavan Junior (ducasp): For develop his open source TELNET tool. 

    - x1Pepe, SYSOP of Sotano MSX BBS for test BDShell. 












