                  
                            FudeBrowser v1.8

              Copyright (C) 1999,2000 by Ricardo Bittencourt

---------------------------------------------------------------------------

                             Index

                         1. Introduction
                         2. Methodology
                         3. Requirements
                         4. WISE syntax
                         5. FudeBrowser syntax
                         6. Files
                         7. License
                         8. Request
                         9. Credits

---------------------------------------------------------------------------

1. Introduction

        Hello, world.

        Web browsing has been a dream for most MSX users for a long time.
In fact, the first messages I ever got from an MSX mailing list, in 1996, 
were asking for programmers who wanted to develop such a thing. 

        Up to now, all the people who tried to make it failed. They often 
conclude it is not possible for three reasons:

        1) The MSX is too slow for HTML processing
        2) The MSX modems are not fast enough to load pages with images.
        3) The MSX don't have enough resolution to display a page properly.

        After learning a lot of tricks during the making of BrMSX, MUST and 
VIP, I tried to make my own MSX Web Browser. I believe I succeded. My 
approaches to the problems described were:

        1) Who said the MSX should make the HTML processing? All you need
is an intelligent server, which outputs pre-formatted HTML pages. Instead
of connecting to the port 80, the MSX could connected in another port
where the intelligent server is installed.

        2) HTML is just plain ASCII. You can reduce a lot the bandwidth 
required by the pages, compressing them before sending. 

        3) By using variable length, proportional fonts, you can have 
more than 50 characters per line in a 256x192 pixel screen, and more than
100 characters per line in 512x212 screen. This gives a very readable text,
even on televisions.

        This pack you just downloaded include two programs:

        Web Intelligent Server (or just WISE for short): a PC server who
read HTML pages and output pre-formatted, compressed .HTZ streams.

        FudeBrowser: an MSX client who reads .HTZ streams and displays
them in the graphic screen.

        Hope you find this program useful.

---------------------------------------------------------------------------
                                             
2. Methodology

        FudeBrowser is being developed in three steps:

        1) No connection

        In this first step, the MSX cannot do any browsing. The server run 
on PC and produce a file with the pre-formatted and compressed stream. This 
file is copied to an MSX-disk and then read by FudeBrowser.

        2) JoyNet connection

        In this second step, the MSX and the PC will be connected through 
a JoyNet link. The MSX will be able to browse the HTML files stored 
locally in the PC.

        3) Internet connection

        In the last stage, the MSX will run an TCP/IP stack and connect
directly to the intelligent server. Full web browsing will be available
at this stage. A TCP/IP stack was developed by Adriano Cunha in his
UZIX project and will be integrated into FudeBrowser in the future.

        The version of FudeBrowser you just downloaded correspond to an
intermediate state between the first and second steps. This version cannot
download files from any remote server, however, browsing is allowed in
the files present in the disk.

---------------------------------------------------------------------------
                                             
3. Requirements

        WISE requires a PC running MS-DOS. A DPMI server such as CWSDPMI
or Windows95 DOS Prompt must be available. A fast machine with lots of
memory is recommended.

        FudeBrowser requires an MSX-1 running MSX-DOS 1. MegaRAM and Memory
Mapper are not required in this version. The BIOS is used for everything,
so FudeBrowser should run on any MSX model, at any CPU speed (including
Turbo-R in R800 mode and machines with Z80 at 7MHz).

---------------------------------------------------------------------------
                                             
4. WISE Syntax

        Usage of WISE is quite simple. You must have the .html document
and all the images it uses on the same directory. Then, just type:

        WISE PAGE.HTM PAGE.HTZ

        This will do the pre-formatting and the compression, saving the
page in the file PAGE.HTZ. Now you just need to copy this file to a 
MSX and use FudeBrowser to read it.

        The current version of WISE cannot read all kinds of images 
supported by Netscape. Graphic formats supported are:

        - color JPEG images (.jpg, .jpeg)
        - 24-bit PCX files (.pcx)

        You'll need a file format conversor if you want to see GIF images.

        The HTML tags currently supported are:

        <A HREF>
        <BR>,<P>,<HR>
        <BODY BGCOLOR>,<BODY TEXT>,<BODY LINK>,<TITLE>
        <U>,<B>,<CENTER>
        <H1>,<H2>,<H3>
        <IMG ALT>,<IMG SRC>
        <FONT COLOR>,<FONT SIZE>
        <DL>,<DD>,<DT>,<UL>,<LI>
        <TT>,<CODE>,<PRE>

        All escape codes are supported, such as &nbsp; &lt; &gt; &amp; 
&quot; &aacute; &Aacute; &Ccedil; &ccedil; and other accentuated characters.

        Hyperlinks are supported, but you have to change the contents of
