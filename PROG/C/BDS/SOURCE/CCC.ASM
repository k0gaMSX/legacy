;
; ccc.asm:
;

;
; This is the declaration parser....
;

bst:	xra a
	sta stelf
	sta unflg
	sta forml
	sta clevb
	sta sf
	sta newid
	inr a
	sta clevt
	call initst
	lxi h,0
	shld stora
	shld stno
	lxi h,st
	shld stp
	call initps
	dcx d

bst1:	inx d
bst2:	call pascd
	jnz bst2a
	lda clev
	ora a
	rnz
	lhld stora
	shld extsa
	ret

bst2a:	cpi lbrcd	;open curly-brace?
	jnz bst3

	call ckabrt	;a convenient place to check for abortion...

	lda forml	;yes. have we been processing a formal declaration
	ora a		;list?
	jnz bst2b	;if so, switch state to being out of formal area.

	lda clevb	;else if still at top level, then there
	ora a		; is an error here somewhere.
	jnz bst2c	;at top level? if not, all OK.

	lxi h,stgilc	;if at top level, bad curly-brace encountered.
fatal:	jmp perrab

bst2b:	lxi h,0
	shld stora

bst2c:	xra a		;turn off formal flag
	sta forml
	lxi h,clevb
	inr m		;bump curly count
	jmp bst1	;and go for more

bst3:	cpi rbrcd	;right curly bracket?
	jnz bst5
	lda clevb	;yes.
	ora a		; were we already at top level?
	jnz bst4
	lxi h,stg12	;if so, then error.
	jmp fatal

bst4:	dcr a		;debump curly-count
	sta clevb
	jnz bst1	;and go loop if not back to top level
	lda clev	;now at top level. bump func count
	inr a
	sta clevt
	xra a		;set clev to zero (external)
	sta clev
	lhld stora	;set local stack frame size for func just completed
	mov b,h		; processing.
	mov c,l
	lhld fndad	;this is the address of where the sf size will go
	inx h
	inx h
	mov m,c		;well, now it is. store it.
	inx h
	mov m,b
	lhld extsa	;and restore the external storage allocation value
	shld stora	;to the storage allocator.
	jmp bst1	;and go for more external stuff.


bst5:	call tstty	;no. a type specifier?
	jnc bst5a
	cpi regcd	;no. "register"?
	jz bst5b
	cpi shrtcd
	jnz bst6
bst5b:	push d		;yes.
	lhld nlcnt	;ignore it.
	push h
	inx d
	call igsht
	pop h
	shld nlcnt
	pop d
	call tstty	;if not followed by type, assume "int"
	jnc bst5z
	mvi a,81h	;"int" code
	stax d
	jmp bst5a

bst5z:	mvi a,0ffh	;delete "register" code
	stax d
	jmp bst1

bst5a:	call declp	;process declarations of this type
	jmp bst1	;and loop for more text

bst6:	ldax d		;not a declaration. an identifier?
	call varch
	jc bst1		;if not, then not interesting. look for something else
	call finds	;yes. is it in the symbol table?
	jc bst8
	lda clev	;yes. are we processing externals?
	ora a
	jnz bst6a
	mvi a,negone	;if so, might be typeless function def; insert "int".
	call mvtxt
	mvi a,81h	;"int" code
	stax d
	jmp bst5a

bst6a:	call cknex	;not external. make sure it isn't an external
	push h		; redeclaration.
	mov a,c		;remove text of identifier and replace it with
	sui 3		; the special 3-byte symbol table pointer.
	call mvtxt
	pop h
	call bstz2
	lda flev
	ora a
	jnz bst1	;ignore if already local
	push d		;else must create local instance of an identifier
	lxi d,st+8	;having an external namesake...
	dad h
	dad h	
	dad h
	dad h
	dad d
	mov a,m
	ani 1
	jnz bst6f	;go do it if needed.
	pop d		;else already declared locally. nothing else to do.
	jmp bst1	;go process some more text

;
; So, now we know we have a usage of a function defined
; externally... let's make an st entry for it locally:
;

bst6f:	lxi d,-8
	dad d	;HL--> ext def.
	xchg
	lhld stp
	mvi b,16
bst6f1:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz bst6f1

	lxi d,-8
	dad d
	mov a,m
	ori 3
	mov m,a
	inx h
	mov a,m
	ani 0e0h
	mov b,a
	lda clev
	add b
	mov m,a
	inx h
	pop d
	dcx d
	dcx d
	jmp bstf3


cknex:	push psw
	lda clev
	ora a
	jz ck2
	pop psw
	ret

ck2:	lxi h,stg15
	call perr
	call fsemi
	pop h
	pop h
	jmp bst1

bst8:	push d
	lhld nlcnt
	push h
	call pasvr
	pop h
	shld nlcnt
	pop d
	cpi open
	jz bstf
	call cknex
	cpi openb
	jz bste
	cpi arrow
	jz bste
;	cpi period
;	jnz bst10

bste:	call bvarm	;bad variable message
	call pasvr
	jmp bst1

;bst10:	call bvarm
;	call bstl
;	jmp bst1

bstl:	call instt
	mov a,c
	sui 3
	sta tmpbs
	call mvtxt
	lda forml	;if formal, set formal bit
	rlc ! rlc ! ani 04h
	ori 10h		;always set to int type
	mov m,a
	inx h
	lda clev
	ora a
	jnz bstlb

bstla:	lxi h,stg15
	call perr
	jmp bst1

bstlb:	mov m,a
	inx h
	push h
	lhld stora
	mov b,h
	mov c,l
	inx h
	inx h
	shld stora

bstlc:	pop h
	call bstz
	ret


bstf:	lda clev
	ora a
	jnz bstf2
	call fnnt
	jmp bst1

