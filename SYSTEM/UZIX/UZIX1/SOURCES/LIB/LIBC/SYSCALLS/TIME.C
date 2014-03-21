/********** MSX-UZIX version of syscalls ************/
/* time_t time(time_t *tvec); */

#include "syscalls.h"

#ifdef L_time
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");

UNIX gtime(time_t *tvec);

	asm("_gtime:");
	asm("	ld hl,30");
	asm("	jp __sys__1");

time_t time(time_t *tvec) {
	time_t ttvec;
	
	if (tvec == NULL) {
		gtime(&ttvec);
		return ttvec;
	}
	gtime(tvec);
	return *tvec;
}
#endif
