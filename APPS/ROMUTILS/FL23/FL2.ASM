; *******************************
; *          FL2                *
; *   version 2.3 14-01-2002    *
; *    (c) Ramones 2003         *
; * *****************************


; TASM (CHAOS ASSEMBLER) VERSION


; *** CONSTANTS ***

; Generic MSX


BDOSADR:	.equ	05h
RDSLT:	.equ	0Ch
CALSTL:	.equ	01Ch
ENASLT	.equ	024h
EXPTBL:	.equ	0FCC1h
CSRSW:	.equ	0FCA9h
EXTVDP:	.equ	0FFE7h

; Program

intro:	.equ	0D0Ah
endline:	.equ	36
rungameroutine:	.equ	0C000h
optionsc:	.equ	rungameroutine
systemc:	.equ	rungameroutine+1
rungameadr:	.equ	rungameroutine+2
rungame:	.equ	rungameadr+2

; dos

DOSVER:	.equ	06Fh

		.org	0100h

		jp	init

; **** MAIN PROGRAM ****

init:
			; Actual parameters saved

		ld	(savesp),sp		; Stack Pointer saved
		ld	a,(CSRSW)		; Cursor Saved
		ld	(savecursor),a
		call	cursoroff	; Turn cursor off (no matter about its state)

			; Execution Program "on the fly" placed
			; in its position, page 3

		ld	hl,rungameorg
		ld	de,rungame
		ld	bc,rungameend - rungameorg
		ldir

		call	checkrunadr		; Run routine's address checked

		ld	de,logo_txt
		call	print			; Print logo

		call	checkdos		; Dos version checked

		call	checksystem		; MSX Type checked
		call	checkflash		; Search FLASH ROM
		call	checkparams		; Check and Save parameters


		ld	a,(options)
		bit	6,a			; only erasing flash?
		jp	nz,eraseflash	; yes, jump to erase it

		bit	7,a	; option /n?
		jr	nz,init0		; yes, jump to execute it.

		call	checkfile		; Checks if file-argument exists
		call	eraseflash		; Erase flash. 
		call	loadfile 		; Load file in flash

			; autoexecute options
init0:
		ld	a,(options)
		and	1			; execute the game "on the fly"?
		jp	nz,rungame		; Yes. Execute RUNGAME Routine

		jp	exitok		; No. Exit Program


; *** CHECKING ROUTINES ***

; -------------------
; CHECKFLASH
; Searches FLASH ROM 
; ------------------

checkflash:

		ld	de,search_txt
		call	print			; Prints searching message

		ld	a,0FFh
		ld	(thisslt),a		; Inits SIGSLOT Routine

checkflash0:
		call	sigslot		; Calls the next slot (first one if first time)
		cp	0FFh			; Is it the last slot?
		jr	z,checkflashnot	; Yes. FLASH was not found

		ld	h,080h		; It is not the last slot. Placed it in page 2
		call	ENASLT
		call	checkdeviceid	; Searching flash by esecuting its ID_CHECK command
		jr	nz,checkflash0	; Not found in this slot, continue with next one


		ld	a,(thisslt) 	; FLASH WAS FOUND 
		ld	(flashslt),a	; Slot saved

		push	af 			; For printing the message of slot / subslot
		and	03h
		add	a,030h		; ASCII conversion of the Slot
		ld	(foundslt),a
		pop	af
		rrca
		rrca
		and	03h
		add	a,030h
		ld	(foundsslt),a	; ASCII conversion of the Subslot.

		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT		; Restoring page 2 (Memory again)

		ld	de,found_txt
		jp	print		; Printing message with info about slot / subslot

checkflashnot:
		; FLASH NOT FOUND
		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT	; Memory placed
		ld	de,notfound_txt
		jp	errortxt		; Error message, exiting program



; -----------------
; CHECK
; Check toggle bits
; C = 1 Error
; -----------------

check:
		push	bc

		ld	a,(04000h)
		ld	b,a
check1:
		ld	a,(04000h)
		ld	c,a
		cp	b
		jr	z,checkend

		and	000100000b
		ld	a,(04000h)
		ld	b,a
		jr	z,check1

		ld	a,(04000h)
		cp	c
		jr	z,checkend

		; error

		pop	bc
		scf
		ret
checkend:
		pop	bc
		ret


; ------------------------
; CHECKDEVICEID
; Check Flash Device ID 
; Am29F040B = A4
; Z = 1 if Flash Rom found
; -------------------------

checkdeviceid:

		ld	hl,08001h
		ld	(hl),0F0h	; Send Reset Command.

		ld	de,08555h
		ld	bc,082AAh
		ld	a,0AAh
		ld	(de),a
		ld	a,055h
		ld	(bc),a
		ld	a,090h
		ld	(de),a		; Send 4 cycles command DEVICE ID
		ld	a,0A4h
		cp	(hl)	; 0A4h byte found?
		; Z = 1 Yes
		ld	hl,08001h
		ld	(hl),0F0h		; Reset Command
		ret

