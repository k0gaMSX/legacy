/********** MSX-UZIX version of syscalls ************/
/* UNIX open(name, flag, ...); */

#include "syscalls.h"

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#define dosyscall()	asm(" call " __str1(SYSCADDR))

#ifdef L_open
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_open");
	asm("	signat	_open,4122");
	asm("_open:");
	asm("	push ix");
	asm("	ld ix,0");
	asm("	add ix,sp");
	asm("	ld l,(ix+6)");
	asm("	ld h,(ix+7)");
	asm("	push hl");	/* last parameter in stack */
	asm("	ld l,(ix+4)");
	asm("	ld h,(ix+5)");
	asm("	push hl");	/* flag in stack */
	asm("	push de");	/* name in stack */
	asm("	ld hl,20");
	asm("	push hl");
	dosyscall();
	asm("	call __ret__");
	asm("	pop ix"); /* discards HL (syscall number) */
	asm("	pop ix"); /* discards DE */
	asm("	pop ix"); /* discards first HL */
	asm("	pop ix"); /* discards second HL */
	asm("	pop ix"); /* restore original IX */
	asm("	ret");
#endif
