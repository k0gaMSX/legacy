;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@              S Y M S T U D I O   S Y S T E M   L I B R A R Y               @
;@                     - SYMBOS FILE MANAGER FUNCTIONS -                      @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author: Prodatron / Symbiosis
;Date:   30.04.2006

;This library supports you in using the file manager functions.
;Instead of including the following routines in your application code you may
;use the "SySystem_CallFunction" routine directly, so that you would save some
;overhead. In this case you can see this library just as an example, how to
;access the file manager.
;The existance of "AppPrzN" (a byte, where the ID of the applications process
;is stored) and "AppMsgB" (the message buffer, 14 bytes, which are placed in
;the transfer ram area) is required.


Library SyFile_FILNEW
;******************************************************************************
;*** Name           File_New
;*** Input          IXH  = File path and name ram bank (0-15)
;***                HL   = File path and name address
;***                A    = Attributes
;***                       Bit0 = 1 -> Read only
;***                       Bit1 = 1 -> Hidden
;***                       Bit2 = 1 -> System
;***                       Bit5 = 1 -> Archive
;*** Output         A    = Filehandler ID
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Creates a new file and opens it for read/write access. If the
;***                file was already existing, it will be emptied first. For
;***                additional information see 018 (FILOPN).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILNEW
        ret
EndLib

Library SyFile_FILOPN
;******************************************************************************
;*** Name           File_Open
;*** Input          IXH  = File path and name ram bank (0-15)
;***                HL   = File path and name address
;*** Output         A    = Filehandler ID
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens an existing file for read/write access. This means, that
;***                you can read and write in the file like you want. You can open
;***                up to 8 different files at the same time.
;***                For more information about the file path see the introduction
;***                of the DIRECTORY MANAGEMENT FUNCTIONS.
;***                The media will be reloaded first, if the device is set to
;***                "removeable media" and there is no other open file on the same
;***                device.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN
        ret
EndLib

Library SyFile_FILCLO
;******************************************************************************
;*** Name           File_Close
;*** Input          A    = Filehandler ID
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Closes an opened file. If there is unwritten data in the sector
;***                cache, it will be written to disc at once.
;***                This command closes a file in any case, even if an error
;***                occured.
;***                If an error occured during file reading/writing you must close
;***                the file, too, to have the filehandler free again!
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO
        ret
EndLib

Library SyFile_FILINP
;******************************************************************************
;*** Name           File_Input
;*** Input          A    = Filehandler ID
;***                HL   = Destination address
;***                E    = Destination ram bank (0-15)
;***                BC   = Number of bytes
;*** Output         BC   = Number of read bytes
;***                ZF   = 1 -> All requested bytes have been read
;***                       0 -> The end of the file has been reached, and less
;***                            bytes than requested have been read (check BC)
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,DE,HL,IX,IY
;*** Description    Reads a specified amount of bytes out of an opened file. After
;***                this operation the file pointer will be moved behind the last
;***                read byte. This means, that it is possible to read several
;***                blocks with different sizes out of an opened file. It doesn't
;***                matter, if you already did write operations, too.
;***                If you try to read more bytes than available, the zero flag
;***                will be reset. In any case BC contains the amount of read
;***                bytes.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP
        ret
EndLib

Library SyFile_FILOUT
;******************************************************************************
;*** Name           File_Output
;*** Input          A    = Filehandler ID
;***                HL   = Source address
;***                E    = Source ram bank (0-15)
;***                BC   = Number of bytes
;*** Output         BC   = Number of written bytes
;***                A    = 0 -> All bytes have been written
;***                       1 -> The device is full, and less bytes have been
;***                            written (check BC)
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,DE,HL,IX,IY
;*** Description    Writes a specified amount of bytes into an opened file. After
;***                this operation the file pointer will be moved behind the last
;***                written byte. If the file pointer has been somewhere in the
;***                middle of the file before this operation, the data at this
;***                place will be overwritten. If you have been at the end of the
;***                file, its length will be extended.
;***                You can write several blocks with different sizes, and it
;***                doesn't matter if you already read from the file before.
;***                It's possible, that not all bytes have been written, if the
;***                device is full. Register A will be 1 in this case. In any case
;***                BC contains the amount of written bytes.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOUT
        ret
