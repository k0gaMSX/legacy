	MODULE	MEMCHR

;	void *memchr(adr,ch,cnt)

memchr_::
	ld	a,e
	cpir
	dec	hl
	ret	z	;found
	ld	hl,0	;not found
	ret

	ENDMODULE


	MODULE	MOVMEM

;	void movmem(from,to,cnt)
;	void setmem(from,ch,cnt)

setmem_::
	ld	a,b
	or	c
	ret	z
	ld	(hl),e
	ld	e,l
	ld	d,h
	inc	de
	dec	bc
movmem_::
	ld	a,b
	or	c
	ret	z
	ldir
	ret

	ENDMODULE


	MODULE	MEMSET

;	void *memset(adr,c,cnt)

memset_::
	push	hl
	call	setmem_##
	pop	hl
	ret

	ENDMODULE


	MODULE	MEMCPY

;	void *memcpy(to,from,n)

memcpy_::
	ld	a,b
	or	c
	ret	z
	push	hl
	ex	de,hl
	ldir
	pop	hl
	ret

	ENDMODULE


	MODULE	MEMMOVE

;	void *memmove(to,from,n)

memmove_::
	ld	a,b
	or	c
	ret	z
	push	hl
	ex	de,hl
	ld	a,d
	cp	h
	jr	nz,.1
	ld	a,e
	cp	l
.1:	jr	nc,.2
	ldir
	pop	hl
	ret
.2:	add	hl,bc
	ex	de,hl
	add	hl,bc
	ex	de,hl
	lddr
	pop	hl
	ret

	ENDMODULE


	MODULE	MEMCMP

;	int memcmp(s1,s2,n)

memcmp_::
	ld	a,(de)
	sub	(hl)
	jr	nz,.1
	inc	hl
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,memcmp_
	ld	h,a
	ld	l,a
	ret
.1:	ld	hl,1
	ret	nc
	ld	hl,-1
	ret

	ENDMODULE


	MODULE STRCPY
strcpy_::
	ex	de,hl
	push	de
.1:	ld	a,(hl)
	ldi
	or	a
	jp	nz,.1
	pop	hl
	ret
	ENDMODULE

	MODULE STRNCPY
strncpy_::
	ex	de,hl
	push	de
.2:	ld	a,(hl)
.3:	ldi
	jp	pe,.4
	or	a
	jp	nz,.2
	dec	hl
	jp	.3
.4:
	pop	hl
	ret
	ENDMODULE

	MODULE STRCAT
strcat_::
	xor	a
	ld	b,a
	ld	c,a
	push	hl
	cpir
	dec	hl
	ex	de,hl
.1:	ld	a,(hl)
	ldi
	or	a
	jp	nz,.1
	pop	hl
	ret
	ENDMODULE

	MODULE STRNCAT
strncat_::
	xor	a
	push	hl
	ld	bc,0
	cpir
	dec	hl
	ex	de,hl
.4:	ld	a,(hl)
	or	a
	jr	z,.5
	ldi
	jp	po,.4
.5:	xor	a
	ld	(de),a
	pop	hl
	ret
	ENDMODULE

	MODULE STRCMP
strcmp_::
	ex	de,hl
.6:	ld	a,(de)
	sub	(hl)
        jr	nz,.7
	inc	de
	inc	hl
	ld	a,(de)
	or	a
	jp	nz,.6
.7:
	ld	h,a
	ld	l,0
	ret
	ENDMODULE

	MODULE STRNCMP
strncmp_::
	ex	de,hl
.6:	ld	a,(de)
	sub	(hl)
        jr	nz,.7
	ld	a,(de)
	or	a
	jr	z,.7
	inc	de
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jp	nz,.6
.7:
	ld	h,a
	ld	l,0
	ret
	ENDMODULE

	MODULE STRCHR
strchr_::
	ld	a,(hl)
	cp	e
	ret	z
	inc	hl
	or	a
	jp	nz,strchr_
	ld	h,a
	ld	l,a
	ret
	ENDMODULE

	MODULE INRANGE
@inran::
	ld	a,(hl)
	or	a
	ret	z
	cp	e
	inc	hl
	jp	nz,@inran
	or	255
	ret
	ENDMODULE

	MODULE STRCSPN
strcspn_::
	ld	b,h
	ld	c,l
	ld	hl,0
.8:	ld	a,(bc)
	or	a
	ret	z
	push	hl
	ex	de,hl
	push	hl
	ld	e,a
	call	@inran##
	pop	de
	pop	hl
	ret	nz
	inc	hl
	inc	bc
	jp	.8
	ENDMODULE

	MODULE STRPBRK
