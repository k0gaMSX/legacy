; init graphics lib

;void ginit(void)
        psect   text

EXPTBL  equ     0FCC1h
	global	_ginit,VDPIO
_ginit:
        ld      hl,6
        ld      a,(EXPTBL)
        push    ix
        push    iy
	call	00ch
        pop     iy
        pop     ix
        ei
        ld      (VDPIO),a
	ret


 call    _CALSUB
        jp      cret


;--------------------------