	
;
; clinka.asm:
;
; BDS C Linker 3/86
;
; Copyright (c) 1980, 1981, 1982, 1986  by Leor Zolman, BD Software, Inc.
;
; Added -f option 4/15/81: forces loading all functions in next crl file
; Added -n option 9/9/82: activates NOBOOT mechanism in COM file
; Added defdsk/defusr mechanism to library file searches 9/12/82
; Added -z option to inhibit clearing of externals 11/15/82
; 

; MARC-specific features:
;   Gets deff.crl, deff2.crl and c.ccc from /libC unless -c is given
;   Added -i option to produce absolute image under MARC instead of default
; 	   load file formatted output.
;   Added -m option for MARC: makes c.ccc do a "mexmem" call before setting SP
;	Changed -m to cause NON-maxmem. I.e., replaced "call marc" with "nop"s.


 	org tpa

	jmp clink

;
; Configuration block:
;
	if not prerel
defdsk:	db 0ffh		;default disk for library files (0=A, etc., FF=current)
defusr:	db 0ffh		;default user area for lib files, FF = current
	endif

	if prerel
defdsk:	db 0ffh
defusr:	db 0ffh
	endif

defsub:	db 0		;default submit file on A: for distribution version
conpol:	db 1		;true to poll for console interrupts
wboote:	db 0		;true to perform warm-boot on exit
pstrip: db 1		;(dummy in CLINK:) parity strip
nouser:	db 0		;true to disable usage of set user area calls

;
;end configuration block
;

patch:	ds 19		;reserved for future expansion (adjust when adding
			;		bytes above)

clink:	shld zenvad	;save Z environment pointer (if in HL)
	lxi h,0		;save system SP
	dad sp
	shld spsav	;save system SP
	lxi sp,stack	;set up own stack
	call zsetup

	lhld errbyt
	mvi m,0		;no error by default

	call linit	;initialize linker

	lxi d,stg0	;print opening message
	call pstg

	xra a
	sta zsysf	;not zsystems, by default

	call comlin	;process immediate command line options

	IF CPM
	lda defdsk	;set default disk for library files
	inr a
	sta deffs
	sta deff2s
	sta deff3s
	sta ccc
	ENDIF


	lxi d,tab1	;set code area pointer to
	lhld tb1siz
	push h		;save tab1 size
	dad d
	dcx h
	shld tb1end	;save addr of end of tab1
	lxi d,100	;leave some space in case of
	dad d		; tab1 overflow
	shld cda
	shld cdp

	lxi h,tab1
	pop b		;get tab1 size
c4:	mvi m,0		;clear tab1
	inx h
	dcx b
	mov a,b
	ora c
	jnz c4		;if not, keep looping

	IF TESTING3	;print out contents of fcbs
	push psw
	call printf
	  db 'before reading c.ccc, fcbs is: ',0
	push h
	lxi h,fcbs
	call pfnamu
	pop h
	call crlf
	pop psw
	ENDIF

	IF CPM
	call setdu	;set up default library file user areas
	ENDIF

	call readc	;read in c.ccc (if not a segment)

	IF ZSYS
	lhld cda	;check load address for consistency
	lxi d,0bh	;offset for load addr in header
	dad d
	mov e,m
	inx h
	mov d,m		;DE now = load addr from header
	lhld runsat
	call cmphd
	jz c400
	
	lxi d,stglde
	call pstg
	jmp abort


c400:

;	IF CPM
	lda curusr	;go back to current user area
	mov e,a
	mvi c,sguser
	lda nouser
	ora a

	IF NOT ALPHA
	cz bdos
	ENDIF

;	ENDIF

	IF MARC
	lxi h,fcbt	;put crl extension on main filename
	push h
	call scrl
	pop h
	ENDIF

c40:
	IF TESTING3	;print out contents of fcbs
	push psw
	call printf
	  db 'before reading in main file, fcbs is: ',0
	push h
	lxi h,fcbs
	call pfnamu
	pop h
	call crlf
	pop psw
	ENDIF

	call gnfl	;open main file and read in directory
	jc abort	;abort if can't find it

	IF TESTING
	call printf
	   db 'just successfully opened main file',0
	ENDIF

	IF CPM
	mvi a,4
	sta nr
	call reads	;get external data area size and exaddr parameters
	ENDIF

	IF NOT CPM
	lxi h,tbuff
	lxi d,10
	call reads
	ENDIF

	lhld tbuff+3	;get external data size.
	shld smsf

	lda tbuff	;was explicit external area given?
	ora a
	jz c4a		;if not, skip setting eaddr
	sta eflag	;if so, tell that we have an explicit address
	lhld tbuff+1	;and copy the passed external address into eaddr
	shld eaddr

c4a:	lxi h,stgm	;read in "main" function
	call ft2	;is it there?
	jnc link2

	lxi h,stgmn	;try long version also
	call ft2
	jnc link2

	lxi d,stg6	;no. can't link.
c2:	call pstg	;print error message

	IF MARC
	lxi h,fcbt
	ENDIF

	call pfnamu	;print file in which error occurred
	jmp abort	;and abort

link2:	mvi a,255	;initialize function number to -1
	sta fcnt
	lxi h,stgmn

	mvi a,1
	sta gotf

	call entt1	;enter "main" function in table

	call pre	;read it in

	IF TESTING
	call printf
	   db 'returned from ''pre'' call for main function...',0
	ENDIF

link3:	call gtfns	;get all we can from current CRL file

link4:
;	IF CPM
	mvi a,1
	sta search	;search default path unless otherwise set by getfn

	mvi c,sguser	;set user area back to current
	lda curusr
	mov e,a

	lda nouser
	ora a

	IF NOT ALPHA
	cz bdos
	ENDIF

	lda savdrv	;any drive number saved?
	ora a
	jz link5
	dcr a		;if so, change back to it
	mov e,a
	mvi c,select
	call bdos	
	xra a
	sta savdrv	;and clear saved drive byte
;	ENDIF

link5:	call fungt	;are there any functions missing?
	jc linkd	;if not, all done

	call getfn	;else get name of new CRL file to search
	
	IF MARC
	lxi h,fcbt	;get pointer to the just-gotten crl filename
	ENDIF

	call gnfl	;open it and read in directory

	jnc link3	;if opened OK, go read in some functions...

;
; At this point, all files on the command line and all default
; library files have been loaded...
;

	IF MARC		;under MARC, set dflag to indicate that all
	mvi a,1		;deff?.crl files have been searched at least once.
	sta dflag
	ENDIF

	jmp link4	;go see if there's more linking to do.


linkd:	mvi a,1
	sta donef	;all done. scan rest of command line
	lda mflag	;if it hasn't been scanned through
	ora a		;already...
	cnz getfn
	call reslv	;resolve function references

	call getcdf2	;get default external address
	push h		;save in C.CCC for use by "codend()" function
	lhld cda
	lxi d,codend
	dad d
	pop d

	lda segf	;if segment, don't write into code!
	ora a
	jnz linkd0

	mov m,e
	inx h
	mov m,d

linkd0:	xchg

	lda eflag	;-e option specified?
	ora a
	jz linkd1
	lhld eaddr	;yes. get the value given in -e option instead
linkd1:	push h		;save as external starting address in C.CCC
	lhld cda	; for run-time use.
	lxi d,extrns
	dad d
	pop d

	lda segf	;if segment, don't write into code!
	ora a
	jnz lnkd1a

	mov m,e
	inx h
	mov m,d

lnkd1a:	xchg	

	shld extadd
	xchg
	lhld smsf	;get size of external area
	dad d		;add to start of external area
	push h		;and store where it'll be available to the
	lhld cda	;endext library routine
	lxi d,freram
	dad d
	pop d

	lda segf	;if segment, don't write into code!
	ora a
	jnz lnkd1b

	mov m,e
	inx h
	mov m,d

lnkd1b:
	lda zflag	;-z option given?
	ora a
	jz skip1

	lhld cda	;if so, disable the external clearing subroutine
	lxi d,clrex	;by changing the first byte of the appropriate
	dad d		;jump vector from C3 into C9.
	mvi m,0c9h