bstf2:	call instt
	mov a,c
	sui 3
	call mvtxt
	mvi m,13h
	inx h
	lda clev
	ora a
	jz bstla
	mov m,a
	inx h
bstf3:	push h
	lhld fnc
	mov b,h
	mov c,l
	inx h
	shld fnc
	pop h
	call bstz
	jmp bst1


bstz:	mov m,c
	inx h
	mov m,b
	inx h
	inx h
	inx h
	inx h
	inx h
	shld stp
	lhld stno
	push h
	inx h
	shld stno
	pop h

bstz2:	mvi a,varcd
	stax d
	inx d
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	ret

fnnt:	push d
	mvi a,-1 and 255
	call mvtxt
	mvi a,81h
	jmp dclp1

declp:	xra a
	sta what	;"what" defaults to variable
	inr a
	sta type	;"type" defaults to int (bug fix 11/19/80)
	ldax d
	push d
	cpi uncd
	jz dclp0
	cpi sttcd
	jnz dclp1
dclp0:	call decs
	jmp dclp1c

dclp1:	sui 80h
	sta type
	inx d
	call igsht
	cpi regcd	;ignore "register" keyword
	jnz dclp1b
	inx d
dclp1b:	xra a
	sta what
	call declst

dclp1c:	ldax d
	cpi semi
	jnz decf
	pop h
	dcx h
dclp2:	inx h
	mov a,m
	cpi nlcd
	jz dclp3
	mvi m,0ffh
dclp3:	call cmphd
	jnz dclp2
	ret

; Remove text between start of function def
; and start of formal param list:

decf:	lda lind	;check for illegal func def of type struct or union
	ora a
	jnz decf00
	lda type
	cpi 6
	jnz decf00

	lxi h,stgbft	;bad function type (function cannot return a struct)
	call perr
	
decf00:	lhld opena
	xchg		;put start of formal param list ptr in DE
	pop h		;get --> start of declaration
decf01:	call cmphd
	jz decf03
	mov a,m		;except for newlines, that is...
	cpi nlcd
	jz decf02
	mvi m,0ffh
decf02:	inx h
	jmp decf01

decf03:	mvi a,-3 and 255 ;make room for function code
	call mvtxt

decf0:
	mvi a,varcd
	stax d
	inx d
	lhld stno
	dcx h
	lda pdfd	;use original st# if declared previously
	ora a
	jz decf1
	lhld pdfdno
decf1:	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	inx d
	call igsht	;now find param list
	inx d
	mvi a,1
	sta forml	;set formal flag
	lhld stora
	shld extsa	;save external storage count
	lxi h,1		;reset local function count number
	shld fnc
	dcx h		;and clear local storage allocator
	shld stora
decf2:	call igsht	;scan formal parm list
decf3:	cpi close	;end?
	rz		;if so, all done
	call varch	;else legal identifier?
	jnc decf4
	lxi h,stg23	;if not, complain
	call perr
	mvi a,close	;and skip rest of list
	call findc
	ret

decf4:	call finds	;does identifier already exist?
	jnc decf5
decf4a:	call bstl	;no. install as simple formal int
	jmp decf6	;and go for more

decf5:	lda flev	;exists already. External in its formal
	ora a	 	;incarnation?
	jz decf4a	;if so, simply ignore external one.
	push h	
	push b
	lxi h,stg24	;else redeclaration error (only possibility
	call bvarm2	;is an identical id earlier in parm list)
	pop b
	mov a,c
	sui 3
	call mvtxt
	pop h
	call bstz2
decf6:	inx d		;go on to next parm
	call igsht
	cpi comma
	jnz decf3		
	inx d
	jmp decf2


;
; Process structure declaration:
;

decs:	sta tmpsu
	mvi a,1
	sta modaf
decs0:	inx d
	call igsht
	cpi regcd	;ignore "register" keyword
	jz decs0

	cpi lbrcd	;immediate structure listing?
	jz decsl
	call finds	;if not, must be struct identifier
	jnc decse	;if known identifier, go handle it
	call instt	;otherwise install new struct identifier name
	mvi a,1
	sta newid
	call pasvr
	jmp decs1

decsl:	push d		;if no identifier given, use a dummy name
	lxi d,stgdu
	call instt
	pop d

decs1:	lda forml	;save state of formal, since it is meaningless
	push psw	;for a structure type definition
	lda what
	push psw
	mvi a,2
	sta what
	lxi h,0
	shld dmsiz
	dcx h
	shld size
	xra a
	sta forml
	sta lind
	sta ptfnf
	call wrapup
	pop psw
	sta what
	pop psw
	sta forml
	lhld stno
	dcx h
	shld size

decsf:	call igsht	;see what follows the identifier
	cpi lbrcd	;left brace?
	jz decsd	;if so, go handle definition
	jmp decsd6	;else go process declarator list

decse:	xra a
	sta newid
	shld size
	push h
	push d
	call getsz
	xchg
	shld strsz
	pop d
	pop h
	push h
	call cvtst
	ani 3
	cpi 2
	jz decse2
	pop h
	lxi h,stg28

decse1:	call perr
	call fsemi
	ret

decse2:	push h
	push d
	lhld nlcnt
	push h
	call pasvr	
	pop h
	shld nlcnt
	pop d
	pop h
	cpi lbrcd
	jnz decse3

	inx h
	inx h
	inx h
	inx h	
	inx h
	mov a,m
	cpi 255
	jz decse3
	lxi h,stg24
	call bvarm2	;"redeclaration of: name"

decse3:	pop h
	call pasvr
	jmp decsf


decsd:	lda forml
	push psw
	xra a
	sta forml
	push h
	lhld stora
	push h
	lhld mxsiz
	push h
	lda stelf
	push psw
	lda unflg
	push psw
	lxi h,0
	shld stora
	shld mxsiz
	mvi a,1
	sta stelf
	xra a
	sta unflg
	inx d
	lda tmpsu
	cpi uncd
	jnz decsd2
	sta unflg

