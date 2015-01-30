;Interrpt sample for kinrou 5th for SOLiD C

	aseg
	org	4000H

;In this file
	global	inton_,intoff_
	global	kinint_

timi	equ	0fd9fh
jpcode	equ	0f7h
MINTER	equ	6029H		;Kinrou 5th's interrupt entry

inton_:
	di
	ld	hl,timi
	ld	de,intsav
	ld	bc,5
	ldir
	ld	a,jpcode
	ld	(timi),a
	ld	a,(0f342h)
	ld	(timi+1),a
	ld	hl,intmain
	ld	(timi+2),hl
	ld	a,0c9H
	ld	(timi+4),a
	ei
	ret

intoff_:
	di
	ld	hl,intsav
	ld	de,timi
	ld	bc,5
	ldir
	ei
	ret

intsav:
	nop
	nop
	nop
	nop
	ret

intflag:
	defb	0ffh

intmain:
	di
	push	af
	push	hl
	push	de
	push	bc
	push	ix
	push	iy

	ld	a,(intflag)
	and	a
	jp	z,qrtint
	xor	a
	ld	(intflag),a

	ld	a,(kinint_)
	and	a
	call	nz,MINTER

iend:

ocall:
	call	intsav		;call old int
	ld	a,0ffh
	ld	(intflag),a
qrtint:
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	pop	af
	ei
	ret

kinint_:
	defb	0

	end