; ----------------------
; CHECK DOS
; check operating system
; ----------------------

checkdos:
		ld	c,DOSVER
		call	bdos	; Send DOSVER command to dos
		ld	a,b
		ld	(dos),a	; Save dos version
		ret

; ----------------
; CHECKSYSTEM
; check MSX
; ----------------

checksystem:
		ld	a,(EXPTBL)
		ld	hl,02Bh
		call	RDSLT
		ld	(ID),a	; save country byte

		ld	a,(EXPTBL)
		ld	hl,02Dh
		call	RDSLT			; Check byte 02Dh (MSX version)
		ld	(system),a
		cp	03	; Turbo R?
		ret	c	; no ret

						; is MSX Turbo R

		ld	iy,(EXPTBL-1)
		ld	ix,0183h
		call	CALSTL
		or	080h
		ld	(savecpu),a	; save actual CPU mode

		and	3
		ret	nz	; r800 on

		ld	a,081h	; and set r800 no dram
systemsetcpu:
		ld	iy,(EXPTBL-1)
		ld	ix,0180h
		call	CALSTL
		ret

; --------------------
; CHECKPARAMS
; Check line params
; --------------------

checkparams:
		ld	hl,080h
		ld	a,(hl)
		or	a	; Parameters?
		ld	de,help_txt
		jp	z,errortxt		; no parameters. Show Help and exit

		call	checkoptions	; Check parameter options


		call	checkfilename	; Check filename 

		ld	a,(dos)
		cp	2
		jp	nc,fillname		; If DOS2 then fill only the name 

		ld	hl,filenamedos2	; DOS1. Extract FILENAME
		ld	de,filenamedos1

checkparams0:
		ld	a,(hl)
		cp	'.'
		jr	z,checkparams2
		ld	(de),a
		inc	de

checkparams1:
		inc	hl
		djnz	checkparams0
		jp	fillname
checkparams2:
		ld	de,filendos1ext
		ld	b,4
		jr	checkparams1

; -------------------
; CHECKFILENAME
; Extract the name of
; the parameters in
; DOS2 format
; ------------------


checkfilename:
		ld	a,(080h)
		cp	1
		ld	b,a
		jr	z,checkfilename00
		dec	b
checkfilename00:
		ld	hl,082h
		ld	de,filenamedos2
		ld	c,0
checkfilename0:
		ld	a,(hl)
		or	a
		jr	z,checkfilename1
		cp	'/'
		jp	z,checkfilename2
		cp	32
		jp	z,checkfilename1
		cp	0Dh
		jr	z,checkfilename1

		ld	(de),a
		inc	de
		inc	c
checkfilename1:
		dec	hl
checkfilename2:
		inc	hl
		inc	hl
		djnz	checkfilename0

		ld	b,c
		ld	a,c
		or	a
		ret	nz
		ld	b,1
		ret

; --------------------------------------
; CHECKOPTIONS
; OPTIONS :
;             0 - Run loaded Game    /r
;             1 - European Keyboard  /e
;             2 - Japanese Keyboard  /j
;             3 - R800 On.           /8
;             4 - Pal                /5
;             5 - NTSC               /6
;             6 - Delete             /d
;             7 - No load.           /n
; OPTIONS2:
;             0 - delete all sector  /s
;
; ---------------------------------------



checkoptions:
		push	bc
		xor	a
		ld	(options),a
		ld	(options2),a
		ld	a,(080h)
		ld	b,a
		ld	hl,082h

checkoptions0:
		ld	a,(hl)
		cp	'/'
		call	z,checkoptions1
checkoptions00:
		inc	hl
		djnz	checkoptions0
		pop	bc
checkoptions1:
		inc	hl
		ld	a,(hl)

		or	000100000b

		ld	de,help_txt
		cp	'?'
		jp	z,errortxt

		cp	'h'
		jp	z,errortxt

		ld	c,1
		cp	'r'
		jr	z,checkoptions2

		sla	c
		cp	'e'
		jr	z,checkoptions2

		sla	c
		cp	'j'
		jr	z,checkoptions2

		sla	c
		cp	'8'
		jr	z,checkoptions2

		sla	c
		cp	'5'
		jr	z,checkoptions2

		sla	c
		cp	'6'
		jr	z,checkoptions2

		sla	c
		cp	'd'
		jr	z,checkoptions2

		sla	c
		cp	'n'
		jr	z,checkoptions2

		ld	c,1
		cp	's'
		jr	z,checkoptions3
		ret