decsd2:	call igsht
	cpi rbrcd
	jz decsd4
	call tstty
	jnc decsd3
	lxi h,stg16
	call perr
	call fsemi
	inx d
	jmp decsd2

decsd3:	call declp
	jmp decsd2

decsd4:	inx d
	lda unflg
	ora a
	jz decsd5
	lhld mxsiz
	shld stora
decsd5:	pop psw
	sta unflg
	pop psw
	sta stelf
	lhld stora
	shld strsz
	mov b,h
	mov c,l
	pop h
	shld mxsiz
	pop h
	shld stora
	pop h
	shld size
	push d
	call getsz
	mov m,c
	inx h	
	mov m,b
	pop d
	pop psw
	sta forml
	xra a
	sta newid	;identifier no longer new after definition

decsd6:	mvi a,6
	sta type
	call declst
	xra a
	sta newid	;clear newid flag
	ret

getsz:	dad h
	dad h
	dad h
	dad h
	lxi d,st+12
	dad d
	mov e,m
	inx h
	mov d,m	
	dcx h
	ret



declst:	call igsht
	cpi semi
	rz

decls1:	lda what
	push psw
	call dec

;
; Check for forward references to undefined structures:
;

	lda type
	cpi 6
	jnz decls0	;structure?
	lda lind	;yes. indirection?
	ora a
	jnz decls0
	lda newid	;no. brand new, undefined struct id?
	ora a
	jz decls0
	lxi h,stg28a	;using undefined structure id
	call perr

decls0:	call igsht
	cpi comma
	inx d
	jnz decls2
	pop psw
	sta what
	jmp decls1

decls2:	dcx d
	pop b	;clean up stack
	cpi semi
	rz
	lda what
	cpi 1
	rz
	lxi h,stg25
	call perr
	call fsemi
	ret

dec:	xra a
	sta ptfnf
	sta lind
	sta sf
	inr a
	sta modaf
	lxi h,0
	shld dmsiz
	shld tmpa
	lhld stora
	shld adrs
	xra a
	sta frmrf
	sta pdfd
	call decr
	lda pdfd
	ora a
	cz wrapup
	lda frmrf	;was it a formal resolution?
	ora a
	jz dec2
	lhld savsta	;yes. restore storage allocation count
	shld stora
dec2:	lda funcf
	ora a
	rz
	lda clevt
	sta clev
	cpi 64		;max # of funcs specifiable in 6 bits
	rc
	lxi h,stgtmf	
	jmp pstgab

decr:	xra a
	sta funcf
	call igsht
	cpi open
	jnz decr1
	inx d
	call decr
	cpi close
	inx d
	jz deca
	lxi h,stg16

decr0:	call perr
	call fsemi
	ret

decr1:	cpi mulcd
	jnz decr2
	inx d
	call decr
	lxi h,lind
	inr m
	mov a,m
	cpi 4
	jc deca
	lxi d,stgtmi	;too much indirection
	call perr
	jmp deca

decr2:	call varch
	jnc decr3
	lxi h,stg17
	jmp decr0

decr3:	call finds	;symbol exist already?
	jnc dcr3a

	lda forml	;no. are we processing formal declarations?
	ora a
	jz decr3a	;if not, no problem
			;OK, we're definitely doing formal declarations:
	lda stelf	;processing structure definition?
	ora a
	jnz decr3a	;if so, allow it (wierd but OK, I guess...)

decr3e:	lxi h,stgbfd	;else error.
	call bvarm2	; "idendtifier not in formal list: name"
	jmp decr3a

dcr3a:	shld pdfdno
	lda clev	;are we at external level?
	ora a
	jz decr3x	;if so, go handle that case
	lda flev	;we're local. Is identifier also an external
	ora a		;variable?
	jnz decr3z

	lda stelf	;if in a structure def, don't look too hard...
	ora a
	jnz decr3a

	lda forml	;yes. If we're formal, bad news.
	ora a
	jnz decr3e
	jmp decr3a	;else just make a local instance of the identifier.

decr3z:	lda stelf	;now we know: we're local & we have a previously
	ora a		; defined local identifier to process.
	jnz dr3za	;are we processing a structure definition?

	lda forml	;if not, it BETTER be a formal parameter decl...
	ora a
	jz dcr3ze	;if not, it is a redeclaration error.

	mvi a,0		;else must set things up specially for wrapup
	sta modaf	;make sure stp and stno aren't bumped in wrapup
	inr a
	sta frmrf	;set formal resolution flag

	lhld stora	;save current storage allocator
	shld savsta	;to be restored AFTER the wrapup

	lhld inadsv	;get pointer to ST entry of formal parameter
	dcx h
	shld tempd
	inx h
	inx h
	mov a,m		;get address from ST entry
	inx h
	mov h,m
	mov l,a
	shld adrs	;make current for wrapup
	jmp decr4	;and handle rest of declaration normally

dr3za:	lhld inadsv
	dcx h
	shld tempd
	lda what
	ora a
	jnz dcr3ze
	mov a,m
	ani 8
	jz dcr3ze
	mov a,m
	rlc
	rlc
	rlc
	rlc
	ani 7
	mov b,a
	lda type
	cmp b
	jnz dcr3z1
	inx h
	inx h
	mov c,m
	inx h
	mov b,m
	lhld stora
	mov a,b
	cmp h
	jnz dcr3z1
	mov a,c
	cmp l
	jnz dcr3z1
	xra a
	sta modaf
	jmp decr4

dcr3ze:	lxi h,stg24
	call bvarm2
	call fsemi
	ret

dcr3z2:	call perr
	call fsemi
	ret

dcr3z1:	lxi h,stgbsd
	jmp dcr3z2

