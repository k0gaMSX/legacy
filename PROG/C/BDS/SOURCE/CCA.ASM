;
; CC1: the first pass of the C compiler...
; MARC-generalized  version
;
; 7/17/82: added -w to write debugger info file and insert restarts
; 7/18/82: changed -w to -k<n>  (for Kirkland), taking n as the restart
; 	   vector to use (1-7), defaults to 6.
; 8/22/82: Fixed mvtxt to not overflow stack in recursion
; 9/9/82:  Added search path mechanism to cc2.com auto-load, made FF def.
;	   disk and user use "current" as default
; 10/6/82: added auto-".c" on main file feature
; 11/85:   Added -z option to use RST 1 - RST 5 for value-fetch optimization
; 12/85:   Added RED logic to write out PROGERRS.$$$ error file
; 
;

	IF NOT LASM AND NOT SLRMAC
	maclib cc
	ENDIF

	org tpa		;start of CP/M TPA

 	jmp cc1		
 
 	db cr,lf
 	db 'Copyright (c) 1982, 83, 84 by Leor Zolman'
 	db cr,lf,lf
 	db 'Please don''t rip me off.'
 	db cr,lf,lf,1ah
patch0:	db 0,0,0,0,0,0,0,0 		;space to expand message

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;	Configuration block area:
	;

defdsk:	db 0ffh		;default library disk drive
defusr: db 0ffh		;default library user area

defsub:	db 00h		;default disk to find submit file on
conpol:	db 1		;true to poll the console for interrupts
wboote:	db 0		;true to always do warm-boot on exit
;zenvf:	ds 1		;true if Z environment
;			;new for v1.51:
pstrip: db 1		;true to strip parity when reading source file

	IF ALPHA
nouser: db 1		;true to disable all user-area operations performed
	ENDIF		; by CC, for special kinds of systems that like it

	IF NOT ALPHA
nouser: db 0		;false to allow user area changes
	ENDIF

werrs:	db 0		;write errors flag, for RED interface

optim:	db 80h		;0: optimize for speed, use all long code sequences
			;b7 true: optimize for space, in general
			;b0-b6 true: use RST1-RST7 (respectively)
			; for -Z optimization through restart vectors

krst:	db 6		;default CDB restart vector

zenvf:	ds 1		;true if Z environment

	;
	; End Configuration Block
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

patch:	dw 0,0,0,0,0,0,0,0	;patch space
patch2:	dw 0,0,0,0,0,0,0,0
patch3: dw 0,0,0,0,0,0,0

	;
	;	Beginning of compiler code:
	;

cc1:	shld zenvad	;save Z environment pointer
	lxi h,0		;save current SP for possible use in returning to CCP
	dad sp
	shld spsav
	lxi sp,stack	;set up private stack

	call ccinit	;perform general initializations

	IF CPM AND NOT ALPHA
	call chkusr	;check for user number on main filename
	ENDIF

	call comlin	;process command line options
	call readf	;read in file(s), strip comments
	call prep	;process #define lines
	call pitext	;print out intermediate text if specified
	call pass1	;convert keywords,constants,strings
	call lblpr	;process labels and references
	call passx	;proccess constant expressions
	call bst	;build symbol table
	call passc	;process control structure
	call fixt	;purge FF's and stuff from text
	call mkfnt	;make function name table
	call wst4db	;write symbol table for debugger
	call chopst	;chop off 1st 8 bytes of st entries
	call mvfnt	;move func name table adj to text
	call errwrp	;wrap up error handling
	call usage	;print out memory usage diagnostic
	call writf	;write out file

	jmp exit	;all done


;
; Static data area:
;

	IF CPM
spsav:	ds 2	;save stack pointer for non-booting return
ccpok:	ds 1	;true if CCP still intact
erasub:	ds 1	;true if erasing submit files
curusr:	ds 1		;current disk (CP/M)
origusr: ds 1
curdsk:	ds 1		;current user area (CP/M)
origdsk: ds 1
cc2dsk:	ds 1	;default disk to search for cc2
cc2usr:	ds 1	;default user area to search for cc2
dodotc:	ds 1	;true to try ".C" if no ext given and file not found
	ENDIF

curtop:	ds 2	;end of availlable TPA memory
preflag:ds 1	;true when still pre-processing
pflag:	ds 1	;print intermediate text flag ("p" option)
sdisk:	ds 1	;disk # where source came from
chainf:	ds 1	;true if we want to chain to CC2
loadad:	ds 2	;load address
eflag:	ds 1	;true if -e option given
exaddr:	ds 2	;value given to -e option
cnflag:	ds 1	;true if comments nest
okflag:	ds 1	; "readm" routine success flag
mapucv:	ds 1	;no upper case mapping in "stcmp" routine flag

	IF CPM
cfcb:	 db 0,'CC2     COM',0,0,0,0
subfile: db 1,'$$$     SUB',0,0,0,0

redfcb:	 db 0,'PROGERRS$$$',0,0,0,0
	 ds 17	;rest of fcb for RED error file
redbuf:	ds 128	;text buffer for RED error file
redbp:	ds 2	;pointer into text buffer
errsin: ds 1	;true if RED output is active
nomore:	ds 1	;true if future red error output is disabled
	ENDIF

modstk:	ds (fnlen + 2) * (nestmax + 1)
modstp:	ds 2	;pointer to currently active filename
modstc:	ds 1	;counter

