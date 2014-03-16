	MODULE errno

;	errno variable and temporary FCB for DOS1 functions

	DSEG
errno_::ds	2
?xfcb::	ds	38
	ENDMODULE


	MODULE	setfcb

;	setup FCB, used for DOS1 file io functions

_setupfcb_::
	push	hl
	push	de
	ld	l,e
	ld	h,d
	inc	de
	ld	bc,16
	ld	(hl),0
	ldir
	pop	de
	pop	hl
;
	xor	a
	ld	(de),a
	inc	hl
	ld	a,(hl)
	cp	':'
	dec	hl
	jr	nz,setu5
	ld	a,(hl)
	and	0Fh
	ld	(de),a
	inc	hl
	inc	hl
setu5:	inc	de
setu6:	ld	b,8
	call	setu7
	ld	a,(hl)
	cp	'.'
	jr	nz,setu8
	inc	hl
setu8:	ld	b,3
	call	setu7
	xor	a
	ret
;
setu7:	ld	a,(hl)
	cp	'.'
	jr	z,setu9
	cp	'*'
	jr	z,setu12
	cp	'!'
	jr	c,setu9
	ld	(de),a
	inc	hl
	inc	de
	djnz	setu7
	ret
setu12:	inc	hl
	ld	a,'?'
	jr	setu10
;
setu9:	ld	a,' '
setu10:	ld	(de),a
	inc	de
	djnz	setu10	
	ret
	ENDMODULE


	MODULE	dos1fd

;	convert FD to FCB address for DOS1

