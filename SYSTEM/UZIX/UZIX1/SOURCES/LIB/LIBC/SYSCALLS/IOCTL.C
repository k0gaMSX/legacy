/********** MSX-UZIX version of syscalls ************/
/* UNIX ioctl(fd, req, ...) */

#include "syscalls.h"

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#define dosyscall()	asm(" call " __str1(SYSCADDR))

#ifdef L_ioctl
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_ioctl");
	asm("	signat	_ioctl,4122");
	asm("_ioctl:");
	asm("	push ix");
	asm("	ld ix,0");
	asm("	add ix,sp");
	asm("	ld l,(ix+6)");
	asm("	ld h,(ix+7)");
	asm("	push hl");
	asm("	ld l,(ix+4)");
	asm("	ld h,(ix+5)");
	asm("	push hl");
	asm("	push de");
	asm("	ld hl,15");
	asm("	push hl");
	dosyscall();
	asm("	call __ret__");
	asm("	pop ix"); /* discards HL */
	asm("	pop ix"); /* discards DE */
	asm("	pop ix"); /* discards first HL */
	asm("	pop ix"); /* discards second HL */
	asm("	pop ix");
	asm("	ret");
#endif
