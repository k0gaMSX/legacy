

;
; cc2d.asm:
;
; Utility routines for expression evaluator:
;

;
; Lookup the identifier pointed to by HL in the
; symbol table, and set the following values
; according to the symbol table entry:
;	INDC1:	indirection count
;	TYP1:	type
;	STRSZ1:	size of structure (if structure)
;	DIMSZ1:	array information (if array), else
;		address of function (if function)
;	FRML1:	1 if formal argument, else 0
;	(DE):	relative address (relative to BC or extad)
;

lookup:	mov a,m
	cpi varcd
	cnz ierror
	inx h
	mov e,m
	inx h
	mov d,m
	inx h
	call lookp2
	call igsht
	ret

lookp2:	push b
	push h
	xchg
	dad h
	dad h
	dad h
	lxi d,st
	dad d
	mov a,m

	push psw	;flag using structure types as expressions
	ani 3
	cpi 2
	lxi d,stg10
	cz perr
	pop psw

	rrc
	rrc
	rrc
	rrc
	ani 87h
	mov b,a
	mov a,m
	rrc
	rrc
	push psw
	ani 60h
	ora b
	sta typ1
	pop psw
	ani 1
	sta frml1
	inx h
	mov a,m
	rlc
	rlc
	ani 3
	sta indc1
	mov a,m
	ani 3fh
	mvi a,1
	jz lp3
	dcr a
lp3:	sta vext
	inx h
	mov e,m
	inx h
	mov d,m
	inx h
	push d
	mov e,m
	inx h
	mov d,m
	inx h
	xchg
	shld strsz1
	xchg
	mov e,m
	inx h
	mov d,m
	xchg
	shld dimsz1

	pop d
	lda frml1	;formal?
	ora a
	jz lp3a		;if not, displacement value is OK
	lhld sfsiz	;else add sfsiz+4 to it
	dad d		;HL = sfsiz + local_addr
	lxi d,4
	dad d		;HL = sfsiz + local_addr + 4
	xchg		;put value back in DE

lp3a:	lxi h,0
	dad d
	dad d
	dad d
	lda typ1
	ani 40h
	jz lp4
	shld dimsz1

lp4:	pop h
	pop b
	ret

;
; Push operator in A on operator stack:
;

oppsh:	push h
	lhld opstp
	inx h
	mov m,a
	shld opstp
	pop h
	ret

;
; Pop off top entry in operator stack; Error
; if no operators on it:
;

oppop:	push h
	lhld opstp
	mov a,m
	cpi 255
	jz opop1
	ora a
	jnz opop2
opop1:	lxi d,stg7
	call perr
	call fsemi
	pop h
	ret

opop2:	dcx h
	shld opstp
	pop h
	ret

;
; Pop off dummy op
;

oppops:	push h
	lhld opstp
	dcx h
	shld opstp
	pop h
	ret

;
; Look at top of operator stack. Return Z set
; (Z true) if no operators on the stack:
;

tstops:	push h
	lhld opstp
	mov a,m
	ora a
	pop h
	rz
	cpi 255
	ret


;
; Push information about operand 1 on the
; operand information stack:
;

pshn1:	push h
	push psw

	lhld indc1
	xchg
	lhld infsp	;the info-SP
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld strsz1
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld dimsz1
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld sval1
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld svv1
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	lda frml1
	mov m,a
	inx h

	shld infsp
	call chkovn	;check for info table overflow
	pop psw
	pop h
	ret

;
; Push information about operand 2 on the
; operand information stack:
;

pshn2:	push h
	push psw

	lhld indc2
	xchg
	lhld infsp	;the info-SP
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld strsz2
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld dimsz2
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld sval2
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	xchg
	lhld svv2
	xchg
	mov m,e
	inx h
	mov m,d
	inx h

	lda frml2
	mov m,a
	inx h

	shld infsp
	call chkovn	;check for info table overflow
	pop psw
	pop h
	ret

;
; Check for info-table overflow by seeing if the pointer
; has overlapped into the relocation table area:
;

chkovn:	mov a,h
	cpi relt/255	;if info pointer (hi) is less than the addr of the
	rc		;rel table (hi), then no overflow
	jnz chkove	;if not same, then it has overflown
	mov a,l		;if same, check low order byte
	cpi relt and 255
	rc		;if not less than rel table low byte, error

chkove:	lxi d,stgetc	;sub-expressions too deeply nested; complain and 
	jmp perrab	;give up.

;
; Pop off operand information from the operand
; information stack; make it operand 1:
;

ppn1:	push h
	push psw
	lhld infsp
	dcx h

	mov a,m
	sta frml1
	dcx h

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld svv1
	xchg

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld sval1
	xchg

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld dimsz1
	xchg

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld strsz1
	xchg

	mov d,m
	dcx h
	mov e,m
	shld infsp
	xchg

	shld indc1
	pop psw
	pop h
	ret

;
; Pop off information on operand 2:
;

ppn2:	push h
	push psw
	lhld infsp
	dcx h

	mov a,m
	sta frml2
	dcx h

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld svv2
	xchg

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld sval2
	xchg

	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld dimsz2
	xchg
	mov d,m
	dcx h
	mov e,m
	dcx h
	xchg
	shld strsz2
	xchg
	mov d,m
	dcx h
	mov e,m
	shld infsp
	xchg
	shld indc2
	pop psw
	pop h
	ret

;
; Move operand 1 info into operand 2:
;

mvn12:	call pshn1
	call ppn2
	ret

;
; Move operand 2 info info operand 1:
;

mvn21:	call pshn2
	call ppn1
	ret


;
; Analyze the expression characterized by the variables
;	indc1,typ1,strsz1,dimsz1,frml1
; by setting the following variables accordingly:
;	AADRF:	true (non-zero) if an address;
;	ASNOKF:	true if it can be assigned to;
;	AMATHF:	true if it can have math done on it;
;	ASIZE:	if a pointer, size of the object pointed at;
;	AVAR:	true if a variable address (but not a pointer)
;

analyz:	push h		;save text pointer
	call anal1	;perform analysis
	pop h		;restore text pointer
	ret

