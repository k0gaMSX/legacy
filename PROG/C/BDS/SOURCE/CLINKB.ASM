;
; clinkb.asm:
;
; This routine finds, somehow, the name of the next CRL file to search.
; It also processes any command line options that weren't taken care
; of back at the start of the link. This routine has grown into a real
; bitch of kludginess, and I'm sorry about that...but it's so CUTE in
; the way it does so damned much "on the fly" zipping down the command
; line. Anyway, once the command line runs out, deff.crl and deff2.crl
;	(or deff0.crl, deff1.crl, deff2.crl, etc., under MARC)
; are spit back, and if those have been scanned already then a list of
; unresolved function references is printed (because this routine wouldn't
; be CALLED if all the functions had been resolved...) and the user is
; prompted for another file name, or a special command like abort (control-Q)
; or search all deff*.crl files again (a carriage-return.)
;

getfn:	lda mflag	; has command line been fully processed?
	ora a
	jz gfnzz2	;if so, go do something else...

	lhld cptr	;no.
gfn0:	mov a,m
	call twhite	;skip leading white space at the current position
	jnz gfna	;of scanning
	inx h
	jmp gfn0

gfna:	ora a		;have we reached the end of the line (so to speak)?
	jnz gfnb
gfnzz:	sta mflag	;yes. set this flag to tell us so next time

	lda donef	;If link has been completed already, and we were
	ora a		;just scanning for more possible command line options,
	rnz		;then return right here.

gfnzz2:	lda dflag	;if haven't searched DEFF.CRL yet,
	ora a
	jz gfldf	;go do it.

	IF CPM
	lda d2flag	;if haven't searched DEFF2.CRL yet,
	ora a
	jz gfld2f	;go do it.

	lda d3flag	;if haven't scanned DEFF3.CRL yet,
	ora a
	jz gfld3f	;go do it.
	ENDIF

	jmp gtfnz	;else go get file name from user.

gfnb:	cpi '-'		;is the next thing an option?
	jnz gfnc	;if not, go get filename
gfnb0:	inx h		;yes.
gfnb1:	mov a,m		;put in A and convert to upper case
	call mapuc
	sta opletr	;save for possible error reports later

	cpi 'S'		;print stats?
	jz sets

	IF MARC
	cpi 'M'		;do maxmem call in c.ccc?
	jz setm
	ENDIF

	cpi 'T'		;set top of memory?
	jz sett

	cpi 'O'		;set output filename?
	jz seto

	cpi 'W'		;write symbol table?
	jz setw

	cpi 'E'		;set external data starting addr?
	jz setext

	IF CPM		;TEMPORARILY UNIMPLEMENETED UNDER MARC
	cpi 'Z'		;inhibit clearing of external data?
	jz setz

	cpi 'Y'		;read in symbol table file from disk
	jz gsyms

	cpi 'D'		;debug mode?
	jz setd

	cpi 'N'
	jz setn
	ENDIF

	cpi 'F'		;switch to scanning of functions (from loading)?
	jz setf

	call twhite
	jz gfn0
	ora a
	jz gfn0

	push psw
	lxi d,stgbop	;bad option
	call pstg
	pop psw		;print the option char used
	call outch
	call crlf
	jmp abort

sets:	sta statf
	jmp gfnb0

	IF MARC
setm:	push h		;insert a "call marc" instruction at mhackl in c.ccc:
	lhld cda	;get start of code area
	lxi d,mhackl	;get displacement for mhackl in DE
	dad d		;HL --> where "call marc" will go
	mvi m,0cdh	;"call" op
	inx h
	mvi m,msys and 0ffh
	inx h
	mvi m,msys/256
	
	lda taddrf	;if -t option used, don't change taddr
	ora a
	jnz setm2

	lhld curtop	;make physical top of memory logical top 
	shld taddr	;at run-time

setm2: 	pop h		;restore text pointer

	jmp gfnb0
	ENDIF


setw:	sta wflg	;write symbols out
	jmp gfnb0

	IF CPM
setz:	sta zflag	;inhibit clearing external flag
	jmp gfnb0

setn:	sta nflag	;activate NOBOOT option
	jmp gfnb0
	ENDIF

setf:
	IF FORCE
	xra a
	ENDIF

	IF NOT FORCE
	mvi a,1
	ENDIF

	sta fflag
	inx h
	jmp gfn0

	IF CPM		;temp. unimplemented under MARC
