/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** ltoa.c ****************************/
#ifdef L_ltoa
char *ltoa(value, strP, radix)
	long value;
	char *strP;
	int radix;
{
	char hex = 'A';

	if (radix < 0) {
		hex = 'a';
		radix = -radix;
	}
	return	__longtoa (value, strP, radix, (radix == 10), hex);
}
#endif