anal1:	lxi h,1		;assume simple things at first.
	shld asize	;size of 1 byte
	shld subval	;initialize mulitplication accumulator
	xra a
	sta avar	;not a variable
	inr a
	sta amathf	;can do math
	sta asnokf	;ok to assign to it
	sta aadrf	;has an address

	call tstar	;is it an array?
	jz anal6
	call tptr	;no. pointer?
	jz anal6
	call tsval	;no. simple constant value?
	jnz anal3
	xra a		;yes. can't assign to it...
	sta asnokf
	sta aadrf	;and it aint an address.
	jmp anal5a	;make size of it: 2

anal3:	call tsstr	;is it a simple struct base?
	jnz anal4	;if so,
	call anal8a	;set asize = size of one structure
anal3a:	xra a		;can't assign or do math to it.
	sta asnokf
	sta amathf
	ret

anal4:	call tptrf	;pointer to function?
	rz		;all set if so.

anal5:	call tfun	;is it a function?
	jz anal11	;if so, set stuff appropriately.
	mvi a,1		;else, must be a variable address.
	sta avar
	lda typ1
	ora a
	rz		;if char, return with asize = 1
anal5a:	lxi h,asize
	inr m		;else bump asize to 2
	ret

anal6:	call t2dim	;2-dimensional array?
	jnz anal7
	lhld dimsz1	;yes. scale size of obj by 1st dim size
	shld subval
anal7:	lda typ1
	ani 20h		;pointer to function?
	jnz anal7a
	lda indc1	;no.
	cpi 3		;if pointer to pointer...
	jnc anal7a
	call tstar	;array of pointers?
	jnz anal8
	lda indc1
	cpi 2
	jnz anal8
anal7a:	lxi h,2		;double object size
	call mult
	jmp anal10

anal8:	lda typ1	;structure?
	cpi 6
	jnz anal9

anal8a: lhld strsz1	;yes. scale obj size by size of struct
	call getsz	;look up size in symbol table
	call mult	;multiply by old object size
	jmp anal10

anal9:	ora a		;character?
	jz anal10
	lxi h,2		;no. must be 2-byte object.
	call mult
anal10:	lhld subval	;at last we have a final size.
	shld asize	;(subval was just an accumulator for
	call tstar	; the mult routine.)
	rnz		;if not array, all done.
	lda frml1	;if so, only allow it to be assigned to
	ora a		;if it isn't a formal parameter.
	rnz
anal11:	xra a
	sta asnokf	;woops, its formal. Disallow assignment
	ret

;
; Perform same analysis for 2nd operand, leaving
; 1st operand info intact:
;

anal2:	call pshn1
	call mvn21
	call analyz
	call ppn1
	ret


;
; Perform internal indirection on the object as characterized
; above. By "internal" I mean that no code is generated;
; rather, pointers become lvalues, 2-dim arrays become 1-dim
; arrays, etc. Error if object isn't SOME kind of object that
; can have indirection performed on it; i.e, a constant.
;

indir:	push h
	call ind1
	pop h
	ret

ind1:	call tstar	;array?
	jnz ind3
	call t2dim	;yes. 2-dim?
	lxi h,0
	jnz ind2
	lxi h,0ff00h	;yes. change into 1-dim
ind2:	shld dimsz1
	ret

ind3:	call tptrf	;pointer to function?
	jnz ind4
	lda typ1	;yes. make into an actual function
	ani 0dfh	;strip off ptr to func bit
	ori 40h		;turn on function bit
	sta typ1	;and store new type
	xra a
	sta simpf	;NOT a simple function instance!
	ret

ind4:	call tfun	;is it a function?
	jz ind5		;if so, bad news.
	call tptr	; a pointer?
	jnz ind5
	lda indc1	;yes. de-bump indirection count by 1.
	dcr a
	sta indc1
	ret

ind5:	lxi d,stg21	;something is screwy in the state of
	jmp perr	;confusion. (?)


;
; Type Testing functions....each of the following routines
; tests for some particular property, and returns Z true if
; the property is true for the expression described by
; INDC1,TYP1,etc...
;

tstar:	call tfun	;is expr an array?
	jz invrt	;if function, then not array.
	push h		;look at dim size.
	lhld dimsz1
	mov a,h
	ora l
	pop h		; now Z set if NOT array

invrt:	jz invrt2	;invert Z flag.
	xra a		; if wasn't zero,
	ret		; set zero and return.
invrt2:	xra a		;else reset zero by clearing
	inr a		;and incrementing A.
	ret

;
; Test if expr is a 2 dimensional array
;

t2dim:	call tstar	;array?
	rnz		;if not, certainly not a 2-dim array.
	lda dimsz1+1	;else look at high byte of dim size
	cpi 0ffh	;this is special code for 1-dim array
	jmp invrt	;if 1-dim, not 2-dim, and vice versa!

;
; Test if expr is a pointer to function (special case)
;

tptrf:	call tstar	;an array?
	jz invrt	;if so, not pointer to function
	call tfun	;if function,
	jz invrt	;not a pointer to one!
	lda typ1	;else look at the crucial bit
	ani 20h
	jmp invrt	;if set, then is a pointer to function

;
; Test if expr is any kind of pointer (including an array)
;

tptr:	call tfun	;function?
	jz invrt	;if so, not a pointer.
	call tptrf	;pointer to function?
	rz		;if so, definitely a pointer
	call tstar	;array?
	rz		;if so, implicitly a pointer.
	lda indc1	;else check indirection count
	cpi 2
	rc		;if <2, not pointer.
	xra a		;else is a pointer.
	ret

;
; Same as above for operand 2:
;

tptr2:	call pshn1
	call mvn21
	call tptr
	call ppn1
	ret

;
; Test if expr is a simple pointer (not pointer-to-pointer)
;
  
tsptr:	call tfun	;if function,
	jz invrt	;not pointer.
	call t2dim	;2-dim array?
	jz invrt	;if so, not simple pointer
	call tstar	;array?
	rz		;if so, simple pointer.
	call tptrf	;pointer to function?
	rz		;if so, simple pointer.
	lda indc1	;check indirection count
	cpi 2		;if == 2, simple pointer.
	ret

