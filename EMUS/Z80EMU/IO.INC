;--------------------------------------------
; Next routines are used by all I/O routines
;--------------------------------------------
; Output emulation
; C = I/O port
; A = Data

OUTPUT:
	OUT (C),A
	RET

;---------------------------
; Input emulation
; C = I/O port
; A = Data

INPUT:
	IN A,(C)
	RET