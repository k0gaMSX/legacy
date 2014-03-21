;*
;* UZIX - UNIX Implementation for MSX
;* (c) 1997-2001 Arcady Schekochikhin
;*		 Adriano C. R. da Cunha
;*
;* UZIX is based on UZI (UNIX Zilog Implementation)
;* UZI is a UNIX kernel clone, written for Z-80 systems, by Douglas Braun.
;*
;* This program is under GNU GPL, read COPYING for details
;*
;*/
;
; ZILO - secondary bootstrap
; load and execute UZIX from a system UZIX disk
; by A&L Software 1998, 2000
;

; WARNING: ZILO code must be shorter than 2049 bytes.

; ZILO doesn't check if machine is MSX2 since there is a MSX1 version of
; UZIX. The memory check is enough (MSX1 with mapper can run UZIX).

	org	100h

UZIXSCT 	equ	6	; initial UZIX image sector
UZIXSIZ 	equ	56	; UZIX image size in sectors
SCTSTEP 	equ	7	; load step in sectors (maximum: 16)
				; obs.: UZIXSIZ/step must be integer

CR		equ	13
LF		equ	10
FF		equ	12
_EI		equ	0FBh
_DI		equ	0F3h
_RET		equ	0C9h

im2base 	equ	0FEh		; IM2 interrupt table: FE00h..FF01h
im2addr 	equ	0FDh		; IM2 ISR address: 0FDFDh (KILL command hook)
exptbl		equ	0FCC1h		; MSX expanded slot table
firstdr		equ	0FB22h		; first disk interface slot

; must be conform with UZI.AS
romcaluzx	equ	0801Ch		; ROM/BDOS caller routine address

; must be conform with UNIX.H/MACHDEP.MSX
romcaladd	equ	0BF00h		; temporary addr for ZILO ROM caller
bootdrvaddr	equ	0F6F2H		; UZIX boot drive
configbyte	equ	0F6F3H
			; F6F3h: xxxHTBRS
			;	    ^^^^^   
			;	    ||||+-- 1=stop drive	  1=don't stop
			;	    |||+--- 1=megaram		  0=mapper
			;	    ||+---- 1=reboot diskrom	  0=no reboot
			;	    |+----- 1=TR internal diskrom 0=no TR diskrom
			;	    +------ 1=no stopdrive count  0=stopdrive count
tickaddr	equ	0F6F4H		; UZIX clock config byte
ramaddr 	equ	0F6F5h		; UZIX RAM size (in pages) byte
ramslot 	equ	0F6F6h		; UZIX RAM slot byte
RSTK		equ	0F6F0h		; romcall temporary stack
ZSTK		equ	0F7C3h		; ZILO stack / kernel temp stack

; must be conform with UZIXBOOT.AS
cfMSX		equ	0D000h		; MSX type got by boot loader
cfTICKS 	equ	0D001h		; MSX frequency got by boot loader
cfDISK		equ	0D002h		; boot disk type
cfDRIVE 	equ	0D003h		; boot drive number

calromds	equ	romcaladd
bdoshigh	equ	romcaladd+3

UZIXORG 	equ	08000h
UZIXload	equ	01000h
TMPBUF		equ	0C000h
TMPAREA 	equ	08000h
PAGE1		equ	04000h

PSLOT		equ	0A8h		; primary slot selection port
SSLOT		equ	0FFFFh		; secondary slot selection address
MAPPER0		equ	0FCh
MAPPER1 	equ	0FDh
MEGARAM 	equ	08Eh

; ZILO signature
start:
	jr	env
	defb	'B','Z'

config: defb	00000000B
; 	  xxxHTBxS
;	     ^^^ ^   
;	     ||| +- 1=stop drive	  0=don't stop
;	     ||+--- 1=reboot diskrom	  0=no reboot
;	     |+---- 1=TR internal diskrom 0=no TR diskrom
;	     +----- 1=no stopdrive count  0=stopdrive count

; Start preparing environment
env:	ld	a,(config)	; copy configuration bits to right address
	and	000011101B
	ld	(configbyte),a
	bit	4,a		; no stop drive count?
	jr	nz,env1		; so, skip stop spinning drives
	call	savecnf
	ld	b,255
env0:	push	bc
	call	0fd9fh
	pop	bc
	djnz	env0		; make all drives stop spinning
	call	restcnf
