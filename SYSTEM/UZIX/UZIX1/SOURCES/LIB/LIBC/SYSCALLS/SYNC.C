/********** MSX-UZIX version of syscalls ************/
/* UNIX sync(void); */

#include "syscalls.h"

#ifdef L_sync
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_sync");
	asm("	signat	_sync,26");
	asm("_sync:");
	asm("	ld hl,29");
	asm("	jp __sys__");
#endif


