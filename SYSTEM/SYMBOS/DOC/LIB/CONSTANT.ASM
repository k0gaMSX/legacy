;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                    S y m b O S   -   C o n s t a n t s                     @
;@                                                                            @
;@             (c) 2000-2007 by Prodatron / SymbiosiS (Jörn Mika)             @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;P R O C E S S - I D S
PRC_ID_KERNEL   equ 1   ;kernel process
PRC_ID_DESKTOP  equ 2   ;desktop manager process
PRC_ID_SYSTEM   equ 3   ;system manager process


;M E S S A G E S
;General
MSC_GEN_QUIT    equ 0   ;application is beeing asked, to quit itself
MSC_GEN_FOCUS   equ 255 ;application is beeing asked, to focus its window

;Kernel Commands
MSC_KRL_MTADDP  equ 1   ;add process (P1/2=stack, P3=priority (7 high - 1 low), P4=ram bank (0-8))
MSC_KRL_MTDELP  equ 2   ;delete process (P1=ID)
MSC_KRL_MTADDT  equ 3   ;add timer (P1/2=stack, P4=ram bank (0-8))
MSC_KRL_MTDELT  equ 4   ;delete timer (P1=ID)
MSC_KRL_MTSLPP  equ 5   ;set process to sleep mode
MSC_KRL_MTWAKP  equ 6   ;wake up process
MSC_KRL_TMADDT  equ 7   ;add counter service (P1/2=address, P3=ram bank, P4=process, P5=frequency)
MSC_KRL_TMDELT  equ 8   ;delete counter service (P1/2=address, P3=ram bank)
MSC_KRL_TMDELP  equ 9   ;delete all counter services of one process (P1=process ID)

;Kernel Responses
MSR_KRL_MTADDP  equ 129 ;process has been added (P1=0/1->ok/failed, P2=ID)
MSR_KRL_MTDELP  equ 130 ;process has been deleted
MSR_KRL_MTADDT  equ 131 ;timer process has been deleted (P1=0/1->ok/failed, P2=ID)
MSR_KRL_MTDELT  equ 132 ;timer has been removed
MSR_KRL_MTSLPP  equ 133 ;process is sleeping now
MSR_KRL_MTWAKP  equ 134 ;process has been waked up
MSR_KRL_TMADDT  equ 135 ;counter service has been added (P1=0/1->ok/failed)
MSR_KRL_TMDELT  equ 136 ;counter service has been deleted
MSR_KRL_TMDELP  equ 137 ;all counter services of a process have been deleted

;System Commands
MSC_SYS_PRGRUN  equ 16  ;load application or document (P1/2=address filename, P3=ram bank filename)
MSC_SYS_PRGEND  equ 17  ;quit application (P1=ID)
MSC_SYS_SYSWNX  equ 18  ;open dialogue to change current window (next) (-)
MSC_SYS_SYSWPR  equ 19  ;open dialogue to change current window (previouse) (vorheriges) (-)
MSC_SYS_PRGSTA  equ 20  ;open dialogue to load application or document (-)
MSC_SYS_SYSSEC  equ 21  ;open system secuity dialogue (-)
MSC_SYS_SYSQIT  equ 22  ;open shut shown dialogue (-)
MSC_SYS_SYSOFF  equ 23  ;shut down (-)
MSC_SYS_PRGSET  equ 24  ;start control panel (P1=submodul -> 0=main window, 1=display settings, 2=date/time)
MSC_SYS_PRGTSK  equ 25  ;start taskmanager (-)
MSC_SYS_SYSFIL  equ 26  ;call filemanager function (P1=number, P2-13=AF,BC,DE,HL,IX,IY)
MSC_SYS_SYSHLP  equ 27  ;start help (-)
MSC_SYS_SYSCFG  equ 28  ;call config function (P1=number, 0=load, 1=save, 2=reload background)
MSC_SYS_SYSWRN  equ 29  ;open message/confirm window (P1/2=adresse, P3=ram bank, P4=number of buttons)
MSC_SYS_PRGSRV  equ 30  ;shared service function (P4=type [0=search, 1=start, 2=release], P1/2=addresse 12char ID, P3=ram bank 12char ID or P3=program ID, if type=2)
MSC_SYS_SELOPN  equ 31  ;open fileselect dialogue (P6=filename ram bank, P8/9=filename address, P7=forbidden attributes, P10=max entries, P12=max buffer size)

