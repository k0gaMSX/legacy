

;
; cc2c.asm:
;
; This is the binary expression special case list interpreter
; for version 1.4:
;

spcash:	push psw
	call spcs2
	pop psw
	ret

spcs2:	lhld svv1	;if INFO1 is the constant:
	shld sr0	;<constant value> into sr0
	call cmh
	shld sr2	;-<constant value> into sr2
	dcx h
	shld sr4	;-<constant value + 1> into sr4

	lda sval2
	sta ssval
	call tcnst2
	jnz spcs2a
	lhld svv2	;if INFO2 is the constant:
	shld sr0	;<constant value> into sr0
	shld svv1
	call cmh
	shld sr2	;-<constant value> into sr2
	dcx h
	shld sr4	;-<constant value + 1> into sr4
	lda sval1
	sta ssval
spcs2a:	xchg
spcs3:	mov a,m
	ora a
	rz
	sta key
	mov b,a
	inx h
	mov e,m
	inx h
	mov d,m	
	inx h
	mvi c,0
	ani 7
	cpi 7
	jnz spcs3a
	push h
	call spcs2	;perform a recursive list evaluation
	pop h
	jz spcs3	;if not match found in subordinate list, resume search
	ret		;else a match was found - done.
	
spcs3a:	xchg
	shld spval
	xchg
	mov e,m
	inx h
	mov d,m
	inx h
	xchg
	shld spmac
	xchg
	ani 7
	dcr a		;key = 1?
	jnz sptst2

sptry1:	call tcnst1	;yes.
	jz sptr1a	;fit template?
	inr c		;no-commutative?
	mov a,b
	ani 20h
	jnz sptry3	;if so, go try key=3 case
	jmp spcs3	;else no match yet

sptr1a:	lda sval2	;fits key=1 template if info2 in HL
	ani 0c0h
	jnz spcs3
	jmp spfnd

sptst2:	dcr a		;key = 2?
	jnz sptst3
sptry2:	call tcnst1	;yes.
	jz sptr2a	;fit template?
	inr c		;no. commutative?
	mov a,b
	ani 20h
	jnz sptry4	;if so, try key=4	
	jmp spcs3	;else no match

sptr2a:	lda sval2	;fits key=2 template if info2 in HL
	ani 0c0h
	jz spcs3
	jmp spfnd

sptst3:	dcr a		;key = 3?
	jnz sptst4
sptry3:	call tcnst2	;yes
	jnz spcs3	;no good unless info2 a constant
sptr3a:	lda sval1	;OK, good only if info1 in HL	
	ani 0c0h
	jnz spcs3
	jmp spfnd

sptst4:	dcr a		;key = 4?
	jnz sptst5
sptry4:	call tcnst2	;yes
	jnz spcs3	;good only if info2 is a constant
sptr4a:	lda sval1	;OK, good only if info1 in DE
	ani 0c0h
	jz spcs3
	jmp spfnd

sptst5:	push h		;set "constant value doesn't matter" flag
	lxi h,5500h
	shld spval	;this is so no auto-lxi is done
	pop h
	dcr a
	jnz sptst6	;key = 5?
	call tcnst1	;yes. check to make sure there are no constants
	jz spcs3
	call tcnst2
	jz spcs3
	mov a,b		;commutative?
	ani 20h
	jnz spfnd	;if so, we know enough to match
	jmp sptr3a	;else go check to make sure info1 is in HL

sptst6:	dcr a		;key = 6?
	cnz ierror	;better be!
	call tcnst1	;make sure we have no constants
	jz spcs3
	call tcnst2
	jz spcs3
	jmp sptr4a	;if OK, make sure info1 is in DE

spfnd:	push h
	lhld spval
	mov a,h
	cpi 55h		;wild card constant test?
	jz spgo		;if so, don't bother to compare constant values
	xchg		;no. must match value
	lhld svv1
	mov a,h
	cmp d
	jnz spfnd1
	mov a,l
	cmp e		;all 16 bits match?
	jz spgo		;if so, go do the special case!
spfnd1:	pop h		;no good. go for more list searching
	jmp spcs3

spgo:	mov a,l		;do we need to do an auto-lxi?
	cpi 55h
	jnz spgo1	;if not 55h, we DO NOT want to do it; else
	lxi d,mac04	;yes. do either lxi h,sr0 or lxi d,sr0
	lda ssval
	ani 0c0h
	jnz spgo0
	lxi d,mac4a
spgo0:	call mcrog
spgo1:	pop h
	lhld spmac	;get the macro
	xchg
	call mcrog	;do it

	mvi b,0		;now set all the resultant infox attributes
	lda key		;register B will accumulate new sval1 value
	mov c,a
	ani 8		;result in a register?
	jz spgo2
	mov a,c		;yes. if in DE, set b6 of reg B accordingly
	ora a
	jp spgo2
	mvi b,40h

spgo2:	mov a,c
	ani 10h		;result a flag?
	jz spgo3
	mov a,c		;yes. set bmap1 and reg B (sval1) accordingly
	rlc
	rlc
	ani 3
	sta sbmap1
	mvi b,4		;this becomes sval1--a flag setting.

spgo2a:	xra a	
	sta indc1
	sta typ1

spgo3:	mov a,c		;result a constant?
	ani 18h
	jnz spgo4
	mov a,c		;yes. FFFF?
	ani 0c0h
	lxi h,0ffffh
	cpi 0c0h
	jz spgo3a	;if so, go set
	inx h		;0000?
	ora a
	jz spgo3a	;if so, go set that
	inx h
	cpi 40h		;0001?
	cnz ierror	;if not, something's screwy in the state of confusion
spgo3a:	shld svv1
	mvi b,1

spgo4:	mov a,b		;set new sval1
	sta sval1
	xra a		;clear Z bit so we'll know we're done if this
	inr a		;is a recursive call to spcash
	ret

;
; The list structures representing all possible special cases of
; binary operators:
;

;
; First define some common constant values:
;

