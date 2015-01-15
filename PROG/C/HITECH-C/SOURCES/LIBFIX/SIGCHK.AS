

	global	__sigchk,_raise
	psect	text
__sigchk:
ld	a,(0fc9bh)	; INTFLG
cp	3		; if ctrl-stop pressed
jp	z,1f		; then ignore all bypasses
ld	hl,7
call	_raise		; raise(SIGQUIT)
ret

1:

ld	hl,(0f3fah)	; getpnt
ld	a,(0f3f8h)	; putpnt
cp	l		; if not keypressed
ret	z		; then return

push	ix
push	iy
ld	ix,09fh
ld	iy,(0fcc0h)
call	01ch		; _CHGET
pop	iy
pop	ix
cp	3		; if not CTRL-C
ret	nz		; then return

ld	hl,1
call	_raise		;raise(SIGINT)
ret

end


