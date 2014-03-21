/* ps.c
 * descripton:	 show processes status
 * author:	 Archi Schekochikhin
 * modified by:  Adriano Cunha <adrcunha@dcc.unicamp.br>
 *		 added the many formats (Archi's version had only one)
 * license:	 GNU Public License version 2
 */

/* obs: options X, w and c not implemented
 *	option n affects only username
 */

#include <stdio.h>
#include <syscalls.h>
#include <unix.h>
#include <time.h>
#include <string.h>
#include <pwd.h>

#define M_l	'l'	/* long format */
#define M_u	'u'	/* user format */
#define M_s	's'	/* signals format */
#define M_m	'm'	/* memory info format */
#define M_X	'X'	/* eXecution format */

#define F_a	0x01	/* all users flag */
#define F_c	0x02	/* command flag */
#define F_w	0x04	/* wide output flag */
#define F_h	0x08	/* no header flag */
#define F_r	0x10	/* running only flag */
#define F_n	0x20	/* numeric output flag */

int	mode = 0;
int	flags = 0;

void do_ps __P((void));
char *mapstat __P((pstate_t));

char *mapstat(s)
	pstate_t s;
{
	switch (s) {
	case P_ZOMBIE:	return "Zombie";
	case P_FORKING: return "Forking";
	case P_RUNNING: return "Running";
	case P_READY:	return "Ready";
	case P_SLEEP:	return "Sleep";
	case P_PAUSE:	return "Pause";
	case P_WAIT:	return "Waitfor";
	}
	return "Undef";
}

/* UZIX t_time is not just counting seconds...
 * so, dirty conversion routines are here:
 */

unsigned long ticks2seconds(time_t *t) {
 return (t->t_time/CLOCKS_PER_SEC)+(t->t_date*60);
}

time_t seconds2uzixtime(unsigned long t) {
 int y=0,m=0,d=0,h=0,mm=0;
 unsigned long t1=t;
 time_t tt;

 if (t1>=31536000) {
  y=t1/31536000L;
  t1=t1-(y*31536000L);
  y=y-10;
 }
 if (t1>=2592000) {
  m=t1/2592000L;
  t1=t1-(m*2592000L);
  m++;
 }
 if (t1>=86400) {
  d=t1/86400;
  t1=t1-d*86400;
  d++;
 }
 if (t1>=3600) {
  h=t1/3600;
  t1=t1-h*3600;
 }
 if (t1>=60) {
  mm=t1/60;
  t1=t1-m*60;
 }
 tt.t_time=(((int)h << 8) << 3) | ((int)mm << 5) | ((int)t1 >> 1);
 tt.t_date=(((int)y << 8) << 1) | ((int)m << 5) | d;
 return tt;
}