checkoptions2:
		ld	a,(options)
		or	c
		ld	(options),a
		ret
checkoptions3:
		ld	a,(options2)
		or	c
		ld	(options2),a
		ret

; ---------------------
; CHECK FILE
; CHECK IF FILE EXIST
; ---------------------

checkfile:
		ld	de,open_txt
		call	print		; Open text

		ld	a,(dos)
		cp	2
		jp	nc,checkfile2 	; DOS2 mode

		call	makefcb		; DOS1. Make FCB and Open command.
		ld	hl,filenamedos1
		call	BuildFCB
		call	open		; Open. If file doesn't exist then error and exit.
		jp	checkfile3	; Show size in 8 K and 16 K pages.

checkfile2:	; DOS2 Open
		ld	de,filenamedos2
		xor	a
		ld	b,0
		ld	c,043h		; Open file DOS2
		call	bdos

		ld	de,filenot_txt
		jp	nz,errortxt	; if Z = 0 then file not found. Error and Exit

		ld	a,b
		ld	(filehandle),a	; Save FILE HANDLE


		push	bc	; For check size in DOS 2, use SEEK Command.
		ld	a,2
		ld	de,0
		ld	hl,0	; Seek
		ld	c,04Ah
		call	bdos
		ld	(sizefile),hl
		ld	(sizefile+2),de

		pop	bc

						; And Now Return Seek to POS 0


		xor	a
		ld	de,0
		ld	hl,0
		ld	c,04Ah
		call	bdos


checkfile3:	; Little Size Routine to change size to ASCII
		ld	a,(sizefile+2)
		and	011110000b
		ld	de,filesize_txt
		jp	nz,errortxt	; File > 512 Ks. ERROR.

		ld	a,(sizefile)
		ld	c,a
		ld	a,(sizefile+1)
		and	01Fh
		or	c	; Distinto de 0 si el fichero no es multiplo de 8Ks
		ld	c,0
		jr	z,checkfile30
		inc	c
checkfile30:
		ld	a,(sizefile+1)	; Size to 8 K page size.
		and	0E0h
		ld	b,a
		ld	a,(sizefile+2)
		and	0Fh
		rl	b
		rl	a
		rl	b
		rl	a
		rl	b
		rl	a
		jr	nz,checkfile31	; No hay ni una pagina de 8K
		inc	a
checkfile31:
		add	a,c	; Suma una pagina extra si la ROM no es multiplo de 8K
		ld	(pages8),a	; Save 8 K pages size.
		srl	a
		ld	(pages),a	; Number of 16K pages
		jr	nc,checkfile32
		inc	a
		ld	(pages),a
checkfile32:
		ld	a,(pages8)
		ld	de,mappages8_txt	; 8K Page Size to ASCII
		ld	ix,mappages8
		call	checkfile33

		ld	a,(pages)	; 16 K Page Size to ASCII
		ld	ix,mappages
		ld	de,mappages_txt

checkfile33:

		; This little code
		; makes conversion 
		; number to ASCII
	
		; WARNING: This code is specific for FL2. Not general code for conversions.

		cp	10
		jr	c,checkfileend
		ld	c,0

checkfile4:
		inc	c
		sub	10
		cp	10
		jr	nc,checkfile4

		push	af
		ld	a,c
		add	a,030h
		ld	(ix+0),a
		pop	af

checkfileend:
		add	a,030h
		ld	(ix+1),a
		jp	print

; --------------------
; CHECKRUNADR
; Check run adress
; --------------------

checkrunadr:
		ld	ix,rungameroutine	; check CD 00 00 bytes
checkrunadr0:
		ld	a,(ix+0)
		cp	0CDh
		jr	nz,checkrunadr1
		ld	a,(ix+1)
		or	a
		jr	nz,checkrunadr1
		ld	a,(ix+2)
		or	a
		jr	z,checkrunadr2
checkrunadr1:
		inc	ix
		jr	checkrunadr0
checkrunadr2:
		ld	(rungameadr),ix	; and save address
		ret


; *** PROGRAM ROUTINES ***

; ----------------------------
; LOADFILE
; Load File into Flash
; Load ALL FILE into Flash ROM
; ----------------------------

loadfile:


		ld	de,write_txt
		call	print		; Show Write Text 

		ld	a,(pages)
		ld	b,a		; Loop "page" times
		or	a
		jr	nz,loadfile1		; If file < 16 Ks 
		ld	b,1			; then 1 loop MIN.

		xor	a			; init actual 16 page. 
		ld	(actualpage),a