r:	equ 8h		;result in a register (key bit flag)
f:	equ 10h		;result is a flag (key bit flag)
con0:	equ 0		;result is constant value of 0
con1:	equ 40h		;result is constant value of 1
conff:	equ 0c0h	;result is constant value of FFFFh
fz:	equ f+000h	;result is Z flag set on true (Z true)
fnz:	equ f+040h	;result is Z flag reset on true (NZ true)
fc:	equ f+080h	;result is C flag set on true (C true)
fnc:	equ f+0c0h	;result is C flag reset on true (NC true)
k:	equ 20h		;operator is commutative
rd:	equ r+80h	;result in DE
rh:	equ r+00h	;result in HL
endlst:	equ 0		;end of list or sub-list

			;wild-card constant value entries:
dolxi:	equ 05555h	;do auto-lxi of constant value into free register
nolxi:	equ 05500h	;wild card value, but no lxi

smadd:	db 1+rh+k
	dw 0,mnul		; + operator

	db 2+rd+k
	dw 0,mnul

	db 1+rh	
	dw 1,macih1

	db 1+rh	
	dw 2,macih2

	db 1+rh	
	dw 3,macih3

	db 1+rh	
	dw 4,macih4

	db 1+rh	
	dw -1,macdh1

	db 1+rh	
	dw -2,macdh2

	db 1+rh	
	dw -3,macdh3

	db 1+rh	
	dw -4,macdh4

	db 2+rd	
	dw 1,macid1

	db 2+rd	
	dw 2,macid2

	db 2+rd	
	dw 3,macid3

	db 2+rd	
	dw 4,macid4

	db 2+rd	
	dw -1,macdd1

	db 2+rd	
	dw -2,macdd2

	db 2+rd	
	dw -3,macdd3

	db 2+rd	
	dw -4,macdd4

	db 1+rh+k
	dw dolxi,mac0ca

	db 2+rh+k
	dw dolxi,mac0ca

	db 5+rh+k
	dw nolxi,mac0ca

	db endlst


smsub:	db 1+rh	
	dw 0,mnul		; - operator

	db 2+rd	
	dw 0,mnul

	db 3+rh	
	dw 0,maccom

	db 4+rd	
	dw 0,maccmd

	db 1+rh	
	dw 1,macdh1

	db 1+rh	
	dw 2,macdh2

	db 1+rh	
	dw 3,macdh3

	db 1+rh	
	dw 4,macdh4

	db 1+rh	
	dw -1,macih1

	db 1+rh	
	dw -2,macih2

	db 1+rh	
	dw -3,macih3

	db 1+rh	
	dw -4,macih4

	db 2+rd	
	dw 1,macdd1

	db 2+rd	
	dw 2,macdd2

	db 2+rd	
	dw 3,macdd3

	db 2+rd	
	dw 4,macdd4

	db 2+rd	
	dw -1,macid1

	db 2+rd	
	dw -2,macid2

	db 2+rd	
	dw -3,macid3

	db 2+rd	
	dw -4,macid4

	db 1+rh	
	dw nolxi,macsb1

	db 2+rh	
	dw nolxi,macsb2

	db 3+rh	
	dw dolxi,macsb3

	db 4+rh	
	dw dolxi,macsb4

	db 5+rh	
	dw nolxi,mcssbh

	db 6+rh	
	dw nolxi,mcssbd

	db endlst


smmul:	db 1+con0+k
	dw 0,mnul		;common cases for both

	db 2+con0+k
	dw 0,mnul		;signed and unsigned

	db 1+rh+k
	dw 1,mnul		;multiplication

	db 2+rd+k
	dw 1,mnul

	db 1+rh+k
	dw -1,maccom

	db 2+rd+k
	dw -1,maccmd

	db 1+rh+k
	dw 2,mcddh1

	db 1+rh+k
	dw 4,mcddh2

	db 1+rh+k
	dw 8,mcddh3

	db 1+rh+k
	dw 16,mcddh4

	db 2+rh+k
	dw 2,mcddd1

	db 2+rh+k
	dw 4,mcddd2

	db 2+rh+k
	dw 8,mcddd3

	db 2+rh+k
	dw 16,mcddd4

	db endlst


smmulu:	db 7	
	dw smmul		;unsigned *

	db 1+rh+k
	dw dolxi,mcumul

	db 2+rh+k
	dw dolxi,mcumul

	db 5+rh+k
	dw nolxi,mcumul

	db endlst


smmuls:	db 7	
	dw smmul		;signed *

	db 1+rh+k
	dw dolxi,mcsmul

	db 2+rh+k
	dw dolxi,mcsmul

	db 5+rh+k
	dw nolxi,mcsmul

	db endlst


smdiv:	db 1+con0+k
	dw 0,mnul		;common cases for both

	db 2+con0+k
	dw 0,mnul		;signed and unsigned

	db 1+rh	
	dw 1,mnul		;division

	db 2+rd	
	dw 1,mnul

	db 1+rh	
	dw -1,maccom

	db 1+rd	
	dw -1,maccmd

	db endlst


smdivu:	db 7	
	dw smdiv		; unsigned / operator

	db 1+rh	
	dw dolxi,mcdiv5

	db 2+rh	
	dw dolxi,mcudiv

	db 3+rh	
	dw dolxi,mcudiv

	db 4+rh	
	dw dolxi,mcdiv5

	db 5+rh	
	dw nolxi,mcudiv

	db 6+rh	
	dw nolxi,mcdiv5

	db endlst


smdivs:	db 7	
	dw smdiv		;signed / operator

	db 1+rh	
	dw dolxi,mcdiv7

	db 2+rh	
	dw dolxi,mcsdiv

	db 3+rh	
	dw dolxi,mcsdiv

	db 4+rh	
	dw dolxi,mcdiv7

	db 5+rh	
	dw nolxi,mcsdiv

	db 6+rh	
	dw nolxi,mcdiv7

	db endlst


smmod:	db 1+con0+k
	dw 0,mnul		;common % operator cases

	db 2+con0+k
	dw 0,mnul

	db endlst


