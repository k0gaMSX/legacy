DenYoNet is an Ethernet card for MSX computers, created by Dennis Koller
and Jos van den Biggelaar, and produced by Sunrise for MSX. In this
section you will find the software that I have developed for this card.

DENYOROM.COM: DenYoNet flash ROM loader 1.1. Tool to load the DenYoNet
flash ROM with a ROM code file.

NOTE: This ROM loader assumes that the MAC for the card is stored at
position 16 of the ROM file (that is, immediately after the MSX ROM
header) and provides three options: keep the MAC on the current card ROM
(default), use the MAC on the new ROM file, or manually specify a new
MAC. Please run the application without parameters for more information.

DENYOETH.ROM: DenYoNet Ethernet UNAPI BIOS 1.5. This is a ROM file that
will made your DenYoNet compatible with the Ethernet UNAPI specification,
so that you can use networking applications by installing a TCP/IP UNAPI
implementation such as InterNestor Lite.

DENYOTCP.ROM: DenYoNet TCP/IP UNAPI BIOS 0.6. This is a ROM file that
will made your DenYoNet compatible with the TCP/IP UNAPI specification,
so that you can use networking applications directly, without having to
install a separate TCP/IP stack.

DENYTCP2.ROM: An alternative version of DenYoNet TCP/IP UNAPI BIOS 0.6
that has the behavior of the ESC key reversed: BIOS is NOT initialized
if the key is NOT pressed at boot time, and is initialized if the key
is pressed.

DENYINIT.COM: DenYoNet TCP/IP BIOS initialization tool. If you boot your
computer while pressing ESC (or while not pressing it, if you use the
alternative BIOS), you can use this tool to initialize the BIOS. Usage:
denyinit <DenyoNet slot>[-<subslot>].


Version 0.6 is feature complete:
in addition to the TCP and UDP connectivity provided by the embedded
W5100, it has domain name resolver, DHCP client and support for sending
PINGs. This version will escalate to 1.0 after additional testing is
performed.

Note for Panasonic FS-A1 GT owners There is a known bug in
the DenYoNet TCP/IP UNAPI BIOS that manifests in MSX Turbo-R Panasonic
FS-A1 GT computers and prevents the computer from booting. If you own
a DenYoNet card and that MSX model (or any other model in which you
experiment the same problem) please apply the following workaround while
the bug is being investigated:

Flash the alternative BIOS version (DENYTCP2.ROM) in your DenYoNet.
Execute DENYINIT.COM from your AUTOEXEC.BAT, or manually before using
networking software.  An alternative method to initialize the DenYoNet
BIOS is by executing CALL DENYOINIT in the BASIC prompt.  .

