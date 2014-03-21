#ifndef __SETJMP_H
#define __SETJMP_H
#ifndef __TYPES_H
#include <types.h>
#endif

#ifdef __TURBOC__
/*
 * I know most systems use an array of ints here, but I prefer this   - RDB
 */
typedef struct {
	unsigned int pc;
	unsigned int sp;
	unsigned int bp;
	unsigned int si;
	unsigned int di;
} jmp_buf[1];
#else

#ifdef HI_TECH_C

typedef int jmp_buf[7];

#else

#error fillin setjmp.h!

#endif
#endif

int setjmp __P((jmp_buf env));
void longjmp __P((jmp_buf env, int rv));

#endif