casoff:	ds 1	;case overflow flag
esctmp:	ds 1
errad:	ds 2
eradf:	ds 1
scc:	ds 1	;string character count for psstg
stgcct:	ds 2	;points to where length byte goes for psstg
nlflag:	ds 2	;used in the pitext routine  for something or other
nltmp2:	ds 1
nltmp:	ds 2
modaf:	ds 1	;whether to modify st ptrs after wrapup or not
inadsv:	ds 2	;some more kludgery to allow multiple struct
		;elements to have same name in separate structs
stsiz:	ds 2
coda:	ds 2
fndtmp:	ds 1
mvtmp:	ds 1
errf:	ds 1
cmntf:	ds 1
udiag:	ds 1
stgf:	ds 1 
csf:	ds 1
sf:	ds 1
flev:	ds 1
fixfl:	ds 1
pdfd:	ds 1  ;previously declared func. def. flag
pdfdno:	ds 2	;symbol # for above
stora:	ds 2
strsz:	ds 2
mxsiz:	ds 2
tmplf:	ds 2
tmpbs:	ds 1
tmpsu:	ds 1
fbufp:	ds 2
opena:	ds 2
stno:	ds 2
fntp:	ds 2
fnts:	ds 2
fnc:	ds 2
lbln:	ds 2
eofad:	ds 2
meofad:	ds 2	;max eofad for elbowroom announcement
nlcnt:	ds 2
nlcnts:	ds 2	;save nlcnt when in #include file
ptfnf:	ds 1
type:	ds 1
stelf:	ds 1
forml:	ds 1
what:	ds 1
lind:	ds 1
clev:	ds 1
clevb:	ds 1
clevt:	ds 1
unflg:	ds 1
newid:	ds 1	;used for flagging undefined structure identifiers
adrs:	ds 2
size:	ds 2
dmsiz:	ds 2
tempd:	ds 2
tempdp:	ds 2
tmpa:	ds 2
savsta:	ds 2
tmpfr:	ds 2
fndad:	ds 2
extsa:	ds 2
stp:	ds 2
mtpln:	ds 2
symno:	ds 2
funcf:	ds 2
z80f:	ds 1
frmrf:	ds 1
esadr:	ds 2
lcnt:	ds 1	;used by parameterized #define preprocessor 
operad:	ds 2	;where option error begins
odisk:	ds 1	;output disk designation
semiok:	ds 1
nlfnd:	ds 1	;used by decf routine
kflg:	ds 1	;true if "-k" option given to write CDB file
signm:	ds 1	;used by "passx", put here just to be safe...
cpyend:	ds 2	;parameter to "copy" routine showing end address
bcnstf:	ds 1	; (readf, pass1) true when bad char constants must
		; 		 be flagged as an error

ascb:	ds 4
	db ': ',0

	ds 10
stkchk:	ds 2	;if this ever gets clobbered, stack has overflowed

	ds 320
stack:	equ $

stg2:	db 'Close error+'
stg3:	db 'File output error; dir or disk full?+'
stgoer:	db '": option error+'
stg10:	db 'Encountered EOF unexpectedly',cr,lf
	db ' (check curly-brace balance)+'
stg12:	db 'Unmatched right brace+'
stg14:	db 'Undeclared identifier: ',0
stg15:	db 'Illegal external statement+'
stg16:	db 'Bad declaration syntax+'
stg17:	db 'Missing legal identifier+'
stg19:	db 'Function definition not external+'
stg20:	db 'Need explicit dimension size+'
stg21:	db 'Too many dimensions+'
stg22:	db 'Bad dimension value+'
stg23:	db 'Bad parameter list element+'
stg24:	db 'Redeclaration of: ',0
stg25:	db 'Missing semicolon+'
stg27:	db 'Expecting "{" in struct or union def+'
stg28:	db 'Illegal structure or union id+'
stgbft:	db 'Bad function type+'
stg28a:	db 'Undefined structure id+'
stgdu:	db '*Unnamed'
stg40:	db 'Expecting "("+'
stgbp:	db 'Unmatched left parenthesis+'

stgstk:	db 'Stack Overflow: '			; keep these two together
stgov:	db 'Sorry; out of memory+'

stgtc:	db 'I''m totally confused. '
	db 'Check your control structure!+'
stgom:	db 'Out of symbol table space; specify more...+'
stgtmf:	db 'Too many functions (63 max)',0
stgmq:	db 'String too long (or missing quote)+'
stgbsd:	db 'Attribute mismatch from previous declaration+'
stgelb:	db 'elbowroom',cr,0
stgunu:	db 'unused',cr,0
oshit:	db 'Internal Error...Call BDS+'

stgcce:	db cr,lf
	IF CPM
	db 'Can''t find CC2.COM; writing CCI file to disk'
	ENDIF
	db cr,lf,0

stgiep:	db 'Include @',0
stgilc:	db 'Illegal "{" encountered externally',0
stgtmi:	db 'Declaration too complex+'
stgbfd:	db 'Missing from formal parameter list: ',0
stgabo:	db 'Compilation aborted by ^C+'
stgeri:	db cr,lf,'RED error output initiated+',0

;
; passc error messages:
;

