;
; CCB.ASM: Second main source file of CC.ASM
;
;	Miscellaneious utility routines,
;


;
; Delete a file:
;

	IF CPM
delfil:
	lxi d,fcb
delf2:
	push h
	push d
	lxi h,12
	dad d
	mvi m,0
	mvi c,delete
	call bdos
	pop d
	pop h
	ret
	ENDIF

;
; Create a new file:
;
create:
	IF CPM
	lxi d,fcb
create2:
	push h
	push d
	lxi h,12	;clear extent byte
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
	ENDIF

	jmp openo3

;
; Open a file for output:
;
openo:	lxi d,fcb
openo2:	call openg
	rnz

openo3:	lxi h,stg3
	jmp pstgab

	IF CPM
openg:	push h
	push d
	push d		;save fcb pointer
	mvi c,openfil
	call bdos
	pop d		;clear nr byte
	lxi h,32
	dad d
	mvi m,0
	cpi 0ffh	;return Z set on error
	pop d
	pop h
	ret
	ENDIF


;
; Close a file:
;
closef:	lxi d,fcb
close2:
	IF CPM
	push h
	mvi c,closefil
	call bdos
	pop h
	cpi 255
	rnz
	lxi h,stg2
	jmp pstgab
	ENDIF


;
; Write a sector of a file out to disk:
;

	IF CPM
writs:	lxi d,fcb
writs2:	push h
	mvi c,wsequen
	call bdos
	pop h
	ora a
	rz
	lxi h,stg3
	jmp pstgab

;
; Copy 128 bytes from mem at (HL) to tbuff (80h), pad last sector
; with ^Z's if CPYEND reached and return Cy set if so:
;


copys:	lxi d,tbuff
	mvi b,80h

copy1:	mov a,m
	stax d
	push d
	xchg
	lhld cpyend
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
copy6:	dcr b
	jz copy7
	mvi a,1ah
	stax d
	inx d
	jmp copy6

copy7:	stc
	ret
	ENDIF		;end of CP/M-dependent file I/O


;
; Bump line count:
;

bumpnl:	push h
	lhld nlcnt
	inx h
	shld nlcnt
	pop h
	ret


;
; print out file name in default fcb:
;

pfnam:	push d
	lxi d,fcb
	call pfnam2
	pop d
	ret

;
; Print out filename of fcb at DE:
;


pfnam2:	push d
	push h
	push b
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
	pop h
	pop d
	ret

pnseg:	ldax d
	cpi ' '
	cnz outch
	inx d
	dcr b
	jnz pnseg
	ret

;
; Print out the value in HL in hex, followed by a colon
; and a space.
; Upon entry, A non-0: print no leading spaces
;	       A == 0: print leading spaces making total textual output 4 chars
;
;

prhcs:	push psw
	push d
	call prh	;convert HL to ascii at ascb
	pop d
	pop psw
	ora a
	lxi h,ascb
	jz prhcs3	;if printing leading spaces, go do it
	dcx h
prhcs1:	inx h
	mov a,m
	cpi ' '
	jz prhcs1	;if all four digits, no leading spaces needed

prhcs3:	call pstg
	ret

;
; Print A in ASCII followed by a slash
;

prads:	ani 1fh		;max 31
	call pra
	mvi a,'/'
	call outch
	ret

pra:	cpi 10		;single digit?
	jnc pra2	;if not, go handle double digits
pra0:	adi '0'		;print single digit in A
pra1:	call outch
	ret
pra2:	mvi b,0		;calculate 10's digit
pra3:	inr b
	sui 10
	cpi 10
	jnc pra3
	push psw
	mov a,b
	call pra0	;print tens digit
	pop psw
	jmp pra0

;
; Convert value in HL into ASCII at ascb, ascb+1, ascb+2, ascb+3:
;

prh:	push h
	lxi h,'  '
	shld ascb
	lxi h,' 0'	;mac doc. is wrong about this!
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


;
; 2's complement HL:
;

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


;
; "Ignore stuff" routine; pass by newlines, white space,
; module start and end bookkeeping, and keep the lines count
; (stored in nlcnt) for error reporting:
;

igsht:	ldax d
	cpi modbeg	;begin nested module?
	jnz igsh0

	inx d
	call pushmn	;push on modstk, process line number stuff
	jmp igsht

igsh0:	cpi modend
	jnz igsh1	;include file end?
	call popmn	;restore line number and pop filename off modstk
	jmp igsh1a

igsh1:	cpi 0ffh
	jnz igsh2

igsh1a:	inx d
	jmp igsht

igsh2:	cpi nlcd
	jnz igsh3
	call bumpnl
	inx d
	jmp igsht

igsh3:	ora a
	ret

;
; Push filename at DE onto modstk, save current line number after it,
; bump modstc, and reset nlcnt:
;

