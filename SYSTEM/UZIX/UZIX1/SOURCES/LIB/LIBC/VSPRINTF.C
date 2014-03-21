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

#ifdef L_vsprintf
int vsprintf(sp, fmt, ap)
	char *sp;
	char *fmt;
	va_list ap;
{
	static FILE string[1] = {
		{ 0, 0, (unsigned char *)-1, 0, (unsigned char *)-1, -1,
		_IOFBF | __MODE_WRITE
		}
	};
	int rv;

	string->bufpos = (unsigned char *)sp;
	rv = vfprintf(string, fmt, ap);
	*(string->bufpos) = 0;
	return rv;
}
#endif