stgc1:	db 'Mismatched control structure',cr,lf,0
stgc2:	db 'Expecting "while"',cr,lf,0
stgc7:	db 'Illegal break or continue',cr,lf,0
stgc6:	db 'Bad "for" syntax',cr,lf,0
stgc8:	db 'Expecting "{" in switch statement',cr,lf,0
stgc9:	db 'Bad "case" constant',cr,lf,0
stgc10:	db 'Illegal statement',cr,lf,0
stgcof:	db 'Too many cases (200 max per switch)',cr,lf,0
stgddf:	db 'Can''t have more than one `default:''',cr,lf,0


;
; Initialize compiler flags and variables:
;

ccinit:	call zsetup

	lhld protm
	shld curtop

	lhld errbyt
	mvi m,0		;no error by default

	lxi h,stg0	;print sign-on message
	call pstgco	;print to console only

	mvi c,gdisk	;get current disk and user area
	call bdos
	sta curdsk	;store current disk
	sta origdsk	;and save as original disk upon invokation of CC

	IF NOT ALPHA
	mvi c,sguser	;set/get user area
	mvi e,0ffh
	lda nouser
	ora a
	cz  bdos
	sta curusr	;store current user area
	sta origusr	;and save as original user area upon invoking CC
	ENDIF

	lda defdsk	;set cc2 search path
	inr a		;first set disk
	sta cc2dsk
	lda defusr
	cpi 0ffh	;and user area. default to current?
	jnz cc2
	lda curusr	;if so, set to current user area
cc2:	sta cc2usr
	lda defsub
	inr a		;if FF, make current; else, make explicit disk code
	jnz cc3		;if not set to find submit files on current disk, don't
	lda curdsk	;else set current disk as explicit disk byte in SUB.$$$
	inr a		;     fcb in case we abort in the middle of file read
cc3:	sta subfile	;set disk to find $$$.SUB on

	lda pstrip	;does user want parity stripped on input file?
	ora a
	jnz cc3a		;if so, do nothing (strips by default)

	IF IMPURE
	mvi a,0		;IMPURE CODE: *** NOP ***
	sta stripp
	mvi a,0b7h	;IMPURE CODE: *** ORA A  ***
	sta stripp+1	
	ENDIF

cc3a:
	IF CPM		;initialize some CP/M-only parameters
	lda fcb		;get source disk #
	sta sdisk	;save it
	sta odisk
	lxi d,tbuff	;set tbuff explicitly, to facilitate debugging
	mvi c,sdma	;of the 4200h version on my 0-based system
	call bdos
	ENDIF

	xra a		;initialize following flags to FALSE:
	sta kflg	;no debugger features by default
	sta eflag	;no -e option yet
	sta errf	;error ocurred flag
	sta eradf
	sta mapucv	;no-upper-case-mapping on string-compare flag
	sta pflag
	sta z80f	;false for 8080, true for Z80
	sta semiok
	sta nomore	;allow RED output for starters

	IF CPM
	sta cfcb
	sta erasub	;don't bother erasing SUBMIT files unless -x given
	sta errsin	;no RED error file active yet
	ENDIF

	inr a		;initialize following flags to TRUE:

	sta preflag
	sta chainf

	IF CPM
	sta cnflag	;assume comments nest for starters
	sta ccpok	;CCP intact at first under CP/M
	ENDIF

	mvi a,2		;find out if we're on Z80 or 8080
	inr a
	jpe cc1z	;if on Z80,
	sta z80f	;will come here to set z80 flag.

cc1z:	lxi h,dfstsz	;default symbol table size
	shld stsiz
	lxi h,tpa	;default load address for generated code
	shld loadad
	lxi h,0a55ah	;for stack overflow check
	shld stkchk
	lxi h,0		;reset label counter
	shld lbln
	ret

	IF CPM AND NOT ALPHA
chkusr:
	lxi d,fcb+1	;check to see if user area given on filename
	call gdec	;number?
	rc		;if not, no problem
	ldax d
	cpi '/'		;user area prefix character?
	rnz
	lxi h,stgnua	;can't give user area
	jmp pstgab
	ENDIF

zsetup:	xra a
	sta zenvf	;not z environment by default
	lxi h,errdum
	shld errbyt	;dummy error byte by default
	mvi a,1
	sta oktort	;ok to return to ccp, despite ccpok for now
	lhld zenvad
	push h
	lxi d,1bh
	dad d
	mov e,m
	inx h
	mov d,m		;get reflexive env addr from env
	pop h		;original Z env value
	call cmphd	;save as reflexive address?
	jnz setp2a	;if not z system, set top of memory

	mvi a,1
	sta zenvf	;Z system.
	push h		;save env pointer
	lxi d,3fh	;get potential ccp address
	dad d
	mov a,m 
	inx h
	mov h,m
	mov l,a
	shld ccpad

	pop h		;get env pointer

	push h
	lxi d,22h
	dad d
	mov a,m
	inx h
	mov h,m
	mov l,a		;HL -> message buffer
	lxi d,6		;get address of error byte
	dad d
	shld errbyt	;save the address
	pop h

	lxi d,8		;get type
	dad d
	mov a,m
	sta envtyp
	
	ani 80h		;b7 hi?
	lhld ccpad
	jnz setup3	;if so, use ccpad as ccp address
setp2a:	lhld ram+1	;else calculate the old way
	lxi d,-1603h
	dad d