;
; Test if expr is simple value (not address):
;

tsval:	call tstar	;if array,
	jz invrt	;not value.
	call tfun
	jz invrt	;no functions allowed.
	call tptr
	jz invrt	;no pointer either.
	call tsstr	;structure?
	jz invrt	;if so, sorry.
	lda indc1
	ora a		;true only if no indirection.
	ret

;
; Same as above for 2nd operand:
;

tsval2:	call pshn1
	call mvn21
	call tsval
	call ppn1
	ret

;
; Test if simple character value
;

tschr:	call tsval	;if not simple value, not likely to
	rnz		;be simple char value!
	lda typ1
	ora a
	ret		;else is only if type is char.

;
; Same for 2nd operand
;

tschr2:	call tsval2
	rnz
	lda typ2
	ora a
	ret


;
; Test if expr is structure base
;

tsstr:	call tstar
	jz invrt	;if array, not structure.
	lda typ1
	cpi 6
	rnz		;if not struct, no good.
	lda indc1
	cpi 2
	jc tstr1	;pointer?
	xra a		;yes. no good.
	inr a	
	ret
tstr1:	xra a		;no pointer; ok.
	ret


;
; Test if expr is a function
;

tfun:	lda typ1
	ani 40h		;look at function bit.
	jmp invrt	;if set, is a function.

;
; Test if expr is simple pointer to characters
;

tsptrc:	call tsptr	;simple pointer?
	rnz		;if not, no good.
	call tptrf	;pointer to function?
	jz invrt	;if so, not pointer to char.
	lda typ1
	ora a
	ret		;true only if type == char.

;
; Test if simple lvalue (as opposed to array or pointer)
;

tslv:	call tstar
	jz invrt	;arrays no good
	call tptrf
	jz invrt	;neither are ptrs to funcs
	lda indc1
	dcr a
	rnz		;no good if not lvalue
	lda typ1
	cpi 6
	jmp invrt	;and no good if struct.

;
; Test if simple character lvalue
;

tsclv:	call tslv
	rnz		;no good if not simple lvalue
	lda typ1
	ora a
	ret		;or if type not char

;
; The following routines "check" for some property, and
; spew an error message if the property is found to be
; lacking...
;

;
; Test to see if expr is a pointer or a value, and give
;   "Bad use of unary op" error if not. Obviously, this
;   routine is called from the unary operator processor.
;

ckaok:	call tptr	;pointer?
	rz		;if so, OK

; This is the entry point for the check for "simple value only"

ckval:	call tsval	;simple value?
	rz		;if so, OK
	lxi d,stg13
	jmp perr


;
; If A==2, it means that an lvalue was called for from an
; operator which cannot provide it. Bad news.
;

ckvok:	cpi 2
	rnz
	lxi d,stg8
	call perr

;
; Give an error if both operands are not simple values.
;

ckval2:	call tsval	;is 1st a value?
	jnz ckv2e	;if not, trouble.
	call pshn1	;save info on 1st operand
	call mvn21	;give 1st operand 2nd operand's info
	call tsval	;so we can call tsval.
	call ppn1	;restore 1st operand's info
	rz		;return if 2nd operand was value
ckv2e:	lxi d,stg18	;woops.
	jmp perr

;
; Logical branch table handler routines:
;

ltabmp:	push d		;bump ltab with new entry
	push h
	lhld ltabp	;get logical table pointer  in HL
	xchg		;put in DE

	lxi h,ltabp-5	;get pointer to end of logical table in HL
	call cmpdh	;make sure pointer is well below end of table
	jc ltbmp2	;if so, no problem...
	lxi d,stgcsn	;control structure too deeply nested
	jmp perrab
	
ltbmp2:
	call glbl
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	xchg
	call glbl
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	mvi m,0
	inx h
	shld ltabp
	pop h
	pop d
	ret

;
; Define true label at current position in code, if used bit
; for that entry is set:
;

ltabtd:	push h
	push d
	lhld ltabp
	dcx h
	mov a,m
	ani 1
	jz ltbtd1
ltbtd0:	dcx h
	dcx h
	dcx h
	mov d,m
	dcx h
	mov e,m
	call entl
ltbtd1:	pop d
	pop h
	ret

;
; Force definition of true ltab entry:
;

fltbtd:	push h
	push d
	lhld ltabp
	dcx h
	jmp ltbtd0

;
; Define false label entry if appropriate used bit is set:
;

ltabfd:	push h
	push d
	lhld ltabp
	dcx h
	mov a,m
	ora a
	jp ltbfd1
ltbfd0:	dcx h
	mov d,m
	dcx h
	mov e,m
	call entl
ltbfd1:	pop d
	pop h
	ret

;
; Force definition of false label entry:
;

fltbfd:	push h
	push d
	lhld ltabp
	dcx h
	jmp ltbfd0

;
; Pop last entry off the ltab:
;

ltabpp:	push h
	push d
	lhld ltabp
	lxi d,-5
	dad d
	shld ltabp
	pop d
	pop h
	ret

;
; Convert logical flag setting to value in DE:
;

cvtlvd:	lda sval1
	ani 4
	rz		;ignore if no flag set
	lda sval1	;(just fixed:OK -lz)
	ani 20h		;if already have a value, put into DE if not 
	jz cvtvd1	;already there. so, do we have a value?
	lda sval1
	ani 0c0h	;yes. is it already in DE?
	rnz
	call gxchg	;no, put it there
	lda sval1
	ori 40h
	sta sval1	;tell that it's in DE
	ret
	
cvtvd1:	lda sbmap1	;else get the flag setting
	ani 7
	adi 6
cvtvd2:	push d
	mov e,a
	mvi d,0
	push h
	lxi h,flagct
	dad d
	dad d
	mov e,m
	inx h
	mov d,m
	call mcrog
	pop h
	pop d
	mvi a,1
	sta typ1
	lda sval1
	ori 60h		;tell that we have a value in addition to
	sta sval1	;a flag setting.
	ret

;
; Convert logical flag setting to value in HL:
;

