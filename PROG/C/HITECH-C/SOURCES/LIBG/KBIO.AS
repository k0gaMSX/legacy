        MACRO   msxbios,routine
	psect	text
	push	ix
	push	iy
	ld	ix,routine
	ld	iy,(0fcc0h)
	call	001ch
	ei
	pop	iy
	pop	ix
	ENDM

; void kilbuf()

;	KILBUF	clears the keyboard buffer.

KILBUF	equ	0156h
	psect	text
	global	_kilbuf

_kilbuf:
	msxbios KILBUF
	ret

; unsigned char chsns()

;	CHSNS	checks the status of keyboard buffer.

CHSNS	equ	009Ch

	psect	text
	global	_chsns

_chsns:
	msxbios CHSNS
	ld	hl,0
	ret	z		; buffer empty
	inc	hl
	ret


; char chget()

;	CHGET	waits for characters being input and returns the
;		character code. (equals getch)

;CHGET	 equ	 009Fh
;	 psect	 text
;	 global  _chget
;
;_chget:
;	 msxbios CHGET
;	 ld	 l,a
;	 ld	 h,0
;	 ret

; void chput(c)
; char	  c;

;	CHPUT	outputs a character to the console.

CHPUT	equ	00A2h
	psect	text
	global	_chput

_chput:
	ld	a,l
	msxbios CHPUT
	ret

; int lptout(c)
; char	  c;

;	LPTOUT	outputs a character to the line printer.
;	Returns 0 if successful, -1 if aborted, 1 if printer busy

LPTOUT	equ	00A5h
	psect	text
	global	_lptout

_lptout:
	push	hl
	call	_lptstt
	ld	hl,1
	ret	z		; return 1 if busy
	msxbios LPTOUT
	sbc	a,a
	ret


; char lptstt()

;	LPTSTT	checks the line printer status.
;	Exit:	1   if printer ready,
;		0   if not.

LPTSTT	equ	00A8h
	psect	text
	global	_lptstt

_lptstt:
	msxbios LPTSTT
	ld	hl,0
	ret	z
	ld	hl,1
	ret


; char *pinlin()

PINLIN	equ	00AEh
	psect	text
	global	_pinlin
_pinlin:
	msxbios PINLIN
	inc	hl
	ret

; char *inlin()

INLIN	equ	00B1h
	psect	text
	global	_inlin
_inlin:
	msxbios INLIN
	inc	hl
	ret

; unsigned char breakx()

;	BREAKX	checks the status of the Control-STOP key.
;	Exit:	0 if not pressed, 1 if being pressed

BREAKX	equ	00B7h
	psect	text
	global	_breakx

_breakx:
	msxbios BREAKX
	sbc	a,a			; 000h if not pressed
					; 0ffh if being pressed
	and	1
	ret

                                                                                                                     