smmodu:	db 7	
	dw smmod		;unsigned % operator

	db 1+con0
	dw 1,mnul

	db 2+con0
	dw 1,mnul

	db 1+rh	
	dw dolxi,mcmod5

	db 2+rh	
	dw dolxi,mcumod

	db 3+rh	
	dw dolxi,mcumod

	db 4+rh	
	dw dolxi,mcmod5

	db 5+rh	
	dw nolxi,mcumod

	db 6+rh	
	dw nolxi,mcmod5

	db endlst


smmods:	db 7	
	dw smmod		;signed % operator

	db 1+rh	
	dw dolxi,mcmod7

	db 2+rh	
	dw dolxi,mcsmod

	db 3+rh	
	dw dolxi,mcsmod

	db 4+rh	
	dw dolxi,mcmod7

	db 5+rh	
	dw nolxi,mcsmod

	db 6+rh	
	dw nolxi,mcmod7

	db endlst


smsr:	db 1+rh	
	dw 0,mnul		; >> operator

	db 2+rd	
	dw 0,mnul

	db 1+rh	
	dw dolxi,macsrh

	db 2+rh	
	dw dolxi,macsrd

	db 3+rh	
	dw dolxi,macsrd

	db 4+rh	
	dw dolxi,macsrh

	db 5+rh	
	dw nolxi,macsrd

	db 6+rh	
	dw nolxi,macsrh

	db endlst


smsl:	db 1+rh	
	dw 0,mnul		; << operator

	db 2+rd	
	dw 0,mnul

	db 1+rh	
	dw 1,mcddh1

	db 1+rh	
	dw 2,mcddh2

	db 1+rh	
	dw 3,mcddh3

	db 1+rh	
	dw 4,mcddh4

	db 1+rh	
	dw 5,mcddh5

	db 2+rh	
	dw 1,mcddd1

	db 2+rh	
	dw 2,mcddd2

	db 2+rh	
	dw 3,mcddd3

	db 2+rh	
	dw 4,mcddd4

	db 2+rh	
	dw 5,mcddd5

	db 1+rh	
	dw dolxi,macslh

	db 2+rh	
	dw dolxi,macsld

	db 3+rh	
	dw dolxi,macsld

	db 4+rh	
	dw dolxi,macslh

	db 5+rh	
	dw nolxi,macsld

	db 6+rh	
	dw nolxi,macslh

	db endlst


smgtu:	db 1+fnz
	dw 0,mcn10		; unsigned ">" operator

	db 2+fnz
	dw 0,macde0

	db 3+con0
	dw 0,mnul

	db 4+con0
	dw 0,mnul

	db 1+fc
	dw nolxi,macsb5

	db 2+fc	
	dw nolxi,macsb6

	db 3+fnc	
	dw nolxi,macsb1

	db 4+fnc	
	dw nolxi,macsb2

	db 5+fc	
	dw nolxi,mcagbu

	db 6+fc	
	dw nolxi,mcbgau

	db endlst


smgts:	db 1+fnc		;signed ">" operator
	dw -1,macrhl

	db 2+fnc	
	dw -1,macrdl

	db 3+fc
	dw 0,macrhl

	db 4+fc
	dw 0,macrdl

	db 1+fc
	dw dolxi,mcbgas

	db 2+fc
	dw dolxi,mcagbs

	db 3+fc	
	dw dolxi,mcagbs

	db 4+fc	
	dw dolxi,mcbgas

	db 5+fc	
	dw nolxi,mcagbs

	db 6+fc	
	dw nolxi,mcbgas

	db endlst


smltu:	db 1+con0		;unsigned "<" operator
	dw 0,mnul

	db 2+con0
	dw 0,mnul

	db 3+fnz
	dw 0,mcn10

	db 4+fnz
	dw 0,macde0

	db 1+fnc	
	dw nolxi,macsb1

	db 2+fnc	
	dw nolxi,macsb2

	db 3+fc	
	dw nolxi,macsb5

	db 4+fc	
	dw nolxi,macsb6

	db 5+fc	
	dw nolxi,mcalbu

	db 6+fc	
	dw nolxi,mcblau

	db endlst


smlts:	db 1+fc			;signed "<" operator
	dw 0,macrhl

	db 2+fc
	dw 0,macrdl

	db 3+fnc
	dw -1,macrhl

	db 4+fnc
	dw -1,macrdl

	db 1+fc	
	dw dolxi,mcblas

	db 2+fc	
	dw dolxi,mcalbs

	db 3+fc	
	dw dolxi,mcalbs

	db 4+fc	
	dw dolxi,mcblas

	db 5+fc	
	dw nolxi,mcalbs

	db 6+fc	
	dw nolxi,mcblas

	db endlst


smeq:	db 1+fz+k
	dw 0,mcn10		; == operator

	db 2+fz+k
	dw 0,macde0

	db 1+fz+k
	dw 1,mache1

	db 1+fz+k
	dw 2,mache2

	db 1+fz+k
	dw 3,mache3

	db 1+fz+k
	dw 4,mache4

	db 2+fz+k
	dw 1,macde1

	db 2+fz+k
	dw 2,macde2

	db 2+fz+k
	dw 3,macde3

	db 2+fz+k
	dw 4,macde4

	db 1+fz+k
	dw -1,mchen1

	db 1+fz+k
	dw -2,mchen2

	db 1+fz+k
	dw -3,mchen3

	db 2+fz+k
	dw -1,mcden1

	db 2+fz+k
	dw -2,mcden2

	db 2+fz+k
	dw -3,mcden3

	db 1+fz+k
	dw nolxi,mcsb1a

	db 2+fz+k
	dw nolxi,mcsb1b

	db 5+fz+k
	dw nolxi,mceq

	db endlst


