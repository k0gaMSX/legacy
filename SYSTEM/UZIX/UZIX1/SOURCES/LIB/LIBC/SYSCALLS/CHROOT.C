/********** MSX-UZIX version of syscalls ************/
/* UNIX chroot(char *dir); */

#include "syscalls.h"

#ifdef L_chroot
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_chroot");
	asm("	signat	_chroot,4154");
	asm("_chroot:");
	asm("	ld hl,39");
	asm("	jp __sys__1");
#endif
