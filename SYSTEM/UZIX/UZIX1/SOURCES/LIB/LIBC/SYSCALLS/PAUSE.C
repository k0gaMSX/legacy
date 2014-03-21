/********** MSX-UZIX version of syscalls ************/
/* UNIX pause(void); */

#include "syscalls.h"

#ifdef L_pause
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_pause");
	asm("	signat	_pause,26");
	asm("_pause:");
	asm("	ld hl,21");
	asm("	jp __sys__");
#endif


