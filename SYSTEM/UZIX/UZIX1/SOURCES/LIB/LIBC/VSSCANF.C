/* scanf.c
 */

#include "scanf.h"

#ifdef L_vsscanf
int vsscanf(sp, fmt, ap)
	char *sp;
	char *fmt;
	va_list ap;
{
	static FILE string[1] = {
		{ 0, (unsigned char *)-1, 0, 0, (unsigned char *)-1, -1,
		  _IOFBF | __MODE_READ
		}
	};
	string->bufpos = (unsigned char *)sp;
	return vfscanf(string, fmt, ap);
}
#endif