skip1:	
	lda segf	;if segment, don't do rest of this kludgery
	ora a
	jnz linkf

	lhld cda	;get ptr to startup code in HL

	IF ZSYS
	lxi d,lxiloc
	dad d		
	ENDIF
	
	lda taddrf	; -t option given?	
	ora a
	jnz linke

	lda nflag	;noboot option given?
	ora a
	jz linkd2	;if not, go handle normally

; Configure for NOBOOT:

	IF ZSYS
	push h
	lhld	cda
	lxi d,noboot
	dad d
	mvi m,1		;set noboot flag in runtime
	pop h
	jmp linkf
	ENDIF

	IF NOT ZSYS
	mvi m,0c3h
	inx h
	mvi m,(snobsp and 255)	;low byte of snobsp address
	inx h
	mvi m,(snobsp / 255)	;high byte of snobsp

	lxi d,8		;point HL at nobret jump op
	dad d
	mvi m,(nobret and 255)	;low byte of nobret address
	inx h
	mvi m,(nobret / 255)	;high byte of nobret address

	lhld curtop		;get top of available memory
	shld taddr
	jmp linkf
	ENDIF

linkd2:			;no -n given.

	mvi m,2ah	;no. generate initial "lhld ram+6, sphl"
	inx h

	lxi d,bdosp	;at run time, ram+6 points to base of bdos
	mov m,e
	inx h
	mov m,d
	inx h
	mvi m,0f9h	; sphl to set SP to top of TPA
	jmp linkf

linke:
	xchg		;save code loc in DE
	lhld taddr	;if -t option given, leave the "lxi sp, stack"
	xchg		; instruction there, and insert given value.

	inx h		;pass the lxi sp op

	mov m,e		;store value
	inx h
	mov m,d

linkf:
	IF ZSYS		;handle setup of Z3 Header:
	lhld	runsat
	xchg
	lxi h,tpa
	call cmphd	;standard load address?
	jz linkf2	;if so, no problem

	push d		;save runsat address

	lhld cda	;make type 3 header
	mvi m,0c7h	;RST 0, so won't crash vanilla CP/M

	lxi d,8		;offset to Z type
	dad d
	mvi m,3		;make type 3

	inx h
	inx h
	inx h		;point to load addr

	pop d		;get back runsat address
	mov m,e		;store runsat address in header
	inx h
	mov m,d
	ENDIF

linkf2:
	call pstat	;print out stats

	lxi d,stgok	;print completion message
	call pstg	;and free-ram diagnostic

	lhld bdosp	;protected memory highest available tpa addr
	mvi l,0

	xchg
	lhld cdp
	call cmh
	dad d
	mov a,h
	rar
	rar
	ani 3fh
	mov l,a
	mvi h,0
	dcx h
	call prhld
	lxi d,stglo
	call pstg

	IF TESTING3	;print out contents of fcbs
	push psw
	call printf
	  db 'right before calling writf, fcbs is: ',0
	push h
	lxi h,fcbs
	call pfnamu
	pop h
	call crlf
	pop psw
	ENDIF

	IF MARC
	call crlf
	mvi a,2
	sta consfd	;route write error messages to stderr
	ENDIF

	call writf	;write out file or execute directly

	IF CPM
exit:	lda wboote	;need to do warm boot?
	ora a
	jnz ram		;if so, go do it
	lhld spsav	;put saved CCP stack pointer in SP
	sphl
	lda ccpok	;CCP still intact?
	ora a
	rnz		;if so, return
	lda oktort	;ok to return despite ccpok being false?
	ora a
	rnz		;if so, return
	jmp ram		;otherwise warm-boot

subfile: db 1,'$$$     SUB',0,0,0,0
	ENDIF

	IF MARC
	lxi h,0		;return code: A OK
exit:	mvi c,m$exit
	jmp msys

ferror:	mvi c,m$error
	call msys
	lxi h,-1
	jmp exit

putext:	mov a,m
	ora a
	jz putxt2
	inx h
	jmp putext

putxt2:	pop d		;get pointer to extension to be put on
putxt3:	ldax d
	mov m,a
	inx h
	inx d
	ora a
	jnz putxt3	;copy to (HL) until zero encountered
	xchg		;then jump to byte after the zero byte to return
	pchl	
	ENDIF

;
; Set up ZCPR3 environment:
;

	
zsetup:	xra a
	sta zenvf
	inr a		;ok to return, by default 
	sta oktort

	lxi h,errdum
	shld errbyt

	lhld zenvad
	push h

	lxi d,1bh
	dad d
	mov e,m
	inx h
	mov d,m		;get reflexive env addr from env
	pop h		;original Z env value
	call cmphd	;save as reflexive address?
	jnz setp2a	;if not Z system, go handle

	push h
	lxi d,22h	;point to message buffer address
	dad d
	mov a,m
	inx h
	mov h,m
	mov l,a		;HL -> message buffer
	lxi d,6		;get address of error byte
	dad d
	shld errbyt	;save the address
	pop h

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
	lxi d,8		;get type
	dad d
	mov a,m
	sta envtyp
	
	ani 80h		;b7 hi?
	lhld ccpad
	jnz setup3	;if so, use ccpad as ccp address
setp2a:	lhld 0001h	;else calculate the old way
	lxi d,-1603h
	dad d

setup3:	xra a		;clear 'ccp volatile' flag
	sta ccpok	
	xchg		;put ccp address in DE
	lhld bdosp
	mvi l,0		;zero out low-order byte
	call cmphd	;set Cy if [BASE+6,7] < CCP
	jc setup4	;if BASE+6 < CCP, use BASE+6 as end of prot mem
	xchg		;else use CCP as end of prot. mem.
	mvi a,1		;and set ccp volatile flag
	sta ccpok
	xra a		;NOT ok to return by default!
	sta oktort	;  (go by value of ccpok)
setup4:	shld curtop
	ret


envtyp:	ds 1
zenvf:	ds 1	;true if running under ZCPR3
zenvad:	ds 2
ccpad:	ds 2 	;address of CCP for type 80h ZCPR3
oktort:	ds 1	;ok to return despite ccpok being false?
errbyt:	dw errdum	;address of Z3 error byte
errdum:	ds 1	;if CP/M, errbyt points here

	IF CPM
fcbt:	db 0
	db '        '
	db '   '
	db 0,0,0,0
	ENDIF

	IF CPM
fcbs:	db 0		;name of output file buffer
	db '        '	;8 filename spots
	db 'COM'
	db 0,0,0,0
	ENDIF


	IF NOT ALPHA AND NOT ZSYS
stg0:	db 'BD Software C Linker   v'
	ENDIF
	
	IF NOT ALPHA AND ZSYS
stg0:	db 'BD Software C Linker (for ZCPR3)  vZ'
	ENDIF

	IF ALPHA
stg0:	db 'BDS Alpha-C Linker   v'
	ENDIF

	IF NOT ZSYS
	db '1.'
	ENDIF

	db version

	IF ZSYS
	db '.'
	ENDIF

	db update

	IF PREREL
	db ' (pre-release)'
	ENDIF

	IF CPM
	db cr,lf,0
	ENDIF

	IF MARC
	db '  for MARC',lf,0
	ENDIF

stg2:	db 'Error reading: ',0

	IF CPM
stgnua:	db 'No user area prefix allowed on main filename',0
stg5:	db lf,'Dir full; ',cr
	ENDIF

	IF NOT CPM
stg5:	db lf,'Error creating output file: ',0
	ENDIF

stg3:	db lf,'Error writing: ',0
stg4:	db lf,'Can''t close: ',0
stg6:	db 'No main function in ',0
stgas:	db cr,lf,'Missing function(s):',cr,lf,0
stg7:	db lf,'Type the name of a CRL file '
	db 'to scan; ',cr,lf

	IF CPM
	db '<CR> to scan all DEFF files, '
	ENDIF

	IF NOT CPM
	db '<CR> to scan all deff?.crl files, '
	ENDIF

	IF CPM
	db '^Z-<CR> to abort: ',0
	ENDIF

	IF NOT CPM
	db 'or your ''quit'' char to abort: ',0
	ENDIF

stgm:	db 9dh
stgmn:	db 'MAI','N'+80h,0

	IF CPM
