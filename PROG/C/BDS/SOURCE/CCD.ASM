
;
; ccd.asm:
;

;
; preprocessor directive handler:
;

defstr: db '#defin', 'e'+80h
undfst:	db '#unde','f'+80h
ifst:	db '#i','f'+80h
ifdfst:	db '#ifde','f'+80h
ifndst:	db '#ifnde','f'+80h
endfst:	db '#endi','f'+80h
elsest:	db '#els','e'+80h
prepw:	db 'Warning: Ignoring unknown preprocessor directive',cr,lf,0
stgppo:	db 'String overflow; call BDS+'
stgmmp:	db 'EOF found when expecting #endif+'
stgbds:	db 'Bad parameter list syntax+'
stgbd1:	db 'Missing parameter list+'
stgbd2:	db 'Parameter mismatch+'
stgnwc:	db 'Not in a conditional block+'
stgbce:	db 'Conditional expr bad or beyond implemented subset+'

prep:	lxi h,lblt	;set pointer to start of string space table
	shld def2p

	xra a
	sta bcnstf	;supress errors on bad constants till later on...

	lxi h,lblt+strsiz
	shld stp
	mvi m,0

	call initps	;initialize for pass through text

	xra a		;initialize nested conditional control variables
	sta nestl	;current conditional nesting level
	sta didelse	;didn't see an #else yet in current macro
	sta dstgf	;not in a string (for prlin)
	inr a
	sta active	;currently conditionally active

prep1:	call nextch	;handle bookkeeping
	jnc prep1a	;EOF?

	lda nestl	;Yes. In a conditional block?
	ora a
	lxi h,stgmmp
	jnz perrab	;if so, go complain and abort
	xra a
	sta preflag	;not in preprocessor anymore
	ret		;otherwise done with preprocessor

prep1a:	lhld nlcnt	;save line count
	shld nlcsav
	cpi cr		;line only a lone CR?
	jnz prep1b	;if not, process the line

	dcx h		;else debump line count
	shld nlcsav
	jmp prep2a	;and go wrap up

prep1b:	push d		;process #defined substitutions on current line,
	lda active	;but only if active
	ora a
	cnz prlin
	pop d

	call igwsp
	ldax d		;a preprocessor directive?
	cpi '#'
	jnz prep2	;if not, don't bother with rest of this stuff

	lxi h,endfst	;#endif?
	call stcmp
	jz pendif

	lxi h,elsest	;#else?
	call stcmp
	jz pelse

	lxi h,ifdfst	;#ifdef?
	call stcmp
	jz pifdef

	lxi h,ifndst	;#ifndef?
	call stcmp
	jz pifndef

	lxi h,ifst	;#if?
	call stcmp
	jz pif

	lda active
	ora a		;if not active, don't do any more processing
	jz prep2

	lxi h,defstr	;#define?
	call stcmp
	jz pdef

	lxi h,undfst	;#undef?
	call stcmp
	jz pundef

	push d		;check for possible '#' on a line by itself; this
prpwlp:	inx d		;should be ignored by turning the line into FF's:
	ldax d
	cpi 0ffh	;we'll allow this between # and NL
	jz prpwlp
	cpi cr		;end of line?
	jz prpwrn0

prpwrn:	lxi h,prepw	;print this warning ONLY if
	call pwarn
prpwrn0: pop d
	jmp prep2b


;
; Come here when current line is NOT a preprocessor directive:
;

prep2:	lda active	;active?
	ora a
	jz prep2b
	
prep2a:	call nextch	;find CR or EOF
	rc
	cpi cr
	inx d
	jnz prep2a
	jmp prep2c

prep2b:	call dellin	;delete line
prep2c:	lhld nlcsav	;bump saved line count
	inx h
	shld nlcnt
	jmp prep1	;and go for more text


;
; Delete current line of text at DE, up to CR:
;	

dellin:	ldax d
	cpi cr
	jnz dell2
	inx d
	ret

dell2:	mvi a,0ffh
	stax d
	inx d
	jmp dellin


;
; Process #endif:
;

pendif:	lda nestl	;if not in a conditional, complain
	ora a
	jnz pendf2
pendf1:	lxi h,stgnwc	;"Not within conditional block"
	jmp perrab

pendf2:	dcr a		;decrement nest level
	sta nestl

	pop psw		;pop old activity state
	sta active
	pop psw
	sta didelse

	jmp prep2b	

		
;
; Process #else:
;

pelse:	lda nestl	;if not in a conditional block, error
	ora a
	jz pendf1
	lda didelse	;have we already done an #else this block?
	ora a
	jnz pendf1	;if so, error

	pop psw		;peek at last activity state
	push psw
	ora a
	jz pelse2	;last level active? If not, leave this one inactive

	lda active	;yes. flip current state
	ora a
	mvi a,1		;was active false?
	jz pelse1	;if so, make it true
	xra a		;else was true: make it false
pelse1:	sta active
pelse2:	mvi a,1		;set didelse
	sta didelse
	jmp prep2b	

;
; Process #ifdef:
;

pifdef:	push d		;save text pointer
	lda active	;if not active, don't bother evaluating identifier
	ora a
	jz doif
	call defined	;test to see if identifier defined
	jmp doif	;go wrap up

;
; Process #ifndef:
;

pifndef: push d		;just like for #ifdef, 
	lda active
	ora a
	jz doif
	call defined
	cma		;execpt flip the logical result
	jmp doif

;
; Process #if:
;

pif:	push d		;save text pointer
	lda active
	ora a
	jz doif		;if not active, don't bother evaluating line
	lxi h,3	
	dad d
	xchg
	call ifexp	;otherwise evaluate conditional expression
	jmp doif

;
; Evaluate conditional expression at DE, having  BNF:
;
;	ifexp :=  <ifexp2> 
;	    (or)  <ifexp2> && <ifexp>
;	    (or)  <ifexp2> || <ifexp>
;
;	ifexp2 := <constant>
;	    (or)  <(ifexp)>
;	    (or)  not<ifexp2>	("not" is an exclamation point)
;

ifexp:	call ifexp1	;evaluate expression
	mov b,a		;save result in B
	call gndch	;make sure there isn't anything after it
	cpi cr
	mov a,b		;get back the result
	rz		;if CR, all done
ifexp0:	lxi h,stgbce	;bad conditional expression
	jmp perrab

;
; Recursive entry point for conditional expression evaluator:
;

ifexp1:	call ifexp2	;evaluate subexpression
	jc ifexp0	;error if not legal expression
	mov b,a		;put result in B
	call igwsp	;check for operators
	mvi c,'&'
	cmp c
	jz ifxp1a
	mvi c,'|'
	cmp c
	jz ifxp1a
	mov a,b		;no legal operators..return evaluated value.
	ret

ifxp1a:	inx d		;check for second identical character
	ldax d
	cmp c
	jnz ifexp0	;if not, syntax error
	push b		;OK, save last result (B) and operator (C)
	inx d		;evaluate next operand
	call ifexp1
	mov l,a		;put result in L
	pop b		;get back previous result and operator
	mov a,c		;look at operator
	cpi '&'		;logical and?
	mov a,b		;get previous result in A
	jnz ifxp1b
	ana l		;if so, AND the two and return result
	ret
ifxp1b:	ora l		;else OR the two and return result
	ret

ifexp2:	call igwsp	;skip leading whitespace
	cpi '('		;parenthesized expression?
	jnz ifxp2a
	inx d		;yes. pass the opening paren
	call ifexp1	;evaluate inner expression
	mov b,a
	call igwsp	;check for closing paren
	cpi ')'
	stc		;return Cy if not closed
	rnz
	inx d		;otherwise pass the close paren
	mov a,b		;get back result
	cmc		;clear Cy
	ret		;and return

