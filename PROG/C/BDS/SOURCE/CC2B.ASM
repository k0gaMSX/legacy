
;
; cc2b.asm:
;
; Expression evaluator (code generator)
;  The text pointer is always assumed to be in HL
;  when evaluating expressions...
;
; Note that several of the high-level routines have
;  several entry points, some of which "force a value
;  result" (if the name ends with "v") and some that don't.
;  This is to allow optimization for expressions which don't
;  really need to produce a value; for example, the statement:
;		foo++;
;  obviously doesn't need to produce a result that was the old
;  value of foo, as if it were being used in a larger expression.
;  Thus, whenever possible, we try to detect stuff like this and
;  avoid needless code generation by using the appropriate entry
;  point within the expression evaluation routines.

;
; Top level expression evaluation entry point. Called
; from expression-statement processor only (never need return
; value when expression is entire statement):
;

exprnv:	xra a
	sta val		;allow optimizing for no ret val
	jmp expr0

;
; General expression evaluator entry point from outside
; itself (i.e from within the statement processor as opposed to
; 	  from within expr itself):
;  Note that we might need a value here, if for example this
;  gets called from the "if" statement processor...
;

expr:	call ckabrt	;check for abortion of complilation
	mvi a,1
	sta val		;we want a resulting value
expr0:	
	push h		;save current line count for general error diagnosis
	lhld nlcnt
	shld savnlc
	pop h

	call opsin	;initialize operator stack
	xra a
	sta faflg	;clear func-arg flag
	sta lflg	;clear logical-expr flag
	call expr1	;evaluate
	call igsht	;skip trailing gunk (white space)
	ret

;
; Recursive entry point. Handles:
;	expr
;	expr,expr (except when in fun arg list or 3rd ?: expr)
;
;	Upon entry, register A tells what we want:
;		00 = rvalue
;		01 = lvalue if possible
;		02 = must have lvalue
;	(this convention remains active down to many of the
;	 lower level routines also...)

;
; Special entry point to force value result:
;

expr1v:	mov b,a		;save old A value
	lda val		;and old val value
	push psw
	ori 01h		;force value result
	sta val
	mov a,b		;restore A value
	call expr1	;evaluate
	mov b,a		;save next char of text
	pop psw		;restore old val value
	sta val
	mov a,b		;get back next char of text
	ret		;and done

;
; Normal entry point:
;

expr1:	push psw

exp1a:	call expr2	;process expression
	lda faflg	;in arg list?
	ora a		;if so, don't recognize comma operator
	jnz exp1b
			;process comma operator:
	call igsht	;no. check for , operator
	cpi comma
	jnz exp1ay	;if none, go on
			;else process rest of comma expression:
	inx h		;pass over the comma
	call rpshp	;reset push-op not to conflict with info from
	pop psw		;get back result-type-needed flag     \first sub-expr
	push psw
	call expr1	;call recursively to handle rest of comma expr
	call ppshp	;restore push-opt table

exp1ay:	call asgnop	;check for assignment operator (covers hole
	jnz exp1b	;	in expr syntax parser)
	lxi d,stg8b
	jmp perrab

exp1b:	pop psw
	ret

;
; Secondary entry point...
; Handles:
;	expr
;	expr ? expr : expr
;

;
; Call this if we must generate a value
;

expr2v:	mov b,a
	lda val
	push psw
	ori 01h		;force value result
	sta val
	mov a,b
	call expr2
	mov b,a
	pop psw
	sta val
	mov a,b
	ret

;
; Or call this if we don't care
;

expr2:	push psw
	call pxpr3	;peek past binary expression
	cpi qmark	;?: expression?
	jnz expr2a
	call ltabmp	;yes, bump logical branch table
	call expr3
	jmp qexpr	;and go finish up in ?: handler

expr2a:	pop psw
	push psw
	call expr3
	pop psw		;else done
	ret

;
; Little kludge routine to pass over simple and/or binary expressions:
;

pxpr3:	push h		;save text ptr and line count
	lhld nlcnt
	xthl
	push h
pxpr3a:	call sexpas	;pass by simple expression
	call binop	;followed by binop?
	jz morpp3
	call igsht	;make sure we get next char in A
	pop h		;no--all done
	xthl		;restore text ptr and line count
	shld nlcnt
	pop h
	ret

morpp3:	inx h		;yes--pass it and keep scanning
	jmp pxpr3a


;
; Handles:
;	sexpr binop sexpr
;	sexpr asgnop sexpr
;	sexpr
;
;	Note: "sexpr" means "simple expression", defined here as
;	      an expression having no binary, assignment, or ternary
;	      operators at the top level (although it may have them
;	      within parentheses)	

expr3:	push psw
	call sexpasl	;peek at token past simple expr
	jnc expr3b	;carry from sexpasl indicates illegal
	pop psw		;  simple expression: error.
	ret

expr3b:
	call binop	;binary operator?
	jz bexpr	;if so, go handle binary expression
	call asgnop	;assignment operator?
	jnc aexpr	;if so, go handle assignment expression
	cpi qmark	; ?-: expr?
	jnz expr3a
	pop psw		;yes. don't care if lvalue wanted
	lda val
	push psw	;save old val
	mvi a,1		;force value result, but don't force flag
	sta val		;   result to be converted to hard value
	xra a		;force rvalue of first expr
	call sgenv
	pop psw
	sta val		;restore val
	ret

expr3a:	pop psw		;not ?: expr.
	call sgen	;evaluate simple expression
	ret

sexpasl: push h		;peek past sexpr to see next
	lhld nlcnt	;non-white-space character
	xthl
	push h
	call sexpas
	pop h
	xthl
	shld nlcnt
	pop h
	ret


;
; Process simple (non-binary operator involved) expression
; of form:
;	* sexpr
;	& sexpr
;	- sexpr
;	! sexpr
;	~ sexpr
;	sizeof expr
;	pexpr	(primary expression)
;

;
; Recursive entry point to force value result:
;

sgenv:	mov b,a
	lda val
	push psw
	ori 01h
	sta val
	mov a,b
	call sgen
	mov b,a
	pop psw
	sta val
	mov a,b
	ret

;
; Normal entry point:
;

sgen:	call sgen0
	call igsht
	ret

sgen0:	push psw
	shld cdp	;update code buffer pointer

	xra a
	sta klujf	;clear short-cut-fetch-kludge flag

	call igsht	;check for unary ops
	cpi mulcd	;indirection operator?
	jnz sgen3
	inx h
	xra a
	call rpshp
	call sgenv	;yes. evaluate operand.
	call ppshp
	xra a
	sta value
	pop psw
	push psw
	ora a		;need an address?
	jnz sgen2	;if so, don't gen indirection
	call t2dim	;else do. 2-dim array?
	jz sgen2a	;if so, generate no code
	call tptrf
	jz sgen2a	;same for ptr to func
	call tsptr	;simple ptr?
	jz sgen0a	;if so, go handle indirection
	call flshh1
	call maca0c	;else get value of ptr to ptr
	jmp sgen2a	;and do internal indirection once only

maca0c:	push psw
	lda optimf	;optimizing mem indirection?
	ani 4
	jz maca0e
	mvi a,0dfh	;rst3: mov a,m;inx h;mov h,m;mov l,a;ret
	call genb
maca0d:	pop psw
	ret
maca0e:	lxi d,maca0
	call mcrog
	pop psw
	ret

sgen0a:	lda typ1	;ptr to struct?
	ani 7
	cpi 6
	jz sgen2a	;if so, no code
sgen2:	call indir	;do internal indirection on data type
	mvi a,1		;force a val result, so code such as: "*foo;" by itself
	sta val		;used to clear a memory-mapped status port, works.
	jmp sgen8	;and wrap-up.

sgen2a:	call indir
	pop psw
	ret

sgen3:	cpi ancd	;address-of operator?
	jnz sgen4
	mvi a,2		;if so, get address of operand
	inx h		;now HL -> operand
	call rpshp
	call sgenv	;evaluate
	call ppshp
	call tptrf	;ptr to func?
	jz sgen3b	;if so, obscure.
	call tstar	;array?
	jz sgen3b	;if so, we can't represent it. just smirk.
	lda indc1	;else bump indirection count
	inr a
	sta indc1
sgen3b:	pop psw		;we don't care what was asked for here.
	ret

sgen4:	cpi mincd	;minus operator?
	jnz sgen5
	inx h
	xra a
	call rpshp
	call sgenv	;yes. eval argument
	call ppshp
	pop psw
	call ckvok	;make sure we don't need lvalue
	call tcnst1
	jnz sgen4a	;constant?
	push h		;yes...
	lhld svv1
	call cmh
	shld svv1
	pop h
	ret

