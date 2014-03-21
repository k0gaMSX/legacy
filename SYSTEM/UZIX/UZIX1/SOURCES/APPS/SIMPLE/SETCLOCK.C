/* setclock.c
 * descripton:	 set machine real-time clock
 * author:	 Adriano Cunha <adrcunha@dcc.unicamp.br>
 * license:	 GNU Public License version 2
 */
#include <unistd.h>
#include <string.h>
#include <time.h>
#ifdef __TURBOC__
#define	STDOUT_FILENO	1
#endif

/* get an integer value from *p and return the first char after in p1 */
int getint(char *p, char **p1) {
	int v = 0;

	while (*p >= '0' && *p <= '9') {
		v *= 10;
		v += *p - '0';
		++p;
	}
	*p1 = p;
	return v;
}

/* convert a given time in t1 and date in t2 into struct tm */
int conv_time(char *t1, char *t2, struct tm *tt) {
	int h, m, s, d, mm, y;
	char *t;

	/* hh:mm[:ss] */
	t = t1;
	h = getint(t, &t);
	if ((h < 0) || (h > 23) || (*t++ != ':'))	return 0;
	m = getint(t, &t);
	if ((m < 0) || (m > 59))			return 0;
	if (*t) {
		if (*t++ != ':')			return 0;
		s = getint(t, &t);
		if ((s < 0) || (s > 59) || (*t != 0))	return 0;
	}
	else	s = 0;

	/* dd/mm/yy[yy] */
	t = t2;
	d = getint(t, &t);
	if ((d < 1) || (d > 31) || (*t++ != '/'))	return 0;
	mm = getint(t, &t);
	if ((mm < 1) || (mm > 12) || (*t++ != '/'))	return 0;
	y = getint(t, &t);
	if (y < 100) {
		if (y < 80)
			y += 100;
	}
	else	y -= 1900;
	if ((y < 0) || (*t != 0))			return 0;
	tt->tm_hour = h;
	tt->tm_min = m;
	tt->tm_sec = s;
	tt->tm_year = y;
	tt->tm_mon = mm - 1;
	tt->tm_mday = d;
	return 1;
}

void wr(char *s) {
	write(STDOUT_FILENO, s, strlen(s));
}

int main(argc, argv)
	int argc;
	char **argv;
{
	struct tm tt;
	time_t mytimet;

	if (argc < 2) {
		wr("usage: setclock hh:mm[:ss] dd/mm/yyyy\n");
		return 0;
	}
	argv++;
	if (!conv_time(*argv, *(argv + 1), &tt)) {
		wr("Bad date/time format\n");
		return 1;
	}
#ifdef __TURBOC__
	wr(asctime(&tt));
#else
	mytimet = mktime(&tt);
	if (stime(&mytimet) < 0) {
		wr("You have no permission to set clock\n");
		return 2;
	}
#endif
	return 0;
}
