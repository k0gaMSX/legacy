;[]------------------------------------------------------------[]
;|	C0.AS -- UZIX Start Up Code				|
;|	MSX/HTC/UZIX Run Time Library	version 1.0		|
;[]------------------------------------------------------------[]

	global	small_model
small_model equ 1
	psect	text,class=CODE
	psect	strings,class=CODE
	psect	const,class=CODE
	psect	data,class=DATA
	psect	bss,class=DATA
	psect	_bssend,class=DATA

	global	_main, _exit, __exit
	global	start

	signat	_exit,4152	; arg in DE
	signat	__exit,4152	; arg in DE
	psect 	text

; At the start, SP points to user stack.
	org	100h
;;; executable header layout
start:	defb	0C3h		; for ???
	defw	start0

	org	103h
e_flags: defb	0		; bit 7: 1-not refresh system vectors on swapin()
e_text:  defw	etext
e_data:  defw	edata
e_bss:	 defw	ebss
e_heap:	 defw	0
e_stack: defw	0
e_env:	 defw	__argc
;;; total size of header == 16 bytes

	org	110h
start0: 
	ld	(___stktop),sp

; Clear BSS
	ld	hl, (e_data)
	ex	de, hl
	ld	hl, (e_bss)
	or	a	; CLC
	sbc	hl, de
	ld	c, l
	ld	b, h
	dec	bc	; BC = counter-1
	ld	l, e
	ld	h, d	; HL = e_data
	inc	de	; DE = e_data+1
	ld	(hl), 0
	ldir		; clear bss - always >= 10 bytes

	pop	bc		; drop retaddr
; now there are the next stack structure:
;	+4 envp
;	+2 argv
; sp->	+0 argc
	ld	ix, 0
	add	ix, sp
	ld	l, (ix+4)
	ld	h, (ix+5)
	ld	(_environ),hl
	ld	l, (ix+2)
	ld	h, (ix+3)
	ld	(__argv),hl
	ld	l, (ix+0)
	ld	h, (ix+1)
	ld	(__argc),hl
start1:	
	call	_main
	pop	bc
	pop	bc
	pop	bc
	ex	de, hl		; exit arg in DE
_exit:
	push	de
	ld	hl, (___cleanup)
	ld	a, l
	or	h
	call	nz, indirect	; (*__cleanup)(exitcode, ???)
	pop	de
	jp	__exit		; to kernel - arg in DE

indirect:
	jp	(hl)

;[]------------------------------------------------------------[]
;|	Start Up Data Area					|
;|								|
;|	WARNING 	Do not move any variables in the data	|
;|			segment unless you're absolutely sure	|
;|			that it does not matter.		|
;|								|
;[]------------------------------------------------------------[]

	psect	data
etext:

;	Memory management variables
	global	___heapbase, ___brklvl, ___heaptop, ___stktop

___heapbase:	defw	ebss
___brklvl:	defw	ebss
___heaptop:	defw	ebss
___stktop:	defw	0

	psect	bss
	global	__argc, __argv, _environ, _errno, ___cleanup
edata:	
__argc:		defs	2
__argv:		defs	2
_environ:	defs	2
_errno:		defs	2
___cleanup:	defs	2

	psect	_bssend
ebss:

	end	start

