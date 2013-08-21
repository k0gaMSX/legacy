;
;
; cc2a.asm
;
; 7/18/82: Added Kirkland debugging feature: if kflg (110h) is non-zero,
; 	   we assume it is the proper restart value to be inserted
;	   at the start of each expression that is the first on a line,
;	   to be followed by the line number.
;
; 12/30/85: Added new "modstk" module numbering/naming mechanism as 
; 	previously implemented in CC.
;


	org ram+100h	;start of TPA

	jmp cc2		;jump around data passed from CC during autoload:

	IF CPM
chainf:	db 0		;true if cc2 being auto-loaded by cc1 (103h)
	ENDIF

	IF NOT CPM
chainf:	db 1		;always being auto-loaded if under MARC
	ENDIF

optimf:	db 1		;true if value-fetch hack is OK to perform (104h)
cccadr:	dw ram+100h	;address of base of run-time package 	(105h)
exaddr:	ds 2		;explicit external address, (if eflag is true) (107h)
eflag:	db 0		;default to no explicit external address (109h)

	IF MARC
fnam:	ds 2		;pointer to filename for use in writing out crl file
	ENDIF

	IF CPM
spsav:	ds 2		;saved CCP stack pointer under CP/M (10Ah)
	ENDIF

curtop:	ds 2		;current top of memory (10Ch)

	IF MARC
maxmd:	db 0		;maxmem done flag, under MARC
	ENDIF

	IF CPM
ccpok:	db 1		;CCP still intact flag, under CP/M (10Eh)
	ENDIF

	IF CPM
erasub:	db 0		;bit 0: true if erasing submit files on error (10Fh)
			;bit 1: "werrs" true if writing RED file
	ENDIF

	IF NOT CPM
	ds 1		;dummy byte under MARC
	ENDIF

cdbflg: db 0		;CDB flag (-k<n> option to CC1) (110h)

	IF CPM
defsub:	db 0		;where to find submit files (CP/M only) (111h)
conpol:	db 1		;whether or not to poll console for interrupts (112h)
errbyt:	dw errdum	;ZCPR3 error condition flag address (dummy default)
	ENDIF


	IF NOT CPM
	ds 4
	ENDIF

oktort:	db 0		;extracted from ccpok b1 on startup
wboote:	db 1		;extracted from ccpok b2 on startup
zenvf:	db 0		;extracted from ccpok b3 on startup

errdum:	ds 1		;dummy zcpr3 error flag


cc2:	lxi h,0		;save current SP in HL
	dad sp
	lxi sp,stack	;set up new stack

	IF CPM
	lda defsub
	inr a
	sta subfile
	ENDIF

	lda chainf	
	ora a
	jz cc2a		;if not chaining, go initialize stuff

			; UNPACK ccpok:

	lda ccpok	;extract oktort from ccpok
	mov b,a
	ani 1		;b0
	sta ccpok	;set ccpok flag

	mov a,b
	ani 2		;b1
	rrc
	sta oktort	;set ok to return to ccp flag

	mov a,b
	ani 4		;b2
	rrc
	rrc
	sta wboote	;set do warm boot on exit flag

	mov a,b
	ani 8		;b3
	rrc
	rrc
	rrc
	sta zenvf	;set ZCPR3 flag

	ora a		;Z environment?
	jnz cc20a	;if not, go do greeting

	lxi h,errdum	;else set errbyt address to dummy
	shld errbyt

cc20a:	lxi d,s00	;print CR-LF if being chained to from cc1
	call pstgco	;if chaining, print CR-LF before sign-on message
	jmp cc2b

cc2a:	shld spsav	;save CCP stack pointer
	lhld ram+6
	shld curtop	;set up current top of memory below CCP
	mvi a,1
	sta ccpok	;set CCP not bashed flag
	
cc2b:	lhld errbyt
	mvi m,0		;no error by default

	lxi d,s0	;regular sign-on msg
	call pstgco

	call c2init	;do rest of initialization

