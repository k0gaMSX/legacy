/*
 * setjmp.c for UZIX
 * by A&L Software, 08/07/99
 */
#include <setjmp.h>

static int _lngjmprv = 1;

#ifdef __TURBOC__

int setjmp (env)
	jmp_buf env;
{
	env[0].di = _DI;
	env[0].si = _SI;
	env[0].bp = _BP;
	env[0].sp = _SP;
	__emit__(0x58); /* pop ax */
	__emit__(0x50); /* push ax */
	env[0].pc = _AX;
	return 0;
}

void longjmp(env, rv)
	jmp_buf env;
	int 	rv;
{
	_SP = env[0].sp;
	_DI = env[0].di;
	_SI = env[0].si;
	_BP = env[0].bp;
	__emit__(0x58); /* pop ax */ /* discards return from longjmp */
	_AX = env[0].pc;
	__emit__(0x50); /* push ax */ /* now return is as it was from setjmp */
	if (rv) 
		return rv;
	return 1; 
}
#endif

#ifdef HI_TECH_C
#include "setjmp.msx"
#endif
