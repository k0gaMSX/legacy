	public bdos,getchar,putchar

	vbd	equ	5		;bdos vector addr

; bdos(bc,de) int bc,de;

bdos:
	pop h				;get return addr
	pop d				;(de) param
	pop b				;(bc) param
	push h				;restore return addr
	jmp vbd


; char (int) getchar()

getchar:
	mvi c,1				;get consol function
	jmp vbd


; putchar(c) char (int) c;

putchar:
	pop h				;get return addr
	pop d				;(de) is c param
	push h				;return addr back
	push d				;resave c param
	mvi c,2				;put consol function
	call vbd			;do bdos
	pop h				;return original c param
	ret

	end
