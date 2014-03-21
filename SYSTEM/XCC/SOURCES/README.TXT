Note to developer about the source structure:

The main directory contains:
xcc.gen
--> this can be compiled to xcc.com with gen80
--> It is a simple loader that loads the main
--> program, called xcc.ovl. The xcc.com loader
--> is very stable.

sources
--> This contains all the sources of the main program
--> Each individual sources can be compiled with gen80
--> into a rel file.
--> The rel files can be put together into the xcc.ovl
--> file with batch file link.bat, which calls l80

macs
--> Macro files that can be included from the gen files
--> in the sources directory.

rels
--> Empty directory, to hold the rel files
--> You have to create this directory yourself on your
--> hard-drive. CVS does not copy empty directories.

On my MSX, I have all the stuff with the above structure on
the hard drive. To be precise, in:
b:\ontw\xcc

When I want to work on XCC, I do the following:
b:
cd \ontw\xcc
1.bat

The 1.bat batch file copies everything from macs directory and
from rels directory to h:\ (the ram drive)
Furthermore, it copies following batch files to drive h:
xcg.bat : batch file to copy gen files back to b:\ontw\xcc\sources
xcr.bat : batch file to copy rel files back to b:\ontw\xcc\rels
xcm.bat : batch file to copy mac files back to b:\ontw\xcc\macs
xcb.bat : batch file to copy bat files back to b:\ontw\xcc

On top of that, it copies the various xcc files from b:\ontw\xcc
to h:\ (that is: xcc.com, xcc.ovl, xcc.hlp and xcc.cfg).

After that, it goes to directory b:\ontw\xcc\sources,
from which you can manually copy the gen files to drive h:

The idea is that all the actual work is done from drive h:, where
all the sources are together in the root directory. This to
facilitate the limitations of gen80 and l80, which do not know
about sub directories.


If you choose a different directory structure setup on your
hard-drive, then you should update the various batch files accordingly.

