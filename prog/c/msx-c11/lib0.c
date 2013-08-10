/*
	LIB0.C  -       declarations for assembly language subroutines
			(for FPC)
	 8-Jul-85       debug inp(), outp()
	20-Jul-87       move movmem(), setmem(), memcpy(), memset()
			from LIBZ
			add setjmp(), longjmp(), _initrap(), _endtrap()

	The functions whose name begin with underscore character
	are only used internally.
*/

#include "stdio.h"


char    bdos(c)
char    c;
{
}

int     bdosh(c)
char    c;
{
}

char    bios(code)
char    code;
{
}

char    calla(addr, a, hl, bc, de)
int     *addr, a, hl, bc, de;
{
}

int     call(addr, a, hl, bc, de)
int     *addr, a, hl, bc, de;
{
}

char    inp(port)
unsigned        port;
{
}

VOID    outp(port, val)
unsigned port;
char    val;
{
}

VOID    memcpy(dest, source, length)
char    *dest, *source;
size_t  length;
{
}

VOID    movmem(source, dest, length)
char    *dest, *source;
size_t  length;
{
}

VOID    memset(dest, byte, length)
char    *dest, byte;
size_t  length;
{
}

VOID    setmem(dest, length, byte)
char    *dest, byte;
size_t  length;
{
}

int     setjmp(env)
jmp_buf env;
{
}

VOID    longjmp(env, val)
jmp_buf env;
int     val;
{
}

VOID    _initrap()
{
}

VOID    _endtrap()
{
}
