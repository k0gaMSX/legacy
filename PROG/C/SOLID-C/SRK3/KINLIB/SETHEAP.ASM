	extrn	XMAIN
	extrn	$MEMRY
	public	SETHEAP

SETHEAP:
	ld	hl,8000H
	ld	($MEMRY),hl
	jp	XMAIN
