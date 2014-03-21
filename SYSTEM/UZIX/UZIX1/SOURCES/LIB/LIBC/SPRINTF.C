/* printf.c
 *    Dale Schumacher			      399 Beacon Ave.
 *    (alias: Dalnefre')		      St. Paul, MN  55104
 *    dal@syntel.UUCP			      United States of America
 *
 * Altered to use stdarg, made the core function vfprintf.
 * Hooked into the stdio package using 'inside information'
 * Altered sizeof() assumptions, now assumes all integers except chars
 * will be either
 *  sizeof(xxx) == sizeof(long) or sizeof(xxx) == sizeof(short)
 *
 * -RDB
 */

#include "printf.h"

#ifdef L_sprintf
#if 1
int sprintf(char *sp, char *fmt,...)
#else
int sprintf(sp, fmt, va_alist)
	char *sp;
	char *fmt;
	va_dcl
#endif
{
	static FILE string[1] = {
		{ 0, 0, (unsigned char *)-1, 0, (unsigned char *)-1, -1,
		_IOFBF | __MODE_WRITE
		}
	};
	va_list ptr;
	int rv;

	va_strt(ptr, fmt);
	string->bufpos = (unsigned char *)sp;
	rv = vfprintf(string, fmt, ptr);
	va_end(ptr);
	*(string->bufpos) = 0;
	return rv;
}
#endif

