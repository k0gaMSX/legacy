/* numeric/string conversions package
 */

#include "cvt.h"

/*********************** xitoa.c ***************************/
#ifdef L_xitoa
char *_itoa(i)
	int i;
{
	return ltostr((long)i,10);
}
#endif
