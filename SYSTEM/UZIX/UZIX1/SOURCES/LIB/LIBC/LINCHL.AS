	psect	text
	global	linchl
linchl:
	inc	(hl)
	ret	nz
	inc	hl	
	inc	(hl)
	ret	nz	
	inc	hl	
	inc	(hl)
	ret	nz	
	inc	hl	
	inc	(hl)
	ret