sgen4a:	call flshh1
	call tschr	;simple char value to negate?
	lxi d,mac0e
	jnz mcrog	;if not, assume a 2 byte value
	lxi d,mac01	;else character. turn into "int"
	mvi a,1
	sta typ1
	jmp mcrog	;and negate.

sgen5:	cpi notcd	;logical negation?
	jnz sgen6

	pop b		;get saved value code
	lda notklg	;save notkludge
	push psw
	push b		;and push saved value code back on stack

	xra a
	sta notklg	;by default, no notkludge is to be performed

	inx h		;bump txt ptr to arg of !
	call igsht	;check for "(" for a special case...
	cpi open
	jnz sgen5z	;if not, go handle normally
	lda val
	ora a
	jp sgen5z	;if don't need value, also go handle normally
	mvi a,81h
;	sta val		;turn into high force factor 
	sta notklg	;set "notkludge" flag

sgen5z:	lda val		;get result-type-needed flag
	cpi 81h		;if we need a value, then make sure we don't jump
	cz ltabmp	; out of range of the following expression

	call ltbflp	;flip ltab label entries and used bit bits. (No effect
			;if a value is needed, since both T & F addrs are same)
	xra a
	call rpshp
	call sgenv
	call ppshp
	call ltbflp	;flip ltab entries back to normal (if val is false)
	call ckaok	;make sure arg is val or ptr

	lda val
	cpi 81h		;was a value needed?
	jnz sgen50	;if not, don't clean up the range restriction
	call ltabtd	;otherwise clean up possible jump references
	call ltabfd
	call ltabpp

sgen50:	pop psw
	call ckvok	;details, details.

	call tcnst1	;was expr a constant?
	jnz sgen5a
	push h		;yes. invert the logic.
	lhld svv1
	mov a,h
	ora l
	jz sgn50a
	lxi h,-1
sgn50a:	inx h
	shld svv1
	pop h
	pop psw		;restore notkluge
	sta notklg
	ret

sgen5a:	lda notklg	;was notkludge flag set?
	ora a
	jz sgen5y	
			;OK--now we have to explicitly force into HL the value
			;that resulted from the expression...
	pop psw
	sta notklg	;first restore the kludge flag

	lda sval1	;result a flag setting?
	ani 4
	jnz sgn5ba	;if so, make sure not to flush it!

	jmp sgen5b	;otherwise don't skip the flushing business.

sgen5y:	pop psw		;restore old notkludge flag
	sta notklg

	lda sval1	;was result of expr a flag being set?
	ani 4	
	jz sgen5b

	lda sbmap1	;yes. simply invert the logic of the flag setting
	xri 1
	sta sbmap1
	lda val		;absolutely need value?
	cpi 81h
	rnz
	lda sval1	;if so, make sure we convert current flag setting
	ani 0dfh	;into an absolute value
	sta sval1
	call cvtlvh
	ret

sgen5b:	
	call flshh1
sgn5ba:	call tschr	;character argument?
	lxi d,mcn11	;"mov a,l - ora a"
	jnz sgen5c
	lda typ1	;if so, make into int
	inr a
	sta typ1
	jmp sgen5d
sgen5c:	lxi d,mcn10	;else int.
sgen5d:	call mcrog
	lda sval1	;tell that flag is now set
	ori 4
	sta sval1
	xra a		;flags: Z true
	sta sbmap1
	lda val		;need a REAL value in HL?
	ora a
	rp		;if not, all done.
	lxi d,macf1	;else gen call to routine to set HL to 1 if
	call mcrog	;Z is true
	lda sval1
	ori 20h		;tell that value is in HL as well as in flags
	sta sval1
	mvi a,1
	sta typ1
	ret

ltbflp:	push h		;hack routine to flip the true and false ltab
	push b		;entries, so that the not operator is real efficient
	lhld ltabp
	lxi d,-5
	dad d		;get HL pointing to start of current ltab entry
	mov e,m		;get true entry in DE
	inx h
	mov d,m
	inx h
	push d		;save it on stack
	mov e,m		;get false entry in DE
	inx h
	mov d,m
	inx h
	mov a,m		;get flag byte
	call flpa	;flip bits 0 and 7 of flag byte
	mov m,a		;save it back
	dcx h
	pop b		;put back true entry where false entry was
	mov m,b
	dcx h
	mov m,c
	dcx h
	mov m,d		;and put back false entry where true entry was
	dcx h
	mov m,e
	pop b
	pop h
	ret
;
; Switch bits 0 and 7 of the value in A:
;

flpa:	mvi b,0
	ora a		;is bit 7 on?
	jp flpa2
	inr b
flpa2:	ani 1		;is bit 0 on?
	mov a,b
	rz		;if not, return with b7 of result off also
	ori 80h		;else turn on b7 of result
	ret

sgen6:	cpi circum	;bitwise negate?
	jnz sgen7
	inx h
	xra a
	call rpshp
	call sgenv
	call ppshp
	call ckval	;you get this all by now, right?
	pop psw
	call ckvok
	call tcnst1
	jnz sgen6a
	push h
	lhld svv1
	call cmh
	dcx h
	shld svv1
	pop h
	ret

sgen6a:	call flshh1
	call tschr
	lxi d,mac1b
	jnz mcrog
	lxi d,mac1a
	jmp mcrog	;was 'jmp sgen5a'...why?

sgen7:	cpi sizcd	;sizeof?
	jnz sgen7b
	pop psw		;clean up stack
	inx h
	lda codflg
	push psw
	xra a
	sta codflg	;don't generate any code while doing this
	mvi a,1		;get lvalue if possible
	call sgenv
	pop psw
	sta codflg	;restore code generation flag
	push h
	call analyz	;set asize equal to size of object
	lhld asize
	call tptr	; was it a pointer?
	jnz sgen7a
	lxi h,2		;if so, size is always gonna be 2 bytes
sgen7a:	shld sr0
	shld svv1
	lxi h,100h	;set indc1 to 0 and typ1 to 1
	shld indc1
	dcr h
	shld dimsz1	;and zero dim size
	pop h
	mvi a,1
	sta sval1	;make result a constant
	ret
	
sgen7b:	pop psw		;well... no unary operator. must be
	push psw	;just a plain ole' primary expr
	call rpshp
	call primg	;evaluate it
	call ppshp

sgen8:	pop psw		;need address?
	cpi 2
	jnz sgen8a
	call analyz	;yes. Let's see if we got one...
	lda aadrf
	ora a
	rnz		;if so, all ok.
	lxi d,stg8	;else look out!
	jmp perr

sgen8a:	mov b,a		;address not mandatory.
	lda val		;need we bother with value?
	ani 1
	rz		;if not, we don't.
	lda value	;pre-processed value?
	ora a
	rnz		;if so, leave it alone
	call tsval	;else...simple value?
	rz		;if so, fine.
	mov a,b
	dcr a		;else, is an lvalue OK?
	rz		;if so, done
	call tsptr	;simple pointer?
	jz sgen8c	;if so, OK.
	call tstar	;array?
	jz sgen8c	;that's OK too.
	call tsstr	;structure?
	rz		;if so, just grin and bear it {It MIGHT
			; be something like (foo).bar}
			;is it a function? (i.e., a function name
	call tfun	;without being a call or having addr taken?)
	rz		;if so, leave it alone.

sgen8c:	call tptrf	;ptr to func?
	jz sgen8g

	call tstar	;array?
	jnz sgen8d

	lda frml1	;yes. formal array?
	ora a
	rz		;if not, all done.
	xra a		;else make it NOT formal
	sta frml1	;and indirect to get real base addr
	jmp sgen8g

sgen8d:	call tptr	;pointer?
	jz sgen8g	;if so, 2 byte indirect

	xra a		;else must be simple lvalue.
	sta indc1	;make it an rvalue
	call tschr	;char?
	jnz sgen8g	;if not, do full 2 byte indirection

;
; handle a character lvalue indirection:
;

	lda sval1	;external char?
	ani 8
	jz sgn8d4	;if not, don't bother with kluge-fetch

	lda sval1	;yes.
	ani 1		;abs lvalue?
	jz sgn8d3	;if not, go do call hack

sgn8d9:	lxi d,mac40	;yes. do lhld sr0, even tho we only need a char
	push h		;get address, stick in sr0
	lhld svv1
	shld sr0
	pop h
	call mcrog
	xra a
	sta sval1
	ret


sgn8d3:	lda optimf	;optimize for space?
	ora a
	jz sgn8d4	;if not, go do normal speed optimization

	lda sval1	;do we have a const lvalue to do it on?
	ani 3
	jnz sgn8d5	;if so, go do it

			;no.