cvtlvh:	lda sval1
	ani 4
	rz
	lda sval1	;do we already have a value in a reg?
	ani 20h
	jz cvtlh1
	lda sval1	;yes. if in HL, leave it there
	ani 0c0h
	rz
	call gxchg	;else put into HL
	lda sval1
	ani 3fh		;tell that result is in HL
	sta sval1
	ret

cvtlh1:	lda sbmap1
	ani 7
	call cvtvd2
	ani 3fh
	sta sval1
	ret

flagct:	dw macf1,macf2,macf3,macf4,macf4a,macf4b
	dw macf5,macf6,macf7,macf8,macf8a,macf8b

cjoptb:	db 0cah,0c2h,0dah,0d2h,0f2h,0fah,0c3h

;
; Generate conditional jump-on-true:
;

gncjt:	push h
	lhld ltabp
	dcx h
	mov a,m
	ori 1
	mov m,a
	dcx h
	dcx h
	dcx h
	mov d,m
	dcx h
	mov e,m
	xchg
	shld sr0
	lda sval1		;constant?
	ani 1
	jz gncjt2
	lhld svv1		;yes. do jump if true, else don't
	mov a,h
	ora l
	pop h
	rz
gncjt1:	mvi a,6
	jmp gncjt3

gncjt2:	lda sval1		;flag setting?
	ani 4
	pop h
	jz gncjt4
	lda sbmap1		;yes. find which one and do it.
	ani 7
gncjt3:	push h
	mov e,a
	mvi d,0
	lxi h,cjoptb
	dad d
	mov a,m
	call genb
	lxi d,mac36a
	call mcrog
	pop h
	ret

gncjt4:	lda sval1		;lvalue?
	ani 2
	jnz gncjt1		;if so, always generate a jump
	lda sval1		;value in DE?
	ani 0c0h
	jnz gncjt6		;if so, go handle
	lxi d,mac33		;do "mov a,h - ora l - jnz sr0" if not char
	call tschr
	jnz gncjt5
	lxi d,mac7a		;if char, do "mov a,l - ora a - jnz sr0"
gncjt5:	call mcrog
	ret

gncjt6:	lxi d,mac33d
	call tschr
	jnz gncjt5
	lxi d,mac7ad
	jmp gncjt5

;
; Generate conditional jump-on-false:
;

gncjf:	push h
	lhld ltabp
	dcx h
	mov a,m
	ori 80h
	mov m,a
	dcx h
	mov d,m
	dcx h
	mov e,m
	xchg
	shld sr0
	lda sval1		;constant?
	ani 1
	jz gncjf2
	lhld svv1		;yes. either jump or don't.
	mov a,h
	ora l
	pop h
	rnz
gncjf1:	mvi a,6
	jmp gncjt3

gncjf2:	lda sval1		;not a constant. flag setting?
	ani 4
	pop h
	jz gncjf4
	lda sbmap1		;yes. do appropriate cond'l jmp
	ani 7
	xri 1
	jmp gncjt3

