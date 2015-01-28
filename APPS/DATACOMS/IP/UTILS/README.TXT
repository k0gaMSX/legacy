PING.COM: Simple PING client 1.1. Sends one ping request automatically,
then sends additional requests when ENTER is pressed.

TFTP.COM: TFTP client/server 1.0. TFTP is a simple and straighforward
way to transfer single files between two computers. [Source code]

TCPCON.COM: TCP console 1.1. It is a simplified Telnet client, it just
sends data from the keyboard to the network and from the network to the
screen, ignoring the Telnet control codes.

FTP.COM: FTP client 1.0. Command-line based FTP client, requires MSX-DOS
2 to work. The multiple file management commands (MGET, MPUT and MDELETE)
require NestorMan to work. [Source code] (NOTE: Comments on the source
code of FTP.COM are mainly in Spanish, I'm sorry but I'm not going to
translate it to English. If anyone wants to do the job, I'll be happy
yo post the translated version here.)

SNTP.COM: SNTP client 1.0. Allows you to configure the clock of your MSX
by querying the current date and time to a time server. You can find a
list of public time server at the NTP pool page. [Source code]

TWEETER.COM: MSX trivial tweeter 1.0. Allows you to send messages to
Twitter from your MSX.
TWEETER.CHR: CP850 character map file. If this file is placed in the
same directory of TWEETER.COM, you will be able to include in your
tweetes special characters pertaining to the CP850 character set (western
european) such as vowels with tilde and others like ñ ¡ ¿. On japanese
MSX you can generate these characters by using NestorAcentos.

HGET.COM: HTTP file downloader 1.1. A (very) simplified version of the
popular tool WGET, it allows you to download files and resources by using
the HTTP protocol. Supports basic HTTP authentication and continuing the
retrieval of interrupted downloads. It has an "interactive" mode in which
the URL of the resource to retrieve can be obtained from the console
output of another program, by using pipelining (e.g. type url.txt |
hget con). Version 1.1 corrects some small bugs.

GETURL.COM: URL extractor 1.0. This is not strictly a network application,
but it may be useful when used together with HGET. It searches inside
a text file for a line with the format [urlname] url, then it sends the
URL to the console. For example, if you have a file named urls.txt with
one of the lines being [knm] www.konamiman.com, you can execute geturl
urls.txt knm | hget con as an equivalent of hget www.konamiman.com.

MSXTDB.LZH: MSX trivial dropbox 1.1. Dropbox is an online file storage
service which offers both free and paid plans (at the time of this
writing, there is one free plan that provides 2GB of storage space, and
two paid plans that provide 50GB and 100GB). MSX trivial dropbox is a
suite of programs that allows to manage, and to transfer files from/to,
a Dropbox account from your MSX. The download includes a user manual.

OBSOSMB.COM: ObsoSMB 1.0. ObsoSMB allows you to expose your MSX disk
drives as shared folders to machines running Microsoft Windows; this
is achieved by using SMB, a protocol defined by Microsoft for sharing
resources across a network. Yo can then perform any operation on the
exposed files and folders (transfer, rename, create, delete, change
attributes) by using Windows explorer or any other file manager from
your PC.

OBSOFTP.COM: ObsoFTP 1.0. ObsoFTP will turn your MSX into a FTP
server, allowing you to easily transfer files between your MSX and other
computers. This is a less powerful file sharing option than ObsoSMB, but
more interoperable as it does not require a Windows client.

Note about MSX trivial tweeter user authorization
Before the application can send tweets on your behalf, you will
need access to a computer with a web browser in order to perform an
authorization process; this must be done only once per Twitter account.

It works this way: MSX trivial tweeter will connect to Twitter in order
to get a temporary authorization token. Then, it will display you a long
and ugly URL that you must type on the address bar of a web browser. From
here, you confirm that you authorize MSX trivial tweeter to tweet on
your behalf. You get then a PIN code, that you must type on your MSX.

It is not my fault. The OAuth protocol is quite cumbersome on non-web
based Twitter clients.

Note about MSX trivial dropbox
Starting at version 1.1, MSX trivial dropbox is no longer a standalone
application. It uses Dropbox API v1, which requires mandatory usage of
HTTPS. MSX computers can't currently handle HTTPS (or any other protocol
on top of SSL/TLS), therefore it is necessary to use a proxy (located in
another computer) to convert plain TCP to SSL and the other way around
(an example of such proxy is stunnel). Please read the MSX trivial
dropbox user manual for details.

Also, as in the case of MSX trivial tweeter, a one-time authorization
process with the involvement a web browser is needed before using
the tool.

ETH.COM: Ethernet UNAPI control program 1.0. Allows you to perform various
control tasks on your Ethernet hardware, such as obtaining and changing
(when supported) the MAC address, or resetting the Ethernet hardware.

TCPIP.COM: TCP/IP UNAPI control program 1.0. Allows you to perform
various control tasks on any TCP/IP UNAPI implementation, such as manually
setting the IP addresses, or enabling/disabling the automatic reply to
incoming PINGs.


