;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@              S Y M S T U D I O   S Y S T E M   L I B R A R Y               @
;@                      - SCREENSAVER SUPPORT ROUTINES -                      @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author: Prodatron / Symbiosis
;Date:   02.03.2007

;The SymbOS desktop manager supports the handling of screensaver applications.
;This library supports you in creating an own screensaver application.
;The existance of
;- "AppPrzN" (a byte, where the ID of the applications process is stored)
;- "AppMsgB" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;- "PrgDatCod" (the first byte of the header/code area)
;is required.

;The following additional routines are required and have to be implemented:
;- "ScrSav_ANIMAT" - place here the routine, which starts the animation
;- "ScrSav_CFGOPN" - place here the routine, which opens the configuration
;                    dialogue
;                    [optional; place a RET here, if you don't need this]
;- "ScrSav_MESSAG" - place a routine here, which proceeds additional messages
;                    (A=message type, IY=message buffer)
;                    [optional; place a RET here, if you don't need this]
;- "ScrSav_INIT" -   place a routine here, which does initialisation work,
;                    after the screensaver loaded its configuration data
;                    [optional; place a RET here, if you don't need this]

;The following data definitions are required:
;- "ScrSav_ID" -     contains a 4byte identifier string to validate the
;                    configuration data
;- "ScrSav_CONFIG" - the current configuration data is stored here, please fill
;                    it with the default configuration; it has to start with
;                    the 4byte identifier string
;EXAMPLE
;ScrSav_ID      db "RAIN"
;ScrSav_CONFIG  db "RAIN"
;               db 100      ;number of raindrops
;               dw #ff0     ;raindrop colour
;               db 2        ;raindrop speed
;               ds 64-8     ;the remain of the config data area is not used


Library ScrSav_MAIN
;******************************************************************************
;*** Name           ScreenSaver_Main
;*** Input/Ouput    [not a sub routine]
;*** Description    This can be used as the main routine of a screensaver
;***                application. You should place it directly at the starting
;***                point of the program code. It checks the received messages,
;***                calls the different functions of the screensaver and quits
;***                the application if required.
;******************************************************************************

        ld b,10             ;*** wait some time for the initial message
SavMai1 push bc
        rst #30
        ld a,(AppPrzN)
        db #dd:ld l,a
        db #dd:ld h,-1
        ld iy,AppMsgB
        rst #18
        db #dd:dec l
        pop bc
        jr z,SavMai3
        djnz SavMai1
        call ScrSav_ANIMAT      ;no message has been received -> start animation directly...
        jp SavEnd               ;...and quit after that

SavMai2 ld a,(AppPrzN)      ;*** wait for the next message
        db #dd:ld l,a
        db #dd:ld h,-1
        ld iy,AppMsgB
        rst #08                 ;sleep, until a new message appears
        db #dd:dec l
        jr nz,SavMai2

SavMai3 ld iy,AppMsgB       ;*** handle the received message
        ld a,(iy+0)
        cp MSC_SAV_INIT
        jp c,SavEnd             ;0=quit application
        jr z,SavIni             ;1=initialisation, load config data (p1=ram bank, p2/3=address)
        cp MSC_SAV_CONFIG
        jr nz,SavMai4           ;3=open configuration dialogue
        db #dd:ld a,h
        ld (ScrSav_CALLER),a    ;remember the caller process ID
        call ScrSav_CFGOPN
        jr SavMai2
SavMai4 jr nc,SavMai5
        call ScrSav_ANIMAT      ;2=start animation
        jr SavMai2
SavMai5 call ScrSav_MESSAG      ;test other messages
        jr SavMai2

SavIni  ld a,(PrgDatCod+14) ;*** load configuration and test, if valid; if yes, it will overwrite the default config
        add a:add a:add a:add a
        or (iy+1)
        ld l,(iy+2)
        ld h,(iy+3)
        ld de,ScrSav_TEMP       ;copy it to the temp buffer
        ld bc,64
        rst #20:dw jmp_bnkcop
        ld b,4                  ;test, if configuration is valid by comparing the 4byte-identifier
        ld hl,ScrSav_ID
        ld de,ScrSav_TEMP
SavIni1 ld a,(de)
        cp (hl)
        jp nz,SavMai2           ;it is not valid -> keep the default config
        inc de
        inc hl
        djnz SavIni1
        ld hl,ScrSav_TEMP       ;it is valid -> copy the temp data to the configuration
        ld de,ScrSav_CONFIG
        ld bc,64
        ldir
        call ScrSav_INIT        ;do initialisation work
        jp SavMai2

SavEnd  ld a,(AppPrzN)      ;*** quit the screensaver application
        db #dd:ld l,a
        ld a,3
        db #dd:ld h,a
        ld iy,AppMsgB
        ld (iy+0),MSC_SYS_PRGEND
        ld a,(PrgDatCod+88)
        ld (iy+1),a
        rst #10
SavEnd1 rst #30
        jr SavEnd1

ScrSav_TEMP     ds 64       ;this is used to load the config and check, if it's valid
ScrSav_CALLER   db 0        ;process ID of the caller process

EndLib

Library SyShell_CFGSAV
;******************************************************************************
;*** Name           ScreenSaver_Config_Save
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    This routine will send back the configuration data to the
;***                caller process, so that it can be written back later into
;***                the SYMBOS.INI file. Please use this function, after the
;***                user has finished modifying the settings in the config
;***                dialogue window and clicked on the Ok-button.
;******************************************************************************
        ld a,(ScrSav_CALLER)
        or a
        ret z
        db #dd:ld h,a
        ld a,(AppPrzN)
        db #dd:ld l,a
        ld iy,AppMsgB
        ld (iy+0),MSR_SAV_CONFIG
        ld a,(PrgDatCod+14)
        ld (iy+1),a
        ld hl,ScrSav_CONFIG
        ld (iy+2),l
        ld (iy+3),h
        rst #10
        ret
EndLib