deffs:	db 0,'DEFF    CRL',0
deff2s:	db 0,'DEFF2   CRL',0
deff3s:	db 0,'DEFF3   CRL',0
ccc:	db 0,'C       CCC',0
	ENDIF

	IF NOT CPM
deffs:	db '/libC/deff0.crl',0
ccc:	db '/libC/c.ccc',0
	ENDIF

stg1:	db 'Can''t find ',0
stglca:	db 'Last code address: ',0
stgext:	db cr,lf,'Externals start at ',0
stgxt2:	db ' occupy ',0
stgxt3:	db 'bytes, last byte at ',0
stgtm:	db cr,lf, 'Top of memory: ',0
stgds:	db cr,lf, 'Stack space: ',0
stgabt:	db bell,'Link ABORTED',cr,lf,0


	IF CPM
stgdo:	db bell,cr,lf,'Warning! Externals extend into the BDOS!',cr,lf,0
	ENDIF

	IF MARC
stgdo:	db lf,'Warning! Externals extend into system memory!',lf,0
	ENDIF

	IF CPM
stgdo2:	db bell,lf,'Warning! Externals overlap code!',cr,lf,0
	ENDIF

	IF MARC
stgdo2:	db lf,'Warning! Externals overlap code!',lf,0
	ENDIF

stgom:	db 'Out of memory',0
stglo:	db 'K link space remaining',cr,0
stgok:	db 'Writing output...',cr,lf,0
stgserr: db 'Bad symbols',0
stgdeb:	db lf,'Executing:',cr,lf,0
stglde:	db 'Load Address does not match Z3 Header in Runtime Pkg',cr,lf,0
stgbop:	db 'Bad option: -',0
stgt1o:	db 'Ref table overflow',0
stgver:	db 'Missing arg to -'
stgdps:	db 'Symbol re-defined: ',0
stgdpf:	db 'Ignoring duplicate function: ',0
stgabo:	db '^C',cr,lf,0

	IF MARC
stgnof:	db 'Usage:  '

	db 'clink <main_crl_file> [-cmsvw]'
	db ' [-e <addr>] [-t <addr>] [-l <addr>]'
	db lf

	db tab,'[-o <new_name>] [-y <sym_name>]'
	db ' [<crl_file> [<crl_file>] ... ]'
	db 0
	ENDIF

opletr:	ds 1
	db 0

stgtmf:	db 'Sorry; 255 funcs max',0


;
; Initialize linker:
;

linit:	mvi c,sguser	;get current user area
	mvi e,0ffh
	lda nouser
	ora a

	IF NOT ALPHA
	cz bdos
	ENDIF

	IF ALPHA
	nop
	nop
	nop
	ENDIF

	sta curusr	;save current user area number
	lda defsub
	inr a
	sta subfile

	xra a
	sta wrsmf	; "outch" not to write to SYM file

	IF MARC		;under marc, initialize message output fd
	mvi a,1
	sta consfd	;route first msgs to stdout (1)
	lxi h,0
	shld noffst	;search /libC by default for deff*.crl & c.ccc

	mvi c,m$memory	;get top of memory value before doing maxmem call
	call msys
	xchg
	shld taddr	;taddr before maxmem call

	mvi c,m$maxmem	;do a maxmem call
	call msys
	mvi a,1
	sta maxmd	;note that we've done the maxmem call (once only)

	mvi c,m$memory	;get top of memory AFTER maxmem call has been done
	call msys
	xchg
	shld curtop	;and as physical top of memory for linkage
	ENDIF

	IF MARC		;if MARC version, get argc and argv:
	sta marcfd	;clear marcfd in case of usage diagnostic
	pop psw		;skip return address

	pop h		;get argc passed by MARC
	mov a,l		;set A = argc
	dcr a
	lxi d,stgnof	; complain and abort if no filename given
	jz stgab

	sta argc	;else save argc for later use

	pop h		;get argv passed by MARC
	inx h
	inx h		;point argv to main filename pointer
	shld argv	;save pointer to main filename pointer

	mov a,m		;indirect to get pointer to main filename
	inx h
	mov h,m
	mov l,a

	push h		;save it on stack
	lxi d,fcbt	;copy main filename to fcbt for use in reading
	call movfn	;   in main crl file
	pop h		;and also copy to fcbs for use in writing out file
	lxi d,fcbs
	call movfn
	ENDIF

	IF TESTING3	;print out contents of fcbs
	push psw
	call printf
	  db 'after first setting fcbs, fcbs is: ',0
	push h
	lxi h,fcbs
	call pfnamu
	pop h
	call crlf
	pop psw
	ENDIF


	IF CPM
	lxi d,tbuff	;set DMA address
	mvi c,sdma	;(helps me debug 4200h version
	call bdos	; on 0-based CP/M system)

	lxi h,fcb	;save filename argument
	lxi d,fcbs
	call movfn	;move main filename to fcbs
	lxi h,fcbs+9	;and give it a COM extension by default
	mvi m,'C'
	inx h
	mvi m,'O'
	inx h
	mvi m,'M'
	ENDIF

	xra a		;clear some flags:
	sta segf	;assume not a segment by default
	sta debugf	;don't immediately execute file
	sta statf	;default to no stats
	sta dflag	;haven't searched DEFF.CRL yet
	sta quietf	;report unfound files
	sta rdngsm	;not reading in symbols from disk
	sta taddrf	;no top of memory address given yet
	sta eflag	;no external data addr given yet
	sta donef	;all function references not resolved yet
	sta wflg	;controls writing of SYM file

	IF CPM
	sta zflag	;don't inhibit clearing of externals
	sta d2flag	;haven't searched DEFF2.CRL either
	sta d3flag	;haven't searched DEFF3.CRL either
	sta nflag	;no noboot option given yet
	sta hflag	;don't force lhld 4206 unless -h given
	sta savdrv	;no drive number currently saved
	ENDIF

	IF MARC
	sta dlast	;last DEFF?.CRL searched (0 for none)
	sta marcfd	;no file open yet
	sta iflag	;no image mode output file unless -i used
	sta oflag	;haven't seen -o yet
;	sta maxmd	;haven't done maxmem call yet
	ENDIF

	IF NOT FORCE
	sta fflag	;no forced loading of all funcs in crl file
	ENDIF

	inr a
	sta mflag	;more text to process in command line

	IF FORCE
	sta fflag	;force loading of all funcs in crl file
	ENDIF

	IF CPM
	lda fcb		;default disk to get CRL files from
	sta dcrl	; is disk where source file came from

	lhld curtop	;set protected memory address
	shld taddr
	ENDIF	

	lxi h,dt1siz	;set default tab1 size
	shld tb1siz

	lxi h,tpa	;default starting address
	shld runsat	; (alterable only if -l option used)
	ret


;
; Process immediate command line options:
;

comlin:
	IF CPM
	lxi h,fcb+1	;see if user area given as part of filename
	call gdec
	jc clink0	;if not, OK
	mov a,m		;else, followed by slash?
	cpi '/'
	jnz clink0	;if not, no problem
	lxi d,stgnua	;else abort with "no user number allowed" message
	jmp stgab

clink0:	lxi h,cline	;copy command line from tbuff to area at cline
	shld cptr	;under CP/M
	lxi h,tbuff
	mov b,m
	inr b
	inx h
	lxi d,cline
c0:	dcr b
	jz c0a
	mov a,m
	stax d
	inx h
	inx d
	jmp c0
	ENDIF

	IF NOT CPM
	mvi a,2
	sta consfd	;future msgs to go stderr

	lxi h,cline	;copy all MARC args into area at cline, emulating
	shld cptr	;CP/M command line passage
	xchg		;DE is destination area
	lhld argv	;HL will point to arg text
c00a:	lda argc	;get arg count
	ora a
	jz c0a		;if done, go process the line
	dcr a
	sta argc	;not done. debump argc and copy current arg text
	push h		;save pointer to text address
	mov a,m
	inx h
	mov h,m
	mov l,a		;HL points to actual arg text
	call movfn	;move it to (DE)
	dcx d		;stomp on the trailing null from the last arg text
	mvi a,' '	; (replace it with a space)
	stax d
	inx d
	pop h		;restore arg pointer
	inx h		;bump to next pointer
	inx h
	jmp c00a	;and go for it
	ENDIF	

