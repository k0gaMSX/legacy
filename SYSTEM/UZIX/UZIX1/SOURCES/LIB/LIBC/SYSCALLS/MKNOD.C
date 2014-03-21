/********** MSX-UZIX version of syscalls ************/
/* UNIX mknod(char *name, mode_t mode, int dev); */

#include "syscalls.h"

#ifdef L_mknod
	asm("	psect text,class=CODE");
	asm("	global __sys__3");
	asm("	global	_mknod");
	asm("	signat	_mknod,12346");
	asm("_mknod:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,18");
	asm("	jp __sys__3");
#endif
