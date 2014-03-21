/*************************** GMTIME ************************************/
#include "time-l.h"

#ifdef L_gmtime

static unsigned int __mon_days[12] = {
	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

void __tm_conv(tmbuf, pt, offset)
	struct tm *tmbuf;
	time_t *pt;
	int offset;
{
	register int y, i, wday, yday;

	tmbuf->tm_sec = (pt->t_time & 31) * 2;
	tmbuf->tm_min = ((pt->t_time >> 5) & 63) + offset;
	tmbuf->tm_hour = ((pt->t_time >> 11) & 31);
	
	tmbuf->tm_mday = (pt->t_date & 31);
	tmbuf->tm_mon = ((pt->t_date >> 5) & 15) - 1;
	y = ((pt->t_date >> 9) & 127) + 1980;

	while (tmbuf->tm_min < 0) {
		tmbuf->tm_min += 60;
		tmbuf->tm_hour--; 
		while (tmbuf->tm_hour < 0) {
			tmbuf->tm_hour += 24;
			i =  __mon_days[tmbuf->tm_mon];
			if (tmbuf->tm_mon == 1 && __isleap(y))
				++i;
			tmbuf->tm_mday--; 
			while (tmbuf->tm_mday < 0) {
				tmbuf->tm_mday += i;
				tmbuf->tm_mon--; 
				while (tmbuf->tm_mon <= 0) {
					tmbuf->tm_mon += 12;
					--y;
				}
			}
		}
	}
	while (tmbuf->tm_min >= 60) {
		tmbuf->tm_min -= 60;
		tmbuf->tm_hour++; 
		while (tmbuf->tm_hour >= 24) {
			tmbuf->tm_hour -= 24;
			i =  __mon_days[tmbuf->tm_mon];
			if (tmbuf->tm_mon == 1 && __isleap(y))
				++i;
			tmbuf->tm_mday++; 
			while (tmbuf->tm_mday > i) {
				tmbuf->tm_mday -= i;
				tmbuf->tm_mon++; 
				while (tmbuf->tm_mon >= 12) {
					tmbuf->tm_mon -= 12;
					++y;
				}
			}
		}
	}
	tmbuf->tm_year = y - 1900;
	if (y > 1996) {
		/* Jan 1, 1997 was Wen */
		i = 1997;
		wday = 2;
	}
	else {
		/* Jan 1, 1970 was Thu */
		i = 1970;
		wday = 3;
	}
	while (i < y) {
		wday += __isleap(i) ? 2 : 1;
		++i;
	}
	i = 0;
	yday = tmbuf->tm_mday; 
	while (i < tmbuf->tm_mon) {
		yday += __mon_days[i];
		if (i == 1 && __isleap(i))
			++yday;
		++i;
	}
	tmbuf->tm_wday = (wday + yday) % 7;
	tmbuf->tm_yday = yday + 1;
	tmbuf->tm_isdst = -1;
#if TIME_T_IS_JUST_A_LONG_NUMBER
	long t = unixtime(pt);

	days = t / SECS_PER_DAY;
	rem = t % SECS_PER_DAY;
	rem += offset;
	while (rem < 0) {
		rem += SECS_PER_DAY;
		--days;
	}
	while (rem >= SECS_PER_DAY) {
		rem -= SECS_PER_DAY;
		++days;
	}
	tmbuf->tm_hour = rem / SECS_PER_HOUR;
	rem %= SECS_PER_HOUR;
	tmbuf->tm_min = rem / 60;
	tmbuf->tm_sec = rem % 60;
	/* January 1, 1970 was a Thursday.  */
	tmbuf->tm_wday = (4 + days) % 7;
	if (tmbuf->tm_wday < 0)
		tmbuf->tm_wday += 7;
	y = 1970;
	while (days >= (rem = __isleap(y) ? 366 : 365)) {
		++y;
		days -= rem;
	}
	while (days < 0) {
		--y;
		days += __isleap(y) ? 366 : 365;
	}
	tmbuf->tm_year = y - 1900;
	tmbuf->tm_yday = days;
	ip = __mon_lengths[__isleap(y)];
	y = 0; 
	while (days >= ip[y])
		days -= ip[y++];
	tmbuf->tm_mon = y;
	tmbuf->tm_mday = days + 1;
	tmbuf->tm_isdst = -1;
#endif
}

struct tm *gmtime(timep)
	time_t *timep;
{
	static struct tm tmb;

	__tm_conv(&tmb, timep, (int)(timezone/60));
	return &tmb;
}
#endif

