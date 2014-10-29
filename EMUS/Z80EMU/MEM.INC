;--------------------------------------------
; Next routines are used by all memory routines
;--------------------------------------------
; Output emulation
; HL= Memory location
; A = Data
; Can change: Nothing

PUTA:
	LD (HL),A
	RET
;---------------------------
; Input emulation
; HL= Memory location
; A = Data
; Can change: F-reg

GETA:
	LD A,(HL)
	RET