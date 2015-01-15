; BIT BLITTER ROUTINES FOR HI-TECH C
;--------------------------------------------------------------

; void cpyv2v(sx1, sy1, sx2, sy2, sp, dx, dy, dp, logop)
; unsigned int sx1, sy1, sx2, sy2;
; unsigned char sp;
; unsigned int dx, dy;
; unsigned char dp;
; unsigned char logop;


; CPYV2V: copy vram to vram. Parameters:
;
;	sx1	=	start x1
;	sy1	=	start y1
;	sx2	=	end x2
;	sy2	=	end y2
;	sp	=	source page
;	dx	=	dest x
;	dy	=	dest y
;	dp	=	dest page
;	logop	=	logical operation



LINWRK	equ	0FC18h			; temp
CPYSRC	equ	LINWRK
CPYDST	equ	CPYSRC+2
SCRMOD	equ	0FCAFh
GRPACX	equ	0FCB7h
GRPACY	equ	0FCB9h

	psect	text
	global	_cpyv2v,_setind,csv,cret


_cpyv2v:
	call	csv
	ld	e,(ix+6)
	ld	d,(ix+7)	; DE=sx1
	ld	l,(ix+8)
	ld	h,(ix+9)	; HL=sy1
	ld	a,(ix+14)	; A=sp
	ld	(CPYSRC),a
	ld	c,(ix+16)
	ld	b,(ix+17)	; BC=dx
	ld	(GRPACX),bc
	ld	c,(ix+18)
	ld	b,(ix+19)	; BC=dy
	ld	(GRPACY),bc
	ld	a,(ix+20)	; A=dest page
	ld	(CPYDST),A
	ld	a,(ix+22)	; A=logop
	ld	b,a		; logop in B
	push	de		; save source x start
	push	bc		; save logical operation
	ld	a,32		; begin writing from register #32
	call	_setind
	out	(c),e		; set source x start
	out	(c),d
	out	(c),l		; set source y start
	ld	a,(CPYSRC)
	add	a,h
	out	(c),a
	push	hl		; save source y start
	ld	hl,(GRPACX)	; set destination x
	out	(c),l
	out	(c),h
	ld	hl,(GRPACY)	; set destination y
	out	(c),l
	ld	a,(CPYDST)
	add	a,h
	out	(c),a
	ld	b,0		; initialize value for ARG
				; i.e. assume x/y is to the right/down
	ld	a,(GRPACX)	; get destination x
	or	e		; OR with x source
	ld	l,(ix+10)
	ld	h,(ix+11)	; HL=sx2
	sbc	hl,de		; hl = x_end - x_start
	jr	nc,xdot_pos	; x offset is positive
	ld	a,(GRPACX)
	cpl
	ld	d,a
	ld	a,e
	cpl
	or	d
	ex	de,hl			; negate hl
	ld	hl,0
	sbc	hl,de
	set	2,b
xdot_pos:
	inc	hl
	out	(c),l			; set number of dots for x
	out	(c),h
	or	l			; or with number of dots for x
	pop	de			; restore y_start
	ld	l,(ix+12)
	ld	h,(ix+13)	; HL=sy2
	sbc	hl,de		; hl = y_end - y_start
	jr	nc,ydot_pos	; y offset is positive
	ex	de,hl		; negate hl
	ld	hl,1
	sbc	hl,de
	set	3,b