cc2c:	call dofun	;process a function
	lhld cdp
	call igshzz	;move pointer to next function
	shld cdp	;and save text pointer
	mov a,m		;get 1st char of next function
	lxi h,entn	;bump entry count (function count)
	inr m
	ora a
	jnz cc2c	;are we at EOF?

    	lhld codp	;yes.
	dcx h
	shld eofad	;set this for the "writf" routine

	call errwrp	;wrap up error handling, exit if there were errors

	lxi h,ascb+4	;else do write out a CRL file...
	mvi m,'K'	;but first give a usage report

	IF CPM
	lhld bdosp	;this is as high as free memory can ever get
	mvi l,0
	ENDIF

	xchg
	lhld codp	;and this is as high as we got generating code
	call cmh
	dad d
	mov a,h		;divide difference by 1K
	rar
	rar
	ani 3fh
	mov l,a		;and print out result
	mvi h,0
	dcx h
	xra a
	call prhcs	;print out their difference
	lxi d,stgtsp	;with some text
	call pstg	;and...

	call writf	;write out the CRL file

	IF CPM
exit:	lda wboote	;do warm boot on exit?
	ora a
	jnz ram		;if so, go boot

	lda chainf	;did we chain?
	ora a
	jz ram		;if not, do warm boot in case we're SID-ing

	lhld spsav	;get possibly saved CCP SP
	sphl

	lda ccpok	;CCP intact?
	ora a
	rnz		;return if so

	lda oktort	;ok to return DESPITE ccpok's value?
	ora a
	rnz		;if so, return

	jmp ram		;else warm-boot
	
	ENDIF


;
; Some standard routine addresses within C.CCC, all relative
; to the origin of C.CCC (stored at cccadr at run time)
; These values will change anytime C.CCC is reconfigured.
;

ldei:	equ 04dh	;value-fetch routines
sdei:	equ 05ch
lsei:	equ 06bh
ssei:	equ 077h
ldli:	equ 083h
sdli:	equ 090h


pzinh:	equ 09dh		;flag conversion routines
pnzinh:	equ pzinh+6
pcinh:	equ pzinh+12
pncinh:	equ pzinh+18
ppinh:	equ pzinh+24
pminh:	equ pzinh+30
pzind:	equ pzinh+36
pnzind:	equ pzinh+42
pcind:	equ pzinh+48
pncind:	equ pzinh+54
ppind:	equ pzinh+60
pmind:	equ pzinh+66

eqwel:	equ 0e5h	;relational operator routines

blau:	equ 0ebh
albu:	equ blau+1

bgau:	equ 0f2h
agbu:	equ bgau+1

blas:	equ 0f9h
albs:	equ blas+1

bgas:	equ 104h
agbs:	equ bgas+1


smod:	equ 10fh
usmod:	equ 129h
smul:	equ 13fh	;multaplicative operator routines
usmul:	equ 16bh
usdiv:	equ 189h
sdiv:	equ 1cbh


sderbl:	equ 1e4h	;shift operator routines
shlrbe:	equ sderbl+1
sdelbl:	equ 1f2h
shllbe:	equ sdelbl+1


cmhl:	equ 1fah	;2's complement routines
cmd:	equ 202h



;
; Keyword codes
;