sgn8d4:	call flshh1	;generate address of char, the hard way
	mvi a,6eh	;do an indirection
	call genb
	xra a
	sta sval1	;all done
	ret

sgn8d5:	lda svv1+1
	ora a
	jnz sgn8d7	
	lxi d,ssei
sgn8d6:	mvi a,0cdh
	call genb
	call addccc
	call gende
	jmp sgen8j

sgn8d7:	lxi d,lsei
	jmp sgn8d6

sgn8d8:	call genb
	jmp sgen8j	


;
; Handle 16 bit lvalue indirection:
;

sgen8g:	lda sval1	;if we have abs external object, always use lhld
	ani 1
	jnz sgn8d9

	lda optimf	;not abs external; ok to do c.ccc fetch optimization?
	ora a
	jz sgn8g0	;if so, go deal with it

	lda sval1	;ok to optimize for space, if an lvalue const
	ani 3		;is it an lvalue constant?
	jnz sgn8g1	;if not, go do the hard way

sgn8g0:	call flshh1	;else get address the hard way
	call maca0c	;and do hard indirection
	ret

sgn8g1:	lda sval1	;external variable?
	ani 8
	jz sgn8g3

	lda svv1+1
	ora a
	jnz sgn8g2

	lxi d,sdei
	jmp sgn8d6

sgn8g2:	lxi d,ldei
	jmp sgn8d6

sgn8g3:	lda svv1+1	;short or long displacement?
	ora a
	jz sgn8g4
	lxi d,ldli
	lda optimf
	ani 20h
	jz sgn8d6
	mvi a,0f7h	;rst 6: jmp ldli
	jmp sgn8d8

sgn8g4:	lxi d,sdli
	lda optimf
	ani 10h
	jz sgn8d6
	mvi a,0efh	;rst 5: jmp sdli
	jmp sgn8d8


sgen8j:	lda svv1	;now generate displacement.
	call genb	;always do low order byte.
	lda svv1+1	;but do high-order only if non-zero.
	ora a
	cnz genb
	xra a
	sta sval1
	ret


gende:	push d		;generate code equal to DE:	
	mov a,e	
	call genb
	pop d
	mov a,d
	call genb
	ret

	
addccc:	push h
	lhld cccadr
	dad d
	xchg
	pop h
	ret


;
; Evaluate primary expression of form:
;	++pexpr
;	--pexpr
;	pexpr++
;	pexpr--
;	pexpr[expr]
;	pexpr(arg list opt)
;	pexpr.identifier
;	pexpr->identifier
;	spexpr	(i.e, simple primary expr)
;
;  Note that whenever possible, this routine generates the
;  address of the object. Only special cases like constants
;  and functions may evaluate to constant values.
;

primg:	mov c,a
	xra a
	sta value	;clear pre-processed-value flag
	sta indc1
	sta frml1
	sta klujf
	sta sbmap1
	xra a
	sta sval1
	push h
	lxi h,0
	shld svv1
	shld dimsz1	;clear array size
	pop h
	call igsht
	cpi pplus	;leading ++ ?
	mvi b,0
	jz prmg2a
primg2:	cpi mmin	;leading -- ?
	jnz primg3
	mvi b,2		;yes.
prmg2a:	push b
	inx h
	mvi a,2
	call sgenv	;evaluate the lvalue
	pop b	
	call tsclv	;if character lvalue,
	jz prmg2b	;  always get address into HL before doing ++ or --
	lda sval1	
	ani 1
	jnz prim30	;if abs external lvalue, DON'T flush addr into HL
	
prmg2b:	call flshh1	;flush to get lvalue in HL if not abs external non-char
	jmp prim30	;and perform the ++ or -- operation

primg3:	call sprimg	;process simple primary expr
primg4:	call igsht	;check for primary expr op
	cpi open	;function call?
	jz primf
	cpi openb	;subscripting?
	jz primb
	cpi period	; . ?
	jz primp
	cpi arrow	; -> ?
	jz prima
primg6:	call igsht
	cpi pplus	;trailing ++ ?
	jnz primg7
	mvi b,1
	jmp primg8

primg7:	cpi mmin	;trailing -- ?
	jz prmg7a

	cpi varcd	;primary expression followed by a name? if not,
	rnz		;all done with this primary expression.
	
	lxi d,s4	;probably a missing semicolon
	call perrsv
	ret
	
prmg7a:	mvi b,3
primg8:	inx h
	call tsclv	;if simple character lvalue, always flush addr	
	jz primg9
	lda sval1	;if abs external lvalue, DON'T flush
	ani 1
	jnz prmg10
	
primg9:	call flshh1	;flush into HL for prim30
prmg10:	call prim30	;yes. perform post-decrement
	jmp primg4




;
; Evaluate simple primary expression of form:
;	(expr)
;	string constant
;	numeric constant
;	identifier (variable name, that is)
;

sprimg:	call igsht
	cpi open	;left parenthesis?
	jnz sprms
	mov b,c
	call sprmp	;yes. process expr in parens
	call igsht
	ret

;
; Process expression in parentheses:
;

trbnop:	ds 1		;trailing-binop flag, for use by sprmp

sprmp:	lda faflg	;save old fun-arg flag
	push psw
	lda trbnop
	push psw	;save trailing binop flag
	xra a
	sta faflg	;clear fun-arg flag
	sta trbnop	;clear trailing binop flag
	lda val
	push psw
	push h		;peek after (), looking for a primop
	lhld nlcnt
	xthl
	push h
	call mtchp
	call igsht
	cpi pplus
	jz sprmp2
	cpi mmin
	jnz sprmp3
sprmp2:	lda val		;we found a ++ or --; force lvalue result
	ori 1		;and thus force value result
	sta val
	mvi a,2
	jmp sprmp6

sprmp3:	push b
	call binop	;() followed by binary operator?
	pop b
	jnz sprmp4
	call lbinop	;yes...if logical, don't worry about it
	jz sprmp4
	call ltabmp	;not logical. bump ltab,
	mvi a,81h
	sta val		; and force value result
	sta trbnop	;set trailing binop flag (so that
	mov a,b		;restore evaluation code
	jmp sprmp6	; ltab will be popped later)

sprmp4:	call primop
	mov a,b		;if other primop
	jnz sprmp6
	lda val
	ori 1
	sta val		;force result
	xra a		;get rvalue no matter what

sprmp6:	pop h
	xthl		;restore text pointer and line count
	shld nlcnt	;to what they were before the
	xthl		;peek-ahead
	inx h
	call expr1	;evaluate inside of parens
	pop d
	pop psw
	sta val		;restore old val
	lda trbnop	;trailing binop flag set?
	ora a
	jz sprmp7

	call ltabtd	;if so, define true and false ltab entries
	call ltabfd
	call ltabpp	;and pop off the ltab entry

sprmp7:	pop psw
	sta trbnop	;restore former trailing binop flag
	pop psw
	sta faflg	;restore old fun arg flag
	push d
	call igsht
	cpi close	;check for matching )
	jz sprmp8
	xthl		;if none, error.
	push h
	lhld nlcnt
	xthl
	shld nlcnt
	lxi d,stg9
	call perr
	pop h
	shld nlcnt
	pop h
	call psemi
	ret

sprmp8:	pop d		;wrap up
	inx h
	mvi a,1	
	sta value
	ret

;
; If string constant, put string in-line, generate a 
; pointer to it and a jump around it:
;

sprms:	cpi strcd	;string constant?
	jnz sprmc
	xra a		;yes. make type "pointer to chars"
	sta typ1
	mvi a,2		;and set up other type info
	sta indc1
	sta value
	inx h		;get the string code number in DE
	mov e,m
	inx h
	mov d,m
	inx h
	push h		;save text pointer
	lhld stgad	;now search for the given string in the string pool
sprms1:	mov c,m
	inx h
	mov b,m
	inx h
	mov a,b
	cmp d
	jnz sprms2
	mov a,c
	cmp e
	jz sprms3	;found string code match?
sprms2:	push d		;no. try next string in pool
	mov e,m
	mvi d,0
	inx d
	dad d
	pop d
	jmp sprms1

sprms3:	push h		;found string. check for folding potential and
	call entstr	;enter into table if a new unique string...
	pop h
	jc sprms4	;was the table out of space?
	xchg		;no. put label code for the string into HL
	shld sr0
	lxi d,mac98a	;lxi h,sr0 (with a forward reference)
	call mcrog
	pop h		;restore text pointer
	ret		;all done

sprms4:	push h		;generate lxi h,foo - jmp bar - foo: <text>,0 - bar:
	call glbl	;set up some symolic labels
	shld sr0
	call glbl
	shld sr1
	lxi d,mac98
	call mcrog
	pop h
	mov b,m		;found it. B holds length; now generate the
