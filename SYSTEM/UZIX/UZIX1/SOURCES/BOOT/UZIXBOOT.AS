;*
;* UZIX - UNIX Implementation for MSX
;* (c) 1997-2001 Arcady Schekochikhin
;*		 Adriano C. R. da Cunha
;*
;* UZIX is based on UZI (UNIX Zilog Implementation)
;* UZI is a UNIX kernel clone, written for Z-80 systems, by Douglas Braun.
;*
;* This program is under GNU GPL, read COPYING for details
;*
;*/
;
; UZIX boot sector - primary bootstrap
; function: load and execute ZILO to load UZIX
; by A&L Software 1998-2000
;
	org	100H

BIAS	equ	0C000h-100H	; load point

	macro	SYSTEM, fun
	ld	c, fun
	call	0F37Dh
	endm

	macro	PRINT, msg
	ld	de, msg+BIAS
	SYSTEM	9
	endm

CR	equ	13
LF	equ	10

ROM_IF	equ	2Bh		; hardcoded interrupt frequence
ROM_MSX equ	2Dh		; hardcoded MSX kind
ENASLT	equ	0024h		; BIOS enable slot routine
ROMSLT	equ	0FCC1h		; MSX ROM slot

; must be conform with ZILO.AS
cfMSX	equ	0D000h		; temporary address of MSX ID byte
cfTICKS equ	0D001h		; temporary address of MSX freq byte
cfDISK	equ	0D002h		; temporary disk id byte for ZILO
cfDRIVE equ	0D003h		; temporary boot drive ID for ZILO

BZILOI	equ	2		; ZILO image initial sector
BZILOS	equ	4		; ZILO image length (in sectors)
BZILOA	equ	0100h		; ZILO origin address
BZILOT	equ	0A000h		; ZILO temporary address

; Boot signature (obs.: N/A means Not Applicable)
bootsig:defb	0EBh,0FEh,090h	; boot signature
	defm	'UZIXdisk'	; disk name
	defw	512		; sector size in bytes
	defb	2		; cluster size (in sectors)
	defw	1+1+55		; number of reserved sectors
	defb	1		; number of FATs (N/A, 1 for compatibility)
				; on UZIX: reserved sectors for kernel
	defw	1		; number of directory entries (N/A, 1 for compatibility)
	defw	720*2		; number of sectors on disk
id:	defb	0F9h		; disk ID
	defw	1		; FAT size in sectors (N/A, 1 for compatibility)
	defw	9		; number of sectors per track
	defw	2		; number of disk sides
	defw	1		; number of hidden sectors

; Start of boot program (IMPORTANT: can't be greater than 98 bytes)

if	MSXDOS2 = 1
start:  jr      start0		; MSXDOS2 boot signature
				; IT DOESN'T WORK WITH TURBO-R GT!!!
				; REMOVE THE SIGN BELOW OR DISK WILL NOT BOOT!
        defm    'VOL_ID'
        defb    000h,015h,075h,005h,01bh
        defb    000h,000h,000h,000h,000h
endif
if	MEGASCSI = 1
start:  jr      start0		; MSXDOS2 boot signature
        defm    'VOL_ID'
	defb	000h,066h,067h,048h,041h
	defm	'NO NAME    '
endif
if      IDE = 1
start:  jr      start0		; MSXDOS2 boot signature
        defm    'VOL_ID'
        defb    000h,052h,00ch,0aeh,0f3h
        defm    'IDEFDISK3.1FAT12   '
endif

start0:	ret	nc
	ld	(hl),67h
	inc	hl
	ld	(hl),0C0h
	ld	sp,0f51fh
	ld	de,messg+BIAS		; presents UZIX boot
	call	print+BIAS

; Select ROM in page 0 and 1
rom:	di
	ld	h,0
	ld	a,(ROMSLT)
	call	ENASLT
	ld	h,40h
	ld	a,(ROMSLT)
	call	ENASLT
	ei

; Set variables for ZILO
	ld	a,(id+BIAS)	; disk ID for ZILO
	ld	(cfDISK),a
	ld	a,(ROM_IF)	; MSX interrupt frequency
	ld	(cfTICKS),a

; Get hardware info
	ld	a,(ROM_MSX)	; MSX standard
	ld	(cfMSX),a

; Load ZILO
bzilo:	ld	de,BZILOT
	SYSTEM	1Ah		; set DTA
	SYSTEM	19h		; get drive number
	ld	(cfDRIVE),a
	ld	l,a
	ld	de,BZILOI	; start
	ld	h,BZILOS	; size
	SYSTEM	2Fh		; read absolute
	or	a
	jr	nz,loaderr

; Select 64k RAM
ram:	di
	in	a,(0A8h)
	call	iniram+BIAS
	out	(0A8h),a	; primary slot
	ld	a,(0FFFFh)
	cpl
	call	iniram+BIAS
	ld	(0FFFFh),a	; secondary slot

; Move ZILO to right place and execute it
execbz: ld	hl,(BZILOT+2)	; check for ZILO signature
	ld	de,'BZ'
	sbc	hl,de
	jr	nz,nozilo
	ld	hl,BZILOT	; loaded image
	ld	de,BZILOA	; ZILO original address
	ld	bc,BZILOS*512	; ZILO size
	push	de		; starting addr
	ldir			; move to real place in RAM
	ret			; start ZILO

; Mask bits in A to select 64k RAM
iniram: and	0F0h
	ld	b,a		; 3322----
	rrca
	rrca
	rrca
	rrca			; ----3322
	or	b		; 33223322
	ret

; Print a message in DE
print:	ld	c,9
	jp	0f37dh

; Boot messages and data
messg:	defm	'UZIX boot: '
loadm:	defm	'loading ZILO$'

; Display error message (no ZILO on disk) and hangs up MSX
nozilo: call	errorX+BIAS
	defm	' - no ZILO!$'

; Display error message (load error) and hangs up MSX
loaderr:call	errorX+BIAS
	defm	' - error!$'

errorX: pop	de
; Display error message in DE and hangs up MSX
error:	call	print+BIAS
error1: jr	error1

	org	bootsig+510
	defw	0AA55h	; boot sector signature

	end
