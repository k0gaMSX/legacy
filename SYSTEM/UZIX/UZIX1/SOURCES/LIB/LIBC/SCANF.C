/* scanf1.c
 */

#include "scanf.h"

#ifdef L_scanf
#if 1
int scanf(char *fmt,...)
#else
int scanf(fmt, va_alist)
	char *fmt;
	va_dcl
#endif
{
	va_list ptr;
	int rv;

	va_strt(ptr, fmt);
	rv = vfscanf(stdin, fmt, ptr);
	va_end(ptr);
	return rv;
}
#endif