;System Responses
MSR_SYS_PRGRUN  equ 144 ;application has been started (P1=result -> 0=ok, 1=file doesnt exist, 2=file is not executable, 3=error while loading  [P8=filemanager error code], 4=memory full, P8=app ID, P9=process ID)
MSR_SYS_SYSFIL  equ 154 ;filemanager function returned (P1=number, P2-13=AF,BC,DE,HL,IX,IY)
MSR_SYS_SYSWRN  equ 157 ;message/confirm window response (P1 -> 0=already in use, 1=opened [P2=number], 2=ok, 3=yes, 4=no, 5=cancel/close)
MSR_SYS_PRGSRV  equ 158 ;shared service function response (P1=state [5=not found, other codes see MSR_SYS_PRGRUN], P8=app ID, P9=process ID)
MSR_SYS_SELOPN  equ 159 ;message from fileselect dialogue (P1 -> 0=Ok, 1=cancel, 2=already in use, 3=no memory free, 4=no window free, -1=open ok, super window has been opened [P2=number])

;Desktop Commands
MSC_DSK_WINOPN  equ 32  ;open window (P1=ram bank, P2/3=address data record)
MSC_DSK_WINMEN  equ 33  ;redraw menu bar (P1=window ID) [only if focus]
MSC_DSK_WININH  equ 34  ;redraw window content (P1=window ID, P2=-1/-Num/Object, P3=Object) [only if focus]
MSC_DSK_WINTOL  equ 35  ;redraw window toolbar (P1=window ID) [only if focus]
MSC_DSK_WINTIT  equ 36  ;redraw window title (P1=window ID) [only if focus]
MSC_DSK_WINSTA  equ 37  ;redraw window status lien (P1=window ID) [only if focus]
MSC_DSK_WINMVX  equ 38  ;set content x offset (P1=window ID, P2/3=XPos) [only if focus]
MSC_DSK_WINMVY  equ 39  ;set content y offset (P1=window ID, P2/3=XPos) [only if focus]
MSC_DSK_WINTOP  equ 40  ;takes window to the front (P1=window ID) [always]
MSC_DSK_WINMAX  equ 41  ;maximize window (P1=window ID) [always]
MSC_DSK_WINMIN  equ 42  ;minimize window (P1=window ID) [always]
MSC_DSK_WINMID  equ 43  ;restore window size (P1=window ID) [always]
MSC_DSK_WINMOV  equ 44  ;moves window to a new position (P1=window ID, P2/3=XPos, P4/5=YPos) [always]
MSC_DSK_WINSIZ  equ 45  ;resize the window (P1=window ID, P2/3=XPos, P4/5=YPos) [always]
MSC_DSK_WINCLS  equ 46  ;closes and removes window (P1=window ID) [always]
MSC_DSK_WINDIN  equ 47  ;redraw window content, even if it hasnt focus (P1=window ID, P2=-1/-Num/Objekt, P3=Object) [always]
MSC_DSK_DSKSRV  equ 48  ;desktop service request (P1=type, P2-P5=parameters)
MSC_DSK_WINSLD  equ 49  ;redraw window scrollbars (P1=window ID) [only if focus]
MSC_DSK_WINPIN  equ 50  ;redraw window content part (P1=window ID, P2=-1/-Num/Object, P3=Object, P4/5=Xbeg, P6/7=Ybeg, P8/9=Xlen, P10/11=Ylen) [always]
MSC_DSK_WINSIN  equ 51  ;redraw content of a super control (P1=window ID, P2=super control ID, P3=SubObject) [always]