setd:	mvi a,1		;for starters, no text list
	sta debugf	;causes file to be executed
	inx h		;pass over the `D'
	call igsp	;test for arg list text
	cpi '"'
	jnz gfna	;if not, all done
	sta debugf	;set debugf to > 1 to indicate a text list	
	inx h
	shld argptr	;and set a pointer to the arg list
setd1:	mov a,m		;find the trailing quote
	inx h
	cpi '"'
	jnz setd1
	jmp gfnb1	;instead of written to disk
	ENDIF

sett:	inx h
	call gtaddd
	xchg
	shld taddr
	mvi a,1
	sta taddrf
	xchg
	jmp gfn0

;
; Scan a hex address at text at HL and return
; with the value in DE, and HL pointing past the text:
; Complain and abort if no legal value given.	
;

gtaddd:	lxi d,0
gtad1:	call igsp
	call tsthd
	jnc gtad3
	lxi d,stgver
stgab:	call pstg

	IF CPM
	call crlf
	ENDIF

	jmp abort

gtad2:	mov a,m
	call tsthd
	rc
gtad3:	call addda
	inx h
	jmp gtad2

addda:	push h
	xchg
	dad h
	dad h
	dad h
	dad h
	mov e,a
	mvi d,0
	dad d
	xchg
	pop h
	ret

tsthd:	call mapuc
	sui '0'
	rc
	cpi 10
	cmc
	rnc
	cpi 11h
	rc
	cpi 17h
	cmc
	rc
	sui 7
	ret

seto:
	IF MARC
	mvi a,1
	sta oflag
	ENDIF

	inx h		;point HL to filename
	lxi d,fcbs	;this is where the fcb for it will be set up

	IF CPM
	lda dcrl	;save default crl disk 'cause we're gonna clobber it
	push psw
	lda fcbs	;get default output disk
	sta dcrl	;put it here for gfncp2
	ENDIF

	call igsp	;ignore leading space of filename text
	call gfncp2	;set up fcb

	IF CPM
	pop psw
	sta dcrl	;restore dcrl
	ENDIF

	jmp gfn0

setext:	inx h
	call gtaddd
	xchg
	shld eaddr
	mvi a,1
	sta eflag
	xchg
	jmp gfn0

	IF CPM
gsyms:	inx h		;read in a symbol table file
	call igsp	;ignore spaces
	push h		;assume "sym" extension by default
	lxi h,fcb+9
	mvi m,'S'
	inx h
	mvi m,'Y'
	inx h
	mvi m,'M'
	pop h

	call gfncp	;set up the default FCB w/file name
	xra a
	call open	;try to open the symbols file for reading
	jc gsym2	;if can't, don't read in symbols
	lxi h,tbuff
	shld buffp	;init buffer pointer

	lhld cdp
	push h		;save code pointer
gsymlp:	mvi a,1		;set "reading symbol" flag
	sta rdngsm
	call dosym	;process a symbol
	jnc gsymlp	;until we run out
	pop h		;get back
	shld cdp
	xra a		;clear "reading symbols" flag
	sta rdngsm

	call close	;close symbol file
gsym2:	lhld cptr	;get back text pointer
	jmp gfn0	;and go process more commands



dosym:	call igsht	;ignore garbage
	rc		;return if EOF
	call tsthd	;legal value character?
	jc serror
	call getval	;get value in hex from file

	push h		;this gets added later, 
	call getcdf
	call cmh	;so subtract it now!	
	xchg
	pop h

	dad d		;subtracting...
	shld cdp	;set up for call to entt1
	call getname	;get symbol name at sname buffer
	lxi h,sname	;get pointer to name
	lxi d,stgmn	;is it the "MAIN" entry?
	call stcmp
	rz		;if so, don't yank it!
	mvi a,1		
	sta gotf	;this is so that entt1 defines the symbol here
	call entt1
	xra a		;no error
	ret		;and done with the symbol

serror:	lxi d,stgserr	;"illegal symbol in file"
	jmp stgab

getname: lxi h,sname
	call igsht
	jc serror	;if no legal 1st char of symbol name, error
getn2:	mov m,a
	inx h
	call getcc	;get next char
	jc getn3	;if EOF, also end-of-symbol!
	call tstsht	;is it "whitespace" character?
	jnz getn2	;if not, store and get next char
getn3:	dcx h		;turn on bit 7 of last char
	mov a,m
	ori 80h
	mov m,a
	ret


getval:	lxi h,0		;clear sum
getv2:	dad h		;shift sum left 4 bits
	dad h
	dad h
	dad h
	mov e,a		;add new hex digit to sum
	mvi d,0
	dad d
	call getcc	;any more chars?
	call tsthd
	jnc getv2	;if so, go do them
	ret		;else done


igsht:	call getcc	;get character from file
	call tstsht	;if no more, return C set
	rc
	jz igsht	;and ignore junk
	ret
	ENDIF

tstsht:	call twhite
	rz
	cpi 0dh		;cr?
	rz
	cpi 0ah		;lf?
	rz
	cpi 1ah		;EOF?
	stc
	rz		;if so, set C
	cmc		;else not EOF
	ret		;else good character

	IF CPM
getcc:	push h		;save HL
	lhld buffp	;get buffer pointer
	mov a,l
	ani 7fh		;start of buffer?
	jnz getc2
	call reads	;yes. read in a sector
	rc		;return C if EOF
getc2:	mov a,m		;get char from buffer
	push psw	;save character
	inx h		;bump pointer
	mov a,l		;end of sector?
	ani 7fh
	jnz getc3
	lxi h,tbuff
getc3:	pop psw
	shld buffp	;and save for next time
	pop h		;restore HL
	ora a		;clear Carry
	ret
	ENDIF

igsp:	mov a,m		;ignore spaces at text at HL
	call twhite
	rnz
	inx h
	jmp igsp

;
; At this point, we have a filename on the command line. It will
; be interpreted as the name of a CRL file, and scanned for needed
; functions:
;

gfnc:	call gfncp	;collect up the name
	jmp afterg

;
; This routine, given a pointer to the ascii text of a CP/M filename,
; sets up the default fcb with the given name. The disk to stick in the
; the disk byte by default is loaded from dcrl, but that is overridable
; if an explicit disk designator is given.
;
; The filename may also be preceded by a user number code of form "#/",
; causing a switch to that user area for the duration of the file scan,
; and then a reversion back to the current user area.
;

gfncp:
;	IF CPM		;put a CP/M filename into the default fcb:
 	lxi d,fcb
gfncp2:	push d		;save pointer to working fcb
	push h		;save text pointer
	call gdec	;user area prefix? If so, starts with number...
	jc gfncp4	;if not, don't assume a user number is there
	mov a,m		;if we saw a number, check for trailing slash
	cpi '/'
	jnz gfncp4	;if no slash, it wasn't a user number

	xthl		;pop old text pointer off stack
	pop h

	push d		;save DE
	mov e,b		;set the user number to the given value
	mvi c,sguser
	lda nouser
	ora a
	push h		;save pointer to slash in text
	IF NOT ALPHA
	cz bdos
	ENDIF
	pop h		;get back text pointer

	pop d		;restore DE
	inx h		;bump text ptr past the slash
	push h		;push back so we can fall through to next section
	xra a		;disable default disk searching
	sta search

gfncp4:	pop h		;restore text pointer to start of filename
gfncp5:	inx h
	mov a,m		;is an explicit disk designator given?
	dcx h
	cpi ':'
	lda dcrl
	stax d		;in case not, set it up with the default disk
	jnz gfnc0
	xra a		;disable default disk searching
	sta search
	mov a,m		;else get the actual disk letter
	call mapuc	;in upper case, of course
	sui '@'		;subtract offset to put into proper range
	inx h
	inx h
	stax d		;save at start of target fcb
	mov a,m		;space or null follow designator?
	ora a
	jz gfncp9
	cpi ' '
	jnz gfnc0	;if not, go parse filename
gfncp9:	pop d		;else don't, having only modified disk designator.
	ret
	
gfnc0:	inx d
gfnc1:	mvi b,8
	call gfnc3	;load the principle filename
	mov a,m
	ora a
	jz gfnca	;end of command line?
	cpi ' '		;if not, was filename terminated by a space?
	jz gfnca	;if so, don't touch the COM extension
	inx h		;else either clear the extension (if a lone "." given)
	mvi b,3		;or set up the new exntension.
	call gfnc3
gfnca:	shld cptr	;save command line pointer
	xthl		;exchage command line pointer with fcb address on stack
	lxi d,12	;clear the extent field of the fcb
	dad d
	mvi m,0
	pop h		;get back the command line pointer and return
	ret

;
; This routine copies up to B ascii letters from text at HL to the fcb
; filename or extension field at DE, padding with spaces on the right:
;

gfnc3:	mov a,m
	ora a
	jz padsp
	call twhite
	jz padsp
	cpi '.'
	jz padsp
	call mapuc
	stax d 	
	inx d
	inx h
	dcr b
	jnz gfnc3
padsp:	mov a,b
	ora a
	rz
	mvi a,' '
	stax d
	inx d
	dcr b
	jmp padsp
;	ENDIF

	IF NOT CPM	;for MARC, copy the filename to fcbt:
	lxi d,fcbt
gfncp2:	mov a,m
	ora a
	jz gfncp3
	call tstsht	;end of name?
	jz gfncp3
	stax d
	inx h
	inx d
	jmp gfncp2	

gfncp3:	shld cptr
	xra a
	stax d
	ret
	ENDIF

afterg:	lda donef		;if all done, we don't need to load the file
	ora a
	jnz getfn

	IF CPM
	  call scrl
;	  inr a
;	  sta search		;search current, then default disk/user area
	ENDIF

	IF NOT CPM
	  push h
	  lxi h,fcbt
	  call scrl
	  pop h
	ENDIF	

	ret

;
; Announce missing functions after all given CRL files have been
; read in and there are still unresolved function references:
;

gtfnz:	lxi d,stgas
	call pstg	;"missing functions:"
	call list	;list out function names

	IF MARC
	xra a
	sta dlast	;reset deff?.crl counter whenever going into
	ENDIF		;interactive mode under MARC

getfn2:	call crlf
	lxi d,stg7	;ask for input
	call pstg

gfl1:	lxi h,tbuff	;get a line of user input at tbuff

	IF CPM		;under CP/M, use the bdos call to get a line of input
	mvi m,120
	xchg
	mvi c,readbuf
	call bdos	;get line of input
	call crlf
	lxi h,tbuff+2	;get length byte
	push h
	dcx h	
	mov a,m
	inr a
	add l
	mov l,a
	mvi m,0
	pop d
	ENDIF

	IF NOT CPM		;get a line of input under MARC:
	push h		;save pointer to start of text line buffer area
gfl1a:	call inch	;get a character from console
	mov m,a		;save it
	inx h		;bump pointer
	cpi newlin	;newline?		
	jnz gfl1a
	dcx h
	mvi m,0		;if so, change it to a null
	pop d		;and restore pointer to accumulated line into DE
	ENDIF

gfl1b:	ldax d
	inx d
	call twhite
	jz gfl1b

	IF CPM
	cpi 1ah		;control-Z?
	jnz gfl1c	;if so, abort the linkage
	ENDIF

	IF NOT CPM
	jmp gfl1c	;don't bother checking for ^Q under MARC, since
	ENDIF		;^C's are handled by the OS.

abort:
	lhld errbyt
	mvi m,0ffh

	IF NOT ALPHA
	mvi e,0		;switch to user 0 to erase submit file under ZSYSTEM
	mvi c,sguser
	lda nouser
	ora a
	jnz abort2

	lda zenvf	;zsystems?
	ora a
	cnz bdos	;if so, change to user 0
abort2:
	ENDIF

	lxi d,subfile	;if so, erase submit file on user 0
	mvi c,delete
	call bdos

	lda curusr	;restore to current user area
	mov e,a
	mvi c,sguser
	lda nouser
	ora a
	IF NOT ALPHA
	cz bdos
	ENDIF

	lxi d,stgabt	;abort message
	call pstg
	jmp exit

	IF NOT CPM
	lda marcfd	;any file open?
	ora a
	cnz close	;if so, close it
	call crlf	;put out extra CR-LF under MARC
	lxi h,-1
	jmp exit
	ENDIF

gfl1c:	ora a		;null input line?
	jnz gfl2

	IF MARC
	xra a		;if so, cause all deff*.crl files to be searched
	sta dflag	;under MARC
	ENDIF

gfldf:
	IF FORCE
	xra a
	sta fflag	;turn off forced loading while scanning libraries
	ENDIF

	lxi h,deffs	; search deff.crl (or current deff?.crl under MARC)

	IF MARC		;now--go through all deff?.crl files under MARC
	push h
	lda dlast	;has the cycle been started yet?
	ora a		;if so, go on to next iteration
	jnz gfldfn
	mvi a,'0'	;else start it up with deff0.crl
	sta dlast
	dcr a		;make it so it gets bumped to '0' and used

gfldfn:	lxi d,10	;point to variable location
	dad d

	inr a		;bump dlast to next value
	cpi ':'		;if up past the digits, turn it into an 'a'
	jnz gfldfo
	mvi a,'a'

gfldfo:	sta dlast	;save for looping
	mov m,a		;and put into filename as next deff?.crl to search
	cpi '4'
	jc gfldfp

	sta quietf	;be quiet if past deff3.crl

gfldfp:	pop h	

	xchg
	lhld noffst	;add either 0 (to search /libC) or 6 (current direct)
	dad d
	ENDIF

	IF CPM
	lxi d,fcb
	ENDIF

	IF NOT CPM
	lxi d,fcbt
	ENDIF

	call movfn

	IF CPM
	call setdu	;make library user area the current user area
	xra a
	sta d2flag	;cause deff2.crl and deff3.crl to be re-scanned
	sta d3flag
	sta search	;don't search anywhere but default
	inr a
	sta dflag	;and say that deff.crl has now been scanned
	ENDIF

	ret


;	IF CPM		;only search DEFF2.CRL and DEFF3.CRL explicitly
gfld2f:	lxi h,deff2s	;under CP/M
	lxi d,fcb
	call movfn
	xra a
	sta search	;only search default
	inr a
	sta d2flag
	call setdu	;set library user area to be current
	ret

gfld3f:	lxi h,deff3s
	lxi d,fcb
	call movfn
	xra a
	sta search	;only search default
	inr a
	sta quietf	;don't complain if can't open file
	sta d3flag
	call setdu	;set library user area to be current
	ret

setdu:	lda defusr
	mov e,a
	mvi c,sguser
	lda nouser
	ora a
	IF NOT ALPHA
	cz bdos
	ENDIF
	ret
;	ENDIF

gfl2:	xchg		;put text address in HL
	dcx h
	call gfncp	;set up fcb with name of file

	IF MARC
	lxi h,fcbt
	ENDIF
;
;	IF CPM
;	mvi a,1
;	sta search	;search current, then default disk/user area
;	ENDIF

	call scrl
	ret

;
; List out names of missing functions:
;

list:	lxi h,tab1
	shld fngtt
	mvi b,7
lst1:	call fung2
	rc

lst2:	mov a,m
	push psw
	ani 7fh

	IF CPM
	call mapuc
	ENDIF

	call outch
	pop psw
	ora a
	inx h
	jp lst2
	dcr b
	jnz lst3
	call crlf
	mvi b,7
lst3:	mvi a,' '
	call outch
	call outch
	jmp lst1

readc:	lda segf	;if segment, don't read in C.CCC
	ora a
	rnz

	IF CPM
	call savfn	;else do...if CP/M, save main filename for later use
	ENDIF

	lxi h,ccc	;get name of c.ccc

	IF MARC
	xchg
	lhld noffst	;add either 0 (to search /libC) or 6 (current direct)
	dad d
	ENDIF

	IF CPM
	lxi d,fcb	;set up fcb under CP/M
	call movfn
	ENDIF

	xra a
	call open	;open c.ccc for reading
	jc abort	;abort if can't find it

	IF CPM		;read in c.ccc under CP/M
	lhld cda
rdc1:	call reads
	jc rdc2
	call cpys
	jmp rdc1
	ENDIF

	IF NOT CPM
	lda marcfd	;figure out how big c.ccc really is
	mvi c,m$fsize
	call msys
	xchg		;put length into DE (from HL)
	lhld cda	;get load address into HL
	call reads	;under MARC, call read to get entire file in
	ENDIF



rdc2:	lhld cda
	mov a,m		;test if ZSYSTEMS c.ccc
	cpi 0ebh
	jz rdc2a
	xra a		;if not, reset zsysf, else set it
rdc2a:	sta zsysf

	lxi d,cccsiz
	dad d
	mov e,m
	inx h
	mov d,m	
	lhld cda
	dad d
	shld cdp
	call close
	
	IF CPM
	call resfn	;restore main filename to default fcb under CP/M
	ENDIF

	IF TESTING
	call printf
	   db 'c.ccc loaded correctly',0
	ENDIF

	ret		;end of readc routine

	IF CPM
savfn:	lxi h,fcb
	lxi d,fcbt
	jmp movfn

resfn:	lxi h,fcbt
	lxi d,fcb
	jmp movfn
	ENDIF

	IF CPM
movfn:	mvi b,13
movf1:	mov a,m
	stax d
	inx h
	inx d
	dcr b
	jnz movf1
	ret
	ENDIF

	IF NOT CPM
movfn:	mov a,m
	stax d
	inx h
	inx d
	ora a
	jnz movfn
	ret
	ENDIF


;
; Read a function in to memory from the currently open CRL file:
;

rdfun:	call ckabrt
	lda fcnt	;bump function count
	inr a
	sta fcnt
	cpi 255		;reached functional limit of clink?
	jnz rdf0
	lxi d,stgtmf	;yes. complain and abort.
	jmp stgab
			;else proceed reading in the function:
rdf0:	lhld enst	;get starting position of function in the file
	mov b,h
	mov c,l		;put into BC
	call cmh	;negate it
	xchg
	lhld enend	;get ending position (actually start of next one)
	dad d		;subtract starting position to get length
	push h		;save length
	xchg		;put into DE
	lhld cdp	;and add to current load address
	dad d

rdf0a:	lda curtop+1	;to see if it overflows memory
	dcr a		;** possible bug fix ***
	mov l,a
	mov a,h
	cmp l
	jc rdf1		;overflow?
			;yes....

	IF CPM
	lda ccpok	;CCP intact?
	ora a
	jnz rdf00a	;if so, try making it go away
	ENDIF

rdf0b:	lxi d,stgom	;if so, print message and abort
	jmp stgab	;just abort under CP/M

rdf00a:
	IF CPM
	push h		;save HL
	lhld bdosp	;get protected memory address
	mvi l,0
	shld curtop	;make it new top of memory
	pop h		;restore HL
	xra a
	sta ccpok	;clear CCP intact flag
	jmp rdf0a	;go try again
	ENDIF

rdf1:
	IF CPM
	lxi d,fcb	;OK, function will fit into memory.
	call setdat
	mov a,c
	ori 80h
	mov l,a
	mvi h,ram/256
	shld tbp
	call reads
	ENDIF

	IF NOT CPM
	lhld enst	;get starting position of function in CRL file
	mvi b,0		;absolute seek
	mvi c,m$seek
	lda marcfd
	call msys	;seek to correct position in file
	jnz ferror
	ENDIF

	lhld cdp	;get code pointer
	xchg		;put into DE: this is where the data will go
	pop h		;get length of function module
	push h
	dad d		;add to base address
	shld cdn	;save this for some other routine to futz with

	IF CPM
	pop h
rdf2:	call rdbt
	stax d
	inx d
	dcx h
	mov a,h
	ora l
	jnz rdf2
	ret
	ENDIF

	IF NOT CPM
	pop d		;get length of function module
	lhld cdp	;get load address for function module
	call reads	;read in the module
	ret
	ENDIF

	IF CPM		;all this kludgery only for CP/M
rdbt:	push h
	lhld tbp
	mov a,l
	ora a
	jz rdb2
	mov a,m
	inx h
	shld tbp
	pop h
	ret

rdb2:	call reads
	lxi h,tbuff
	mov a,m
	inx h
	shld tbp
	pop h
	ret

;
; Routine used under CP/M to set the extent and record fields
; of the default fcb to the first sector of the function to be read in:
;

setdat:	mov h,b
	mov l,c
	dad h
	mov a,h
	ani 7fh
	lxi h,32
	dad d
	mov m,a
	sta tmpnr
	mov a,b
	rlc
	rlc
	ani 3
	lxi h,12
	dad d
	cmp m
	rz
	push psw
	push h
	call close
	pop h
	pop psw
	mov m,a
	call open
	jc abort
	lda tmpnr
	sta fcb+32
	ret
	ENDIF		;end of this section of CP/M-only kludgery

pre:
	IF TESTING
	call printf
	  db 'calling rdfun:',0
	ENDIF

	call rdfun	;read in the function

	IF TESTING
	call printf
	  db 'returned from rdfun.',0
	ENDIF
	
	lhld cdp

	push h		;find start of code, so on-the-fly
pre0:	mov a,m		;reference fixing can be done for
	inx h		;those references to functions
	ora a		;already processed and in their
	jnz pre0	;fixed positions.
	inx h		;found end of name list.
	inx h		;now HL -> start of actual func code
	shld fncodb	;save function code begin addr
	pop h
	
	lda fcnt2
	mov b,a
	mvi c,0
pre1:	mov a,m
	ora a
	jz pre2
	push h
	inr c
	mov h,b
	mov l,c
	shld refv
	xra a
	sta gotf
	pop h
	push h
	push b
	call entt1
	pop b
	pop h
	call pb7hi
	jmp pre1

pre2:	inx h
	mov c,m
	inx h
	mov b,m
	inx h
	xchg
	lhld cdp
	push h
	push h
	call cmh
	dad d
	xchg
	pop h
	call sqish
	pop h
	dad b
	push h
	mov c,m
	inx h
	mov b,m
	inx h
	push h
	call getcdf2
	shld fadr
	pop h
pre3:	mov a,b
	ora c
	jz pre4
	mov e,m
	inx h
	mov d,m
	inx h
	push h
	lhld cdp
	dad d
	mov e,m
	inx h
	mov d,m
	push h
	lhld fadr
	dad d
	xchg
	pop h
	mov m,d
	dcx h
	mov m,e
	pop h
	dcx b
	jmp pre3

pre4:	pop h
	shld cdp
	ret

cmh:	push psw
	mov a,h
	cma
	mov h,a
	mov a,l
	cma
	mov l,a
	inx h
	pop psw
	ret


sqish:	push b
	mov b,h
	mov c,l
	dad d
	xchg
	lhld cdn
sq2:	ldax d
	stax b
	mov a,d
	cmp h
	jnz sq3
	mov a,e
	cmp l
	jnz sq3
	pop b
	ret
sq3:	inx d
	inx b
	jmp sq2


reslv:	lxi h,tab1
	mvi d,0
rlv2:	mov a,m
	ora a
	rz
	inx h
	jp rlv2
	mov a,m
	ani 7fh
	mov b,a
	inx h
	mov c,m
	inx h
	push h
	push d
	mov l,d
	mvi h,0
	dad h
	lxi d,tab2
	dad d
	mov e,m
	inx h
	mov d,m
	call getcdf
	dad d
	shld doresv
	pop d
	pop h

rlv3:	mov a,b
	ora c
	jnz rlv4
	inr d
	jmp rlv2

rlv4:	push d
	push h
	inx h
	mov l,m
	mvi h,0
	dad h
	lxi d,tab2
	dad d
	mov e,m
	inx h
	mov d,m
	pop h
	mov a,m
	inx h
	inx h
	call dores
	pop d
	dcx b
	jmp rlv3


dores:	push h
	push b
	mov c,a
	mvi b,0
	lxi h,0
	dad b
	dad b
	dad b
	inx h
	dad d
	xchg
	lhld doresv
	xchg
	mov m,e
	inx h
	mov m,d
	pop b
	pop h
	ret


entt1:	xchg
	lxi h,tab1
	lxi b,0
	xra a
	sta fcnt2
et1a:	mov a,m
	ora a
	jz et1c
	push b
	call stcmp
	pop b
	jz et1d
	lda fcnt2
	inr a
	sta fcnt2
et1b:	call past1e
	inx b
	jmp et1a

et1c:	ldax d

	IF CPM
	call mapuc2
	ENDIF

	mov m,a
	inx d
	inx h
	ora a
	jp et1c
	mvi m,0
	inx h
	mvi m,0
	inx h
	mvi m,0
	dcx h
	dcx h

	xra a		;allow this symbol entry
	sta rdngsm
	
	push d
	call ckov2	;check for table 1 overflow
	pop d

et1d:	lda gotf
	ora a
	mov a,m
	inx h		;has the function just been read in?
	jnz et1e
	ora a		;no. has it been read in previously?
	jp et1d2


	lda fcnt2	;yes. fix reference immediately. first
	mov l,a		; compute where referenced function will
	mvi h,0		; reside at run time...
	dad h		;now HL is offset into tab2.
	lxi d,tab2	;get HL pointing to location of address
	dad d		; of referenced function.
	mov a,m		;and get the address.
	inx h
	mov h,m
	mov l,a		;now HL points to the function code in RAM
	xchg		;need to add offset to get actual
	call getcdf	; load address
	dad d		;now HL = load address of the referenced func
	shld doresv	;save it for use by dores.

	lhld fncodb	;now compute location of reference within
	xchg		; the new function...DE -> start of code
	lda refv	;A tells position # of jump vector
	jmp dores	;let dores figure out the rest and do

et1d2:	push d
	mov e,m
	dcx h
	mov d,m
	inx d
	mov m,d
	inx h
	mov m,e
	pop d
	inx h
	call tb1ex

	call ckfng
	xchg
	lhld refv
	xchg
	mov m,e
	inx h
	mov m,d
	ret

et1e:	lda rdngsm	;has new symbol been previously defined?
	ora a
	jz et1e2

	dcx h		;perhaps. test if table entry is defined...
	mov a,m
	ora a
	inx h
	jp et1e2	;if bit 7 was set on that byte, it was defined...
			; so was it?
	lxi d,stgdps	;yes...complain
	lxi h,sname
	lda fflag	;forcing all functions from a crl file?
	ora a
	jz et1e0

	mvi a,81h	;set this so function doesn't get loaded later
	sta gotf
	lxi d,stgdpf	;if so, use special message for duplicate entry
	lhld savnam	;get pointer to function name
	
	IF FORCE
	push h
	mov a,m
	cpi 'M'
	jnz et1e00
	inx h
	mov a,m
	cpi 'A'
	jnz et1e00
	inx h
	mov a,m
	cpi 'I'
	jnz et1e00
	inx h
	mov a,m
	cpi 'N'+80h		
	jnz et1e00
	pop h
	ret

et1e00:	pop h
	ENDIF

et1e0:	call pstg
et1e1:	call pfnm
	call crlf	;follow with CR-LF combo
	ret		;and ignore the symbol name this time...


et1e2:	dcx h
	mov a,m
	ori 80h
	mov m,a
	lxi h,tab2
	dad b
	dad b
	xchg
	lhld cdp
	xchg
	mov m,e
	inx h
	mov m,d
	ret

ckfng:	push d
	push h
	xchg
	lhld fngtt
	mov a,h
	sub d
	jc ckfd
	jnz ckfng1
	mov a,l
	sub e
	jc ckfd
ckfng1:	inx h
	inx h
	shld fngtt
ckfd:	pop h
	pop d
	ret

;
; Expand tab1 from the current position of HL by 2 bytes:
;

tb1ex:	push h
	push b

	push h
	lhld tb1end
	mov b,h
	mov c,l
	dcx b
	dcx b
	pop h

	call cmh
	dad b
	inx h
	push b
	mov b,h		;set BC to the count
	mov c,l

	lhld tb1end
	xchg
	pop h		;HL is source addr

	mvi a,2		;if on 8080, do it the hard way
	inr a
	jpo z80exp

ex8080:	mov a,m
	stax d
	dcx h
	dcx d
	dcx b
	mov a,b
	ora c
	jnz ex8080
	jmp ckov

z80exp:	db 0edh,0b8h	;LDDR on Z80.

ckov:	lhld tb1end	;check last byte of tab1 (initialized to zero)
	lxi d,-10
	dad d
	mov a,m
	ora a		;if still zero, ok
	jz ckovok
	lxi d,stgt1o	;else overflow
	jmp stgab

ckov2:	push h
	push b
	jmp ckov
	
ckovok:	pop b
	pop h
	ret	

;
; Test the strings at DE (b7 high on last char) and
; at HL for equality:
;

stcmp:	push b
	push d
	push h
stcm1:	mov a,m

	IF CPM
	call mapuc2
	ENDIF

	mov b,a
	ldax d

	IF CPM
	call mapuc2
	ENDIF

	cmp b
	jnz stcm3
	ora a
	jm stcm2
	inx d
	inx h
	jmp stcm1
stcm2:	pop d
	pop d
	pop b
	xra a
	inx h
	ret
stcm3:	pop h
	pop d
	pop b
	ret

;
; Map character in A to upper case, preserving
; the parity bit:
;

mapuc2:	push b
	ora a
	push psw
	ani 7fh
	call mapuc
	mov b,a
	pop psw
	mov a,b
	pop b
	rp
	ori 80h
	ret

;
; Test routine for debugging MARC version under CP/M:
;
	IF TESTING2
test:	lxi h,argvtt	;test argv
	push h
	lxi h,2		;test argc
	push h
	lxi h,0		;dummy return address
	push h
	jmp  tpa

argvtt:	dw argv0
	dw argv1
	dw argv2

argv0:	db 'clink',0
argv1:	db 't',0
argv2:	db '-s',0
	ENDIF

	IF TESTING OR TESTING3
printf: xthl		;save HL on stack, get string pointer into HL
	push d		;save DE
	xchg		;put string pointer into DE
	call pstg	; print the string
	xchg		;put return address from DE into HL
	push h
	call crlf	; and follow with cr-lf
	pop h		;get back return address
	pop d		; restore DE
	xthl		;put return address back on stack, get back HL	
	ret		
	ENDIF		;end of test sequence


;
; Return Z true if char is space or tab:
;

twhite:	cpi ' '
	rz
	cpi tab
	ret

wsp:	equ getfn

ascb:	ds 4	;ascii buffer used for hex-to-decimal conversion
	db 0

curtop:	ds 2	;pointer to top of user memory

zsysf:	ds 2	;z systems flag

donef:	ds 1	;tells if all linked up yet
dcrl:	ds 1	;disk from which to get deff and deff2
cdp:	ds 2	;points to next free space in code
cdn:	ds 2
enst:	ds 2	;used to pass disk addr of function to "rdfun"
enend:	ds 2	;used to pass last disk addr of function + 1 to "rdfun"
smsf:	ds 2	;external data block size
quietf:	ds 1	;true if we don't want to complain if can't open file


fcnt:	ds 1	;function count...holds current function number
fcnt2:	ds 1
gotf:	ds 1	;set true when calling "entt1" w/ just-loaded function
statf:	ds 1	;true if -s option given
wflg:	ds 1	;true if -w option given
segf:	ds 1	;true if segment being linked
zflag:	ds 1	;true if -z option given
tmpnr:	ds 1	;workspace used by "setdat" routine
fngtt:	ds 2
refv:	ds 2
fadr:	ds 2
bufp:	ds 2
buffp:	ds 2	;used by gsyms routine as buffer pointer

cline:	ds 140	;elongated for v1.32
sname:	ds 15
cptr:	ds 2
mflag:	ds 1
dflag:	ds 1	;true if we've scanned DEFF.CRL under CP/M, or if we've
		;scanned all deff?.crl files under MARC

taddr:	ds 2	;address of top of memory available to running program
taddrf:	ds 1
eflag:	ds 1	;if external address supplied
eaddr:	ds 2	;if eflag true: extern. addr.
extadd:	ds 2	; final external address.
wrsmf:	ds 1	;true if writing symbols to disk during outch calls
rdngsm:	ds 1	;true if reading a symbol from a file
nsmbs:	ds 2
tbase:	ds 2
fflag:	ds 1	;true when loading all functions; else scanning for needed ones
runsat:	ds 2	;load address
savcdp:	ds 2	;save cdp here while reading in symbols
debugf:	ds 1	;true if running file instead of writing to disk
argptr:	ds 2	;points to arg list text if used with -d option
fncodb:	ds 2	;used in new mod to do reference fixing on the fly
doresv:	ds 2
fargb:	ds 2
savnam:	ds 2	;used to save function name pointers for error printout
tb1siz:	ds 2
cda:	ds 2
tb1end:	ds 2
tab2:	ds 512
direc:	ds 512

	IF CPM
d2flag:	ds 1	;true if we've scanned DEFF2.CRL
d3flag:	ds 1	;true if we've scanned DEFF3.CRL
hflag:	ds 1	;true if Leo want's lhld 4206 instead of 0006
tbp:	ds 2
ccpok:	ds 1
spsav:	ds 2
nflag:	ds 1	;true if "-n" for noboot given
curusr:	ds 1	;current user area number
savdrv:	ds 1	;saved drive number when temporarily gone elsewhere
search:	ds 1	;true to search current drive/user area for file, then default
	ENDIF

	IF MARC
argc:	ds 1
argv:	ds 2
marcfd:	ds 1
maxmd:	ds 1	;true if maxmem call done yet
iflag:	ds 1	;true if image mode output file wanted; else load format file
btsav:	ds 1	;scratch used by writld routine
endtst:	ds 1
datap:	ds 2
runsav:	ds 2
oflag:	ds 1	;true if -o given
noffst:	ds 2	;either 0 or 6, depending on whether -c option used
fcbs:	ds 40
fcbt:	ds 40
consfd:	ds 1	;1 if console output going to stdout, or 2 for stderr
dlast:	ds 1	;last deff?.crl file searched ('1', '2', ...), or 0 if none
	ENDIF

	ds 75
stack:	equ $

tab1:	equ $		;reference table begins here

	IF LASM
	end
	ENDIF