gotcd:	equ 8dh		;goto
rencd:	equ 8eh		;return
sizcd:	equ 8fh		;sizeof
brkcd:	equ 90h		;break
cntcd:	equ 91h		;continue
ifcd:	equ 92h		;if
elscd:	equ 93h		;else
docd:	equ 95h		;do
whlcd:	equ 96h		;while
swtcd:	equ 97h		;switch
lbrcd:	equ 9bh		;{
rbrcd:	equ 9ch		;}
mainc:	equ 9dh		;main
pplus:	equ 0b2h	;++
mmin:	equ 0b3h	;--
arrow:	equ 0b4h	;->
mincd:	equ 0b5h	;-
mulcd:	equ 0b6h	;*
divcd:	equ 0b7h	;/
ancd:	equ 0bbh	;&
letcd:	equ 0beh	;=
notcd:	equ 0bfh	;!
open:	equ 0c2h	;(
close:	equ 0c3h	;)
plus:	equ 0c4h	;+
period:	equ 0c5h	;.
semi:	equ 0c6h	;";"
comma:	equ 0c7h	;,
openb:	equ 0c8h	;[
closb:	equ 0c9h	;]
colon:	equ 0cah	;:
circum:	equ 0cbh	;~
qmark:	equ 0c0h	;?
slcd:	equ 0b0h	;<<
srcd:	equ 0b1h	;>>
lecd:	equ 0aeh	;<=
gecd:	equ 0afh	;>=
eqcd:	equ 0aah	;==
neqcd:	equ 0abh	; <excl.pt.>=
modcd:	equ 0b8h	;%
gtcd:	equ 0b9h	;>
ltcd:	equ 0bah	;<
xorcd:	equ 0bch	;^
orcd:	equ 0bdh	;|
andand:	equ 0ach	;&&
oror:	equ 0adh	;||


;
; Text strings:
;

s1:	db 'Can''t open file+'
s2:	db cr,lf,'Write error+'
s2a:	db 'CRL Dir overflow: break up source file+'
s3:	db 'Missing label+'
s4:	db 'Missing semicolon+'
s4a:	db 'Extra text after statement, before ";"+'
stgms:	equ s4	;a more mnemonic name for this error msg
s5:	db 'Illegal statement+'
s6:	db 'Can''t create CRL file+'
stg7:	db 'Bad operator+'
stg8:	db 'Lvalue required+'
stg8a:	db '++ or -- operator needs Lvalue+'
stg8b:	db 'Bad left operand in assignment expr.+'
stg9:	db 'Mismatched parens+'
stg9a:	db 'Mismatched brackets+'
stg10:	db 'Bad expression+'
stg11:	db 'Bad function name+'
stg13:	db 'Bad arg to unary op+'
stg14:	db 'Expecting ":"+'
stg15:	db 'Bad subscript+'
stg16:	db 'Bad array base+'
stg17:	db 'Bad struct or union spec+'
stg17a:	db 'Using undefined struct type+'
stg18:	db 'Bad type in binary operation+'
stg19:	db 'Bad struct or union member+'
stg20:	db 'Bad member name+'
stg21:	db 'Illegal indirection+'
stgie:	db 'Internal error: garbage in file or bug in C+'
stgom:	db 'Sorry, out of memory. Break it up!+'
stgeof:	db 'Encountered EOF unexpectedly+'
stgbf:	db 'Bad parameter list+'
stgeri:	db cr,lf,'RED error output initiated+'

	IF CPM
stgabo:	db 'Compilation aborted by ^C+'
	ENDIF

	IF NOT CPM
stgabo:	db 'Compilation aborted+'
	ENDIF
 
stgbbo:	db 'Expecting binary op+'
stgeop:	db 'Missing "("+'
stgecp:	db 'Missing ")"+'

stgtsp:	db 'to spare',cr
	IF MARC
	   db lf
	ENDIF
	db 0

stgftb:	db 'The function ',0
stgtb2:	db ' is too complex; break it into smaller ones+'
stgmlb:	db 'Missing "{" in function def''n+'
stgcsn:	db 'Control Structure '
stgetc: db 'Nesting too deep+'

	IF CPM
subfile: db 1,'$$$     SUB',0,0,0,0
	ENDIF

s00:	db cr,lf,0

patch:	dw 0,0,0,0,0,0,0,0,0,0ffffh	;patch space
patch2:	dw 0,0,0,0,0,0,0,0ffffh
patch3:	dw 0,0,0,0,0,0,0ffffh


;
; Special codes
;

