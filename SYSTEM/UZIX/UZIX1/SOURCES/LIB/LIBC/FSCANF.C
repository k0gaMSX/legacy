/* scanf.c
 */

#include "scanf.h"

#ifdef L_fscanf
#if 1
int fscanf(FILE * fp, char *fmt,...)
#else
int fscanf(fp, fmt, va_alist)
	FILE *fp;
	char *fmt;
	va_dcl
#endif
{
	va_list ptr;
	int rv;

	va_strt(ptr, fmt);
	rv = vfscanf(fp, fmt, ptr);
	va_end(ptr);
	return rv;
}
#endif