;Desktop Responses
MSR_DSK_WOPNER  equ 160 ;open window failed; the maximum of 32 windows has been reached
MSR_DSK_WOPNOK  equ 161 ;open window successfull (P4=number)
MSR_DSK_WCLICK  equ 162 ;window has been clicked (P1=window number, P2=action, P3=subspezification, P4/5,P6/7,P8/9=parameters)
MSR_DSK_DSKSRV  equ 163 ;desktop service answer (P1=type, P2-P5=parameters)
MSR_DSK_WFOCUS  equ 164 ;window got/lost focus (P1=window number, P2=type [0=blur, 1=focus])
MSR_DSK_CFOCUS  equ 165 ;control focus changed (P1=window number, P2=control number, P3=reason [0=mouse click/wheel, 1=tab key])
MSR_DSK_WRESIZ  equ 166 ;window has been resized (P1=window number)
MSR_DSK_WSCROL  equ 167 ;window content has been scrolled (P1=window number)

;Shell Commands
MSC_SHL_CHRINP  equ 64  ;char is requested (P1=channel [0=standard, 1=keyboard])
MSC_SHL_STRINP  equ 65  ;line is requested (P1=channel [0=standard, 1=keyboard], P2=ram bank, P3/4=address)
MSC_SHL_CHROUT  equ 66  ;char should be writtten (P1=channel [0=standard, 1=screen], P2=char)
MSC_SHL_STROUT  equ 67  ;line should be writtten (P1=channel [0=standard, 1=screen], P2=ram bank, P3/4=address, P5=length)
MSC_SHL_EXIT    equ 68  ;application released focus or quit itself (P1 -> 0=quit, 1=blur)

;Shell Responses
MSR_SHL_CHRINP  equ 192 ;char has been received (P1=EOF-flag [0=no EOF], P2=char, P3=error status)
MSR_SHL_STRINP  equ 193 ;line has been received (P1=EOF-flag [0=no EOF], P3=error status)
MSR_SHL_CHROUT  equ 194 ;char has been written (P3=error status)
MSR_SHL_STROUT  equ 195 ;line has been written (P3=error status)

;Screensaver Messages
MSC_SAV_INIT    equ 1   ;initialises the screen saver (P1=bank of config data, P2/3=address of config data [64bytes])
MSC_SAV_START   equ 2   ;start screen saver
MSC_SAV_CONFIG  equ 3   ;open screen savers own config window (at the end the screen saver has to send the result back to the sender)
MSR_SAV_CONFIG  equ 4   ;returns user adjusted screen saver config data (P1=bank of config data, P2/3=address of config data [64bytes])


;D E S K T O P - A C T I O N S
DSK_ACT_CLOSE   equ 5   ;close button has been clicked or ALT+F4 has been pressed
DSK_ACT_MENU    equ 6   ;menu entry has been clicked (P8/9=menu entry value)
DSK_ACT_CONTENT equ 14  ;a control of the content has been clicked (P3=sub spec [see dsk_sub...], P4=key or P4/5=Xpos within the window, P6/7=Ypos, P8/9=control value)
DSK_ACT_TOOLBAR equ 15  ;a control of the toolbar has been clicked (see DSK_ACT_CONTENT)
DSK_ACT_KEY     equ 16  ;key has been pressed without touching/modifying a control (P4=Ascii Code)

DSK_SUB_MLCLICK equ 0   ;left mouse button has been clicked
DSK_SUB_MRCLICK equ 1   ;right mouse button has been clicked
DSK_SUB_MDCLICK equ 2   ;double click with the left mouse button
DSK_SUB_MMCLICK equ 3   ;middle mouse button has been clicked
DSK_SUB_KEY     equ 7   ;keyboard has been clicked and did modify/click a control (P4=Ascii Code)
DSK_SUB_MWHEEL  equ 8   ;mouse wheel has been moved (P4=Offset)