pushmn:	push h		;save HL
	lxi h,modstc	;bump modstc
	inr m
	mov a,m
	cpi 6
	lxi h,stgine
	cnc perrab		

	lhld modstp	;get next mod stack entry slot address
	mvi b,12
	call movrc	;push new module name onto modstk
	push d		;save text ptr
	xchg
	lhld nlcnt	;get line count
	xchg		;line count in DE, modstk ptr in HL
	mov m,e
	inx h
	mov m,d
	inx h
	shld modstp
	lxi h,0
	shld nlcnt	;clear nlcnt for new module
	pop d		;restore text pointer
	pop h		;restore HL
	ret	

;
; Pop modstk entry:
;

popmn:	push h		;save registers
	push d
	lhld modstp
	dcx h
	mov d,m
	dcx h
	mov e,m		;DE holds old nlcnt
	xchg
	shld nlcnt	;restore line count
	lxi h,-12
	dad d		;roll modstk pointer back to start of current level
	shld modstp	;save modstk pointer
	lxi h,modstc	;debump module count
	dcr m
	pop d
	pop h
	ret

movrc:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz movrc
	ret

;
; General purpose ram move routine. 
; B = byte count
; C controls direction of move:
;	0: DE->HL, 1: HL->DE
;

movram:	mov a,c
	ora a
	jz movr2
	xchg
movr2:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz movr2
	mov a,c
	ora a
	jz movr3
	xchg
movr3:	push d		;make sure we don't overflow stack area
	push h
	lhld coda
	xchg		;put code area addr in DE
	pop h		;and current include stack pointer in HL
	call cmphd
	pop d		;restore sp
	rc		;if OK, return
	lxi h,stgine	;include error
	jmp pstgab	;print message and quit

;
; Map alphabetic character in A to upper case:
;

mapuc:	cpi 61h
	rc
	cpi 7bh
	rnc
	sui 20h
	ret

;
; Special version of mapuc,  which supresses mapping if "mapucv" is true
;

mapuc0:	push b		;save B
	mov b,a		;save char to map in B
	lda mapucv	;get control var
	ora a		;do we do a mapping?
	mov a,b		;get back char to map in A
	cz mapuc	;if we do a mapping, go do it
	pop b		;restore B
	ret		;all done

	
;
; Print out line number, error message in HL, and set errf so
; we don't auto-load cc2:
;

perr:	push psw
	call pwarn
	mvi a,1
	sta errf
	pop psw
	ret

;
; Print out line number, error message in HL, but don't touch
; errf:
;

pwarn:	push h
	call pmodnc	;print module name
perr2:	lhld nlcnt
	call prhcs	;print line number of error
	pop h
	call pstg
	ret

;
; Print module name, colon, space:
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
; Print out module name:
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
; Print out string pointed to by HL, with + character shorthand
; for a CR-LF:
;

pstg:	mov a,m
	ora a
	rz
	cpi '+'
	jz crlf
	call outch
	inx h
	jmp pstg

;
; Print strig to console only:
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
	mov e,a

	lda werrs
	ora a		;if not writing errs to PROGERRS file,
	jz outch3	;	go write to console
	
	lda nomore	;if done writing RED errors, just go to console
	ora a
	jnz outch3

	lda errsin
	ora a
	jnz outch1	;if RED buffer initialized, go handle I/O
			;else initialize RED buffer:
	inr a
	sta errsin

	push d
	lxi d,redfcb
	lda odisk
	stax d
	call delf2	;delete previous PROGERRS.$$$
	call create2	;create new one
;	call openo2	;open for output
	lxi h,redbuf
	shld redbp	;initialize redbuf sector pointer

	lxi h,stgeri	;"RED error output initiated"
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


;
; print "undeclared variable: " and print out the
; variable name being pointed to by DE:
;

bvarm:	lxi h,stg14
bvarm2:	call perr
	push d
	call pvarn	;print out the name
	pop d
	call crlf
	ret

;
; print out the variable name pointed to by DE:
;

pvarn:	ldax d
	call varch
	rc
	call outch
	inx d
	jmp pvarn

;
; Print error message in HL and abort:
;

pstgab:
pstgb2:	call pstg
	jmp errab

;
; Print error msg in HL with line number, and abort:
;

perrab:	call perr

;
; Come here to abort, when fatal error has been diagnosed:
;

errab:	lhld errbyt	;set error byte flag for ZCPR3
	mvi m,0ffh

	call errwrp	;wrap up any RED file activity

errab2:	mvi a,7		;ring a bell for errors having occurred
	call outch
	lda erasub	;bother to erase submit files?
	ora a
	jz exit

	mvi e,0		;go to user 0 for submit file erasure
	mvi c,sguser

	IF NOT ALPHA
	lda nouser
	ora a
	jnz errab3	;if no user areas, don't do it

	lda zenvf	;if not ZSYSTEMS, don't do it
	ora a
	cnz bdos
errab3:
	ENDIF

	lxi d,subfile	;erase pending submit files and abort
	call delf2