strpbrk_::
	ld	a,(hl)
	or	a
	jr	z,.9
.10:	push	hl
	ld	l,(hl)
	push	de
	ex	de,hl
	call	@inran##
	pop	de
	pop	hl
	ret	nz
	inc	hl
	jp	.10
.9:	ld	h,a
	ld	l,a
	ret
	ENDMODULE

	MODULE STRLEN
strlen_::
	xor	a
	ld	b,a
	ld	c,a
	push	hl
	cpir
	pop	de
	scf
	sbc	hl,de
	ret
	ENDMODULE

	MODULE STRRCHR
strrchr_::
	ld	b,h
	ld	c,l
	ld	hl,0
.11:	ld	a,(bc)
	or	a
	ret	z
	cp	e
	jr	nz,.12
	ld	h,b
	ld	l,c
.12:	inc	bc
	jp	.11
	ENDMODULE

	MODULE STRLWR
strlwr_::
	push	hl
slwr1:	ld	a,(hl)
	or	a
	jr	z,slwr2
	call	tolower_##
	ld	(hl),a
	inc	hl
	jp	slwr1
slwr2:	pop	hl
	ret
	ENDMODULE

	MODULE STRUPR
strupr_::
	push	hl
slwr3:	ld	a,(hl)
	or	a
	jr	z,slwr4
	call	toupper_##
	ld	(hl),a
	inc	hl
	jp	slwr3
slwr4:	pop	hl
	ret
	ENDMODULE


	MODULE STRSPN
strspn_::
	ld	b,h
	ld	c,l
	ld	hl,0
.8:	ld	a,(bc)
	or	a
	ret	z
	push	hl
	ex	de,hl
	push	hl
	ld	e,a
	call	@inran##
	pop	de
	pop	hl
	ret	z
	inc	hl
	inc	bc
	jp	.8
	ENDMODULE

	MODULE STRSTR
strstr_::
        ld	a,(hl)
	or	a
	jp	nz,.13
	ld	l,a
	ld	h,a
	ret
.13:	push	hl
	push	de
.14:	ld	a,(de)
	or	a
	jr	z,.15
	cp	(hl)
	inc	hl
	inc	de
	jp	z,.14
	pop	de
	pop	hl
	inc	hl
	jp	strstr_
.15:	pop	de
	pop	hl
	ret
	ENDMODULE

	MODULE STRTOK
	CSEG
strtok_::
	ld	(?2),de
	ld	(?1),hl
	ld	A,L
	OR	H
	Jr	NZ,@0
	ld	hl,(?5)
	ld	(?1),hl
@0:
	ld	(?4),hl
@2:
	ld	hl,(?1)
	ld	a,(hl)
	inc	hl
	ld	(?1),hl
	or	a
	jr	z,@1
	ld	e,a
	ld	hl,(?2)
	CALL	@inran##
	jr	z,@2
	ld	hl,(?1)
	dec	hl
	ld	(hl),0
	inc	hl
	ld	(?5),hl
@1:	ld	hl,(?4)
	RET

	DSEG
?5:	DS	2
?1:	DS	2
?2:	DS	2
?4:	DS	2
	
        ENDMODULE

	MODULE RAND
	CSEG
srand_::
	ld	(seed),hl
	ret
rand_::
	ld	a,h
	or	a
	push	af
	call	?abshl##
	call	rnd1
	pop	af
	ret	p
	jp	?neghl##
rnd1:
	push	hl
	ld	hl,(seed)
	ld	a,r
	ld	b,a
rnd2:	rr	h
	rl	l
	adc	a,51
	xor	h
	ld	h,a
	djnz	rnd2
	ld	de,(seed)
	add	hl,de
	ld	(seed),hl
	res	7,h
	pop	de
	call	?DVNHD##
	ex	de,hl
	ret
seed:	dw	01001101011010011b
	ENDMODULE

	MODULE DIVTT
div_::	call	?dvihd##
	ld	(save1),hl
	ld	(save2),de
	ld	hl,save1
	ret
	DSEG
save1:	ds	2
save2:	ds	2
	ENDMODULE

	MODULE	atoi
	CSEG
atoi_::
	ex	de,hl
	xor	a
	ld	(?2),a
	ld	h,a
	ld	l,a
	ld	a,(de)
	cp	02Dh
	jr	z,@0
	cp	02Bh
	jr	z,@1
	jr	@2
