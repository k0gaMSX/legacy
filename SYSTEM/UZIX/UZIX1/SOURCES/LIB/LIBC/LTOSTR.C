/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** ltostr.c ****************************/
#ifdef L_ltostr
static char buf[34];	/* max len for radix == 2 */

char *ultostr(val, radix)
	unsigned long val;
	int radix;
{
	return ultoa(val,buf,radix);
}

char *ltostr(val, radix)
	long val;
	int radix;
{
	return ltoa(val,buf,radix);
}
#endif