exit:	call resetu	;reset to original user drive/ user area

	lda wboote	;need to perform warm-boot?
	ora a
	jnz ram		;if so, go do it.
	lhld spsav	;get (possibly valid) saved stack pointer
	sphl		;put into SP
	lda ccpok	;CCP intact?
	ora a
	rnz		;if so, return to CCP
	jmp ram		;otherwise do a warm boot

resetu:	lda origdsk	;reset disk and user area to original
	mov e,a
	mvi c,select
	call bdos
	lda origusr
	mov e,a
	mvi c,sguser

	IF NOT ALPHA
	lda nouser
	ora a
	cz bdos	
	ENDIF

	ret



;
; Print a newline to the console:
;

crlf:	push psw

	IF CPM
	mvi a,cr
	call outch
	ENDIF

	mvi a,lf
	call outch
	pop psw
	ret

;
; Check for abortion:
;

ckabrt:
	push h
	push d
	push b
	push psw

	lda conpol	;are we polling the console?
	ora a
	jz nohit	;if not, don't do anything

	mvi c,intcon	;interrogate console status
	call bdos
	ora a
	jz nohit
	mvi c,coninp
	call bdos	;if something hit, see if a ^C
	cpi 3
	jz intrpt	
nohit:	pop psw		;if not, don't interrupt
	pop b
	pop d
	pop h
	ret

intrpt:	lxi h,stgabo	; and abort.
	jmp pstgab
	
;
; Check for stack overflow:
;

chkstk:	push h
	push d
	push b
	push psw
	lhld stkchk
	lxi d,0a55ah
	call cmphd	;make sure stack check word is still intact
	jz nohit	;if so, no problem
	lxi h,stgstk	;else spew stack overflow message
	jmp perrab


;
; Squeeze the symbol table by chopping out the name portion of every entry
; (reducing the st size by half, since each entry up to now has been
; 8 chars of name and 8 bytes of attributes):
;

chopst:	lhld stno
	mov b,h
	mov c,l		;BC = symbol entry count
	lxi h,st
	lxi d,st

sqst2:	mov a,b
	ora c
	jnz sqst3
	shld stp
	ret

sqst3:	push h
	lxi h,8
	dad d
	xchg
	pop h

sqst4:	ldax d
	mov m,a
	inx d
	inx h
	mov a,l
	ani 7
	jnz sqst4
	dcx b
	jmp sqst2

;
; Write out special CCI-symbol-table file for Kirkland's debugger if "-w"
; option given...write out stno entries from symbol table at st, each
; 16 bytes long. Call the file <name>.CDB ... this is gonna be a neat hack!
;

wst4db:	lda kflg	;was -w even given?
	ora a		;if not, return
	rz

	lxi h,st	;get size of symbol table in HL
	call cmh
	xchg
	lhld stp	;get symbol table next free slot pointer
	shld cpyend	;this is where we'll stop writing to the output file.
	dad d
	shld st-2	;put symbol table size in place

	IF CPM
	lxi h,fcb+9
	mvi m,'C'
	inx h
	mvi m,'D'
	inx h
	mvi m,'B'
	lda odisk	;set output disk designation
	sta fcb
	call delfil	;delete old versions
	call create	;create output file
;	call openo	;and open it for output

	lxi h,st-2
wstdb2:	call copys
	push psw
	call writs
	pop psw
	jnc wstdb2
	call closef	;close the output file.
	ENDIF

	ret


;
; Little general purpose utility to compare HL and DE,
; and return C set if HL < DE
;

cmphd:	mov a,h
	cmp d
	rnz
	mov a,l
	cmp e
	ret


;
; Routine to make sure we haven't overflowed available memory space. At
; first, we try to use memory below the command processor (under both
; CP/M and MARC). If we run out of room, we either punt the CCP under
; CP/M or do the maxmem call under MARC to get more memory.
;

ckov:	push h
	push d
ckov0:	lda curtop+1	;high order byte of top of mem addr
	dcr a
	mov d,a
	mov a,h
	cmp d
	jc ckovok	;overflow?

	IF CPM
	lda ccpok	;under CP/M, is the CCP still intact?
	ora a
	jnz ckov1	;if so, go try for more memory
	ENDIF

	lxi h,stgov	;We've used all we can...it's all over now.
	jmp pstgab

ckov1:
	IF CPM
	push h
	lhld bdosp	;change curtop to reflect BDOS address now
	mvi l,0		;zero out low order byte
	shld curtop
	pop h
	xra a		;and tell that the CCP is now defunct
	sta ccpok
	jmp ckov0
	ENDIF	


ckovok:	pop d
	pop h
	ret



;
; The following function is hairy. It forms the core hack of the BDS C
; parsing algorithm: it moves expands and compacts text at the current
; text pointer location (DE), where A upon entry is negative to EXPAND
; by -(A), positive to squeeze by A, or zero to do nothing.
;
; This is getting documented approximately 3 1/2 years after being written.
; It's been one HELL of a WIERD three and a half years!!!!!!!!!!
;