c0a:	xra a		;OK, command line has been copied
	stax d		;terminate with null byte
	lxi h,cline	;find first non-space char
	call igsp
	ora a		;if end of line,
	jz c1		; don't pass over main filename
c0c:	inx h		;else do.
	mov a,m
	ora a
	jz c1
	call twhite
	jnz c0c
	call igsp	;pass space between this and next arg

c1:	shld cptr	;save text pointer for getfn routine

;
; Here process -l and -r and -v; set tb1siz to optional arg of -r,
; set runsat to optional arg of -l, and set segf if -v given:
; also handle new -c option for MARC
; Also handle new -m option to call MEXMEM under MARC...
;
	
	dcx h
prep0:	inx h
prep:	mov a,m
	ora a		;done preprocessing command line?
	rz		;if so, return 

	cpi '"'		;possible option to "-d"?
	jnz prep3	
prep2:	inx h		;if so, skip it totally
	mov a,m
	ora a
	rz		;if null byte, done scanning command line
	cpi '"'
	jnz prep2
	jmp prep0	;then continue scanning for useful options

prep3:	cpi '-'		;no. dashed option?	
	jnz prep0	;if not, ignore it
	shld fargb	;else save first arg byte
	inx h
	mov a,m		;get option letter
	call mapuc
	sta opletr	;save for error msg
	inx h

	cpi 'C'		;set disk to get c.ccc and deff*.crl from
	jz copt

	IF CPM
	cpi 'H'		;little kludge (for Leo only)
	jz hopt
	ENDIF

	IF MARC
	cpi 'I'		;image mode?
	jz iopt
	ENDIF

	cpi 'L'		;set load addr?
	jz lopt
	cpi 'R'		;set ref table size?
	jz ropt
	dcx h
	cpi 'V'		;declare a segment?
	jnz prep
	inx h
	sta segf	;this one's easy.
purge:	xchg		;put current text addr in DE
purge1:	lhld fargb	;get 1st byte of arg
purge2:	mvi m,' '	;clear it to a space
	inx h
	call cmphd	;done?
	jnz purge2	;keep blanking till done.
	jmp prep	;and go pre-process some more

ropt:	call gtaddd	;get argument
	xchg
	mov a,h
	ora a
	jz purge1	;must be at least 100h to be reasonable!
	shld tb1siz	;set tab1 size;
	jmp purge1	;and go purge text from command line

copt:
	IF CPM
	call igsp
	call cnvtd	;get source disk for C.CCC and DEFF*.CRL
	sta defdsk	;(under CP/M only; MARC version assumes
			;all this stuff is in /etc)
	inx h		;bump text pointer to possible user area
	call gdec	;user area given?
	jc copt9	;if not, done with -c option
	sta defusr	;else user area given. Store it at defusr
	
copt9:	xchg
	jmp purge1

;
; Scan text at HL for a decimal number. If found, return in B and clear Cy.
; Return Cy set if no legal decimal number.
; Upon exit, HL is left pointing to the first non-decimal-digit character.
;

gdec:	mvi b,0
	call igsp
	call legdd
	mvi a,0
	rc	
gdec1:	mov a,m
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
	inx h
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
	ENDIF

	IF NOT CPM
	xchg		;put text pointer in DE
	lxi h,6		;set noffst to 6 so current directory is
	shld noffst	;searched for deff*.crl & c.ccc instead of /libC
	jmp purge1
	ENDIF


	IF CPM
hopt:	sta hflag	;kludge for Leo, under CP/M only
	xchg
	jmp purge1
	ENDIF

	IF MARC
iopt:	sta iflag	;set image mode to produce absolute image
	xchg
	jmp purge1
	ENDIF

lopt:	call gtaddd	;get argument
	xchg
	shld runsat	;set origin address
	jmp purge1	;and purge from command line	




;
; Check for user abortion:
;

ckabrt:	push psw
	push h
	push d
	push b

	IF CPM
	lda conpol	;are we polling for interrupts?
	ora a
	jz noabrt	;if not, ignore console...

	mvi c,intcon	;interrogate console status
	call bdos
	ora a
	jz noabrt
	mvi c,coninp
	call bdos
	cpi 3		;control-C aborts
	jnz noabrt

	lxi d,stgabo	;abort.
	jmp stgab
	ENDIF

	IF NOT CPM
	mvi c,m$ichec
	call msys
	ENDIF

noabrt:	pop b
	pop d
	pop h
	pop psw
	ret


;
; Here is a little routine to take an ASCII char in A that
; is either a space or a disk letter, and return the
; appropriate code in A to put in the first byte of an
; fcb accessing the given disk:
;

	IF CPM
cnvtd:	call twhite
	jnz cnvtd2
	xra a		;if space, return 0
	ret

cnvtd2:	sui 'A'		;else return 0 for A, 2 for B, etc.
	cpi 'Z'+1
	rc		;OK if a letter
	xra a		;else change to zero
	ret
	ENDIF

;
; Given the address of a function as stored in memory during
; the linkage process, this function returns the actual address
; that the function will occupy when executing:
;

getcdf:	lhld runsat
	push d
	xchg	
	lhld cda
	call cmh
	dad d
	pop d
	ret

getcdf2: call getcdf
	xchg
	lhld cdp
	dad d
	ret


;
; Print out the contents of register pair HL in ASCII:
;  (uses the simple gas-pump algorithm)
;

prhld:	push d
	push h
	lxi h,'  '
	shld ascb
	lxi h,' 0'
	shld ascb+2
	pop h
	inx h
prh0:	mov a,h
	ora l
	jz prnt
	dcx h
	push h
	lxi h,ascb+3
prh1:	mov a,m
	call twhite
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
prnt:	lxi d,ascb
	call pstg
	pop d
	ret

;
; Print out file name in the fcb, with user number preceding:
; 
pfnamu:
	lda nouser
	ora a
	jnz pfnam	;if user areas disabled, don't even try
	mvi e,0ffh
	mvi c,32
	call bdos	;get current user number
	call prad	;print out value of A in decimal
	mvi a,'/'
	call outch	;follow with slash, then print rest of filename

;
; Routine to print out the name of the file
; in the fcb:
;
	
	IF CPM
pfnam:
	push d
	push b
	lda fcb
	ora a		;if no special disk, don't print a letter
	jnz pfnam1
	push d
	push h
	mvi c,gdisk
	call bdos
	inr a	
	pop h
	pop d
pfnam1:	adi '@'		;make it into the disk letter
	call outch
	mvi a,':'
	call outch
pfnam2:	mvi b,8
	lxi d,fcb+1
	call pnseg	;print filename
	mvi a,'.'
	call outch
	mvi b,3
	call pnseg	;print extension
	call crlf
	pop b
	pop d
	ret


;
; Print out user number in A in decimal:
;

prad:	push b
	call prad2
	pop b
	ret

prad2:	mvi c,0		;compute first digit
prad3:	cpi 10		;less than 10?
	jc prfd		;if so, print first digit
	sui 10		;else subtract 10
	inr c		;bump tens digit
	jmp prad3
	
prfd:	push psw	;save last digit
	mov a,c		;look at first digit
	ora a		;zero?
	cnz prhd	;if not, print it
	pop psw		;get last digit
	jmp prhd	;print it

;
; print out string at DE, max length B,
; delete spaces:
;

pnseg:	ldax d
pns2:	call outch
	inx d
	dcr b
	rz
	ldax d
	call twhite
	jnz pns2
pns3:	inx d
	dcr b
	jnz pns3
	ret
	ENDIF

;
; Print out statistics in response to -s option:
;

pstat:	call alphab	;alphabetize symbols

;	lda statf	;if printing stats, put out a crlf
;	ora a
;	cnz crlf

;	call crlf

	call wrsmb	;write symbols to disk and console

