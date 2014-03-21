; puts(str) char *str; /* followed by newline */

	public puts

puts:	pop h				;get return addr
	xthl				;restore return, (hl)= str
	call putlp			;output string 'til 0
	mvi e,13
	call puts1			;cr
	mvi e,10			;lf
puts1:	mvi c,2				;output (e)
	jmp 5


; putstr(str) char *str; /* no newline */

	public putstr

putstr:	pop h				;get return addr
	xthl				;restore return, (hl)= str

putlp:	mov a,m				;get char
	ora a
	rz				;done on 0
	push h				;save pointer
	mov e,a				;(e) = char
	call puts1			;output
	pop h				;restore pointer
	inx h				;adj & loop
	jmp putlp

	end