;D E S K T O P - S E R V I C E S
DSK_SRV_MODGET  equ 1   ;get screen mode (output P2=mode)
DSK_SRV_MODSET  equ 2   ;set screen mode (input P2=mode)
DSK_SRV_COLGET  equ 3   ;get colour      (input P2=number, output P2=number, P3/4=RGB value)
DSK_SRV_COLSET  equ 4   ;set colour      (input P2=number, P3/4=RGB value)
DSK_SRV_DSKSTP  equ 5   ;freeze desktop  (input P2=type [0=Pen0, 1=Raster, 2=background, 255=no screen modification, switch off mouse])
DSK_SRV_DSKCNT  equ 6   ;continue desktop
DSK_SRV_DSKPNT  equ 7   ;clear desktop   (Eingabe P2=Typ [0=Pen0, 1=Raster, 2=background])
DSK_SRV_DSKBGR  equ 8   ;initialize and redraw desktop background
DSK_SRV_DSKPLT  equ 9   ;redraw the complete desktop


;J U M P S
jmp_memsum  equ #8100 ;MEMSUM
jmp_sysinf  equ #8103 ;SYSINF
jmp_clcnum  equ #8106 ;CLCNUM
jmp_mtgcnt  equ #8109 ;MTGCNT
jmp_timget  equ #810C ;TIMGET
jmp_timset  equ #810F ;TIMSET
jmp_memget  equ #8118 ;MEMGET
jmp_memfre  equ #811B ;MEMFRE
jmp_memsiz  equ #811E ;MEMSIZ
jmp_meminf  equ #8121 ;MEMINF
jmp_bnkrwd  equ #8124 ;BNKRWD
jmp_bnkwwd  equ #8127 ;BNKWWD
jmp_bnkrbt  equ #812A ;BNKRBT
jmp_bnkwbt  equ #812D ;BNKWBT
jmp_bnkcop  equ #8130 ;BNKCOP
jmp_bnkget  equ #8133 ;BNKGET
                      ;**empty**
jmp_scrget  equ #8139 ;SCRGET
jmp_mosget  equ #813C ;MOSGET
jmp_moskey  equ #813F ;MOSKEY
jmp_bnk16c  equ #8142 ;BNK16C
jmp_keytst  equ #8145 ;KEYTST
jmp_keysta  equ #8148 ;KEYSTA
jmp_keyput  equ #814B ;KEYPUT
jmp_bufput  equ #814E ;BUFPUT
jmp_bufget  equ #8151 ;BUFGET
jmp_bufsta  equ #8154 ;BUFSTA


;Filemanager Functions (call via MSC_SYS_SYSFIL)
FNC_FIL_STOINI  equ 000
FNC_FIL_STONEW  equ 001
FNC_FIL_STORLD  equ 002
FNC_FIL_STODEL  equ 003
FNC_FIL_STOINP  equ 004
FNC_FIL_STOOUT  equ 005
FNC_FIL_STOACT  equ 006
FNC_FIL_STOINF  equ 007

FNC_FIL_DEVDIR  equ 013
FNC_FIL_DEVINI  equ 014
FNC_FIL_DEVSET  equ 015

FNC_FIL_FILINI  equ 016
FNC_FIL_FILNEW  equ 017
FNC_FIL_FILOPN  equ 018
FNC_FIL_FILCLO  equ 019
FNC_FIL_FILINP  equ 020
FNC_FIL_FILOUT  equ 021
FNC_FIL_FILPOI  equ 022
FNC_FIL_FILF2T  equ 023
FNC_FIL_FILT2F  equ 024
FNC_FIL_FILLIN  equ 025

FNC_FIL_DIRDEV  equ 032
FNC_FIL_DIRPTH  equ 033
FNC_FIL_DIRPRS  equ 034
FNC_FIL_DIRPRR  equ 035
FNC_FIL_DIRREN  equ 036
FNC_FIL_DIRNEW  equ 037
FNC_FIL_DIRINP  equ 038
FNC_FIL_DIRDEL  equ 039
FNC_FIL_DIRRMD  equ 040
FNC_FIL_DIRMOV  equ 041
FNC_FIL_DIRINF  equ 042