TESTM:	EQU 0


mvtxt:	ora a		;check for zero
	rz		;return if so
	jp sqish	;if positive, go squish

	cma		;otherwise negate
	inr a

	push h		;save registers
	push b
	push d
	push psw

	ldax d
	cpi 0ffh
	jnz mvtxt1

	pop psw
	cpi 1
	jnz mvtxt0
	pop d
	pop b
	pop h
	ret

mvtxt0:	pop d
	pop b
	pop h
	inx d
	dcr a
	cma
	inr a
	call mvtxt
	dcx d
	ret

	IF TESTM

	call tstriv	;see if expansion is all into filler bytes...
	jnz mvtxt1	;if not, go do standard expansion

	pop psw		;if so, we don't need to do anything,
	pop d		;so pop registers and return.
	pop b
	pop h
	ret

;
; Returns Z set if there are at least (A) FF bytes at (DE). 
; Preserves DE but not necessarily A:
;

tstriv:	push d		;save text pointer
tstrv2:	ldax d		;text for FF
	cpi 0FFh
	jnz tstrv3	;if not, trivial test fails.
	inx d		;else bump text pointer to next char
	dcr a		;and test for completion
	jnz tstrv2	;if haven't found enough, go on looking
			;otherwise we found enough--success!
tstrv3:	pop d
	ret
	ENDIF


mvtxt1:	pop psw
	sta mvtmp
	jmp fndff

mvtxt2:	lda mvtmp
	mov h,d
	mov l,e
	dcx d

mvtxt3:	push psw
	ldax d
	mov m,a
	pop psw
	pop b
	push psw
	mov a,c
	cmp e
	jnz mvtxt5
	mov a,b
	cmp d
	jnz mvtxt5
	pop psw
	dcr a
	jnz mvtxt6
	pop b
	pop h
	ret

mvtxt5:	pop psw
	push b
	dcx h

mvtxt6:	dcx d
	jmp mvtxt3


fndff:	mov c,a
	sta fndtmp
	mvi b,7
	ldax d
	ora a
	jnz fff0
	mvi a,1
	call expnd
	inx d

fff0:	ldax d
	ora a
	jz fff2
	cpi 0ffh
	jnz fff1
fff0b:	inx d
	ldax d
	cpi 0ffh
	dcx d	
	ldax d
	jnz fff1
	dcr c
	jz mvtxt2

	mvi b,7
	push d
fff0a:	inx d
	jmp fff0

fff1:	cpi nlcd
	jz fff1a
	cpi cr
	jnz fff4
fff1a:	dcx d
	cpi '\'
	inx d
	jz fff4
	dcx d
	dcx d
	ldax d
	inx d
	inx d
	cpi '\'
	jz fff4
	dcr b
	jnz fff0a
	mvi b,7
	inx d
	ldax d
	cpi 0ffh
	jz fff0b

fff2:	mov a,c
	adi 40
	call expnd

fff3:	dcr c
	jz mvtxt2
	push d
	inx d
	jmp fff3

fff4:	ldax d
	cpi swtbc
	jnz fff5
	inx d
	ldax d
	mov l,a
	mvi h,0
	dad h
	dad h
	inx h
	inx h
	inx d
	dad d
	xchg
	jmp fff0

fff5:	call cdtst
	jc fff6
	inx d
	inx d
	jmp fff0a

fff6:	cpi modbeg
	jnz fff0a
	lxi h,14
	dad d
	xchg
	jmp fff0

sqish:	push b
	mov b,a
	mvi a,0ffh
sqish2:	stax d
	inx d
	dcr b
	jnz sqish2
	pop b
	ret


expnd:	push h
	push b
	push psw
	push d
	lhld eofad
	mov b,h
	mov c,l
	mov e,a
	mvi d,0
	dad d
	push h
	push b
	shld eofad
	mov b,h
	mov c,l
	lhld meofad
	call max
	shld meofad
	pop b
	pop h
	call ckov
	pop d

expnd1:	call mvbhd
	pop psw
	mov b,a
	push d
expnd4:	mvi a,0ffh
	stax d
	inx d
	dcr b
	jnz expnd4
	pop d
	pop b
	pop h
	ret


;
; Routine to move stuff from (BC) to (HL), decrementing both
; as we go, until BC passes DE -- doing it by block move if possible
; (if runnign a Z80), or by brute force if on an 8080 or 8085.
; Clobbers BC and HL.
;

mvbhd:	lda z80f	;z80?
	ora a
	jz mvbhdl	;if not, do it the long way

	push d
	push h	
	xchg
	call cmh
	dad b
	inx h
	push h
	mov h,b
	mov l,c
	pop b
	pop d
	db 0edh,0b8h	;ldir instuction
	pop d
	ret


mvbhdl:	ldax b		;do it the long way
	mov m,a
	mov a,c
	cmp e
	jnz mvbhd2
	mov a,b
	cmp d
	rz
