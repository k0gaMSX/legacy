;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@              S Y M S T U D I O   S Y S T E M   L I B R A R Y               @
;@                - SYMBOS SYMSHELL TEXT TERMINAL FUNCTIONS -                 @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author: Prodatron / Symbiosis
;Date:   26.08.2007

;SymShell provides a program environment with a text terminal. The input and
;output can be redirected from and to different sources and destinations.
;This library supports you in using the SymShell functions.
;The existance of
;- "AppPrzN" (a byte, where the ID of the applications process is stored)
;- "AppMsgB" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;- "PrgDatCod" (the first byte/word of the header/code area, which also
;  includes the total length of the code area)
;is required.

Library SyShell_PARALL
;******************************************************************************
;*** Name           SymShell_Parameters_All
;*** Input          -
;*** Output         (SyShell_TabParas) = list of parameters
;***                                     Byte0,1 = pointer
;***                                     Byte2   = length
;***                (SyShell_TabFlags) = list of flags (see above; a flag is
;***                                     recognized with a % at the beginning,
;***                                     which is skipped in this list)
;***                D                  = number of parameters
;***                E                  = number of flags
;***                ZF                 = if 1, no parameters and flags at all
;*** Destroyed      AF,BC,HL,IX,IY
;*** Description    This function fetches all parameters and flags from the
;***                command line and generates two pointer tables. A flag is
;***                recognized with a leading "%" char. A pointer to a flag
;***                shows to the first char behind the %.
;*** Example        A:\>EXAMPLE.COM filename.ext %x %all hello123
;***                This will generate two entries in the parameter table:
;***                - pointer to "filename.ext", length=12
;***                - pointer to "hello123", length=8
;***                And two entries in the flag table:
;***                - pointer to "x", length=1
;***                - pointer to "all", length=3
;***                Please note, that SymShell itself will add an own flag to
;***                the command line (see "SymShell_Parameters_Shell").
;******************************************************************************
        ld hl,(PrgDatCod)
        ld de,PrgDatCod
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld ix,SyShell_TabParas      ;IX = Parameter List
        ld iy,SyShell_TabFlags      ;IX = Flag      List
        ld bc,8*256+8       ;B=8-number of parameters, C=8-number of flags
SyHPAl1 push bc
        call SyHPAl2
        pop bc
        jr z,SyHPAl7
        ld a,(hl)
        cp "%"
        jr z,SyHPAl6
        ld (ix+0),l         ;Parameter
        ld (ix+1),h
        push hl
        call SyHPAl4
        pop hl
        ld (ix+2),e
        ld de,3
        add ix,de
        dec b
        jr nz,SyHPAl1
        jr SyHPAl7
SyHPAl6 inc hl              ;Flag
        ld (iy+0),l
        ld (iy+1),h
        push hl
        call SyHPAl4
        pop hl
        ld (iy+2),e
        ld de,3
        add iy,de
        dec c
        jr nz,SyHPAl1
SyHPAl7 ld a,8
        sub c
        ld e,a
        ld a,8
        sub b
        ld d,a
        or e
        ret
;HL=position inside the string -> jump to next string -> HL=next string, ZF=1 end reached
SyHPAl2 ld a,(hl)
        inc hl
        or a
        ret z
        cp " "
        jr nz,SyHPAl2
        dec hl
        ld (hl),0
SyHPAl3 inc hl
        ld a,(hl)
        cp " "
        jr z,SyHPAl3
        ld a,1
        or a
        ret
;HL=position inside the string -> E=length until the end
SyHPAl4 ld e,0
SyHPAl5 ld a,(hl)
        or a
        ret z
        cp " "
        ret z
        inc e
        inc hl
        jr SyHPAl5

SyShell_TabParas   ds 8*3
SyShell_TabFlags   ds 8*3

EndLib