EndLib

Library SyFile_FILPOI
;******************************************************************************
;*** Name           File_Pointer
;*** Input          A    = Filehandler ID
;***                IY,IX= Difference
;***                C    = Reference point
;***                       0 = File begin
;***                       1 = Current pointer position
;***                       2 = File end
;*** Output         IY,IX= new absolute pointer position
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL
;*** Description    Moves the file pointer to another position. The difference is
;***                specified with IY and IX, IY is the high word, IX the low word
;***                (difference = 65536 * IY + IX).
;***                You can also use this function to find out the length of an
;***                opened file. Just set IY,IX to 0 and choose 2 as the reference
;***                point type. The pointer will be placed behind the last byte of
;***                the file, so you will get its length in IY,IX.
;*** Examples       IY = 0,     IX = 1,   C = 1 -> Increases the position by 1
;***                IY = 65535, IX = -10, C = 2 -> Sets the pointer before the last
;***                                               10 bytes of the file
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILPOI
        ret
EndLib

Library SyFile_FILF2T
;******************************************************************************
;*** Name           File_Decode_Timestamp
;*** Input          BC   = Time code
;***                       bit  0- 4 = second/2
;***                       bit  5-10 = minute
;***                       bit 11-15 = hour
;***                DE   = Date code
;***                       bit  0- 4 = day (starting from 1)
;***                       bit  5- 8 = month (starting from 1)
;***                       bit  9-15 = year-1980
;*** Output         A    = second
;***                B    = minute
;***                C    = hour
;***                D    = day (starting from 1)
;***                E    = month (starting from 1)
;***                HL   = year
;*** Destroyed      F
;*** Description    Decodes the file timestamp, which is used for the file system.
;***                You can use this function after reading the timestamp of a
;***                file with 035 (DIRPRR) or 038 (DIRINP).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILF2T
        ret
EndLib

Library SyFile_FILT2F
;******************************************************************************
;*** Name           File_Encode_Timestamp
;*** Input          A    = second
;***                B    = minute
;***                C    = hour
;***                D    = day (starting from 1)
;***                E    = month (starting from 1)
;***                HL   = year
;*** Output         BC   = Time code (see FILF2T)
;***                DE   = Date code (see FILF2T)
;*** Destroyed      AF,HL,IX,IY
;*** Description    Encodes the file timestamp, which is used for the file system.
;***                You can use this function before changing the timestamp of a
;***                file with 034 (DIRPRS).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILT2F
        ret
EndLib

Library SyFile_FILLIN
;******************************************************************************
;*** Name           File_LineInput
;*** Input          A    = Filehandler ID
;***                HL   = Destination buffer address (size must be 255 bytes)
;***                E    = Destination buffer ram bank (0-15)
;*** Output         BC   = Number of read bytes (without terminator)
;***                ZF   = 0 -> 1 or more bytes have been loaded
;***                       1 -> EOF reached, nothing has been loaded
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,DE,HL,IX,IY
;*** Description    Reads one text line out of an opened file. A text line is
;***                terminated by a single 13, a single 10, a combination of 13+10,
;***                a combination of 10+13 or by a single 26 ("end of file" code).
;***                The line terminator will not be copied to the destination line
;***                buffer, but a 0 will be added behind the last char of the line.
;***                This function allows you to read a text file line by line at a
;***                very high speed, because you don't need to read single chars
;***                and check for line feeds by yourself.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILLIN
        ret
EndLib


Library SyFile_DIRDEV
;******************************************************************************
;*** Name           Directory_Device
;*** Input          A    = Driveletter ("A"-"Z")
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Selects the current drive.
;***                As your application is running in a multitasking environment,
;***                unfortunately this command does not make many sense, as other
;***                applications could select an other drive again.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRDEV
        ret
EndLib