smand:	db 1+con0+k
	dw 0,mnul		; & operator

	db 2+con0+k
	dw 0,mnul

	db 1+rh+k
	dw -1,mnul

	db 2+rd+k
	dw -1,mnul

	db 1+rh+k
	dw dolxi,mcand

	db 2+rh+k
	dw dolxi,mcand

	db 5+rh+k
	dw nolxi,mcand

	db endlst


smor:	db 1+rh+k
	dw 0,mnul		; | operator

	db 2+rd+k
	dw 0,mnul

	db 1+conff+k
	dw -1,mnul	

	db 2+conff+k
	dw -1,mnul

	db 1+rh+k
	dw dolxi,mcor

	db 2+rh+k
	dw dolxi,mcor

	db 5+rh+k
	dw nolxi,mcor

	db endlst


smxor:	db 1+rh+k
	dw 0,mnul

	db 2+rd+k
	dw 0,mnul

	db 1+rh+k
	dw dolxi,mcxor

	db 2+rh+k
	dw dolxi,mcxor

	db 5+rh+k
	dw nolxi,mcxor

	db endlst





;
; This routine returns Z true if both operands are chars,
; else returns not Z and clears the high order byte of
; any of the two operands which aren't chars:
;

chradj:	call tschr	;first operand a char?
	jnz chrdj2
	call tschr2	;yes. 2nd?
	rz		;if so, return Z true
	lxi d,mac61	;else clear hi byte of HL
chrdj1:	call mcrog
	xra a
	inr a		;and return Z false
	ret
chrdj2:	call tschr2	;2nd operand char?
	rnz		;if not, done
	lxi d,mac62	;if so, clear hi byte of DE
	jmp chrdj1


parerr:	lxi d,stg18
	jmp perr

unsadj:	call tptr
	jz unsdj2
	call tptr2
	jz unsdj2
	call tsval
	rnz
	call tsval2
	rnz
	lda typ1
	cpi 2
	rz
	lda typ2
	cpi 2
	rnz
	sta typ1
	ret

unsdj2:	xra a
	ret

;
; Routine to "pass over" a simple expression in text:
;

sexpas:	call igsht
	inx h
	cpi mulcd	;check for unary ops
	jz sexpas
	cpi ancd
	jz sexpas
	cpi mincd
	jz sexpas
	cpi notcd
	jz sexpas
	cpi circum
	jz sexpas
	cpi pplus
	jz sexpas
	cpi mmin
	jz sexpas
	cpi sizcd
	jz sexpas
	dcx h		;else pass primary expr
	call ppas
	ret

ppas:	call sppas	;pass simple primary expr
	rc		;abort if error
ppas2:	call igsht	;check for primary ops
	cpi open
	jnz ppas3
ppas2a:	call mtchp
	jmp ppas2

ppas3:	cpi openb
	jnz ppas4
	call mtchb
	jmp ppas2

ppas4:	inx h
	cpi arrow
	jz ppas5
	cpi period
	jz ppas5
	cpi pplus
	jz ppas2
	cpi mmin
	jz ppas2
	dcx h		;all done.
	stc
	cmc
	ret

ppas5:	call igsht
	cpi varcd
	jnz ppase
ppas6:	inx h
	inx h
	inx h
	jmp ppas2

sppas:	cpi open
	jz ppas2a
	cpi strcd
	jz ppas6
	cpi varcd
	jz ppas6
	cpi concd
	jz ppas6

ppase:	lxi d,stg10
	call perrsv
	stc
	ret

 

;
; Routine to "look ahead" past the current text, and
; return the next non-space character, restoring old
; text pointer and line count:
;

looka:	push h
	lhld nlcnt
	xthl
	push h
	inx h
	call igsht
	pop h
	xthl
	shld nlcnt
	pop h
	ret


domac:	mov a,c
	add a
	add a
	add a
	add b
	add b
	push h
	lxi h,mact
	mov e,a
	mvi d,0
	dad d
	mov e,m
	inx h
	mov d,m
	call mcrog
	pop h
	ret

aluadj:	mov a,l
	ora a
	rnz
	mov a,h
	ora a
	rnz
	mvi h,1
	ret


mult:	push b
	push d
	mov b,h
	mov c,l
	lhld subval
	xchg
	lxi h,0

mult1:	mov a,b
	ora c
	jz mult2
	dad d
	dcx b
	jmp mult1

mult2:	shld subval
	pop d
	pop b
	ret

maddd:	mov a,d
	ora a
	jnz maddd2
	mov a,e
	cpi 4
	jnc maddd2
maddd1:	mov a,d
	ora e
	rz
	mvi a,23h
	call genb
	dcx d
	jmp maddd1

maddd2:	xchg
	shld sr0
	xchg
	lxi d,mac0c
	call mcrog
	ret


;
; Return Z set if keyword in A is a binary operator:
;

binop:	mvi b,15
	cpi 0b6h
	rz
	cpi 0b7h
	rz
	cpi 0b8h
	rz
	dcr b
	cpi 0c4h
	rz
	cpi 0b5h
	rz
	dcr b
	cpi 0b0h
	rz
	cpi 0b1h
	rz
	dcr b
	cpi 0bah
	rz
	cpi 0b9h
	rz
	cpi 0afh
	rz
	cpi 0aeh
	rz
	dcr b
	cpi 0aah
	rz
	cpi 0abh
	rz
	dcr b
	cpi 0bbh
	rz
	dcr b
	cpi 0bch
	rz
	dcr b
	cpi 0bdh
	rz
	dcr b
	cpi 0ach
	rz
	dcr b
	cpi 0adh
	ret

;
; Return Z if keyword in A is logical binary op (&& or ||):
;

lbinop:	cpi oror
	rz
	cpi andand
	ret

;
; Return Z if keyword is ++ or --:
;

ppormm:	cpi pplus
	rz
	cpi mmin
	ret

;
; Return Z if keyword in A is asignment operator:
;


asgnop:	cpi 0beh
	rz
	cpi 0a0h
	rc
	cpi 0ach
	cmc
	ret

cnvsop:	sui 0a0h
	push h
	push d
	lxi h,sopt
	mov e,a
	mvi d,0
	dad d
	mov a,m
	pop d
	pop h
	ret

