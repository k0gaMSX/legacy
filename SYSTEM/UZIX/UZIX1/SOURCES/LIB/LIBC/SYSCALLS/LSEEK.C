/********** MSX-UZIX version of syscalls ************/
/* UNIXL lseek(int file, off_t offset, int flag); */

#include "syscalls.h"

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#define dosyscall()	asm(" call " __str1(SYSCADDR))

#ifdef L_lseek
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_lseek");
	asm("	signat	_lseek,12348");
	asm("_lseek:");
	asm("	pop hl");	/* HL=ret addr */
	asm("	push ix");	/* save IX */
	asm("	ld ix,0");
	asm("	add ix,sp");
	asm("	ld c,(ix+6)");
	asm("	ld b,(ix+7)");	/* BC=flag */
	asm("	push bc");
	asm("	ld (ix+6),l");
	asm("	ld (ix+7),h");	/* put ret addr after arguments in stack */
	asm("	pop ix");	/* IX=flag (was in BC) */
	asm("	ex (sp),ix");	/* IX=original value, put flag in stack */
	asm("	pop hl");	/* HL=flag */
	asm("	pop bc");	/* BC=offset lsw */
	asm("	ex (sp),hl");	/* put flag in stack, HL=offset msw */
	asm("	push hl");	/* put offset msw in stack */
	asm("	push bc");	/* put offset lsw in stack */
	asm("	push de");	/* put file in stack */
	asm("	ld hl,25");	/* syscall */
	asm("	push hl");
	dosyscall();
	asm("	inc sp");
	asm("	inc sp");	/* discards syscall number */
	asm("	inc sp");
	asm("	inc sp");	/* discards flag */
	asm("	inc sp");
	asm("	inc sp");
	asm("	inc sp");
	asm("	inc sp");	/* discards offset */
	asm("	inc sp");
	asm("	inc sp");	/* discards file */
	asm("	ex de,hl");	/* cancel EX DE,HL in __ret__ */
	asm("	jp __ret__");
#endif