Library SyFile_DIRPTH
;******************************************************************************
;*** Name           Directory_Path
;*** Input          IXH  = File path ram bank (0-15)
;***                HL   = File path address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Selects the current path for the current or a different
;***                drive. As your application is running in a multitasking
;***                environment, unfortunately this command does not make many
;***                sense, as other applications could select an other path
;***                again.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRPTH
        ret
EndLib

Library SyFile_DIRPRS
;******************************************************************************
;*** Name           Directory_Property_Set
;*** Input          IXH  = File path and name ram bank (0-15)
;***                HL   = File path and name address
;***                A    = Property type
;***                       0 = Attribute          -> C  = attribute
;***                                                      Bit0 = 1 -> Read only
;***                                                      Bit1 = 1 -> Hidden
;***                                                      Bit2 = 1 -> System
;***                                                      Bit5 = 1 -> Archive
;***                       1 = Timestamp modified -> BC = time code, DE = date code
;***                       2 = Timestamp created  -> BC = time code, DE = date code
;***                BC,DE= see above
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Changes a property of a file or a directory. You can set the
;***                attribute, the "created" time and the "modified" time.
;***                For more information about the time and date code see 023
;***                (FILF2T).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRPRS
        ret
EndLib

Library SyFile_DIRPRR
;******************************************************************************
;*** Name           Directory_Property_Get
;*** Input          IXH  = File path and name ram bank (0-15)
;***                HL   = File path and name address
;***                A    = Property type
;***                       0 = Attribute
;***                       1 = Timestamp modified
;***                       2 = Timestamp created
;*** Output         C    = Attributes (if requested)
;***                       Bit0 = 1 -> Read only
;***                       Bit1 = 1 -> Hidden
;***                       Bit2 = 1 -> System
;***                       Bit3 = 1 -> Volume ID
;***                       Bit4 = 1 -> Directory
;***                       Bit5 = 1 -> Archive
;***                BC,DE= Time and date code (if requested)
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,HL,IX,IY
;*** Description    Reads a property of a file or a directory.
;***                For more information about the time and date code see 023
;***                (FILF2T).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRPRR
        ret
EndLib

Library SyFile_DIRREN
;******************************************************************************
;*** Name           Directory_Rename
;*** Input          IXH  = Ram bank (0-15) of old and new file name
;***                HL   = Address of file path and old file name
;***                DE   = Address of new file name
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Renames a file or a directory. The new file name must not
;***                include a path. The function will fail, if a file or directory
;***                with the new name already exists.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRREN
        ret
EndLib

Library SyFile_DIRNEW
;******************************************************************************
;*** Name           Directory_New
;*** Input          IXH  = Directory path and name ram bank (0-15)
;***                HL   = Directory path and name address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Creates a new directory. The function will fail, if a file or
;***                directory with the same name already exists.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRNEW
        ret
EndLib

Library SyFile_DIRINP
;******************************************************************************
;*** Name           Directory_Input
;*** Input          IXH  = Directory path ram bank (0-15)
;***                HL   = Directory path address (may include a search mask)
;***                IXL  = forbidden attributes
;***                       Bit0 = 1 -> don't show read only files
;***                       Bit1 = 1 -> don't show hidden files
;***                       Bit2 = 1 -> don't show system files
;***                       Bit3 = 1 -> don't show volume ID entries
;***                       Bit4 = 1 -> don't show directories
;***                       Bit5 = 1 -> don't show archive files
;***                A    = Destination buffer ram bank (0-15)
;***                DE   = Destination buffer address
;***                BC   = Destination buffer length
;***                IY   = Number of entries, which should be skipped
;*** Output         HL   = Number of read entries
;***                BC   = Remaining unused space in the destination buffer
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,DE,IX,IY
;*** Data structure 00  4B  File length (32bit double word)
;***                04  1W  Date code, see 023 (FILF2T)
;***                06  1W  Time code, see 023 (FILF2T)
;***                08  1B  Attributes, see 035 (DIRPRR)
;***                09  ?B  File or sub directory name
;***                ??  1B  0 terminator
;*** Description    Reads the content of a directory. You can specify a name filter
;***                filter by adding a file mask to the path (* and ? are allowed)
;***                and an attribute filter. We recommend always to set Bit3
;***                (volume ID) of the attribute filter byte.
;***                The system skips the specified amount of entries first and
;***                then loads as many entries as exist or as there is place in the
;***                destination buffer. Please note, that the entries will not be
;***                sorted. Depending on its name every entry in the destination
;***                buffer can have a different length and is terminated with 0
;***                behind the file name. Filenames don't contain spaces.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRINP
        ret
