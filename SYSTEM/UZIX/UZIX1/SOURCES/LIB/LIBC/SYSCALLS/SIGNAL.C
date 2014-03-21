/********** MSX-UZIX version of syscalls ************/
/* UNIX signal(signal_t sig, sig_t func); */

#include "syscalls.h"

#ifdef L_signal
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_signal");
	asm("	signat	_signal,8250");
	asm("_signal:");
	asm("	ld d,0");	/* SIG is 8 uchar, but is passed to UNIX as uint */
	asm("	ld hl,26");
	asm("	jp __sys__2");
#endif


