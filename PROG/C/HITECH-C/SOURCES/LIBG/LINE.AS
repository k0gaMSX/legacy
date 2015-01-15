
; void  line(x1, y1, x2, y2, color, logop)
; unsigned int x1, y1, x2, y2;
; unsigned char color,logop;

        psect   text
        global  _line,_boxline,_boxfill,_D_LINE
	global	_romline,csv,cret,_CALBAS,_seti36

GRPACX  equ     0FCB7h
GRPACY	equ	0FCB9h
SCRMOD	equ	0FCAFh

_line:
        call    csv
        push    ix
	push	iy
	ld	a,(ix+14)	; color
	ld	b,(ix+16)	; logop
        ld      e,(ix+6)
        ld      d,(ix+7)        ; DE=x1
        ld      l,(ix+8)
        ld      h,(ix+9)        ; HL=y1
        exx
        ld      l,(ix+10)
        ld      h,(ix+11)
        ld      e,(ix+12)
        ld      d,(ix+13)
        push    hl
        push    de
        exx
        pop     iy              ; IY=y2
	pop	ix		; IX=x2
        ld      (GRPACX),ix
	ld	(GRPACY),iy

        push    af
	ld	a,(SCRMOD)
	cp	4+1
	jp	c,old_line
	pop	af
        call    _D_LINE
        pop     iy
        pop     ix
        jp      cret


;       draw a line
;
;	entry		a  = color
;			b  = operation
;			de = x start
;			hl = y start
;			ix = x end
;			iy = y end
;
DOLINE	equ	58FCh
ACPAGE	equ	0FAF6h

_D_LINE:
	push	de
	push	hl
	push	ix
	push	iy
	push	af
	push	af
	push	hl
        call    _seti36                 ; begin writing from register #36
	push	ix
	pop	hl
	out	(c),l			; set x start
	out	(c),h
	push	iy
	pop	hl
	out	(c),l			; set y start
	ld	a,(ACPAGE)
	add	a,h
	out	(c),a
	ld	a,00001100B		; initialize value for ARG
	push	ix
	pop	hl
	sbc	hl,de			; hl = x_end - x_start
	jr	nc,xdel_pos		; x offset is positive
	ex	de,hl			; negate hl
	ld	hl,1
	sbc	hl,de
	and	11111011B
xdel_pos:
	push	hl
	pop	ix
	pop	de			; restore y_start
	push	iy
	pop	hl
	sbc	hl,de			; hl = y_end - y_start
	jr	nc,ydel_pos		; y offset is positive
	ex	de,hl			; negate hl
	ld	hl,1
	sbc	hl,de
	and	11110111B
ydel_pos:
	push	ix
	pop	de			; de = x_delta
	push	hl			; compare y_delta with x_delta
	sbc	hl,de
	pop	hl
	jr	c,xdel_bigger		; x_delta is bigger than y_delta
	ex	de,hl
	or	00000001B
xdel_bigger:
	out	(c),e			;set major delta
	out	(c),d
	out	(c),l			;set minor delta
	out	(c),h
;
;	time to set the color
;
	ld	e,a
	pop	af			; restore color
	out	(c),a
;
;	time to set the argument register
;
	out	(c),e
;
;	time to set the line command
;
	ld	a,b			; restore operation code
	or	01110000B		;issue line command
	out	(c),a
	pop	af
	pop	iy
	pop	ix
	pop	hl
	pop	de
	ret

old_line:
	pop	af			; restore color
	ld	bc,DOLINE
        call    _romline
        pop     iy
        pop     ix
        jp      cret


;--------------------------------------------------------------

; void boxline(x1, y1, x2, y2, color, logop)
; unsigned int x1, y1, x2, y2;
; unsigned char color,logop;

BOXLIN	equ	5912h

        psect   text

_boxline:
        call    csv
        push    ix
	push	iy
	ld	a,(ix+14)	; color
	ld	b,(ix+16)	; logop
        ld      e,(ix+6)
        ld      d,(ix+7)        ; DE=x1
        ld      l,(ix+8)
        ld      h,(ix+9)        ; HL=y1
        exx
        ld      l,(ix+10)
        ld      h,(ix+11)
        ld      e,(ix+12)
        ld      d,(ix+13)
        push    hl
        push    de
        exx
        pop     iy              ; IY=y2
	pop	ix		; IX=x2
        ld      (GRPACX),ix
	ld	(GRPACY),iy

        push    af
	ld	a,(SCRMOD)
        cp      4+1
	jr	c,old_box
	pop	af			; restore color
					; make SURE that Acc will not be
					; changed till the end of routine!
	push	hl			; save y1
	push	ix			; HL = x2
	pop	hl
	and	a
	push	hl
	sbc	hl,de			; x2 - x1
	pop	hl
	jr	z,boxline_vert		; x1 == x2
	jr	nc,draw_box_xok		; x2 is greater
	ex	de,hl
	and	a			; make sure of NC (for next SBC)
draw_box_xok:
;
;	Now, x1 (in DE) are x2 (in HL) are normalized. (x1 < x2)
;
	ex	(sp),hl			; save x2
					; restore y1 in HL
	push	de			; save x1
	push	iy			; DE = y2
	pop	de
	push	hl
	sbc	hl,de
	pop	hl
	jr	z,boxline_horiz		; y1 == y2
	jr	c,draw_box_yok		; y2 is greater
	ex	de,hl
draw_box_yok:
;
;	Now, y1 (in HL) and y2 (in DE) are normalized. (y1 < y2)
;
	push	de			; IY = y2
	pop	iy
	pop	de			; DE = x1
	pop	ix			; IX = x2