decr3x:	call cvtst
	shld tempdp
	ani 3
	cpi 3		;is previously declared identifier a function ref?
	jz decr3y	;if so, go handle as a "previously declared func def"f
	mov a,m		;else is it a structure element?
	ani 8
	jnz decr3z	;if so, handle as such and let errors happen there
	call dcr3ze	;else barf on it.
	jmp errab

decr3y:	mvi a,1
	sta pdfd
	mov a,m
	ani 0fdh	;change from func ref to func def
	mov m,a
	jmp decr4

decr3a:	call instt	;install new identifier
decr4:	lhld nlcnt
	push h
	call pasvr
	pop h
	cpi open
	jz decr4a
	lda pdfd
	ora a
	jnz dcr3ze
	jmp deca

decr4a:	xchg
	shld opena
	xchg
	push h
	call mtchp
	pop h
	cpi semi
	jz decr5
	cpi comma
	jnz decr7

decr5:	shld nlcnt
	lhld opena
	xchg
	jmp deca

decr7:	lda clev	;found a function definition--process it
	ora a
	jz decr8
	lxi h,stg19
	jmp decr0

decr8:	mvi a,1
	sta funcf
	sta what
	shld nlcnt	;restore line count at start of func name ident
	lxi h,0	
	shld adrs
	lhld tempd
	lda pdfd
	ora a
	jz decr9
	lhld tempdp
decr9:	shld fndad
	ret

deca:	call igsht
	cpi open
	jnz deca3
	lda lind
	ora a
	jz deca2
	dcr a
	sta lind
	mvi a,1
	sta ptfnf
	call mtchp
	ret

deca2:	mvi a,3
	sta what
	lhld fnc
	shld adrs
	inx h
	shld fnc
	call mtchp
	ret

deca3:	cpi openb
	rnz
	lda lind
	sta sf
	lxi h,1
	call gdim
	shld tmpa
	lda forml
	ora a
	jnz deca4
	lda csf
	ora a
	jnz deca4

dca3a:	lxi h,stg20
	call gdim1a

deca4:	call igsht
	cpi openb
	jz deca5
	lxi h,0ff00h
	shld dmsiz
	ret

deca5:	call gdim
	call multa
	lda csf
	ora a
	jz dca3a
	call igsht
	cpi openb
	jnz deca6

deca5a:	lxi h,stg21
	call gdim1a

deca6:	shld dmsiz
	ret

gdim:	inx d
	xra a
	sta csf
	call igsht
	inx d
	cpi closb
	rz
	dcx d
	mvi a,1
	sta csf
	ldax d
	cpi concd
	jz gdim2

gdim1:	lxi h,stg22
gdim1a:	call perr
	call fsemi
	pop h
	pop h
	ret

gdim2:	inx d
	ldax d
	mov l,a
	inx d
	ldax d
	mov h,a
	inx d
	call igsht
	cpi closb
	inx d
	rz
	jmp gdim1


mult:	push d
	mov d,h
	mov e,l
	lxi h,0

mult2:	dad d
	dcx b
	mov a,b
	ora c
	jnz mult2
	pop d
	ret

multa:	push h
	mov b,h
	mov c,l
	lhld tmpa
	call mult
	shld tmpa
	pop h
	ret


wrapup:	push d
	lda what
	mov b,a
	lda forml
	add a
	add a
	add b
	mov b,a
	lda stelf
	add a
	add a
	add a
	add b
	mov b,a
	lda type
	add a
	add a
	add a
	add a
	add b
	mov b,a
	lda ptfnf
	rrc
	add b
	lhld tempd
	mov m,a
	inx h
	lda lind
	rrc
	rrc
	ani 0c0h
	mov b,a
	lda clev
	add b
	mov m,a
	inx h
	xchg
	lhld adrs
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	xchg
	lhld size
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	xchg
	lhld dmsiz
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	lda modaf
	ora a
	jz wrap2
	shld stp
	lhld stno
	inx h
	shld stno
wrap2:	pop d
	lda what
	ora a
	rnz

	lxi b,1
	lhld tmpa
	mov a,h
	ora l
	jz wrapf
	lda sf
	ora a
	jnz wrapf
	lda forml
	ora a
	jnz wrapf
	mov b,h
	mov c,l

wrapf:	mov h,b
	mov l,c

	lda lind
	ora a
	lxi b,2		;if any levels of indirection, make object size
	jnz wrpf3	;equal to two

	lda ptfnf	;pointer to function is a special case of indirection
	ora a
	jnz wrpf3
	
	lda forml
	ora a
	jnz wrpf3
	lda type
	cpi 6
	jnz wrpf2
	push h
	lhld strsz
	mov b,h
	mov c,l
	pop h
	mov a,b
	cpi 0ffh
	jnz wrpf3
	push h
	lxi h,stg28
	call perr
	lxi b,1
	pop h
	jmp wrpf3

wrpf2:	dcx b
	ora a
	jz wrpf3
	inx b
	cpi 3
	jc wrpf3
	inx b
	inx b
	cpi 5
	jc wrpf3
	inx b
	inx b
	inx b
	inx b

wrpf3:	call mult
	mov b,h
	mov c,l
	lhld stora
	lda unflg
	ora a
	jz wrpf4
	lhld mxsiz
	call max
	shld mxsiz
	lxi h,0
	jmp wrpf5
wrpf4:	dad b
wrpf5:	shld stora
	xra a
	sta sf
	ret

max:	mov a,b
	cmp h
	rc
	jz max2

max1:	mov h,b
	mov l,c
	ret

max2:	mov a,c
	cmp l
	rc
	mov h,b
	mov l,c
	ret


;
; Definitions of some scratch variables and buffers
; used by passc: Since passc happens after bst is all
; done, we put all passc's temp space on top of the bst
; code:
;