mvbhd2:	dcx h
	dcx b
	jmp mvbhd


;
; Return Cy true if byte in A is a code byte:
;

cdtst:	cpi concd
	rc
	cpi strcd+1
	cmc
	ret

;
; Purge FF's and related garbage/filler bytes from text:
;

fixt:	lhld coda	;HL is source pointer
	mov d,h		;DE is dest pointer
	mov e,l

fix0:	mov a,m		;end of code?
	ora a
	jnz fix2

	stax d		;yes. handle strings.
	inx d
	inx h
fix1:	mov a,m
	cpi 1ah		;end of strings?
	jnz fix1a	;if not, still doing strings.
	stax d		;yes.
	xchg
	shld eofad
	ret

fix1a:  mvi b,3		;handle string storage.
	call movb
	mov b,a
	call movb
	jmp fix1

fix2:	call cdtst	;three byte code?
	jc fix4
	mvi b,3
	call movb
	jmp fix0

fix4:	cpi 0ffh	;garbage byte?
	jnz fix5
	inx h		;yes. skip it.
	jmp fix0

fix5:	cpi swtbc	;switch statement?
	jnz fix8

	stax d		;yes.
	inx d
	inx h
fix6:	mov a,m
	cpi 0ffh
	jnz fix7
	inx h
	jmp fix6
fix7:	push h
	mov l,a
	mvi h,0
	dad h
	dad h
	inx h
	inx h
	inx h
	mov b,h
	mov c,l
	pop h
	call mvmd
	jmp fix0

fix8:	cpi modbeg	;start of module?
	jnz fix10
	mvi b,12	;yes. copy module name
	call movb
	jmp fix0

fix10:	stax d
	inx h
	inx d
	jmp fix0


fix11:	lxi h,oshit
	call pstgab

movb:	inr b
movb2:	dcr b
	rz
	mov a,m
	stax d
	inx h
	inx d
	jmp movb2



mvmd:	lda z80f
	ora a
	jz mvmdl	;if on 8080, can't use block move
	db 0edh,0b0h	;else can
	ret

mvmdl:	mov a,m		;do it the hard way for 8080
	stax d
	inx h
	inx d
	dcx b
	mov a,b
	ora c
	jnz mvmd
	ret


pascd:	call igsht
	rz
	call cdtst
	jnc pscd2
	xra a
	inr a
	ldax d
	ret

pscd2:	inx d
	inx d
	inx d
	jmp pascd


fsemi:	mvi a,semi


;
; Find next occurence of the character passed in A:
;

findc:	mov b,a
findc1:	ldax d
	cmp b
	rz
	ora a
	jnz finc2
	lxi h,stg10
	jmp fatal

finc2:	cpi nlcd
	jnz finc3
	call bumpnl

finc3:	inx d
	call cdtst
	jc finc4
	inx d
	inx d
	jmp findc1

finc4:	push psw
	lda eradf
	ora a
	jnz finc5
	pop psw
	jmp findc1

finc5:	pop psw
	cpi 80h
	jc findc1	;if no control keyword found, no problem
	cpi 9dh
	jnc findc1

	cpi 8fh		;special case of a keyword allowed in
	jz findc1	;an expression: sizeof

	lhld nlcnt	;else error...probably missing semicolon
	push h
	lhld errad
	shld nlcnt
	lxi h,stg25
	call perr
	pop h
	shld nlcnt
	dcx d
	dcx d
	mvi a,semi
	stax d
	ret

;
; New routine that expects to see a semicolon as
; the first non-trivial item in text; else error given.
;

esemi:	call igsht
	cpi semi	;next thing a semi?
	rz		;if so, OK-- else insert one.

insrts:	lhld nlcnt	;save real line count
	push h
	lhld esadr	;get fake count
	shld nlcnt
	lxi h,stg25
	call perr	;print error
	pop h
	shld nlcnt
	mvi a,negone	;make room for automatic semi
	call mvtxt
	mvi a,semi	;just to aid diagnosing later errors
	stax d
	ret


tstty:	cpi chrcd
	rc
	cpi gotcd
	cmc
	ret


;
; Return Cy false if character in A is legal anywhere in an identifier name:
;

varch:	call varch2
	rnc
	cpi '0'
	rc
	cpi '9'+1
	cmc
	ret

;
; Return Cy false if char in A is legal as FIRST char in an identifier name:
;

varch2:	cpi 'A'
	rc
	cpi 'Z'+1
	cmc
	rnc
	cpi 5fh
	rz
	cpi 61h
	rc
	cpi 7bh
	cmc
	ret


;
; Advance text pointer past identifier at DE:
;

pasvr:	call igsht
psvr2:	call varch
	jnc psvr3
	call igsht
	ret

psvr3:	inx d
	ldax d
	jmp psvr2


;
; Advance text pointer past parentheses at DE:

