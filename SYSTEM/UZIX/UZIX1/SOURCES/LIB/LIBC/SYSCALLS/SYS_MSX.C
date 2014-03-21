/********** MSX-UZIX version of syscalls ************/

#include "syscalls.h"

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#define dosyscall()	asm(" call " __str1(SYSCADDR))

	asm("	psect text,class=CODE");
        asm("   global __sys__, __sys__1, __sys__2, __sys__3, __ret__");

/* System call structure:
 *  Arguments passed through stack: unix(#,arg1, arg2, ...)
 *  Result returned in DE:HL (LSB/MSB form)
 *  If error found then CY=1 and BC=errno
 *  WARNING:
 *  As result is 32 bits, if it's a 16 bit value (all syscalls, except lseek),
 *  HL will allways be 0, returning a false result from syscall.
 *  That's why the EX DE,HL in __ret__. If a syscall must return a
 *  long value, do the CALL 5 in the syscall itself, no via __sys__x
 *  (see lseek for example) and remember doin EX DE,HL before calling __ret__.
 */
#ifdef L___syscall
	asm("	global _errno");

	asm("__sys__3:");
	asm("	push bc"); /* the third value is already in stack */
	asm("	push de");
	asm("	push hl");
	dosyscall();
	asm("	inc sp");
	asm("	inc sp"); /* discards second arg in stack */
	asm("	jr 3f");
	asm("__sys__2:");
	asm("	push bc");
	asm("	push de");
	asm("	push hl");
	dosyscall();
	asm("3: inc sp");
	asm("	inc sp"); /* discards second arg in stack */
	asm("	jr 2f");
	asm("__sys__1:");
	asm("	push de");
	asm("	push hl");
	dosyscall();
	asm("2: inc sp");
	asm("	inc sp"); /* discards first arg in stack */
	asm("	jr 1f");
	asm("__sys__:");
	asm("	push hl");
	dosyscall();
	asm("1: inc sp");
	asm("	inc sp"); /* discards last value in stack (HL) */
	asm("__ret__:");
	asm("	ex de,hl");
	asm("	ret nc");
	asm("	ld (_errno),bc");
	asm("	ld de,-1");
	asm("	ld hl,-1");
	asm("	ret");

	asm("	global	__setset");
	asm("	global	__getset");
	asm("__setset:");
	asm("	pop bc");
	asm("__getset:");
	asm("	ld hl,7");
	asm("	jp __sys__2");
#endif