nlcd:	equ 0f7h	;new-line (linefeed)
concd:	equ 0f8h	;constant code (followed by 2 byte value)
varcd:	equ 0f9h	;variable code (foll. by 2 byte disp into s.t.)
lblcd:	equ 0fah	;label code (foll. by 2-byte label val)
labrc:	equ 0fch	;label reference (foll. by 2-byte label code value)
strcd:	equ 0fdh	;string code (foll. by 2-byte sting #)
swtbc:	equ 0feh	;byte following `switch(expr)', preceding case table

litrl:	equ 0f7h
endms:	equ 38h

modbeg:	equ 0f5h
modend:	equ 0f6h



minit:	lda optimf	;look at rst7 bit of optimization flag
	ani 40h
	rz		;if not set, don't fudge with macro table
	lxi h,m16bz
	shld mactz
	shld mactz+2
	lxi h,m18z
	shld mactz+4
	shld mactz+6
	ret


;
; Come here on an internal error (if ierror is called instead
; of jumped to, that makes it easier to find out where the
; internal error occurred)
;

ierror:	lxi d,stgie	;come here when things are REALLY skewered

;
; Print out error and abort compilation:
;

perrab:	call perr


;
; The general abort entry point...abort submit processing
; and reboot.
;

errab:	push h
	lhld errbyt
	mvi m,1		;set zcpr3 error flag (or dummy under CP/M)
	pop h
	
	lda werrs
	ora a
	cnz errwr2

errab2:
	mvi a,7		;ring a bell for errors having occurred
	call outch
	lda erasub	;bother to erase submit files?
	ora a
	jz exit		;if not, all done

	mvi c,sguser	;get current user
	mvi e,0ffh

	push psw	;save current user

	mvi c,sguser	;select user 0
	mvi e,0
	lda zenvf	;but only under ZSYSTMS!
	ora a
	cnz bdos

	lxi d,subfile	;erase pending submit files
	call delf2

	pop psw		;get original user
	mov e,a
	mvi c,sguser	;select original user
	call bdos

	jmp exit	;all done


;
; Routine that expects a semicolon to be the next non-space
; character in the text. If it isn't, spew an error. If it
; is, pass over it:
;

psemi:	call igsht
	cpi semi
	jnz psmi2
	inx h
	ret

psmi2:	push h
	lhld nlcnt	;get current line number
	xthl		;put in on stack, get text ptr in HL
	call fsemi	;advance to semicolon
	xthl		;push text ptr onto stack, get old line no. in HL
	xchg		;put old line no. in DE
	lhld nlcnt	;get current line no.
	call cmpdh	
	pop h		;get back current text ptr
	lxi d,s4
	jnz psmi3	;if no semicolon on current line, complain about
			; missing semicolon
	lxi d,s4a	;else complain about superfluous characters	
psmi3:	call perr
	inx h		;advance text ptr past semicolon
	ret


;
; Routine to skip everything until a semicolon is found (used
; mainly in error-recovery following the detection of a really
; screwy, non-cleanly-recoverable error):
;

fsemi:	mov a,m
	ora a
	jz igshe1	;if EOF, bad error
	cpi semi
	rz

	lxi d,s5
	cpi lbrcd
	jz perrab
	cpi rbrcd
	jz perrab

	cpi nlcd
	jnz fsemi3
	push h
	lhld nlcnt
	inx h
	shld nlcnt
	pop h
fsemi3:	call cdtst
	jc fsemi5
	inx h
	inx h
fsemi4:	inx h
	jmp fsemi

fsemi5:	cpi modbeg
	jnz fsemi4
	push d
	lxi d,13
	dad d
	pop d
	jmp fsemi


;
; Given HL->text, pass by any special codes and white space:
;

pascd:	call igsht
	call cdtst
	rc
	inx h
	inx h
	inx h
	jmp pascd

igcd:	equ pascd

pascd2:	call igshzz
	ora a
	rz
	call cdtst
	jnc pscd3
	ora a
	ret
pscd3:	inx h
	inx h
	inx h
	ora a
	jmp pascd2

cdtst:	cpi 0f8h
	rc
	cpi 0feh
	cmc
	ret

;
; Ignore white space in text (but acknowledge newlines
;  by bumping line count when they're encountered), and handle
; modbeg/modend:
;

igsht:	call igshzz
	ora a
	rnz
	lda prnflg	;file ends inside parens or brackets?
	ora a
	jz igshe1

	lxi d,stg9	;yes...if prnflag is 1, then use parens message
	dcr a
	jz igsht0	
	lxi d,stg9a	;else use brackets message

igsht0:	lhld prnsav
	shld nlcnt
	jmp perrab

igshe1:	lxi d,stgeof
igshe2:	jmp perrab

igshzz:	mov a,m
	ora a
	rz
	cpi nlcd
	jnz igsh2
	push h		;bump newline count
	lhld nlcnt
	inx h
	shld nlcnt
	pop h
	inx h
	jmp igshzz

igsh2:	cpi lblcd
	jnz igsh3
	push d
	inx h
	mov e,m
	inx h
	mov d,m
	inx h
	call entl
	pop d
	jmp igshzz

igsh3:	cpi ' '
	jnz igsh4
igsh3a:	inx h
	jmp igshzz

igsh4:	cpi modbeg	;module begin?
	jnz igsh5
	inx h
	call pushmn	;push module name on module stack
	jmp igshzz

igsh5:	cpi modend	;module end?
	rnz
	call popmn	;pop module name
	jmp igsh3a

;
; Push module name at HL onto modstk, save current line number
; after it in the module stack, bump modstc, and reset nlcnt:
;

pushmn:	xchg	;put text ptr in DE
	push h	;save HL
	lxi h,modstc
	inr m
	lhld modstp
	mvi b,12
	call movrc
	push d
	xchg
	lhld nlcnt
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	shld modstp
	lxi h,0
	shld nlcnt
	pop d
	pop h
	xchg
	ret
		
;
; Pop modstk entry:
;

popmn:	push h
	push d
	lhld modstp
	dcx h
	mov d,m
	dcx h
	mov e,m
	xchg
	shld nlcnt
	lxi h,-12
	dad d
	shld modstp
	lxi h,modstc
	dcr m
	pop d
	pop h
	ret

;
; Move B bytes from (DE) to (HL):
;

movrc:	push psw
movrc1:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz movrc1
	pop psw
	ret		


;
; Peek forward to next token, without actually processing any
; codes or changing status of the text pointer from the current value:
;

peeknxt:
	push h		;save text pointer
	push d
	dcx h
peekn1:	inx h		;look at next char
peekn2:	mov a,m		;if null, done
	ora a
	jz peekn4
	cpi nlcd	;ignore all whitespace and codes
	jz peekn1
	call cdtst
	jc peekn3
	inx h
	inx h
	jmp peekn1
peekn3:	cpi ' '
	jz peekn1
	cpi modend
	jz peekn1
	cpi modbeg
	jnz peekn4
	lxi d,13
	dad d
	jmp peekn2	
peekn4:	pop d
	pop h
	ret


;
; Given that HL->open paren in text, find the matching
; close paren and pass by it (if no matching paren is ever
; found, announce an error ocurring on original line where
; the open paren was found):
;

mtchp:	mvi a,1
	sta prnflg
	push h
	lhld nlcnt
	shld prnsav
	pop h
	call mtchpz
	push psw
	xra a
	sta prnflg
	pop psw
	ret

mtchpz:	inx h
	call igcd
	cpi close
	jnz mtcp2
	inx h
	ret

mtcp2:	cpi open
	jnz mtchpz
	call mtchpz
	dcx h
	jmp mtchpz

;
; Similar to mtchp, except for square brackets instead:
;

mtchb:	mvi a,2
	sta prnflg
	push h
	lhld nlcnt
	shld prnsav
	pop h
	call mtchbz
	push psw
	xra a
	sta prnflg
	pop psw
	ret


mtchbz:	inx h
	call igcd
	cpi closb
	jnz mtcbz2
	inx h
	ret

mtcbz2:	cpi openb
	jnz mtchbz
	call mtchbz
	dcx h
	jmp mtchbz

;
; Convert ASCII character in A to upper case,
; but don't change value of parity bit!
;

mapuc:	push b
	mov b,a
	ani 7fh
	call mapuc2
	mov c,a
	mov a,b
	ani 80h
	ora c		;OR in original parity bit
	pop b
	ret

mapuc2:	cpi 61h
	rc
	cpi 7bh
	rnc
	sui 32
	ret

;
; Return Cy set if (DE < HL)
;


cmpdh:	mov a,d
	cmp h
	rnz
	mov a,e
	cmp l
	ret


;
; Print error message, but use the line number saved at "savnlc" instead
; of the standard "nlcnt" count:
;

perrsv:	push	h		;save current text pointer
	lhld	nlcnt		;save current line count
	push	h
	lhld	savnlc		;get saved line count
	shld	nlcnt		;make it current just for this
	call	perr
	pop	h		;now restore everything
	shld	nlcnt
	pop	h
	ret			;and return


;
; Report error by first printing out the current line number followed
; by a colon and a space, and then printing out the string pointed to
; by DE on entry:
;

perr:	mvi a,1
	sta errf
	lda prerrs	;print error msgs?
	ora a
	rz		;return if not
	push h
	call pmodnc	;print module name, colon, space
	lhld nlcnt
	call prhcs
	call pstg
	pop h
	ret


;
; Print out current module name, followed by a colon and space
;

pmodnc:	call pmodnm
	push psw
	mvi a,':'
	call outch
	mvi a,' '
	call outch
	pop psw
	ret

;
; Print out current module name:
;

pmodnm:	push h
	push d
	lhld modstp
	lxi d,-14
	dad d
	xchg
	call pfnam2
	pop d
	pop h
	ret


;
; Print out filename of fcb at DE:
;


pfnam2:	push b
	ldax d		;get disk code
	ora a
	jz pfnm3	;if file on currently logged disk, don't print
			;disk designator.

;	mvi c,gdisk	;This section of code commented out to keep
;	push d		;files on the currently logged drive from having
;	call bdos	;a disk designator printed before their names.
;	pop d		;uncomment the code to put this feature back
;	inr a		;into action.

pfnm2:	adi '@'		;get A = 'A' for drive A, 'B' for B, etc.
	call outch
	mvi a,':'
	call outch
pfnm3:	inx d
	mvi b,8
	call pnseg
	ldax d
	cpi ' '
	mvi a,'.'	;print dot only if filename has extension
	cnz outch
	mvi b,3
	call pnseg
	pop b
	ret

pnseg:	ldax d
	cpi ' '
	cnz outch
	inx d
	dcr b
	jnz pnseg
	ret


;
; Print out the null-terminated string pointed to by DE:
;

pstg:	ldax d
	ora a
	rz
	cpi '+'
	jnz pstg2
	mvi a,cr
	call outch
	mvi a,lf
	jmp outch

pstg2:	call outch
	inx d
	jmp pstg


;
; Output a string to console only:
;

pstgco:	lda werrs
	push psw
	xra a
	sta werrs
	call pstg
	pop psw
	sta werrs
	ret

;
; Output a character of text to the console and/or PROGERRS.$$$ file:
;

outch:	push d
	push b
	push h
	push psw

	mov e,a		;move char to be output to E register

	lda werrs
	ora a		;if not writing errs to PROGERRS file,
	jz outch3	;	go write to console
	
	lda errsin
	ora a
	jnz outch1	;if RED buffer initialized, go handle I/O
			;else initialize RED buffer:
	inr a
	sta errsin

	push d
	lxi d,redfcb
	lda fcb
	stax d
	call delf2	;delete previous PROGERRS.$$$
	call create2	;create new one
;	call fopen2	;open for output
	lxi h,redbuf
	shld redbp	;initialize redbuf sector pointer

	lxi d,stgeri	;"RED error output initiated"
	call pstgco	;print text to console only
	pop d

outch1:	call redout	;write char to red output file

outch3:	mvi c,conout
	call bdos

	pop psw
	pop h
	pop b
	pop d
	ret

; Write a character to RED output buffer, flushing if needed:

redout:	lhld redbp	;get redbuf pointer
	mov m,e		;store char
	inx h		;bump pointer
	shld redbp	;save pointer
	mov a,l		;past end of buffer?
	cpi (redbuf+128) and 0ffh
	rnz		;if not, return



redwrt:	push d
	lxi d,redbuf	;set DMA address to redbuf for sector write
	mvi c,sdma
	call bdos

	lxi d,redfcb
	call writs2	;write sector

	lxi d,tbuff	;set DMA address back for normal file i/o
	mvi c,sdma
	call bdos

	lxi h,redbuf
	shld redbp	
	pop d
	ret
		

; Wrap up error handling, exit if there were errors:

errwrp:	call errwr1
	xra a
	sta werrs
	ret

errwr1:	lda errf	;were there any errors?
	ora a
	rz		;return if no errors

	lda werrs	;RED output enabled?
	ora a
	jz errab2	;if not, we're all done.

errwr2:	lda errsin
	ora a
	lxi h,stgie	;if errf true but RED buf not initialized,
	cz perrab	; some kind of internal error
	mvi e,1ah	;ascii end-of-file
	call redout
	lhld redbp
	mov a,l
	cpi redbuf and 0ffh	;has buffer just been flushed?
	cnz redwrt	;if not, write buffer one last time
	lxi d,redfcb
	call fclose2	;close RED output buffer
	jmp errab2


;
; Print a newline to the console:
;

crlf:	push psw
	mvi a,cr
	call outch
	mvi a,lf
	call outch
	pop psw
	ret


;
; Print out the value in HL in hex, followed by a colon
; and a space.
; Upon entry, A non-0: print no leading spaces
;	       A == 0: print leading spaces making total textual output 4 chars
;
;

prhcs:	push h
	push d
	push psw
	call prh	;convert HL to ascii at ascb
	pop psw
	ora a
	lxi h,ascb
	jz prhcs3	;if printing leading spaces, go do it

	dcx h
prhcs1:	inx h
	mov a,m
	cpi ' '
	jz prhcs1	;if all four digits, no leading spaces needed

prhcs3:	xchg		;put text ptr in DE
	call pstg
	pop d
	pop h
	ret


;
; Convert Hex value in HL to ASCII, at ASCB, followed by a colon 
; and a space. A kludgey gas-pump algorithm is used, since
; no big numbers are ever printed (only line numbers):
;


prh:	push d
	call prh00
	pop d
	ret

prh00:	push h
	lxi h,'  '
	shld ascb
	lxi h,' 0'
	shld ascb+2
	pop h
	inx h
prh0:	mov a,h
	ora l
	rz
	dcx h
	push h
	lxi h,ascb+3
prh1:	mov a,m
	cpi ' '
	jnz prh2
	mvi a,'0'
prh2:	inr a
	cpi '9'+1
	jz prh4
prh3:	mov m,a
	pop h
	jmp prh0
prh4:	mvi m,'0'
	dcx h
	jmp prh1


fopen:
	IF CPM
	lxi d,fcb

fopen2:	push d
	mvi c,openfil
	call bdos
	cpi 255
	pop d
	jz op2
	push h	;clear nr field
	lxi h,32
	dad d
	mvi m,0
	pop h
	ret
	ENDIF

	IF NOT CPM
	mvi c,m$open
	call msys
	sta marcfd
	rz
	jmp ferrab
	ENDIF

op2:	lxi d,s1
	call pstg
	jmp errab

fclose:	lxi d,fcb

	IF CPM
fclose2:
	push h
	mvi c,closefil
	call bdos
	ENDIF

	IF NOT CPM
	mvi c,m$close
	lda marcfd
	call msys
	jnz ferrab
	ENDIF

	pop h
	ret

writs:
	lxi d,fcb

	IF CPM		;write a sector under CP/M
writs2:	push h
	mvi c,wsequen
	call bdos
	pop h
	ora a
	rz
	ENDIF

	IF NOT CPM
	mvi c,m$write
	lda marcfd
	call msys
	rz
	jmp ferrab
	ENDIF

	lxi d,s2
	call pstg
	jmp errab


reads:	push h
	
	IF CPM
	lxi d,fcb
	mvi c,rsequen
	call bdos
	pop h
	ora a
	rz
	stc
	ret
	ENDIF

	IF NOT CPM
	lda marcfd
	mvi c,m$read
	lxi h,tbuff
	lxi d,128
	call msys
	jnz ferrab
	pop h
	mov a,e		;end of file?
	ora a
	rnz		;if not, return with Carry not set
	stc		;else set Carry
	ret		;and return
	ENDIF


		
delfil:
	IF CPM
	lxi d,fcb
delf2:
	push d
	push h
	lxi h,12
	dad d
	mvi m,0
	mvi c,delete
	call bdos
	pop h
	pop d
	ret
	ENDIF


create:	lxi d,fcb
create2:
	push h
	push d
	lxi h,12
	dad d
	mvi m,0
	mvi c,makfil
	call bdos
	pop d

	lxi h,32
	dad d
	mvi m,0
	pop h

	cpi 255
	rnz

	lxi d,s6
	call pstg
	jmp errab

;
; Write out the CRL file to disk:
;

writf:	lxi h,fcb+9	;make the extension "CRL"
	mvi m,'C'
	inx h
	mvi m,'R'
	inx h
	mvi m,'L'
	call delfil	;delete old versions
	call create	;create new output file

;	call fopen	;open it under CP/M; under MARC, already open...

	lhld codp
	xchg
	lhld cdao
	dad d
	xchg
	lhld dirp
	mvi m,80h
	inx h
	mov m,e
	inx h
	mov m,d
	lxi h,direc	;write out CRL directory

	IF CPM
	call copys	;(copy and write 4 sectors under CP/M)
	call writs
	call copys
	call writs
	call copys
	call writs
	call copys
	call writs
	ENDIF

	IF NOT CPM
	lxi d,512	;just write it all out under MARC (yey)
	call writs
	ENDIF

	lhld start	;now write out the code

	IF CPM
writ2:	call copys
	push psw
	call writs
	pop psw
	jnc writ2
	call fclose
	lxi h,fcb+10
	mvi m,'C'	;delete the CCI file, if it exists
	inx h
	mvi m,'I'
	ENDIF


	IF NOT CPM
	call cmh
	xchg
	lhld eofad
	dad d
	inx h		;HL is length of file to write out
	xchg
	lhld start
	call writs	;write out the CRL file in one shot (yey for MARC)
	call fclose
	ENDIF

	lda chainf
	ora a		;only attempt to delete if not chained
	cz delfil	;	to from CC1.
	ret

;
; Copy 128 bytes from mem at HL to tbuff:
;	(Return C set on EOF)
;

	IF CPM		;only need this under CP/M
copys:	lxi d,tbuff
	mvi b,80h
copy1:	mov a,m
	stax d
	push d
	xchg
	lhld eofad
	mov a,h
	cmp d
	jnz copy2
	mov a,l
	cmp e
	jz copy5
copy2:	xchg
	pop d
	inx h
	inx d
	dcr b
	jnz copy1
	xra a
	ret

copy5:	pop d
copy5a:	dcr b
	jz copy7
	inx d
	mvi a,1ah
	stax d
	jmp copy5a

copy7:	stc
	ret
	ENDIF

	IF MARC	;put this here so if the name overshoots, it'll
endnmp:	ds 2		;temporaries used in file renaming routine
dotflg:	ds 1
nambuf:	ds 40	;just write into something we don't need...
	ENDIF

;
; This routine sees if anything has been typed at the console,
; and if so, if it is a ^C then the compilation is aborted:
;

ckabrt:	push h
	push d
	push b
	push psw
	
	IF CPM
	lda conpol	;if not polling console, don't so it.
	ora a
	jz noabrt
	mvi c,intcon
	call bdos
	ora a
	jz noabrt
	mvi c,coninp
	call bdos
	cpi 3
	jnz noabrt

	lxi d,stgabo
	call pstg
	jmp errab	
	ENDIF

	IF NOT CPM
	mvi c,m$ichec
	call msys
	ENDIF

noabrt:	pop psw
	pop b
	pop d
	pop h
	ret

	IF LASM
	link cc2b
	ENDIF