ydot_pos:
	inc	hl
	out	(c),l			; set number of dots for y
	out	(c),h
	out	(c),a			; dummy (skip register #44)
	out	(c),b			; set the argument register
;
;	see if we can use high speed move
;
	ld	b,a			; set byte boundary flag in b
	pop	hl			; restore logical operation code in h
	pop	de			; restore source x start
	ld	a,h			; logical operation specified?
	and	a
	jr	nz,vv_logical		; yes, move logically
	ld	a,(SCRMOD)
	cp	8			; screen 8?
	jr	z,vv_hs 		; yes, always use high speed
	cp	6			; screen 6?
	jr	z,vv_check_4		; yes, check lower 2 bits
	ld	a,b			; on byte boundary?
	rrca
	jr	nc,vv_hs		; yes, use high speed move
	jr	vv_logical		; no, use logical move

vv_check_4:
	ld	a,b			; on byte boundary?
	and	11B
	jr	z,vv_hs 		; yes, use high speed move
vv_logical:
	ld	a,h			; get the logical operation code
	or	10010000B		; issue lmmm command
	out	(c),a
	jp	cret
;
;	we can use high speed moves
;
vv_hs:
	ld	a,11010000B
	out	(c),a
	jp	cret


;--------------------------------------------------------------

;	MODULE	DOTS

;	Calculate number of bytes from number of pixels (X and Y)
;
;	For screen 5/7

	psect	text
	global	_DOT_5,_DOT_6,_MUL32

_DOT_5:
	push	hl
	push	bc
	push	de
	ld	l,b			; HL = pixels per line
	ld	h,d
	ld	d,0			; DE = lines
	call	_MUL32			; HL:BC = HL * DE in rnd()
	rr	l			; divide by 2 to get number of bytes
	rr	b
	rr	c
	jr	dots_6_0

;
;	For screen 6
;
_DOT_6:
	push	hl
	push	bc
	push	de
	ld	l,b			; HL = pixels per line
	ld	h,d
	ld	d,0			; DE = lines
	call	_MUL32			; HL:BC = HL * DE
	xor	a			; clear to check remainder
	rr	l			; divide by 4 to get number of bytes
	rr	b
	rr	c
	rra
	rr	b
	rr	c
	rra
	add	a,0FFh			; set carry if Acc<>0
dots_6_0:
	ld	a,c			; round up
	adc	a,0
	jr	z,dots_6_1		; lower byte is 0
	inc	b			; increment higher byte
dots_6_1:
	pop	de
	ld	e,b			; E = higher byte of loop count
	pop	bc
	ld	b,a			; B = lower byte of loop count
	pop	hl
	ret

;--------------------------------------------------------------

; void cpyv2m(sx1, sy1, sx2, sy2, sp, dest)
; unsigned int sx1, sy1, sx2, sy2;
; unsigned char sp;
; char * dest;

; CPYV2M: copy vram to ram. Parameters:
;
;	sx1	=	start x1
;	sy1	=	start y1
;	sx2	=	end x2
;	sy2	=	end y2
;	sp	=	source page
;	dest	=	dest address

	psect	text
	global	_cpyv2m,_setind,_selstt,_slst0,_DOT_5,_DOT_6,csv,cret


_cpyv2m:
	call	csv
	ld	e,(ix+6)
	ld	d,(ix+7)	; DE = sx1
	ld	l,(ix+8)
	ld	h,(ix+9)	; HL = sy1
	ld	c,(ix+10)
	ld	b,(ix+11)	; BC = sx2	- ix
	ld	(GRPACX),bc
	ld	a,(ix+14)	; source page
	ld	(CPYSRC),a
	exx
	ld	l,(ix+12)
	ld	h,(ix+13)	; HL' = sy2     - iy
	ld	(GRPACY),hl
	ld	e,(ix+16)
	ld	d,(ix+17)
	ld	(CPYDST),de	; dest
	exx
	ld	a,32			; begin writing from register #32
	call	_setind
	out	(c),e			; set source x start
	out	(c),d
	out	(c),l			; set source y start
	ld	a,(CPYSRC)
	add	a,h
	out	(c),a
	push	hl			; save source y start
	out	(c),a			; dummy
	out	(c),a
	out	(c),a
	out	(c),a
	ld	b,0			; initialize value for ARG
					; i.e. assume x/y is to the right/down
	ld	hl,(GRPACX)		; sx2
	sbc	hl,de			; hl = x_end - x_start
	jr	nc,v2m_xdot_pos		; x offset is positive
	ex	de,hl			; negate hl
	ld	hl,0
	sbc	hl,de
	set	2,b
v2m_xdot_pos:
	inc	hl
	out	(c),l			; set number of dots for x
	out	(c),h
	pop	de			; restore y_start
	push	hl			; save dots/line

	ld	hl,(GRPACY)		; hl=sy2
	sbc	hl,de			; hl = y_end - y_start
	jr	nc,v2m_ydot_pos		; y offset is positive
	ex	de,hl			; negate hl
	ld	hl,1
	sbc	hl,de
	set	3,b
v2m_ydot_pos:
	inc	hl
	out	(c),l			; set number of dots for y
	out	(c),h
	out	(c),a			; dummy (skip register #44)
	out	(c),b			; set the argument register
	ld	a,10100000B		; set LMCM command
	out	(c),a
	pop	de			; restore number of pixels per line
	push	ix
	ld	ix,(CPYDST)
	ld	(ix+0),e		; set X extent
	ld	(ix+1),d
	ld	(ix+2),l
	ld	(ix+3),h		; set Y extent
	pop	ix
	ld	b,e
	ld	e,l
	dec	c
	dec	c
	ld	hl,(CPYDST)
	inc	hl
	inc	hl
	inc	hl
	inc	hl
;
;	DB = number of pixels per line
;	E  = number of lines
;	C  = (VDPIO@)+1
;	HL = pointer to destination
;
	ld	a,(SCRMOD)
	cp	8			; screen 8?
	jr	nz,v2m_5		; no
;
;	screen 8
;
	ld	d,b			; save counter for a line
v2m_8_loop:
	ld	b,d			; initialize pixel counter
	di
	ld	a,7
	call	_selstt
v2m_8_line:
	ini				; transfer a line
	jr	nz,v2m_8_line
	call	_slst0
	ei
	dec	e			; done all lines?
	jr	nz,v2m_8_loop		; no
	jp	cret
;
v2m_5:
	cp	6			; screen 6?
	jr	z,v2m_6			; yes
;
;	screen 5 or 7
;
	call	_DOT_5			; calculate total number of bytes
v2m_5_loop:
	di
	ld	a,7
	call	_selstt
	in	a,(c)			; get color
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	in	d,(c)			; get color
	or	d			; combine
	ld	(hl),a			; set to destination
	call	_slst0
	ei
	inc	hl
	djnz	v2m_5_loop
	dec	e
	jr	nz,v2m_5_loop
	jp	cret
;
;	screen 6
;
v2m_6:
	call	_DOT_6			; calculate total number of bytes
v2m_6_loop:
	di
	ld	a,7
	call	_selstt
	in	a,(c)			; get color
	add	a,a
	add	a,a
	nop
	in	d,(c)			; get color
	or	d			; combine
	add	a,a
	add	a,a
	in	d,(c)			; get color
	or	d			; combine
	add	a,a
	add	a,a
	in	d,(c)			; get color
	or	d			; combine
	ld	(hl),a			; set to destination
	call	_slst0
	ei
	inc	hl
	djnz	v2m_6_loop
	dec	e
	jr	nz,v2m_6_loop
	jp	cret


;--------------------------------------------------------------

; void cpym2v(src, dir, dx, dy, dp, logop)
; char *src;
; unsigned char dir;
; unsigned int dx, dy;
; unsigned char dp;
; unsigned char logop;

DIR	equ	CPYDST+2
LOGOPR	equ	0FB02h

	psect	text
	global	_seti36,_DOT_5,_DOT_6,_cpym2v

_cpym2v:
	call	csv
	ld	l,(ix+6)		; hl = *src
	ld	h,(ix+7)
	ld	(CPYSRC),hl
	ld	a,(ix+8)
	ld	(DIR),a			; save dir
	ld	e,(ix+10)
	ld	d,(ix+11)		; DE = dx
	ld	l,(ix+12)
	ld	h,(ix+13)		; HL = dy
	ld	a,(ix+14)		; dest page
	ld	(CPYDST),a
	ld	a,(ix+16)		; logop
	ld	(LOGOPR),a
	ld	(GRPACX),de
	ld	(GRPACY),hl
        call    _seti36
	out	(c),e			; set destination x start
	out	(c),d
	out	(c),l			; set destination y start
	ld	a,(CPYDST)
	add	a,h
	out	(c),a
	ld	hl,(CPYSRC)
	ld	b,(hl)			; set pixels per line (DB)
	inc	hl
	out	(c),b
	ld	d,(hl)
	inc	hl
	out	(c),d
	ld	e,(hl)			; set lines (E)
	inc	hl
	out	(c),e
	ld	a,(hl)
	inc	hl
	out	(c),a
;
;	see if we can use high speed move
;
	ld	a,(DIR)			; get direction
	and	1			; is X to the left?
	jr	nz,jrnz_m2v_logical	; yes, move logically
	ld	a,(LOGOPR)		; logical operation specified?
	and	a
jrnz_m2v_logical:
	ld	a,(SCRMOD)
	jr	nz,m2v_logical		; yes, move logically
	cp	8			; screen 8?
	jr	z,m2v_8 		; yes, always use logical move
					; because there will be no improvement
					; in speed even if we use HMMC
	push	hl
	ld	a,(GRPACX)		; get dx
	or	b			; OR with the number of pixels per line
	ld	l,a			; save it
	ld	a,(SCRMOD)		; restore screen mode
	cp	6			; screen 6?
	ld	a,l			; get byte boundary flag
	pop	hl
	jr	z,m2v_check_4		; yes, check lower 2 bits
	rrca				; on byte boundry?
	jr	nc,m2v_5_hs		; yes, use high speed move
	jr	m2v_5_lm		; no, use logical move
;
m2v_logical:
	cp	8
	jr	z,m2v_8
	cp	6
	jp	z,m2v_6_lm
	jr	m2v_5_lm
;
m2v_check_4:
	and	11B			; on byte boundry?
	jr	nz,m2v_6_lm 		; no, use logical move
;
;	screen 6, high speed move
;
;	DB = number of pixels per line
;	E  = number of lines
;	HL = pointer to source
;
	call	_DOT_6			; calculate total number of bytes
m2v_hs:
	outi				; set first data
	ld	a,(DIR)
	add	a,a
	add	a,a
	out	(c),a			; set arg
	ld	a,11110000B		; issue HMMC command
	out	(c),a
	call	seti44
	inc	b
	dec	b
	jr	z,m2v_hs_cont		; done with a partial block
m2v_hs_loop:
	outi
	jr	nz,m2v_hs_loop
m2v_hs_cont:
	dec	e
	jr	nz,m2v_hs_loop
	jp	cret

;
;	screen 5/7, high speed move
;
m2v_5_hs:
	call	_DOT_5
	jr	m2v_hs

;
;	screen 8
;
m2v_8:
	ld	d,b			; save counter for a line
	outi				; set first data
	ld	a,(DIR)
	add	a,a
	add	a,a
	out	(c),a			; set arg
	ld	a,(LOGOPR)		; get logop
	or	10110000B		; issue LMMC command
	out	(c),a
	call	seti44
	inc	b
	dec	b
	jr	z,m2v_8_cont		; done with a line
	jr	m2v_8_loop
;
m2v_8_loop0:
	ld	b,d			; initialize pixel counter
m2v_8_loop:
	outi
	jr	nz,m2v_8_loop
m2v_8_cont:
	dec	e
	jr	nz,m2v_8_loop0
	jp	cret

;
;	screen 5/7, logical
;
m2v_5_lm:
	call	_DOT_5			; calculate total number of bytes
	ld	a,(hl)
	rlca
	rlca
	rlca
	rlca
	out	(c),a			; set color
	ld	a,(DIR)
	add	a,a
	add	a,a
	out	(c),a			; set arg
	ld	a,(LOGOPR)		; get logop
	or	10110000B		; issue LMMC command
	out	(c),a
	call	seti44
	jr	m2v_5_lm_cont
;
m2v_5_lm_loop:
	ld	a,(hl)			; get data
	rlca
	rlca
	rlca
	rlca
	out	(c),a			; set color
	nop
	nop
m2v_5_lm_cont:
	ld	a,(hl)
	out	(c),a			; set color
	inc	hl
	djnz	m2v_5_lm_loop
	dec	e
	jr	nz,m2v_5_lm_loop
	jp	cret

;
;	screen 6, logical
;
m2v_6_lm:
	call	_DOT_6			; calculate total number of bytes
	ld	a,(hl)
	rlca
	rlca
	out	(c),a			; set color
	ld	d,a			; save it
	ld	a,(DIR)
	add	a,a
	add	a,a
	out	(c),a			; set arg
	ld	a,(LOGOPR)		; get logop
	or	10110000B		; issue LMMC command
	out	(c),a
	call	seti44
	ld	a,d
	jr	m2v_6_lm_cont
;
m2v_6_lm_loop:
	ld	a,(hl)
	rlca
	rlca
	out	(c),a			; set color
m2v_6_lm_cont:
	nop
	rlca
	rlca
	out	(c),a			; set color
	nop
	rlca
	rlca
	out	(c),a			; set color
	nop
	rlca
	rlca
	out	(c),a			; set color
	inc	hl
	djnz	m2v_6_lm_loop
	dec	e
	jr	nz,m2v_6_lm_loop
	jp	cret

;
;	Set the indirect register pointer to #44
;
seti44:
	dec	c			; point to command/status register
	dec	c
	di
	ld	a,80h+44		; inhibit auto increment
	out	(c),a
	ld	a,17+80h
	ei
	out	(c),a
	inc	c			; point to indirect register
	inc	c
	ret


                                                                                                                               