loadfile1:					; load loop
		push	bc
		call	fillpage		; fill page 2 (read buffer) with 0FFh
		call	load16K		; and load one 16 K page to buffer

		call	patch_country	; if option
		pop	bc
		push	bc
		call	writeflash		; now write this 16 K to FLASH

		ld	de,punto_txt
		call	print			; show '.' for 16 K page loaded
		pop	bc
		ld	a,(actualpage)
		inc	a
		ld	(actualpage),a	; and inc page to next loop
		djnz	loadfile1		; next loop
		call	close			; end for load. Close File.

		ld	de,intro_txt
		call	print
		ld	de,exitok_txt	; and print Success Text.
		jp	print

; ------------------
; LOAD16K
; Load 16K 
; to page 2
; from file open
; ------------------

load16K:
			; this code load 16 Ks from file
			; to buffer (page 2 08000h - 0BFFFh)

		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT		; mem in page 2
		ei
		ld	de,08000h
		ld	hl,04000h
		ld	a,(dos)
		cp	2
		jr	nc,load16K2		; if DOS 2 make <> load

		push	hl			; DOS 1 LOAD.
		call	setdma		; set DMA
		pop	hl
		call	readmax		; and read 16 Ks or max if file < 16K or file size 
		jp	read			; is not mult. of 16. And READ.
load16K2:
						; DOS 2 LOAD
		ld	a,(filehandle)
		ld	b,a
		ld	c,048h		; DOS 2 COMMAND LOAD
		jp	bdosce

; ----------------
; PATCH_COUNTRY
; Patch keyboard
; and mode in ROM
; -----------------

patch_country:
		ld	a,(options)
		and	000000110b	; Check /j and /e command.
		ret	z	; Not necessary to patch ROM

		rrca
		and	1
		ld	e,a

		ld	a,(ID)
		and	0F0h
		or	e
		ld	e,a

		di
		ld	hl,08000h
		ld	bc,03FFFh
patch_country1:
	
		ld	a,03Ah	; byte a buscar  
		cpir
		ret	nz	; No hay mas...  

		ld	a,(hl)
		cp	02Bh
		jp	nz,patch_country1	; Otro intento
		inc	hl
		ld	a,(hl)
		or	a
		jp	nz,patch_country1
		dec	hl
		ld	(hl),e
		dec	hl
		ld	(hl),03Eh
		inc	hl
		jp	patch_country1




; --------------------
; FILL PAGE
; Fill page 2 with FFH
; ---------------------

fillpage:
		ld	hl,08000h
		ld	de,08001h
		ld	bc,03FFFh
		ld	(hl),0FFh
		ldir				; fill
		ret

; -----------------
; FILLNAME
; Search params for
; extract filename
; -----------------


fillname:
		ld	hl,filenamedos2+63
		ld	b,64				; max params. End to init loop
fillname0:
		ld	a,(hl)
		or	a
		jr	z,fillname1			; 0 dec
		cp	':'	; end
		jr	z,fillname2
		cp	05Ch 	; "\"             ; params 
		jr	z,fillname2
fillname1:
		dec	hl
		djnz	fillname0

fillname2:
		inc	hl
		ld	de,filenameshow	; loop for fill filenameshow
fillname3:
		ld	a,(hl)
		or	a
		ret	z
		ld	(de),a
		inc	hl
		inc	de
		jr	fillname3

; ----------------------
; DELAY
; Flash operation delay
; for erase command
; ----------------------

delay:
		push	bc			; this delay is for erasing operations

		call	check
		ld	de,error_txt
		jp	c,error

		ld	de,punto_txt
		call	print		; print "." from 64 Ks block or loop delay in

		ld	a,(flashslt)
		ld	h,040h
		call	ENASLT		; return flash to page 2 (DOS1 Compatibility)
		ei
		pop	bc
		ret


; -------------------------------------------------------
; SIGSLOT
; Returns in A the next slot every time it is called.
; For initializing purposes, THISSLT has to be #FF.
; If no more slots, it returns A=#FF.
; --------------------------------------------------------

			; this code is programmed by Nestor Soriano aka Konamiman

sigslot:
		ld	a,(thisslt)	;Returns the next slot, starting by
		cp	0FFh			;slot 0. Returns #FF when there are not more slots
		jr	nz,SIGSL1		;Modifies AF, BC, HL.  
		ld	a,(EXPTBL)
		and	%10000000
		ld	(THISSLT),a
		ret

SIGSL1:
		ld	a,(THISSLT)
		cp	%10001111
		jr	z,NOMASLT
		cp	%00000011
		jr	z,NOMASLT
		bit	7,a
		jr	nz,SLTEXP

SLTSIMP:
		and	%00000011
		inc	a
		ld	c,a
		ld	b,0
		ld	hl,EXPTBL
		add	hl,bc
		ld	a,(hl)
		and	%10000000
		or	c
		ld	(THISSLT),a
		ret

SLTEXP:
		ld	c,a
		and	%00001100
		cp	%00001100
		ld	a,c
		jr	z,SLTSIMP
		add	a,%00000100
		ld	(THISSLT),a
		ret

