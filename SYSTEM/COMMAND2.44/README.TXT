    MSX-DOS 2 COMMAND version 2.44
    (c) 1989 by MSX Association
    (c) 1997 by C.P.U.
    (c) 2010 by The New Image

    This is the original patch to rebuild COMMAND2.COM from version 2.20 or 
    version 2.31 to version 2.44. To avoid  problems with  copyrights, this 
    new version is released as a patch. COMMAND2.COM  version 2.20  or 2.31 
    to patch it to version 2.44.

    After many years of inactivity  The New Image  decided to  continue the 
    development of COMMAND2.COM. COMMAND2.COM version 2.44 was triggered by 
    a tab completion bugfix in version  2.42, which  is an  adapted version 
    2.40 released by Hardware Partners Nederland. There  also is  a version 
    2.43 which contains simple text fixes of version 2.42 released by KdL.

    To install COMMAND2.COM version 2.44, follow this procedure:

    To start COMMAND2.COM from floppy disk:

    - Copy the files COMMAND2.COM and MSXDOS2.SYS to this disk.
    - Restart the computer with this disk in  the drive.  Version 2.44 will 
      be installed automatically.
    - The new COMMAND2.COM is  installed on  the disk.  The old  version is 
      stored as COMMAND2.OLD.

    To start COMMAND2.COM from harddisk, CompactFlash or SD:

    - Change to the drive with the diskette.
    - Install COMMAND2.COM with INSTALL. INSTALL will  install COMMAND2.COM
      automatically on drive A:\. If you want it to be installed some place 
      else, provide the drive and directory as INSTALL parameter.  Example: 
      INSTALL B:\COMMAND. This  directory requires  the COMMAND2.COM  to be 
      installed to.
    - After a while the specified location (default A:\) will have  the new 
      version of COMMAND2.COM. The old version is stored as COMMAND2.OLD.

    INSTALL will check if you have a version of  COMMAND2.COM which  can be 
    patched. INSTALL can only patch COMMAND2.COM version 2.20 or 2.31.

    Version 2.44 fixes the tab completion  bug as  well, while  keeping the 
    circular feature of version 2.41. For the complete list of changes read 
    the HISTORY.TXT text file. For more detailed information on commands or 
    features read the respective .HLP files. Easy access is done  using the 
    built in HELP command.

    The files TO.COM and TREE.COM are now part of DOS version 2.41, and are 
    also  included in  this patchdisk. The old version of RRAMDISK.COM will 
    not run  under COMMAND2.COM  version 2.40,	therefore a  patch to  this 
    program  is also  included. The  new version  has no  features added or 
    removed.

    New external commands are MORE.COM and TYPEWW.COM. A simplified version 
    of MORE.COM, which only works correctly on text based display modes, is 
    already available for many years. This version of MORE.COM supports the 
    Kanji display modes as well. TYPEWW.COM types text files like  the TYPE 
    command, with the difference that a word  is printed  on the  next line 
    when it doesn't fit on the current line anymore (word-wrap).

    The files  DIR.BTM, COPY.BAT  and COPY.BTM are examples of the new pos- 
    sibilities	of batch  files. An  explanation of COPY.BAT can be read in 
    the help file IFF.HLP.

    To clarify some of the new features a few batch files are included:
    - IPSMASS.BTM     shows how multiple IPS files can be applied to a file 
                      using the new SHIFT batch command.
    - WWTYPE.BTM      another example for the SHIFT batch command.

    The file  SETALIAS.BAT contains some useful aliases. Of course you have 
    to	adapt some  of the  parameters yourself.  When starting the file, a 
    file called  ALIAS.DAT will  be created  in the root directory of drive 
    A:. Add ALIAS /L A:\ALIAS.DAT to your AUTOEXEC.BAT to load the aliases, 
    so that you don't have to execute the time-consuming SETALIAS.BAT.


    Any questions and/or remarks are welcome. Ideas, bug reports  and other 
    related messages can be sent to The New Image.

    Enjoy COMMAND2.COM version 2.44!

    website: http://www.tni.nl/
    e-mail:  bifi@msxnet.org
    IRC:     #msxdev on the Rizon network
