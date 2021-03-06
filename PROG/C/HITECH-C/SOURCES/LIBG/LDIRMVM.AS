;void ldirmv(dst, src, len)
;char *dst;
;unsigned int src,len;

;       LDIRMV  moves block from VRAM to memory.
;
	psect	text
	global	_ldirmv,_setrd,csv,cret
_ldirmv:
        call    csv
        ld      l,(ix+8)
        ld      h,(ix+9)
	call	_setrd
        ld      l,(ix+6)
        ld      h,(ix+7)        ; HL = pointer to destination
        ld      e,(ix+10)       ; DE = length
        ld      d,(ix+11)       ; C  = VDPIO@
	ld	b,e		; set lower byte of length
	ld	a,d		; set higher byte of length
	inc	e		; is lower byte of length 0?
	dec	e
	jr	z,ldirmv_1	; yes
	inc	a
ldirmv_1:
	ini			; INIR cannot be used (VDP may fail)
	jp	nz,ldirmv_1
	dec	a
	jp	nz,ldirmv_1
        jp      cret

;--------------------------------------------------------------

;void ldirvm(dst, src, len)
;unsigned int dst,len;
;unsigned char *src;

;       LDIRVM  moves block from memory to the VRAM.
;
        psect   text
	global	_ldirvm,_setwrt,csv,cret
_ldirvm:
        call    csv
        ld      l,(ix+6)
        ld      h,(ix+7)
	call	_setwrt
        ld      l,(ix+8)
        ld      h,(ix+9)        ; HL = pointer to source
        ld      e,(ix+10)       ; DE = length
        ld      d,(ix+11)       ; C  = VDPIO@
ldirvm0:
	ld	b,e		; set lower byte of length
	ld	a,d		; set higher byte of length
	inc	e		; is lower byte of length 0?
	dec	e
	jr	z,ldirvm_1	; yes
	inc	a
ldirvm_1:
	outi			; OTIR cannot be used (VDP may fail)
	jp	nz,ldirvm_1
	dec	a
	jp	nz,ldirvm_1
        jp      cret


                                                                                                                            