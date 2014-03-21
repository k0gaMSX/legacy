/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** atoi.c ****************************/
#ifdef L_atoi
int atoi(str)
	char *str;
{
	return (int)strtol(str,NULL,10);
}
#endif