get_fd::ld	h,0
	add	hl,hl
	ld	d,h
	ld	e,l
	add	hl,hl
	ld	b,h
	ld	c,l
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,de
	add	hl,bc
	ld	de,(?fio##)
	add	hl,de
	ret

	ENDMODULE


	MODULE open
;
;FD open(char *name,int mode,int attr)	-- DOS1, DOS2, MISIX
;
open_::	push	ix
	ld	a,(_os_ver_##)
	or	a
	jp	z,op1
	dec	a
	jr	z,op2
	ex	de,hl
	ld	h,l
	ld	a,c
	and	00100111b
	ld	l,a
.0:	ld	c,35h
	call	5
op25:	pop	ix
	or	a
	ld	(errno_##),a
	ld	h,0
	ret	z
op14:	ld	hl,0FFFFh
	ret
;
op2:	xor	a
	ld	b,c	;attributes
	bit	0,e	;O_WRITE
	jr	nz,op21
	or	1
op21:	bit	2,e	;O_EXCL?
	jr	z,op22
	set	7,b
op22:	bit	5,e
	ld	c,43h
	jr	z,op23
	bit	4,e
	jr	z,op23
	inc	c
op23:	ex	de,hl
	push	hl
	call	5
	pop	de
	bit	6,e
	jr	z,op24
	push	bc
	ld	hl,0	;O_APPEND
	ld	d,h
	ld	e,l
	ld	a,2
	ld	c,4Ah
	call	5
	pop	bc
op24:	ld	h,0
	ld	l,b
	jr	op25
;
op1:	push	de
	push	hl		;attributes ignored in DOS-1
	ld	hl,(?fio##)
	ld	de,38
	ld	b,16
op11:	ld	a,(hl)
	inc	a
	jr	z,op12
	add	hl,de
	djnz	op11
	pop	de
	pop	hl
op15:	pop	ix
	jr	op14
;
op12:	ld	a,16
	sub	b
	ld	(fdd),a
	ex	de,hl
	pop	hl
	push	de
	call	_setupfcb_##
	pop	de
	pop	bc
	bit	5,c	;CREAT?
	push	bc
	ld	c,0Fh
	jr	z,op13
	ld	c,16h
op13:	push	de
	call	5
	pop	de
	pop	bc
	or	a
	jr	nz,op15
	ld	hl,14
	add	hl,de
	ld	(hl),1	;set reclen = 1
	inc	hl
	ld	(hl),0
	push	hl
	ld	de,18
	add	hl,de	;hl -> RANDOMREC
	ex	de,hl
	pop	hl
	inc	hl
	bit	6,c
	jr	nz,op16
	ld	hl,$$00
op16:	ld	bc,4
	ldir
	ld	hl,(fdd)
	jp	op25
;
$$00:	db	0,0,0,0	;pointer position for OPEN
;
;
;int close(FD fd);	-- DOS1, DOS2, MISIX
;
close_::ld	h,0
	ld	a,(_os_ver_##)
	or	a
	jr	z,cl1
	dec	a
	jr	z,cl2
	ld	c,36h
cl0:	push	ix
	call	5
cl00:	pop	ix
	or	a
	ld	hl,0
	ld	(errno_##),a
	ret	z
	dec	hl
	ret
;
cl1:	call	get_fd##
	ex	de,hl
	ld	c,10h
	push	ix
	push	de
	call	5
	pop	hl
	ld	(hl),255
	jr	cl00
;
cl2:	ld	b,l
	ld	c,45h
	jr	cl0
;
	DSEG
fdd:	dw	0

	ENDMODULE



	MODULE create
;
;FD creat(char *name, int attr)	-- DOS1(attributes ignored), DOS2, MISIX
;
creat_::ld	c,e
	ld	b,d
	ld	e,39h
	jp	open_##
	ENDMODULE


	MODULE read
;
;int read(FD fd,void *buf,int nbytes);  -- DOS1, DOS2, MISIX
;
read_::	push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,rd1
	dec	a
	jr	z,rd2
	push	hl
	push	bc
	ld	c,1Ah
	call	5
	pop	hl
	pop	de
	ld	c,3Ch
rd3:	call	5
rd3a:	pop	ix
	cp	2
	ret	c
	ld	(errno_##),a
	ld	hl,0
	ret
;
rd1:	push	bc
	push	hl
	ld	c,1Ah
	call	5
	pop	hl
	call	get_fd##
	ex	de,hl	
	pop	hl		;byte cnt
	ld	c,27h
	push	de
	call	5
	pop	ix
	bit	7,(ix+24)
	jr	z,rd3a
	set	6,(ix+24)
	jr	rd3a
;
rd2:	ld	a,l
	ld	l,c
	ld	h,b
	ld	b,a
	ld	c,48h
	jr	rd3

	ENDMODULE


	MODULE write
;
;int write(FD fd,void *buf,int nbytes);  -- DOS1, DOS2, MISIX
;
write_::push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,rd1
	dec	a
	jr	z,rd2
	push	hl
	push	bc
	ld	c,1Ah
	call	5
	pop	hl
	pop	de
	ld	c,3Dh
rd3:	call	5
	pop	ix
	cp	2
	ret	c
	ld	(errno_##),a
	ld	hl,0
	ret
;
rd1:	push	bc
	push	hl
	ld	c,1Ah
	call	5
	pop	hl
	call	get_fd##
	ex	de,hl	
	pop	hl		;byte cnt
	ld	c,26h
	jr	rd3
;
rd2:	ld	a,l
	ld	l,c
	ld	h,b
	ld	b,a
	ld	c,49h
	jr	rd3

	ENDMODULE


	MODULE lseek
;
;char _seek(FD fd,long * where,char ot);  -- DOS1, DOS2, MISIX
;
_seek_::push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,sk1
	dec	a
	jr	z,sk2
	ld	h,c
	ld	c,3Bh
sk0:	call	5
	pop	ix
	ld	(errno_##),a
	ret
;
sk2:	ld	a,c
	ld	b,l
	push	de
	pop	ix
	ld	l,(ix+0)
	ld	h,(ix+1)
	ld	e,(ix+2)
	ld	d,(ix+3)
	ld	c,4Ah
	jr	sk0	
;
sk1:	push	de
	push	bc
	call	get_fd##
	ex	de,hl		;where to put
	pop	bc
	ld	a,c
	or	a
	ld	hl,$$00
	jr	z,sk11
	ld	hl,33
	add	hl,de
	dec	a
	jr	z,sk11
	ld	hl,16
	add	hl,de
sk11:	ld	b,h
	ld	c,l		;where to get
	ld	hl,33
	add	hl,de
	ex	de,hl		;where to put
	pop	hl		;pop offset pointer
	ld	a,(bc)
	add	a,(hl)
	ld	(de),a
	inc	bc
	inc	de
	inc	hl	
	ld	a,(bc)
	adc	a,(hl)
	ld	(de),a
	inc	bc
	inc	de
	inc	hl	
	ld	a,(bc)
	adc	a,(hl)
	ld	(de),a
	inc	bc
	inc	de
	inc	hl	
	ld	a,(bc)
	adc	a,(hl)
	ld	(de),a
	xor	a
	pop	ix
	ret

$$00:	db	0,0,0,0

	ENDMODULE

	MODULE ltell
;
;char _tell(FD fd,long * where);  -- DOS1, DOS2, MISIX
;
_tell_::push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,sk1
	dec	a
	jr	z,sk2
	push	de
	pop	ix
	ld	(ix+0),0
	ld	(ix+1),0
	ld	(ix+2),0
	ld	(ix+3),0
	ld	h,1
	ld	c,3Bh
sk0:	call	5
sk2a:	pop	ix
	ld	(errno_##),a
	ret
;
sk2:	push	de
	ld	a,1
	ld	b,l
	ld	hl,0
	ld	de,0
	ld	c,4Ah
	call	5
	pop	ix
	ld	(ix+0),l
	ld	(ix+1),h
	ld	(ix+2),e
	ld	(ix+3),d
	jr	sk2a
;
sk1:	push	de
	call	get_fd##
	ld	de,33
	add	hl,de
	pop	de
	ld	bc,4
	ldir
	xor	a
	pop	ix
	ret

	ENDMODULE


	MODULE sleep
;
;void sleep(int seconds);	-- MISIX only
;
sleep_::ld	a,(_os_ver_##)
	cp	2
	ret	nz
	push	ix
	ex	de,hl
	ld	c,4Dh
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE PID
;
;char getpid();		-- MISIX only
;
;char getppid();	-- MISIX only
;
getppid_::
	ld	c,49h
	db	21h
getpid_::
	ld	c,48h
	ld	a,(_os_ver_##)
	cp	2
	ld	a,0
	ret	nz
	push	ix
	call	5
	pop	ix
	ret

	ENDMODULE


	MODULE chdir
;
;char chdir(char *path);	-- DOS2, MISIX
;
chdir_::ld	a,(_os_ver_##)
	or	a
	ret	z
	ex	de,hl
	dec	a
	jr	z,.1
	ld	c,40h
.2:	push	ix
	call	5
	pop	ix
	ld	(errno_##),a
	ret
.1:	ld	c,5Ah
	jr	.2

	ENDMODULE


	MODULE getcwd
;
;char *getcwd(char *buf,int size);
;
getcwd_::
	push	ix
	push	hl
	push	bc
	ld	c,19h
	call	5
	ld	l,a
	ld	a,(_os_ver_##)
	or	a
	jr	z,gc1
	dec	a
	jr	z,gc2
	inc	l
	ld	de,(0F34Dh)
	ld	c,44h
	call	5
gc3:	pop	bc
	pop	de
	ld	hl,(0F34Dh)
	push	de
	ldir
	dec	de
gc0:	xor	a
	ld	(de),a
	pop	hl
	pop	ix
	ret
;
gc1:	pop	bc
	pop	de
	push	de
	ld	a,'A'
	add	a,l
	ld	(de),a
	inc	de
	ld	a,':'
	ld	(de),a
	inc	de
	jr	gc0
;
gc2:	ld	b,l
	ld	de,(0F34Dh)
	ld	c,59h
	call	5
	jr	gc3

	ENDMODULE


	MODULE strerr
;
;char *strerr(int errno)
;
strerr_::
	ld	a,(_os_ver_##)
	or	a
	jr	z,.1
	ld	de,(0F34Dh)
	dec	a
	jr	z,.2
	ld	c,31h
.3:	push	ix
	call	5
	pop	ix
	ld	hl,(0F34Dh)
	ret
;
.1:	ld	hl,$$t
	ret
.2:	ld	b,l
	ld	c,66h
	jr	.3
;
$$t:	db	'DOS-1 error',0

	ENDMODULE


	MODULE perror
;
;void perror(char *str);
;
perror_::
	push	ix
	ld	a,h
	or	l
	jr	z,.2
.3:	ld	a,(hl)
	inc	hl
	or	a
	jr	z,.4
	db	0F7h,80h,0A2h,0
	jr	.3
.4:	ld	a,':'
	db	0F7h,80h,0A2h,0
.2:	ld	hl,(errno_##)
	call	strerr_##
.5:	ld	a,(hl)
	inc	hl
	or	a
	jr	z,.6
	db	0F7h,80h,0A2h,0
	jr	.5
.6:	pop	ix
	ret
	ENDMODULE


	MODULE fcntl
;
;int fcntl(FD fd,int mode,int arg)
;char fcntla
;
fcntl_::
fcntla_::
	ld	a,(_os_ver_##)	;this function works ONLY in MISIX
	cp	2
	jr	nz,.1
	ld	h,e
	ld	e,c
	ld	d,b
	ld	c,3Eh
	call	5
	ld	(errno_##),a
	or	a
	ret	z
.1:	ld	a,0FFh
	ld	l,a
	ld	h,a
	ret
	ENDMODULE



	MODULE isatty
;
;char isatty(FD fd)	-- DOS1, DOS2, MISIX
;
isatty_::
	push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,isa1
	dec	a
	jr	z,isa2
	ld	h,6
	ld	c,3Eh
	call	5
isa3:	pop	ix
	cp	0FFh
	ret	z
	xor	a
	ret
;
isa2:	ld	b,l
	ld	c,4Bh
	xor	a
	call	5
	pop	ix
	xor	a
	bit	7,e
	ret	z
	dec	a
	ret
;
isa1:	call	get_fd##
	ld	de,24
	add	hl,de
	ld	a,(hl)
	jr	isa3
	
	ENDMODULE



	MODULE	UNLINK

;	char	unlink(char *filename)	-- DOS1, DOS2, MISIX
;	char	remove(char *filename)

unlink_::
remove_::
	ld	a,(_os_ver_##)
	or	a
	jr	z,.1
	ex	de,hl
	dec	a
	jr	z,.2
	ld	c,39h
.3:	push	ix
	call	5
	pop	ix
	or	a
	ret	z
	ld	(errno_##),a
	ld	a,255
	ret
.2:	ld	c,4Dh
	ld	hl,0
	jr	.3
.1:	ld	de,?xfcb##
	call	_setupfcb_##
	ld	de,?xfcb##
	ld	c,13h
	jr	.3
	ENDMODULE



	MODULE	MKDIR

;	char mkdir(char * name)

mkdir_::			;DOS2, MISIX
	ld	a,(_os_ver_##)
	dec	a
	ret	m
	push	ix
	ex	de,hl
	jr	z,mkd1
	ld	c,41h
mkd0:	call	5
	pop	ix
	or	a
	ret	z
	or	a
	ret	z
	ld	(errno_##),a
	ld	a,255
	ret
;
mkd1:	ld	bc,9044h
	xor	a
	jr	mkd0

	ENDMODULE


	MODULE	RMDIR

;	char	rmdir(char *name) -- DOS2, MISIX

rmdir_::
	ex	de,hl
	ld	a,(_os_ver_##)
	dec	a
	ret	m
	push	ix
	ld	c,4Dh
	jr	z,rmd0
	ld	c,42h
rmd0:	call	5
	pop	ix
	or	a
	ret	z
	ld	(errno_##),a
	ld	a,255
	ret

	ENDMODULE


	MODULE	RENAME

;	char	rename(char *old, char *new);	-- DOS1, DOS2, MISIX

rename_::
	push	ix
	ld	a,(_os_ver_##)
	or	a
	jr	z,ren1
	dec	a
	jr	z,ren2
	push	de
	push	hl
	ld	c,39h
	call	5
	pop	hl
	ld	de,(0F34Dh)
.1:	ld	a,(hl)
	ldi
	or	a
	jr	nz,.1
	pop	hl
.2:	ld	a,(hl)
	ldi
	or	a
	jr	nz,.2
	ld	de,(0F34Dh)
	ld	c,38h
ren0:	call	5
	pop	ix
	or	a
	ret	z
	ld	(errno_##),a
	ld	a,255
	ret
;
ren2:	push	hl
	push	de
	ld	c,4Dh
	call	5		;delete new
	pop	hl
	pop	de
	ld	c,4Eh
	jr	ren0
;
ren1:	push	de
	ld	de,?xfcb##
	call	_setupfcb_##
	pop	hl
	ld	de,?xfcb##+16
	call	_setupfcb_##
	ld	de,?xfcb##+16
	ld	c,13h
	call	5
	ld	de,?xfcb##
	ld	c,17h
	jr	ren0

	ENDMODULE


	MODULE	GETENV

;char	*getenv(char *name); -- DOS2, MISIX

getenv_::
        ld	de,(0F34Dh)
.1:	ld	a,(hl)
	cp	'a'
	jr	c,.2
	cp	'z'+1
	jr	nc,.2
	sub	' '
.2:	ld	(de),a
	inc	hl
	inc	de
	or	a
	jr	nz,.1
	ld	hl,(0F34Dh)
	ld	a,(_os_ver_##)
	or	a
	ret	z		;in DOS1 returns passed name
	dec	a
	jr	z,.3
	ex	de,hl
	push	de
	ld	l,0
	ld	c,44h
.4:	push	ix
	call	5
	pop	ix
	pop	hl
	ret
.3:	ld	d,h
	ld	e,l
	inc	d
	push	de
	ld	bc,0FE6Bh
	jr	.4
	
	ENDMODULE


	MODULE	DUP
;
;	FD	dup(FD fd);	-- MISIX, DOS2
;
dup_::	ld	a,(_os_ver_##)
	or	a
	ret	z
	push	ix
	dec	a
	jr	z,du1
	ld	h,0
	ld	c,3Eh
	call	5
	pop	ix
	ret
du1:	ld	b,l
	ld	c,47h
	call	5
	pop	ix
	ld	l,b
	ld	h,0
	ret

	ENDMODULE


	MODULE	DUP2
;
;	char	dup2(FD f1, FD f2);	-- MISIX only
;
dup2_::	ld	a,(_os_ver_##)
	cp	2
	ret	nz
	ld	h,1
	ld	c,3Eh
	push	ix
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	ioctl
;
;	int	ioctl(FD fd, char function, int arg)
;	char	ioctla(FD fd, char function, int arg)	-- DOS2 only
;
ioctla_::
ioctl_::ld	a,(_os_ver_##)
	dec	a
	ret	nz
	push	ix
	ld	a,e
	ld	e,c
	ld	d,b
	ld	b,l
	ld	c,4Bh
	call	5
	pop	ix
	ex	de,hl
	ret
	ENDMODULE
