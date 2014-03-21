/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** strtol.c ****************************/
#ifdef L_strtol
#include <ctype.h>

long strtol(nptr, endptr, base)
	char *nptr, **endptr;
	int base;
{
	long number;
	int negative = 0;
	char *ptr = nptr;

	while (isspace(*ptr))
		ptr++;
	if (*ptr == '-') {
		++negative;
		++ptr;
	}
	else if (*ptr == '+')
		++ptr;
	number = (long)strtoul(ptr, endptr, base);
	return (negative ? -number : number);
}
#endif

