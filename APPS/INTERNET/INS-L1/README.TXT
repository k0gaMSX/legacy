Note: discontinued software
To get the latest version of InterNestor Lite, please take a look at
the current InterNestor Lite section. Version 1.x is discontinued.

Starting at version 2.0, InterNestor Lite implements the TCP/IP UNAPI
specification and is not compatible with versions 1.x: networking
applications targetting the TCP/IP UNAPI implementations will not work
on versions 1.x, and vice versa. For this reason, InterNestor Lite 1
is still available for download here, so you can still using the old
applications made for versions 1.x.

Networking application developers should target the TCP/IP UNAPI
specification instead of InterNestor Lite for new applications. Moreover,
to the extent possible, existing applications should be ported to target
the TCP/IP specification.

See also the InterNestor Lite project site on SourceForge.net.

InterNestor Lite is a TCP/IP stack that works on MSX2/2+/TR with at
least 128K RAM. It supports two kinds of hardware: serial port (RS232)
with modem, and the Ethernet UNAPI.

INL11.LZH: InterNestor Lite 1.1.1. Includes both the serial and the
Ethernet UNAPI version, as well as the Fossil driver (necessary for
the serial version), and the user's and programmer's manual in spanish
and english. It has support for UDP and TCP, as well as for sending and
capturing raw datagrams, and built-in resolver; a simple PING client,
a TFTP client/server, a TCP console -simplified Telnet client- and a
Telnet client with partial support for VT100 escape codes are included
(the first three applications include the source code).

NOTE: If you have an ObsoNET card, make sure you have BIOS version 1.1 on
it, which implements the Ethernet UNAPI specification; otherwise you will
not be able to use InterNestor Lite with your ObsoNET. You can download
the latest ObsoNET BIOS from the ObsoNET section.

FTP.COM: FTP client for InterNestor Lite 1.x. This application is similar
to the command-line based FTP client shipped with the Windows and Linux
operating systems. It requires DOS 2, and the commands that operate
on multiple files (MGET, MPUT and MDELETE) require also that NestorMan
be installed.

