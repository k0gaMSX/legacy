;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@       S Y M B O S   E X E   A P P L I C A T I O N   T E M P L A T E        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

org #1000
READ "SymbOS-Constants.asm"

;==============================================================================
;### CODE AREA ################################################################
;==============================================================================

;### APPLICATION HEADER #######################################################

;Definition (before the initialization phase)
prgdatcod       equ 0           ;Length of the code area (includes this header)
prgdatdat       equ 2           ;Length of the data area
prgdattra       equ 4           ;Length of the transfer area
prgdatorg       equ 6           ;Original origin of the assembler code
prgdatrel       equ 8           ;Number of entries in the relocator table
prgdatstk       equ 10          ;Length of the stack in bytes
prgdatcrn       equ 12          ;Length of crunched data      (*NOT YET SUPPORTED*)
prgdatctp       equ 14          ;Cruncher type (0=uncrunched) (*NOT YET SUPPORTED*)
prgdatnam       equ 15          ;Application name. The end of the string must be filled with 0.
prgdatidn       equ 48          ;"SymExe10" SymbOS executable file identification
prgdatcex       equ 56          ;Length of additional reserved code area memory
prgdatdex       equ 58          ;Length of additional reserved data area memory
prgdattex       equ 60          ;Length of additional reserved transfer area memory
prgdatres       equ 62          ;*RESERVED* (26 bytes)
prgdatver       equ 88          ;required OS version (minor, major)
prgdatism       equ 90          ;Application icon (small version), 8x8 pixel, SymbOS graphic format
prgdatibg       equ 109         ;Application icon (big version), 24x24 pixel, SymbOS graphic format
prgdatlen       equ 256         ;Total length of the header

;Definition (after the initialization phase)
prgpstdat       equ 6           ;Address of the data area
prgpsttra       equ 8           ;Address of the transfer area
prgpstspz       equ 10          ;Additional sub process IDs; 4 process IDs can be registered here
prgpstbnk       equ 14          ;Ram bank number (1-8), where the application is located
prgpstmem       equ 48          ;Additional memory areas; 8 memory areas can be registered here,
                                ;each entry consists of 5 bytes:
                                ;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
                                ;01  1W  Address
                                ;03  1W  Length
prgpstnum       equ 88          ;Application ID
prgpstprz       equ 89          ;Main process ID

;------------------------------------------------------------------------------
;Header data for this applications
prgcodbeg   dw prgdatbeg-prgcodbeg  ;length of the code area
            dw prgtrnbeg-prgdatbeg  ;length of the data area
            dw prgtrnend-prgtrnbeg  ;length of the transfer area
prgdatadr   dw #1000                ;original origin                    POST address of the data area
prgtrnadr   dw 0                    ;number of reloc table entries      POST address of the transfer
prgprztab   dw prgstk-prgtrnbeg     ;length of the stack                POST sub process IDs
            dw 0                    ;length of crunched data
prgbnknum   db 0                    ;cruncher type                      POST ram bank number (1-8)
            db "SymbOS EXE template":ds 32-19:db 0 ;Name
prgmemtab   db "SymExe10"           ;SymbOS executable identification   POST location of additional memory areas
            dw 0                    ;length of additional reserved code area memory
            dw 0                    ;length of additional reserved data area memory
            dw 0                    ;length of additional reserved transfer area memory
            ds 26                   ;*RESERVED*
            db 0,2                  ;required OS version (minor, major)
                                    ;application icon (small version), 8x8 pixel, SymbOS graphic format
prgicnsml   db 2,8,8:db #77,#00:db #8F,#CC:db #9F,#FF:db #AF,#1F:db #AF,#1F:db #CF,#2E:db #CF,#2E:db #77,#CC
                                    ;application icon (big version), 24x24 pixel, SymbOS graphic format
prgicnbig   db 6,24,24,#00,#00,#00,#00,#00,#00,#33,#FE,#00,#00,#00,#00,#47,#1F,#80,#FF,#CC,#00,#8F,#0F,#FF,#0F,#6C,#00,#8F,#0F,#0F,#0F,#6C,#00,#8F,#0F,#0F,#0F,#7D,#EE,#8F,#3E,#E3,#1F,#EF,#3E,#8F,#4B,#16,#EF,#0F,#6C,#8F,#82,#0A,#87
            db #0F,#6C,#9F,#0D,#05,#4F,#0F,#C8,#9E,#0A,#0A,#4B,#0F,#C8,#9E,#04,#05,#43,#1F,#80,#9E,#08,#02,#4B,#1F,#80,#9F,#0C,#05,#4F,#3E,#00,#9F,#82,#0A,#87,#3E,#00,#9F,#4B,#16,#C3,#6C,#00,#AF,#3E,#E3,#E7,#6C,#00,#EF,#0F,#0F,#F7
            db #C0,#00,#CF,#0F,#7F,#FB,#88,#00,#47,#7F,#F8,#B1,#CC,#00,#77,#F8,#80,#10,#EE,#00,#30,#80,#00,#00,#F7,#00,#00,#00,#00,#00,#72,#80,#00,#00,#00,#00,#30,#00
;------------------------------------------------------------------------------

;### APPLICATION CODE #########################################################

;### PRGPRZ -> Application process
prgprz  ;...
        jp prgend

;### PRGEND -> Quit application
prgend  ld a,(prgprzn)          ;application process is the sender
        db #dd:ld l,a
        db #dd:ld h,3           ;system manager process is the receiver
        ld iy,prgmsgb
        ld (iy+0),MSC_SYS_PRGEND    ;send "program end" command
        ld a,(prgcodbeg+prgpstnum)  ;and specy the application ID
        ld (iy+1),a
        rst #10
prgend1 rst #30                 ;wait until the end is coming...
        jr prgend1


;==============================================================================
;### DATA AREA ################################################################
;==============================================================================

prgdatbeg

;...

db 0    ;every area must have at least a length of 1 byte


;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================

prgtrnbeg
;### Stack for the applications main process
        ds 128      ;stack space
prgstk  ds 6*2      ;register predefinition
        dw prgprz   ;routine start address
prgprzn db 0        ;process ID

;### Message buffer
prgmsgb ds 14

;...

prgtrnend