sprms5:	inx h		;string characters.
	mov a,b
	ora a
	jz sprms6	;done?
	mov a,m		;no. generate next byte
	call genb
	dcr b
	jmp sprms5	;and go for more

sprms6:	xra a		;generate trailing null byte
	call genb
	lhld sr1	;and define the symbolic label
	xchg		;at the end of the string (this is the object
	call entl	;of the jump after the lxi h,string instruction
	pop h
	ret

entstr:	push h		;calculate label code for a new string
	lxi h,strtb	;if already in table, return old code, else enter it.
ntstr0:	mov e,m		;get next label # from table into DE
	inx h
	mov d,m
	inx h
	mov a,d		;end of table?
	ora e
	jnz ntstr0

	push h		;yes. check to see if table is full
	push d
	call cmh	;HL := -(table pointer)
	lxi d,strtb+strsz
	dad d		;calcualate (end - current_pointer)
	pop d
	mov a,h
	pop h
	ora a		;overflow?
	jp ntstr1
	pop h		;yes.
	stc		;return carry
	ret

ntstr1:	xchg		;there is room for another entry
	call glbl	;get new label code
	xchg		;put into DE
	dcx h
	mov m,d		;enter label code in table
	dcx h
	mov m,e
	inx h
	inx h		;now enter pointer to text
	pop b		;which was on the stack
	mov m,c
	inx h
	mov m,b
	inx h		;and clear next field as end flag
	xra a
	mov m,a
	inx h
	mov m,a
	ret		;all done.


	IF 0		;disable string-folding, since it isn't standard...

ntstr2:	mov c,m		;compare current table entry with given text
	inx h
	mov b,m		;BC :=  --> current table entry text
	inx h
	xthl		;HL := new string entry being processed
	push h		;save the starting addr of the label
	push d		;save the label code
	ldax b		;check length bytes against each other
	cmp m
	jz ntstr4	;same length?
ntstr3:	pop d		;no, so a mismatch right off.
	pop h
	xthl		;restore stuff for another try
	jmp ntstr0

ntstr4:	mov d,a		;ok, lengths match. now compare text
	inr d		;D holds char count
ntstr5:	dcr d		;done?
	jnz ntstr6
	pop d		;yes...we have a match. use old label code (in DE now)
	pop h
	pop h		;restore HL
	ret		;and done

ntstr6:	inx b		;keep on comparing the two strings
	inx h
	ldax b
	cmp m
	jz ntstr5	;still matching? if so, keep going.
	jmp ntstr3	;no. go on to next entry

	ENDIF


;
; If numeric consant, generate "lxi h,whatever"
;

sprmc:	cpi concd	;constant?
	jnz sprmv
	inx h		;yes. get the value in DE
	mov e,m
	inx h
	mov d,m
	inx h
	xchg		;generate lxi h,value
	shld svv1
	xchg
	mvi a,1		;make type integer
	sta typ1
	sta sval1	;make it a constant
	call igsht
	ret

;
; Process an identifier. If not an identifier, error.
;

sprmv:	cpi varcd	;identifier?
	jz sprmv2
	lxi d,stg10	;no. At this point it can't be anything
	call perrsv	;else except an error. Find the next semicolon
	call fsemi	;and attempt to keep going from there.
	ret

sprmv2:	call lookup	;look up the identifier in the symbol table.
	xchg
	shld sr0	;save displacement for later code generating use
	shld svv1
	xchg		;and leave in DE also
	lda typ1	;is it a struct or union element?
	ani 80h
	jz sprmv3
	lxi d,stg20	;if so, error.
	call perr
sprmv3:	lda typ1	;is it a function?
	ani 40h
	jz sprmv5
	sta simpf	;yes. set "simple function" (as opposed to a pointer
	lda indc1	; to a function) flag. Then fudge the indirection
	ora a		; count if necessary.
	jz sprmv4
	inr a
	sta indc1
sprmv4:	call igsht	;followed by an open paren?
	cpi open
	rz		;if so, is a simple function and may be ignored.
	push h		;else is not so simple.
	lhld dimsz1	; used to generate lxi h,addr; NOW generate:
	inx h		;		lhld addr+1
	shld sr0
	lxi h,0
	shld dimsz1
	lxi d,mac40r	; lhld sr0 (relocated)
	call mcrog
	pop h
	xra a		;and reset the simple function call flag.
	sta simpf
	ret

sprmv5:	call tptrf	;pointer to func?
	jz sprv5a	;if so, don't touch indir count
	lda indc1	;else do.
	inr a
	sta indc1
sprv5a:	mvi a,2
	sta sval1
	lda vext	;external?
	ora a		;if not, all done
	rz

	mvi a,0ah	;yes; make it external and an lvalue
	sta sval1	;set the external bit.
	lda eflag	;absolute external mode enabled?
	ora a
	rz		;if not, all done

	push h		;if absolute externals enabled,
	lhld exaddr	;get the base address
	dad d		;add to offset
	shld svv1	;and make that the value
	xchg		;leave it in DE also
	pop h
	mvi a,0bh	;now: external, an lvalue, and a constant!
	sta sval1	
	ret

genllv:	push h
	lhld sr0
	mov a,h
	ora l
	pop h
	jz genlv2
	lxi d,mac41
	call mcrog
	ret

genlv2:	mvi a,60h	;if has local displacement of zero,
	call genb	;can skip the "lxi h,disp dad b" and
	mvi a,69h	;just do a "mov h,b  mov l,c" instead.
	call genb	;(a little optimization here, a bit there...)
	ret

;
; Process subscript expression (on entry, HL -> "[")
;

primb:	call analyz	;check for pointer base
	lda amathf	; (weed out illegal bases)
	ora a
	jz prmb2a
	call tstar	;array?
	jz prmb1	;if so, not pointer base.
	lda value	;pre-processed value?
	ora a
	jnz prmb1
	call tptr	;no. pointer?
	jnz prmb1
	call indnoc
prmb1:	xra a
	sta value
	inx h
	lda frml1
	ora a
	jz prmb2
	call tstar
	jnz prmb2
	call indnoc
	xra a
	sta frml1

prmb2:	call tptr
	jz prmb3
prmb2a:	lxi d,stg16	;illegal array base error
	call perr

prmb3:	xchg
	lhld indc1
	push h
	lhld dimsz1
	push h
	lhld strsz1
	push h
	lhld asize
	push h
	lhld sval1
	push h
	lhld svv1
	push h
	xchg
	lda faflg
	push psw
	xra a
	sta faflg
	call tcnst1
	cz rpshp
	cnz spshp
	xra a
	call expr1v	;evaluate subscript
	lda sval1
	sta ssval
	ani 1
	cz flshh1	;if not constant, flush subscript
	xra a
	sta value
	pop psw
	sta faflg
	xra a
	sta frml1
	call tsval
	lda typ1
	xchg
	lhld svv1
	shld subval
	pop h
	shld svv1
	pop h
	shld sval1
	pop h
	shld asize
	pop h
	shld strsz1
	pop h
	shld dimsz1
	pop h
	shld indc1
	xchg
	jz prmb4
	lxi d,stg15
	call perr
	inx h
	jmp primg4

prmb4:	push h
	push psw
	lda ssval
	ani 1		;was subscript a constant?
	jz prmb4b
	call ppshp	;yes.
	lda sval1	;is base a constant too?
	ani 3
	jz prmb4a
	lhld asize	;yes; entire expression can be constant
	call mult
	xchg
	lhld svv1
	dad d
	shld svv1
	pop psw
	jmp prmb6d

prmb4a:	pop psw
	lhld asize	;we have const subscript, but NOT constant base
	call mult	;entire subscrip expr can be a constant
	push h		;..add it to the base.	
	call flshh1	;generate code for the base
	pop d
	call maddd	;and code to add subscript to it
	jmp prmb6c	;and go wrap up

prmb4b:	pop psw		;NOT constant subscript; has been flushed into HL
	ora a		;char value?
	jnz prmb5
	lxi d,mac61	;yes, clear H
	call mcrog

prmb5:	lhld asize	;get final subscript value into HL
	call gnmulh	;gen code to mult HL by asize
	call ppshp
	call tcnst1	;was base a constant lvalue?
	jz prmbts	;if so, go handle that scwewy case.
			;this stuff commented out for now; perhaps forever.

	call gpopd	;gen code to pop base into DE

prmbad:	mvi a,19h	;"dad d"
	call genb

prmb6c:	xra a		;result in HL
	sta sval1

prmb6d:	pop h		;clean up.
	inx h
	call indir
	jmp primg4

indnoc:	call flshh1
	call maca0c
	ret

prmbts:	lhld svv1
	shld sr0
	lda sval1
	ani 8
	jnz prbts2
	call gxchg	;'xchg' subscript into DE
	call genllv
	jmp prmbad

prbts2:	lda sval1
	ani 1
	jz prbts3
	lxi d,mac0c
	call mcrog
	jmp prmb6c

prbts3:	mov a,h		;save adjusted subscript on stack, unless base 
	ora l		; address of array is zero...
	cnz gpushh	;either save adjusted subscript 
	cz gxchg	;or just put it in DE for a while
	lxi d,mac6a
	call mcrog	;do 'lhld extbas'
	xchg		;add relative external address to extbas
	push d
	call maddd
	pop h
	mov a,h
	ora l		;now, if subscript was pushed on the stack,
	cnz gpopd	;get back adjusted subscript (else don't)
	jmp prmbad	;and go add it


;
; Process function call:
;

primf:	call tfun	;was thing before '(' a function?
	jz prmf2
	lxi d,stg11	;if not, error.
	call perr
	call mtchp
	jmp primg4

prmf2:	xra a
	sta argcnt	;clear arg count
	lda simpf	;OK...is it a simple function call?
	ora a
	jz prmf4
	call sargs	;yes. process args
	lxi d,mac08	;generate "call" op

prmf3:	call mcrog

	lda argcnt	;now restore stack. more than 6 args?
	cpi 7
	jc prmf3a

	push h		;yes. use the long sequence.
	mov l,a
	mvi h,0		;HL = argcnt
	dad h		;HL = # of bytes of stack used
	shld sr0
	pop h
	lxi d,mac8ar	;long code sequence to reset SP
	call mcrog	
	jmp prmf3c

prmf3a:	mov b,a		;save count in B
	inr b
prmf3b:	dcr b
	jz prmf3c
	call gpopd	;"pop d" for each arg
	jmp prmf3b	

prmf3c:	lda typ1	;set type of returned value
	ani 0bfh
	sta typ1
	mvi a,1
	sta value
	call igsht
	jmp primg4

prmf4:	call flshh1
	call gpushh	;handle non-simple function call
			;gen code to push func address
	call sargs	;process args
	lda argcnt	;bump arg count to account for pushed func addr
	inr a		;   later when we reset the SP after returning
	sta argcnt	

	push h		;generate code to retrieve function addr we
	mov l,a		;pushed before processing args.
	mvi h,0
	dad h		
	shld sr1	;special displacement needed by mac8a
	pop h

	lxi d,mac8a	;special non-simple function call code sequence
	jmp prmf3

; 
; Process function argument list:
;

sargs:	xchg		;save HL
	lhld dimsz1
	push h
	lhld indc1
	push h
	lhld strsz1
	push h
	lhld sval1
	push h
	lhld svv1
	push h
	lda simpf
	push psw

	xchg		;restore HL

;
; Now push the beginning address of the text of each function
; argument: (# of addresses pushed will end up in argcnt)
;

srgs0:	inx h
srgs1:	call igsht
	cpi close
	jz srgs3	;if end of arg list, go backtrack and evaluate...

srgs2:	push h		;else another arg to push text address of.

	xchg		;save text ptr in DE
	lhld nlcnt	;save the line number associated with the arg text
	push h
	xchg		;restore text ptr

	push b
	lda argcnt
	inr a
	sta argcnt
			;pass over an arg. This is much neater than the old
	call pasarg	;way of disabling code generation and evaluating the
			;arg!
	pop b
	call igsht
	cpi comma	;arg followed by comma?
	inx h
	jz srgs2	;if so, bump text pointer and look for more args
	dcx h		;else look for close paren

srgs2a:	cpi close
	cnz plerr	;if not followed by a close paren, error

srgs3:	push h
	lhld nlcnt
	shld savcnt	;save line count for end of list
	pop h

;
; Now, for each saved address, generate the code for
; the argument and push it:
;

srgs4:	shld savtxt	;save text pointer to end of list

	lda argcnt	;get arg count	
srgs5:	ora a
	jz srgs6	;done?
	push psw	;save argcount
	call igsht	;if not, we'd better be staring at a comma!
	cpi comma
	jz srgs5a
	cpi close
	cnz plerr	;tell about it if we aren't
srgs5a:	pop psw		;get back argcount
	pop h		;restore the line number matching the arg
	shld nlcnt
	pop h		;get text of previous arg and evaluate
	push psw	;save argcnt

	lda val
	push psw	;save current state of val
	ori 81h		;force value result even for logical expressions
	sta val
	call doarg
	call igsht
	pop psw
	sta val		;restore former state of val

	lda sval1
	ani 0c0h
	cz gpushh	;generate "push h" if value in HL
	cnz gpushd	;else "push d" is called for

	pop psw		;get back argcnt
	dcr a		;de-bump
	jmp srgs5	;and go do next arg	

;
; Come here to diagnose a parameter list error:
;

plerr:	lxi d,stgbf	;else must've been a parameter list error
	call perr
	call fsemi
	dcx h
	ret

;
; This routine passes over the text of a function arg--all parens,
; brackets get matched, and first comma or close paren at upper
; level terminates the scan.
;

pasarg:	call pascd2	;ignore codes and cruft
	cpi openb	;if [,
	jnz pasrg2
	call mtchb	;find matching ]
	jmp pasarg	;and go on

pasrg2:	cpi open	;if (,
	jnz pasrg3	;find matching )
	call mtchp
	jmp pasarg	;and go on

pasrg3:	cpi comma	;if comma
	rz		;found end
	cpi close	;same for top level )
	rz
	call badxch	;is character OK in an expression?
	rc		;return w/carry set if no good
pasrg4:	inx h		;else scan to next character
	jmp pasarg

;
; Return C set if keyword code in A is illegal within an expr:
;

badxch:	cpi semi	;semicolon no good
	stc
	rz
	cpi sizcd	;sizeof OK
	rz
	cpi rbrcd+2	;if <= maincode, no good
	ret

;
; Restore everything and prepare to generate calling sequence:
;

srgs6:	pop psw
	sta simpf
	lhld savcnt	;get line count for end of list
	shld nlcnt	;resotre as current count
	pop h
	shld svv1
	pop h
	shld sval1
	pop h
	shld strsz1
	pop h
	shld indc1
	pop h
	shld sr3
	lxi h,0
	shld dimsz1
	lhld sfsiz
	shld sr0
	call glbl
	shld sr2

	lhld savtxt	;get back text pointer
	inx h
	ret

;
; Process the arg at HL, either generating code or not depending
; on the state of codflg:
;

doarg:	lda faflg	;bump funarg flag so commas are treated
	inr a		;as terminators instead of operators.
	sta faflg

	lda argcnt
	push psw

	xchg
	lhld savtxt
	push h
	lhld savcnt
	push h
	lhld nlcnt	;save nlcnt of START of arg for error reports
	push h
	xchg

	call rpshp
	call ltabmp	;bump ltab, to keep logical branches from escaping
	xra a		;evaluate arg
	call expr1v
	
	call igsht	;make sure arg is followed by comma or close paren
	cpi comma
	jz doarg1	;if comma, OK
	cpi close

	xchg		;get nlcnt that was valid at START of arg, so error
	pop h		;report points to beginning of illegally-terminated
	shld nlcnt	;parameter
	push h
	xchg

	cnz plerr	;if nor comma or close paren, complain

doarg1:	call ltabfd	;come here whether false
	call ltabtd	;		of true
	call ltabpp	;value results from arg expression
	call ppshp

	lda sval1	;if a constant,
	ani 3
	cnz flshh1	;flush into HL
			;else might be in either HL or DE
	xchg		;restore state
	pop h		;clean up stack (pushed nlcnt earlier)
	pop h
	shld savcnt
	pop h
	shld savtxt
	
	xchg

	pop psw
	sta argcnt

	call tschr	;and generate code to zero high byte 
	jnz doarg2	;if arg is a char
	lda sval1	;clear H if value in HL
	ani 0c0h
	lxi d,mac61
	cz mcrog
	lxi d,mac62	;else clear D
	cnz mcrog

doarg2:	lda faflg	;reset funarg flag to handle commas correctly
	dcr a
	sta faflg
	ret

;
; Handle -> operator:
;

prima:	inx h
	call analyz
	call tptrf
	jz prmae	;ptr to func no good as base
	lda amathf
	ora a
	jz prmae	;base no good if can't do math on it
	lda aadrf	
	ora a
	jz prma2	;if not an address, don't need to indirect
	lda avar
	ora a
	jz prma0	;if not a variable, also don't need to indirect
	call tschr	;no characters allowed as base
	jz prmae

prma0:	call tstar	;is the base an array?
	jnz prma1
	lda frml1	;yes...a formal one?
	ora a
	jz prma2	;if not, don't indirect
prma1:	lda value	;if base already a value, don't indirect
	ora a
	jnz prma2
	call sgen8g	;else get the value of the pointer on left of ->
	jmp prma2	;and go add the member address

prmae:	lxi d,stg17	
	call perr

prma2:	call igsht
	cpi varcd
	jz prma3

prmae2:	call sexpas
	lxi d,stg19
	jmp perr

prma3:	call lookup
	lda typ1
	ani 80h
	jnz prma4
prma3b:	lxi d,stg19	;bad member name found
	call perr
	jmp primg4

prma4:	call primap
	call tcnst1	;now, if base is a constant, don't bother generating
	jnz prma5	;any code. is it a constant?
	push h
	lhld svv1	;yes. Add member offset to svv1.
	dad d
	shld svv1	;now wasn't that easy?
	pop h
	jmp primg4	;go skip over the code generation part

prma5:	push d
	call flshh1	;make sure base is in HL
	pop d
	call maddd
prma6:	xra a
	sta sval1
	jmp primg4

;
; Handle "." operator:
;

primp:	call tsval
	jnz primp2
	lxi d,stg17
	call perr
primp2:	inx h
	call igsht
	cpi varcd
	jnz prmae2
	call lookup
	lda typ1
	ani 80h
	jz prma3b
	call tcnst1
	jz primp3
	push d
	call flshh1	;if not constant, get base in HL
	pop d
	jmp prma4	;and go add member displacement value

primp3:	push h
	lhld svv1
	dad d
	shld svv1
	pop h
	call primap
	jmp primg4

primap:	lda typ1
	ani 7fh
	sta typ1

;	ani 20h
;	rnz

	nop!nop!nop

	lda indc1
	inr a
	sta indc1
	xra a
	sta value
	ret


;
; Handle ++ and -- operation on lvalue:
;

prim30:	lda val
	ora a		;check if we need result value
	jnz prim30b	;if so, get it.
	call igsht	;else no value explicitly needed
	call primop	;trailing primary operator?
	jz prim30a	;if so, play safe & force value
	mov a,b		;else optimize for no result value!
	ani 0feh	;and make post ops into pre ops
	mov b,a
	jmp prim30b

prim30a: mvi a,1
	 sta val

prim30b: call prm30
	xra a
	sta frml1
	ret

prm30:	mvi a,1
	sta value
	call analyz
	lda asnokf
	ora a
	jz p30err
	lda amathf
	ora a
	jnz p30a
p30err:	lxi d,stg8a
	jmp perr

p30a:	lda avar
	ora a
	jz p30b
	xra a
	sta indc1
	lda typ1
	ora a
	jnz p30a2
	lda val
	mvi c,0
	ora a
	jz domac
	inr c
	jmp domac

p30a2:	lda sval1	;abs external addr?
	ani 1
	jnz p30a3

	mvi c,2		;no.
	call domac
	inr c
	lda val
	ora a
	cnz domac
	mvi a,40h
	sta sval1
	ret

p30a3:	push h		;yes.
	lhld svv1
	shld sr0
	pop h
	mvi c,8
	call domac
	inr c
	lda val
	ora a
	cnz domac
	xra a
	sta sval1
	ret


p30b:	lda sval1	;abs external addr?
	ani 1
	jnz p30g

	lxi d,m20	;no.
	lda optimf	;-z7 in effect?
	ani 40h
	jz p30ba
	lxi d,m20z

p30ba:	call mcrog
	lda val
	ora a
	jz p30c
	call ckle2
	jz p30c
	mvi c,4
	call domac
p30c:	call ckle2
	jnz p30d
	mvi c,5
	call domac
	lda asize
	dcr a
	jz p30e
	mvi c,5
	call domac
	jmp p30e

p30d:	push h
	lhld asize
	shld sr0
	mov a,l
	sta sr1+1
	mov a,h
	sta sr2+1
	mvi a,0d6h
	sta sr1
	mvi a,0deh
	sta sr2
	pop h
	mvi c,6
	call domac
p30e:	lxi d,m28
	call mcrog
	mvi a,40h
	sta sval1
	lda val
	ora a
	rz

	call ckle2
	jz p30f
	mvi c,7
	jmp domac

p30f:	mvi c,3
	call domac
	lda asize
	dcr a
	mvi c,3
	cnz domac
	ret

p30g:	push h		;yes, abs external addr.
	lhld svv1
	shld sr0
	pop h
	lxi d,mac40	;do 'lhld foo'
	call mcrog
	lda val		;need value result?
	ora a
	jz p30h
	call ckle2	;yes.
	jz p30h
	mvi c,10	;push old value
	call domac
p30h:	call ckle2
	jnz p30i
	mvi c,11
	call domac
	lda asize
	dcr a
	jz p30j
	mvi c,11
	call domac
	jmp p30j

p30i:	push h
	lhld asize
	shld sr1
	call cmh
	shld sr2
	pop h
	mvi c,12
	call domac
p30j:	lxi d,mac09	;do: 'shld foo'
	call mcrog
	xra a
	sta sval1	;result in HL
	lda val		;need result?
	ora a
	rz		;if not, all done
	call ckle2	;else restore former value...
	jz p30k
	mvi c,13
	jmp domac

p30k:	mvi c,9
	call domac
	lda asize
	dcr a
	mvi c,9
	cnz domac
	ret


ckgt2:	lda asize+1
	ora a
	jnz invrt
	lda asize
	cpi 3
	rc
	xra a
	ret

ckle2:	call ckgt2
	jmp invrt

mact:	dw m12a,m12a,m14a,m14a		;c = 0
	dw m12,m13,m14,m15		;c = 1
mactz:	dw m16b,m16b,m18,m18		;c = 2
	dw mnul,m23,mnul,m22		;c = 3
	dw mnul,m21,mnul,m21		;c = 4
	dw m22,m22,m23,m23		;c = 5
	dw m26,m26,m27,m27		;c = 6
	dw mnul,m30,mnul,m30		;c = 7

	dw me16b,me16b,me18,me18	;c = 8
	dw mnul,me23,mnul,me22		;c = 9
	dw mnul,me21,mnul,me21		;c = 10
	dw me22,me22,me23,me23		;c = 11
	dw me26,me26,me27,me27		;c = 12
	dw mnul,me30,mnul,me30		;c = 13


;
; New ALU code generator for v1.4
;	info2 OP inf1 --> destination
;
; where info2 is either: a) in a reg, b) a constant, or c) on the stack,
;  and  info1 is either: a) in a reg, b) a constant, or c) a flag setting
;  and  destination is either a register or a constant.
;

