/*************************** CTIME ************************************/
#include "time-l.h"

#ifdef L_ctime
char *ctime(timep)
	time_t *timep;
{
	return asctime(localtime(timep));
}
#endif