@0:
	ld	a,001h
	ld	(?2),a
@1:
	inc	de
@2:
	ld	a,(de)
	cp	030h
	jr	c,@3
	ld	a,(de)
	cp	03Ah
	jr	nc,@3
	add	hl,hl
	ld	c,l
	ld	b,h
	add	hl,hl
	add	hl,hl
	add	hl,bc
	inc	de
	ld	c,a
	ld	b,000h
	add	hl,bc
	jr	@2
@3:
	ld	a,(?2)
	or	a
	ret	z
	xor	a
	sub	l
	ld	l,a
	ld	a,0
	sbc	a,h
	ld	h,a
	ret
	DSEG
?2:	DS	1
	ENDMODULE

	MODULE	STRTOL
;
;int strtoi(char *s, char **eptr, int base)
;
	CSEG
strtoi_::
	ld	(base),bc
	push	de
	ld	(s@),hl
	ex	de,hl
	xor	a
	ld	(sig),a
	ld	h,a
	ld	l,a
	ld	(n@),hl
	ld	a,(de)
	cp	02Dh
	jr	z,@4
	cp	02Bh
	jr	z,@5
	jr	@6
@4:
	ld	a,001h
	ld	(sig),a
@5:
	inc	de
	ld	(s@),de
@6:
	ld	a,c
	or	b
	jr	nz,@7
	ld	a,(de)
	cp	'0'
	jr	nz,@8
	ld	bc,00008h
	ld	(base),bc
	inc	de
	ld	(s@),de
	ld	a,(de)
	and	5Fh
	cp	'X'
	jr	nz,@10
	ld	bc,00010h
	ld	(base),bc
	inc	de
	ld	(s@),de
	jr	@10
@8:
	ld	bc,0000Ah
	ld	(base),bc
	jr	@10
@7:
	ld	a,c
	sub	010h
	or	b
	jr	nz,@10
	ld	a,(de)
	cp	'0'
	jr	nz,@10
	ld	hl,00001h
	add	hl,de
	ld	a,(hl)
	and	5Fh
	cp	'X'
	jr	nz,@10
	inc	hl
	ld	(s@),hl
@10:
	ld	e,c
	ld	d,b
	ld	hl,0000Ah
	call	?CPSHD##
	jr	nc,@12
	ld	a,039h
	jr	@13
@12:
	ld	a,c
	add	a,030h
@13:
	ld	(?16),a
	ld	e,c
	ld	d,b
	ld	hl,0000Ah
	call	?CPSHD##
	jr	nc,@14
	ld	a,c
	add	a,057h
	jr	@15
@14:
	ld	a,(?16)
@15:
	ld	(?17),a
@23:
	ld	hl,(s@)
	ld	a,(hl)
	inc	hl
	ld	(s@),hl
	call	tolower_##
	ld	(?15),a
	cp	'0'
	jr	c,@18
	ld	hl,(?16)
	cp	l
	jr	c,@17
	cp	061h
	jr	c,@18
	ld	hl,(?17)
	cp	l
	jr	nc,@18
@17:
	ld	de,(base)
	ld	hl,(n@)
	call	?MULHD##
	ex	de,hl
	ld	a,(?15)
	cp	03Ah
	jr	nc,@19
	ld	hl,0-30h
	jr	@20
@19:
	ld	hl,0-61h+10
@20:
	add	hl,de
	ld	b,0
	ld	c,a
	add	hl,bc
	add	hl,de
	ld	(n@),hl
	jr	@23
@18:
	ld	de,(s@)
	pop	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,(sig)
	ld	hl,(n@)
	or	a
	ret	z
	xor	a
	sub	l
	ld	l,a
	ld	a,0
	sbc	a,h
	ld	h,a
	ret

	DSEG
s@:	DS	2
base:	DS	2
sig:	DS	1
n@:	DS	2
?15:	DS	1
?16:	DS	1
?17:	DS	1
	ENDMODULE

	MODULE	qsort
_swp_:
@0:
	ld	a,l
	or	h
	ret	z
	ld	a,(de)
	ex	af,af'
	ld	a,(bc)
	ld	(de),A
	ex	af,af'
	ld	(bc),A
	inc	de
	inc	bc
	dec	hl
	jr	@0

	DSEG
?7:	DS	2
?10:	DS	2
?9:	DS	2
?11:	DS	2
?12:	DS	2
?13:	DS	2
?18:	DS	2
	CSEG