;	lda statf	;if stats desired,
;	ora a		;print them out
;	jnz pst00
;
;	call ovrlap	;check for code/externals overlap
;
;	lhld smsf	;and check for external area overflow into system
;	xchg
;	lhld extadd
;	dad d
;	jc exovfl	;if carry, REAL overflow!
;	xchg		;DE holds end of external area
; 	lhld taddr	;get end of TPA address
;	call cmphd	;HL better be less than DE....
;	rnc		;if so, no problem
;exovfl:
;	lxi d,stgdo	;else trouble!
;	call pstg
;	ret

pst00:	lxi d,stglca	; "last code address = ..."
	call crlf
	call pstg
	call getcdf2	;get last code addr. + 1
	dcx h
	call prhls	;print last code address out

;
; Print external data stats, but DON'T if linking a segment
; and no -e option is given:
;

	lda segf
	ora a
	jz pst00a	;if not linking a segment, print all stats
	lda eflag	;yes, linking a segment. -e option given?
	ora a
	jz pst0		;if not, skip printing external numbers

pst00a:	lxi d,stgext	;"external data starts at "
	call pstg
	lhld extadd
	push h
	call prhlc
	lxi d,stgxt2	;"occupy "
	call pstg
	lhld smsf
	push h		;save size of external data area
	call prhls
	lxi d,stgxt3	;" bytes, and and end at"
	call pstg
	pop d		;get size of externals
	pop h		;get start of externals
	dad d		;get ending address of externals
	dcx h
	push h		;save for local store calc later
	mov a,d		;special case of no externals
	ora e
	jnz skpfdg
	inx h
skpfdg:	call prhls
	pop h

pst0:	push h
	lxi d,stgtm	;"top of memory=..."
	call pstg
	lhld taddr
	dcx h
	push h		;save top of memory address
	call prhls

	lda segf
	ora a
	jz pst1

	pop d
	pop d
	jmp crlf

pst1:	lxi d,stgds		;print data & stack space 
	call pstg		; only if not a segment
	pop d			;get saved top of memory address in DE
	pop h			;get external ending address in HL
	call cmphd		;check for overflow
	push psw		;save Cy flag for msg later
	jc pst2			;externals end before top of memory?
	mvi a,'-'		;no-- print a negative sign
	call outch	
	xchg			;exchange so it'll come out positive
pst2:	call cmh
	dad d
	call prhls		;print out amount of stack space
	call crlf
	pop psw			;check for overflow condition
	lxi d,stgdo		;data overflow message
	cnc pstg

ovrlap:	call getcdf2		;check for externals/code overlap
	xchg			;put end of code addr in DE
	lhld extadd		;get external base address
	call cmphd		;is external base < end of code + 1?
	lxi d,stgdo2
	cc pstg	
	ret

wrsmb:	mvi a,4
	sta gotf	;init symbols-per-line countdown
	sta wrsmf	;and make outch write to disk as well as console
	lda wflg	;	(to disk only if wflg is on)
	ora a
	jz wrsm2	;write symbols to disk?

	IF CPM
	lxi h,fcbs
	lxi d,fcb
	call movfn
	lxi h,fcb+9
	mvi m,'S'
	inx h
	mvi m,'Y'
	inx h
	mvi m,'M'
	ENDIF

	IF NOT CPM
	lxi h,fcbs
	lxi d,fcbt
	push d
	push d
	call movfn
	pop h
	call putext
	   db '.sym',0
	pop h
	ENDIF

	call crate2	;if so, create symbols file
	lxi h,tbuff	;init buffer pointer
	shld bufp
wrsm2:	lhld nsmbs	;set BC = countdown of # of symbols
	mov b,h
	mov c,l
	lxi d,0		;while DE will go the other way
wrsm3:	call wsmb	;write out a single symbol and address
	inx d		;bump pointer to next symbol pointer
	inx d
	dcx b		;de-bump countdown
	mov a,b		;done?
	ora c
	jnz wrsm3	;if not, keep loopin'

	call crlf	;done. put out trailing crlf

	IF CPM
	mvi b,1ah	;terminating control-Z for CP/M (cough cough)
	lda wflg	;were we writing to a file?
	ora a
	cnz wrb3	;(into file only)
	ENDIF

	xra a
	sta wrsmf	;turn off kludge flag
	lda wflg
	ora a		;writing to disk?
	rz		;if not, all done

	IF CPM
	mvi b,1ah	;if so, pad file with control-Z's for CP/M
	lhld bufp
	mov a,l
	ani 7fh		
	jz wrsm6
wrsm4:	mov a,l
	ani 7fh
	jz wrsm5
	mov m,b
	inx h
	jmp wrsm4
wrsm5:	lxi h,tbuff
	call writs
	ENDIF

	IF NOT CPM	;for MARC, just write out rest of the buffer
	lhld bufp
	mov a,l
	ani 7fh
	jz wrsm6
	mov e,a		;put byte count in DE
	mvi d,0
	lxi h,tbuff
	call writs	;write out remainder of symbol text buffer
	ENDIF

wrsm6:	call close
	ret

wsmb:	push d		;write out symbol #DE and its value
	lxi h,tab2	;first get value
	dad d
	mov a,m
	inx h
	mov h,m
	mov l,a		;HL = raw value
	push h		;add offset	
	call getcdf
	pop d
	dad d
	call prhls	;print out value in hex
	lxi h,wsp	;now get name
	pop d
	dad d
	mov a,m
	inx h
	mov h,m
	mov l,a
	call pfnm	;print out name
	lda gotf	;see if we trail with tab or crlf
	dcr a
	sta gotf
	jz wsmbcr
	mvi a,9		;tab.
	call outch
	ret
wsmbcr:	call crlf	;crlf
	mvi a,4		;reset line count
	sta gotf
	ret

	
;
; Alphabetize symbols for SYM file output and stat printout:
;

alphab:	call setwsp	;set up swp with pointers to symbols in tab1
	lxi b,0		;initalize outer loop variable
ab1:	lhld nsmbs	;done with outer loop?
	dcx h
	call cmpbh
	rnc		;if so, all done sorting
	mov d,b		;else initialize inner loop
	mov e,c
	inx d
ab2:	lhld nsmbs	;done with inner iteration?
	dcx h
	call cmphd
	jc ab4		;if so, iterate outer loop
	call cmptx	;else compare two symbols
	jnc ab3		;out of order?
	lxi h,wsp	;yes. swap pointers.
	shld tbase	
	call swap
	lxi h,tab2
	shld tbase
	call swap
ab3:	inx d		;bump inner loop variable
	jmp ab2
ab4:	inx b		;bump outer loop variable
	jmp ab1

cmpbh:	mov a,b		;return C set if BC < HL
	cmp h
	rnz
	mov a,c
	cmp l
	ret

cmphd:	mov a,h		;return C set if HL < DE
	cmp d
	rnz
	mov a,l
	cmp e
	ret

swap:	lhld tbase	;switch the 16 bit values at tbase+BC
	dad b		;			and  tbase+DE
	dad b
	push b		;save BC
	push h		;save tbase+BC
	mov c,m		; BC := (tbase+BC)
	inx h
	mov b,m
	lhld tbase
	dad d
	dad d
	push d		;save DE
	mov e,m		; DE := (tbase+DE)
	inx h
	mov d,m
	mov m,b		; (tbase+DE) := (tbase+BC)
	dcx h
	mov m,c
	pop h		;get back original DE in HL
	xchg		;put into DE, and HL:=(tbase+DE)
	mov b,h		; BC := (tbase+DE)
	mov c,l
	pop h		;get back tbase+BC
	mov m,c		; tbase+BC := tbase+DE
	inx h
	mov m,b
	pop b		;and restore original BC
	ret		;oh well, so it isn't documented all that greatly!

setwsp:	lxi h,tab1	;initialize wsp with pointers to entries in tab1
	lxi b,0		;symbol count
	lxi d,wsp	;destination of pointers
setw2:	mov a,m		;end of tab1?
	ora a	
	jnz setw3
	mov h,b		;yes. set nsmbs to # of symbols found
	mov l,c
	shld nsmbs
	ret		;and return.

setw3:	push h		;not done. enter pointer into wsp...
	cpi 9dh		;"main" is a special code; fudge the pointer
	jnz setw4
	lxi h,stgmn	;"MAIN'"