sopt:	db 0c4h,0b5h,0b6h,0b7h,0b8h
	db 0b1h,0b0h,0bbh,0bch,0bdh

primop:	cpi open
	rz
	cpi openb
	rz
	cpi arrow
	rz
	cpi period
	ret

prmop2:	call primop
	rz
	cpi pplus
	rz
	cpi mmin
	ret

;
; Handle a binary expression, with HL pointing to the first arg:
;

lcflag:	ds 1 		;controls optimizing for constant logical subexpr.
			;=10h when no lbinop activity,
			;=20h when pending next (noted) lbinop result
			;b6 hi when abs logical value of binexp determined
			;if b6 true, b7 is: 1 for TRUE, 0 for FALSE

lflag:	ds 1		;true if &&/|| expression

bexpr:	lda codflg
	push psw
	lda arith
	push psw
	mvi a,10h	;initialize lcflag to: "no activity"
	sta lcflag
	xra a
	sta arith
	sta lflag
bxpr00:	call rpshp
bxpr0:	xra a
	call oppsh
	call sexpasl
	push h
	lhld ltabp
	cpi andand	; Do special ltab hackery if NEXT operator is || or &&
	jnz bxpr0a	;&& operator?
	push h		;yes. propogate last false branch table label,
	dcx h		;add new true label
	dcx h
	mov d,m
	dcx h
	mov e,m
	pop h
	push d
	xchg
	call glbl
	xchg
	mov m,e
	inx h
	mov m,d
	inx h
	pop d
	jmp bxpr0b

bxpr0a:	cpi oror
	jnz bxpr0c	;|| operator?
	push h		;yes. propogate last true branch table label,	
	lxi d,-5	;add new false label.
	dad d
	mov e,m
	inx h
	mov d,m
	pop h
	mov m,e
	inx h
	mov m,d
	inx h
	xchg
	call glbl
	xchg
bxpr0b:	mov m,e
	inx h
	mov m,d
	inx h
	inx h
	shld ltabp

	lda lcflag	;first activity?
	cpi 10h
	jnz bxpr0c	;if not, don't change this here
	mvi a,20h	;if not, prime for some activity
	sta lcflag	

bxpr0c:	pop h

	lda value
	push psw

	lda arith
	push psw
	ora a		;was arith set?
	cnz ltabmp	;if so, bump ltable to keep branches local...

	lda lcflag	;save logical constant flag
	push psw
	lda lflag	;save logical expression flag
	push psw

	xra a
	call sgenv	;evaluate the operand.

	pop psw
	sta lflag	;restore logical expr flag

	pop psw		;get old lcflag in A
	mov b,a		;save in B
	ora a		;was old lcflag cleared?
	jz lchck1	;if so, keep it that way.
	ani 30h		;was it primed or inactive?
	mov a,b
	jnz lchck2	;if so, let newer one be propogated
			;else...
lchck1:	sta lcflag	;restore logical constant flag