qsort_::
	ld	(?7),hl
	ld	hl,0FFB0h
	add	hl,sp
	ld	sp,hl
	ld	l,c
	ld	h,b
	ld	(?9),hl
	ex	de,hl
	ld	(?10),hl
	ld	hl,(?7)
	ex	de,hl
	ld	hl,00000h
	add	hl,sp
	ld	(hl),e
	inc	hl
	ld	(hl),d
	push	de
	ld	e,c
	ld	d,b
	push	de
	ld	hl,(?10)
	ex	de,hl
	ld	hl,0FFFFh
	add	hl,de
	pop	de
	call	?MULHD##
	pop	de
	add	hl,de
	call	?SAUHL##
	DW	40+2
	ld	hl,00000h
	ld	(?18),hl
@5:
	inc	h
	dec	h
	jp	m,@3
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,00002h
	add	hl,sp
	add	hl,de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	pop	hl
	add	hl,hl
	ex	de,hl
	ld	hl,00028h
	add	hl,sp
	add	hl,de
	ld	a,c
	sub	(hl)
	inc	hl
	ld	a,b
	sbc	a,(hl)
	jr	c,@4
	ld	hl,(?18)
	dec	hl
	ld	(?18),hl
	jr	@5
@4:
	ld	hl,(?18)
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,00002h
	add	hl,sp
	add	hl,de
	push	hl
	ld	hl,(?9)
	ld	c,l
	ld	b,h
	pop	hl
	ld	a,(hl)
	sub	c
	ld	e,a
	inc	hl
	ld	a,(hl)
	sbc	a,b
	ld	d,a
	ex	de,hl
	ld	(?12),hl
	pop	hl
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Ah
	add	hl,sp
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	(?13),hl
	ld	(?11),hl
@12:
	ld	hl,(?12)
	ld	de,(?13)
	ld	a,l
	sub	e
	ld	a,h
	sbc	a,d
	jp	nc,@6
	ex	de,hl
	ld	(?13),hl
	ex	de,hl
	add	hl,bc
	push	bc
@8:
	ld	(?12),hl
	push	bc
	push	hl
	ld	hl,@1
	push	hl
	call	?LAUHL##
	DW	92+2
	push	hl
	ld	hl,(?11)
	ex	de,hl
	ld	hl,(?12)
	ret
@1:
	pop	de
	pop	bc
	inc	h
	dec	h
	jp	p,@7
	ld	hl,(?12)
	add	hl,bc
	jr	@8
@7:
	push	bc
	push	de
	ld	hl,(?13)
	ex	de,hl
	ld	a,e
	sub	c
	ld	c,a
	ld	a,d
	sbc	a,b
	ld	b,a
	ld	l,c
	ld	h,b
	ld	(?13),hl
@10:
	ld	hl,(?12)
	ld	a,l
	sub	c
	ld	a,h
	sbc	a,b
	jr	nc,@9
	ld	hl,@2
	push	bc
	push	hl
	call	?LAUHL##
	DW	94+2
	push	hl
	ld	hl,(?11)
	ex	de,hl
	ld	l,c
	ld	h,b
	ret
@2:
	ex	de,hl
	ld	hl,00000h
	pop	bc
	call	?CPSHD##
	jr	nc,@9
	ld	hl,(?9)
	ld	a,c
	sub	l
	ld	c,a
	ld	a,b
	sbc	a,h
	ld	b,a
	ld	l,c
	ld	h,b
	ld	(?13),hl
	jr	@10
@9:
	pop	de
	pop	hl
	ld	a,e
	sub	c
	ld	a,d
	sbc	a,b
	jr	nc,@11
	call	_swp_
@11:
	pop	bc
	jp	@12