env1:	ld	sp,ZSTK
	ld	a,(cfTICKS)	; MSX interrupt frequency
	add	a,a		; shift left - test bit 7
	ld	a,60
	jr	nc,env2 	; 60Hz
	ld	hl,freqtyp
	dec	(hl)
	ld	a,50		; 50Hz
env2:	ld	(tickaddr),a
	ld	a,(cfDRIVE)	
	ld	(bootdrvaddr),a	; boot drive

; Set parameters in ROM caller
		
setromc:ld	a,(cfDRIVE)
	call	chkdrv
	ld	a,b		; boot drive
	ld	(bootdrv),a
	ld	a,c		; boot diskROM
	ld	(0f348h),a	; main diskROM now is boot diskROM
	ld	bc,romcaladd	; install ROM caller and romcaladd
	call	moveromc

; Clear MSXDOS from memory
nodos:
	di
	ld	hl,0FD9Fh		; save HTIMI hook for stopdrive
	ld	de,hookbkp-1
	call	savehook
	
	; preserve RS232 hooks - pass 1
	
	ld	hl,0FD9Ah
	ld	de,hookbkp+5
	call	savehook
	ld	hl,0FFCAh
	ld	de,hookbkp+10
	call	savehook
	
	;
	
	ld	hl,0FD9Ah
	ld	de,0FD9Ah+1
	ld	bc,0FFD6h-0FD9Ah
	ld	(hl),RET
	ldir
	ld	hl,0F1D0h		; clear MSXDOS2 hooks
	ld	de,0F1D0h+1		; (they jumps to Exxxh)
	ld	bc,0F22Fh-0F1D0h
	ld	(hl),RET
	ldir

	; preserve RS232 hooks - pass 2
	
	ld	de,0FD9Ah
	ld	hl,hookbkp+5
	call	savehook
	ld	de,0FFCAh
	ld	hl,hookbkp+10
	call	savehook
	ld	a,RET
	ld	(0FF3Eh),a

	ld	a,255		; flag to indicate RS232 not initialized yet
	ld	(0fcbch),a
	
	;

	ld	hl,0D004h
	ld	de,0D004h+1
	ld	bc,0F000h-0D004h
	ld	(hl),0
	ldir

; Install new interruption handler
no38h:
	ld	hl,im2addr*256+im2addr	; ISR addr == EI, RET
	ld	a,_EI
	ld	(hl),a
	inc	hl
	ld	a,_RET
	ld	(hl),a
	ld	hl,im2base*256		; fill FE00h-FF01h with ISR addr
	ld	de,im2base*256+1	; this is hook area, but mnemonic FDh/FDh
	ld	bc,0101h		; has no meaning to Z80 and FF02h is C9h
	ld	(hl),im2addr		; some MSX seems to have spurious
	ldir				; interrupts in IM2 mode, and gets
	ld	a,im2base		; ISR addr at XX38h and others...
	ld	i,a			; set IM2 vectors base
	im	2

; Presents ZILO
present:
	ld	b,80		; assume 80 columns
	ld	a,(cfMSX)
	or	a
	jr	nz,present1
	ld	b,40		; MSX1? 40 columns
present1:
	ld	a,b
	ld	(0F3AEh),a	; line len in screen 0
	ld	hl,010Fh
	ld	(0F3E9h),hl	; foreground/background color
	ld	a,1
	ld	(0FCA9h),a	; cursor display on
	ld	ix,06Ch
	call	calromds	; INITXT (SCREEN 0 40 or 80 columns, 24 lines)
	ld	ix,0CCh
	call	calromds	; ERAFNK
	ld	de,messg
	call	print		; environment ok (no RST38, routines installed)

; Print MSX type
machine:
	ld	de,machmsg
	call	print
	ld	a,(cfMSX)
	inc	a
	ld	e,a
	add	a,a
	add	a,e		; msx*3
	ld	e,a
	ld	d,0
	ld	hl,msxtype-3
	add	hl,de
	ex	de,hl
	call	print
	ld	de,freqmsg
	call	println
	ld	a,(cfMSX)
	cp	3
	call	z,r800m

; Set STOPDRIVE call if Turbo-R
stpdrv:
	ld	a,(configbyte)	; if config byte set stopdrive,
	bit	0,a
	jr	nz,stpdrv1	; warn user
	ld	a,(cfMSX)
	cp	3		; if MSX is Turbo-R
	jr	z,stpdrv1	; or
	ld	ix,09Ch
	call	calromds	; (check if user pressed a key)
	jr	z,stpdrv2
	ld	ix,09Fh		; if user pressed a key, get the key
	call	calromds
	cp	32		; is SPACE?
	jr	nz,stpdrv2	; so,
	