;
;	Draw upper-horizontal line
;
	push	iy
	push	hl
	pop	iy
	dec	ix
	call	_D_LINE			; (x1, y1) - (x2-1, y1)
;
;	Draw right-vertical line
;
	inc	ix
	pop	hl
	dec	hl
	push	iy
	push	de
	push	ix
	pop	de
	call	_D_LINE			; (x2, y2-1) - (x2, y1)
;
;	Draw lower-horizontal line
;
	inc	hl
	pop	ix
	inc	ix
	push	hl
	pop	iy
	call	_D_LINE			; (x2, y2) - (x1+1, y2)
;
;	Draw left-vertical line
;
	dec	ix
	pop	hl
	inc	hl
	push	ix
	pop	de
jp_d_line:
        call    _D_LINE                 ; (x1, y1+1) - (x1, y2)
        pop     iy
        pop     ix
        jp      cret
;
boxline_vert:
	pop	hl			; restore y1
	jr	jp_d_line
;
boxline_horiz:
	pop	de			; restore x1
	pop	ix			; restore x2
	jr	jp_d_line
;
old_box:
	pop	af			; restore color
	ld	bc,BOXLIN
        call    _romline
        pop     iy
        pop     ix
        jp      cret


;--------------------------------------------------------------

; void boxfill(x1, y1, x2, y2, color, logop)
; unsigned int x1, y1, x2, y2;
; unsigned char color,logop;

DOBOXF	equ	58C1h

_boxfill:
        call    csv
        push    ix
	push	iy
	ld	a,(ix+14)	; color
	ld	b,(ix+16)	; logop
        ld      e,(ix+6)
        ld      d,(ix+7)        ; DE=x1
        ld      l,(ix+8)
        ld      h,(ix+9)        ; HL=y1
        exx
        ld      l,(ix+10)
        ld      h,(ix+11)
        ld      e,(ix+12)
        ld      d,(ix+13)
        push    hl
        push    de
        exx
        pop     iy              ; IY=y2
	pop	ix		; IX=x2
        ld      (GRPACX),ix
	ld	(GRPACY),iy

        push    af
	ld	a,(SCRMOD)
        cp      4+1
        jp      c,old_fill
	pop	af
	push	af			; save color
	push	hl
	push	ix
	pop	hl
	and	a
	push	hl
	sbc	hl,de
	pop	hl
	jr	nc,d_fill_xok
	ex	de,hl
	and	a
d_fill_xok:
	ex	(sp),hl
	push	de
	push	iy
	pop	de
	push	hl
	sbc	hl,de
	pop	hl
	jr	c,d_fill_yok
	ex	de,hl
d_fill_yok:
	push	de			; now, everything is in order
	pop	iy
	pop	de
	pop	ix
        call    _seti36                 ; begin writing from register #36
	out	(c),e			; set x start
	out	(c),d
	out	(c),l			; set y start
	ld	a,(ACPAGE)
	add	a,h
	out	(c),a
	push	hl
	push	ix
	pop	hl
	and	a
	sbc	hl,de			; hl = x_end - x_start
	inc	hl
	out	(c),l			; set x extension
	out	(c),h
	ld	a,l
	or	e			; a = x_start or x_extension
	push	iy
	pop	hl
	pop	de
	sbc	hl,de			; hl = y_end - y_start
	inc	hl
	out	(c),l			; set y extension
	out	(c),h
	ld	e,a
;
;	see if we can use high-speed move
;
	pop	hl			; restore color in h
	inc	b
	djnz	d_fill_logical		; logical operation specified
	ld	a,(SCRMOD)
	cp	8
	jr	z,d_fill_hs_8
	cp	7
	jr	z,check_2
	cp	6
	jr	z,check_4
check_2:
	ld	a,e
	rrca
	jr	nc,d_fill_hs_4
	jr	d_fill_logical

check_4:
	ld	a,e
	and	11B
	jr	z,d_fill_hs_2
d_fill_logical:
;
;	time to set the color
;
	out	(c),h
;
;	time to set the argument register
;
	xor	a
	out	(c),a
;
;	time to set the lmmv command
;
	ld	a,b
	or	10000000B		;issue lmmv command
	out	(c),a
        pop     iy
        pop     ix
        jp      cret

;
;	time to set the color
;
d_fill_hs_2:
	ld	a,h
	add	a,a
	add	a,a
	or	h
	ld	h,a
d_fill_hs_4:
	ld	a,h
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	h
	ld	h,a
d_fill_hs_8:
	out	(c),h
;
;	time to set the argument register
;
	xor	a
	out	(c),a
	ld	a,11000000B		; issue hmmv command
	out	(c),a
        pop     iy
        pop     ix
        jp      cret
;
old_fill:
	pop	af			; restore color
	ld	bc,DOBOXF
        call    _romline
        pop     iy
        pop     ix
        jp      cret


;       MODULE  ROMLINE
;
;	Low level routine to call LINE, BOXLINE, BOXFILL in ROM BASIC
;
;	Used internally
;
ATRBYT	equ	0F3F2h
GXPOS	equ	0FCB3h
GYPOS	equ	0FCB5h

_romline:
	ld	(ATRBYT),a
	push	bc			; save routine address
	ld	(GXPOS),ix		; set end x
	ld	(GYPOS),iy		; set end y
	ld	c,e			; set start x
	ld	b,d
	ex	de,hl			; set start y
	pop	ix			; restore routine address
        jp      _CALBAS

                                       