setup3:	xra a		;clear 'ccp volatile' flag
	sta ccpok	;and CCP INTACT flag
	xchg		;put ccp address in DE
	lhld bdosp
	mvi l,0		;zero out low-order byte
	call cmphd	;set Cy if [BASE+6,7] < CCP
	jc setup4	;if BASE+6 < CCP, use BASE+6 as end of prot mem
	xchg		;else use CCP as end of prot. mem.
	mvi a,1		;and set ccp volatile flag
	sta ccpok	;and set ccpok
	xra a		;NOT ok to return to ccp despite ccpok
	sta oktort
setup4:	shld protm
	ret


envtyp:	ds 1

;zenvf 		;is after wboote
zenvad:	ds 2	;address of Z3 environment block
ccpad:	ds 2 	;address of CCP for type 80h ZCPR3
protm:	ds 2	;start of protected memory
oktort:	ds 1	;ok to return to ccp despite ccpok flag?i
errbyt:	ds 2	;message buffer error byte address
errdum:	ds 1	;in case we're NOT under ZCPR3...


;
; Process command line options:
;

comlin:
	lxi h,st	;init symbol table free space pointer
	shld stp

	IF CPM
	lda tbuff
	adi 81h
	mov l,a
	mvi h,tbuff/100h
	mvi m,0		;place 00 at end of command line
	lxi d,tbuff+1	;DE will be text pointer as we process
	call igsp	;find source file name
	lxi h,stg1	;is it there?
	jz pstgab	;if not, error.
	call fspac	;pass it, and any blanks after it.
	ENDIF

	IF CPM
cc11:	call igsp	;done processing line?
	xchg
	shld operad	;save in case of error
	xchg
	ENDIF

cc111:	rz		;if so, go compile
	cpi '-'		;dash?
	jnz operr	;if not, operand error
	inx d		;get option character
	ldax d
	call mapuc	;convert to upper case
	inx d		;advance pointer past option character

cc12a:
	IF NOT ALPHA
	cpi 'K'
	jnz cc12d
	call gdec	;get optional restart param
	jnc cc12b	;param given?
	lda krst	;if not, use default value
	jmp cc12c	;if not, make it 6

cc12b:	cpi 8
	jnc operr	;if >=8, error...else OK

cc12c:	sta kflg	;set debugging mode with restart value
	jmp cc11

cc12d:	cpi 'W'		;flip error file activity?
	jnz cc12
	lda werrs	;get write error flag
	xri 1		;logically invert
	sta werrs	;and save it back
	jmp cc11
	ENDIF

cc12:	cpi 'O'		;optimize for speed flag?
	jnz cc13
	xra a		;if so, no longer optimizing for space
	sta optim
	jmp cc11

cc13:	cpi 'Z'		;RST optimization flag?
	jnz cc13z

	ldax d
	call legdd	;any parameters given?
	jnc cc13c	;if not, assume full optimization

	mvi a,0bfh	;if not, assume we're using all RST locations
	sta optim
	jmp cc11

cc13c:	mov b,a
	mvi a,80h	;paramters supplied. Activate only
	sta optim	;those optimizations with supplied parameters
	mov a,b

cc13a:	ora a		;check for range between 1-7
	jz operr
	cpi 8
	jnc operr		

	mov b,a		;save rst code in B
	mvi c,80h	;start walking bit at left, to be rotated into low bit
cc13b:	mov a,c		;shift bit left
	rlc
	mov c,a
	dcr b	
	jnz cc13b	;loop till done shifting
	lda optim
	ora c
	ori 80h		;set space optimization bit, just in case
	sta optim
	inx d
	ldax d		;any more vector specifications?
	call legdd
	jnc cc13a
	jmp cc11	;else all done
	

cc13z:	cpi 'P'		;print flag?
	jnz cc14
	sta pflag
	jmp cc11

cc14:	cpi 'R'		;symbol reservation option?
	jnz cc15
	call gdec	;get A=decimal number, 0-19
	cpi 7
	jc operr	;if < 7 or >19 then error.
	cpi 20
	jnc operr
	add a
	add a
	mov h,a
	mvi l,0
	shld stsiz	;set symbol table size to nK
	jmp cc11

cc15:
	IF CPM		
	cpi 'A'		;auto-load option? (CP/M only)
	jnz cc16
	call gdskc	;get disk code, 1-16, or 0 for 'Z'
	sta cfcb	;set disk field of cc2 fcb
	sta chainf	;if 0, this prevents auto-chaining
	sta cc2dsk	;set default cc2 search disk
	call gdec	;user number given?
	jc cc11
	sta cc2usr	;if so, set default cc2 search search area
	jmp cc11
	ENDIF

	IF CPM
cc16:	cpi 'D'		;output disk specification?
	jnz cc16a	;if not, check for other options
	call gdskc	;get disk letter
	ora a
	jz operr	;don't allow 'Z'
	sta odisk
	jmp cc11
	ENDIF

	IF CPM
cc16a:	cpi 'X'
	jnz cc17
	mvi a,1
	sta erasub	;erase submit files
	jmp cc11
	ENDIF

cc17:	
	IF NOT ALPHA
	cpi 'M'		;load address specifier?
	jnz cc18
	call ghxarg	;get hex arg in HL
	jc operr
	shld loadad
	jmp cc11
	ENDIF

