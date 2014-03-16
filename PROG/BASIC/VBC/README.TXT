SOLiD VBasic, version 2.7
=========================

Here it goes, a BASIC compiler for MSXDOS.
This version must be considered a wide public beta,
and it contains some bugs that are listed below.

RUNNING
--------------------------------------
To use the compiler you must have:
  a) compiler itself;
  b) library files: bk.rel, basend.rel and ilib.irl
  c) AS assembler and LD linker
All the stuff can be downloaded from SOLiD home page
at http://www.glasnet.ru/~msxegor/msx.html

To compile your program, save it in ASCII format
as a <filename>.BAS (note BAS extension) and then
type the following command:

	BAS <filename>

(note NO extension)
If no errors occur, you will get <filename>.COM
MSDOS executive.


LANGUAGE
--------------------------------------
Supported features:
+  MSX-2 BASIC, file in ASCII format.
+  Some of MSX-2+ BASIC features like set scroll
+  WHILE/WEND extension
+  LOOP WHILE/UNTIL extension

Unsupported features:
+  LOAD/SAVE,CLOAD/CSAVE,MERGE and BLOAD/BSAVE (except for BLOAD,S) commands
+  ERASE not supported  and causes error
+  Arrays must be defined once, with constant length.
+  CLEAR works differently; only string variables cleared
+  X commands of play and draw macro languages not supported
+  Maximum two-dimensioned arrays supported (sorry for this one)
+  RESUSME without parametres may cause errors (or may not, this depends)
+  Vaiables of same names and different types not supported

Other differences
+  RUN executes DOS COM file
+  DEFINT A-Z by default!
+  Lines may NOT be numbered
+  (maybe something else, I don't remember)


KNOWN BUGS
---------------------------------
This version of compiler and libraries was written for a very
tignt configuration. This is not portable, I know, but it was
written in the times when the very single MSX architecture in
Russia (USSR back then) was Yamaha MSX.
The programs are written to be fast, using direct hardware
access where possible. This mapy cause troubles when running
on systems much different from Yamaha. In opposite, most
Philips MSX users will probably NOT face any troubles at all.

Bug list follows:
+  RST30 used to call BIOS in libraries. May cause troubles
   on MSXes with RAM in extended slot 0 (Daewoo)
+  Direct slot switching in float point routines. May cause
   problems on computers with SUB-ROM in extended slot 0
+  Some library routines may occasionaly cause trouble with
   DOS 2.


DISCLAIMER
----------------------------------
This program is PUBLIC DOMAIN BETA.
Feel free to report bugs and suggestions to Egor VOZNESSENSKI,
the autor, at msxegor@glasnet.ru
If I get enough responce, I shall produce a new, enhanced
version, as well as good documentation in english.

Home page:
	http://www.glasnet.ru/~msxegor