Library SyShell_PARSHL
;******************************************************************************
;*** Name           SymShell_Parameters_Shell
;*** Input          (SyShell_TabFlags) = list of flags
;***                E                  = number of flags
;*** Output         CF        = error state (0 = ok, 1 = no shell parameters
;***                            found; application should quit itself at once)
;***                (ShlPrzN) = shell process ID
;***                (ShlScrX) = x length in chars of the text terminal window
;***                (ShlScrY) = y length in chars of the text terminal window
;*** Destroyed      AF,BC,HL,IX,IY
;*** Description    This function parses the SymShell info flag from the
;***                command line. The info flag is built like this:
;***                %spPPXXYY
;***                PP is the process ID of the SymShell application, XX and YY
;***                is the size of the text terminal window.
;***                Every SymShell-based application has to parse this flag
;***                with the help of this function, as at least the process ID
;***                is required for any communication with SymShell. You have
;***                to call SyShell_PARALL first (see "SymShell_Parameters_All")
;***                before you call this function, as the flag table has already
;***                to be generated.
;***                For additional information see also "Symshell Command Line
;***                Information" in the chapter "SymShell Text Terminal" of the
;***                Symbos Developer Documentation.
;******************************************************************************
        ld a,e
        or a
        jr z,SyHPSh6            ;no Flags -> error
        ld ix,SyShell_TabFlags
        ld bc,3
SyHPSh1 ld l,(ix+0)
        ld h,(ix+1)
        ld a,(hl)
        cp "s"
        jr nz,SyHPSh2
        inc hl
        ld a,(hl)
        cp "p"
        jr  z,SyHPSh3
SyHPSh2 add ix,bc
        dec e
        jr nz,SyHPSh1
SyHPSh6 scf                     ;no Shell-Data -> error
        ret
SyHPSh3 inc hl
        call SyHPSh4
        ld (ShlPrzN),a
        call SyHPSh4
        ld (ShlScrX),a
        call SyHPSh4
        ld (ShlScrY),a
        or a
        ret
;(HL)=2digit number -> A=number, HL=HL+2
SyHPSh4 call SyHPSh5
        add a
        ld d,a
        add a:add a
        add d
        ld d,a
        call SyHPSh5
        add d
        ret
SyHPSh5 ld a,(hl)
        sub "0"
        cp 10
        inc hl
        ret c
        pop hl      ;clear stack
        pop hl
        scf         ;wrong number -> error
        ret

ShlPrzN db 0    ;shell process ID
ShlScrX db 0    ;x length in chars of the text terminal window
ShlScrY db 0    ;y length in chars of the text terminal window

EndLib

Library SyShell_CHRINP
;******************************************************************************
;*** Name           SymShell_CharInput_Command
;*** Input          A  = Channel (0=Standard, 1=Keyboard)
;*** Output         ZF = EOF status (0=EOF)
;***                CF = Error state (0 = ok, 1 = error; A = error code)
;***                - If error status is 0 and there is no EOF:
;***                A  = Char
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Reads a char from an input source. The input source can be
;***                the standard channel or the console keyboard. Usually the
;***                standard channel is the console keyboard, too, but it can also
;***                be a textfile or another source, if redirection or piping is
;***                active.
;***                If the keyboard is used, this function won't return as long as
;***                no key is pressed. If the user pressed Control+C or if the end
;***                of the file (EOF) has been reached, the EOF flag will be set.
;******************************************************************************
        ld bc,MSR_SHL_CHRINP*256+MSC_SHL_CHRINP
        call SyShell_DoCommand
        ret c
        ld a,(iy+2)
        ret
EndLib

Library SyShell_STRINP
;******************************************************************************
;*** Name           SymShell_StringInput_Command
;*** Input          D  = Channel (0=Standard, 1=Keyboard)
;***                HL = String buffer address (must have a size of 256 bytes)
;***                E  = String buffer ram bank (0-15)
;*** Output         ZF = EOF status (0=EOF)
;***                CF = Error state (0 = ok, 1 = error; A = error code)
;***                - If error status is 0 and there is no EOF, the string
;***                  buffer contains the read line.
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Reads a string from an input source. The input source can be
;***                the standard channel or the console keyboard. Usually the
;***                standard channel is the console keyboard, too, but it can also
;***                be a textfile or another source, if redirection or piping is
;***                active.
;***                The maximum lenght of a string is 255 chars, so the buffer must
;***                have a size of 256 bytes (255 + terminator). A string is always
;***                terminated by 0.
;***                If the keyboard is used, this function won't return until the
;***                user typed in a text line and pressed the Return key. If the
;***                user pressed Control+C or if the end of the file (EOF) has been
;***                reached, the EOF flag will be set.
;******************************************************************************
        ld bc,MSR_SHL_STRINP*256+MSC_SHL_STRINP
        jp SyShell_DoCommand