gncjf4:	lda sval1		;not a flag or constant; must be value.
	ani 2
	rnz			;ignore if lvalue (can't be "false")
	lda sval1		;value in DE?
	ani 0c0h
	jnz gncjf6		;if so, go handle
	lxi d,mac0d		;do "mov a,h - ora l - jz sr0" if not char
	call tschr
	jnz gncjf5
	lxi d,mac07		;use "mov a,l - ora a - jz sr0" if char
gncjf5:	call mcrog
	ret

gncjf6:	lxi d,mac0dd
	call tschr
	jnz gncjf5
	lxi d,mac07d
	jmp gncjf5


;
; "Or" the current and last "false-label-used" bits:
;

ltabfo:	push h
	lhld ltabp
	dcx h
	mov a,m
	ani 80h
ltbfo1:	dcx h
	dcx h
	dcx h
	dcx h
	dcx h
	ora m
	mov m,a
	pop h
	ret

;
; "Or" the current and last "true-label-used" bits:
;

ltabto:	push h
	lhld ltabp
	dcx h
	mov a,m
	ani 1
	jmp ltbfo1

;
; Routine to generate a forward jump and push the label value
; used on the stack before returning:
;

gfjmp:	xthl		;put text pointer on stack, get HL = ret address
	shld retadd	;save return address
	push psw
	call glbl	;get a label
	shld sr0
	pop psw
	xthl		;put it on stack, get text pointer back in HL
	push psw
	lxi d,mac36
	call mcrog	;generate the jump
	pop psw
	push h		;save text pointer
	lhld retadd	;get return address
	xthl		;put ret addr on stack, get HL=text pointer 	
	ret		;and all done. Tricky, huh?	

;
; Routine to pop label value off stack and define the label at the
; current code position:
;

plvdl:	xthl		;get return address in HL, put text pointer on stack
	shld retadd	;save return address
	pop h		;get HL = text pointer
	pop d		;get label value in DE
	push h		;put text pointer back on stack
	push psw
	call entl	;enter the label value
	pop psw
	lhld retadd	;get return addr back in HL
	xthl		;push ret address on stack, get HL = text ptr
	ret		;all done.

;
; Routine to get a new symbolic label, define it at current position
; in code, and push it on the stack for later use:
;

glvdl:	xthl		;put text ptr on stack, get HL = ret addr
	shld retadd	;save return address
	push psw
	call glbl	;get a new label
	xchg		;put in DE
	call entl	;define it here
	xchg		;put label value back in HL
	pop psw
	xthl		;push label on stack, get HL = text pointer
	push h		;push text pointer on stack
	lhld retadd	;get return address
	xthl		;put ret addr on stack, get HL = text ptr
	ret		;all done.
	
;
; Routine to pop a label value off the stack and generate a jump
; to it:
;

plvgj:	xthl		;get ret addr in HL, push text ptr on stack
	shld retadd	;save return address
	pop d		;get back text ptr in DE
	pop h		;get label value to generate jump to in HL
	shld sr0
	xchg		;put text pointer back in HL
	lxi d,mac36
	call mcrog	;generate the jump
	push h		;save text pointer on stack
	lhld retadd	;get return address
	xthl		;put ret addr on stack, get text ptr back in HL
	ret		;all done.

;
; Routine to flush info1 into HL; i.e, make sure that the object
; evaluated into info1 has a value generated in the HL register:
;

flshh1:	push psw
	push b
	lda sval1
	mov b,a
	push h
	lhld svv1
	shld sr0
	pop h
	mov a,b		;constant of some kind?
	ani 3
	jz fls1a
	mov a,b		;yes. simple constant?
	ani 1
	jz fls0
	lxi d,mac04	;yes. do lxi h,sr0
	call mcrog
fls00:	xra a
	sta sval1
	jmp fls1c

fls0:	mov a,b		;relative lv const. local?
	ani 8
	jnz fls0a
	call genllv	;yes.
	jmp fls00

fls0a:	lxi d,mac6a	;no: external
	call mcrog
	push h
	lhld svv1
	xchg
	call maddd
	pop h
	jmp fls00

fls1a:	mov a,b		;flag setting?
	ani 4
	jz fls1b

fls1v:	call cvtlvh	;yes. turn it into a value in HL (if
	jmp fls00

fls1b:	mov a,b		;value in DE ?
	ani 0c0h
	jz fls1c
	call gxchg	;yes. do 'xchg'
	jmp fls00

fls1c:	pop b		;fine as it is.
	pop psw
	ret


;
; Flush info1 into DE:
;

flshd1:	push psw
	push b
	lda sval1
	mov b,a
	push h
	lhld svv1
	shld sr0
	pop h
	mov a,b
	ani 3
	jz flsd1a
	mov a,b
	ani 1
	jz flsd0
	lxi d,mac4a
	call mcrog
	jmp flsd00

flsd0x:	call gxchg
flsd00:	mvi a,40h
	sta sval1
	jmp flsd1c

flsd0:	mov a,b
	ani 8
	jnz flsd0a
	call genllv
	jmp flsd0x

flsd0a:	lxi d,mac6a
	call mcrog
	push h
	lhld svv1
	xchg
	call maddd
	pop h
	jmp flsd0x

flsd1a:	mov a,b
	ani 4
	jz flsd1b
flsd1v:	call cvtlvd
	jmp flsd00

flsd1b:	mov a,b
	ani 0c0h
	jz flsd0x
flsd1c:	pop b
	pop psw
	ret

flshh2:	call pshn1
	call mvn21
	call flshh1
	call mvn12
	call ppn1
	ret

flshd2:	call pshn1
	call mvn21
	call flshd1
	call mvn12
	call ppn1
	ret

;
; Put info1 value into DE if currently in HL:
;

pn1ind:	push b
	push psw
	lda sval1
	mov b,a
	ani 4
	jnz flsd1v
	mov a,b
	ani 3
	jnz flsd1c
	jmp flsd1b

;
; Put info1 value in HL if in DE:
;

pn1inh:	push b
	push psw
	lda sval1
	mov b,a
	ani 4
	jnz fls1v
	mov a,b
	ani 3
	jnz flsd1c
	jmp fls1b


pn2ind:	call pshn1
	call mvn21
	call pn1ind
	call mvn12
	call ppn1
	ret


;
; Push Optimization handlers:
;

rpshp:	push h
	push psw
	push b
	lhld pshpp
	mov a,m		;get pushop flag at current level
	ani 8
	mov b,a		;save masked off register designator bit in B
	mov a,m		;get back flag
	inx h
	ani 0a0h
	jz rpsh1
	mvi a,20h
	ora b
rpsh1:	pop b
rpsh2:	mov m,a
	shld pshpp
	pop psw
	pop h
	ret

spshp:	push h
	push psw
	lhld pshpp
	mov a,m
	ani 3fh
	ori 80h		;set push bit, but preserve pushed bits (b4)
	call orinrg	;set b3 if DE holds value that needs to be pushed
	mov m,a		;set current level push-op flag to "set"
	inx h		;now set next level for subordinate routine
	mvi a,20h	;lower-level "set push-op"
	call orinrg	;or in the register designation
	jmp rpsh2	;and go set in the pushop table.

orinrg:	push b		;set b3 if sval1 indicates DE holds value
	mov b,a
	lda sval1
	ani 0c0h
	mov a,b
	pop b
	rz
	ori 8
	ret

ppshp:	push h
	push psw
	lhld pshpp
	mov a,m
	dcx h
	ani 50h
	jz ppsh2
	mov a,m
	ani 80h
	jz ppsh1
	mov a,m
	ani 3fh
	ori 40h
	jmp rpsh2
ppsh1:	mov a,m
	ani 0c0h
	ori 10h
	jmp rpsh2
ppsh2:	mov a,m
	ani 7fh
	mov m,a
	shld pshpp
	pop psw
	pop h
	ret

tpshd:	push h
	lhld pshpp
	mov a,m
	pop h
	ani 40h
	jmp invrt

genpsh:	push b
	mov b,m
	cpi 80h
	mvi a,40h
	jz genp2
	mvi a,10h
genp2:	mov m,a
	mov a,b
	ani 08h
	mvi a,0e5h
	jz genp3
	mvi a,0d5h
genp3:	call genb
	pop b
	ret

;
; Special hacks to generate come super-common op codes:
;

gpushh:	push psw
	mvi a,0e5h
gpshh1:	call genb
	pop psw
	ret

gpoph:	push psw
	mvi a,0e1h
	jmp gpshh1

gpushd:	push psw
	mvi a,0d5h
	jmp gpshh1

gpopd:	push psw
	mvi a,0d1h
	jmp gpshh1

gxchg:	push psw
	mvi a,0ebh
	jmp gpshh1

tcnst1:	lda sval1
	ani 3
	jmp invrt

tcnst2:	lda sval2
	ani 3
	jmp invrt


;
; The actual macros:
;

	IF I80
mcend:	equ 38h		;end of macro: mcend
mcerp:	equ 0cbh	;enter relocation parameter: mcerp 
mcesr:	equ 0efh	;enter symbolic reference: mcesr <srn>

mcsr0:	equ 8h		;substitute value in sr0
mcsr1:	equ 10h		;		  in sr1
mcsr2:	equ 18h		;		  in sr2
mcsr3:	equ 20h		;		  in sr3
mcsr4:	equ 28h		;		  in sr4
mcsr5:	equ 30h		;		  in sr5

mcdr0:	equ 0c7h	;define label	in sr0
mcdr1:	equ 0cfh	;		in sr1
mcdr2:	equ 0d7h	;		in sr2
mcdr3:	equ 0dfh	;		in sr3
mcdr4:	equ 0e7h	;		in sr4

litrl:	equ 0f7h
	ENDIF




;
; The actual macros:
;

;
; New macro sequeces added for the 1.4 optimizer (especially the
; new alugen):
;

macih4:	inx h
macih3:	inx h
macih2:	inx h
macih1:	inx h
	db mcend

macid4:	inx d
macid3:	inx d
macid2:	inx d
macid1:	inx d
	db mcend

macdh4:	dcx h
macdh3:	dcx h
macdh2:	dcx h
macdh1:	dcx h
	db mcend

macdd4:	dcx d
macdd3:	dcx d
macdd2:	dcx d
macdd1:	dcx d
	db mcend

mache5:	dcx h
mache4:	dcx h
mache3:	dcx h
mache2:	dcx h
mache1:	dcx h
mache0:	mov a,h
	ora l
	db mcend

macde5:	dcx d
macde4:	dcx d
macde3:	dcx d
macde2:	dcx d
macde1:	dcx d
macde0:	mov a,d
	ora e
	db mcend

mchen5:	inx h
mchen4:	inx h
mchen3:	inx h
mchen2:	inx h
mchen1:	inx h
	mov a,h
	ora l
	db mcend

mcden5:	inx d
mcden4:	inx d
mcden3:	inx d
mcden2:	inx d
mcden1:	inx d
	mov a,d
	ora e
	db mcend

mcddd1:	xchg
	dad h
	db mcend

mcddd2:	xchg
	dad h
	dad h
	db mcend

mcddd3:	xchg
	dad h
	dad h
	dad h
	db mcend

mcddd4:	xchg
	dad h
	dad h
	dad h
	dad h
	db mcend

mcddd5:	xchg
mcddh5:	dad h
mcddh4:	dad h
mcddh3:	dad h
mcddh2:	dad h
mcddh1:	dad h
	db mcend

mac0ca:	dad d
	db mcend

macsb1:	db 11h,mcsr2,19h,mcend		;lxi d,sr2-dad d

mcsb1a: db 11h,mcsr2,19h,7ch,0b5h,mcend	;lxi d,sr2-dad d-mov a,h-ora l

macsb2:	db 21h,mcsr2,19h,mcend		;lxi h,sr2-dad d

mcsb1b:	db 21h,mcsr2,19h,7ch,0b5h,mcend	;lxi h,sr2-dad d-mov a,h-ora l

macsb3:	db 0cdh				;call cmh-dad d
	db litrl
	dw cmhl
	dad d
	db mcend

macsb4:	db 0cdh				;call cmd-dad d
	db litrl
	dw cmd
	dad d
	db mcend

macsb5:	db 11h,mcsr4,19h,mcend		;lxi d,sr4-dad d
macsb6:	db 21h,mcsr4,19h,mcend		;lxi h,sr4-dad d

macsb7:	db 11h,mcsr4		;lxi d,sr4
	dad d
	mov a,h
	ral
	db mcend

macsb8:	db 21h,mcsr4		;lxi h,sr4
	dad d
	mov a,h
	ral
	db mcend

macsb9:	db 11h,mcsr2		;lxi d,sr2
	dad d
	mov a,h
	ral
	db mcend

macsba:	db 21h,mcsr2		;lxi h,sr2
	dad d
	mov a,h
	ral
	db mcend

macac1:	xra a
	mov m,a
	inx h
	mov m,a
	db mcend

macac3:	db 11h,mcsr0		;lxi d,sr0
	mov m,e
	inx h
	mov m,d
	db mcend

macac4:	mov m,e
	inx h
	mvi m,0
	db mcend

macac5:	mvi d,0
	mov m,e
	inx h
	mov m,d
	db mcend

macacb:	db 32h,mcsr0,mcend		;sta sr0

macacc:	db 21h,mcsr1,22h,mcsr0,mcend	;lxi h,sr1-shld sr0


;
; Macros for function entry and exit:
;

		;entry code for frame size non-zero OR  formal parms
mfntry:	push b
	db 21h,mcsr0	;lxi h,sr0
	dad sp
	sphl
	mov b,h
	mov c,l
	db mcend

		;as above, but no sphl 'cause frame size is 0. This
		; is just to set new BC value. entire system could
		;use improvment, say to know to just dcx b twice for
		;each parameter up until 2...
mfntr2:	push b	
	db 21h, mcsr0	;lxi h,sr0
	dad sp
	mov b,h
	mov c,l
	db mcend


mfex1:	db mcdr1	;define exit label
	db mcend

		;exit code for frame size > 6
mfex2:	xchg
	db 21h,mcsr0	;sr1: xchg - lxi h,sr0 -
	dad sp			
	sphl
	xchg
mfex3:	pop b	;used in stret: routine for quick return (n);
mfex4:	ret	;processing when not at end of function
	db mcend


;
; Macros for ++ and -- operator processing:
;

m12:	inr m
	mov l,m
	db mcend

m12a:	inr m
	db mcend

m13:	mov a,m
	inr m
	mov l,a
	db mcend

m14:	dcr m
	mov l,m
	db mcend

m14a:	dcr m
	db mcend

m15:	mov a,m
	dcr m
	mov l,a
	db mcend

m16b:	mov e,m
	inx h
	mov d,m
	inx d
	mov m,d
	dcx h
	mov m,e
	db mcend

m16bz:	rst 7		;substitute for m16b if -z7 in effect
	inx d
	mov m,d
	dcx h
	mov m,e
	db mcend

me16b:	db 2ah,mcsr0	 	;lhld sr0- inx h- shld sr0
	inx h
	db 22h,mcsr0
	db mcend

m18:	mov e,m
	inx h
	mov d,m
	dcx d
	mov m,d
	dcx h
	mov m,e
	db mcend

m18z:	rst 7
	dcx d
	mov m,d
	dcx h
	mov m,e
	db mcend

me18:	db 2ah,mcsr0,2bh,22h,mcsr0,mcend	; lhld sr0- dcx h- shld sr0

m20:	mov e,m
	inx h
	mov d,m
	db mcend

m20z:	rst 7
	db mcend

m21:	push d
	db mcend

me21:	push h
	db mcend

m22:	inx d
	db mcend

me22:	inx h
	db mcend

m23:	dcx d
	db mcend

me23:	dcx h
	db mcend

m26:	push h
	db 21h,mcsr0		;lxi h,sr0
	dad d
	xchg
	pop h
	db mcend

me26:	db 11h,mcsr1,19h,mcend	; lxi d,sr1- dad d

m27:	db 7bh,mcsr1,5fh,7ah,mcsr2,57h,mcend
				; mov a,e-sr1-mov e,a-mov a,d-sr2-
				; mov d,a  (sr1 and sr2 will contain
				; code sequences like `sui value')

me27:	db 11h,mcsr2	;lxi d,sr2
	dad d
	db mcend

m28:	mov m,d
	dcx h
	mov m,e
	db mcend

m30:	pop d
	db mcend

me30:	pop h
	db mcend

mnul:	db mcend			; null (generates nothing)

macn:	equ mnul		; an alias for `null'

;
; Misc. utility sequences:
;

mac6e:	mov l,m
	db mcend

mac38:	db 0c3h,0,0,mcend		; jmp 0	(used to create the jump
				; vector at start of functions)

mac40:	db 2ah,mcsr0,mcend		; lhld sr0

mac40r:	db 2ah,mcerp,mcsr0,mcend	; lhld sr0 (relocate the address)

mac41:	db 21h,mcsr0,9,mcend		; lxi h,sr0-dad b

mac42:	mov m,e
	inx h
	mov m,d
	db mcend

mcn10:	equ mache0

mcn11:	mov a,l
	ora a
	db mcend

mcn12:	mov a,e
	ora a
	db mcend

mcn13:	mov a,h
	ora a
	db mcend

mcn14:	mov a,d
	ora a
	db mcend

macrdl:	mov a,d
	ral
	db mcend

macrhl:	mov a,h
	ral
	db mcend

mac0d:	mov a,h
	ora l
	db 0cah,mcesr,mcsr0,mcend ; jz foo

mac33:	mov a,h
	ora l
	db 0c2h,mcesr,mcsr0,mcend ; jnz foo


mac07:	mov a,l
	ora a
	db 0cah,mcesr,mcsr0,mcend   ; mov a,l-ora a-jz sr0

mac0dc:	equ mac07		; another alias

mac7a:	mov a,l
	ora a
	db 0c2h,mcesr,mcsr0,mcend   ; mov a,l-ora a-jnz sr0

mac33c:	equ mac7a		; gotta get that ole' USE FACTOR up there!

mac33d:	mov a,d
	ora e
	db 0c2h,mcesr,mcsr0,mcend	;jnz sr0

mac0dd:	mov a,d
	ora e
	db 0cah,mcesr,mcsr0,mcend	;jz sr0

mac7ad:	mov a,e
	ora a
	db 0c2h,mcesr,mcsr0,mcend	;jnz sr0

mac07d:	mov a,e
	ora a
	db 0cah,mcesr,mcsr0,mcend	;jz sr0

mac35:	db mcsr0,0bdh,0c2h,mcesr,mcsr1,mcsr2
	db 0bch,0cah,mcesr,mcsr3,mcdr1,mcend
				; sr0-cmp l-jnz bar-sr1-cmp h-
				; jz sr3-bar: ...

mac35d:	db mcsr0,0bbh,0c2h,mcesr,mcsr1,mcsr2
	db 0bah,0cah,mcesr,mcsr3,mcdr1,mcend
				; sr0-cmp e-jnz bar-sr1-cmp d-
				; jz sr3-bar: ...

mac35c:	db mcsr0,0cah,mcesr,mcsr3,mcend
				; sr0-jz sr3

mac71c:	mov a,l
	cmp e
	db mcend

mac36:	db 0c3h,mcesr,mcsr0,mcend	; jmp sr0

mac36a:	db mcesr,mcsr0,mcend		; just "sr0", with a relocation parm

mac37:	equ mac36		; alias for mac36

maca0:	mov a,m
	inx h
	mov h,m
	mov l,a
	db mcend

mac04:	db 21h,mcsr0,mcend		; lxi h,sr0

mac4a:	db 11h,mcsr0,mcend		; lxi d,sr0

mac6a:	db 2ah			; lhld extbas
	db litrl		; (gets base-of-external-data-area
	dw extbas		; pointer into HL)
	db mcend


mac09:	db 22h,mcsr0,mcend		; shld sr0

;
; Macros for function call generation
;

mac08:	db 0cdh,mcerp,mcsr3,mcend    ; call sr3  (note the `cb'
				; causes a reloc parameter to be generated)
				;(Note: this is the code generated for
				;function calls)

mac8a:	db 21h,mcesr,mcsr2	; lxi h,foo
	push h
	db 21h,mcsr1		; lxi h,sr1
	dad sp
	mov a,m
	inx h
	mov h,m
	mov l,a
	pchl
	db mcdr2,mcend		; foo: ...
				;(generated for calls to non-simple funcs)

mac8ar:	xchg
	db 21h,mcsr0	; lxi h,sr0
	dad sp
	sphl
	xchg
	db mcend		;(cleans up stack on return from func call)

;
; More misc. stuff:
;

mac61:	mvi h,0
	db mcend

mac62:	mvi d,0
	db mcend

maca1:	mov m,e
	inx h
	mov m,d
	db mcend

maca9:	mov m,e
	inx h
	xra a
	mov m,a
	db mcend

;
; Here are some macros to generate calls to routines
; within the C.CCC runtime utility package:
;

macf1:	db 0cdh		;call pzinh
	db litrl
	dw pzinh
	db mcend

macf2:	db 0cdh		;call pnzinh
	db litrl
	dw pnzinh
	db mcend

macf3:	db 0cdh		;call pcinh
	db litrl
	dw pcinh
	db mcend

macf4:	db 0cdh		;call pncinh
	db litrl
	dw pncinh
	db mcend

macf4a:	db 0cdh		;call ppinh
	db litrl
	dw ppinh
	db mcend

macf4b:	db 0cdh		;call pminh
	db litrl
	dw pminh
	db mcend

macf5:	db 0cdh		;call pzind
	db litrl
	dw pzind
	db mcend

macf6:	db 0cdh		;call pnzind
	db litrl
	dw pnzind
	db mcend

macf7:	db 0cdh		;call pcind
	db litrl
	dw pcind
	db mcend

macf8:	db 0cdh		;call pncind
	db litrl
	dw pncind
	db mcend

macf8a:	db 0cdh		;call ppind
	db litrl
	dw ppind
	db mcend

macf8b:	db 0cdh		;call pmind
	db litrl
	dw pmind
	db mcend


mcumul:
mac63u:	db 0cdh			; call usmul
	db litrl
	dw usmul
	db mcend

mcsmul:
mac63s:	db 0cdh			; call smul
	db litrl
	dw smul
	db mcend

mcdiv5:	xchg
mcudiv:
mac64u:	db 0cdh			; call usdiv
	db litrl
	dw usdiv
	db mcend

mcdiv7:	xchg
mcsdiv:
mac64s:	db 0cdh			; call sdiv
	db litrl
	dw sdiv
	db mcend

mcmod5:	xchg
mcumod:
mac79u:	db 0cdh			; call usmod
	db litrl
	dw usmod
	db mcend

mcmod7:	xchg
mcsmod:
mac79s:	db 0cdh			; call smod
	db litrl
	dw smod
	db mcend

mcalbu:
mac68:	db 0cdh			; call albu (DE < HL unsigned?)
	db litrl
	dw albu
	db mcend

mcagbu:
mac69:	db 0cdh			; call agbu (DE > HL unsigned?)
	db litrl
	dw agbu
	db mcend

mcalbs:
mac68s:	db 0cdh			; call albs (DE <= HL signed?)
	db litrl
	dw albs
	db mcend

mcagbs:
mac69s:	db 0cdh			; call agbs (DE > HL signed?)
	db litrl
	dw agbs
	db mcend

mcbgau:	db 0cdh
	db litrl
	dw bgau
	db mcend

mcbgas:	db 0cdh
	db litrl
	dw bgas
	db mcend

mcblau:	db 0cdh
	db litrl
	dw blau
	db mcend

mcblas:	db 0cdh
	db litrl
	dw blas
	db mcend


mceq:
mac71:	db 0cdh			; tests equality of DE and HL
	db litrl
	dw eqwel
	db mcend

maccom:	db 0cdh			;2's complement HL
	db litrl
	dw cmhl
	db mcend

maccmd:	db 0cdh			;2's complement DE
	db litrl
	dw cmd
	db mcend

macsad:	equ mac0ca

macslh:	db 0cdh,litrl		;shift HL left by E bits
	dw shllbe
	db mcend

macsld:	db 0cdh,litrl		;shift DE left by L bits
	dw sdelbl
	db mcend

macsrh:	db 0cdh,litrl		;shift HL right by E bits
	dw shlrbe
	db mcend

macsrd:	db 0cdh,litrl		;shift DE right by L bits
	dw sderbl
	db mcend

mcssbh:	db 0cdh,litrl		;subtract HL from DE, result in HL
	dw cmhl			;call cmhl
	dad d
	db mcend

mcssbd:	db 0cdh,litrl		;subract DE from HL, result in HL
	dw cmd
	dad d
	db mcend


;
; bitwise operator macros:
;

mcand:
mac73:	mov a,h
	ana d
	mov h,a
	mov a,l
	ana e
	mov l,a
	db mcend

mcxor:
mac74:	mov a,h
	xra d
	mov h,a
	mov a,l
	xra e
	mov l,a
	db mcend

mcor:
mac75:	mov a,h
	ora d
	mov h,a
	mov a,l
	ora e
	mov l,a
	db mcend

mac0a:	db 11h,mcsr0,0cdh		; lxi d,sr0-call usmul
	db litrl		;  (used for subscript calculation)
	dw usmul
	db mcend

mac0c:	db 11h,mcsr0	; lxi d,sr0
	dad d
	db mcend

mac98a:	db 21h,mcesr,mcsr0,mcend  ;lxi h,foo (foo to be defined later on)

mac98:	db 21h,mcesr,mcsr0	;lxi h,foo
	db 0c3h,mcesr,mcsr1	;jmp sr1
	db mcdr0,mcend		; foo:

mac01:	mov a,l
	cma
	mov l,a
	inr l
	mvi h,0ffh
	db mcend

mac0e:	db 0cdh
	db litrl
	dw cmhl
	db mcend

macad1:	db 0e5h,21h,mcsr0,0cdh	; push h-lxi h,sr0-
	db litrl		; call usmul
	dw usmul		; (used to scale value in DE before
	pop d
	db mcend		; adding it to pointer in HL)

macd1a:	xchg
	dad h
	xchg
	db mcend

macad2:	db 0d5h,11h,mcsr0,0cdh	; push d-lxi d,sr0-
	db litrl		; call usmul
	dw usmul		; (used to scale value in HL before
	pop d
	db mcend		; adding it to pointer in DE)

macad3:	xchg
	db 21h,mcsr0,0cdh	; xchg-lxi h,sr0-
	db litrl		; call usdiv
	dw usdiv		; (used to scale result after two
	db mcend			; pointers are subtracted

macad4:	xra a
	mov a,h
	rar
	mov h,a
	mov a,l
	rar
	mov l,a
	db mcend

mac1a:	mov a,l
	cma
	mov l,a
	mvi h,0ffh
	db mcend

mac1b:	mov a,l
	cma
	mov l,a
	mov a,h
	cma
	mov h,a
	db mcend

mac05:	db 21h,mcerp,mcsr0	; lxi h,sr0
	db mcend		; (creates a relocation parameter for
				;  the data field of the lxi)


mac65m:	equ mcssbh		; HL <-- DE - HL

mac65b:	equ macsrd		; >>

mac67:	equ macsld		; <<

;
; **** END OF MACROS ****
;

	IF LASM
	link cc2e
	ENDIF