alugen:	sta op		;save operator code
	xra a		;clear "make result type that of info2" flag
	sta par2pf	;and clear "two pointers" flag
	call nolvs	;make sure there aren't any flag settings
	call tpshd	;info2 pushed?
	jnz alugo	;if not, all set to compute
	call tcnst1	;yes. is info1 a constant?
	jz alu1		;if so, go pop info2 into DE
	lda sval1	;no...is info1 value in HL?
	ani 0c0h
	jnz alu2	;if not, pop info2 into HL
alu1:	call gpopd	;pop info2 into DE
	mvi a,40h
	jmp alu3
alu2:	call gpoph	;pop info2 into HL
	xra a
alu3:	sta sval2	;tell that value is now in the appropriate reg
	jmp alugo


;
; Make sure we don't have any flag settings to bum around with
;

nolvs:	lda sval1	;info1 a flag setting?
	ani 4
	jz nolvs2
	lda sval1	;yes. value too?
	ani 24h
	cpi 24h
	jnz nolvs1
	lda sval1	;yes-make value only (preserving register bits)
	ani 0c0h
	sta sval1
	jmp nolvs2

nolvs1:	lda sval2	;info1 is flag only. is info2 in HL?	
	ani 0c3h
	jz flshd1	;if so, put value in DE
	jmp flshh1	;else put it in HL