the link. The "HREF" tag should contain the name of the page in the
MSX disk, without extension. This means you should changes links like that:

        <A HREF="http://www.lsi.usp.br/~ricardo/brmsx.htm">

        ... must be changed to ...

        <A HREF="brmsx">

        The page BRMSX.HTZ must be present on the same directory
of FudeBrowser.

        Links inside the page (using the tag <A NAME="link">) are not
supported yet.

---------------------------------------------------------------------------
                                             
5. FudeBrowser Syntax

        To use FudeBrowser, you just need to type:

        FUDEBROW PAGE

        During the browsing, you can press the following keys:

        UP            - scroll one line up
        DOWN          - scroll one line down
        SHIFT+UP      - scroll one page up
        SHIFT+DOWN    - scroll one page down
        CTRL+UP       - go to top of document
        STOP          - change border color
        SELECT        - change cursor speed
        GRAPH+CURSOR  - move the cursor in the screen
        ENTER         - used to click on objects
        BACKSPACE     - load the previous page again
        HOME          - load the home page of the site  
        F1            - display the help text
        ESC           - exit to DOS

        To move the cursor, just use the cursor keys while holding the
GRAPH (LGRA) key. You can click on the links using the ENTER key. You can
also click on the scroll bar to scroll the screen.

        The BACKSPACE key load the previous page visited. FudeBrowser
stores the address of eight previously visited pages.

        If you have a joystick connected in port 1, then you can use it
to move the cursor. The button A can be used to click in the links,
and the button B is used to load the previous page visited.

        If you have an AdMouse adapter, then you can you a mouse with
FudeBrowser, by selecting AdMouse's joystick emulation mode.

        The HOME key load the home page of the site, which must have
the name INDEX.HTZ, and must be present in the same directory of
FudeBrowser.

        If you try to follow a link not present in the disk, then
the page 404.HTZ will be read. You can modify the 404.HTZ file
to suit your needs.

        Press F1 to show the help text. The help is stored in 
a file HELP.HTZ, which also can be modified to suit you needs.

        This version of FudeBrowser can read files bigger than 16kb,
if you have one or more Memory Mappers connected to your system,
up to a limit of 8 Mb of memory.

        Type "FUDEBROW /S" on the command prompt to get a description
of your system, including the maximum size of HTZ files you can read.

        FudeBrowser can also detect an ADVRAM and optimize itself for it.
Computers with ADVRAM can scroll the screen more or less 80% faster than 
a computer without it.

        Please note that a given version of FudeBrowser can only read .HTZs
generated by the equivalent version of WISE. If your .HTZ was generated with
WISE version 3.14, then only the FudeBrowser version 3.14 will read the file.

---------------------------------------------------------------------------

6. Files

        This pack you downloaded should have the following files:

        FUDEBROW.COM    - FudeBrowser MSX-DOS 1 executable
        FBROW.COM       - FlyBrowser  MSX-DOS 1 executable

        WISE.EXE        - WISE MS-DOS executable

        README.TXT      - this file
        CHANGES.TXT     - log of version changes

        INDEX.HTZ       - sample file
        404.HTZ         - sample file
        HELP.HTZ        - sample file
        GOONIES.HTZ     - sample file
        BRMSX.HTZ       - sample file
        BRSMS.HTZ       - sample file
        SHURATO.HTZ     - sample file
        SPECIAL.HTZ     - sample file
        WINNIE.HTZ      - sample file
        DANICA.HTZ      - sample file
        MCKELLAR.HTZ    - sample file

---------------------------------------------------------------------------

7. License

        This program is now free. Enjoy it.

        Coming soon: FudeBrowser for UZIX !

---------------------------------------------------------------------------

8. Request

        Say NO to Coca-Cola. Drink Maracuja'.

---------------------------------------------------------------------------

9. Credits

        Main Programming
                Ricardo Bittencourt

        Additional Programming
                Adriano Cunha
                Daniel Caetano
                Thomas G. Lane                

        Fonts
                Giovanni Nunes

        Icons
                Raul Tabajara

        Beta Testing
                Cyberknight
                Marcelo Raisinger
                Marco Antonio Simon Dal Poz
                Weber Roder Kai
                Werner Roder Kai
                people from #msxzone

        Fudeba
                Italo Valerio

        Official home page
                http://www.lsi.usp.br/~ricardo/msx.htm

        Unofficial home page
                http://skyscraper.fortunecity.com/klamath/892/brow.htm

        Project started at 1/5/1999. Last modification was on 27/5/2000.

        Send bug reports, comments and suggestions to ricardo@lsi.usp.br

        This program was made while listening to "Flash Gordon" soundtrack.