cc18:	cpi 'E'		;set external address?
	jnz cc19	;if not, illegal option
	sta eflag	;set external address specified flag
	call ghxarg	;get value
	jc operr
	shld exaddr
	jmp cc11

cc19:	cpi 'C'
	jnz operr

	IF CPM
	xra a
	ENDIF

	sta cnflag	;now comments don't nest under CPM, and DO
	jmp cc11	;		nest under MARC


ghxarg:	call igsp	;yes. check for hex arg
	stc
	rz		;return error (c set) if no arg
	call leghd
	rc		;if not legal hex digit, error

	lxi h,0		;else prepare to accumulate value in HL
cc17a:	ldax d
	call leghd
	jnc cc17b	;end of value text?
	xra a
	ret		;yes. clear carry and return value in HL	
cc17b:	dad h		;no. multiply accumulator by 16
	dad h
	dad h
	dad h
	mov c,a		;and add new digit
	mvi b,0
	dad b	
	inx d		;and go to next character
	jmp cc17a

operr:	mvi a,'"'
	call outch
	lhld operad
operr1:	mov a,m
	ora a
	jz operr2
	call outch
	inx h
	mov a,l
	dcr a
	cmp e
	jnz operr1
operr2:	lxi h,stgoer	;op error string
	jmp pstgab	


	IF CPM
gdskc:	call igsp
	jz operr
	sui 'A'-1
	cpi 27
	jnc operr
	inx d		;bump past the char
	cpi 26		;change 'Z' to zero
	rnz
	xra a
	ret
	ENDIF


igsp:	ldax d
	ora a
	rz
	call mapuc
	cpi ' '
	rnz
	inx d
	jmp igsp

	IF CPM
fspac:	ldax d
	ora a
	rz
	inx d
	cpi ' '
	jnz fspac
	jmp igsp
	ENDIF

gdec:	mvi b,0
	call igsp
	call legdd
	mvi a,0
	rc	
gdec1:	ldax d
	call legdd
	mov a,b
	cmc
	rnc
	add a		;get A = 10 * B
	add a		;(*4)
	add a		;(*8)
	add b		;(*9)
	add b		;(*10)
	add c		;now add new digit value in C
	mov b,a		;put into B
	inx d
	jmp gdec1	;and go for more

;
; Check for legal decimal digit, return Cy set if illegal,
; else the binary value of the digit in A:
;

legdd:	call mapuc
	sui '0'
	mov c,a
	rc
	cpi 10
	cmc	
	ret

;
; Check for legal hex digit:
;

leghd:	call legdd
	rnc
	cpi 11h
	rc
	cpi 17h
	cmc
	rc
	sui 7
	ret			


usage:	lxi h,ascb+4
	mvi m,'K'

	IF CPM
	lhld bdosp	;get pointer to top of memory
	mvi l,0
	ENDIF

	xchg		;into DE
	lhld meofad	;get highest addr used
	call cmh	;negate
	dad d		;and add to top of mem to give free ram
	mov a,h		;divide by 1K
	rar
	rar
	ani 3fh
	mov l,a
	mvi h,0
	dcx h

	xra a
	call prhcs	;print out
	lxi h,stgelb	;"elbowroom"
	lda lbln
	ani 0fh		;little hack here!
	jnz cc1b
	lxi h,stgunu	;"unused"
cc1b:	call pstg
	ret

; Wrap up error handling, exit if there were errors:

errwrp:	lda errsin	;error output initialized?
	ora a
	jz errwr3	;if not, don't try to close RED output file

	mvi e,1ah	;ascii end-of-file
	call redout
	lhld redbp
	mov a,l
	cpi redbuf and 0ffh	;has buffer just been flushed?
	cnz redwrt	;if not, write buffer one last time
	lxi d,redfcb
	call close2	;close RED output buffer

errwr3:	lda errf	;if there were real errors (not just warnings)
	ora a		;then exit
	jnz errab2
	inr a
	sta nomore	;no more RED output
	ret		;else return


		
;
; Set up environment for a pass through the text (DE becomes
; text pointer)
;

initps:	lxi h,0
	shld nlcnt