NOMASLT:
		ld	a,0FFh
		ret

; *** FLASH ROUTINES ***

; ----------------------
; WRITEFLASH
; Write 16 Ks into Flash
; page 1 : Flash
; page 2 : Buffer
; NZ = Error
; ----------------------

writeflash:
		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT			; mem to page 2 (DOS1)

		ld	a,(flashslt)
		ld	h,040h
		call	ENASLT		; flash to page 1

		ld	hl,08000h	; from
		ld	de,04000h	; to
		ld	b,d
		ld	c,e
writeflash0:
		di
		ld	a,0AAh
		ld	(04555h),a
		ld	a,055h
		ld	(042AAh),a
		ld	a,0A0h
		ld	(04555h),a	; 4 cycles command PROGRAM     

		ld	a,(actualpage)
		out	(05Ch),a		; select 16 K page in Flash Rom

		ld	a,(hl)
		ld	(de),a
writeflash1:
		call	writeflashp


		inc	hl	; Ok. Next byte.
		inc	de
		dec	bc
		ld	a,b
		or	c
		jp	nz,writeflash0	; All 16 Ks programmed? Return for making next block.
		ei

writeflash2:
		push	af
		ld	a,(0F342h)
		ld	h,040h
		call	ENASLT		; Mem to PAGE 1. (DOS 1 Compatibility)
		pop	af
		ret

		; program byte and check 3 times firt byte
		; check jumper RD

writeflashp:
		push	hl
		push	de
		push	bc
		ld	c,2

writeflashp0:				; write byte loop

		ld	a,(hl)
		ld	(de),a

writeflashp1:

		nop				; little delay
		dec	c


		ld	a,(de)
		xor	(hl)
		jr	z,writeflashpend	; ok programmed

		ld	a,c
		or	a
		jr	nz,writeflashp1

		ld	de,writeproblem_txt
		jp	errortxt	; oops! Error writing bytes. Show Error and exit.

writeflashpend:
		pop	bc
		pop	de
		pop	hl
		ret

; -----------------------
; ERASEFLASH 
; Sector Erase command
; or CHIP Erase Command
; -----------------------

eraseflash:
		ld	de,erase_txt
		call	print			; Erase Text Show.

		ld	a,(flashslt)
		ld	h,040h
		call	ENASLT		; set flash in 04000h


		ld	a,(pages)
		ld	b,a
		srl	b
		srl	b	; DIV pages. Size File / 64. Erase Sector  = 64 K.
		jr	nz,eraseflash0
		inc	b	; if filesize < 64 Ks, MIN 1 block
		jr	erase_f
eraseflash0:
		and	011b	; Si el nzmero de paginas de 16Ks no es mzltiplo de 64
		jr	z,erase_f
		inc	b
erase_f:
		ld	a,030h
		ld	(eraseflashcmd),a


		ld	a,(options2)
		bit	0,a	; check if /d (Only Delete)
		jr	nz,eraseflash01	; Yes. Go to CHIP ERASE Command

		ld	a,(options)
		bit	6,a	; Check if /s (Delete All Sectors and Load)
		jr	z,eraseflash00	; No. Go To Loop Erase 


eraseflash01:
		ld	b,1			; erase all flash (chip erase). 1 Loop.
		ld	a,010h
		ld	(eraseflashcmd),a
		xor	a
		ld	(erasedelay),a	; And init to 010h Command (CHIP ERASE)

eraseflash00:
		ld	c,0			; Loop Init.

eraseflash1:				; Erase Loop. Sector Erase or Chip Erase
		di
		ld	hl,04555h
		ld	de,042AAh
		ld	(hl),0AAh
		ld	a,055h
		ld	(de),a
		ld	(hl),080h
		ld	(hl),0AAh
		ld	(de),a		; 6 cycles COMMAND
		ld	a,c
		out	(05Ch),a		; And pos. page.
		inc	c
		inc	c
		inc	c
		inc	c			; INC FOUR TIMES. Sector size = 64 Ks.

		ld	a,(eraseflashcmd)	; erase command or chip command
		cp	010h			; check if chip command.
		jr	nz,eraseflash2	; No. Goto Erase Sector Command
		ld	(hl),a		; Write CHIP ERASE Command.
		jr	eraseflash3		; Go To second delay and end.
eraseflash2:
		ld	(04000h),a		; Yeah! Sector Erase Command.
eraseflash3:
		call	delay	; and check
		di
		ld	a,0F0h	; end command. Reset Command.
		ld	(04000h),a
		djnz	eraseflash1		; if Sector Erase and file > 64K Loop
		ei

		ld	de,intro_txt
		call	print			; print one intro

		ld	a,(options)
		bit	6,a		; check if /d command.
		ret	z			; No. Return to Main program
		jp	exitok		; Yes. Exit.


