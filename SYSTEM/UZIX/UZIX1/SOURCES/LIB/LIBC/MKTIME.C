/*************************** MKTIME ************************************/
#include "time-l.h"

#ifdef L_mktime
time_t mktime (__tp)
	struct tm *__tp;
{
	time_t tt;

	tt.t_time = (((int)__tp->tm_hour << 8) << 3) | 
	            ((int)__tp->tm_min << 5) | 
	            ((int)__tp->tm_sec >> 1);
	tt.t_date = (((int)(__tp->tm_year - 80) << 8) << 1) | 
	            ((int)(__tp->tm_mon+1) << 5) | __tp->tm_mday;
	return tt;
}
#endif

