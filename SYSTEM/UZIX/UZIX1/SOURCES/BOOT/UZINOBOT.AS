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
; UZIX boot sector - non bootable disk
; function: warn user that this is not a MSXDOS disk
; by A&L Software 1998
;
; WARNING: this program is only for MKFS program!
;
	org	100H

BIAS	equ	0C000h-100H	; bias to load point

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

; Boot signature (obs.: N/A means Not Applicable)
bootsig:defb	0EBh,0FEh,090h		; boot signature
	defm	'UZIXdisk'		; disk name
	defw	512			; sector size in bytes
	defb	2			; cluster size (in sectors)
	defw	1			; number of reserved sectors
	defb	0			; number of FATs (N/A)
					; on UZIX: reserved sectors for kernel
	defw	0			; number of directory entries (N/A)
	defw	720*2			; number of sectors on disk
id:	defb	0F9h			; disk ID
	defw	0			; FAT size in sectors (N/A)
	defw	9			; number of sectors per track
	defw	2			; number of disk sides
	defw	0			; number of hidden sectors

; Start of boot program (must have up to 98 bytes)
start:	ret	nc
	ld	(hl),56h
	inc	hl
	ld	(hl),0C0h
	ld	sp,0F51Fh	; setup stack
	PRINT	messg
	SYSTEM	8		; read key
	cp	27
	jp	z,4022h 	; ESC - go to BASIC
	di
	in	a,(0A8h)
	and	11111100B
	out	(0A8h),a	; primary slot
	ld	a,(0FFFFh)
	cpl
	and	11111111B
	ld	(0FFFFh),a	; secondary slot
	rst	0		; reboot

messg:	defm	'WARNING!'
	defb	07,CR,LF,LF
	defm	'This is a nonbootable UZIX disk.'
	defb	CR,LF
	defm	'Using it under MSXDOS can damage it.'
	defb	CR,LF,LF
	defm	'Hit ESC for BASIC or any key to reboot.$'

	org	bootsig+510
	defw	0AA55h	; boot sector signature

	end	start