EndLib

Library SyShell_CHROUT
;******************************************************************************
;*** Name           SymShell_CharOutput_Command
;*** Input          D  = Channel (0=Standard, 1=Screen)
;***                E  = Char
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a char to the output destination. The output destination
;***                can be the standard channel or the console text screen. Usually
;***                the standard channel is the console text screen, too, but it
;***                can also be a textfile or another destination, if redirection
;***                or piping is active.
;******************************************************************************
        ld bc,MSR_SHL_CHROUT*256+MSC_SHL_CHROUT
        jp SyShell_DoCommand
EndLib

Library SyShell_STROUT
;******************************************************************************
;*** Name           SymShell_StringOutput_Command
;*** Input          D  = Channel (0=Standard, 1=Screen)
;***                HL = String address (terminated by 0)
;***                E  = String ram bank (0-15)
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a string to the output destination. The output
;***                destination can be the standard channel or the console text
;***                screen. Usually the standard channel is the console text
;***                screen, too, but it can also be a textfile or another
;***                destination, if redirection or piping is active.
;***                A string has always to be terminated by 0.
;******************************************************************************
        push hl
        xor a
        ld bc,255
        cpir
        ld a,254
        sub c       ;A=string length
        pop hl
        ld bc,MSR_SHL_STROUT*256+MSC_SHL_STROUT
        jp SyShell_DoCommand
EndLib

Library SyShell_EXIT
;******************************************************************************
;*** Name           SymShell_Exit_Command
;*** Input          D  = Exit type (0 = quit, 1 = blur)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    The application informs SymShell about an exit event.
;***                If an application quits itself, SymShell has to be informed
;***                about that, so that it can remove the application from its
;***                internal management table. In this case the exit type has to be
;***                0 ("quit").
;***                If an application doesn't require the focus inside the text
;***                terminal anymore, it has to send exit type 1 ("blur"). The
;***                background is, that SymShell can run multiple applications in
;***                the same text terminal at the same time. User text inputs will
;***                only be sent to the application which has been started at first
;***                until it releases the focus and goes into blur mode. In this
;***                case the next application or the command line interpreter of
;***                the shell itself will receive the focus (the user can force the
;***                shell to get back focus at once by appending "&" at the end of
;***                the command line).
;******************************************************************************
        ld c,MSR_SHL_EXIT
        jp SyShell_SendMessage
EndLib


;### SUB ROUTINES #############################################################

Library SyShell_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                D  = Channel
;***                E  = Ram bank or char
;***                HL = String address (optional)
;***                B  = String length (optional)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the SymShell process
;******************************************************************************
        ld iy,AppMsgB
        ld (iy+0),c
        ld (iy+1),d
        ld (iy+2),e
        ld (iy+3),l
        ld (iy+4),h
        ld (iy+5),b
        ld a,(ShlPrzN)
        db #dd:ld h,a
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #10
        ret
EndLib

Library SyShell_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      F,BC,DE,HL,IX
;*** Description    Waits for a response message from the SymShell process.
;******************************************************************************
        ld iy,AppMsgB
SyHWMs1 ld a,(ShlPrzN)
        db #dd:ld h,a
        ld a,(AppPrzN)
        db #dd:ld l,a
        rst #08             ;wait for a SymShell message
        db #dd:dec l
        jr nz,SyHWMs1
        ld a,(iy+0)
        ret
EndLib

Library SyShell_DoCommand
;******************************************************************************
;*** Input          C       = Command
;***                A,HL,DE = additional parameters
;***                B       = Response type
;*** Output         CF      = Error state (0 = ok, 1 = error, A = error code)
;***                ZF      = EOF status (0=EOF) [optional]
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Executes a complete SymShell command.
;******************************************************************************
        push bc
        ld b,a
        call SyShell_SendMessage
        pop bc
SyHGRs1 push bc
        call SyShell_WaitMessage
        pop bc
        cp b
        jr nz,SyHGRs1
        ld a,(iy+3)     ;Error state
        ld c,(iy+1)     ;EOF (0=no eof)
        cp 1
        ccf             ;CF=0 no error
        inc c
        dec c           ;ZF=0 EOF
        ret
EndLib