setw4:	mov a,l
	stax d
	inx d
	mov a,h
	stax d
	inx d
	inx b		;bump symbol count
	pop h		;restore pointer into tab1

setw5:	mov a,m		;pass over symbol text
	inx h	
	ora a
	jp setw5

	mov a,m		;and references (if any)
	ani 7fh	
	push d
	mov d,a
	inx h
	mov e,m
	inx h
	dad d
	dad d
	pop d
	jmp setw2	;and go to next symbol

cmptx:	push b		;compare two symbols
	push d		;return C set if wsp(BC) > wsp(DE)
	lxi h,wsp
	dad d
	dad d
	mov e,m
	inx h
	mov d,m		;DE points to second symbol
	lxi h,wsp
	dad b
	dad b
	mov c,m
	inx h
	mov b,m		;BC points to first symbol
	call cmpt2	;compare symbols at BC and DE
	pop d		;restore registers
	pop b
	ret

cmpt2:	ldax b		;get char
	ani 7fh		;strip end-of-symbol bit
	mov h,a		;save
	ldax d		;do same with other symbol
	ani 7fh
	cmp h		;compare with first one
	rnz		;if not same, all done
	ldax d		;else...is 2nd symbol ended?
	ora a
	jp cmpt3
	ldax b		;yes..result depends on whether
	ora a		;1st symbol is ended...
	stc
	rp
	cmc
	ret

cmpt3:	ldax b		;is 1st symbol ended?
	ora a
	rm		;if so, it must be smaller than second.
	inx b		;else check next character...
	inx d
	jmp cmpt2

;
; Print out the function name pointed to by HL for the SYM file and
; stat report:
;

pfnm:	push b
	mvi b,0		;char count
pfnm1:	inr b
	mov a,m
	push psw
	inx h
	ani 7fh
	call outch
	pop psw
	ora a
	jp pfnm1
	mov a,b
	pop b
	cpi 3		;if >= 3 characters, ignore
	rnc
	mvi a,9		;else follow with a tab
	jmp outch

;
; Print out the value in HL in hex and follow by a space:
;

prhls:	call prhl
	mvi a,' '
	jmp outch

;
; Print out the value in HL in hex and follow by a comma:
;

prhlc:	call prhl
	mvi a,','
	jmp outch

;
; Print out the value in HL in hex:
;

prhl:	mov a,h
	call pra
	mov a,l
	jmp pra

;
; Print out the value in A in hex:
;

pra:	push psw
	rrc
	rrc
	rrc
	rrc
	call prhd
	pop psw

;
; Print out the hex digit in A:
;

prhd:	ani 15
	adi 30h
	cpi 3ah
	jc outch
	adi 7
	jmp outch

writf:
	IF CPM		;don't bother with debugging kludge under MARC yet
	lda debugf	;debugging before output?
	ora a
	jz writf0	;if not, go write out CRL file

	lda nflag	;don't try it if -n given, though...
	ora a
	jnz writf0

	lxi d,stgdeb	;yes. tell about debugging
	call pstg

	mvi b,0		;first assume no text string

	lda debugf	;now, was a text string given?
	dcr a
	jz copybt	;if not, just go ahead and do the bootstrap

	lhld argptr	;else copy the text line down into tbuff
	xchg		;DE points to the text
	lxi h,tbuff+1	;HL points into tbuff
        mvi m,' '	;stick in a leading space for good measure
	inx h
	inr b
cpytxt:	ldax d		;get next text character
	call mapuc	;map to upper case just like CP/M does
	cpi '"'		;end of text?
	jz copybt	;if so, go set line length and copy bootc
	mov m,a		;else store the character
	inx h		;bump destination ptr
	inx d		;bump source ptr
	inr b		;bump char count
	jmp cpytxt	;and loop till done.

copybt:	mov a,b		;get text line count
	sta tbuff	;set it for the argc&argv processor

	lxi h,boots	;the bootstrap
	lxi d,bootsa	;where it's going
	mvi b,bbytes	;length of it
bootlp:	mov a,m
	stax d
	inx h
	inx d
	dcr b
	jnz bootlp

	jmp bootsa	;and go copy the program and run it

;
; This is the bootstrap code, to copy the linked COM file down
; into the tpa and run it.
;

bootsa:	equ tbuff+90	;where this boot will reside

boots:	lhld cda	;source addr.
	xchg		;  into DE
	lhld cdp	;last addr. of code + 1
	mov b,h
	mov c,l		;put last addr. in BC
	lxi h,tpa	;destination (start of TPA)
boots1:	ldax d		;copy a byte
	mov m,a
	inx h
	inx d
	mov a,d		;done yet?
	cmp b
	jnz bootsa+12	;jnz boots1
	mov a,e
	cmp c
	jnz bootsa+12
	jmp tpa		;yes. Go execute code	

bbytes:	equ $-boots
	ENDIF		;end of CP/M-only debugging hack, 4 the time being

writf0:
	IF MARC		;under MARC, put an ".out" extension by default
	lxi h,fcbs
	push h		;save for create...
	push h		;save for movfn...
	lda oflag	;was -o option given?
	ora a
	jnz writf1	;if so, don't append '.out' to filename
	call putext
	   db '.out',0
writf1:
	pop h
	lxi d,fcbt	;copy into fcbt for error reporting
	call movfn

	pop h		;create new version
	lxi d,755q	;protection mode allows execution
	call create
	ENDIF

	IF CPM
	call crate	;create an output file under CP/M
	ENDIF

	lhld cda
	
	IF CPM		;under CP/M, copy and write one sector at a time
writ2:	call copys
	push psw
	push h
	lxi h,tbuff
	call writs
	pop h
	pop psw
	jnc writ2
	ENDIF	

	IF NOT CPM	;under MARC
	push h		;save starting address
	call cmh
	xchg
	lhld cdp	;get ending address
	dad d		;subtract starting address
	inx h		;add one to get length of file to write
	xchg		;put length in DE
	pop h		;get back starting address
			;now HL = start, DE = length
	lda iflag	;doing image mode?
	ora a
	jz writld	;if not, go write MARC load format file

	call writs	;write it out	
	jmp close

writld:	push h		;save object code starting address
	lhld runsat	;get load address
	shld runsav	;save for load address record at end of write
	pop h		;restore code starting addr

wrtld1:	call doblck	;set up and write out a block of object file data
	jnz wrtld1	;keep going till all data has been written
	mvi a,1		;now write out load address record
	sta doblck	;use where "doblck" code was for a buffer
	lhld runsav	;get load address
	shld doblck+1

	lxi h,0400h	;this gets stored as "00 04"
	shld doblck+3

	lxi h,doblck	;  as load address.
	lxi d,5		;four bytes for load address record, plus EOF byte
	call writs	;and write out this final record
	ENDIF

	jmp close

	IF MARC
doblck:	shld datap	;save object code pointer for later use
	dcx h		;HL--> where length byte goes
	mov a,d		;more than 255 bytes left to write?
	ora a
	sta endtst	;(save for EOF Test later)
	mov c,e		;in case this is the last, put count in c
	jz sets2	;and go away if this is the last

	push h		;else subtract 255 from DE
	lxi h,-255
	dad d
	xchg
	pop h

	mvi c,255	;and set count = 255
sets2:	mov m,c		;set length count byte for this block
	dcx h

	push d		;C contains byte count; save countDOWN register on stk
	xchg		;save memory pointer in DE
	lhld runsat	;get load address for this block
	xchg		;put into DE
	mov m,d		;transfer to memory
	dcx h
	mov m,e
	dcx h
	mvi m,1		;abs record header byte

	push h		;save start of block for writs

	mov l,c		;update load address
	mvi h,0
	dad d		;by adding byte count to old load address
	shld runsat	;and get it ready for the next iteration

	push b		;save C for count total later
	lhld datap	;compute checksum. get pointer to start of data
	xra a		;clear checksum accumulation