; *** GENERIC SYSTEM ROUTINES ***

; -------------
; CURSOR ON OFF
; -------------

cursoron:
		ld	a,1
cursorset:
		ld	(CSRSW),a
		ret
cursoroff:
		xor	a
		jr	cursorset


; ----------------
; CMPHLDE
; Compares HL and DE
; BIOS RST 020H Clon.
; -----------------

cmphlde:
		ld	a,h
		sub	d
		ret	nz
		ld	a,l
		sub	e
		ret

; ---------------
; BDOSCE
; bdos with error
; Call to BDOS and
; check error
; ----------------

bdosce:	call	BDOSADR
		or	a
		jp	nz,error
		ret

; -----------------
; BDOS
; bdos without error
; ------------------

bdos:
		call	BDOSADR
		or	a
		ret

; -----------------------------------------------
; ERROR
; print error
; call ERRORTXT and set DE pointer to error text
; -----------------------------------------------

error:
		ld	de,error_txt
errortxt:
		ld	c,09h
		call	bdos

; ---------------
; EXITOK
; Exit OK
; ---------------

exitok:
		call	close			; close file (open or not)
		ld	a,(0F342h)
		ld	h,040h
		call	ENASLT		; set mem to page 1
		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT		; set mem to page 2

		ld	a,(system)
		cp	3	; Turbo R?
		jr	c,exit		; No. Go To Exit
		ld	a,(savecpu)		; Yes. Restore CPU Mode
		call	systemsetcpu

; ---------------
; EXIT
; program exit
; ---------------

exit:
		ld	a,(savecursor)	; Restore Cursor Value
		call	cursorset
		ld	sp,(savesp)		; And Restore SP 
		ld	c,0 			; Program Terminate BDOS Command.
		jp	bdos			; Go and Exit. WOW!


; -----------------
; RUNGAME CODE
; Code for making
; BIOS changes
; and RUN Game
; "On the fly"
; -----------------

			; This code is moved in main program to
			; RUNGAME Adress

rungameorg:
		call	close			; Close File. 

		ld	a,(options)
		ld	(optionsc),a	; makes copy options variable

		ld	a,(system)
		ld	(systemc),a		; makes copy system variable
		cp	3	; Turbo R?
		jr	nz,rungameorg0	; No. Stupid use /8 Param.

		ld	a,080h	; Yes. Restore Z80 CPU Mode
		call	systemsetcpu

		ld	a,(options)		; Yes. Check if /8 Command
		bit	3,a
		ld	a,081h
		call	nz,systemsetcpu	; Yes. Set R800 NO DRAM Mode.

rungameorg0:
		ld	de,presspace_txt
		call	print			; Press <SPACE> to Run Game Text.

		ld	a,(0F343h)
		ld	h,080h
		call	ENASLT		; Set MEM to page 2

		ld	a,(flashslt)
		ld	h,040h
		call	ENASLT		; set Flash Rom to page 2 (simulated cartridge)

rungame0:
		ld	a,8
		ld	ix,0141h
		ld	iy,(EXPTBL-1)
		call	CALSTL
		and	1
		jr	nz,rungame0		; check if PRESS SPACE

		ld	sp,(savesp)		; restore SP value

						; Code for set BIOS in page 0
						; It is not possible to use 024H Command. Halt.
		di
		ld	a,(EXPTBL)
		and	3
		ld	b,a			; FCC1h BIOS Slot
		in	a,(0A8h)		; Read A8h slot port
		and	011111100b		; Ignore 0-1 bits
		or	b
		out	(0A8h),a	; and set BIOS Slot

		ld	a,(EXPTBL)		; Check if EXPANDED Slot
		ld	b,a
		and	080h
		jr	z,rungame00		; No. Go to Next Rungame Routine

		ld	a,b			; Yes. Read 0FFFFh Expanded Slot Port.
		and	000001100b
		srl	a
		srl	a
		ld	b,a
		ld	a,(0FFFFh)
		cpl
		and	011111100b		; Ignore 0-1 actual bits (page 0)
		or	b
		ld	(0FFFFh),a		; and set BIOS Slot

rungame00:

			; VIDEO Routines
		ld	a,(systemc)
		or	a	; MSX2 or Higher?
		jr	z,rungame1		; No. MSX1. Stupid /5 or /6 params.

		ld	a,(optionsc)
		ld	b,a
		and	000110000b	; check if user use /5 or /6 param.
		jr	z,rungame1		; No. Go To next routine.

		ld	a,b
		ld	b,0
		bit	5,a		; 50 Hz?
		jr	nz,rungame03	; Yes. Go to Make Video Change.
		ld	b,2
		bit	4,a			; Then is 60 Hz change.
		jr	nz,rungame03