@6:
	ld	(?12),hl
	pop	hl
	ld	(?18),hl
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Ah
	add	hl,sp
	add	hl,de
	push	bc
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(?12)
	ex	de,hl
	pop	hl
	push	de
	call	_swp_
	ld	hl,(?18)
	ld	(?18),hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Ch
	add	hl,sp
	add	hl,de
	pop	bc
	ld	a,(hl)
	sub	c
	ld	e,a
	inc	hl
	ld	a,(hl)
	sbc	a,b
	ld	d,a
	push	de
	ld	hl,(?18)
	add	hl,hl
	ex	de,hl
	ld	hl,00004h
	add	hl,sp
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,c
	sub	e
	ld	l,a
	ld	a,b
	sbc	a,d
	ld	h,a
	pop	de
	call	?CPSHD##
	jr	nc,@13
	ld	l,c
	ld	h,b
	ld	(?12),hl
	ld	hl,(?18)
	ld	(?18),hl
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,00004h
	add	hl,sp
	add	hl,de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(?18)
	inc	hl
	add	hl,hl
	ex	de,hl
	ld	hl,00004h
	add	hl,sp
	add	hl,de
	ld	(hl),c
	inc	hl
	ld	(hl),b
	pop	hl
	ld	(?18),hl
	inc	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Ah
	add	hl,sp
	add	hl,de
	push	hl
	ld	hl,(?12)
	ld	c,l
	ld	b,h
	ld	hl,(?9)
	ld	a,c
	sub	l
	ld	e,a
	ld	a,b
	sbc	a,h
	ld	d,a
	ld	(?9),hl
	pop	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	l,c
	ld	h,b
	ex	de,hl
	ld	hl,(?9)
	ex	de,hl
	add	hl,de
	push	hl
	ld	hl,(?18)
	add	hl,hl
	ex	de,hl
	ld	hl,00004h
	add	hl,sp
	add	hl,de
	pop	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	jr	@14
@13:
	ld	l,c
	ld	h,b
	push	bc
	ex	de,hl
	ld	hl,(?9)
	ex	de,hl
	add	hl,de
	push	hl
	ld	hl,(?18)
	ld	(?18),hl
	inc	hl
	add	hl,hl
	push	hl
	ld	hl,00008h
	add	hl,sp
	ex	de,hl
	ld	(?9),hl
	ex	de,hl
	pop	de
	add	hl,de
	pop	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	hl,(?18)
	push	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Eh
	add	hl,sp
	add	hl,de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(?18)
	inc	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Eh
	add	hl,sp
	add	hl,de
	ld	(hl),c
	inc	hl
	ld	(hl),b
	pop	hl
	add	hl,hl
	ex	de,hl
	ld	hl,0002Ch
	add	hl,sp
	add	hl,de
	pop	bc
	ex	de,hl
	ld	hl,(?9)
	ex	de,hl
	ld	a,c
	sub	e
	ld	e,a
	ld	a,b
	sbc	a,d
	ld	d,a
	ld	(hl),e
	inc	hl
	ld	(hl),d
@14:
	pop	hl
	inc	hl
	ld	(?18),hl
	jp	@5
@3:
	ld	hl,00050h
	add	hl,sp
	ld	sp,hl
	ret
	ENDMODULE


	MODULE	bsear
	DSEG
?33:	DS	2
?37:	DS	2
	CSEG
bsearch_::
	ld	(?33),hl
	ex	de,hl
	ld	(?37),hl
@18:	ld	a,c
	or	b
	jr	z,@16
	ld	hl,@15
	push	bc
	push	hl
	ld	hl,10
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	ld	de,(?37)
	ld	hl,(?33)
	ret
;
;----------- call
;
@15:	ld	de,(?37)
	pop	bc
	ld	a,l
	or	h
	jr	nz,@17
	ld	hl,(?37)
	ret

@17:	push	de
	dec	bc
	ld	hl,6
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	pop	hl
	add	hl,de
	ld	(?37),hl
	jr	@18
;
@16:	ld	hl,00000h
	ret
	ENDMODULE



	MODULE free
	DSEG
_base_::DS	4
	CSEG
_alloc_::
	DW	0
	DSEG
?48:	DS	2
?49:	DS	2
	CSEG
free_::
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	ld	c,l
	ld	b,h
	ld	hl,(_alloc_)
	
	ld	(?49),hl
	ex	de,hl
@22:
	ld	a,e
	sub	c
	ld	a,d
	sbc	a,b
	jr	nc,@19
	ld	l,e
	ld	h,d
	ld	a,c
	sub	(hl)
	inc	hl
	ld	a,b
	sbc	a,(hl)
	jr	c,@20
@19:
	ld	l,e
	ld	h,d
	ld	a,e
	sub	(hl)
	inc	hl
	ld	a,d
	sbc	a,(hl)
	jr	c,@21
	ld	a,e
	sub	c
	ld	a,d
	sbc	a,b
	jr	c,@20
	ld	l,e
	ld	h,d
	ld	a,c
	sub	(hl)
	inc	hl
	ld	a,b
	sbc	a,(hl)
	jr	c,@20
@21:
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ld	(?49),hl
	ex	de,hl
	jr	@22
