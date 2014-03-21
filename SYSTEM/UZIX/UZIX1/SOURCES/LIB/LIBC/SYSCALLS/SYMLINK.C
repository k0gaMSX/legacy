/********** MSX-UZIX version of syscalls ************/
/* UNIX symlink(char *oldname, char *newname); */

#include "syscalls.h"

#ifdef L_symlink
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_symlink");
	asm("	signat	_symlink,8250");
	asm("_symlink:");
	asm("	ld hl,38");
	asm("	jp __sys__2");
#endif