;	shld lbln		;arghh. WHY did this WORK for so LONG?
				;(after lblpr, mustn't reset lbln anymore)

	lxi h,modstk
	shld modstp
	xra a
	sta clev
	sta modstc	;at very top level
	lhld coda
	xchg
	ret


;
;
; Passc: control structure processor:
; This pass preprocesses control statements (like while, do, 
; if...else, etc.) and twists them into a form much easier to digest
; by cc2. E.g., All the `case' statments are removed from a `switch'
; construct and a table of constants and `symbolic labels' is formed.
; If...else statments are turned into simple `if' statments (using some
; added braces and goto's...One may be able to get away from goto's
; in a C program, but it's a bit harder to avoid them at the compiler-
; design level!
;
; Note that at this point, all declarations have been purged from
; the text, leaving only the function definitions. If we ever finish
; up with a function and find something other than another function
; or EOF after it, somethings really screwed up...
;

passc:	call initps	;initialize general pass procecure variables
	lxi h,cntt	;init control table pointer (this is where
	shld cntp	; the "break" and "continue" labels are stored)
	lxi h,fbuf
	shld fbufp
	xra a
	sta clev
	dcx d

pasc1:	inx d
pasc2:	call igsht	;done with text?
	jnz pasc3
	lda clev	;yes. at top level?
	ora a
	rz		;if so, OK

pasc2a:	lxi h,stg10	;==ERROR==
	jmp fatal	;probably mismatched {}s

pasc3:	cpi varcd	;a variable? (i.e., function definition?)
	jz pasc4

pasc3a:	call fsemi
	jmp pasc1	

;	lxi h,stgtc	;if not, somethings screwy
;	jmp fatal

pasc4:	inx d		;ok, we found a function
	inx d
	inx d
	call mtchp	;pass over the arg list
	call state	;process the body as a statment
	jmp pasc2	;and go back for another function

;
; Here it is, the routine to process a statment...
;

state:	call ckabrt	;check for user typing control-C
	call chkstk	;and check for stack overflow

	call igsht
	jz pasc2a	;if expecting a statement and get EOF, error

	call cdtst	;if it starts with a code, ignore the code
	jc state0
	inx d		;ignore it, since its probably a label
	inx d		;code or something trivial.
	inx d
	jmp state

state0:	inx d		;now, does it start with a `{'?
	cpi lbrcd
	jnz state2

state1:	call igsht	;yes. do each statment inside the compound.
	cpi rbrcd	;hit the `}' yet?
	inx d
	rz		;if so, all done
	dcx d		;else just another statment
	call state	
	jmp state1	;and keep a 'goin

state2:	cpi ifcd	;now we hit the real statements. IF?
	jz sif

	cpi whlcd	;WHILE?
	jz swhl

	cpi docd	;DO?
	jz sdo

	cpi forcd	;FOR? 
	jz sfor

	cpi swtcd	;SWITCH?
	jz sswt

	cpi brkcd	;BREAK?
	jz sbrk

	cpi cntcd	;CONTINUE?
	jz scnt

	cpi rencd	;RETURN?
	jz state3

	cpi gotcd	;GOTO?
	jz state3

	cpi cascd	;CASE? if so, bad news!
	jz sterr	; Only the SWITCH processor should see these!

	cpi elscd	;while only the IF processor should see ELSEs
	jz sterr

	cpi defcd	;and only the SWITCH processor, again, should
	jz sterr	;see DEFAULTs

	dcx d		;at this point we assume we have an expression
state3:	mvi a,1		;statment (or a really screwy error.)
	sta eradf
	lhld nlcnt
	shld errad
	call fsemi	;this phase can ignore expression statements.
	xra a
	sta eradf
	inx d
	call igsht
	ret

sterr:	lxi h,stgc10	;seeing a CASE outside of a SWITCH, and other stuff
	jmp fatal	;like that, are good enough reasons to abort.

;
; routine to pass over a statement, I guess because I need to
; look ahead sometimes to figure out what's going on. Geez,
; I can't remember what the hell I used this for...
;
; (In case you're wondering, these comments are being written about
; 11 months after the code. I just now got WORDMASTER going on my
; bee-YOU-tea-full H19 terminal, and need no longer get uptight over
; the chilling prospect of documenting 150K of source using ED...)
;

passt:	call igsht
	jz pasc2a
	call cdtst	;ignore labels and such
	jc past0
	inx d
	inx d
	inx d
	jmp passt

past0:	cpi lbrcd	;left brace?
	jnz past2
	inx d

past1:	call igsht
	cpi rbrcd
	jnz past1a
	inx d
	call igsht
	ret

past1a:	call passt	;yes; pass statement
	jmp past1

past2:	cpi ifcd
	jnz past3	;if statement?
	inx d		;yes.
	call mtchp	;pass expr
	call passt	;pass statement
	cpi elscd	;else?
	rnz
	inx d		;yes. pass statement
	call passt
	ret

past3:	cpi whlcd	;while?
	jz pst5b
	cpi cascd	;case?
	jz past3a
	cpi defcd	;default?
	jnz past4
past3a:	mvi a,colon	;yes; find a colon
	call findc
	inx d		;pass it
	call passt	;pass next statement
	call igsht
	ret

past4:	cpi docd
	jnz past5	;do statement?
	inx d		;yes.
	call passt	;pass statement
	cpi whlcd	;while?
	jz pst4a
	lxi h,stgc2	;if not, error
	call perr


pst4a:	inx d		;pass expr
	call mtchp
	cpi semi
	cnz insrts	;if no semi, insert one automagically.
	inx d
	call igsht
	ret

past5:	cpi forcd	;for statement?
	jnz past6
	sta semiok	;yes. allow semis in text for now.

pst5b:	inx d
	call mtchp	;pass expr(s)
	xra a
	sta semiok
	call passt	;pass statment
	ret

past6:	cpi swtcd	;switch?
	jz pst5b
	ora a		;no. EOF?
	jz pasc2a

	call fsemi	;no. go search for a semicolon
	inx d
	call igsht
	ret

;
; push continue-break data stack, adding two new labels:
;

cnpsh:	push d
	xchg
	lhld cntp
	mov m,e
	inx h
	mov m,d
	inx h
	inx d
	mov m,e
	inx h
	mov m,d
	inx h
	shld cntp
	lda clev
	inr a
	sta clev
	xchg
	dcx h
	pop d
	ret

;
; Pop continue-break data stack:
;

cnpop:	lhld cntp
	dcx h
	dcx h
	dcx h
	dcx h
	shld cntp
	lda clev
	dcr a
	sta clev
	ret