EndLib

Library SyFile_DIRDEL
;******************************************************************************
;*** Name           Directory_DeleteFile
;*** Input          IXH  = File path and name/mask ram bank (0-15)
;***                HL   = File path and name/mask address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Deletes one or more files. You can delete multiple files by
;***                using a file mask (* and ? are allowed).
;***                This function can't be used for deleting directories.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRDEL
        ret
EndLib

Library SyFile_DIRRMD
;******************************************************************************
;*** Name           Directory_DeleteDirectory
;*** Input          IXH  = Directory path and name ram bank (0-15)
;***                HL   = Directory path and name address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Deletes a sub directory. The sub directory has to be empty
;***                and not read only, otherwise the operation will be aborted.
;***                You can specify the directory with or without "/" at the
;***                end of the full path.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRRMD
        ret
EndLib

Library SyFile_DIRMOV
;******************************************************************************
;*** Name           Directory_Move
;*** Input          IXH  = File/directory old and new path ram bank (0-15)
;***                HL   = File/directory source path and name address
;***                DE   = File/directory destination path address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Moves a file or sub directory into another directory of the
;***                same drive. That means, that the drive letter of the source
;***                path must be the same like the drive letter of the
;***                destination path, otherwise the operation will be aborted.
;***                You can either move files or sub directories with this
;***                function, in both cases the source path+name must not end
;***                with a "/".
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRMOV
        ret
EndLib

Library SyFile_DIRINF
;******************************************************************************
;*** Name           Directory_DriveInformation
;*** Input          A    = Driveletter ("A"-"Z")
;***                C    = Information type
;***                       0 = general drive information
;***                       1 = free and total amount of memory
;*** Output         - Information type 0:
;***                A    = Type
;***                       00 = Device does not exist
;***                       01 = Device is ready
;***                       02 = Device is not initialized
;***                       03 = Device is corrupt
;***                B    = Medium
;***                       01 = Floppy disc single side (Amsdos, PCW)
;***                       02 = Floppy disc double side (Fat 12)
;***                       08 = Ram disc
;***                       16 = IDE hard disc or CF card (Fat 16, Fat 32)
;***                C    = File system
;***                       01 = Amsdos Data
;***                       02 = Amsdos System
;***                       03 = PCW 180K
;***                       16 = Fat 12
;***                       17 = Fat 16
;***                       18 = Fat 32
;***                D    = Sectors per cluster
;***                IY,IX= Total number of clusters
;***                - Information type 1:
;***                HL,DE= Number of free 512Byte sectors
;***                IY,IX= Total number of clusters
;***                C    = Sectors per cluster
;***                - Information type 0 and 1:
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F
;*** Description    Returns information about one drive. This function can be
;***                used to find out the amount of free memory on one drive.
;***                Please note, that calculating the free amount of memory on
;***                a FAT16 device may take a while, as everytime the whole FAT
;***                (up to 128KB) needs to be scanned.
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DIRINF
        ret
EndLib

