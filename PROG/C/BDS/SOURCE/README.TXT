=================================
BDS C Compiler/Linker source code
=================================

        "I, Leor Zolman, hereby release all rights to BDS C
    (all binary and source code modules, including compiler,
    linker, library sources, utilities, and all documentation)
    into the Public Domain.  Anyone is free to download, use,
    copy, modify, sell, fold, spindle or mutilate any part of
    this package forever more. If, however, anyone ever
    translates it to BASIC, FORTRAN or C#, *please* do not tell
    me."  
            Leor Zolman (leor@bdsoft.com)
            BD Software (www.bdsoft.com)
            9/20/2002 


===========
Posting Log
===========

9/21/2002:
    I guess I'm still Brain Damaged...I could have sworn I'd 
    zipped the CLINK source with CC and CC2, but it still wasn't in
    there. This time for SURE. CLINK is really, really there.

9/20/2002:
    Initial release.



======================
The Development System
======================

The first version of BDS C was CP/M-80 only, written in early 1979 a 2 MHz
IMSAI 8080 micro with the following configuration:

    IMSAI 8080 base system, blue Plexiglas top cover
    Anywhere between 24K - 56K of RAM, depending on how many of my 8K
        boards were working on any given day (those 21L02 1Kx1 static
        RAM chips ran HOT)  
    Processor Technology VDM-1 64x16 char display card (the H19 came
        along a LOT later)
    Sanyo 8" B&W video monitor
    Processor Technology 3P+S Parallel/Serial card (lots of solder)
    Sergeant's Sentry surplus parallel ASCII keyboard with custom
        breadboarded character latch
    Tarbell Floppy disk interface (Don Tarbell, you rule. By then, I'd
        retired the Tarbell Cassette Interface and JC Penney tape recorder)
    One 8" floppy drive. Or was it two? Eventually it was two...in any case,
        *that's* why BDS C had to be fast. If it weren't, I'd have gone
        insane waiting for it to compile anything.

Some equ's at the top of the major components, and their meanings:

alpha:  equ 0       ;true if "alpha-C" version

    Lifeboat Japan sold an OEM, stripped down version for Sony and Sharp
    consumer CP/M (MSX?) machines. They were moving something like 5-10 thousand
    copies per month at one point. 

motu:   equ 0       ;true if for Mark of the Unicorn

    I had a special version for Mark of the Unicorn, so they could compile
    stuff like Mince and Scribble and FinalWord without running out of table
    space. Scott Layson wrote the L2 linker so BDS C could be used for these
    tools.

trs80:  equ 0       ;true if  special TRASH-80 version

    What can I say? The original TRS-80's didn't have several ASCII keys like
    curlies, vertical bars, etc. etc...it took some special handling.

prerel: equ 0       ;true if `pre-release' is to be printed on startup
debug:  equ prerel

marc:   equ  false  ;true if MARC-resident version

    Ah, MARC. Did I talk about this in the online interview I did? Too much to
    say, now's not the time. I'll try to do justice to this entire episode at
    some point in the future...

THE END (for now)