mtchp:	push h
	call mtchp1
	pop h
	ret

mtchp1:	call igsht
	cpi open
	jz mtchq
	lxi h,stg40
	call perr
	call fsemi
	ret

mtchq:	lhld nlcnt
	shld mtpln

mtchpa:	inx d
mtchpb:	call pascd
	jnz mtchpc
mtchpe:	lhld mtpln
	shld nlcnt
	lxi h,stgbp
	jmp fatal

mtchpc:	cpi close
	jnz mtp2
	push h		;save line count for error diagnostics
	lhld nlcnt
	shld esadr
	pop h
	inx d
	call igsht
	ret

mtp2:	cpi semi	;allow semicolons in parentheses only
	jnz mtp3	;if semiok is non-zero.
	lda semiok
	ora a
	jz mtchpe
	jmp mtchpa

mtp3:	cpi open
	jnz mtchpa
	call mtchpa
	jmp mtchpb

;
; Install identifier at DE in symbol table position given in HL:
;

instt:	push d
	push d
	lhld stp
	push h
	lxi d,16
	dad d
	lda coda+1
	mov b,a
	mov a,h
	cmp b
	jc instta
instt0:	lxi h,stgom
	lda preflag
	ora a
	jz fatal
	jmp pstgab

instta:	pop h
	pop d
	mvi c,0
inst2:	ldax d
	mov m,a
	inr c
	inx h
	inx d
	ldax d
	call varch
	jc inst4
	mov a,c
	cpi 8
	jc inst2

inst3:	inx d
	inr c
	ldax d
	call varch
	jnc inst3

inst4:	dcx h
	mov a,m
	ori 80h
	mov m,a
	inx h
	mvi a,8
	sub c
	mov e,a
	mvi d,0
	jc inst5
	dad d
inst5:	shld tempd
	pop d
	ret



cvtst:	push d
	dad h
	dad h
	dad h
	dad h
	xchg
	lxi h,st
	dad d
	lxi d,8
	dad d
	pop d
	mov a,m
	ret

finds:	lda clev
	sta flev
	call fs
	rnc
	xra a
	sta flev


fs:	lhld stno
	mov b,h
	mov c,l
	lxi h,st

fs2:	mov a,b
	ora c
	jnz fs3
	stc
	ret

fs3:	push d
	push b
	call idcmp
	jz fs4
	lxi d,16
fs3a:	dad d
	pop b
	pop d
	dcx b
	jmp fs2

fs4:	dcx h
	mov a,l
	ani 0f8h
	mov l,a
	lxi d,9
	dad d
	shld inadsv
	mov a,m
	ani 3fh
	mov d,a
	lda flev
	cmp d
	jz fs5
	lxi d,7
	jmp fs3a

fs5:	pop h
	call cmh
	xchg
	lhld stno
	dad d
	pop d
	xra a
	ret

initst:	lhld stsiz
	mov b,h
	mov c,l
	lxi h,st
inits1:	mvi m,0
	inx h
	dcx b
	mov a,b
	ora c	
	jnz inits1
	ret

;
; compare the symbol table entry at HL with the text identifier 
; at DE:
;

idcmp:	push d
	push h
	mvi c,1		;initialize char count
idcmp2:	mov a,m
	ani 7fh		;strip end-of-text bit from char of st entry
	mov b,a		;put it in B.
	ldax d		;get a character from text.
	cmp b		;same?
	jz idcmp3	;if so, go check rest of identifier
idcp2a:	pop h		;else no match.
	pop d
	xra a		;clear zero flag
	inr a		;by incrementing from zero,
	stc		;and also set the carry flag.
	ret

idcmp3:	mov a,m		;ok, so far it matches.
	ora a		;was it the last char of the st entry?
	inx h
	jm idcmp4	;jump if it was
	inx d		;it wasn't. bump text pointer, char count,
	inr c
	jmp idcmp2	;and go look at next charcter

idcmp4:	mov a,c		;end of symbol. if we've already seen 8 characters,
	cpi 8		;ignore rest of symbol at DE (insignificant chars)
	jz idcmp5	
	inx d		;haven't seen 8 chars yet...is next char of text
	ldax d		;a legal identifier character?
	call varch
	jnc idcp2a	;if so, no match.

idcp4a:	xra a		;we have a match. set Z.
	pop d
	pop d
	ret

idcmp5:	inx d		;come here to pass over superfluous chars of text
	ldax d
	call varch
	jc idcp4a
	inr c		;making sure to bump the char count in C as we go.
	jmp idcmp5


;
; Make function name table:
;

mkfnt:	lhld stp
	shld fnts
	shld fntp
	lhld stno
	mov b,h
	mov c,l
	lxi h,st+8

mkft1:	mov a,b
	ora c
	jnz mkft2	;done?
	lhld fntp	;yes. make sure we haven't overflowed	
	xchg		;the symbol table
	lhld coda
	call cmphd	;return C if code area < end of func name table
	rnc
	lxi h,stgom	;list too long. complain and abort
	jmp pstgab