nolvs2:	lda sval2	;info2 a flag setting?
	ani 4
	rz
	lda sval2	;yes. do we have a value already?
	ani 24h
	cpi 24h
	jnz nolvs3
	lda sval2	;yes. make value only, preserving register
	ani 0c0h
	sta sval2
	ret

nolvs3:	lda sval1	;info2 is flag only. info1 in HL?
	ani 0c3h
	jz flshd2	;if so, put value in DE
	jmp flshh2	;else put in HL

;
; Flush all relative constants into registers
;

flrcn:	lda sval1	;info1 a rel const?
	ani 2
	jz frcn2	;if not, go check out info2
	call tcnst2	;info2 a constant?
	jnz frcn1

	call flshh1	;yes-flush info1 into HL
	jmp flrcn	;and go take care of info2

frcn1:	lda sval2	;info1 is rel lv. bummer. push info2
	ani 0c0h
	cz gpushh
	cnz gpushd
	call flshh1	;flush info1 into HL
	call gpopd	;get info2 back into DE
	mvi a,40h	;tell that info2 is in DE
	sta sval2
	ret


frcn2:	lda sval2	;info1 NOT a rel constant. info2 a rel const lv?
	ani 2
	rz		;if not, all done

	call tcnst1	;yes--info1 an abs constant?
	jnz frcn3
	call flshh2	;yes, so flush info2 into HL
	ret	

