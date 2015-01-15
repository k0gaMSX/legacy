; Fake overlay


size	equ	05000h		; max overlay size

	global	_ovbgn, _ovsize, _ovstart

	psect	text

_ovsize:
	defw	size		; this should never be overlaid
_ovstart:
	defw	_ovbgn

	psect	bss		; this goes in the uninit bit
_ovbgn:
	defs	size		; reserve room for overlay

	end
