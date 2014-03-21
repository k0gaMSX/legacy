/* scanf.c
 */

#include "scanf.h"

#ifdef L_sscanf
#if 1
int sscanf(char *sp, char *fmt,...)
#else
int sscanf(sp, fmt, va_alist)
	char *sp;
	char *fmt;
	va_dcl
#endif
{
	static FILE string[1] = {
		{ 0, (unsigned char *)-1, 0, 0, (unsigned char *)-1, -1,
		  _IOFBF | __MODE_READ
		}
	};
	va_list ptr;
	int rv;

	va_strt(ptr, fmt);
	string->bufpos = (unsigned char *)sp;
	rv = vfscanf(string, fmt, ptr);
	va_end(ptr);
	return rv;
}
#endif