frcn3:	lda sval1	;info2 is rel lv. bummer. push info1
	ani 0c0h
	cz gpushh
	cnz gpushd
	call flshh2	;flush info2 into HL
	call gpopd	;get info2 back into DE
	mvi a,40h	;tell that info2 is in DE
	sta sval1
	ret


alugo:	push h		;do this to preserve text ptr in HL
	xra a
	sta wierdp
	call alugo1
	pop h
	ret

wierdp:	ds 1		;true for: (info2 - info1), when info2 ptr & info1 val

alugo1:	lhld svv1
	shld sr0
	lhld svv2
	shld sr1
	lda op

	cpi eqcd	;== and not= are special
	jz alueq
	cpi neqcd
	jz alune

	call analyz
	lda amathf
	ora a
	jz parerr

	call anal2
	lda amathf
	ora a
	jz parerr

	xra a
	sta hbn1cf

	lhld indc1	;turn all characters into
	call aluadj	;integers, and adjust attributes
	shld indc1	;as required.
	cz clhbn1
	lhld indc2
	call aluadj
	shld indc2
	cz clhbn2

	lda op
	cpi mulcd
	jnz aludiv


	call usuals	;handle `*' op
	lxi d,smmulu
	jz spcash
	lxi d,smmuls
	jmp spcash

aludiv:	cpi divcd
	jnz alumod
	call usuals	;handle `/' op
	lxi d,smdivu
	jz spcash
	lxi d,smdivs
	jmp spcash

alumod:	cpi modcd
	jnz aluadd
	call usuals	;handle `%' op
	lxi d,smmodu
	jz spcash
	lxi d,smmods
	jmp spcash

aluadd:	cpi plus
	jnz alusub
	call nolvwr	;permit no rel-lvalue/reg-value combinations
	call paradj	;handle `+' op

	call tbabsc
	lxi d,smadd
	jnz spcash

	lhld svv1	;handle simple constants here
	xchg
	lhld svv2
	dad d
	shld svv1
	lda wierdp	;need to copy sval2 to sval1?
	ora a
	rz

aluad3:	lda sval2
	ani 3fh
	mov b,a
	lda sval1
	ani 0c0h
	ora b
	sta sval1	;yes, so do it
	ret

;
; Make sure we don't end up with one operand being a relative lvalue
; constant and the other a value in a register:
;

nolvwr:	lda sval1
	ani 3		;info1 in a reg?
	jz flrcn	;if so, go flush info2 if it is a rel lvalue
	lda sval2
	ani 3		;info2 in a reg?
	jz flrcn	;if so, go flush info1 if it is a rel lvalue
	ret

alusub:	cpi mincd
	jnz alusr
	call nolvwr	;permit no rel-lvalue/reg-value combinations
	call paradj	;handle `-' op
	call tbabsc
	lxi d,smsub
	cnz spcash
	lhld svv1	;do this just in case we had two constants
	call cmh
	xchg
	lhld svv2
	dad d
	shld svv1

	lda par2pf	;two pointers?
	ora a
	jnz alus1	;if so, go scale result by object size
	
	lda wierdp	;no. Was it an (ptr - val) expression?
	ora a
	jnz aluad3	;if so, go set info1 to type of info2
	ret		;else info1 is correct type-all done.


alus1:	lhld asize	;we've gotta scale result by object size
	shld sr0
	dcx h
	mov a,h
	ora l		;size = 1?
	jz alus2	;if so, don't do nuthin'
	lxi d,macad3	;else gen code to divide by object size
	call tbabsc
	cnz mcrog	;but don't bother if both constants
	cz divs1a	;in case they're constants, calculate value here
alus2:	lxi h,0
	shld dimsz1
	xra a
	sta indc1
	inr a
	sta typ1
	call tbabsc	;if both were abs constants,
	rnz
	mvi a,1
	sta sval1	;result is ABS constant (even if both args were lv's)
	ret

alusr:	cpi srcd
	jnz alusl
	call ckval2	;handle `>>' op
	call flrcn
	call tbabsc
	lxi d,smsr
	jnz spcash
	lhld svv2	;do constant case
	lda svv1
	mov b,a
	inr b
alusr2:	dcr b
	jz alusl3
	xra a
	mov a,h
	rar 	
	mov h,a
	mov a,l
	rar
	mov l,a
	jmp alusr2


alusl:	cpi slcd
	jnz alugt
	call ckval2	;handle `<<' op
	call flrcn
	call tbabsc
	lxi d,smsl
	jnz spcash
	lhld svv2	;do constant case
	lda svv1
	inr a
alusl2:	dcr a
	jz alusl3
	dad h
	jmp alusl2

alusl3:	shld svv1
	ret

alugt:	cpi gtcd
	jnz aluge
alugt2:	call usual2	;do '>' op
	lxi d,smgtu
	jz spcash
	lxi d,smgts
	jmp spcash

aluge:	cpi gecd
	jnz alult
	call alult2	;do '>=' (simply inverse of '<')
	jmp alune1

alult:	cpi ltcd
	jnz alule
alult2:	call usual2	;do '<' op
	lxi d,smltu
	jz spcash
	lxi d,smlts
	jmp spcash

alule:	cpi lecd
	jnz aluand
	call alugt2	;do '<=' (simply inverse of '>')
	jmp alune1

aluand: cpi ancd
	jnz aluxor
	call ckval2	;do '&' op
	call flrcn
	call tbabsc
	lxi d,smand
	jnz spcash
	lhld svv1	;handle trivials constant case
	lda svv2
	ana l
	mov l,a
	lda svv2+1
	ana h
	mov h,a
	shld svv1
	ret

aluxor:	cpi xorcd
	jnz aluor
	call ckval2	;do '^' op
	call flrcn
	call tbabsc
	lxi d,smxor
	jnz spcash
	lhld svv1	;do simple constants case
	lda svv2
	xra l
	mov l,a
	lda svv2+1
	xra h
	mov h,a
	shld svv1
	ret

aluor:	cpi orcd

	push d
	lxi d,stgbbo	;'expecting binary operator'
	cnz perrab	;no other operators; better be '|'
	pop d

	call ckval2
	call flrcn
	call tbabsc
	lxi d,smor
	jnz spcash
	lhld svv1	;do trivial constants case
	lda svv2
	ora l
	mov l,a
	lda svv2+1
	ora h
	mov h,a
	shld svv1
	ret

alune:	call alueq	;for not=, first call the == routine
alune1:	lda sval1	;and invert the result.
	ani 4		;was it a flag setting?
	jz alune2
	lda sbmap1	;yes-invert bit 0
	xri 1
	sta sbmap1
	ret

alune2:	lda sval1
	ani 3		;result a constant?
	cz ierror	;if not, must've screwed up somewhere
	lhld svv1	;get result of == test
alun2a:	mov a,h
	ora l
	lxi h,0		;was it zero?
	jnz alune3	;if not, new result IS zero
	inx h		;if so, new result is 1
alune3:	shld svv1
	ret
			;handle == operator:
alueq:	call flrcn	;flush rel lvalue constants
	call tbabsc
	jnz alueq2	;both constants?
	lhld svv1	;yes.
	xchg
	lhld svv2	;compare them
	call cmh
	dad d		;set HL to zero if two are equal
	jmp alun2a

alueq2:	lda sval1
	sta ssval
	call tschr	;info1 a simple char?
	jnz aleq3
	call tschr2	;yes. info2 also a char?
	jnz aleq2b
	lxi d,mac71c	;yes--do simple mov a,e-cmp l
	call mcrog
aleq20:	xra a
aleq2a:	sta sbmap1
	mvi a,4
	sta sval1
	ret

aleq2b:	call tcnst2	;info1 is a char, info2 isn't..
	jnz aleq2e	;is info2 a constant?
	lhld svv2
	shld svv1	;if so, xfer value over to common area
alq2b2:	lda svv1+1	;info1 is a char. is info2 (const) <= 255?
	ora a
	jnz aleq2d
	lda ssval	;yes.
	ani 0c0h	;get low byte of non-constant into A
	mvi a,7dh
	cz genb		;if non-constant in H, do "mov a,l"
	mvi a,7bh
	cnz genb	;else do "mov a,e"
	lda svv1	;special case constant of 0?
	ora a
	jnz aleq2g
	mvi a,0b7h	;if so, do "ora a"
	call genb
	jmp aleq20

aleq2g:	mvi a,0feh	;do 'cpi value'
	call genb
	lda svv1
	call genb
	jmp aleq20

aleq2d:	lxi h,0		;if char value and two byte constant,
	shld svv1	;can't possibly be equal
	mvi a,1
	sta sval1
	ret

aleq2e:	lxi d,mac61	;zero high-order byte of char value
	lda ssval
	ani 0c0h
	cz mcrog
	lxi d,mac62
	cnz mcrog
	lxi d,mac71
	call mcrog
	jmp aleq20

aleq3:	call tschr2	;info1 NOT char, but is info2?
	jnz aleq4
	lda sval2	;yes--set up info2 attributes in common area
	sta ssval
	call tcnst1	;if info1 not constant, go zero high byte of
	jnz aleq2e	;info2 and do 16-bit test
	jmp alq2b2	;else optimize for character constant

aleq4:	lxi d,smeq	;do the normal macro for 2 values or one constant
	jmp spcash	;and one big value.




;
; If one or two pointers appear in a + or - operation, scale
; the non-pointer by the size of the object the pointer points to:
;

paradj: call unsadj	;adjust for unsigned operands
	call tptr2	;info2 a pointer?
	jz prdj2
	call tptr	;no. info1 a pointer?
	rnz		;if not, nothin' to do.
	lda op
	cpi mincd
	jz parerr	;2nd arg can't be pointer in binary `-' operation
	call analyz
	lhld svv2
	shld subval
	lhld asize
	shld sr0
	lda sval2
	call sclabh	;scale object described by A by HL bytes
	shld svv2	;save value in case of constant (such as array base)
	ret

