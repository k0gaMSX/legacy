/********** MSX-UZIX version of syscalls ************/
/* UNIX modulereg(uint sig, int (*func)()); */
/* UNIX moduledereg(uint sig); */
/* UNIX modulecall(uint sig, uint fcn, char *args, int argsize); */
/* UNIX modulesendreply(int pid, int fcn, char *repladdr, int replysize); */
/* UNIX modulereply(int sig, int fcn, char *repladdr); */

#include "syscalls.h"

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)
#define dosyscall()	asm(" call " __str1(SYSCADDR))

#ifdef UZIX_MODULE
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");

        asm("   global  _modulereg");
        asm("   signat  _modulereg, 8250");
        asm("_modulereg:");
        asm("   ld hl,40");
	asm("	jp __sys__2");

        asm("   global  _moduledereg");
        asm("   signat  _moduledereg, 4154");
        asm("_moduledereg:");
        asm("   ld hl,41");
        asm("   jp __sys__1");

        asm("   global  _modulecall");
        asm("   signat  _modulecall, 16442");
        asm("_modulecall:");
        /* DE=module sign
           BC=function
           on stack: retaddr args argsize
         */
        asm("	exx");
        asm("	pop bc");	/* BC'=ret addr */
        asm("	pop de");	/* DE'=args */
        asm("	pop hl");	/* HL'=argsize */
        asm("	push bc");
        asm("	push hl");
        asm("	push de");
        asm("	exx");		/* now stack is: args argsize retaddr */
        asm("	push bc");
        asm("	push de");	/* now is: DE BC args argsize retaddr */
        asm("   ld hl,42");     /* syscall */
	asm("	push hl");
	dosyscall();
	asm("	inc sp");
	asm("	inc sp");	/* discards syscall number */
	asm("	inc sp");
        asm("   inc sp");       /* discards argsize */
	asm("	inc sp");
        asm("   inc sp");       /* discards args */
	asm("	inc sp");
        asm("   inc sp");       /* discards fcn */
	asm("	inc sp");
        asm("   inc sp");       /* discards sig */
	asm("	ex de,hl");	/* cancel EX DE,HL in __ret__ */
	asm("	jp __ret__");

        asm("   global  _modulesendreply");
        asm("   signat  _modulesendreply, 16442");
        asm("_modulesendreply:");
        /* DE=PID
           BC=function
           on stack: retaddr args argsize
         */
        asm("	exx");
        asm("	pop bc");	/* BC'=ret addr */
        asm("	pop de");	/* DE'=args */
        asm("	pop hl");	/* HL'=argsize */
        asm("	push bc");
        asm("	push hl");
        asm("	push de");
        asm("	exx");		/* now stack is: args argsize retaddr */
        asm("	push bc");
        asm("	push de");	/* now is: DE BC args argsize retaddr */
        asm("   ld hl,43");     /* syscall */
	asm("	push hl");
	dosyscall();
	asm("	inc sp");
	asm("	inc sp");	/* discards syscall number */
	asm("	inc sp");
        asm("   inc sp");       /* discards replysize */
	asm("	inc sp");
        asm("   inc sp");       /* discards repladdr */
	asm("	inc sp");
        asm("   inc sp");       /* discards fcn */
	asm("	inc sp");
        asm("   inc sp");       /* discards pid */
	asm("	ex de,hl");	/* cancel EX DE,HL in __ret__ */
	asm("	jp __ret__");

        asm("   global  _modulereply");
        asm("   signat  _modulereply, 12346");
        asm("_modulereply:");
        /* DE=module sign
           BC=function
           on stack: retaddr addr
         */
        asm("	exx");
        asm("	pop bc");	/* BC'=ret addr */
        asm("	pop de");	/* DE'=addr */
        asm("	push bc");
        asm("	push de");
        asm("	exx");		/* now stack is: addr retaddr */
        asm("	push bc");
        asm("	push de");	/* now is: DE BC addr retaddr */
        asm("   ld hl,44");     /* syscall */
	asm("	push hl");
	dosyscall();
	asm("	inc sp");
	asm("	inc sp");	/* discards syscall number */
	asm("	inc sp");
        asm("   inc sp");       /* discards repladdr */
	asm("	inc sp");
        asm("   inc sp");       /* discards fcn */
	asm("	inc sp");
        asm("   inc sp");       /* discards sig */
	asm("	ex de,hl");	/* cancel EX DE,HL in __ret__ */
	asm("	jp __ret__");
#endif


