; gets(str) char *str;

	public gets

len	equ	255			;max len

gets:	pop b				;get return addr
	pop h				;(hl)= str addr
	push b				;restore return
	push h				;save str addr
	mvi m,len			;preset length
	mvi c,10
	xchg				;(de)= str addr
	call 5				;do bdos

	pop d				;(de)= str addr
	lxi h,1
	dad d				;(hl)= buffer-1
	mov a,m				;(a)= len
	mov c,a
	mvi b,0				;(bc)= len
	push b				;save len
	ora a
	jz gets2			;empty now

	inx h				;buffer
gets1:	mov a,m
	stax d				;char (m) -> (de)
	inx d
	inx h				;adj pointers
	dcr c				;adj len count
	jnz gets1			;loop til 0

gets2:	pop h				;return length
	xra a				;(a)=0
	stax d				;terminate str
	ret

	end
