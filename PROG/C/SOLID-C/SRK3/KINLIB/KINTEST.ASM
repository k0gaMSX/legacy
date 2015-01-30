	.z80
;	SOLID C Compiler ver 1.00 (pass 2)

	cseg
?63999:
	db	77,117,115,105,99,32,100,97,116,97
	db	32,98,117,102,102,101,114,58,37,52
	db	88,10,0
?63998:
	db	75,73,78,82,79,85,53,46,68,82
	db	86,0
?63997:
	db	68,114,105,118,101,114,32,108,111,97
	db	100,32,79,75,32,33,10,0
?63996:
	db	77,117,115,105,99,32,102,105,108,101
	db	32,108,111,97,100,32,79,75,32,33
	db	10,0
?63995:
	db	83,101,116,117,112,32,101,114,114,111
	db	114,46,10,0
;{
main_:
	push	ix
	ld	ix,0
	add	ix,sp
	push	de
	push	bc
	push	bc
	push	bc
	ld	(ix-2),e
	ld	(ix-1),d
	ld	de,2
	call	?cpshd
	jp	nc,@0
	ld	hl,1
	call	exit_
@0:
	ld	hl,8192
	call	malloc_
	ld	(ix-8),l
	ld	(ix-7),h
	push	hl
	ld	a,l
	or	h
	jp	nz,@1
	ld	hl,1
	call	exit_
@1:
	pop	hl
	push	hl
	push	hl
	ld	bc,?63999
	push	bc
	ld	hl,2
	call	printf_
	pop	bc
	pop	bc
	ld	de,0
	ld	hl,?63998
	call	open_
	ld	(ix-6),l
	ld	(ix-5),h
	push	hl
	ld	a,l
	and	h
	inc	a
	jp	nz,@2
	ld	l,(ix-8)
	ld	h,(ix-7)
	call	free_
	ld	hl,1
	call	exit_
@2:
	pop	hl
	ld	de,24569
	ld	bc,8199
	push	hl
	call	read_
	ld	a,l
	or	h
	jp	nz,@3
	ld	l,(ix-8)
	ld	h,(ix-7)
	call	free_
	ld	l,(ix-6)
	ld	h,(ix-5)
	call	close_
	ld	hl,1
	call	exit_
@3:
	pop	hl
	call	close_
	ld	bc,?63997
	push	bc
	ld	bc,_iob_+28
	push	bc
	ld	hl,2
	call	fprintf_
	pop	bc
	pop	bc
	ld	e,(ix-2)
	ld	d,(ix-1)
	ld	hl,2
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	de,0
	call	open_
	ld	(ix-6),l
	ld	(ix-5),h
	ld	a,l
	and	h
	inc	a
	jp	nz,@4
	ld	l,(ix-8)
	ld	h,(ix-7)
	call	free_
	ld	hl,1
	call	exit_
@4:
	pop	de
	ld	l,(ix-6)
	ld	h,(ix-5)
	ld	bc,8192
	push	de
	push	hl
	call	read_
	ld	a,l
	or	h
	jp	nz,@5
	ld	l,(ix-6)
	ld	h,(ix-5)
	call	close_
	ld	hl,1
	call	exit_
@5:
	pop	hl
	call	close_
	ld	bc,?63996
	push	bc
	ld	bc,_iob_+28
	push	bc
	ld	hl,2
	call	fprintf_
	pop	bc
	pop	bc
	call	kinini_
	xor	a
	ld	(kinint_),a
	call	inton_
	pop	hl
	ld	de,0
	push	hl
	call	kinply2_
	pop	hl
	push	hl
	or	a
	jp	z,@6
	push	hl
	ld	bc,?63995
	push	bc
	ld	bc,_iob_+28
	push	bc
	ld	hl,2
	call	fprintf_
	pop	bc
	pop	bc
	call	intoff_
	pop	hl
	call	free_
	ld	hl,1
	call	exit_
@6:
	ld	a,1
	ld	(kinint_),a
@13:
	call	kilbuf_
	call	chget_
	ld	l,a
	ld	h,0
	call	toupper_
	ld	l,a
	ld	h,0
	push	hl
	ld	a,l
	sub	80
	or	h
	jp	z,@7
	ld	a,l
	sub	83
	or	h
	jp	z,@8
	ld	a,l
	sub	70
	or	h
	jp	z,@9
	ld	a,l
	sub	86
	or	h
	jp	z,@10
	jp	@11
@7:
	ld	l,(ix-8)
	ld	h,(ix-7)
	ld	de,0
	call	kinply2_
	ld	a,1
	ld	(kinint_),a
	ld	a,1
	jp	@11
@8:
	call	kinpau_
	jp	@11
@9:
	ld	a,16
	call	kinfade_
	xor	a
	ld	(kinint_),a
	jp	@11
@10:
	ld	l,(ix-4)
	ld	h,(ix-3)
	inc	hl
	ld	(ix-4),l
	ld	(ix-3),h
	ld	a,l
	sub	16
	ld	a,h
	sbc	a,0
	jp	c,@12
	ld	hl,0
	ld	(ix-4),l
	ld	(ix-3),h
@12:
	call	kinvol_
@11:
	pop	hl
	ld	a,l
	sub	81
	or	h
	jp	nz,@13
	call	kinstop_
	xor	a
	ld	(kinint_),a
	call	intoff_
	pop	hl
	call	free_
	ld	hl,0
	ld	sp,ix
	pop	ix
	ret
;}


	public	main_
	extrn	exit_
	extrn	malloc_
	extrn	printf_
	extrn	open_
	extrn	free_
	extrn	read_
	extrn	close_
	extrn	fprintf_
	extrn	_iob_
	extrn	kinini_
	extrn	kinint_
	extrn	inton_
	extrn	kinply2_
	extrn	intoff_
	extrn	kilbuf_
	extrn	chget_
	extrn	toupper_
	extrn	kinpau_
	extrn	kinfade_
	extrn	kinvol_
	extrn	kinstop_
	extrn	?cpshd

	end