cntt:	equ bst		;(ds 220)
cntp:	equ bst+220	;(ds 2)
swtc:	equ bst+222	;(ds 1)
swtt:	equ bst+223	;(ds 800)
swtp:	equ bst+1023	;(ds 2)
defp:	equ bst+1025	;(ds 2)
defflg:	equ bst+1027	;(ds 1)
tmpnl:	equ bst+1028	;(ds 2)
fbuf:	equ bst+1030	;(ds 350)
;
; "Expendable" routines: the following code gets
; overwritten by the symbol table after it is used...
;

	ds 4
st:	equ ($+15) and 0fff0h


stg11:	db 'Illegal colon+'
stg26:	db 'Undefined label used+'
stg99:	db 'Syntax error+'
stg8:	db 'Bad constant+'
stg8a:	db 'Bad octal digit+'
stg8b:	db 'Bad decimal digit+'
stgsuf:	db 'Curly-braces mismatched somewhere in this definition+'

;
; The following strings used only by "readf", so their storage
; areas may be used by other routines afterwards...
;

stg4:	db 'Disk read error+'
stgie:	db 'Cannot open ',0
stgine:	db '#include files nested too deep+'
stgnua:	db 'No user area prefix allowed+'
stgucc:	db 'Unterminated comment begins here+'

	IF NOT ALPHA
stg0:	db 'BD Software C Compiler '
	ENDIF

	IF ZSYSTEM
	db '(for ZCPR3) '
	ENDIF

	IF ALPHA
stg0:	db 'BDS Alpha-C Compiler '
	ENDIF

	if not ZSYSTEM
	db 'v1.'
	db version
	db updatn+'0'
	endif

	if ZSYSTEM
	db 'vZ'
	db version
	db '.'
	db updatn+'0'
	ENDIF

	IF UPDATY			;if there is a secondary update number,
	     db updaty			;then specify it,
	     db ' '
	ENDIF

	IF NOT UPDATY
	     db '  '
	ENDIF

	db '(part I)'
	
	IF PREREL
	   db '  pre-release'
	ENDIF

	db cr,lf

	IF	DEMO
	db	'	==== DEMO COPY ====    **** NOT FOR DISTRIBUTION ****'
	db cr,lf
	db	'	This compiler package is available through this store,'
	db cr,lf
	db	'	or directly from:',		cr,lf
	db	'		BD Software, Inc.',	cr,lf
	db	'		P.O. Box 2368',		cr,lf
	db	'		Cambridge, Ma. 02238',	cr,lf
	db	'		Phone: (617) 576-3828',	cr,lf
	db	'		Price:    $150 (8" SSSD format)',cr,lf
	ENDIF

	db 0

	IF CPM
stg1:	db 'Usage: ',cr,lf
	db 'cc <source_file> [-p] [-o] [-a <x>] [-d <x>]'
	ENDIF

	IF CPM AND NOT ALPHA
	db ' [-m <addr>]'
	ENDIF

	IF CPM
	db ' [-e <addr>] [-r <n>]'
	ENDIF

	db '+'

savadr:	equ $		;this is where readf will go....


;
; The following storage is for routines in the expendable portion of 
; the program. The sections for each (independent) pass are org-ed to
; start at "stg4", to conserve memory
;

	org stg4	; "prep" data area:

deformt: ds 50		; (prep) for scratch space later on
txbuf:	ds 200		; (prep) scratch space
nlcsav:	ds 2		; (prep) nlcnt gets saved here while text is hacked
def2p:	ds 2		; (prep) string table pointer for preprocessor
deftmp:	ds 2		; (prep)
dstgf:	ds 1		; (prep)
nestl:	ds 1		; (prep) nesting level for preprocessor
active: ds 1		; (prep) active conditional compilation flag
didelse: ds 1		; (prep) true if "#else" already done
parenc:	ds 1		; (prep) paren nesting count, used by "deform"

	org stg4	; "passx" and "lblpr" data area:

opstp:	ds 2		; (passx) op stack pointer for constant expr evaluator
opstk:	ds 30		; (passx) operator stack for const. expr evaluator
valsp:	ds 2		; (passx) val stack ptr for const. expr eval.
valstk:	ds 50		; (passx) val stack for const. expr. eval.
savnlc:	ds 2		; (lblpr) for saving function starting line #s


;
; Read in the source file from disk, process
; #includes on the fly, recursively
;

	org savadr

readf:	lxi h,st	;initialize code address to follow
	xchg		;	variable-sized symbol table
	lhld stsiz
	dad d
	shld coda

	lxi h,inclstk	;set up #include processing stack after code ends
	shld fsp
	lhld coda
	shld textp

	IF CPM
	xra a		;don't put out user number on main filename
	sta udiag
	inr a		;allow automatic ".c" tacking for main file
	sta dodotc
	ENDIF

	call initps

	call readm
	ora a		;successful?
	jz errab	;go abort if not
	mvi m,0
	inx h
	mvi m,1ah
	shld eofad
	shld meofad
	ret

;
; Read in a source module from disk. Filename and user number have
; been preset by calling routine (file info at default fcb):
;

readm:	push d
	lxi d,fcb
	call openg
	pop d
	jnz rm2		;if no error, goto rm2

	IF CPM		;try ".c" if no extension given.
	lda dodotc	;allowing automatic ".C" tacking?
	ora a
	jz reade	;if not, then open simply failed.

	lxi d,fcb+9	;else try tacking ".C" if no extension given.
	ldax d
	cpi ' '
	jnz reade	;if extension given, simple error.
	mvi a,'C'	;else tack on the .C extension
	stax d
	jmp readm	;and go try opening it THAT way
	ENDIF

reade:	lda modstc	;at top level?
	ora a
	lxi h,stgie	;"Cannot open: "
	push psw
	cz pstg
	pop psw
	cnz perr
	call prfnm	;<filename>
	call crlf
	xra a		;return zero to indicate failure
	lhld textp	;return HL still valid so we don't botch up memory
	ret