ifxp2a:	cpi '!'		;negation operator?
	jnz ifxp2b
	inx d		;yes. evaluate operand
	call ifexp2
	rc		;ignore if error
	ora a		;otherwise flip result
	mvi a,1
	rz		;return 1 if result was 0
	dcr a		;return 0 if result was 1
	ret

ifxp2b:	call digt	;otherwise must be decimal constant
	rc		;return error if not
ifxp2c:	ldax d		;check a char of the constant
	call digt	;digit?
	jnc ifxp2	;if so, go process
	xra a		;else result is zero.
	ret

ifxp2:	inx d		;bump ptr to next digit
	ora a		;was last digit zero?
	jz ifxp2c	;if so, go loop
ifxp3:	ldax d		;otherwise find end of value
	call digt
	inx d
	jnc ifxp3	;keep looping till we find a non-digit
	dcx d		;all done
	xra a		;return no Cy
	inr a		;and a value of 1
	ret


;
; Come here after #if, #ifdef or #ifndef condition has been
; evaluated, with A = <condition>, either 0 or non-0:
;

doif:	mov b,a		;save condition in B
	lda nestl	;bump nesting level
	inr a
	sta nestl

	pop d		;get back text pointer

	lda didelse	;push current activity state
	push psw
	lda active
	push psw

	ora a		;currently active
	jz doif2	;if not, remain inactive
	mov a,b		;look at conditional test result
	ora a
	jz doif2	;if false, active = 0;
	mvi a,1		;else active = 1.
doif2:	sta active

	xra a
	sta didelse	;clear didelse for the new level
	jmp prep2b	;and go clean up


;
; Process #undef:
;

pundef:	push d
	call defined
	pop d
	jc prep2b	;if already not defined, ignore it
	mvi m,'*'	;otherwise place a strange char there to erase it
	jmp prep2b	;and go wrap up

;
; Process #define definition:
;

pdef:	push d		;found #define line. Save text ptr for later deletion.
	call defined	;re-defining an identifier?
	jc pdef2
	call prepa	;yes. go do that
	jmp pdef3

;
; Install the identifier at DE for the first time:
;

pdef2:	lhld stp
	call prepa	;install identifier
	shld stp
	mvi m,0

;
; Collect up the substitution text in the string table:
;

pdef3:	push psw
	call igwsp
	pop psw
	ora a		;parameterized?
	jnz prargs	;if so, go handle elsewhere

	call gndch	;a null definition?
	cpi cr
	jnz pdef4a
	mvi a,0ffh	;if so, define as a whitespace (FF) byte
	jmp pdef4b

pdef4:	call gndch	;else install simple text, till end of line
pdef4a:	stax b
	inx b
	cpi cr
	jnz pdef4
	dcx b		;turn b7 high on last char of replacement text
	dcx b
	ldax b
	ori 80h
pdef4b:	stax b
	inx b
	mov h,b		;and replace text table pointer
	mov l,c

pdef5:	shld def2p	;make sure def2p hasn't collided with identifier table
	lxi d,lblt+strsiz
	call cmphd	;return C if def2p < end of table2 (ie. no overflow)
	jc pdef6	;if no overflow, no problem

	lxi h,stgppo	;preprocessor overflow: complain and abort
	jmp pstgab

pdef6:	pop d
	jmp prep2b	;go delete line and finish up

;
; Process parameterized substitution text: replace arg keywords with
; special codes (80, 81, etc.) as it is stored in string table:
;

	IF 0
stgflg:	ds 1		;in a string flag, for parameterized definitions
escflg:	ds 1		;escaped char in text string flag
	ENDIF

prargs:	mov h,b		;copy string table address into HL
	mov l,c
	ani 7fh		;strip b7 off arg count
	mov c,a		;put in C
	inr c		;C = # of args + 1


prarg0:	call gndch	;see if text at DE matches one of the formal args

	call varch2
	jnc prarg2

prarg1:	mov m,a		;no match...just store it
	inx h
	cpi cr
	jnz prarg0	;and go for more
	jmp pdef5	;when done, go wrap up.

prarg2:	dcx d		;go back to start of the identifier
	push b		;get set to search arg text table for match
	push h
	mvi b,80h
	lxi h,deformt
prarg3:	dcr c		;done searching list?
	jz prarg6
	mov a,m		;no. compare strings
	inx h
	push h
	mov h,m
	mov l,a
	push b
	call idcmp
	jnz prarg5	;match?
prarg4:	inx d		;yes.
	dcr c		;replace arg with code number
	jnz prarg4
	pop b
	mov a,b		;get code number
	pop h
	pop h
	pop b
	jmp prarg1	;and go store it

prarg5:	pop b		;no match. try next table entry
	pop h		;get table pointer
	inx h		;point to next arg string
	inr b		;bump current code number
	jmp prarg3

prarg6:	pop h
	pop b		;no match. Copy identifier literally
	ldax d
prarg7:	mov m,a
	inx h
	inx d
	ldax d
	call varch	;still part of identifier?
	jnc prarg7	;if so, keep on storing
	jmp prarg0	;else go for next piece of text
	
;
; Install the identifier at DE in the defined constant id table. For
; parameterized defines, count up formal args and make sure the count
; gets into the table.
;
; On entry, HL points to the spot in the table where the id is to be
; inserted:
;
; Return A == argcount (b7 high if args present), BC --> text area
; where key text is to be stored.
;

prepa:	push h		;push id table pointer
	lhld stp	;get id table free slot pointer
	xthl		;push on stack, get back id table pointer
	shld stp	;make id pointer act as free slot pointer for now
	call instt	;install identifier at DE

	push h		;save pointer to argcount byte
	mov l,c		;put identifier length in HL
	mvi h,0
	dad d		;now HL -> char after identifier in text
	mov a,m		;look at it
	cpi '('		;parameterized define?
	mvi a,0
	jnz prepa2	;if not, install 0 in argcount byte position
	call deform	;else go count up formal args, return A = # of args
	jnc prepa1
	lxi h,stgbds
	jmp perrab

prepa1:	ori 80h		;set b7 to indicate parameterized define
prepa2:	xthl		;push text pointer from HL, get HL = table pointer
	mov m,a		;store argcount value in id table
	inx h		;bump table pointer to string addr area
	push h		;save str addr area ptr
	lhld def2p	;get string table free area pointer
	mov b,h		;move to BC
	mov c,l
	pop h		;get back str addr area ptr
	mov m,c		;save string pointer in id table
	inx h
	mov m,b
	inx h		;HL now points to next id slot
	pop d		;get back text pointer
	xthl		;push text pointer, pop old id table free slot ptr
	shld stp	;save id table free slot ptr

	push d		;check for table overflow...we have one if
	xchg		;stp not less than coda
	lhld coda
	xchg
	push psw	;save argcount value
	call cmphd	;return C if stp < coda
	jnc instt0	;if stp >= coda, go complain and abort
	pop psw		;restore argcount value
	pop d
	pop h
	ret

;
; Given HL -> formal arg list for parameterized define,
;  1. Put list of pointers to the args at deformt
;  2. put b7 high on last byte of each arg
;  3. return A = # of formal args (0 is legal), and HL -> after list
;
; If A == 0 on entry, allow only identifiers,
; If A <> 0,  allow any type of objects
;

deform:	mov b,a		;save strings_ok flag in B

	xra a		;initialize extra line count
	sta lcnt

	mvi c,0		;init arg count
	xchg		;put text pointer in DE
	lxi h,deformt	;init arg ptr list ptr
	inx d		;pass '('
	call igwsp	;ignore trash
	cpi ')'		;null list?
	jnz defrm2

defrm1a:
	inx d		;yes. pass over ')'
	xchg		;put text ptr back in HL
	mov a,c		;get arg count in A
	ret

