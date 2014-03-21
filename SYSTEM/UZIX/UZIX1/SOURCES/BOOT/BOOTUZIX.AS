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
; BOOTUZIX - load the bootsector of UZIX from a
; drive and runs it
; (c) A&L Software 2001
;
	org	100H

	macro	SYSTEM, fun
	ld	c, fun
	call	5
	endm

	macro	PRINT, msg
	ld	de, msg
	SYSTEM	9
	endm

	ld	a,(82h)		; get drive letter
	and	223		; uppercase
	cp	'A'
	jr	c,error		; must be between A and H
	cp	'I'
	jr	nc,error
	ld	a,(83h)		; must have a ':' after the letter
	cp	':'
	jr	nz,error
	ld	de,0c000h
	SYSTEM	1Ah		; read boot sector at C000h	
	ld	a,(82h)
        and     223
	sub	'A'		; convert drive letter to drive number
	push	af
	ld	l,a
	ld	de,0
	ld	h,1
	SYSTEM	2Fh		; read absolute sector 0
	or	a
	jr	nz,loaderr
	ld	a,(0c003h)	; check signature
	cp	'U'
	jr	nz,noboot
	ld	a,(0c004h)
	cp	'Z'
	jr	nz,noboot
	ld	a,(0c005h)
	cp	'I'
	jr	nz,noboot
	ld	a,(0c006h)
	cp	'X'
	jr	nz,noboot
	pop	af
	ld	e,a		; select UZIX boot drive as default one
	SYSTEM	0Eh
	scf
	ld	hl,0c100h
	jp	0c01eh		; execute bootsector
	
error:	PRINT	driverr
error1:	ei
	ld	b,255
error2: halt
	djnz 	error2
	ld	ix,0
	ld	iy,(0fcc0h)
	call	1ch

loaderr:PRINT	booterr
	jr	error1

noboot:	PRINT	nouzix
	jr	error1
	
driverr:defm	'Invalid boot drive$'
	
booterr:defm	'Error reading bootsector$'

nouzix :defm	'Bootsector is not for UZIX$'

	end
