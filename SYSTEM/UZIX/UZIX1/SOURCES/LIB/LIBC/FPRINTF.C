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

#ifdef L_fprintf
#if 1
int fprintf(FILE * fp, char *fmt,...)
#else
int fprintf(fp, fmt, va_alist)
	FILE *fp;
	char *fmt;
	va_dcl
#endif
{
	va_list ptr;
	int rv;

	va_strt(ptr, fmt);
	rv = vfprintf(fp, fmt, ptr);
	va_end(ptr);
	return rv;
}
#endif