sets3:	add m		;add next byte
	inx h		;bump memory pointer
	dcr c		;de-bump countdown
	jnz sets3	;keep going till done

	cma		;negate A to acheive actual checksum byte
	inr a
	mov b,a		;save checksum in B
	mov a,m		;get byte of data AFTER end of block
	sta btsav	;save somewhere for later restoration
	mov m,b		;replace with checksum (kludge, kludge)

	pop b		;get back byte count in C
	mvi b,0		;use to compute total size of block to be written
	lxi h,5		;fudge factor because of ld format overhead
	dad b		;add to byte count to get total # byte to write
	xchg		;put into DE for writs routine
	pop h		;get pointer to start of block
	push d		;save this stuff
	push h
	call writs	;write the block
	pop h		;restore this stuff
	pop d
	dad d		;get pointer to start of data for NEXT block
	dcx h		;point back to checksum byte, which overwrote data
	lda btsav	;get back the byte butchered by the checksum byte
	mov m,a		;restore it to its proper place
	pop d		;get back countdown register
	lda endtst	;was this the last block? if so, endtst will be zero
	ora a		;set the Z flag if so, so we don't come here again...
	ret

	ENDIF



	IF CPM		;only need this sector copy kludge under CP/M
copys:	lxi d,tbuff
	mvi b,80h
copy1:	mov a,m
	stax d
	push d
	xchg
	lhld cdp
	mov a,h
	cmp d
	jnz copy2
	mov a,l
	cmp e
	jz copy3
copy2:	xchg
	pop d
	inx h
	inx d
	dcr b
	jnz copy1
	xra a
	ret

copy3:	pop d
copy4:	dcr b
	jz copy5
	mvi a,1ah
	stax d
	inx d
	jmp copy4
copy5:	stc
	ret
	ENDIF		;end of sector copy kludge

;
; Open a file. Under CP/M, the default fcb is assumed to have been
; set up for a file. Under MARC, a name pointer is passed in HL
; and location "marcfd" is set here to the file descriptor returned
; by the MARC system call; register A is 0 for opening for READ, or
; 1 for WRITE.
;

open:	push b		;save registers
	push d
	push h

	IF TESTING
	push psw
	call printf
	  db 'trying to open: ',0
	push h
	call pfnamu
	pop h
	pop psw
	ENDIF

	IF CPM
	lxi d,fcb
	mvi c,openfil
	call bdos
	ENDIF

	IF NOT CPM
	mvi c,m$open
	call msys
	ENDIF

	IF CPM
	cpi 255		;return value of 255 from CP/M's 'open' means error
	jnz op2
	ENDIF

	IF NOT CPM
	jz op2		;Z flag under MARC indicates success
	ENDIF

	lxi d,stg1	;spew an error.
op1:	lda quietf	;be quiet about it?
	ora a
	cz pstg
	mvi a,0		;clear quietf.
	sta quietf	

	IF MARC
	pop h
	push h		;get filename string for MARC pfnam routine
	ENDIF

	cz pfnamu	;tell name of file that can't be opened
	stc		;set carry to indicate error to calling routine
	jmp op3

op2:
	IF CPM
	xra a
	sta nr
	ENDIF

	IF NOT CPM
	sta marcfd	;store fd for file only if it opened correctly
	ENDIF

	IF TESTING
	call printf
	  db '....opened OK',0
	ENDIF

op3:	pop h
	pop d
	pop b
	ret


;
; Close a file. Under CP/M, also zero out the extent field so the
; next routine to use the default fcb doesn't go apeshit opening
; the wrong extent.
;


close:
	IF TESTING
	call printf
	   db 'closing...',0
	ENDIF

	IF CPM
	push b
	push d
	push h
	lxi d,fcb
	mvi c,closefil
	call bdos
	lxi h,fcb+12
	mvi m,0
	pop h
	pop d
	pop b
	cpi 255
	rnz
	lxi d,stg4
	jmp c2
	ENDIF

	IF NOT CPM
	lda marcfd
	mvi c,m$close
	call msys
	jnz ferror
	mvi a,0
	sta marcfd	;clear fd byte for error recovery
	ret
	ENDIF


;
; Delete a file. Name is in default fcb for CP/M, or passed in HL
; for MARC:
;

delfil:
	IF CPM
	lxi d,fcb
	lxi h,fcb+12
	mvi m,0
	mvi c,delete
	jmp bdos
	ENDIF

	IF NOT CPM
	mvi c,m$unlink
	call msys
	jnz ferror
	ret
	ENDIF




;
; Create a file and open it, first deleting any old version.
; Filename is set up in default fcb under CP/M, or pointed to by
; HL under MARC:
;

crate:
	IF CPM
	lxi h,fcbs
	lxi d,fcb
	call movfn
crate2:	call delfil
	call create
;	call open	;don't need to call open, since "create" does it for us
	ret
	ENDIF

	IF NOT CPM
crate2:	lxi d,644q	;protection mode
	jmp create
	ENDIF


;
; Create a new file. Default fcb is set up under CP/M; name pointer
; is passed under MARC along with a protection mode in DE; marcfd
; is set to the fd of the file (since the creat call opens it for writing):
;


create:
	IF CPM
	lxi d,fcb
	lxi h,fcb+12
	mvi m,0
	lxi h,fcb+32
	mvi m,0
	mvi c,makfil
	call bdos
	cpi 255
	rnz
	lxi d,stg5
	jmp c2
	ENDIF

	IF NOT CPM
	mvi c,m$creat
	call msys
	jnz ferror
	sta marcfd	;save the fd if it got created OK
	ret
	ENDIF	


;
; Under CP/M, reads in a sector of data from the default fcb,
; setting the Carry flag on end of file,
; and prints something appropriately nasty on error. Under MARC,
; reads in DE bytes to memory at HL from the currently open file:
;

reads:	
	IF CPM
	push h		;under CP/M
	push d
	lxi d,fcb
	mvi c,rsequen
	call bdos	;read a sector
	pop d
	pop h
	ora a
	rz		;error?
	dcr a		;maybe.
	stc
	rz		;return carry if EOF
	ENDIF		;else fall through to error reporting routine


	IF MARC		;under MARC:
	lda marcfd
	mvi c,m$read
	push d		;save byte count
	call msys	;read data
	pop b		;get back byte count in BC
	jnz ferror
	mov a,d
	cmp b
	jnz reads1
	mov a,e
	cmp c
	rz

;	mov a,d
;	ora e		;is DE zero? if so, EOF: an error here
;	rnz
	ENDIF

reads1:	lxi d,stg2	;read error: barfsville
	jmp c2


;
; Write a sector of data to the file in the default fcb under CP/M;
; write DE bytes from memory at HL to the "marcfd" file under MARC:
;

writs:
	IF CPM
	push d
	push h
	mvi c,wsequen
	lxi d,fcb
	call bdos
	pop h
	pop d
	ora a
	rz
	ENDIF

	IF NOT CPM
	mvi c,m$write
	lda marcfd
	call msys
	rz
	jmp ferror
	ENDIF	

	lxi d,stg3	;write error: complain
	jmp c2

;
; Read a character from the standard input (console only under CP/M):
;

inch:
	IF CPM
	push b
	push h
	mvi c,coninp
	call bdos
	pop h
	pop b
	ENDIF

	IF NOT CPM
	xra a		;standard input under MARC
	mvi c,m$getcf
	call msys
	jnz ferror
	ENDIF

	IF CPM
	call mapuc
	ENDIF

	cpi 3
	jz abort
	ret

;
; Print a CR-LF onto standard output (console only under CP/M):
;

crlf:	IF CPM
	mvi a,cr
	call outch
	ENDIF

	mvi a,lf		;and fall through to outch

;
; Write a character to standard output, and to the symbols file
; if wrsmf flag is active:
;

outch:
	IF MARC
	cpi cr		;ignore CR's under MARC
	rz
	ENDIF

	push h
	push b
	push d
	push psw
	mov b,a
	lda wrsmf	;if wrsmf true,
	ora a
	jz outc1
	mov a,b		;do it all in wrb
	call wrb
	jmp outc1a

outc1:	mov a,b		;otherwise just put out to the console
	call outch2

outc1a: pop psw
	pop d
	pop b
	pop h
	ret


;
; Write the character in A to the standard output (console only under CP/M):
;

