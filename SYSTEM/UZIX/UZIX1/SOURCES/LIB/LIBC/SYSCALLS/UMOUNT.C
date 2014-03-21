/********** MSX-UZIX version of syscalls ************/
/* UNIX umount(char *spec); */

#include "syscalls.h"

#ifdef L_umount
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_umount");
	asm("	signat	_umount,4154");
	asm("_umount:");
	asm("	ld hl,32");
	asm("	jp __sys__1");
#endif