@20:
	ld	l,e
	ld	h,d
	push	hl
	ld	l,c
	ld	h,b
	ld	(?48),hl
	pop	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	push	bc
	ld	hl,(?48)
	ld	c,l
	ld	b,h
	ld	hl,00002h
	add	hl,bc
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,bc
	push	hl
	ld	l,c
	ld	h,b
	ld	(?48),hl
	pop	hl
	pop	bc
	push	de
	ld	a,l
	cp	c
	jr	nz,$+4
	ld	a,h
	cp	b
	jr	nz,@23
	ld	hl,(?48)
	push	hl
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	hl
	ld	hl,(?49)
	ld	(?49),hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	inc	hl
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	add	hl,de
	ex	de,hl
	pop	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ld	hl,(?49)
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	pop	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	jr	@24
@23:
	ex	de,hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(?48)
	ld	(hl),c
	inc	hl
	ld	(hl),b
@24:
	pop	de
	ld	hl,00002h
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,de
	push	de
	push	hl
	ld	hl,(?48)
	ld	c,l
	ld	b,h
	pop	hl
	ld	a,l
	cp	c
	jr	nz,$+4
	ld	a,h
	cp	b
	jr	nz,@25
	ld	hl,00002h
	add	hl,de
	push	de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	hl
	ld	hl,00002h
	add	hl,bc
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	add	hl,de
	ex	de,hl
	pop	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ld	l,c
	ld	h,b
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	pop	de
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	jr	@26
@25:
	ex	de,hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
@26:
	pop	de
	ex	de,hl
	ld	(_alloc_),hl
	ret
	ENDMODULE


	MODULE malloc
	DSEG
?59:	DS	2
?61:	DS	2
	CSEG
malloc_::
	inc	hl
	inc	hl
	inc	hl
	srl	h
	rr	l
	srl	h
	rr	l
	inc	hl
	ld	c,l
	ld	b,h
	ld	(?61),hl
	ld	hl,(_alloc_##)
	ld	(?59),hl
	ld	a,l
	or	h
	jr	nz,@27
	ld	hl,_base_##
	ld	(?59),hl
	push	hl
	ld	hl,_base_##
	ld	(_alloc_##),hl
	ld	(_base_##),hl
	ld	hl,00000h
	ld	(_base_##+2),hl
	pop	hl
@27:	ld	e,(hl)
	inc	hl
	ld	d,(hl)
@33:	ld	hl,00002h
	add	hl,de
	ld	a,(hl)
	sub	c
	inc	hl
	ld	a,(hl)
	sbc	a,b
	jr	c,@28
	ld	hl,00002h
	add	hl,de
	ld	a,(hl)
	cp	c
	inc	hl
	jr	nz,@29
	ld	a,(hl)
	cp	b
	jr	nz,@29
	ld	l,e
	ld	h,d
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(?59)
	ld	(hl),c
	inc	hl
	ld	(hl),b
	jr	@30
@29:
	ld	hl,00002h
	add	hl,de
	ld	a,(hl)
	sub	c
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	sbc	a,b
	ld	(hl),a
	ld	hl,00002h
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,de
	ex	de,hl
	ld	hl,00002h
	add	hl,de
	ld	(hl),c
	inc	hl
	ld	(hl),b
@30:
	ld	hl,(?59)
	ld	(_alloc_##),hl
	ld	hl,00004h
	add	hl,de
	ret
@28:
	ld	hl,(_alloc_##)
	ld	a,e
	cp	l
	jr	nz,@31
	ld	a,d
	cp	h
	jr	nz,@31
	ld	l,c
	ld	h,b
	add	hl,hl
	add	hl,hl
	call	sbrk_##
	ld	a,l
	and	h
	inc	a
	jr	nz,@32
	ld	hl,00000h
	ret
@32:
	push	hl
	inc	hl
	inc	hl
	ld	bc,(?61)
	ld	(hl),c
	inc	hl
	ld	(hl),b
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	push	bc
	call	free_##
	ld	hl,(_alloc_##)
	ex	de,hl
	pop	bc
@31:
	ex	de,hl
	ld	(?59),hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	jp	@33
	ENDMODULE



	MODULE calloc
	DSEG
?70:	DS	2
	CSEG
calloc_::
	ld	(?70),hl
	push	de
	call	?MULHD##
	call	malloc_##
	pop	de
	ld	a,l
	or	h
	jr	nz,@34
	ld	hl,00000h
	ret
@34:
	push	hl
	ld	hl,(?70)
	call	?MULHD##
	ld	c,l
	ld	b,h
	pop	hl
	ld	(hl),0
	push	hl
	ld	d,h
	ld	e,l
	inc	de
	dec	bc
	ldir
	pop	hl
	ret
	ENDMODULE