mkft2:	mov a,m
	rar
	push h
	push b
	cc mkft3
	pop b
	pop h
	lxi d,16
	dad d
	dcx b
	jmp mkft1

mkft3:	lxi d,-8
	dad d
	push h
	mov h,b
	mov l,c
	call cmh
	xchg
	lhld stno
	dad d
	xchg
	lhld fntp
	mov m,e
	inx h
	mov m,d
	inx h
	pop d

mkft4:	ldax d
	mov m,a
	inx d
	inx h
	ora a
	jp mkft4
	shld fntp
	ret

mvfnt:	lhld fnts
	call cmh
	xchg
	lhld fntp
	dad d
	shld st-2
	mov b,h
	mov c,l
	lhld fnts
	xchg
	lhld stp

mvft1:	mov a,b
	ora c
	jz mvft2
	ldax d
	mov m,a
	inx h
	inx d
	dcx b
	jmp mvft1

mvft2:	shld fntp
	ret

;
; Perform "big expansion" of text:
; 

bexp:	xchg
	call cmh
	mov b,h
	mov c,l
	lhld eofad
	push h
	push h
	dad b
	mov b,h
	mov c,l
	pop h
	inx b
	dad d
	shld eofad
	call ckov
	pop d

bexp1:	mov a,b
	ora c
	jz bexp2
	ldax d
	mov m,a
	dcx h
	dcx b
	dcx d
	jmp bexp1

bexp2:	inx d
	ret

;
; Either write CCI file to disk (if -az given, CP/M only) or auto-load
; into CC2:
;

writf:	lhld extsa	;put externals size word in place
	shld st-6

	lxi h,st	;get size of symbol table in HL
	call cmh
	xchg
	lhld stp
	dad d
	shld st-4	;put symbol table size in place

	lhld eofad	;now copy tokenized code down to just past the
	mov b,h		;end of the symbol table
	mov c,l
	lhld coda
	xchg
	lhld fntp
                
writ1:	ldax d
	mov m,a
	inx h
	inx d
	mov a,e
	cmp c
	jnz writ1
	mov a,d
	cmp b
	jnz writ1
	shld eofad

	IF CPM
	lda chainf
	ora a
	jnz chain
	ENDIF

	IF NOT CPM
	jmp chain
	ENDIF

	IF CPM
writ1a:	lxi h,fcb+9
	mvi m,'C'
	inx h
	mvi m,'C'
	inx h
	mvi m,'I'
	lda odisk	;set output disk designation
	sta fcb
	call delfil
	call create	;create output file
	lhld eofad	;copy till end of all data
	shld cpyend

	lxi h,st-6
writ2:	call copys
	push psw
	call writs
	pop psw
	jnc writ2
	call closef	;close the output file.
	ret
	ENDIF


chain:
	lda cc2dsk	;get default cc2 disk
	sta cfcb	;set as first byte of fcb

	IF NOT ALPHA
	lda nouser	;don't futz with user areas?
	ora a
	jnz chain0	;if not, skip chaning user area

	lda cc2usr	;get cc2 default user area
	mov e,a

	mvi c,sguser
	call bdos	;change to that user area
	ENDIF

chain0:	call occ2	;try to open in default user area and disk

	push psw	;save condition
	lda curdsk	;switch back to current disk and user area
	inr a
	sta cfcb

	IF NOT ALPHA
	lda nouser
	ora a
	jnz chain1

	lda curusr	;change back to current user area
	mov e,a

	mvi c,sguser
	call bdos
	ENDIF

chain1:	pop psw		;get back condition of first cc2 open attempt
	jnz ch3		;go read in if prior open succeeded

	call occ2	;else try to read in current disk and user area...
	jnz ch3		;if ok, go read

	jmp cc2bad	;else give up

occ2:	lhld curtop
	push h		;try to open cc2
	lxi d,-33
	dad d
	push h
	lxi d,cfcb
	mvi b,16
ch2:	ldax d
	mov m,a
	inx h	
	inx d
	dcr b
	jnz ch2
	pop d
	mvi c,openfil
	call bdos	;try to open cc2.com
	pop h
	dcx h
	mvi m,0		;clear nr field of CC2 fcb
	cpi 255		;cc2 on disk?
	ret

cc2bad:	lxi h,stgcce	;nope. complain and write out cci file

	call pstg
	jmp writ1a

ch3:	
	call movef	;move schlameel to high ram
	lxi h,tbuff	;move bootstrap to tbuff (== just 80h under MARC)
	lxi d,bootcode
	mvi b,bootlen
ch4:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz ch4

