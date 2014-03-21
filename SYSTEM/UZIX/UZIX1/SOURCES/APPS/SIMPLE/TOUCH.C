/* touch.c
 * descripton:	 change files creation/modification date
 * author:	 Archi Schekochikhin
 *		 Adriano Cunha <adrcunha@dcc.unicamp.br>
 * license:	 GNU Public License version 2
 */

#include <unistd.h>
#include <sys/stat.h>
#include <utime.h>
#include <time.h>
#include <string.h>
#include <errno.h>

void wr(char *s) {
	write(STDERR_FILENO, s, strlen(s));
}

int getint(p, p1)
	char *p;
	char **p1;
{
	int v = 0;
	for (v = 0; *p >= '0' && *p <= '9'; ++p) {
		v *= 10;
		v += *p - '0';
	}
	*p1=p;
	return v;
}

int xconvtime(t1, t2, timet)
	char *t1;
	char *t2;
	time_t *timet;
{
	int h,m,s,d,mm,y;
	char *t, *dd, *e;
	struct tm tt;

	t=t1;
	dd=t2;
	h=getint(t, &e);
	if ((h<0) || (h>23) || (*e!=':')) return 0;
	m=getint(t=++e, &e);
	if ((m<0) || (m>59) || (*e!=':')) return 0;
	s=getint(t=++e, &e);
	if ((s<0) || (s>59) || (*e!=0)) return 0;
	d=getint(dd, &e);
	if ((d<1) || (d>31) || (*e!='/')) return 0;
	mm=getint(dd=++e, &e);
	if ((mm<1) || (mm>12) || (*e!='/')) return 0;
	dd++;
	y=getint(dd=++e, &e);
	if (y<100) {if (y<80) y+=100;} else y-=1900;
	if ((y<0) || (*e!=0)) return 0;
	tt.tm_hour=h;
	tt.tm_min=m;
	tt.tm_sec=s;
	tt.tm_year=y;
	tt.tm_mon=mm-1;
	tt.tm_mday=d;
	*timet=mktime(&tt);
	return 1;
}

int main(argc, argv)
	int argc;
	char **argv;
{
	int i, fd, er = 0, ncreate = 0, modif = 0, mytime = 0, tmptim;
	struct utimbuf utim;
	struct stat statbuf;
	char *p;
	time_t now, mytimet;

	if (argc < 2) {
		wr("usage: touch [-c] [-m] [-d time] filename ...\n");
		return 0;
	}
	argc--;
	argv++;
	while ((argc > 0) && (**argv == '-')) {
		argc--;
		p = *argv++ ;
		while (*++p) switch (*p) {
			case 'd':
				if (!xconvtime(*argv, *(argv+1), &mytimet)) {
					wr("Bad date/time format\n");
					return 0;
				}
				argc -= 2;
				argv += 2;
				mytime = 1;
				break;
			case 'c':
				ncreate = 1;
				break;
			case 'm':
				modif = 1;
				break;
			default:
				wr("Unknown option(s) ");
				wr(p);
				wr(".\n");
				return 0;
		}
	}
	for (i = 0; i < argc; i++) {
		p = argv[i];
		if ((fd = open(p, 2)) < 0) {
			if (errno == ENOENT) {
				if (!ncreate) {
					er = creat(p, 0666);
					if (er != -1) er = close(er);
				}
			}
		} else {
			close(fd);
			time(&now);
			stat(p, &statbuf);
				utim.actime = now;
				utim.modtime = now;
			if (mytime) {
				utim.actime = mytimet;
				utim.modtime = mytimet;
			}
			if (modif) utim.actime = statbuf.st_atime;
			er = utime(p, &utim);
		}
		if (er != 0) {
			wr("Can't touch file ");
			wr(p);
			wr(".\n");
		}
	}
	return er;
}

