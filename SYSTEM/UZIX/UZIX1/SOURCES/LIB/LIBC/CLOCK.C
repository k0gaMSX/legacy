/*************************** CLOCK ************************************/
#include "time-l.h"

#ifdef L_clock
#include <types.h>
#include <unistd.h>

long clock(VOID) {
	struct tms __tms;

	times(&__tms);
	return (__tms.tms_utime.t_time+__tms.tms_utime.t_date*CLOCKS_PER_SEC*60);
}
#endif

