;*
;* UZIX - UNIX Implementation for MSX
;* (c) 1997-2001 Arcady Schekochikhin
;*		 Adriano C. R. da Cunha
;*
;* UZIX is based on UZI (UNIX Zilog Implementation)
;* UZI is a UNIX kernel clone written for Z-80 systems.
;* All code is public domain, not being based on any AT&T code.
;*
;* The author, Douglas Braun, can be reached at:
;*	7696 West Zayante Rd.
;*	Felton, CA 95018
;*	oliveb!intelca!mipos3!cadev4!dbraun
;*
;* This program is under GNU GPL, read COPYING for details
;*
;*/
;
;**********************************************************
;C Start Up code for MSX/UZIX
;*********************************************************/

; this file must be linked first
; absolute binary executable
; 8000h	UZI.AS
; 801Ch	ROM caller code
;  ...	UZIX kernel code
;  ...

	psect	text,global,pure
	psect	strings,global
	psect	const,global
	psect	data,global
	psect	bss,global

	global	_main
	global	start, __Lbss, __Hbss
	global	small_model

	psect	text

start:	jr	start0
	defm	'UZIX'		; signature for bootstraps
	
start0:	ld	de, __Lbss	; clear the BSS
	ld	hl, __Hbss
	or	a	; CLC
	sbc	hl, de
	ld	c, l
	ld	b, h
	dec	bc	; BC = counter-1
	ld	l, e
	ld	h, d	; HL = __Lbss
	inc	de	; DE = __Lbss+1
	ld	(hl), 0
	ldir		; clear bss - always >= 1 byte
	jp	_main	; NO RETURN

; ROM caller - this address: 801Ch
; You are able to use memory from 8000h to 801Bh - it is only once running code!

	defs	140	; space for ROM caller code
			
	psect	bss
small_model:
	defs	1

	end	start
