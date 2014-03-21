/*************************** LOCALTIME ************************************/
#include "time-l.h"

#ifdef L_localtim
struct tm *localtime(timep)
	time_t *timep;
{
	static struct tm tmb;

	__tm_conv(&tmb, timep, 0);
	return &tmb;
}
#endif

