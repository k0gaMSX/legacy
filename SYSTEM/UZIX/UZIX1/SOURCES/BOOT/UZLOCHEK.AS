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
; UZLOCHEK - check if drive H: is free to boot UZIX
; from MSX hard-disk interfaces
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

	ld	a,(80h)
	or	a
	jr	z,test
	ld	a,(82h)		; option '/L'
	cp	'/'
	jr	nz,test
	ld	a,(83h)
	cp	'L'
	jr	z,golock
	cp	'l'
	jr	z,golock
	jr	test
golock: ld	a,1		; so set 'lock' flag
	ld	(lock),a

test:	ld	b,0		; try clearing RAMDISK
	SYSTEM	68h
	or	a
	jr	nz,err		; can't do it? error.

        ld      de,filez
        ld      b,00000111B     ; [search for system/hidden/subdir/files]
        ld      ix,buffer
        ld      c,40h
        call    5
        or	a
        jr	z,err		; file was found? RAMdisk wasn't deleted. error!

	ld	b,2		; try creating a 32k RAMDISK
	SYSTEM	68h
	or	a
	jr	nz,err		; can't do it? error.

        ld      de,filez
        ld      b,00000111B     ; [search for system/hidden/subdir/files]
        ld      ix,buffer
        ld      c,40h
        call    5
        cp	0D7h		; if no file was found, that's ok.
        ret	z
        jr      err		; else error

err:	PRINT	errmsg		; print error message
	ld	a,(lock)
	or	a
	jr	nz,err1		; if 'lock' flag set, hangup MSX
	ld	bc,08062h
	jp	5		; else return to DOS (aborting batchfile)

err1:	di
err2:	jr	err2

lock:	defb	0

errmsg:	defb	13,10
	defm	'Drive H: is not available.'
	defb	13,10
	defm	'Cannot boot UZIX.'
	defb	13,10,'$'

filez:  defm    'H:\*.*'
        defb    0

buffer:
	end