prfnm:
	IF CPM
	lda udiag	;printing user number as part of filename?
	ora a
	jz prfnm2
	lda defusr
	cpi 0ffh	;if default user area is always the current one,
	lda curusr	;   don't mention it in error report
	cnz prads	;print decimal number and slash
prfnm2:
	ENDIF
	call pfnam
	ret

;
; Module opened OK. Set up for reading:
;

rm2:	xra a		;initialize comment nesting level count
	sta cmntf
	sta quotf	;not in a quoted string

	IF CPM
	sta dodotc	;don't append ".C" on first try
	ENDIF

	IF NOT ALPHA
	inr a
	ENDIF

	sta udiag	;print user number in filename diagnostics from now on
	lxi h,tbuff+secsiz-1	;set up sector buffer so the next call to

	IF NOT CPM
	lxi h,secbuf+secsiz-1
	ENDIF

	shld sptr	;init sector pointer

	lxi h,0		;clear line number for unmatched comment diagnostics
	shld nlcnt
	shld atcnt	;clear active text line counter, also for above

	lhld textp
	mvi m,modbeg	;install module-begin code and filename in text...
	inx h
	push h
	call insrtm	;install module name into text
	pop d
	call pushmn	;push module name onto modstk
	xchg	

rm2a:	mvi a,cr
	sta lastc

rm3:	call getc	;get a character
	jc rm3ab0	;on EOF, go check for last-line CR and close the file

rm3aa:	call kludge	;reverse cr's and lf's for some strange reason...
	mov a,c		;always save CR's
	cpi cr
	jnz rm3ab

	call bumpnl	;bump line count
	call ckabrt	;check once in a while for abortions
	jmp storc

rm3ab:
	cpi 1ah		;if control-Z, check for proper final line termination
	jnz rm3ac

;
; Perform end-of-file consistency check, to make sure final line of the
; file was properly terminated with a newline:
;

rm3ab0:	push h		;save text pointer
rm3ab1:	dcx h
	mov a,m
	cpi cr
	jz rm3ab2	;if found CR, last line was properly terminated...
	cpi 0ffh
	jz rm3ab1	;ignore FF's
	pop h		;else last line was NOT properly terminated. insert CR
	mvi m,cr
	inx h
	jmp rm3ab3	;and go close file

rm3ab2:	pop h
rm3ab3:	call closef
	mvi m,modend	;module-end marker
	inx h
	call popmn	;pop module name off module stack

	lda cmntf
	ora a		;file ends in the middle of a comment?
	mvi a,1		;return success code if not
	rz
	push h

	call pfnam	;print file name
	mvi a,':'
	call outch
	mvi a,' '
	call outch

	lhld atcnt	;get last active line number
	call prhcs
	lxi h,stgucc	;"UNCLOSED COMMENT" diagnostic
	call pstg
	pop h
	xra a		;return 0 -- error condition
	ret

rm3ac:	cpi 0ch		;formfeeds turn into nulls
	jz storff

	cpi lf		;so do linefeeds
	jz storff

	ora a		;nulls are totally ignored
	jz rm3

	lda cmntf
	ora a		;are we in a comment?
	jnz rm3ac2	;if so, go test for in-comment conditions

	push h		;save line number as last active line number
	lhld nlcnt
	shld atcnt
	pop h
	jmp storc	;and go save character in memory

rm3ac2:	mov a,c		;we're in a comment.
	cpi '/'		;have we encountered a close comment?
	jnz rm3a
	lda lastc
	cpi '*'
	mvi a,'/'
	jnz rm3a
	lda cmntf	;yes. decrement comment count.
	dcr a
	cpi 255
	jz rm2a		;don't store back if too many closes!
	sta cmntf
	jmp rm2a

rm3a:	cpi '*'		;have we encountered another open comment?
	jnz rm3b
	lda lastc
	cpi '/'
	mvi a,'*'
	jnz rm3b	
	lda cnflag	;do comments nest?
	ora a
	jz rm2a		;if not, ignore this new open comment.
	lda cmntf	;yes. bump comment count.
	inr a
	sta cmntf
	jmp rm2a

rm3b:	sta lastc	;still in comment. keep scanning.
	jmp rm3

storc:	mov m,c		;not in a comment. store the character
	
	mov a,c
	call mapuc
	cpi '#'		;preprocessor directive?
	jnz rm4
	lda lastc	;get char before "#" for later check
	sta lastc2	;to make sure it is a CR.
	shld pndsav
	mvi a,'#'
rm3r:	inx h
rm3s:	sta lastc
	jmp rm3

storff:	mvi a,0ffh
	mov m,a
	jmp rm3r