stpdrv1:
	ld	hl,configbyte
	set	0,(hl)		; set stopdrive flag (see DEVFLOP.C)
	ld	de,stpmsg	; warn user
	call	println

stpdrv2:
	ld	ix,0156h
	call	calromds	; clear keyboard buffer

; Check for Memory Mapper
mapper:
	xor	a
	call	findram 	; search for Mapper
	cp	255
        jp      z,megaram       ; if found:
	ld	(mapslt),a	; save mapper slot
	ld	de,mpmessg
	call	prtslot 	; print mapper slot
	ld	a,(mapslt)
	call	changeslt	; select mapper slot
	ld	a,(mapslt)
	ld	b,a
	xor	a
	call	sizetst
	ld	(mpsize),a
	ld	b,a
	ld	a,3		; re-select mapper page 3 in RAM page 1
	out	(MAPPER1),a	; (sizetst selects mapper page 2 in RAM page 1)
	xor	a
	call	prtsize
	ld	a,(mpsize)
	cp	7		; more than 7 mapper pages found?
        jp      c,megaram       ; if not, insufficient memory
	ld	(ramaddr),a
        ld	hl,configbyte
        res	1,(hl)		; indicate mapper found
        jr      dskrom

; Check for MegaRAM
megaram:
	ld	a,1
	call	findram 	; search for MegaRAM
	cp	255
        jp      z,nohard        ; if found:
	ld	(mrslt),a	;  save MegaRAM slot
	ld	de,mrmessg
	call	prtslot 	;  print MegaRAM slot
	ld	a,(mrslt)
	ld	b,a
	ld	a,1
	call	sizetst 	;  calculate size
	ld	(mrsize),a
	ld	(mpsize),a
	ld	b,a
	ld	a,1
	call	prtsize 	;  print size
        cp      15              ; more than  mapper pages found?
        jp      c,nohard        ; if not, insufficient memory
        srl	a		; A=A/2 (number of 16k pages)
	ld	(ramaddr),a
        ld      a,(mrslt)
        call	changeslt	; select megaram slot
        ld	hl,configbyte
	set	1,(hl)		; indicate megaram found
	ld	bc,romcaladd
	call	moveromc	; reinstall ROM caller (now swaps back to MegaRAM)

; Show DiskROM slot
dskrom: 
	ld	de,drmsg	; "DiskROM"
	ld	a,(0f348h)
	call	prtslot
	call	ptlf

; Show boot disk

bootd:	ld	de,drvbmsg
	call	print
	ld	a,(cfDRIVE)
	add	a,65
	call	putc
	call	ptlf
	
; Load UZIX image at address 'UZIXload'
loadz:
	ld	a,(bootdrv)
	cp	255
	jp	z,error
	ld	a,'L'
	call	putc
	ld	de,loadmsg
	call	print
	call	savecnf

	ld	ix,4029h
	ld	hl,configbyte
	bit	0,(hl)		; if stopdrive flag set,
	call	nz,bdoshigh	; stop drive first

	call	prtpnt				
	ld	hl,UZIXload	; loading address
	ld	c,UZIXSCT	; starting sector
	ld	b,UZIXSIZ	; # of sectors in UZIX image
loadz1: push	bc
	ld	b,SCTSTEP	; # of sectors
	ld	e,c
	ld	d,0		; sector #
	ld	a,(cfDISK)
	ld	c,a		; disk id
	or	a		; CLC
	ld	a,(bootdrv)
	push	hl
	ld	hl,TMPBUF
	ld	ix,4010h	; DISKIO
	call	bdoshigh
	jp	c,error
	call	prtpnt
	call	restcnf
	pop	de		; loading address
	ld	hl,TMPBUF
	ld	bc,SCTSTEP*512
	ldir			; move data to right location, HL+=SCTSTEP*512
	ex	de,hl		; HL = next loading address
	pop	bc		; C = sector#, B = # of sectors
	ld	a,c
	add	a,SCTSTEP	; sector += step
	ld	c,a
	ld	a,b
	sub	SCTSTEP 	; size -= step
	ld	b,a
	or	a
	jr	nz,loadz1

; Verify UZIX signature in kernel image
	ld	hl,UZIXload+2
	ld	de,sign
	ld	b,4
	call	compare
	jp	nz,error

