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


; void inifnk()

;	INIFNK	initializes function key strings.
;	Entry:	None.
;	Exit:	None.

INIFNK	equ	003Eh

	psect	text
	global	_inifnk

_inifnk:
	msxbios INIFNK
	ret

; void erafnk()

;	ERAFNK	erases the function key display.

ERAFNK	equ	00CCh
	psect	text
	global	_erafnk
_erafnk:
	msxbios ERAFNK
	ret

; void dspfnk()

;	DSPFNK	displays the function key display.

DSPFNK	equ	00CFh
	psect	text
	global	_dspfnk

_dspfnk:
	msxbios DSPFNK
	ret

; void di()

	psect	text
	global	_di
_di:
	di
	ret

; void ei()

	psect	text
	global	_ei
_ei:
	ei
	ret

                    