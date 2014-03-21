/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** atol.c ****************************/
#ifdef L_atol
long atol(str)
	char *str;
{
	return strtol(str,NULL,10);
}
#endif

