GLOBAL _cloadptr,_bloadptr,_vramptr

SECTION .data
_cloadptr:
  incbin "cload.bin"
_bloadptr:
  incbin "bload.bin"
_vramptr:
  incbin "clear.bin"
	