rungame03:
		ld	a,(EXTVDP+1)
		and	011111101b
		or	b
		ld	(EXTVDP+1),a
		out	(099h),a
		ld	a,128+9
		out	(099h),a		; #9 VDP Register. Set Video Mode.

rungame1:					; Yeah! End Code. RUN GAME!!

		xor	a
		out	(05Ch),a		; set flash pages to init or reset set
		ld	(06000h),a		; page 0 = 0
		inc	a
		out	(05Dh),a
		ld	(06800h),a		; page 1 = 1
		inc	a
		out	(05Eh),a
		ld	(07000h),a		; page 2 = 2
		inc	a
		out	(05Fh),a
		ld	(07800h),a		; page 3 = 3

		ld	hl,(04002h)		; EXEC Adress from ROM
		ld	ix,(rungameadr)
		ld	(ix+1),l
		ld	(ix+2),h		; patch my run code
rungameexe:
		call	0			; Nooo. 0 nooo. this is patched address. :)
						; If Game does not use disk then run and end,
						; but if the game uses disk, then search it.
						; In this moment the system and DOS are running.
						; End of search.
						; The game returns to this point
						; and set in 0FEDCh system var, the run adress
						; for ROM program.
		ld	hl,(0FEDCh)
		jp	(hl)			; Well. :) Run. Bye!

rungameend:


; *** BDOS ROUTINES ***

; -------------------
; PRINT
; DE : Pointer to Text
; --------------------

print:
		ld	c,09h
		jp	bdos

; ----------------
; MAKEFCB
; Prepare NEW FCB
; ---------------

MakeFCB:
		ld	hl,FCB
		ld	de,FCB+1
		ld	(hl),0
		ld	bc,37
		ldir
		ret

; -------------
; BUILDFCB
; HL = Pointer to namefile string
; ----------------

BuildFCB:
		ld	de,FileName
		ld	bc,11
		ldir
		ret

; ---------------
; OPEN FCB FILE
; ---------------

Open:
		ld	de,FCB
		ld	c,0Fh
		call	bdos
		ld	de,filenot_txt
		jp	nz,errortxt

		ld	ix,FCB
		ld	a,1
		ld	(ix+14),a
		xor	a
		ld	(ix+15),a
		ld	(ix+33),0
		ld	(ix+34),0
		ld	(ix+35),0
		ld	(ix+36),0
		ret

; --------------
; SEEK
; DEHL = Pointer
; --------------

Seek:
		ld	ix,FCB
		ld	(ix+33),l
		ld	(ix+34),h
		ld	(ix+35),e
		ld	(ix+36),d
		ret

; ------------
; SETDMA
; DE = Buffer
; ------------

SetDMA:
		ld	c,01Ah
		jp	bdos

; -------------------------------------------------------
; READ
; HL Bytes to read from opened FCB, with the pointer ready
; -------------------------------------------------------

Read:
		ld	de,FCB
		ld	c,027h
		jp	bdosce


; ----------------
; CLOSE
; CLOSE FCB FILE
; ----------------

Close:				; Close File. Check DOS variable for DOS2 and DOS1 Close
		ld	a,(dos)
		cp	2
		jr	nc,close2

		ld	de,FCB
		ld	c,010h
		jp	bdos

close2:
		ld	a,(filehandle)
		ld	b,a
		ld	c,045h
		jp	bdos

; -------------------------
; READ MAX
; HL : Size to read
; Returns HL max size
; -------------------------

readmax:
		; this code
		; is for DOS1 Compatibility

		; In DOS2 if HL parameter (Read Size) > Size File or Bytes to read
		; Do not Return ERROR 
		; But DOS1 RETURN ERROR
		; The Load16K Code USES HL = 16384 bytes ALWAYS.

		push	af
		push	de

		push	hl

		xor	a
		ld	hl,(sizefile+2)
		ld	de,(sizeread+2)
		sbc	hl,de
		ld	(sizefiletmp+2),hl
		ld	hl,(sizefile)
		ld	de,(sizeread)
		sbc	hl,de
		ld	(sizefiletmp),hl
		pop	hl

		push	hl

		ld	de,(sizefiletmp)
		call	cmphlde
		jr	nc,readmax0
		pop	hl
readmaxend:
		pop	de
		pop	af
		ret

readmax0:
		ld	de,(sizefiletmp+2)
		ld	hl,0
		call	cmphlde
		pop	hl
		jr	z,readmax1
		jr	readmaxend

readmax1:
		ld	hl,(sizefiletmp)
		jr	readmaxend


; *** TEXTS ***

logo_txt:
		.text	"Flash Rom Loader 2.3 (DOS 2 Compatible) for LPE-FLASH G"
		.dw	intro
		.text	"(c) 2003 by Ramones & Manuel Pazos"
		.dw	intro
		.db	endline