defrm2:	call igwsp	;ignore leading trash
	cpi cr		;newline character?
	jnz defr2a	;if not, assume it's legal starting char
	lda lcnt	;bump extra line count
	inr a
	sta lcnt
	inx d		;go on to next char
	jmp defrm2	;and go check for more extra newlines
	
defr2a:	mov m,e		;add adress of next arg to list
	inx h
	mov m,d
	inx h

	mov a,b
	ora a		;if allowing identifiers only,
	jz defrm4	;then go do that

	xra a		;clear paren nest level
	sta parenc

defr3a:	ldax d		;else process generalized arg: get char of text
	inx d		;bump text pointer
	cpi '"'		;quote?
	jnz defr3d	;if not, go check for terminators
			;process string arg:
defr3b:	ldax d		;look at next arg of string
	inx d
	cpi '\'		;backslash?
	jnz defr3c
	inx d		;if so, pass over the next char
	jmp defr3b
defr3c:	cpi '"'		;closing quote?
	jnz defr3b	;if not, keep looping till we find one
	jmp defr3a	;found closing quote. go for more of the arg

defr3d:	dcx d		;temporarily place txt ptr on current char
	cpi ','		;comma?
	jnz dfr3d1	;if not, check for close paren
	lda parenc	;in parens?
	ora a
	jz defr4a	;if not, found end
	jmp dfr3d2	;else inside parens, so ignore	

dfr3d1:	cpi ')'		;close paren?
	jnz dfr3d3	;if not, go check for other special chars
	lda parenc
	ora a
	jz defr4a	;if already zilch, all done with this paren
	dcr a		;else debump paren count
	sta parenc
dfr3d2:	inx d		;else go on with term
	jmp defr3a

dfr3d3:	inx d		;advance txt ptr back past current char
	cpi ''''	;single quote?
	jz defr3e	;if so, go handle
	cpi '('		;open paren?
	jnz defr3a	;if not, go for next char
	lda parenc	;bump paren count
	inr a	
	sta parenc
	jmp defr3a	;and go for more text

defr3e:	ldax d		;process object in single quotes
	inx d
	cpi '\'
	jnz defr3f
	inx d		;ignore char after backslash
	jmp defr3e	
defr3f:	cpi ''''	;closing single quote?
	jnz defr3e	;if not, keep scanning
	jmp defr3a	;else done with single quote object; go for more arg

defrm4:	ldax d		;get character at txt ptr
	call varch2	;legal 1st char of identifier?
	rc		;if not, error.
defr40:	inx d		;find char after last char of identifier
	ldax d
	call varch
	jnc defr40

defr4a:	dcx d		;go back to last char of arg
	ldax d		;set b7
	ori 80h
	stax d
	inr c		;bump arg count
	inx d		;get next char
	call igwsp
	cpi ','		;comma?
	jnz defrm5	;if not, go check for ')'
	inx d		;else pass comma and look for identifier
	jmp defrm2
	
defrm5:	cpi ')'		;now must be either close or an error
	jz defrm1a
	stc		;error. set Cy and return
	ret

;
; Test to see if identifier at DE has already been defined in a previous
; #define line. Return Cy clear if previously defined.
;

defined:
	mov l,c		;look at the identifier.
	mvi h,0
	dad d
	xchg
	call igwsp
	call findd	;is it already defined? set C if not.
	lhld deftmp
	mvi a,0ffh	;also A = 0ffh if no carry,
	rnc
	cma		;A = 0 if carry
	ret


;
; Process all text substitutions on the line pointed to by DE:
;

prlin:	push d		;save pointer to start of line for later retrieval
	lda dstgf	;and save state of in-string flag
	push psw

	ora a		;in a string from previous line?
	jnz prln0	;if so, don't check for preprocessor directives

	call igwsp	;ignore leading white space, checking for directives
	lxi h,ifst	;line begin with #if?
	call stcmp
	jz prln1	
	ldax d		;line start with #?
	cpi '#'
	jz prl0a	;if so, don't preprocess.
	jmp prln0

prln1:	inx d		;line starts with #if. Pass "#if"
	inx d
	inx d
	call igwsp	;process rest of #if line.


prln0: 	dcx d
prlin9:	inx d
prlin0:	ldax d		;end of file?
	ora a
	jz prl0a	;if so, end of line for sure.
	cpi cr		;end of line?
	jnz prlin1
prl0a:	pop psw		;yes. all done. clean up stack (pushed dstgf)
	pop d		;and pop text pointer to start of line
	ret

prlin1:	lda dstgf	;in a string right now?
	ora a
	ldax d
	jz prlinc
	cpi '"'		;yes. close quote?
	jz prlinb	;if so, go flip "in string" state
	cpi '\'		;no. escape?
	jnz prlin9	;if not, just go to next char
	inx d		;if so, skip next character
	jmp prlin9

prlinb:	lda dstgf
	cma
	sta dstgf
	jmp prlin9

