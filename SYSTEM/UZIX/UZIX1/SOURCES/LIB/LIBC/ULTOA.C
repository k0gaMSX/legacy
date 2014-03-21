/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** ultoa.c ****************************/
#ifdef L_ultoa
char  *ultoa(value, strP, radix)
	unsigned long value;
	char *strP;
	int radix;
{
	char hex = 'A';

	if (radix < 0) {
		hex = 'a';
		radix = -radix;
	}
	return	__longtoa (value, strP, radix, 0, hex);
}
#endif

