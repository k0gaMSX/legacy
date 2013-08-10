;*** cls2.com clear screen ***
;
;

	assume	cs:_code
_code	segment
	org	0100h	
start:
	xor	al,al
	out	0a8h,al
	out	0aah,al
	out	0ach,al
	out	0aeh,al
	
	mov	al,80h
	out	07ch,al
	mov	dx,007eh
	xor	al,al
	out	dx,al
	out	dx,al
	out	dx,al
	out	dx,al
	
	xor	al,al
	out	0a6h,al
	push	es
	mov	ax,0a800h
	mov	es,ax
	xor	ax,ax
	mov	cx,4000h
	xor	di,di
	rep stosw
	mov	al,1
	out	0a6h,al
	mov	cx,4000h
	xor	di,di
	rep stosw
	pop	es
	
	xor	al,al
	out	07ch,al
	
	mov	ah,0ch
	int	18h
	mov	ah,40h
	int	18h
	mov	ah,4ch
	int	21h
	
_code	ends

end	start