prlinc:	cpi '"'		;not in a string. start of string quote?
	jz prlinb	;if so, go flip "in string" state
	cpi ''''	;character constant?
	jnz prlind
	call chcnst1	;yes. pass over it
	jmp prlin0

	
prlind:	call varch2	;identifier?
	jc prlin9

prline:	call subst	;yes. do substitutions
	jc prlinf	;any done?
	pop psw		;yes. restore dstgf
	sta dstgf
	pop d		;and text pointer, then start processing line again.
	jmp prlin

prlinf:	inx d		;pass over rest of identifier name
	ldax d
	call varch
	jnc prlinf
	jmp prlin0	;and go for more stuff.


;
; Search for identifier pointed to by DE in the identifier
; table. Return Cy set if not found, else HL pointing to
; the arg count byte immediately following the name entry
; in the table:
;

findd:	lxi h,lblt+strsiz 	;start of identifier table

findd2:	mov a,m
	ora a
	stc
	rz
	shld deftmp
	call idcmp
	jnz findd3
	lhld deftmp
	push b
	lxi b,8
	dad b
	pop b
	ret

findd3:	lxi b,11
	dad b
	jmp findd2


;
; Ignore white space at DE:
;

igwsp:	ldax d
	inx d
	call twsp
	jz igwsp
	dcx d
	ret


;
; Do all potential substitutions for the text at DE:
;

subst:	call findd	;is identifier at DE a defined symbol?
	rc

	mov b,m		;put arg count in B
	inx h
	mov a,m
	inx h
	mov h,m
	mov l,a	

	mov a,b		;parameterized?
	ora a
	jz substs	;if so, go handle simple substitution

	ani 7fh		;otherwise put arg count in B
	mov b,a
	push d		;save  ->old text
	call pasvr	;param list?
	call igwsp	;ignore white space between var and possible param list
	cpi '('
	jz subst2
	lxi h,stgbd1
	jmp perrab

subst2:	push h		;save ->new text
	xchg		;put text ptr in HL
	push b
	call deform	;build list of param ptrs
	xchg		;put text ptr back in DE
	jnc subst3
	lxi h,stgbds
	jmp perrab		

subst3:	pop b
	cmp b
	jz subst4	;correct # of args?
	lxi h,stgbd2
	call perrab

subst4:	pop h		;HL ->new text
	push d		;save DE (->after old text)
	lxi d,txbuf	;now create new text image at txbuf

	mov a,m		;check for a null text image
	cpi cr
	jnz subst5	;if not null, handle normally
	mvi a,0ffh	;else place null FF byte in text area
	stax d
	jmp subst9a

subst5:	mov a,m
	inx h
	cpi cr
	jz subst9
	ora a
	jm subst6	;if arg code, go substitute
	stax d		;otherwise just a char
	inx d
	jmp subst5

subst6:	ani 7fh		;now substitute an arg for the code byte
	add a
	mov c,a
	mvi b,0
	push h
	lxi h,deformt
	dad b
	mov a,m
	inx h
	mov h,m
	mov l,a		;HL -> arg text represented by code byte
subst7:	mov a,m
	ani 7fh
	stax d
	inx d
	mov a,m
	inx h
	ora a 
	jp subst7	;keep copying till b7 is high on last char
	pop h
	jmp subst5

subst9:	dcx d		;turn on b7 of last char of text area
	ldax d
	ori 80h
subst9a:
	stax d
	pop d		;all done...now just replace old text with new text
	pop h
	push h
	call cmh
	dad d
	mov c,l
	pop d
	lxi h,txbuf
	call substs

	lda lcnt	;get extra line count
	mov b,a		;save in B
	cma		;negate for "mvtxt"
	inr a
	call mvtxt	

substa:	mov a,b
	ora a
	rz	
	mvi a,cr
	stax d
	inx d
	dcr b
	jmp substa

;
; Substitute text at HL for identifier at DE, length of id at DE is in C:
;

substs:	push h		;save ->new text
	push b		;save id length
	push h		;push ->new text
	call cmh	;HL = -(new text addr)
	xthl		;push -(new addr), get HL = new addr
subs2:	mov a,m		;compute length of new text
	inx h
	ora a
	jp subs2
	pop b		;get -(new addr) in BC
	dad b		;HL = length
	xthl		;push lengh, HL = id length (in L)
	mvi h,0		;HL = id length
	call cmh	;HL = -(id length)
	pop b
	push b		;BC = new text length
	dad b		;HL = difference in lengths
	mov a,l		;negate difference
	cma
	inr a
	call mvtxt	;shift text
	pop b
	pop h
	inx b
subs3:	dcx b		;insert new text
	mov a,b
	ora c
	rz
	mov a,m
	cpi 0FFh	;filler byte?
	jz subs4
	ani 7fh
subs4:	stax d
	inx d
	inx h
	jmp subs3
		

;
; Print out intermediate text if "-p" option given:
;

pitext:
	lda pflag	;return if intermediate text
	ora a		;	printout not desired
	rz

	lda werrs	;output to console only
	push psw
	xra a
	sta werrs

	lhld coda
	xchg		;DE points to text
	lxi h,0		;HL holds line count
	call initps	;initialize for pass through text
	sta nlflag	;enable null line numbering

	call crlf	; leading blank lines
	call crlf

ploop:	call gndch	;get next significant character
	ora a
	jnz ploop1

ploopd:	call crlf	;end of file.
	pop psw		;restore RED file output status
	sta werrs
	ret		;all done.

ploop1:	cpi cr
	jnz ploop2
	call ckabrt	;check for control-C on console
	lda nlflag	;ok to number null lines?
	ora a
	jnz ploop7	;print empty line number on first null line in	
	mvi a,1		; a series of null lines, but not on rest of them.
	sta nlflag
	call number
	jmp ploop7

ploop2:	cpi modbeg	;start of module?
	jnz ploop3
	shld nlcnt	;save line count for pushmn to use
	push d		;save ptr to filename
	call pushmn	;process start of include file.
	call crlf
	call indnt	;indent for new module name
	call indnt	;  extra indentation lines name up with text
	xchg		;save current DE in HL
	pop d		;get filename
	call pfnam2	;print out module name
	xchg		;put text ptr back in DE
	mvi a,':'
	call outch
	lxi h,0		;clear new line count
	jmp ploop

ploop3:	cpi modend	;and of module?
	jnz ploop4

	call popmn	;process end-of-module by putting out
	call crlf	;an extra cr-lf for readability.
	lhld nlcnt	;restore line count from where popmn put it
	jmp ploop


ploop4:	call number	;number the new line
ploop5:	cpi 255
	jz ploop6	;don't print filler bytes
	call outch
ploop6:	ldax d		;put out the line
	inx d
	ora a
	jz ploopd
	cpi cr
	jnz ploop5
	xra a
	sta nlflag	;enable numbering of next null line

ploop7:	inx h
	jmp ploop

;
; Get next char of text at DE, but if there's nothing but trash
; between it and the end of the line, just return the CR:
;

gndch:	ldax d
	inx d
	cpi 255
	jz gndch	;ignore FF's
	call twsp	;is next char white space?
	rnz		;if not, must use it.
	push psw	;else if rest of the stuff on the line is trash
	push d
	call tnbcr	;is it?
	jz gndch2
	pop d		;no, there's more useful stuff. 
	pop psw
	ret

gndch2:	pop psw		;no more useful stuff. return a CR
	pop psw
	inx d		;and pass over the CR.
	mvi a,cr
	ret	


;
; Return Z set if there's nothing but trash until the end of the line:
;

tnbcr:	ldax d
	cpi cr		;return?
	rz		;if so, NOT a garbage character
	call twsp	;white space?	
	rnz		;if not, not a garbage char
	inx d
	jmp tnbcr	;else keep scanning line for cr or non-space.

;
; Number the current pitext line:
;

number:	push psw
	call crlf
	call indnt	;indent 2 spaces per module stacking
numb2:	push h
	xra a		;all line numbers take 4 characters
	call prhcs
	pop h
	pop psw
	ret

;
; Indent according to module stack count (2 spaces per module):
;

indnt:	lda modstc	;get module nesting count
	dcr a		;print (A-1)*3 spaces
	mov b,a
	add a
	add b
	inr a
	mov b,a
indnt1:	dcr b
	rz
	mvi a,' '
	call outch
	jmp indnt1

;
; Perform constant substitutions, keyword encodings,
; and string constant encodings:
;

pass1:	call initps	;initialize for pass
	dcx d
ps1a:	inx d
ps1b:	call nextch	;process current char, return Cy on EOF
	rc		;done if EOF

ps1ba:	cpi '"'		;string to be processed?
	jz psstg

	push d		;no. constant?
	push b

	mvi a,1		;force error reporting on bad constant
	sta bcnstf
	call const
	mvi a,0
	sta bcnstf	;turn bad constant reporting back off

	mov a,c
	pop b
	pop d

	jc ps1c		;if not a constant, do potential keyword substitutions

	sui 3		;it was a constant.  substitute a constant code 
	call mvtxt	; for the text of the constant.
	mvi a,concd	;key byte
	stax d
	inx d
	mov a,l		;low order byte of value
	stax d
	inx d
	mov a,h		;high order byte of value
	stax d
	jmp ps1a

;
; Try to match the keyword at DE (whose first char
; is in A, already converted to upper case) with an
; entry in the keyword table. Hashing is used on the
; bits 0-3 of the first character. If no match is found
; and the first character was NOT a legal identifier
; character, then a syntax error occurs; else it is
; assumed the string is an identifier and it is left
; alone.
;

ps1c:	mov a,b
	cpi 05fh	;underscore?
	jz ps1h		;if so, assume identifier
	cpi 'A'		;legal identifier char?
	jc ps1c3
	cpi 'Z'+1
	jc ps1c2
	stc		;no. set carry for later.
	jmp ps1c3

ps1c2:	xra a		;yes, legal ident. char.
ps1c3:	push psw	;now let's do some hashing...
	mov a,b		;get 1st char of test string
	rlc
	ani 1eh
	push b
	mov c,a
	mvi b,0		;BC = disp into hash table
	lxi h,khasht	;HL = start of table
	dad b		;HL = address of sublist
	mov a,m	
	inx h
	mov h,m
	mov l,a		;HL -> sublist
	pop b
ps1d:	mov a,m		;done searching list?
	cpi 255
	jz ps1g
	ani 7fh		;no. 1st char match?
	cmp b		;if not, don't bother comparing
	jnz ps1f	;	rest of string
	push b		;OK, compare rest of string!
	call stcmp
	mov a,c		;save length of strings
	pop b
	jnz ps1f	;if no match, keep searching
	mov c,a		;match...restore length into C
	pop psw		;clean up stack
	mov a,m		;get 1 byte code into text
ps1e:	stax d
	inx d	
	dcr c
	jz ps1b
	mvi a,0ffh	;and fill out space with FF's
	jmp ps1e

ps1f:	mov a,m		;go to next table entry
	inx h
	ora a
	jp ps1f
	inx h
	jmp ps1d

ps1g:	pop psw		;search failed. could it have
	jnc ps1h	; been an identifier?
	lxi h,stg99	;no: must be syntax error.
	call perr
	jmp ps1a

ps1h:	ldax d		;possible identifier; let it be
	call varch
	jc ps1b
	inx d
	jmp ps1h


;
; process a string constant:
;

psstg:	push d
psstg1:	call glbl
	mov a,l
	cpi 1ah
	jz psstg1
	xchg
	lhld eofad
	mov m,e
	inx h
	mov m,d
	inx h
	shld stgcct
	inx h
	pop d
	push d
	xra a
	mov c,a
	sta scc
psstg2:	inx d
	ldax d

	ora a
	jz pstger	;if EOF, REALLY missing quote.

	cpi '"'
	jz psstg3
	cpi cr
	jz pstger	;if CR in text, error.
	cpi newlin	;same for newlin
	jz pstger
	call stgelt
	mov m,a
	call ckov
	inx h
	push h
	lxi h,scc
	inr m
	pop h
	jnz psstg2

pstger:	lxi h,stgmq
	jmp fatal

psstg3:	shld eofad
	mvi m,1ah
	lhld stgcct
	lda scc
	mov m,a		;set length byte for string
	pop h		;get start of string
	push h
	call cmh
	dad d
	lxi d,78
	call cmphd	;is HL < 78?
	jnc pstg3a	;if not, do big squish

	mov a,l		;else do normal mvtxt
	sui 2
	pop d
	call mvtxt
	jmp pstg3b

pstg3a:	dcx h		;do big squish
	dcx h		;now HL is # of bytes to squish
	pop d
	call bsqsh	;big squish routine

pstg3b:	mvi a,strcd
	stax d
	inx d
	lhld lbln
	dcx h
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	inx d

	mvi b,0
	lhld nlcnt
	dad b
	shld nlcnt

	inr c
psstg4:	dcr c
	jz ps1b
	mvi a,negone
	push b
	call mvtxt
	pop b
	mvi a,nlcd
	stax d
	inx d
	jmp psstg4

bsqsh:	push d
	lxi d,80
	call cmphd	;is HL < 80?	
	jc bsqsh2
	lxi d,-79
	dad d
	pop d
	call bsqsh	;bsqsh(HL-79);
	lxi h,79
	call bsqsh
	ret

bsqsh2:	pop d
	mov a,l
	call mvtxt
	ret

;
; Get next string element, set carry if EOF encountered:
;

stgelt:	cpi '\'
	rnz
	inx d
	ldax d
	cpi '"'
	rz
	cpi 0ffh
	jnz stglt2
stglt0:	inx d
	ldax d
	cpi 0ffh
	jz stglt0
	inr c
stglt1:	inx d
	ldax d
	cpi 0ffh
	jz stglt1
	jmp stgelt

stglt2:	push h
	dcx d
	call chkesc
	pop h
	dcx d
	ret

;
; Check for escape sequence at text at DE:
;

chkesc:	ldax d
	cpi '\'
	stc
	inx d
	rnz		;did we see a backslash?
	ldax d		;yes. save the next character for later retrieval
	inx d		;and point to character after that
	sta esctmp
	call mapuc
	cpi 'N'		;check for special escape codes. \n?
	jnz esc2
	mvi a,newlin
	ret
esc2:	cpi 'T'		;\t?
	jnz esc3
	mvi a,ht	;if so, turn into tab
	ret
esc3:	cpi 'B'		;\b?
	jnz esc4
	mvi a,bs	;if so, turn into backspace
	ret
esc4:	cpi 'R'		;\r?
	jnz esc5
	mvi a,cr	;if so, turn into carriage return
	ret
esc5:	cpi 'F'		;\f?
	jnz esc6
	mvi a,ff	;if so, turn into formfeed
	ret
esc6:	cpi '\'		;if \\, return \ character
	rz
	cpi 27h		;if \', return ' character
	rz
	call odig2	;otherwise check for octal digit
	jnc esc7
	lda bcnstf	;report constant errors?
	ora a
	lda esctmp	;if not octal digit, use the character and ignore the
	rz		; backslash, unless we need to report an error...
esc6a:	lxi h,stg8a	;bad octal constant error.
	jmp cnst2b


esc7:	mov l,a		;OK, we have an octal digit. Put into L
	ldax d		;look at next character
	call odig2	;octal digit?
	mov h,a		;save in H
	mov a,l		;get first digit
	jc esc8		;if second character not octal digit, go finish up
	mov a,h		;otherwise get second digit
	inx d		;point to potential third digit
	call shfto	;shift first digit to left
	ldax d		;look at potential third digit
	call odig2	;is it octal?
	mov h,a		;save in H in case it is
	mov a,l		;get total of first two digits
	jc esc8		;finish up  if no third digit
	mov a,h		;get third digit
	inx d		;point to character after third digit (closing qoute?)
			;and add third digit to the sum.

shfto:	mov h,a		;this little routine adds the octal digit in H to
	mov a,l		;the octal value in L, after multiplying the value
	rlc		;in L by 8.
	rlc
	rlc
	add h
	mov l,a
	ret

esc8:	push psw	;we've seen an illegal octal digit. if bcnstf is
	ldax d		;true and the current character isn't a quote, then
	cpi ''''	;report an error. Else just return the value.
	jz esc9		;Do we see a quote?
	lda bcnstf	;no...
	ora a
	jz esc9		;is bcnstf true?
	pop psw		;yes, so report error
	jmp esc6a