cklev:	lda clev
	ora a
	rnz
	lxi h,stgc7
	call perr
	pop h
	jmp sbrk3

;
; Define a symbolic label given in HL at current location in text:
;

insll:	mvi a,-3 and 255
	call mvtxt
insls:	mvi a,lblcd
	jmp insr2

;
; Install a symbolic label REFERENCE to label in HL at
; current location in text:
;

inslr:	mvi a,-3 and 255
	call mvtxt
insrs:	mvi a,labrc

insr2:	stax d
	inx d
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	inx d
	ret

;
; Install a new label definition at current location in text:
;

lblni:	call glbl
	jmp insll

;
; Install a new label reference at current place in text:
;

lblri:	call glbl
	jmp inslr

;
; Get a new label value in HL:
;

glbl:	lhld lbln
	inx h
	shld lbln
	dcx h
	ret

;
; Process a "for" statement:
;

sfor:	dcx d
	mvi a,lbrcd	;left curly-brace to delimit entire for statement
	stax d
	inx d
	call igsht
	cpi open
	jz sfor2
	lxi h,stgc6
	call perr

sfor2:	mvi a,0ffh
	stax d
	call chsbp
	call passt
	mvi a,-5 and 255
	call mvtxt
	mvi a,whlcd
	stax d
	inx d
	call glbl	;get lbl z (object of the goto later)
	push h
	call insls
	call glbl	;get lbl x
	call cnpsh
	push h		;push lbl x
	mvi a,open
	stax d
	inx d
	call igsht
	cpi semi
	jnz sfor3
	mvi a,-3 and 255
	call mvtxt
	mvi a,concd
	stax d
	inx d
	mvi a,1
	stax d
	inx d
	mvi a,0
	stax d
	inx d
	jmp sfor4

sfor3:	call chsbp
	call fsemi
sfor4:	mvi a,close
	stax d
	inx d
	call glbl	;get lbl y
	xthl		;HL = lbl x, stack = lbly
	push h		;push lbl x
	push d
	mvi a,negone
	call mvtxt
	mvi a,open
	stax d
	push d
	inx d
	lhld nlcnt
	shld nltmp
	call igsht
	cpi close
	jz sfor4a
	pop d
	jmp sfor4b
sfor4a:	mvi a,-3 and 255
	call mvtxt
	mvi a,concd
	stax d
	inx d
	mvi a,1
	stax d
	inx d
	xra a
	stax d
	pop d

sfor4b:	call mtchp
	lhld nlcnt
	push d
	xchg
	lhld nltmp
	call cmh
	dad d
	pop d
	mov a,l
	sta nltmp2
sfor5:	pop h
	push h
	push h
	call cmh
	dad d
	pop d
	shld tmplf
	lhld fbufp
	mov b,h
	mov c,l
	xthl
	push h
	lhld tmplf
	mov h,l

sfor6:	ldax d
	stax b
	inx d
	inx b
	dcr l
	jnz sfor6
	push h
	mov h,b
	mov l,c
	shld fbufp
	pop h
	pop d
	mvi a,lbrcd
	stax d
	inx d
	mov a,h
	push psw
	push psw
	dcr a
	call mvtxt
	lda nltmp2
	push psw
	cma
	inr a
	call mvtxt
	pop psw
sf6a:	ora a
	jz sf6b
	push psw
	mvi a,nlcd
	stax d
	inx d
	pop psw
	dcr a
	jmp sf6a

sf6b:	call state
	call cnpop
	pop psw
	cma
	sui 14
	call mvtxt
	mvi a,semi
	stax d
	inx d
	pop psw
	pop h
	mov b,h
	mov c,l
	shld fbufp
	pop h		;get lbl x
	push psw
	push b
	call insls	;define lbl x here
	pop b
	pop psw
	mov h,a
sfor7:	ldax b		;now copy the saved increment portion
	cpi nlcd	;back into the text
	jnz sfor7a	;but watch out for newlines
	dcx d		;and especially FAKE newlines (a la Somos)
	ldax d
	inx d		;if a newline found, make sure it isn't
	call cdtst	;just the operand of a 3-byte code
	ldax b
	jnc sfor7a	;if it is, leave it as it is
	mvi a,0ffh	;it isn't, so turn it into a garbage space
sfor7a:	stax d
	inx d
	inx b
	dcr h
	jnz sfor7
	mvi a,semi
	stax d
	inx d
	mvi a,rbrcd
	stax d
	inx d
	pop h		;get lbl y
	xthl
	mvi a,gotcd	;put in the kludge "goto" to go with the "while"
	stax d
	inx d
	call insrs
	mvi a,semi
	stax d
	inx d
	pop h
	call insls
	mvi a,rbrcd
	stax d
	inx d
	ret

chsbp:	push d
	lhld nlcnt
	push h
chsbp1:	call pascd
	cpi semi
	jz chsok
	cpi open
	jz chsbpp
	cpi close
	jnz chsbp2
	pop h
	shld nlcnt
	lxi h,stgc6
	jmp perrab

chsok:	pop h
	shld nlcnt
	pop d
	ret
chsbp2:	inx d
	jmp chsbp1
chsbpp:	call mtchp
	jmp chsbp1

;
; Process a "switch" statement:
;