void do_ps() {
	info_t info;
	ptptr p;
	int i, j, uid;
	struct s_pdata pdata;
	struct s_kdata kdata;
	char *str;
	char stime[9], cputime[9], pmem, pcpu;
	char nuser[5], username[9], pssize[5];
	int useridknown = 0, userid = 0;
	struct passwd *pwd;
	int totalram;
	time_t temptime;
	signal_t psignal;
	unsigned long ptimes;
	unsigned char pri;
#define psize	32		/* UZIX: all processes have 32k size */
#define ptty	0		/* UZIX: only one tty now */

	getfsys(GI_PTAB, &info);
	getfsys(GI_KDAT, &kdata);
	totalram = kdata.k_tmem;
	stime[8] = '\0';
	cputime[8] = '\0';
	strcpy(nuser,"USER");
	if (flags & F_n) {
	 	strcpy(nuser, "UID");
	 	useridknown = 1;
	}
	uid = getuid();
	if (!(flags & F_h)) {
		if (mode == 0) printf("  PID\tTTY\tSTAT\tTIME     COMMAND\n");
		if (mode == M_l) printf("%-8s PID   PRI NI  SIZE WCHAN STAT    TTY\tTIME     ALARM\tCOMMAND\n",nuser);
		if (mode == M_u) printf("%-8s PID   %CPU %MEM TTY\tSTAT\tSTART    TIME     COMMAND\n",nuser);
		if (mode == M_s) printf("%-8s PID   SIGNAL PENDING IGNORED STAT\tTTY\tTIME     COMMAND\n",nuser);
		if (mode == M_m) printf("  PID   PPID  TTY\tSIZE\tSTAT\tCOMMAND\n");
	}
	for (p = (ptptr)info.ptr, i = 0; i < info.size; ++i, ++p) {
		if (p->p_status == 0 || (!(flags & F_a) && (p->p_uid != uid)))
			continue;
		if ((flags & F_r) &&
		    (p->p_status != P_RUNNING && p->p_status != P_READY))
			continue;
		pdata.u_pid = p->p_pid;
		/* dependent data from getfsys(pdata) */
		if (p->p_status != P_ZOMBIE) {
			if (getfsys(GI_PDAT, &pdata) < 0) 
				continue;
			psignal = pdata.u_cursig;
			/* start time of process */
			str = ctime(&pdata.u_time);
			strncpy(stime, &str[11], 8);
			/* process CPU time */
			ptimes = ticks2seconds(&pdata.u_utime);
			temptime = seconds2uzixtime(ptimes);
			str = ctime(&temptime);
			strncpy(cputime, &str[11],8);
			/* %CPU */
			time(&temptime);
			pcpu = (ptimes*100)/difftime(&temptime, &pdata.u_time);
		} else {
			psignal = 0;
			strcpy(stime, "--:--:--");
			strcpy(cputime, "--:--:--");
			pcpu = 0;
			strcpy(pdata.u_name, "?");
		}
		pri = p->p_cprio;
		/* user id */
		if (!useridknown || (p->p_uid != userid)) {
			if ((pwd = getpwuid(p->p_uid)) != NULL)
				strcpy(username, pwd->pw_name);
			else	sprintf(username, "%-5d", p->p_uid);
			userid = p->p_uid;
			useridknown = 1;
		}
		/* you must calculate psize here */
		/* %MEM */
		pmem = (psize*100)/totalram;
		/* convert pmem to a string terminated by k or M */
		j = psize;	/* process size in kbytes */
		if (j < 1000) {	/* I know that 1Mb=1024kb, but who cares? */
		 	sprintf(pssize, "%3dk", j);
		} 
		else {
		 	j /= 1024;	/* too dirty... do it better! */
		 	sprintf(pssize, "%3dM", j);
		}
		/* show info */
		if (mode == 0) printf("%5d\t%d\t%s\t%s %s\n",
			p->p_pid, ptty, mapstat(p->p_status), cputime,
			pdata.u_name);
		if (mode == M_l) printf("%-8s %-5d %-3d %-3d %-4s %04X  %-7s %-3d\t%s %-5d  %s\n",
			username, p->p_pid, pri, p->p_nice, pssize, p->p_wait,
			mapstat(p->p_status), ptty, cputime,
			p->p_alarm, pdata.u_name);
		if (mode == M_u) printf("%-8s %-5d %2d%c %2d%c %d\t%s\t%s %s %s\n",
			username, p->p_pid, pcpu, '%', pmem, '%', ptty,
			mapstat(p->p_status), stime, cputime, pdata.u_name);
		if (mode == M_s) printf("%-8s %-5d %-6d %-7d %-7d %s\t%d\t%s %s\n",
			username, p->p_pid, psignal, p->p_pending, p->p_ignored,
			mapstat(p->p_status), ptty, cputime, pdata.u_name);
		if (mode == M_m) printf("  %-5d %-5d %d\t\t%s\t%s\t%s\n",
			p->p_pid, p->p_pptr->p_pid, ptty, pssize, mapstat(p->p_status),
			pdata.u_name);
	}
	fflush(stdout);
}

int main(argc, argv)
	int argc;
	char **argv;
{
	int i;

	for (i = 1; i < argc; ++i) {
		char *p = argv[i];

		if (*p == '-')
			++p;
		while (*p) switch (*p++) {
		case 'l':
		case 'u':
		case 's':
		case 'm':
		/*case 'X':*/
			if (mode != 0) {
				fprintf(stderr, "ps: l, u, s and m are mutually exclusive\n");
				return 0;
			}
			mode = p[-1];
		case 'a':	flags |= F_a;	break;
		/*case 'c':	flags |= F_c;	break;*/
		/*case 'w':	flags |= F_w;	break;*/
		case 'h':	flags |= F_h;	break;
		case 'r':	flags |= F_r;	break;
		case 'n':	flags |= F_n;	break;
		default:
			fprintf(stderr, "usage: ps [-][lusmahrn]\n");
			return 0;
		}
	}
	do_ps();
	return 0;
}