help_txt:
		.dw	intro
		.text	"Usage:"
		.dw	intro
		.text	"     FL2 /opts <filename.ext>"
		.dw	intro
		.text	"     FL2 <filename.ext> /opts"
		.dw	intro
		.text	"Example : FL2 MGALIOUS.ROM /r /e"
		.dw	intro
		.dw	intro
		.text	"Options:"
		.dw	intro
		.text	"     /h : Show this help."
		.dw	intro
		.text	"     /r : Run stored game."
		.dw	intro
		.text	"     /e : Run emulating European Keyboard."
		.dw	intro
		.text	"     /j : Run emulating Japanese Keyboard."
		.dw	intro
		.text	"     /8 : Run R800 mode."
		.dw	intro
		.text	"     /5 : Run in PAL mode (50hz)."
		.dw	intro
		.text	"     /6 : Run in NTSC mode (60hz)."
		.dw	intro
		.text	"     /d : Only delete all sectors."
		.dw	intro
		.text	"     /s : Delete all sectors on load."
		.dw	intro
		.text	"     /n : Don't load, use stored game."
		.dw	intro
		.dw	intro
		.text	"  Page size : 16 KB | Slot On / Off | Read Mode : Rd&Wr | Mapper : I/O"
		.db	endline


search_txt:
		.text	"Searching LPE-FLASH G cartridge in system ..."
		.dw	intro
		.db	endline
notfound_txt:

		.text	"Oops! Flash Rom not Found!!"
		.dw	intro
		.text	"Please check the 'slot on / off' switch."
		.dw	intro
		.db	endline

found_txt:
		.text	"Found LPE-FLASHG in slot : "
foundslt:	.db	030h
		.text	"  subslot : "
foundsslt:	.db	030h
		.dw	intro
		.db	endline

error_txt:
		.text	"ERROR!!!!"
		.db	0Dh,0Ah,"$"
filenot_txt:
		.dw	intro
		.text	"ERROR : Problems opening file ..."
		.dw	intro
		.db	endline

filesize_txt:
		.dw	intro
		.text	"ERROR: File Size > 512 Ks"
		.dw	intro
		.db	endline

open_txt:
		.dw	intro
		.text	"Open file : "

filenameshow:
		.text	"                "
		.dw	intro
		.db	endline

mappages_txt:
		.dw	intro
		.text	"Number of 16 K Pages : "
mappages:
		.dw	03030h
		.dw	intro
		.db	endline

mappages8_txt:
		.dw	intro
		.text	"Number of 08 K Pages : "
mappages8:
		.dw	03030h
		.dw	intro
		.db	endline

erase_txt:
		.dw	intro
		.text	"Erasing Flash Rom "
		.db	endline

intro_txt:
		.dw	intro
		.db	endline

punto_txt:
		.text	"."
		.db	endline
write_txt:
		.dw intro
		.text	"Loading "
		.db endline

writeproblem_txt:

		.dw	intro
		.text	"ERROR : Problems writing Flash Rom ..."
		.dw	intro
		.db	endline

exitok_txt:
		.dw	intro
		.text	"File loaded succesfully."
		.dw	intro
		.db	endline

presspace_txt:
		.dw	intro
		.text	"Press <SPACE> to run the game."
		.dw	intro
		.db	endline


; *** VARIABLES ***

savesp:	.dw	0		; stack pointer
savecpu:	.db	0		; cpu mode in Turbo R
savecursor:	.db	0	; cursor 
dos:		.db	0		; dos version
system:	.db	0		; msx version
options:	.db	0		; options variable 1
options2:	.db	0		; options variable 2
pages8:	.db	0		; 8 K pages
pages:	.db	0		; 16 Kb Pages
actualpage:	.db	0		; Temporal page for load
thisslt:	.db	0FFh		; sigslot flag
flashslt:	.db	0		; slot for flash
id:	.db	0	; country byte
eraseflashcmd:			; tmp variable for Erase Command
		.db	0

erasedelay:
		.db	0		; tmp variable for loop times delay

sizefiletmp:
		.ds	4		; tmp variable for READMAX Code
filehandle:	.db	0		; DOS 2 File Handle

filenamedos2:
		.ds	64		; Tmp for filename
filenamedos1:
		.text	"        "	; DOS1 Filename for DOS1 Code
filendos1ext:
		.text	"   "
		.ds	4

; *** FCB DOS 1 ***

FCB:
Unidad:	.db	0
FileName:	.ds	8
Extname:	.ds	3
		.dw	0
Registro:	.dw	0
SizeFile:	.ds	4
		.ds	13
sizeread:
		.ds	4
		.db	0
                
		.end