prdj2:	call tptr	;info2 is ptr-is info1 ptr too?
	jnz prdj3
	lda op		;yes. Can only subtract 2 ptrs if op is `-'
	cpi mincd
	jnz parerr
	call analyz
	push h
	lhld asize
	push h		;save size of object 1
	call anal2
	lhld asize	;get size of object 2 in HL
	pop d		;get size of object 1 in DE
	mov a,h		;compare size of both objects--must be =
	cmp d
	mov a,l
	pop h
	jnz parerr
	cmp e
	jnz parerr
	mvi a,1
	sta par2pf
	ret

prdj3:	call anal2	;info2 is a pointer.
	lhld svv1
	shld subval
	lhld asize
	shld sr0
	lda sval1
	call sclabh	;scale asize by HL
	shld svv1

	lhld indc2	;move info2 info into info1, but
	shld indc1	;preserve info1's old sval1 and svv1
	lhld dimsz2	;for register allocation/optimization
	shld dimsz1	;purposes.
	lhld strsz2
	shld strsz1
	mvi a,1
	sta wierdp
	ret

sclabh:	mov b,a		;object to scale a constant?
	ani 3
	jz scl2
	call mult	;yes--simple
	ret

scl2:	mov a,h		;multiply by 0?
	ora l
	rz		;if so, just grin and scratch hair.
	dcx h		;multiply by 1?
	mov a,h
	ora l
	rz		;if so, don't do a darned thing
	mov a,b		;else, is value to scale in HL?
	ani 0c0h
	jnz sclde
	call trydad	;yes, try to do it with 'dad h's
	rz		;all done if it worked
	lxi d,macad2	;else scale HL the hard way
	call mcrog
	ret

sclde:	lda codflg	;if value in DE, first see if we can use 'dad h's
	push psw
	xra a
	sta codflg	;disable code generation the first time...
	push h
	call trydad
	pop h	
	jnz sclde2	;can we use "dad h"'s?
	pop psw		;yes. restore codeflag
	sta codflg
	call gxchg	;get the value from DE into HL
	call trydad	;do the dad h's for real
	lda op		;if + operator, don't worry about restoring
	cpi plus	;proper registers (leave them switched)
	cnz gxchg	;but put them back if - operator
	ret

sclde2:	pop psw		;restore codflg
	sta codflg
	lxi d,macad1	;and scale DE the hard way
	call mcrog
	ret


trydad:	mov a,h
	ora a		;if high byte is non-zero, forget about
	rnz		;using dad h's!
	mvi c,29h
	mov a,l
	dcr a
	jz dad1		;if HL was originally 2, go do single dad h
	sui 2
	jz dad2		;if it was 4, do two dad h's
	sui 4
	jz dad3		;if it was 8, do three dad h's
	sui 8		;if wasn't 16, give up
	rnz
	mov a,c
	call genb	;it was 16--do four dad h's
dad3:	mov a,c
	call genb
dad2:	mov a,c
	call genb
dad1:	mov a,c
	call genb
	ret



;
; svv1 <-- svv1/asize, signed
;

divs1a:	lhld svv1
	mov a,h
	ora a
	jp divpos	;svv1 positive? if so, do simple unsigned divide
	call cmh	;else negate to make it positive,
	call divpos	;do the divide
	lhld svv1	;and negate the result
	call cmh
	shld svv1
	ret

;
; svv1 <-- HL/asize, unsigned:
;

divpos:	lxi b,-1	;quotient result
	xchg
	lhld asize
	call cmh
	xchg		;put -asize in DE
divtst:	mov a,h
	ora a		;if HL negative, all done
	jp keepon
	mov h,b
	mov l,c
	shld svv1	;store quotient
	ret

keepon:	dad d		;subtract asize again
	inx b
	jmp divtst	;and test for negative numerator


;
; Some common tests performed by alugen operator handlers:
;

usuals:	call ckval2
usual2:	call flrcn
	call tbabsc
	cz fcnsts
	call unsadj
	ret

;
; Clear high byte of info1's register:
;

clhbn1:	mvi a,0afh	;get 'xra a'
	call genb
	lda sval1
clhb1a:	ani 0c0h	
	mvi a,67h	;'mov h,a'
	cz genb
	mvi a,57h	;'mov d,a'
	cnz genb
	sta hbn1cf
	ret

;
; Clear high byte of info2's register:
;

clhbn2:	lda hbn1cf
	ora a
	lda sval2	;if info1 already cleared, use the 0 in A again
	jnz clhb1a
	lxi d,mac61	;else generate mvi x,0
	ani 0c0h
	cz mcrog	;mvi h,0 if value in HL
	lxi d,mac62
	cnz mcrog	;else mvi d,0
	ret

;
; Return Z set if both info1 and info2 are constants of some kind:
;

tbabsc:	lda sval1
	ani 3
	jz invrt
	lda sval2
	ani 3
	jmp invrt

;
; Flush any and all constants into registers
;

fcnsts:	lda sval1	;info1 a const?
	ani 3
	jz fcn2		;if not, go check out info2
	lda sval2	;yes. info2 a const?
	ani 3
	jz fcn1
	call flshd1	;yes-flush info1 into DE
	jmp fcnsts	;and go take care of info2

fcn1:	lda sval1	;info1 constant, info2 isn't. info1 absolute?
	ani 1
	jz fcn1a
	lda sval2	;yes, so flush into wherever info2 isn't...
	ani 0c0h
	jz flshd1	;either DE, if info2 in HL
	jmp flshh1	;or into HL if info2 in DE

fcn1a:	lda sval2	;info1 is rel lv. bummer. push info2
	ani 0c0h
	cz gpushh
	cnz gpushd
	call flshh1	;flush info1 into HL
	call gpopd	;get info2 back into DE
	mvi a,40h	;tell that info2 is in DE
	sta sval2
	ret


fcn2:	lda sval2	;info1 NOT a constant. info2 a const?
	ani 3
	rz		;if not, all done
	lda sval2	;yes. absolute constant?
	ani 1
	jz fcn2a
	lda sval1	;yes-flush into wherever info1 isn't
	ani 0c0h
	jz flshd2	;into DE if info1 in HL
	jmp flshh2	;into HL if info1 in DE

fcn2a:	lda sval1	;info2 is rel lv. bummer. push info1
	ani 0c0h
	cz gpushh
	cnz gpushd
	call flshh2	;flush info2 into HL
	call gpopd	;get info2 back into DE
	mvi a,40h	;tell that info2 is in DE
	sta sval1
	ret

	IF LASM
	link cc2c
	ENDIF