lchck2:	pop psw
	sta arith

	pop psw
	ora a
	jz bxpr1
	sta value	;logical `or' "value" with old "value"

bxpr1:	lda arith	;was last term preceded by arith operator?
	ora a
	jz bxpr1a	;if not, don't clean up
	xra a		;yes; reset arith flag
	sta arith
	call ltabtd	;define all possible branches as here
	call ltabfd
	call ltabpp	;clean up branch table
	pop psw		;and restore old value of val
	sta val

bxpr1a:	call oppops

bxpr2:	mov a,m	
	call binop	;next thing in text a binary op?
	jz bxpr4

bxpr3:	call tstops	;no. any old ops on stack?
	jz bxpr9
			;yes. generate operations.
	call ppshp
	call oppop	
	call ppn2
	call alugen
	jmp bxpr3

bxpr4:	call tstops	;ok, we have a new binop to process.
	jnz bxpr7	;any old stuff on stack?
	mov a,m		;no. Let's handle && and || specially...
	cpi andand	; && operator?
	jnz bxpr5
	sta lflag	;set, set logical expression flag
	call ppshp

	lda lcflag	;see if it's OK to check for constants
	ani 0f0h
	jz bxpr4a	;only test for constants if lcflag cooperates.

	call tcnst1	;was arg a constant?
	jz bxpr40
	lda lcflag	;if not, clear lcflag if not already finalized
	ani 0c0h
	sta lcflag
	jmp bxpr4a

bxpr40:	lda lcflag	;was lcflag primed?
	cpi 20h
	jnz bxpr41
	mvi a,10h	;if so, un-prime in case we don't score the right
	sta lcflag	;polarity on this constant.

bxpr41:	call tcnsz	;we have a constant. zero?
	jnz bxpr4b	;if not, skip the cond'l jump, but keep evaluating
bxpr42:	xra a		;yes...
	sta codflg	; don't bother generating any more code for the bexpr
	mvi a,40h
	sta lcflag	;set logical constant flag to "yes, false"
	jmp bxpr4b

bxpr4a:	lda val
	cpi 81h		;if must force value, do it:
	cz lv01th	; get 0 or 1 into HL, no matter WHAT.
	call gncjf	;generate conditional jump on false
bxpr4b:	call ltabtd
	call ltabfo
	jmp bxpr5c

bxpr5:	cpi oror
	jnz bxpr6	; || operator?
	sta lflag	;yes, set logical expression flag
	call ppshp

	lda lcflag	;see if it's OK to check for constants
	ani 0f0h
	jz bxpr5a	;only test for constants if lcflag cooperates.

	call tcnst1	;was arg a constant?
	jz bxpr50
	lda lcflag	;if not, clear lcflag if not already finalized
	ani 0c0h
	sta lcflag
	jmp bxpr5a

bxpr50:	lda lcflag	;was lcflag primed?
	cpi 20h
	jnz bxpr51
	mvi a,10h	;if so, un-prime in case we don't score the right
	sta lcflag	;polarity on this constant.

bxpr51:	call tcnsz	;we have a constant. zero?
	jz bxpr5b	;if so, skip the cond'l jump, but keep evaluating

	xra a		;no...thus true, so
	sta codflg	;don't bother generating any more code for the bexpr
	mvi a,0c0h	;set logical constant flag to "yes, true"
	sta lcflag
	jmp bxpr5b

bxpr5a:	lda val
	cpi 81h		;if must force value, do it:
	cz lv01th	; get 0 or 1 in HL no matter WHAT.
	call gncjt	;generate conditional jump on true
bxpr5b:	call ltabfd
	call ltabto

bxpr5c:	call ltabpp
	inx h
	jmp bxpr00

tcnsz:	lda sval1	;set Z flag if constant value of zero
	ani 1
	jz invrt	;if not absolute constant, not value of zero
	push h		;save text pointer
	lhld svv1
	mov a,h
	ora l
	pop h		;now Z set if zero value
	ret


bxpr6:	lda sval1	;if logical bit set, turn it into actual value here
	ani 4		;so stuff like: " <Bang>kbhit() & a<5 " works.
	cnz cvtlvh

	lda val
	cpi 81h		;if must force value, do it:
	cz cvtlvh	; make sure flag settings turn into values in HL

	call tcnst1
	cnz spshp
	cz rpshp
	call pshn1
	mov a,m
	call oppsh
	inx h

	call igsht	;next term a complex expression in parens?
	cpi open
	jnz bxpr0

	lda val		;if so, assume it needs complete evaluation
	push psw
	mvi a,81h	;force value result
	sta val
	mvi a,1		;set arith mode while evaluating
	sta arith	;   next operand of binary op,
	jmp bxpr0	;and go evaluate next arg

bxpr7:	call oppop
	call oppsh
	mov c,b
	call binop

	push d
	lxi d,stgbbo
	cnz perrab	;no other operators; better be '|'
	pop d

	mov a,c
	cmp b
	jz bxpr8
	jnc bxpr6

bxpr8:	call ppshp
	call oppop
	call ppn2
	call alugen
	jmp bxpr2

bxpr9:	call ppshp
	lda val		;absolutely need a value?
	cpi 81h
	jnz bxpr90

	lda lflag	;was it a logical expression (with && and ||) ?
	ora a
	jz bxpr91
	call lv01th	;if so, go convert into 0 or 1 in HL, no matter WHAT
	jmp bxpr90

bxpr91:	call cvtlvh	;else just flush logical flag values into HL

bxpr90:	pop psw
	sta arith	;restore arith flag
	pop psw
	sta codflg	;restore code flag.
	lda lcflag	;result a logical constant?
	ani 0c0h
	jz bxpr9b	;if not, don't create constant return value

	ora a		;set Z flag if constant of 0
	mvi a,1
	sta sval1	;yes--set constant flag
	push h
	lxi h,0		;constant value of zero?
	jp bxpr9a	;if so, go store
	inx h		;else make it 1
bxpr9a:	shld svv1
	pop h

bxpr9b:	pop psw
	cpi 2
	rnz
	lxi d,stg8
	jmp perr
	
;
; This makes sure that the result of the current
; expression is a hard value of 0 or 1 in HL, no matter WHAT.
;

lv01th:	lda sval1	;logical flag?
	ani 4
	jnz cvtlvh	;if so, go convert
	lda sval1
	ani 1		;constant?
	jz lv01b
	push h		;yes. turn into 0 or 1 in HL
	lhld svv1
	mov a,h
	ora l
lv01d:	lxi h,0
	jz lv01a
	inx h
lv01a:	shld svv1
	pop h
	call flshh1	;flush constant into HL
	ret

lv01b:	lda sval1	;not abs constant-is it rel lv?	
	ani 2
	jz lv01c
	mvi a,1		;if so, turn into constant equal to 0
	sta sval1
	push h
	xra a		;set Z to force constant value of 0
	jmp lv01d	;and go wrap up

lv01c:	lda sval1	;not any kind of constant, so must be val in reg
	ani 0c0h	;in DE?
	jz lv01e
	lxi d,macde0	;yes. char?
	call tschr
	cnz mcrog	;if not, do 16-bit test
	lxi d,mcn12
	cz mcrog	;else do 8-bit test
	jmp lv01f	;and go convert into HL value

lv01e:	lxi d,mache0	;value in HL. char?
	call tschr
	cnz mcrog	;if not, do 16-bit test
	lxi d,mcn11
	cz mcrog	;else do 8-bit test

lv01f:	lxi d,macf2	;now convert NZ flag state into HL value
	call mcrog
	mvi a,24h	;set flag and value result
	sta sval1
	mvi a,1		;set flag value of NZ true
	sta sbmap1
	ret



;
; Process assignment expression, given HL -> left
; element of assignment. This might be either a simple
; assignment or an op= type assignment:
;

aexpr:	call igsht	;check for leading & or ++ or --, so that
	cpi ancd	;some common invalid lvalues that can't be
	jz badlv	;detected by analyz can be diagnosed properly.
	call ppormm	;is it ++ or --?
	jz badlv	;if so, bad lvalue
	cpi varcd	;a variable name?
	jnz aexpr0	;if not, all done checking for special cases
	inx h
	inx h
	inx h
	mov a,m
	call ppormm	;is it an expr of form foo++ or foo-- ?
	dcx h
	dcx h
	dcx h
	jnz aexpr0

badlv:	lxi d,stg8b
	call perr

aexpr0:	call rpshp
	mvi a,2		;generate address of left arg
	call sgenv
	call ppshp
	cpi letcd	; simple '=' assignment?
	jz aexpl	;if so, go do it.
	call cnvsop	;convert op= to just op
	push psw	;and save the op for later
	lda sval1	;no. abs const lvalue?
	ani 1
	jz aexp0
	call glvcv	;yes. get value of left operand
	call pshn1	;save info on lvalue before it was indirected
	xra a
	sta sval1	;after indirection, it's a simple value
	jmp aexp2a

aexp0:	call flshh1	;not abs const lvalue. flush into HL
	call pshn1
	call gpushh	;gen. push instr. to save address of left arg
	call tsclv	;test for char value. Is it?
	jz aexp2	;if so, go do single byte indirection

	call maca0c	;else do double byte indirection, perhaps RST'ed
	jmp aexp2a

aexp2:	lxi d,mac6e	;if a char, just do "mov l,m"
	call mcrog

aexp2a:	call tslv	;was left arg a simple lvalue?
	jnz aexp2b
	lda indc1	;if so, de-bump indirection count
	dcr a		; (corresponding to the just-done indirection)
	sta indc1
aexp2b:	call pshn1	;save info on the left arg
	inx h
	call spshp
	call evala
	call ppshp
	call ppn2	;pop info on left arg
	pop psw		;get back the operator code
	call alugen	;now perform the operation
aexp3:	call ppn2	;peek at original lvalue info
	call pshn2
	lda sval2	;was lvalue an abs lv const?
	ani 10h
	jnz aexp3b	;if so, don't pop or do ANYTHING messy.

aexp3a:	call pn1ind	;else make sure the alugen result is in DE
	call gpoph	;gen 'pop h' to get addr of left arg back in HL

aexp3b:	call mvn12	;and put the info on the left and right args into
	call ppn1	;  info1 and info2, respectively
	jmp letgen	;and go generate the assignment code

aexpl:	call pshn1	;come here to handle simple '=' operator
	inx h
	lda sval1
	push psw	;save info1 optimization byte
	call tcnst1
	cnz spshp
	cz rpshp
	call evala	;evaluate rvalue
	call ppshp
	call tpshd
	jnz aexpl2
	pop psw
	jmp aexp3a

aexpl2:	lda sval1
	ani 2
	jnz aexpl3
	pop psw
	jmp aexp3b

aexpl3:	pop psw
	mov b,a		;save left operand into in B
	ani 3		;left operand in a register?
	jz aexpl4
	call flshd1	;no...flush right operand into DE
	jmp aexp3b	;and go process assignment

aexpl4:	mov a,b		;left operand in a register.
	ani 0c0h	;push the appropriate register on stack
	cz gpushh
	cnz gpushd
	call flshd1	;evaluate right operand into DE
	call gpoph	;pop left operand into HL
	call mvn12	;set up for assignment processor
	call ppn1
	lda sval1	;but force left operand data to indicate in HL
	ani 3fh
	sta sval1
	jmp letgen

evala:	lda val
	push psw
	mvi a,81h
	sta val
	call ltabmp	;bump logical table to make sure we stay in this
	xra a		;statement no matter what the (maybe) logical value is
	call expr2v
	call ltabtd	;come here if true
	call ltabfd	;and come here if false, too.
	call ltabpp	;and pop ltab entry
	pop psw
	sta val
	ret


letgen:	call analyz	;ok to assign to the lvalue given?
	lda asnokf
	ora a
	jnz lg2
letbad:	lxi d,stg8b	;no. error.
	call perr
	pop psw
	ret

lg2:	push h		;yup. abs lvalue constant?
	lda sval1
	ani 11h
	jnz palvc	;if so, go handle

	lda sval1	;no. relative lvalue constant?
	ani 2
	jnz prlvc	;if so, go handle that.

	lda sval2	;OK, we have lvalue in HL, rvalue somewhere
	ani 1		;rvalue a constant?
	jz lgncon	;if not, go handle

	call flshh1	;OK, put lvalue into HL if it is in DE

lg3:	lda val		;yes, rvalue is constant.
	ora a
	jnz lg5		;need result?
	call tsclv
	jnz lg4b	;8 bit value?
	mvi a,36h	;yes. do "mvi m,vaue"
	call genb
	lda svv2
	call genb
	jmp lgdone

lg4b:	lhld svv2	;16-bit value.
	mov a,h
	ora l		;zero special case?
	jnz lg4c
	lxi d,macac1	;yes.
	call mcrog
	jmp lgdone

lg4c:	mvi a,36h
	call genb	
	lda svv2
	call genb
	mvi a,23h
	call genb
	mvi a,36h
	call genb
	lda svv2+1
	call genb
	jmp lgdone

lg5:	lhld svv2	;we need value result.
	shld sr0
	call tsclv
	jnz lg5b
	mvi a,1eh
	call genb
	lda svv2
	call genb
	mvi a,73h
	call genb
lg5a:	mvi a,40h	;set result in DE flag
	sta sval1
	jmp lgdone

lg5b:	lxi d,macac3
	call mcrog
	jmp lg5a

;
; Come here after all assignemnts have been done
;

lgdone:	call tslv
	jnz lgdn2
	lda indc1
	dcr a
	sta indc1
lgdn2:	pop h
	pop psw
	call ckvok
	ret

;
; Handle assignment of value in DE to lvalue in HL:
;

lgncon:	call tsclv
	jnz lgnc5	;char lvalue?
	mvi a,73h	;yes.
	call genb
	jmp lg5a

lgnc5:	call tschr2	;no. char rvalue?
	jnz lgnc6
	lxi d,macac4	;yes--so we're assigning a char to an int lvalue.
	lda val		;need value result?
	ora a
	jz lgnc5a
	lxi d,macac5	;if so, make sure high-order byte is zeroed in result
lgnc5a:	call mcrog
	jmp lg5a

lgnc6:	lda optimf
	ani 8
	jz lgnc7
	mvi a,0e7h	;rst 4: mov m,e inx h mov m,d
	call genb
	jmp lg5a

lgnc7:	lxi d,maca1
	call mcrog
	jmp lg5a

;
; Assign to absolute lvalue constant location:
;

palvc:	lhld svv1
	shld sr0
	lhld svv2
	shld sr1
	lda sval2	;rvalue a constant?
	ani 1
	jz palvcc
	lda val		;yes.
	ora a
	jnz palv3	;need value result?
	call tsclv	;no.
	jnz palv2	;8-bit object?
	mvi a,3eh	;yes.
	call genb
	lda svv2
	call genb
	lxi d,macacb
	call mcrog
	jmp lgdone

palv2:	lxi d,macacc	;16-bit object.
palv2a:	call mcrog
	xra a
	sta sval1	;result in HL (if needed)
	jmp lgdone

palv3:	call tsclv	;need value result.
	jnz palv2
	mvi a,1eh
	call genb
	lda svv2
	call genb
palv4:	mvi a,7bh
	call genb
	lxi d,macacb
	call mcrog
	jmp lg5a

palvcc:	call tsclv	;rvalue is in a register.
	jnz plvc2	;simple char lvalue?
	lda sval2	;yes.
	ani 0c0h
	jnz palv4	;in HL?
	mvi a,7dh	;yes.
	call genb
	lxi d,macacb
	jmp palv2a

plvc2:	lda sval2	;16-bit value. in HL?
	ani 0c0h
	cnz gxchg	;go "xchg" if not, to get value into HL
	call tschr2	;simple char rvalue?
	jnz plvc3	;if not, do 16-bit assignment normally

	mvi a,26h	;else clear H before assigning
	call genb
	xra a
	call genb

plvc3:	lxi d,mac09	;go perform assignment
	jmp palv2a
	
;
; Assign to a relative lvalue (external or local) location:
;

prlvc:	lda sval2
	ani 1
	jz prlv2	;constant rvalue?
prlv1:	call flshh1	;yes. get value in HL
	jmp lg3

prlv2:	lda sval1	;no; rvalue in a reg. local lvalue?
	ani 8
	jnz prlv3
	call pn2ind	;yes. get value in DE
	call flshh1
	jmp lgncon

prlv3:	lda sval2	;must be external.
	ani 0c0h
	mvi a,0e5h	;push rvalue.
	jz prlv4
	mvi a,0d5h
prlv4:	call genb
	call flshh1	;generate lvalue in HL
	mvi a,0d1h	;get back rvalue in DE
	call genb
	mvi a,40h	;result in DE
	sta sval2
	jmp lgncon	;go perform assignment.

glvcv:	push h
	lhld svv1
	shld sr0
	pop h
	lxi d,mac40
	call mcrog
	lda sval1
	ani 0feh	;no longer a simple lvalue constant
	ori 10h		;now a "has been" !
	sta sval1
	ret

;
; Gen code to multiply HL by value passed here in HL:
;

gnmulh:	shld sr0	;save the value
	mov a,h
	ora a		;is it very big?
	jnz mulhbg	;if so, go do brutal lxi d,val- call mult- etc.
	mov a,l		;yes.
	ora a
	jnz gnmh2
	lxi d,mac04	;trivial case: lxi h,0
	call mcrog
	ret

gnmh2:	mvi b,6		;find out if we have an easy power of two.
	push psw	;push value
gnmh2a:	pop psw		;pop value
	rar		;rotate right along with carry
	push psw	;and immediately save to preserve carry bit
	ora a		;did we just rotate the only 1 bit into the carry?
	jz gnmh3	;if so, we've got a power of 2 and can do "dad h"'s
	dcr b		;else keep rotating
	jnz gnmh2a
	pop psw		;clean up stack...

mulhbg:	lxi d,mac0a	;no simple power of two. use brute force.
	call mcrog
	ret

gnmh3:	pop psw
	mvi a,7		;ok, we can use dad h's. find out how many
	sub b		;are needed.
	mov b,a		;save 1+n in B.
gnmh4:	dcr b
	rz
	mvi a,29h	;and spit 'em out till done.
	call genb
	jmp gnmh4


;
; process e1 ? e2 : e3 
; (upon entry, HL -> "?")
;
; New for v1.45 (fixing a bug...)
; Take special care in the case of mixed character and non-character
; values for e2 and e3, so 16 bit values don't get their high order
; bytes chopped off.
;

qexpr:	inx h		;get HL -> e2
	call gncjf	;gen cond'l jump-on-false to e3

	call ltabtd	;define $ as true branch of pre-? expr
			;		(fixes bug found by D. Greenlaw)
	pop psw
	push psw
	call rpshp
	call expr1
	call ppshp
	call flshh1
	call igsht
	cpi colon	;followed by colon?
	jz qxpr2
	call ltabpp
qxpr1:	lxi d,stg14	;if not, bad news.
	call perr
	pop d
	ret

qxpr2:	inx h		;colon found OK.
	call tschr	;set Z if e2 is a character value

	pop b		;get item on top of stack
	push psw	;save result of tschr test for later
	push b		;put top item back on the stack

	jnz qxpr2a	;if e2 wasn't a char, don't bother clearing H
	lxi d,mac61
	call mcrog	;clear H if e2 is a char expression	

qxpr2a:	pop psw
	call gfjmp	;generate forward jump to after e3.
	push psw
	call ltabfd	;define false ltab branch
	call ltabpp	;and pop off ltab entry
	call rpshp
	pop psw	

;	call 	expr1	;evaluate e3

	push psw	;like the call above, except comma operator
	call expr2	;recognition is not allowed due to precedence
	pop psw		;rules. This fixes a Dan Grayson bug.

	call ppshp
	call flshh1	;get result in HL

	pop b		;get top item off stack (label code for plvdl)
	pop psw		;get back Z flag, set iff e2 was a char value
	push b		;put label code back onto stack
	jz qxpr3	;if e2 was a char, we don't care if e3 is a char
			;otherwise we might have to promote e3, so let's check:
	call tschr	;was e3 a char value?
	jnz qxpr3	;if not, we don't have to worry about e2 being demoted
	lxi d,mac61	;else promote e3 to an int so that e2 won't be demoted
	call mcrog	;	since e2 was a 16-bit value and e3 is a char.
	mvi a,1		;and make the overall result an int
	sta typ1
qxpr3:	call plvdl	;and pop and define after-e3 label
	ret

	IF LASM
	link cc2d
	ENDIF