Library SyFile_DEVDIR
;******************************************************************************
;*** Name           Directory_Input_Extended
;*** Input          A    = [bit0-3] Destination buffer ram bank (0-15)
;***                       [bit4-7] Directory path ram bank (0-15)
;***                HL   = Directory path address (may include a search mask)
;***                DE   = Destination buffer address. This must first contain two
;***                       words with additional information at the beginning:
;***                       00  1W  Address of list control table
;***                       02  1W  Maximum number of entries
;***                       This function will overwrite this information and fill
;***                       the buffer with the directory data.
;***                BC   = Maximum size of destination buffer
;***                IXL  = forbidden attributes
;***                       Bit0 = 1 -> don't show read only files
;***                       Bit1 = 1 -> don't show hidden files
;***                       Bit2 = 1 -> don't show system files
;***                       Bit3 = 1 -> don't show volume ID entries
;***                       Bit4 = 1 -> don't show directories
;***                       Bit5 = 1 -> don't show archive files
;***                IY   = Number of entries, which should be skipped
;***                IXH  = Additional columns
;***                       Bit0 = 1 -> File size
;***                       Bit1 = 1 -> Date and time (last modified)
;***                       Bit2 = 1 -> Attributes
;*** Output         HL   = Number of read entries
;***                CF   = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      AF,BC,DE,IX,IY
;*** Description    This is a very powerful extension of the directory input
;***                (DIRINP) function. It reads the content of a directory and
;***                converts it into ready to use list control data. So if your
;***                application wants to display the content of a directory inside
;***                a list control, it can use this function and doesn't need to do
;***                any conversion jobs by itself. Also the list control itself can
;***                do the sorting of the directory.
;***                First you have to reserve two memory areas in the same ram
;***                bank. One area needs to be reserved inside the data ram area.
;***                It will contain the texts (file names, dates etc.) and numbers
;***                (file sizes) for the list control. You can choose any size, but
;***                we recommend at least 4000 Bytes. BC must contain its size,
;***                when you call the function. DE contains the address, and the
;***                low nibble of A the ram bank number.
;***                The second area needs to be reserved inside the transfer ram
;***                area of the same bank. It contains the data structure of the
;***                list control. It size is calculated like this:
;***                Size = Maximum_number_of_entries * (4 + Additional_columns * 2)
;***                So when you have two additional columns (like date and
;***                attributes) and want to load up to 100 entries, you need to
;***                reserve 800 bytes.
;***                As there are no more Z80-registers available, the address of
;***                this memory area and the maximum number of entries must be
;***                written to the beginning of the other memory area.
;***                For additional information about reading directories see 038
;***                (DIRINP).
;******************************************************************************
        call SySystem_CallFunction
        db MSC_SYS_SYSFIL
        db FNC_FIL_DEVDIR
        ret
EndLib


;### SUB ROUTINES #############################################################

Library SySystem_CallFunction
;******************************************************************************
;*** Name           System_CallFunction
;*** Input          ((SP+0)) = System manager command
;***                ((SP+1)) = Function ID
;***                AF,BC,DE,HL,IX,IY = Input for the function
;*** Output         AF,BC,DE,HL,IX,IY = Output from the function
;*** Destroyed      -
;*** Description    Calls a function via the system manager. This function is
;***                needed to have access to the file manager.
;******************************************************************************
        ld (AppMsgB+04),bc      ;copy registers into the message buffer
        ld (AppMsgB+06),de
        ld (AppMsgB+08),hl
        ld (AppMsgB+10),ix
        ld (AppMsgB+12),iy
        push af
        pop hl
        ld (AppMsgB+02),hl
        pop hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld (AppMsgB+00),de      ;module und funktion number
        ld a,e
        ld (SyCallN),a
        ld iy,AppMsgB
        ld a,(AppPrzN)
        db #dd:ld l,a
        ld a,3
        db #dd:ld h,a
        rst #10                 ;send message
SyCall1 rst #30
        ld iy,AppMsgB
        ld a,(AppPrzN)
        db #dd:ld l,a
        ld a,3
        db #dd:ld h,a
        rst #18                 ;wait for answer
        db #dd:dec l
        jr nz,SyCall1
        ld a,(AppMsgB)
        sub 128
        ld e,a
        ld a,(SyCallN)
        cp e
        jr nz,SyCall1
        ld hl,(AppMsgB+02)      ;get registers out of the message buffer
        push hl
        pop af
        ld bc,(AppMsgB+04)
        ld de,(AppMsgB+06)
        ld hl,(AppMsgB+08)
        ld ix,(AppMsgB+10)
        ld iy,(AppMsgB+12)
        ret
SyCallN db 0
EndLib