; Move UZIX and ROM caller to the right address and boot UZIX
putuzix:
	call	restcnf
	ld	hl,UZIXload+UZIXSIZ*512
	ld	de,UZIXORG+UZIXSIZ*512
	ld	bc,UZIXSIZ*512+1
	lddr
	ld	bc,romcaluzx
	call	moveromc

; Restore HTIMI hook (for stopping drive)

	ld	hl,hookbkp		; restore HTIMI hook stopdrive address
	ld	de,0FDA0h		
	ld	bc,4
	ldir
	ld	a,(configbyte)
	bit	4,a			; no stop drive count?
	jr	nz,fd9fhk2		; so, disable stop drive countdown routine
	ld	a,(0FDA0h)		; stop drive countdown routine 
	ld	b,a			; is in the same slot of first diskrom?
	ld	a,(firstdr)
	cp	b
	jr	z,bootuz		; if no, MSX maybe has DOS2
	ld	b,a
	ld	a,(0F2C1h)		; FC20h = old stopdrive if DOS2 present
	cp	b			; same slot?
	jr	nz,fd9fhk2		; so is DOS2, just get old address
	ld	(0FDA0h),a
	ld	hl,(0F2C2h)
	ld	(0FDA1h),hl
	jr	bootuz
fd9fhk2:ld	hl,0C9C9h		; different? so I don't know what to do
	ld	(0FD9Fh),hl		; reset stopdrive hook (check UZIX interrupt handler
	ld	(0FDA1h),hl		; for more details)
	jr	bootuz

; Boot UZIX

bootuz:	ld	a,FF		; clear screen
	ld	ix,0A2h
	call	romcaluzx
	ld	sp,ZSTK
	jp	UZIXORG 	; Boot UZIX

; Print $-delimited message in DE
print:
	ld	a,(de)
	cp	'$'
	ret	z
	call	putc
	inc	de
	jr	print

; Print $-delimited message in DE and jump to next line
println:call print
; Jump to next line
dolf:	ld	de,crlf
	jp	print
	
; Prints a '.' character
prtpnt:
	ld	a,'.'
; Print byte in register A
putc:
	ld	ix,0A2h
	jp	calromds	; CALL + RET

; Display error message (I/O error)
error:	ld	de,errmsg
	call	print
	ld	de,errmsg2
	jr	err

; Display error message (no hardware to run)
nohard: ld	de,nohardm
err:	call	print

; Hangs up MSX
exit:	jr	exit

; Enable Mapper/MegaRAM in pages 0/1 (Mapper/MegaRAM slot in A)
changeslt:
	call	savecnf		; save current slot configuration
	ld	(ramslot),a	; save swap RAM slot for UZIX (check EXTERN.H)
	ld	hl,0
	ld	de,TMPAREA
	ld	bc,1000h
	ldir			; move ZILO to 8000h
	jp	TMPAREA+change2 ; at 8000h:
change2:call	TMPAREA+enapg0	; select megaram/mapper slot on pages 0/1
	call	TMPAREA+enapg1
	ld	a,2
	out	(MAPPER0),a	; select initial swap area: mapper pages 2/3
	ld	a,3
	out	(MAPPER1),a	; (no problem if we don't have mapper)
	out	(MEGARAM),a
	ld	hl,0302h	; select initial swap area: megaram pages 0..3
	ld	(5FFFh),hl
	ld	hl,0100h
	ld	(1FFFh),hl
	in	a,(MEGARAM)
	ld	hl,0		; page 0 has RAM?
	ld	a,(hl)		; [ACVS MegaRAM and Mappers allways have]
	cpl
	ld	(hl),a
	cp	(hl)
	jr	z,change3	; no, so it's a DDX MegaRAM (no mirror effect)
	ld	a,(TMPAREA+conf); restore slot configuration
	out	(PSLOT),a
	ld	a,(TMPAREA+conf1)
	ld	(SSLOT),a
	ld	a,(mrslt)
	call	TMPAREA+enapg1	; and select only page 1 for MegaRAM
	ret
change3:ld	hl,TMPAREA
	ld	de,0
	ld	bc,1000h
	ldir			; restore ZILO to 100h
	ret

; Compare two regions of memory (HL and DE, size in B): flag Z if match
compare:
	ld	a,(de)
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	djnz	compare
	ret

; Print MegaRAM/Mapper/DiskROM slot in A, prefix message in DE
prtslot:
	push	af
	call	print
	ld	de,sltmsg
	call	print		; print message
	pop	af
	push	af
	and	00000011B
	call	prtnum		; slot
	pop	af
	bit	7,a
	ret	z
	push	af
	call	prtpnt		; .
	pop	af
	and	00001100B
	srl	a
	srl	a		; subslot
; Print the number in A (0-9) - A destroyed
prtnum:
	add	a,'0'
	jp	putc		; CALL + RET

; Enable mode R800 ROM in MSX Turbo-R
r800m:  
	ld	a,01000100B
	and	2
	xor	081h
	ld	ix,0180h
	call	calromds
	ld	de,r800msg
	jp	println
	
; Enable page 0 in slot in A (CALSLT format)
enapg0: di
	push	af
	push	bc
	push	de
	ld	d,a		; D=1000SSPP
	and	3
	ld	b,a		; B=000000PP
        rrca
        rrca                    ; A=PP000000
	or	b
	ld	b,a		; B=PP0000PP
	in	a,(0A8h)
	and	0FCh
	ld	c,a		; C=XXXXXX00
	and	3Ch		; A=00XXXX00
	or	b
	out	(0A8h),a	; A=PPXXXXPP
	ld	a,d
	and	0Ch		; A=0000SS00
	rrca
	rrca
	ld	b,a		; B=000000SS
	ld	a,(0FFFFh)
	cpl
	and	0FCh		; A=YYYYYY00
	or	b
	ld	(0FFFFh),a	; A=YYYYYYSS
	ld	a,d
	and	3		; A=000000PP
	or	c		; A=XXXXXXPP
	out	(0A8h),a
	pop	de
	pop	bc
	pop	af
	ret

; Enable page 1 in slot in A (CALSLT format)
enapg1: di
	push	af
	push	bc
	push	de
	ld	d,a		; D=1000SSPP
	and	3		; A=000000PP
	rlca
	rlca
	ld	b,a		; B=0000PP00
	rlca
	rlca
	rlca
	rlca			; A=PP000000
	or	b
	ld	b,a		; B=PP00PP00
	in	a,(0A8h)
	and	0F3h
	ld	c,a		; C=XXXX00XX
	and	33h		; A=00XX00XX
	or	b
	out	(0A8h),a	; A=PPXXPPXX
	ld	a,d
	and	0Ch
	ld	b,a		; B=0000SS00
	ld	a,(0FFFFh)
	cpl
	and	0F3h		; A=YYYY00YY
	or	b
	ld	(0FFFFh),a	; A=YYYYSSYY
	ld	a,d
	and	3
	rlca
	rlca			; A=0000PP00
	or	c		; A=XXXXPPXX
	out	(0A8h),a
	pop	de
	pop	bc
	pop	af
	ret

; Save actual slot configuration
savecnf:
	push	af
	in	a,(PSLOT)
	ld	(conf),a
	ld	a,(SSLOT)
	cpl
	ld	(conf1),a
	pop	af
	ret

; Restore slot configuration
restcnf:
	push	af
	ld	a,(conf)
	out	(PSLOT),a
	ld	a,(conf1)
	ld	(SSLOT),a
	pop	af
	ret

; Search for MegaRAM (A=1) or Mapper (A=0) and return its slot (0FFh=not found)
; It's a non-destructive test for Mapper and MegaRAM, but must be executed
; with the interrupts disabled, or system may crash.
findram:
	ld	(memtest),a
	call	savecnf 	; save slot configuration
	xor	a
	ld	hl,exptbl	; HL=expanded slot table
	ld	b,4		; B=number of primary slots
fr1:	ld	(slot1),a
	ld	(slot2),a
	bit	7,(hl)		; expanded?
	jr	nz,fr5
	call	test
	jr	c,fr3
fr2:	inc	hl
	ld	a,(slot1)
	inc	a
	djnz	fr1
	ld	a,255
	jr	fr4
fr3:	ld	a,(slot2)
fr4:	call	restcnf 	; restore slot configuration
	cp	255		; set Z flag
	ret
; search for MegaRAM/Mapper on expanded slots
fr5:	push	bc
	push	hl
	ld	e,0		; E=subslot 0
	ld	b,4		; B=number of subslots
fr6:	ld	a,e
	rla
	rla
	and	00001100B
	ld	c,a
	ld	a,(slot1)
	and	00000011B
	or	c
	set	7,a
	ld	(slot2),a	; A=subslot in CALSLT format
	call	test		; search subslot
	jr	c,fr7		; found
	inc	e
	djnz	fr6
fr7:	pop	hl
	pop	bc
	jp	nc,fr2
	jr	fr3

; Check for MegaRAM/Mapper in subslot in A
test:
	push	bc
	push	de
	push	hl
	ld	a,(slot2)
	call	enapg1
	ld	a,(40ACh)
	push	af		; save slot byte at addr 40ACh
	ld	e,0ACh		; first test
	call	testmm
	ld	e,0CAh		; second test
	call	testmm
test1:	pop	af
	ld	(40ACh),a	; restore slot byte at addr 40ACh
	scf			; flag C - sucess
	jr	test4

; test subslot for Mapper or MegaRAM (pattern in E)
testmm:
	ld	a,(memtest)
	or	a
	jr	nz,testmr

; test subslot for Mapper (pattern in E)
testmp:
	pop	hl		; HL=return address
	pop	af		; A=byte at 40ACh
	out	(MEGARAM),a	; prevent confusing MegaRAM with Mapper
	ld	a,2
	out	(MAPPER1),a
	ld	a,(40ACh)	; replace saved 40ACh byte with byte at 40ACh
	push	af		; of Mapper page 2 in stack
	push	hl
	ld	a,e		; E=pattern byte
	ld	(40ACh),a
	ld	a,1
	out	(MAPPER1),a
	ld	a,(40ACh)	; save byte at 40ACh of Mapper page 1 in stack
	push	af
	xor	a
	ld	(40ACh),a
	ld	a,2
	out	(MAPPER1),a
	ld	a,(40ACh)
	ld	b,a		; B=byte at 40ACh
				; if slot has mapper, B=E, else B=0
	ld	a,1
	out	(MAPPER1),a
	pop	af
	ld	(40ACh),a	; restore byte at mapper page 1
	ld	a,2
	out	(MAPPER1),a	; sucess/fail routine restore byte of page 2
	ld	a,b
	jr	test2

; test subslot for MegaRAM (pattern in E)
testmr:
	out	(MEGARAM),a	; MegaRAM ROM mode
	xor	a
	ld	(40ACh),a	; MegaRAM page 0
	in	a,(MEGARAM)	; MegaRAM RAM mode
	ld	a,e		; E=pattern byte
	ld	(40ACh),a
	out	(MEGARAM),a	; MegaRAM ROM mode
	xor	a
	ld	(40ACh),a	; MegaRAM page 0
	ld	a,(40ACh)

test2:	
	pop	hl		; HL=return address
	cp	e		; RAM?
	jr	nz,test3	; no: go to fail routine
	jp	(hl)		; yes: return

; Fail routine
test3:
	pop	af		; restore slot 4000h byte
	ld	(40ACh),a
	xor	a		; flag NC - no success
test4:	pop	hl
	pop	de
	pop	bc
	ret

; Return the last page in A of MegaRAM (A=1) or Mapper (A=0) in slot in B
; It's a non-destructive test for Mapper and MegaRAM, but must be executed
; with the interrupts disabled, or system may crash.
sizetst:
	call	savecnf
	ld	(memtest),a
	ld	a,b
	call	enapg1		; enable MegaRAM/Mapper at slot B
	ld	a,0
	call	sizechg
	ld	hl,40ACh
	ld	de,mmszbk1
	ld	bc,5
	ldir
	ld	hl,mmstpfl	; put flag on page 0
	ld	de,40ACh
	ld	bc,5
	ldir
	ld	a,(memtest)
	or	a
	jr	nz,st0
	ld	a,3		; start Mapper test at page 3, MegaRAM at 1
st0:	call	sizechg
st1:	ld	hl,4080h	; save test area
	ld	de,mmszbk2
	ld	bc,5
	ldir
	ld	hl,4080h	; clear test area
	ld	de,4081h
	ld	bc,4
	ld	(hl),0
	ldir
	call	sizechg
	ld	hl,mmsizfl
	ld	de,4080h
	ld	bc,5
	ldir			; copy test pattern
	push	af
	ld	hl,mmstpfl
	ld	de,40ACh
	ld	b,5
	call	compare 	; we reached again page 0?
	jr	z,st2		; if yes, terminate test
	ld	hl,mmsizfl
	ld	de,4080h
	ld	b,5
	call	compare 	; this page is RAM?
	jr	nz,st2		; if no, terminate test
	pop	af
	inc	a
	call	st4
	jr	st1		; next page
st2:	call	st4		; test end: restore test area
	ld	a,0
	call	sizechg
	ld	hl,mmszbk1	; restore test area
	ld	de,40ACh
	ld	bc,5
	ld	(hl),0
	ldir
	ld	a,(memtest)	
	or	a
	jr	nz,st3
	ld	a,3		; restore Mapper page 2/MegaRAM page 0 at 4000h
st3:	dec	a
	call	sizechg 	; restore MegaRAM/Mapper page
	call	restcnf
	pop	af
	dec	a
	ret
st4:	ld	hl,mmszbk2	; restore test area
	ld	de,4080h
	ld	bc,5
	ldir
	ret

; Select MegaRAM/Mapper page A at RAM page 1
sizechg:
	push	af
	ld	a,(memtest)
	or	a
	jr	nz,sc1
	pop	af
	out	(MAPPER1),a
	ret
sc1:	pop	af
	push	af
	out	(MEGARAM),a
	ld	(PAGE1),a
	in	a,(MEGARAM)
	pop	af
	ret

; Print the size in kbytes of MegaRAM (A=1) or Mapper (A=0)
; Last page in B
prtsize:
	ld	h,0
	ld	l,b
	inc	hl	; HL = number of pages
	or	a
	jr	nz, ps1 ; MegaRam - 8K pages
	add	hl,hl
ps1:	add	hl,hl
	add	hl,hl
	add	hl,hl	; HL = number of Kbytes
	ld	de, sizetmp
	ld	bc, 1000
	call	digit
	ld	bc, 100
	call	digit
	ld	bc, 10
	call	digit
	ld	bc, 1
	call	digit
	ld	de,sizemsg
	call	print
	jp	ptlf		; CALL + RET
	
; Print a point and a line feed
ptlf:
	call	prtpnt
	jp	dolf

; HL = number, BC = divider, DE = output string
; A <= HL/BC, HL <= HL%BC, DE <= DE+1
digit:
	ld	a,-1
dg1:	inc	a
	or	a
	sbc	hl,bc
	jr	nc,dg1
	add	hl,bc	; restore remainder
	add	a,'0'
	ld	(de),a	; write digit
	inc	de
	ret

; Set absolute addresses of ROM caller by relative address in BC
initcal:ld	hl,int-romcals
	add	hl,bc		; HL=addr+int-romcals
	ld	(calrom+1),hl
	ld	(bdos+1),hl
	ld	hl,calrom3-romcals
	add	hl,bc		; HL=addr+calrom3-romcals
	ld	(adr3+1),hl
	ld	hl,int1-romcals
	add	hl,bc		; HL=addr+int1-romcals
	ld	(adr4+1),hl
	ld	hl,int3+1-romcals
	add	hl,bc		; HL=addr+int3+1-romcals
	ld	(adr5+2),hl
	ld	hl,int2-romcals
	add	hl,bc		; HL=addr+int2-romcals
	ld	(int0+1),hl
	ret

; Get local drive in B (FFh=error) and DiskROM slot in C for a given drive in A
chkdrv:	ld	hl,0FB21h	; diskrom table
	ld	b,4
chkdrv1:sub	(hl)
	jr	c,chkdrv2
	inc	l
	inc	l
	djnz	chkdrv1
	ld	b,0FFh
	ret
chkdrv2:add	a,(hl)
	ld	b,a
	inc	l
	ld	a,(hl)
	ld	c,a
	ret

; Install ROM caller routines at address in BC
moveromc:
	in	a,(PSLOT)
	ld	(calrom1+1),a	; UZIX primary slot
	and	11000000B
	ld	(calrom0+1),a
	ld	a,(SSLOT)	; UZIX secondary slot
	cpl
	ld	(calrom2+1),a
	push	bc
	call	initcal		; install ROM caller routines at temp address ROMCALADD
	pop	de
	ld	hl,romcals
	ld	bc,romcalf-romcals
	ldir
	ret

savehook:
	ld	bc,5
	ldir
	ret

;***********************************************************************
; ROM/BDOS caller routines

romcals:jr	calrom
	nop			; space for JP xxyy
	jr	bdos
	nop			; space for JP xxyy
calrom:	call	int
	ld	de,03C00h	; 00111100b,00000000b
	ld	hl,0FC00h	; 11111100b,00000000b
	jr	calromr
bdos:	call	int
	ld	a,(0f348h)	; disk ROM slot - default: diskrom 0 (set to change)
	ld	e,a
	and	00001100B
	ld	l,a		; L=0000YY00b
	ld	a,e
	and	00000011B
	sla	a
	sla	a
	ld	e,a		; E=0000XX00b
	sla	a
	sla	a
	sla	a
	sla	a		; A=XX000000b
	or	e
	ld	e,a		; E=XX00XX00b	(also set ROMBIOS in page 0)
	ld	d,30h		; D=00110000b
	ld	h,0F3h		; H=11110011b
calromr:in 	a,(PSLOT)
	and	d		; clear page 3 and x
	or	e		; set page 3 and x
	out	(PSLOT),a
	ld	a,(SSLOT)
	cpl
	and	h		; clear page x
	or	l		; set page x
	ld	(SSLOT),a
	in	a,(PSLOT)
	and	00111111B
calrom0:or	0		; set page 3 back to original
	out	(PSLOT),a
	pop	af
	pop	de
	pop	hl
	im	1		; temporaryly to interrupt mode 1
adr3:	call	calrom3
	di
	push	af
	ld	a,im2base
	ld	i,a		; set IM2 vectors base
	im	2		; again interrupt mode 2
calrom1:ld	a,0		; get UZIX primary slot
	out	(PSLOT),a	; restore primary slot
calrom2:ld	a,0		; get UZIX secondary slot
	ld	(SSLOT),a	; restore secondary slot
	pop	af
	jr	int2		; EI/DI and restore stack
calrom3:jp	(ix)
	;----------------
int:	push	af
	ld	a,i
	di
adr4:	jp	pe,int1		; IFF'
	ld	a,_DI
int0:	ld	(int2),a
	pop	af
	ld	(RSTK-2),hl	; same as PUSH HL in RSTK
	pop	hl		; HL=return address
adr5:	ld	(int3+1),sp	; save actual stack
	ld	sp,RSTK-2	; SP=new stack (including saved HL)
	push	de		; saves DE and AF
	push	af
	jp	(hl)		; return
int1:	ld	a,_EI
	jr	int0
int2:	nop			; int2 - EI/DI
int3:	ld	sp,0		; int3+1 - saved user stack pointer
	ret
romcalf:

; ZILO messages and data
messg:	defm	'ZILO - '
sign:	defm	'UZIX loader V1.0'
	defb	CR,LF,LF
	defm	'Environment ready.'
crlf:	defb	CR,LF,'$'
stpmsg: defm	'Stopdrive workaround enabled.$'
errmsg: defb	CR,LF,LF,LF
	defm	'Error l'
loadmsg:defm	'oading UZIX.$'
errmsg2:defm	' ZILO aborted.$'
nohardm:defm    'Error: minimum 128k RAM required.$'

machmsg:defm	'Running on a MSX $'
msxtype:defm	'1 $2 $2+$Turbo-R$'
mrmessg:defm	'MegaRAM$'
mpmessg:defm	'Memory Mapper$'
sltmsg: defm	' found in slot $'
drmsg:  defm	'DiskROM$'
drvbmsg:defm	'Booting from drive $'
freqmsg:defm	', '
freqtyp:defm	'60Hz interrupt.$'
r800msg:defm	'R800 mode enabled.$'
sizemsg:defm	' - '
sizetmp:defm	'0000k size$'

; variables
mmstpfl:defb	00Fh,01Eh,02Dh,03Ch,04Bh
mmsizfl:defb	0F0h,0E1h,0D2h,0C3h,0B4h
bootdrv:defs	1
conf:	defs	1
conf1:	defs	1
slot1:	defs	1
slot2:	defs	1
mapslt: defs	1
mrslt:	defs	1
mpsize: defs	1
mrsize: defs	1
memtest:defs	1
mmszbk1:defs	5
mmszbk2:defs	5
	defs	1
hookbkp:defs	15

DEBUG	equ	0

if DEBUG = 1
; print primary and secondary slot register and 48 bytes from 8000h on screen
dumpdata:
	in	a,(0a8h)
	call	prthex
	ld	a,(0ffffh)
	cpl
	call	prthex
	ld 	hl,8000h
	ld 	b,30h
qwe:	ld	a,(hl)
	push	hl
	push	bc
	call	prthex
	pop	bc
	pop	hl
	inc	hl
	djnz	qwe
	ld	ix,09Fh
	call	romcaluzx
	ret
prthex: push	af
	and	0f0h
	srl	a
	srl	a
	srl	a
	srl	a
	cp	10
	jr	c,prthex2
	add	a,7
prthex2:add	a,30h
	out	(98h),a
	pop	af
	and	0fh
	cp	10
	jr	c,prthex3
	add	a,7
prthex3:add	a,30h
	out	(98h),a
	ld	a,32
	out	(98h),a
	ret
endif	

	end	start