esc9:	pop psw		;don't need to report error; simply return value
	ret

odig2:	cpi '0'
	rc
	cpi '8'
	cmc
	rc
	sui '0'
	ret


;
; Look at current text at DE. If a constant is seen, return NC with
; the value of the constant in HL and C containing the length of the
; text of the constant. Else, return C set:
;

const:	ldax d
	cpi ''''	;character constant?
	jz chcnst	;if so, go handle it elsewhere

	call digt	;a decimal digit?
	rc		;if not, then it isn't the start of any constant
			;else it is.
	mvi c,0		;clear character count
	lxi h,0		;and clear accumulated value
	ora a		;first digit a zero?
	jnz deccn	;if not, go handle decimal constant
	inx d		;yes. look at next character after the zero.
	ldax d
	inr c		;and bump length count
	call mapuc
	cpi 'X'		;hex constant?
	jz hexcn	;if so, go handle it
	dcr c		;else must be an octal constant or 0. go back to
	dcx d		;the zero and let the octal handler take care of it.
	xra a
	jmp octcn

cnst2a:	lxi h,stg8	;come here to diagnose constant errors.
cnst2b:	call perr	;print the error
	stc		;set carry to indicate a bad happenning
	ret

hexcn:	inx d		;process a hex constant
	ldax d		;look at next digit
	call tsthd	;hex?
	jc cnst2a	;if not, there weren't any legal digits, so complain
	dcx d		;otherwise begin accumulating
hexcn1:	inx d		;go to next character
	inr c		;bump count
	ldax d
	call tsthd	;legal hex digit?
	jc octcn1	;if not, all done
	dad h		;else shift previous sum left by 4
	dad h
	dad h
	dad h
	add l
	mov l,a		;add new digit
	jmp hexcn1	;and go for more

octcn:	dad h		;process an octal constant
	dad h
	dad h
	add l
	mov l,a	
	inx d
	inr c
	ldax d
	call odigt
	jnc octcn
	ldax d		;see if this is a hex or decimal digit in an octal #...
	call tsthd
	jc octcn1	
	lxi h,stg8a
octcn0: call perr
octcn1:	xra a
	ret

deccn:	push d		;process a decimal constant..push text pointer
	inr c		;bump char count
	mov d,h
	mov e,l		;move previous sum to DE
	dad h		;multiply previous sum by 10
	dad h
	dad d
	dad h
	mov e,a		;add new digit
	mvi d,0
	dad d
	pop d		;get back text pointer
	inx d
	ldax d		;look at next digit
	call digt
	jnc deccn	;decimal digit? if so, go process it
	ldax d		;else check for a common error, a hex digit
	call tsthd
	jc octcn1	;if it isn't, no problem
	lxi h,stg8b	;else complain about illegal decimal digit
	jmp octcn0

;
; Evaluate character constant at DE, and print an error if no closing
; quote found:
;

chcnst:	call chcnst1
	jc cnst2a
	ret

chcnst1:  push d
	mvi b,0
	inx d
	call chkesc
	mov c,a
	ldax d
	cpi ''''
	jz chcns3
	call chkesc
	mov b,a
	ldax d
	cpi ''''
	jz chcns3
	pop h
	stc
	ret

chcns3:	inx d
	pop h
	call cmh
	dad d
	mov h,b
	mov b,l
	mov l,c
	mov c,b
	xra a
	ret


digt:	call mapuc
	sui '0'
	cpi 10
	cmc
	ret

tsthd:	call digt
	rnc
	sui 7
	cpi 10
	rc
	cpi 16
	cmc
	ret

odigt:	call digt
	rc
	cpi 8
	cmc
	ret



;
; This routine gets next character from text area, returning Cy set
; if EOF encountered, Z set if byte is to be ignored,  and properly
; handling MODBEG, MODEND and line count via NLCNT:
;

nextch:	ldax d
	cpi 0ffh	;ignore FF (filler) bytes
	jz nextc5

	ora a		;zero byte indicates EOF
	stc		;set Cy for EOF
	rz

	cpi modbeg	;adjust line number processing for include files
	jnz nextc2
	inx d
	call pushmn
	jmp nextch	;and go for next char

nextc2:	cpi modend
	jnz nextc3
	call popmn
	jmp nextc5	;and go for 'nother char

nextc3:	call mapuc
	mov b,a
	cpi cr
	jnz nextc4	;if not CR, all done...return the char

	call ckabrt	;found CR: check for abortion at end of every line
	call bumpnl
nextc4:	ora a		;clear Cy
	ret

nextc5:	inx d		;internal looping point for nextch
	jmp nextch


;
; Process all labels in the source file.
;

lblpr:
	mvi a,1
	sta mapucv	;DON'T map to upper case in stcmp routine
	call initps
	dcx d
lblp1:	inx d
	call pascd
	cpi lbrcd	; '{' for start of new function?
	jnz lblp2
	push d		;yes. 
	lhld nlcnt
	shld savnlc	;save line number of function start for error reports
	push h
	call flblp	;find labels
	pop h
	shld nlcnt
	pop d
	call flblv	;resolve labels.
	call ckabrt	;check for using typing control-C
	jmp lblp1

lblp2:	ora a		;EOF?
	jnz lblp1	;if not, go for more text.
	xra a
	sta mapucv	;restore stcmp to normal map-to-upper-case mode
	ret		;yes. all done.

;
; Find labels in a function.
;

flblp:	lxi h,lblt
	shld lblp
	mvi m,0
	xra a
	sta clev
	dcx d
flp0:	inx d
flp1:	call pascd
	jnz flp1a	;EOF before function ends?
			;if so...
lblerr:	lhld savnlc	;put start of function into line number register
	shld nlcnt
	lhld modstp	;advance module stack ptr to cancel popping at EOF
	lxi d,14
	dad d
	shld modstp
	lxi h,stgsuf	;screwed-up function message
	jmp fatal

flp1a:	cpi lbrcd	; '{'?
	jnz flp2
	lxi h,clev	;yes. bump level count.
	inr m
	jmp flp4

flp2:	cpi rbrcd	; '}' ?
	jnz flp3
	lxi h,clev	;yes. decrement level count.
	dcr m
	jnz flp4	;done with funciton?
	ret		;if so, return.

flp3:	cpi elscd	;look for keywords.
	jz flp4
	cpi docd
	jz flp4
	cpi semi
	jnz flp0	;pass expressions.

flp4:	inx d		;check for identifier.
	call igsht
	call varch	;legal first char?
	jc flp1
	push d		;yes. save text ptr.
	mvi c,0		;init char count
flp5:	inx d
	ldax d
	inr c
	call varch	;still an ident?
	jnc flp5
flpwsp:	cpi 255		;no. ignore trailing spaces
	jnz flpcln	;if no more spaces, check for colon	
	inx d		;else pass over the space
	ldax d		;get next char
	inr c		;bump count
	jmp flpwsp	;and keep looking for non-space

flpcln:	cpi colon	;no. followed by a colon?
	pop h		;pop start of label into HL
	jnz flp1
	xchg		;put start of label ptr into DE
	push d		;push it
	push b		;push count
	push b		; a few times
	push d		;and push label ptr again
	xra a
	sta sf
	call flbl
	pop d		;restore label ptr in DE
	pop b		;restore count into C
	jc flp5a
	lxi h,stgml	;all labels must be unique
	call perr
	lxi h,sf
	inr m
flp5a:	lhld lblp	;store the label away
flp6:	ldax d
	dcr c
	jz flp7
	cpi 255		;don't save space as part of the name
	jz flp6a	
	mov m,a
	inx h
flp6a:	inx d
	jmp flp6

flp7:	cpi 255		;last char space?
	jnz flp7a	;if not, treat normally
	dcx h
	mov a,m		;else get last legit char	
flp7a:	ori 80h
	mov m,a
	inx h
	xchg
	lhld lbln
	xchg
	mov m,e	
	inx h
	mov m,d
	inx h
	lda sf
	ora a
	jnz flp8
	shld lblp
	mvi m,0
flp8:	pop b
	pop d
	mov a,c
	sui 2
	call mvtxt
	call glbl
	mvi a,lblcd
	stax d
	inx d
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	jmp flp4

stgml:	db 'Duplicate label+'

;
; Resolve label references:
;

flblv:	dcx d
	xra a
	sta clev
flv0:	inx d
	call pascd
	jz lblerr	;if EOF, go complain

	cpi lbrcd
	jnz flv1
	lxi h,clev
	inr m
	jmp flv0

flv1:	cpi rbrcd
	jnz flv2
	lxi h,clev
	dcr m
	jnz flv0
	ret

flv2:	cpi gotcd	;"goto" keyword?
	jnz flv0
	inx d		;yes.
	call flbl	;label entered in table?
	jnc flv5	;if so, go process
	lxi h,stg26
	call perr
	push d
	mvi c,0
flv3:	ldax d
	call varch
	jc flv4
	inx d
	inr c
	jmp flv3

flv4:	pop d
flv5:	call lblsb	;do substitution
	jmp flv0

;
; Find label in label table:

flbl:	call igsht
	lxi h,lblt
flbl2:	mov a,m
	ora a
	stc
	rz
	call stcmp
	rz

flbl3:	mov a,m		
	ora a
	inx h
	jp flbl3
	inx h
	inx h
	jmp flbl2

lblsb:	mov a,m
	inx h
	mov h,m
	mov l,a
	mov a,c
	sui 3
	push h
	call mvtxt
	pop h
	mvi a,labrc
	stax d
	inx d	
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	ret


stcmp:	push d
	push h
	mvi c,1
stcp1:	mov a,m
	ani 7fh
	call mapuc0
	mov b,a
	ldax d
	call mapuc0
	cmp b
	jz stcp2
stcp1a:	pop h
	pop d
	xra a
	inr a
	ret
stcp2:	mov a,m
	ora a
	inx h
	jm stcp3
	inx d
	inr c
	jmp stcp1
stcp3:	mov a,b
	call varch
	jnc stcp4
stcp3a:	xra a
	pop d
	pop d
	ret
stcp4:	inx d
	ldax d
	call varch
	cmc
	jc stcp1a
	jmp stcp3a


;
; This section of code (PASS X) goes through the code and
; simplifies all constant expressions. Any code following
; an open bracket ("["), open parenthesis, "case" keyword,
; or assignment operator is checked to see if it is a 
; constant expression. If so, it is replaced by its simple
; constant equivalent. 
;

passx:	call initps
	dcx d
psx1:	inx d
	call igsht
	call cdtst
	jc psx1z
	inx d
	inx d
	jmp psx1
psx1z:	inx d
	ora a
	rz
	cpi comma
	jz psx1a
	cpi openb
	jz psx1a
	cpi open
	jz psx1a
	cpi cascd
	jz psx1a
	cpi rencd
	jz psx1a
	call asgnop
	jz psx1a
	dcx d	
	jmp psx1

psx1a:	call ckabrt	;check for using typing control-C
	push d
	lxi h,opstk
	shld opstp
	mvi m,0
	lxi h,valstk
	shld valsp
	call ckce
	jnc psx2
	pop d
	call igsht
	call cdtst	
	jc psx1
	inx d
	inx d
	jmp psx1

psx2:	xthl
	xchg
	dcx h
	dcx d
	mvi c,0

psx2a:	inx d
	ldax d
	cpi nlcd
	jnz psx2b
	inr c
psx2b:	mvi a,0ffh
	stax d
	mov a,l
	cmp e
	jnz psx2a
	mov a,h
	cmp d
	jnz psx2a
	pop h
	mvi a,concd
	dcx d
	dcx d
	stax d
	inx d
	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	mov a,c
	ora a
	jz psx1
	inx d
	mov a,c
	cma
	inr a
	push b
	push h
	call mvtxt
	pop h
	pop b
	mvi a,nlcd

psx2c:	stax d
	inx d
	dcr c	
	jnz psx2c
	dcx d
	jmp psx1

;
; This routine looks at text at DE and returns C reset
; if there is a legal constant expression there, with
; the value in HL; else C is set. DE is left pointing to
; the end of the expression, or wherever it became illegal.
;

ckce:	call ckce2
	rc
	call igsht
	cpi 0c0h
	jz qexpr
	ora a
	ret

ckce2:	push d
	call psce
	pop d
	rc
	call binop
	jz bexpr
	call sce
	ret

;
; Pass over a simple constant expression:
;	unop sce
;	sce
;

psce:	call igsht
	cpi mincd
	jz psce2
	cpi circum
	jz psce2
	call pvsce
	ret

psce2:	inx d
	jmp psce

;
; Pass very simple constant expression:
;	(ce)
;	constant
;

pvsce:	cpi open
	jnz pvsce2
	call mtchp
	call igsht
	ora a
	ret

pvsce2:	cpi concd
	stc
	rnz
	inx d
	inx d
	inx d
	call igsht
	ora a
	ret

;
; process ?: expression:
;

qexpr:	inx d
	mov a,h
	ora l
	jz qexp2
	call ckce
	rc
	cpi colon
	stc
	rnz
	inx d
	push h
	call ckce
	pop h
	ret

qexp2:	call psce
	cpi colon
	stc
	rnz
	inx d
	call ckce
	ret

;
; process simple constant expression:
;	unop sce
;	sce
;

sce:	call igsht
	cpi mincd
	jnz sce2
	inx d
	call sce
	rc
	call cmh
	ora a
	ret

sce2:	cpi circum
	jnz sce3
	inx d
	call sce
	rc
	call cmh
	dcx h
	ora a
	ret

sce3:	call vsce
	ret

;
; process very simple constant expression:
;	constant
;	(ce)
;

vsce:	cpi open
	jnz vsce2
	inx d
	call ckce
	rc
	call igsht
	cpi close
	stc
	rnz
	inx d
	cmc
	ret

vsce2:	cpi concd
	stc
	rnz
	inx d
	ldax d
	mov l,a
	inx d
	ldax d
	mov h,a
	inx d
	call igsht
	ora a
	ret

;
; handle binary expression:
;  sce binop sce binop sce ...
;

bexpr:	xra a
	call oppsh
	call sce
	rc
	call pshh
	call oppop
bxprab:	call igsht
	call binop
	jz bxpr2

bxpr1:	call tstop
	jz bxpr5
	call popb
	call poph
	call oppop
	call alugen
	call pshh
	jmp bxpr1

bxpr2:	call tstop
	jz bxpr3
	mov c,b
	call binop
	mov a,c
	cmp b
	jz bxpr4
	jc bxpr4

bxpr3:	ldax d
	call oppsh
	inx d
	jmp bexpr

bxpr4:	call popb
	call poph
	call oppop
	call alugen
	call pshh
	jmp bxprab

bxpr5:	call poph
	xra a
	ret

oppsh:	push h
	lhld opstp
	inx h
	shld opstp
	mov m,a
	pop h
	ret

oppop:	push h
	lhld opstp
	mov a,m
	dcx h
	shld opstp
	pop h
	ret

tstop:	push h
	lhld opstp
	mov a,m
	ora a
	pop h
	ret

popb:	push h
	call poph
	mov b,h
	mov c,l
	pop h
	ret

poph:	lhld valsp
	push d
	mov d,m
	dcx h
	mov e,m
	dcx h
	shld valsp
	xchg
	pop d
	ret

pshh:	push d
	xchg
	lhld valsp
	inx h
	mov m,e
	inx h
	mov m,d
	shld valsp
	xchg
	pop d
	ret




binop:	mvi b,9
	cpi mulcd
	rz
	cpi divcd
	rz
	cpi modcd
	rz
	dcr b
	cpi plus
	rz
	cpi mincd
	rz
	dcr b
	cpi 0b0h
	rz
	cpi 0b1h
	rz
	dcr b
	cpi 0b9h
	rz
	cpi 0bah
	rz
	cpi 0aeh
	rz
	cpi 0afh
	rz
	dcr b
	cpi 0aah
	rz
	cpi 0abh
	rz
	dcr b
	cpi ancd
	rz
	dcr b
	cpi 0bch
	rz
	dcr b
	cpi 0bdh
	ret

asgnop:	cpi letcd
	rz
	cpi 0a0h
	rc
	cpi 0aah
	jc asgn2
	xra a
	inr a
	ret

asgn2:	xra a
	ret


alugen:	cpi mulcd	;*
	jnz alu2
alu1s:	call initsn	;initialize sign memory
	push d
	xchg
	lxi h,0
alu1a:	mov a,b
	ora c
	jnz alu1b
	call aplysn	;apply sign memory to result
	jmp adone
alu1b:	dad d
	dcx b
	jmp alu1a

initsn:	xra a
	sta signm	;clear sign memory
	push h

	mov h,b
	mov l,c
	call tests	;test BC for negativity
	mov b,h
	mov c,l

	pop h
	call tests	;test HL for negativity
	ret

aplysn:	lda signm	;if signm true, negate HL
	ora a
	rz
	call cmh
	ret

tests:	mov a,h		;if HL is positive, do nothing
	ora a
	rp
	call cmh	;else negate HL
	lda signm	;and reverse sense of sign memory byte
	ora a
	mvi a,1
	jz tests2
	xra a
tests2:	sta signm
	ret	

alu2:	cpi divcd	;/
	jnz alu3
alu2s:	call initsn
	push d
	xchg
	lxi h,0
alu2a:	mov a,d
	cmp b
	jc alu2c
	jnz alu2b
	mov a,e
	cmp c
	jc alu2c
alu2b:	push h
	mov h,b	
	mov l,c
	call cmh
	dad d
	xchg
	pop h
	inx h
	jmp alu2a
alu2c:	call aplysn
	jmp adone

adone:	pop d
	ret

alu3:	cpi modcd	;%
	jnz alu4
	mov a,h
	ora a		;check sign of 1st operand
	push psw	;save for final result sign computation

	call initsn	;make sure mod is computed on positive numbers
	xra a		;zero sign memory to force unsigned result
	sta signm
	push d
	push h
	push b
	call alu2s
	pop b
	call alu1s
	call cmh
	pop d
	dad d
	pop d

	pop psw		;get sign of original 2nd operand
	rp		;if it was positive, leave result positive
	call cmh	;otherwise negate result	
	ret

alu4:	cpi plus	;+
	jnz alu5
	dad b
	ret

alu5:	cpi mincd	;-
	jnz alu6
	push d
	xchg
	mov h,b
	mov l,c
	call cmh
	dad d
	pop d
	ret

alu6:	cpi 0b0h	;<<
	jnz alu7
alu6a:	mov a,b
	ora c
	rz
	dad h
	dcx b
	jmp alu6a

alu7:	cpi 0b1h	;>>
	jnz alu8
alu7a:	mov a,b
	ora c
	rz
	mov a,h
	rar 	
	mov h,a	
	mov a,l
	rar
	mov l,a
	dcx b	
	jmp alu7a

alu8:	cpi 0bah		;<
	jnz alu9
alu8a:	mov a,h
	cmp b
	mov a,l
	lxi h,1
	rc
	dcx h
	rnz
	cmp c
	rnc
	inr l
	ret

alu9:	cpi 0b9h	;>
	jnz alu10
alu9a:	mov a,b
	cmp h
	mov b,l
	lxi h,1
	rc
	dcx h
	rnz
	mov a,c
	cmp b
	rnc
	inr l
	ret

alu10:	cpi 0aeh	;<=
	jnz alu11
	call alu9a
alu10a:	mov a,h
	ora l
	dcx h
	rnz
	inx h
	inx h
	ret

alu11:	cpi 0afh	;>=
	jnz alu12
	call alu8a
	jmp alu10a

alu12:	cpi ancd
	jnz alu13
	mov a,h
	ana b
	mov h,a
	mov a,l
	ana c
	mov l,a
	ret

alu13:	cpi 0bch	;^
	jnz alu14
	mov a,h
	xra b
	mov h,a
	mov a,l
	xra c
	mov l,a
	ret

alu14:	cpi 0bdh	;|
	jnz alu15
	mov a,h
	ora b
	mov h,a
	mov a,l
	ora c
	mov l,a	
	ret


alu15:	cpi 0aah	;==
	jnz alu16
	mov a,h
	cmp b
	jnz fals
	mov a,l
	cmp c
	jnz fals
tru:	lxi h,1
	ret

alu16:	mov a,h		;<not>=
	cmp b
	jnz tru
	mov a,l
	cmp c
	jnz tru
fals:	lxi h,0
	ret


;
; Table of hash addresses for each of the 16
; keyword sub-tables:
;

khasht:	dw tbl0,tbl1,tbl2,tbl3
	dw tbl4,tbl5,tbl6,tbl7
	dw tbl8,tbl9,tbla,tblb
	dw tblc,tbld,tble,tblf

p:	equ 80h

tbl0:	db ' '+p,0ffh	;spaces turn into FF's
	db  255
		

tbl1:	db '!','='+p,0abh
	db '!'+p,0bfh
	db 255

tbl2:	db 'RETUR','N'+p,8eh
	db 'BREA','K'+p,90h
	db 'REGISTE','R'+p,9eh
	db 'BEGI','N'+p,9bh
	db 255

tbl3:	db 'CHA','R'+p,80h
	db 'CONTINU','E'+p,91h
	db 'CAS','E'+p,98h
	db 'STRUC','T'+p,8bh
	db 'SWITC','H'+p,97h
	db 'SIZEO','F'+p,8fh
	db 'SHOR','T'+p,9fh
	db 255

tbl4:	db 'D','O'+p,95h
	db 'DEFAUL','T'+p,99h
	db 255

tbl5:	db 'ELS','E'+p,93h
	db '%','='+p,0a4h
	db '%'+p,0b8h
	db 'UNSIGNE','D'+p,82h
	db 'UNIO','N'+p,8ch
	db 'EN','D'+p,9ch
	db 255

tbl6:	db '&','&'+p,0ach
	db '&','='+p,0a7h
	db 'FO','R'+p,94h
	db '&'+p,0bbh
	db 'VOI','D'+p,81h		;synonym for "int"
	db 255

tbl7:	db 'WHIL','E'+p,96h
	db 'GOT','O'+p,8dh	;boo-hissssss
	db 255

tbl8:	db '('+p,0c2h
	db 255

tbl9:	db ht+p,0ffh
	db ')'+p,0c3h
	db 'I','F'+p,92h
	db 'IN','T'+p,81h
	db 255

tbla:	db ':'+p,0cah
	db '*','='+p,0a2h
	db '*'+p,0b6h
	db 255

tblb:	db ';'+p,0c6h
	db '{'+p,9bh
	db '['+p,0c8h
	db '+','+'+p,0b2h
	db '+','='+p,0a0h
	db '+'+p,0c4h
	db 255

tblc:	db ','+p,0c7h
	db '|','|'+p,0adh
	db '|','='+p,0a9h
	db '|'+p,0bdh
	db '<<','='+p,0a6h
	db '<','='+p,0aeh
	db '<','<'+p,0b0h
	db '<'+p,0bah
	db 255

tbld:	db cr+p,nlcd
	db ']'+p,0c9h
	db '}'+p,9ch
	db '=','='+p,0aah
	db '='+p,0beh
	db '-','>'+p,0b4h
	db '-','-'+p,0b3h
	db '-','='+p,0a1h
	db '-'+p,0b5h
	db 255

tble:	db '>>','='+p,0a5h
	db '>','='+p,0afh
	db '>','>'+p,0b1h
	db '>'+p,0b9h
	db '^','='+p,0a8h
	db '.'+p,0c5h
	db '^'+p,0bch
	db '~'+p,0cbh
	db 255

tblf:	db '?'+p,0c0h
	db '/','='+p,0a3h
	db '/'+p,0b7h
	db 255

;
; Data storage used by "readf":
;

datarea: equ $

secbuf:	ds 256		;sector buffer for reading in file
fsp:	ds 2
sptr:	ds 2
incf:	ds 1		; true if in an include file
pndsav:	ds 2
fnbuf:	ds 50		;file name buffer for reading in files
textp:	ds 2
lastc:	ds 1
lastc2:	ds 1
quotf:	ds 1		;true if in a quoted string
newusr:	ds 1		;new disk for #includes (CP/M)
newdsk:	ds 1		;new user area for #includes (CP/M)
atcnt:	ds 2		;last active line count for comment diagnostics
inclstk: equ $		;"include" stack

;
; Data used by "lblpr":
;

	org datarea	;overlap readf's data area with lblpr's data area

lblp:	ds 2
lblt:	equ $

	IF LASM
	end
	ENDIF
