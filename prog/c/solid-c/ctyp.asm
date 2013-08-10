	MODULE	XTCTY
;
;	table for ctype functs
;
@ctype::
	DB	1,1,1,1,1,1,1,1,1,3,3,3,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	DB	1,2,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,20,20,20,20,20,20,20,20,20,20,8,8,8,8,8
	DB	8,8,48,48,48,48,48,48,32,32,32,32,32,32,32,32,32,32,32,32,32,32
	DB	32,32,32,32,32,32,8,8,8,8,8,8,80,80,80,80,80,80,64,64,64,64,64
	DB	64,64,64,64,64,64,64,64,64,64,64,64,64,64,64,8,8,8,8,1,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	ENDMODULE


	MODULE	TOLOWER
;
;	char	tolower(char ch)
;
tolower_::
	cp	'A'
	ret	c
	cp	'['
	ret	nc
	add	a,' '
	ret

	ENDMODULE


	MODULE	TOUPPER
;
;	char	toupper(char ch)
;
toupper_::
	cp	'a'
	ret	c
	cp	'{'
	ret	nc
	sub	' '
	ret

	ENDMODULE


	MODULE	ISNUMB
;
;	char	isdigit(char ch)
;
isdigit_::
	cp	'0'
	jr	c,.1
	cp	'9'+1
	jr	nc,.1
	ld	a,1
	ret
.1:	xor	a
	ret

	ENDMODULE


	MODULE	ISUPP
;
;	char	isupper(char ch)
;
isupper_::
	cp	'A'
	jr	c,.1
	cp	'Z'+1
	jr	nc,.1
	ld	a,1
	ret
.1:	xor	a
	ret

	ENDMODULE


	MODULE	ISLOWE
;
;	char	islower(char ch)
;
islower_::
	cp	'a'
	jr	c,.1
	cp	'z'+1
	jr	nc,.1
	ld	a,1
	ret
.1:	xor	a
	ret

	ENDMODULE

	
	MODULE	ISASCII
;
;	char	isascii(char ch)
;
isascii_::
	cp	13
	ret	z
	cp	10
	ret	z
	cp	' '
	jr	c,.1
	cp	7Fh
	ret	c
.1:	xor	a
	ret

	ENDMODULE


	MODULE	ISALNUM
;
;	char	isalnum(char ch)
;
isalnum_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,4+32+64
	and	(hl)	
	ret

	ENDMODULE



	MODULE	ISXDIG
;
;	char	isxdigit(char c)
;
isxdigit_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,16
	and	(hl)	
	ret
	ENDMODULE



	MODULE	ISSPACE
;
;	char	isspace(char ch)
;
isspace_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,2
	and	(hl)	
	ret

	ENDMODULE

	MODULE	ISCONTRL
;
;	char	iscntl(char ch)
;
iscntrl_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,1
	and	(hl)	
	ret

	ENDMODULE


	MODULE	ISPUNC
;
;	char	ispunct(char ch)
;
ispunct_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,8
	and	(hl)	
	ret

	ENDMODULE

	MODULE	ISALPHA
;
;	char	isalpha(char ch)
;
isalpha_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,32+64
	and	(hl)	
	ret

	ENDMODULE

	MODULE	ISGRAPH
;
;	char	isgraph(char ch)
;
isgraph_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,0FCh
	and	(hl)	
	ret

	ENDMODULE


	MODULE	ISPRINT
;
;	char	isprint(char ch)
;
isprint_::
	ld	l,a
	ld	h,0
	ld	de,@ctype##
	add	hl,de
	ld	a,0FEh
	and	(hl)	
	ret

	ENDMODULE
