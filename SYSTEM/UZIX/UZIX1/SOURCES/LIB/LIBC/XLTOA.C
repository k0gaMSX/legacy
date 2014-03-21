/* numeric/string conversions package
 */

#include "cvt.h"

/*************************** xltoa.c ***************************/
#ifdef L_xltoa
char *_ultoa(val)
	unsigned long val;
{
	return ultostr(val,10);
}

char *_ltoa(val)
	long val;
{
	return ltostr(val,10);
}
#endif
