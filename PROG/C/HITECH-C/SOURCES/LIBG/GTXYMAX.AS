; unsigned int gtxmax()

        psect   text
        global  _gtxmax

SCRMOD	equ	0FCAFh

_gtxmax:
        ld      hl,255                  ; assume 2..5, 8
	ld	a,(SCRMOD)
	sub	5
	ret	m			; 2..4
	and	a			; affect parity flag
	ret	pe			; 5 or 8
	inc	h
	ret


; unsigned int gtymax()

	global	_gtymax

_gtymax:
        ld      hl,191                  ; assume 2..4
	ld	a,(SCRMOD)
	cp	5
	ret	m			; good assumption
	ld	l,211			; 5..8
	ret

 ret

;-------------------------------------