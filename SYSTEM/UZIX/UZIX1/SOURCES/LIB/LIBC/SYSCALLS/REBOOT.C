/********** MSX-UZIX version of syscalls ************/
/* UNIX reboot(char p1, char p2); */

#include "syscalls.h"

#ifdef L_reboot
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_reboot");
	asm("	signat	_reboot,8250");
	asm("_reboot:");
	asm("	ld b,0");
	asm("	ld d,0");
	/* p1/p2 are char, not int, so D and B must be zeroed */
	asm("	ld hl,37");
	asm("	jp __sys__2");
#endif