;
; Now set up stack at ram area, and push all data that will have to
; be popped back into cc2. The order of pushing, and resulting address
; in cc2, are as follows:
;
;	no.	item	address in cc2
;	---	----	--------------
;	0	kflg	110h
;	1	odisk	5fh		(CP/M only)
;	2	optimf	104h
;	3	loadad	105h-106h
;	4	eflag	109h
;	5	exaddr	107h-108h
;	6	curtop	10ch-10dh
;	7	ccpok	10eh		(ccpok: b0, oktort: b1, wboote b2,
;						zenvf: b3)
;		maxmd	10eh		(MARC only)
;	8	spsav	10ah-10bh	(CP/M only)
;		fnam	10ah-10bh	(MARC only)
;	9	erasub	10fh		(CP/M only)
;	10	defsub/	111h-112h	(CP/M only)
;		conpol
;	11	errbyt	113h-114h	(CP/M only)
;	
; The bootstrap pops these in the reverse order, or course, and sets
; them up in the newly-loaded in cc2.com file.
;

	lxi sp,tpa
	lda kflg	;save CDB flag
	push psw
	lda odisk	;save output disk flag
	push psw
	lda optim	;save optimization flag
	push psw
	lhld loadad	;save load address
	push h
	lda eflag	;save external addr given flag
	push psw
	lhld exaddr	;save external address if given
	push h
	lhld curtop	;save current top of memory
	push h

	IF CPM
	lda ccpok	;save CCP intact flag
	ora a
	jz bt000
	mvi a,1		;set b0 to ccpok
bt000:	mov b,a		;save in B

	lda oktort	;get oktoret flag
	add a		;put bit in b1 position
	add b		;accumulate
	mov b,a		;save it

	lda wboote	;set b2 to wboote
	ora a
	jz bt001
	mvi a,4		;if true, make b2 hi
bt001:	add b

	lda zenvf
	ora a
	jz bt002
	mvi a,8		;set b3
bt002:	add b

	push psw	;save combination of (b0 b1 b2 b3)

	lhld spsav	;save CCP's stack pointer
	push h

	lda werrs	;if werrs false, just push erasub
	ora a
	lda erasub
	jz setbt1
	ori 2		;if werrs true, but b1 high on erasub
	
setbt1:	push psw
	lhld defsub	;save defsub/conpol bytes
	push h
	lhld errbyt	;get ZCPR3 error byte address
	push h

	lhld curtop	;put fcb address of cc2 fcb in BC
	lxi d,-33
	dad d
	mov b,h
	mov c,l
	ENDIF

	jmp tbuff	;go do it

;
; This is the bootstrap that will run down at tbuff:
;

bootcode:
	IF CPM		;first the CP/M version...
	lxi d,tpa	;(cp/m only code is: 35 bytes)
	push d		;save memory load address pointer
	push b		;save cc2's fcb address
	mvi c,sdma	;set DMA address to current memory load address (DE)
	call bdos
	pop d		;pop cc2's fcb address into DE
	push d		;and push back on stack for later
	mvi c,rsequen	;read a sector
	call bdos
	ora a
	pop b		;pop cc2's fcb address into BC
	pop d		;pop memory load address
	jnz postld	;if done, go finish up
	lxi h,80h	;otherwise add 80h to memory load address
	dad d
	xchg		;and put it back in DE
	jmp tbuff+3
	ENDIF

;
; pop stuff off stack for CC2:
;

postld:  equ tbuff + $ - bootcode
	IF CPM
	pop h		;get back wboote flag + extra byte
	shld ram+113h
	pop h		;get back defsub and conpol bytes
	shld ram+111h
	pop psw		;get back erasing submit files flag
	sta ram+10fh
	ENDIF

	pop h		;pop filename under MARC or saved SP under CP/M
	shld ram+010ah	

	pop psw		;pop ccpok/maxmd flag
	sta ram+010eh

	pop h		;pop current top of memory address
	shld ram+010ch

	pop h		;pop external variables address
	shld ram+0107h
	pop psw		;pop external address flag
	sta ram+0109h

	pop h		;pop load address
	shld ram+0105h
	pop psw		;pop optimization flag
	sta ram+0104h
	pop psw		;pop output disk designation flag

	IF CPM
	sta fcb		;set output disk designation
	ENDIF

	pop psw		;pop CDB flag
	sta ram+110h

	mvi a,1
	sta ram+103h	;set chained-to flag
	jmp tpa		;and go execute

bootlen: equ $-bootcode	;length of bootstrap

;
; (end of bootstrap)
;




movef:	lxi d,-(st-6)
	lhld eofad
	dad d		
	inx h
	xchg		;DE = length of text
	lhld curtop
	lxi b,-36
	dad b
	mov b,h
	mov c,l		;BC = destination
	push b		;save for later
	lhld eofad	;HL = source
movef1:	mov a,m
	stax b
	dcx b
	dcx h
	dcx d
	mov a,d
	ora e
	jnz movef1
	pop h		;get addr of where start addr goes
	inx h		;now HL = BDOS - 35
	mov m,c
	inx h		;and BDOS - 34
	mov m,b
	ret		;and all done!


	IF LASM
	link ccc
	ENDIF
