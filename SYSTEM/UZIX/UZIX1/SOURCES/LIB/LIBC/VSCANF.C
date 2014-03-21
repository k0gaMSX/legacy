/* scanf.c
 */

#include "scanf.h"

#ifdef L_vscanf
int vscanf(fmt, ap)
	char *fmt;
	va_list ap;
{
	return vfscanf(stdin, fmt, ap);
}
#endif