rm4:	cpi '"'		;check for quote
	jnz rm4b
	lda quotf	;is this a closing or opening quote?
	ora a
	jnz rm40	;if closing, don't check for '"' case
	lda lastc	;was last char a single quote?
	cpi ''''
	jz rm6
rm40:	lda quotf	;found one. Already in a string?
	ora a
	mvi a,1	
	jz rm4a		;if not, set the string flag
	xra a		;else clear the string flag
rm4a:	sta quotf	;set "in a string" flag
	mvi a,'"'
	jmp rm6	

rm4b:	cpi '\'		;check for backslash in quoted string
	jnz rm4c

	lda quotf	;in a quoted string?
	ora a
	mvi a,'\'
	jz rm6		;if not, ignore backslash
	inx h
	call getcef
	cpi '"'
	jz rm4ba
	cpi '\'
	jz rm4ba
	jmp rm3aa

rm4ba:	mov m,a
	jmp rm6

rm4c:	cpi '*'		;have we encountered an open comment?
	jnz rm5
	lda lastc	;maybe...we have a '*'
	cpi '/'		;was last character a '/'?
	mvi a,'*'	;if not, just store the '*'
	jnz rm6
			;OK, we found a '/*' sequence...
	lda quotf	;in a quoted string?
	ora a
	mvi a,'*'	;if so, don't regard the '/*' as a comment delimiter
	jnz rm6

	dcx h		;definitely a comment delimiter. kill the '/'
	mvi a,1		;and set comment count.
	sta cmntf
	jmp rm2a

rm5:	cpi 'I'		;possibly part of "include" keyword?
	jnz rm6
	lda lastc2	;if a possible #include, make sure
	cpi cr		;the char before the "#" was a CR..
	jnz rm6
	xra a
	sta lastc2
	lda lastc
	cpi '#'
	jz doincl

rm6:	sta lastc
	inx h
	jmp rm3


;
; Handle "#include":
;
; At this point, we've seen "#i"...let's make sure
; we see at least another "n", then skip the rest, and
; then process the file...
;

angleu:	ds 1		;true if angle bracket surrounds filename

doincl:	xra a
	sta angleu
	shld textp
	inx h
doin0:	call getcef
	mov c,a
	call mapuc
	cpi 'N'
	jnz storc
	
	call getcef
	call mapuc
	cpi 'C'
	jnz rm6		;just makin' sure we got "#inc"...

doinz:	call getcef	;pass by rest of "#include" keyword
	call twsp
	jnz doinz

doinz2:	call getcef	;find filename argument
	call twsp
	jz doinz2

	IF CPM
	push psw
	lda curdsk	;by default, new disk and user area
	sta newdsk	;are the same as current disk and user
	lda curusr	;area.
	sta newusr
	pop psw
	ENDIF

	lxi d,fnbuf	;copy name to buffer
	push d

	cpi '"'		;ignore 1st char if quote
	jz doin1
	cpi '<'
	jnz doin1a	;if angle bracket, assume a special directory is
			;to be searched (under CP/M, a disk and user area)
			;	<< Handle Angle Brackets now: >>
	IF CPM
	sta angleu	;note that angle bracket was found
	lda defdsk	;get default disk drive for file yanking
	cpi 0ffh	;default to current?
	jnz doiny1	;if not, use as is

	lda origdsk	;get current disk drive when compiler invoked
;	lda curdsk	;if so, make it the new disk

doiny1:	sta newdsk

	lda defusr	;set new user area
	cpi 0ffh	;default to current?
	jnz doiny2

	lda origusr	;get current user number when compiler invoked
;	lda curusr	;if so, make new user area the current one

doiny2:	sta newusr
	ENDIF	

doin1:	push d
	call getc	
	pop d
	jc closef

doin1a:	cpi lf		;CR,LF,space,tab,", and > all terminate name.
	jnz doin1b
	push h
	lhld sptr
	dcx h
	shld sptr
	pop h
	jmp doin2

doin1b:	cpi cr
	jz doin2
	call twsp
	jz doin2
	cpi '>'
	jz doin2
	cpi '"'
	jz doin2
	stax d
	inx d
	jmp doin1


			;simplified 12/27/85
	IF 0
doin2:
	cpi lf
	cz bumpnl	;bump line count
	jz doin3
			;ignore rest of line, but treat a comment
			;as a special case because of lousy design...
doin20:	call getcsd
	cpi '/'		;possible start of comment?
	jnz doin2	;if not, keep on throwing away the line
	call getcsd	;yes. next character
	cpi '*'		;a star?
	jnz doin2	;if not, keep throwing line away...

doin2a:	call getcsd	;else look for closing comment characters, and preserve
	cpi lf		;linefeeds.
	jnz doin2b	;a linefeed?
	call bumpnl
	lhld pndsav	;if so, store it and bump pointer...
	mvi m,cr
	inx h
	shld pndsav
	jmp doin2a	;and go on processing comment
	
doin2b:	cpi '*'		;possible end of comment?
	jnz doin2a	;if not, keep on scanning comment
	call getcsd	;yes...followed by a slash?
	cpi '/'
	jnz doin2b	;if not, might have been a star...
	jmp doin2	;else done with comment. go process rest of this line.


getcsd:	push d
	call getc
	pop d
	rnc
	pop b
	jmp closef
	ENDIF

twsp:	cpi ' '
	rz
	cpi 0ffh
	rz
	cpi 9
	ret

doin2:	
doin3:	xra a
	stax d
	call pushf

	pop d		;check for explicit user area prefix on filename
	push d		;save ptr in case of no legal user number prefix
	call gdec	;test for decimal number (gdec sets Cy if none)
	jc doin3a	;if no prefix, don't futz with user number
	ldax d		;check for trailing slash
	cpi '/'
	jnz doin3a	;if none, not a legal user number
	mov a,b		;else it is. Make it the new user number
	sta newusr
	inx d		;bump text pointer past user number prefix
	pop h		;discard pushed text pointer from stack
	jmp doin3b	;and go process remainder of filename		

doin3a:	pop d		;under CP/M, set up default fcb with filename
doin3b:	lxi h,fcb
	call setfcb	;set up fcb, return Cy if explicit drive name given
	jc doin3d	;if explicit drive given, don't be intelligent...
			;at this point: no explicit drive name given. Only
			;allow the source file disk to determine new-disk for
			;the included file IFF no angle bracket was used...
	lda angleu	;was angle bracket used?
	ora a		
	jnz doin3e	;if so, IGNORE default source disk (sdisk)
			;inserted by setfcb.
			;If no <...> used, allow sdisk to determine source disk
doin3d:	lda fcb		;see if explicit disk given in #include op
	ora a		;if non-zero, an explicit disk was given,
	jnz doin3c	;	so go log that in as new current disk
	
doin3e:	lda newdsk	;if no disk designator given, set disk byte
	inr a		;with appropriately offset new disk value
	sta fcb	

doin3c:	dcr a		;change fcb-based disk code to BDOS call disk code
	sta newdsk
doin4:	mov e,a
	mvi c,select
	call bdos	;select disk

	lda curdsk	;save current disk and user area on stack
	push psw
	lda curusr
	push psw

	lda newdsk	;and set up new disk and user area for this file
	sta curdsk
	lda newusr
	sta curusr
	
	mov e,a		;select new user area

	IF NOT ALPHA
	lda nouser
	ora a
	jnz doin40	;skip setting user area if 'nouser' true
	mvi c,sguser 
	call bdos
	ENDIF

	IF NOT CPM
	pop h		;else put filename in HL
	shld fnam	;and save for pfnam printout (on error only)
	ENDIF


doin40:	lhld nlcnt	;save line count
	push h

	lhld pndsav
	shld textp

	call readm	;read in the included file

	sta okflag	;save return condition from readm in okflag

	xchg		;save HL in DE
	pop h		;restore line count
	shld nlcnt
	shld atcnt	;match active text to current line number
	xchg		;restore text ptr into HL

	pop psw		;they were before the include file was being processed.
	sta curusr	;first the user number:
	push h		;save HL during BDOS calls
	mov e,a

	IF NOT ALPHA
	lda nouser
	ora a
	jnz doin5a	;skip setting user area if 'nouser' true
	mvi c,sguser
	call bdos
	ENDIF

doin5a:	pop h		;pop HL so we can get at pushed psw...
	pop psw		;and then set the current disk:
	sta curdsk
	push h		;save HL for BDOS call
	mov e,a
	mvi c,select
	call bdos	
	pop h		;restore HL after BDOS futzing

	call popf	
	lda okflag	;was the readm successful?
	ora a
	jnz rm3		;if so, go on
	jmp errab	;and  all done

;
; Get next char from current file, and go close file and return to
; caller one level higher if EOF encountered:
;

getcef:	call getc
	jc getcf2
	cpi 1ah		;end of file character?
	rnz
getcf2:	pop b
	jmp closef

;
; Get next character from current text input file:
;

getc:
	xchg		;save text pointer in DE
	lhld sptr	;get sector pointer in HL
	inx h		;bump it
	mov a,l		;exhausted current sector? look at low byte of ptr

	IF CPM	
	ora a		;check for 00 (end of tbuff) under CP/M
	ENDIF

	jnz getc1
	call reads	;yes. read in next sector

	IF CPM
	lxi h,tbuff	;and reset sector pointer
	ENDIF

	IF NOT CPM
	lxi h,secbuf
	ENDIF

	xchg		;put text pointer back in HL in case of return...
	rc		;if EOF, restore textp into HL and return

	call ckov	;check HL for memory overflow
	xchg		;put text ptr in DE, get sector pointer in HL

getc1:	mov a,m		;get next char from sector buffer

stripp:	ani 7fh		;strip parity -- substitute "nop-ora a" for "ani 7fh"
			;		to allow bit 7 to be high on input text
	shld sptr	;save sector pointer
	xchg		;get back text pointer in HL
	ret


;
; Install current filespec (from default fcb) into text buffer at HL,
; and bump HL past the filename:
;

insrtm:	push b
	push h
	push d
	mvi b,12
	lxi d,fcb
	call movrc
	pop d
	pop h
	pop b
	ret


pushf:	push h
	push d
	mvi c,0
	lhld fsp
	call movstf
	shld fsp
	pop d
	pop h
	ret

popf:	push h
	push d
	mvi c,1
	lhld fsp

	IF CPM
	lxi d,-164	; 33 (fcb) + 128 (buffer) + 2 (ptr) + 1 (rederf) = 164
	ENDIF

	dad d
	shld fsp
	call movstf	
	pop d
	pop h
	ret

movstf:
	IF CPM
	lxi d,fcb
	mvi b,33
	call movram
	lxi d,tbuff
	mvi b,128
	call movram
	lxi d,sptr
	mvi b,3
	call movram
	ret
	ENDIF

	IF CPM		;set default FCB, return Cy set if explicit drive used:
setfcb:	mvi b,8
	push h
	inx d
	ldax d
	dcx d
	cpi ':'
	lda sdisk	;default disk is disk source file came from
	stc
	cmc
	push psw	;push Cy reset in case explicit disk not given
	jnz setf1
	pop psw
	stc
	push psw	;push Cy set, since explicit disk IS given
	ldax d
	call mapuc
	sui '@'
	inx d
	inx d
setf1:	mov m,a
	inx h
	call setnm
	ldax d
	cpi '.'
	jnz setfcb2
	inx d
setfcb2:mvi b,3
	call setnm
	mvi m,0
	lxi d,20
	dad d
	mvi m,0
	pop psw		;restore return flag (Cy set if d: given)
	pop d		;restore fcb address in DE for BDOS call forthcoming
	ret

setnm:	push b
setnm2:	ldax d
	call legfc
	jc pad
	mov m,a
	inx h
	inx d
	dcr b	
	jnz setnm2
	pop b
setnm3:	ldax d
	call legfc
	rc
	inx d
	jmp setnm3

pad:	mvi a,' '
	mov m,a
	inx h
	dcr b	
	jnz pad
	pop b
	ret

legfc:	call mapuc
	cpi '.'
	stc
	rz
	ora a
	stc
	rz
	cmc
	ret

	ENDIF

reads:
	IF CPM		;read a sector of 128 bytes under CP/M
	push h
	push d
	lxi d,fcb
	mvi c,rsequen
	call bdos
	ora a
	pop d
	pop h
	rz
	cpi 1
	jnz rds2
	stc
	ret
	ENDIF

rds2:
	lxi h,stg4
	jmp pstgab


kludge:	cpi cr
	mvi c,lf
	rz
	cpi lf
	mvi c,cr
	rz
	mov c,a
	ret

	IF LASM
	link ccd
	ENDIF