outch2:
	IF CPM
	push b
	mvi c,conout
	mov e,a
	call bdos
	pop b
	ret
	ENDIF
	
	IF NOT CPM	; for MARC:
	mov b,a		;put character in B
	lda consfd	;stdout or stderr under MARC	
	mvi c,m$putcf
	call msys
	jnz ferror
	ret
	ENDIF


wrb:	mov b,a		;write out a byte of symbol table text
	lda statf	;displaying symbol values on console?
	ora a
	jz wrb2
	mov a,b		;yes. do it.
	call outch2
wrb2:	lda wflg	;writing symbols to disk?
	ora a
	rz
wrb3:	push h
	lhld bufp	
	mov m,b
	inx h
	mov a,l
	ani 7fh
	jnz wrb4

	IF MARC
	lxi d,128
	ENDIF

	lxi h,tbuff
	call writs	;if buffer full, dump to disk
wrb4:	shld bufp
	pop h
	ret

	IF MARC
pfnam:	xchg		;for MARC, put name pointer in DE
	call pstg
	call crlf
	ret
	ENDIF

pstg:	push psw
pstg1:	ldax d
	ora a
	jnz pstg2
	pop psw
	ret
pstg2:	call outch
	inx d
	jmp pstg1

gnfl:
	IF CPM
	call scrl	;set CRL extension
	lda quietf
	mov b,a
	mvi a,1
	sta quietf	;don't complain yet under CP/M
	ENDIF

	xra a
	call open	;try to open for reading

	IF CPM
	mov a,b
	sta quietf
	ENDIF	

	IF MARC
	rc		;don't read in directory if not there
	ENDIF

;	IF CPM
	jnc gnflok	;found in first path? if so, go process

	lda search	;no. should we search default area also?
	ora a
	jz cmpln	;if not, go complain

	lda defusr	;now try default disk and user area
	mov e,a
	inr a		;default user area is current user area?
	jz gnfl2	;if so, don't change
	mvi c,sguser

	lda nouser
	ora a
	IF NOT ALPHA
	cz bdos
	ENDIF

gnfl2:	lda defdsk	;default disk current disk?
	mov e,a
	cpi 0ffh	;if so, don't switch
	jz gnfl3

	push d
	mvi c,gdisk	;first get and save currently logged drive
	call bdos
	inr a		;add 1 so A == 1, and 0 can mean "unused"
	sta savdrv
	pop d		;get back drive to switch to in E
	mvi c,select
	call bdos

gnfl3:	xra a		;now try to open in new directory
	call open
	jnc gnflok	;and go on processing if we finally found it
	ret		;else return, since this time "open" printed an error

cmpln:	lda quietf	;do we bitch?
	ora a
	stc
	rnz		;if quietf set, don't bitch, just set Cy and return
	lxi d,stg1	;can't find:
	call pstg
	call pfnamu	;print filename
	stc		;and return Cy set to indicate failure
	ret

gnflok:
;	ENDIF

	lxi h,direc

	IF CPM		;read in directory under CP/M one sector at a time
	call reads
	call cpys
	call reads
	call cpys
	call reads
	call cpys
	call reads
	call cpys
	ENDIF
	
	IF NOT CPM	;under MARC  just read in 512 bytes
	lxi d,512
	call reads
	ENDIF

	xra a		;clear carry
	ret

scrl:
	IF CPM
	lxi h,fcb+9
	mvi m,'C'
	inx h
	mvi m,'R'
	inx h
	mvi m,'L'
	ret
	ENDIF

	IF NOT CPM
	call putext
	   db '.crl',0
	ret
	ENDIF

	IF CPM
cpys:	lxi d,tbuff
	mvi b,80h
cps2:	ldax d
	mov m,a
	inx h
	inx d
	dcr b
	jnz cps2
	ret
	ENDIF		;end of CP/M-only stuff




;
; Get any functions out of the currently open CRL file
; as may be needed, until the supply is exhausted:
;

gtfns:	lda fflag	;force loading of all function in this crl file?
	ora a
	jz gtfn0	;if not, go scan normally for needed functions

;
; Load in EVERY function in the currently open CRL file. Once this works,
; it should also refrain from loading any functions which have already been
; loaded...
;

	lxi h,direc	;and try to get every function we can...
gtfn00:	mov a,m
	cpi 80h		;end of directory?
	jz gtfn03	;if so, done with this crl file
	push h
	push h
	shld savnam	;save a pointer to the name for entt1 to bitch with
	call pb7hi	;pass name (we don't care about it yet)
	call ft23a	;else set function parameters for rdfun
	pop h
	mvi a,1		;say that we got it
	sta gotf
	sta rdngsm	;set this so symbol routine does duplicate checking
	call entt1	;enter into tab1 as gotten
	lda gotf	;was it a duplicate?
	cpi 81h
	cnz pre		;read it in and process if not a duplicate
gtfn02:	pop h		;get back pointer to directory
	call pb7hi	;pass over name of the function we just read in
	inx h		;and its address
	inx h
	jmp gtfn00	;and go for the next one.

gtfn03:
	IF NOT FORCE
	xra a
	sta fflag	;turn off forcing after this file.
	ENDIF
	sta rdngsm	;and reset this also
	jmp close	;and go close the current one

;
; Scan the current CRL file for NEEDED functions only (restarting scan
; every time one is loaded, so any local backward-references are
; resolved):
;

gtfn0:	lxi h,tab1	;init needed-function table pointer
	shld fngtt
gtfn1:	call fung2	;any more ungotten functions in the n-f table?
	jc close	;if not, all done with this crl file
	push h
	call ft2	;else see if the next needed function is in the
	pop h		;  current CRL file
	jc gtfn1	;is it?
	mvi a,1		;yes.
	sta gotf	;say that we got it
	call entt1	;enter the fact in tab1
	call pre	;and actually read it in
	jmp gtfn1	;and go for more

;
; This routine scans through the entire needed-function table for
; any non-loaded needed function entries. As soon as one is found,
; HL is returned with a pointer to the loaded byte for that entry, and
; Z is set. Z is returned NOT set if there aren't any more unloaded functions:
;

fungt:	lxi h,tab1	;start at the beginning
	shld fngtt

;
; This routine scans the needed-function table from the current position
; of the table pointer (fngtt) to the end, looking for unloaded needed
; functions. See above for return values.
;

fung2:	lhld fngtt	;get pointer into tab1
fng21:	push h
	call past1e
	shld fngtt
	pop h
	mov a,m
	ora a
	stc 
	rz
	push h
fng22:	call pb7hi	;pass function name
	mov a,m		;next byte a zero?
	ora a
	pop h
	jm fung2
	ret		;no...so 


past1e:	call pb7hi
	push d
	mov a,m
	ani 7fh
	mov d,a
	inx h
	mov e,m
	inx h
	xchg
	dad h
	dad d
	pop d
	ret


pb7hi:	mov a,m
	inx h
	ora a
	jp pb7hi
	ret


mapuc:	cpi 61h
	rc
	cpi 7bh
	rnc
	sui 32
	ret

;
; This routine scans the current CRL file directory for an occurence of
; the function whose name is pointed to by HL. If found, Cy is returned not
; set. Cy is returned set if not found, of course:
;

ft2:	push h		;save the name pointer
	xchg		;and also put in DE
	lxi h,direc	;start at the beginning of directory
ft21:	mov a,m		;end of directory?
	cpi 80h
	jnz ft22
	pop h		;yes. no match found, so set carry and return
	stc
	ret

ft22:	call stcmp	;not end of directory. current entry match?
	jnz ft24

ft23:	call ft23a
	pop h		;all done. Note carry isn't set because of pb7hi
	ret

ft23a:	mov a,m		;yes--next two bytes after name are file address
	inx h		;put the file address in HL
	push h
	mov h,m
	mov l,a
	shld enst	;save for rdfun to use in loading it later
	pop h		;find out what the address after the subsequent
	inx h		;entry is, to get ending address in file...
	call pb7hi
	mov a,m		;here it is. load into HL
	inx h
	mov h,m
	mov l,a
	shld enend	;and save for rdfun
	ret

ft24:	call pb7hi	;no match. go on to next entry
	inx h
	inx h
	jmp ft21

	IF LASM
	link clinkb
	ENDIF

