=======================================
*     ___       ____  _    ___  ___   *
*    /__  /__/ / / / /_\  /  / /__    *
*   ___/ ___/ /   / /__/ /__/ ___/    *
*       SYMBIOSIS MULTITASKING        *
*       BASED OPERATING SYSTEM        *
=======================================
     M S X   R E L E A S E   2 . 0
      Author: Prodatron/SymbiosiS
---------------------------------------
This archive contains:
---------------------------------------
[SymbOS-MSX-Full.DSK]
   SymbOS MSX Release 2.0 DSK version
Sub directories contain...
   \symbos\   Full application package
   \graphics\ Example SGX graphic files
   \music\    Example SKM music files

[SymbOS-MSX-Full.ZIP]
   SymbOS MSX Release 2.0 ZIP version
---------------------------------------
    For more information about this
        production please visit
   http://www.symbos.de/download.htm
=======================================

-------------------------------------------------------------------------------
!PLEASE READ!               HOW TO START SYMBOS MSX               !PLEASE READ!
-------------------------------------------------------------------------------
SymbOS can be started from MSX-DOS 1 or MSX-DOS 2:

SYMBOS [options] [d0[x[y]] device1.drv] [d1[x[y]] device2.drv]

Options:

f#[slot[subslot]]
    loads default driver for floppy disc (FDC) of type #. Slot and subslot
    number can be specified.
    - Types: 0=nothing, 1=Philips, 2=National, 3=SVI, 4=Microsol, 5=Panasonic
    - Example: SYMBOS F1 -> loads Philips (WD2793) driver.
    ATTENTION: Drivers 2 (National) and 4 (Microsol) hasn't been tested on a
        real machine yet but only in an emulator, and driver 3 (SVI) hasn't
        been tested at all!
        Driver 5 is not included yet! If your FDC is not supported, you always
        have to start SymbOS with the "F0" option, otherwise the system will
        crash!

m#[slot[subslot]]
    loads default driver for mass storage device of type #.
    - Types: 0=nothing, 6=Sunrise IDE, 7=Novaxis SCSI, 8=MegaSCSI
    - Example: SYMBOS M61 -> loads Sunrise IDE driver for slot 1.
    ATTENTION: Drivers 7,8 are not included yet!

d#[slot[subslot]] device.drv
    loads a user defined driver for FDC (0) or mass storage device (1) instead
    of a default one. You have to specify the driver's filename.

p#
    choose partition # as "C"/boot drive. If you have a mass storage device
    like the Sunrise IDE you may need this option. Please note, that some MSX
    FDISK software name partitions not in the logical order. The first MSX
    partition may be the logical partition 4, the second may be 3 etc. Because
    of this SymbOS uses partition 4 (usually drive "A" in MSX-DOS) as the
    default drive "C" (boot) partition, if no other partition is specified.

EXAMPLE: symbos f131 d11 sunrise.drv p4
    -> loads Philips (WD2793) driver for Slot 3/1 and Sunrise IDE driver for
       Slot 1. Partition 4 will be setup as drive C, and SymbOS will
       search on this partition for the configuration file ("SYMBOS.INI").