sswt:	call mtchp
	push d
	lhld cntp
	push h
	dcx h
	dcx h
	dcx h
	mov b,m
	dcx h
	mov c,m
	pop h
	mov m,c
	inx h
	mov m,b
	inx h
	xchg

	call glbl
	shld defp	;set "default" default label

	push psw
	xra a
	sta defflg	;haven't encountered default: yet
	pop psw

	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	shld cntp
	pop d
	lhld defp
	push h
	push d
	cpi lbrcd
	jz ssw0
	lxi h,stgc8
	call perr
	call fsemi
	pop h
	pop h
	ret

ssw0:	lhld nlcnt
	shld tmpnl
	xra a
	sta swtc
	sta casoff
	lxi h,swtt
	shld swtp
	lxi h,clev
	inr m
	inx d

ssw0a:	call igsht
ssw1:	ldax d
	cpi lblcd
	jnz ssw1a
	inx d
	inx d
	inx d
	jmp ssw0a

ssw1a:	cpi cascd
	jz sscas
	cpi defcd
	jz ssdef
	cpi rbrcd
	jz ssdon
ssw2:	call passt
	jmp ssw1

sscas:	inx d
	push d
	call pasff
	cpi concd
	jz ccas2
	pop d
	lxi h,stgc9
ccas1:	call perr
	jmp ssw2

ccas2:	inx d
	lhld swtp
	ldax d
	mov m,a
	inx d
	inx h
	ldax d
	mov m,a
	inx h
	inx d
pasloop:
	mov b,c
	call pasff
	push psw
	mov a,b
	add c
	mov c,a
	pop psw
	cpi nlcd
	jnz ccas2a
	mov a,c
	ori 80h
	mov c,a
	inx d
	jmp pasloop
ccas2a:
	cpi colon
	jz ccas3

ccas4:	lxi h,stgc9
	jmp ccas1

ccas3:	xchg
	call glbl
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	lda casoff
	ora a
	jnz ccas3a
	shld swtp
ccas3a:	xchg
	pop d
	dcx d
	mov a,c
	adi 2
	jp ccas3c
	ani 7fh
	mov c,a
	mvi a,nlcd
	stax d
	inx d
	mov a,c
ccas3c:	call mvtxt
	call insls
	lda casoff
	ora a
	jnz ccas3b
	lxi h,swtc
	inr m
	mov a,m
	cpi 201
	jc ccas3b
	sta casoff
	dcr m
	lxi h,stgcof
	call perr
ccas3b:	jmp ssw0a

pasff:	mvi c,0
pasff1:	ldax d
	cpi 0ffh
	rnz
	inr c
	inx d
	jmp pasff1

ssdef:	push d
	inx d
	call pasff
	cpi colon
	pop d
	jnz ccas4
	mvi a,2
	add c
	call mvtxt
	call lblni
	shld defp
	lda defflg	;default previously defined?
	ora a		;set NZ if so
	mvi a,1
	sta defflg	;it is now, anyway

	lxi h,stgddf	;duplicate default message
	cnz perr	;if default previously defined, bitch
	jmp ssw0a


ssdon:	pop d
	lda swtc
	mov l,a
	mvi h,0
	dad h
	dad h
	push h
	inx h
	inx h
	inx h
	inx h
	call bexp
	mvi a,swtbc
	stax d
	inx d
	lda swtc
	stax d
	inx d
	lxi h,swtt
	pop b
ssdn1:	mov a,b
	ora c
	jz ssdn2
	mov a,m
	stax d
	inx d
	inx h
	dcx b
	jmp ssdn1

ssdn2:	lhld defp
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	inx d
	lhld tmpnl
	shld nlcnt
	call state
	pop h
	call insll
	call cnpop
	ret

;
; Process IF statement:
;

sif:	call mtchp
	call state
	call igsht
	cpi elscd
	rnz
	inx d
	call state
	ret

;
; Process a "while" statement:
;

swhl:	call lblni
	push h
	call cnpsh
	call mtchp
	call glbl
	push h
	call state
	pop h
	xthl
	mvi a,-5 and 255
	call mvtxt	;insert a forced "goto" to before the condition
	mvi a,gotcd	;test, so that things don't get messed up when
	stax d		;single-statement control structure is nested in
	inx d		;a very peculiar way.
	call insrs
	mvi a,semi
	stax d
	inx d
	pop h
	call insll
	call cnpop
	ret

;
; Process "do" statement:
;

sdo:	call lblni
	inx h
	call cnpsh
	push h
	inx h
	inx h
	shld lbln
	call state
	call igsht
	cpi whlcd
	jz sdo2
	lxi h,stgc2
	call perr
sdo2:	inx d
	pop h
	call insll
	call mtchp
	push h
	call esemi
	inx d
	pop h
	inx h
	call insll
	call cnpop
	ret

;
; Process "break" statement:
;

sbrk:	call cklev
	dcx d
	mvi a,gotcd
	stax d
	inx d
	lhld cntp

sbrk2:	dcx h
	mov a,m
	dcx h
	mov l,m
	mov h,a
	call inslr

sbrk3:	lhld nlcnt
	shld esadr
	call esemi
	inx d
	call igsht
	ret

;
; Process "continue" statement:
;

scnt:	call cklev
	dcx d
	mvi a,gotcd
	stax d
	inx d
	lhld cntp
	dcx h
	dcx h
	jmp sbrk2


	IF LASM
	link ccb
	ENDIF
