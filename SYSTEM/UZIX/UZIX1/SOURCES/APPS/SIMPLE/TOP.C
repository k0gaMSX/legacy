/* top.c	 vr. 1.1
 * descripton:	 show processes status interactively
 * author:	 Adriano Cunha <adrcunha@dcc.unicamp.br>
 * 		 heavily based on UZIX ps.c
 * license:	 GNU Public License version 2
 */

#include <stdio.h>
#include <syscalls.h>
#include <unix.h>
#include <time.h>
#include <string.h>
#include <pwd.h>
#include <signal.h>
#include <paths.h>
#include <stdlib.h>

#define MAXDISP		18		/* maximum number of processes displayed */

int nprocs = 0, nrun = 0, nslep = 0, nzomb = 0, nstop = 0;
int noprocstat = 0, nomemstat = 0, delay = 5, runonly = 0, securemode = 0;

char *mapstat(pstate_t s) {
	switch (s) {
		case P_ZOMBIE:	nzomb++;	return "Zombie";
		case P_FORKING:			return "Forking";
		case P_RUNNING:	nrun++;		return "Running";
		case P_READY:			return "Ready";
		case P_SLEEP:	nslep++;	return "Sleep";
		case P_PAUSE:			return "Pause";
		case P_WAIT:	nstop++;	return "Waitfor";
	}
	return "Undef";
}

void cls() {
	putchar('\014');
}

void home() {
	putchar('\013');
}

void clreol() {
	printf("%78s\r"," ");
}

void setcursor() {
	home();
	putchar('\n');
	if (!noprocstat) putchar('\n');
	if (!nomemstat) putchar('\n');
}		

int input(int deflt) {
	char buf[10];

	fflush(stdout);
	fflush(stdin);	
	scanf("%s", buf);
	if (*buf=='\0') return deflt;
	return atoi(buf);
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
		t1=t1-mm*60;
	}
	tt.t_time=(((int)h << 8) << 3) | ((int)mm << 5) | ((int)t1 >> 1);
	tt.t_date=(((int)y << 8) << 1) | ((int)m << 5) | d; 
	return tt;
}

int main(argc, argv) 
	int argc;
	char **argv; {
	char *pp;

	argc--;
	argv++;
	while ((argc > 0) && (**argv == '-')) {
		argc--;
		pp = *argv++ ;
		while (*++pp) switch (*pp) {
			case 'd':
				argc--;
				pp = *argv++ ;
				for (delay = 0; *pp >= '0' && *pp <= '9'; ++pp) {
					delay *= 10;
					delay += *pp - '0';
				}
				if (*pp) {
					printf("Bad delay value\n");
					return 1;
				}
				pp--;	/* *p=0, exit while/switch loop */
				break;
			case 'q':
				delay = 0;
				break;
			case 's':
				securemode = 1;
				break;
			case 'i':
				runonly = 1;
				break;
			default:
				printf("Unknown option\n");
				return 1;
		}
	}
	if (argc != 0) {
		printf("usage: top [-d delay][-q][-s][-i]\n");
		return 1;
	}
	return do_top();
}

void help() {
	char c;

	cls();
	printf("available interactive commands:\n\n");
	printf("space - Update display\n");
	printf("^L    - Clear screen\n");
	printf("i     - Toggle idle processes mode\n");
	printf("m     - Toggle memory usage mode\n");
	printf("t     - Toggle processes summary mode\n");
	if (!securemode) printf("k     - Kill a process\n");
	if (!securemode) printf("r     - Renice a task\n");
	if (!securemode) printf("u     - Show only processes of a specific user\n");
	if (!securemode) printf("s     - Change delay between snapshots\n");
	printf("h,?   - Show this help\n");
	printf("q     - Quit program\n");
	printf("n,#   - Change maximum number of processes shown\n\n");
	printf("Press RETURN to go back...");
	fflush(stdout);
	fflush(stdin);
	c=getchar();
}

void killp() {
	signal_t psignal;
	int kpid;
	
	if (securemode) return;
	printf("PID of process to kill: ");
	kpid=input(0);
	if (kpid < 1) return;
	setcursor();
	clreol();
	printf("Signal to send (15): ");
	(signal_t)psignal=input(15);
	if (psignal < 1 || psignal > NSIGS) psignal = SIGINT;
	kill(kpid, psignal);
}

void renice() {
	int kpid;
	char nicev;
	
	if (securemode) return;
	printf("PID to renice: ");
	kpid=input(0);
	if (kpid < 1) return;
	setcursor();
	clreol();
	printf("Renice PID %d to value (10): ", kpid);
	nicev=(char)input(10);
	setprio(kpid, nicev);
}
	
int do_top() {
	info_t info;
	ptptr p;
	int i, j, delay = 5, pnprocs = 0, securemode = 0;
	int totalram, usedram, kram, maxdisp = MAXDISP, procsdisp = -1;
	int runonly = 0;
	int useronly = 0;
	int kuid = -1;
	uchar nicev;
	unsigned long secs;
	struct s_pdata pdata;
	struct s_kdata kdata;
	char *str, c;
	char cputime[9];
	uchar pmem, pcpu;
	char username[9], pssize[5];
	int useridknown = 0, userid;
	struct passwd *pwd;
	time_t temptime, now;
	unsigned long ptimes, diff;
	signal_t psignal;
#define psize	32

	getfsys(GI_KDAT, &kdata);
	totalram=kdata.k_tmem;
	kram=kdata.k_kmem;
	cputime[8]='\0';
	c='\0';
	for (;;) {
again:		home();
		if (procsdisp != pnprocs) cls();
		pnprocs = procsdisp;
		getfsys(GI_PTAB, &info);
		time(&now);
		str = ctime(&now);
		printf("%s %s.%s (%s) - %s", kdata.k_name, kdata.k_version, 
			kdata.k_release, kdata.k_machine, str);
		if (!noprocstat) 
			printf("%d processes: %d running, %d sleeping, %d zombie, %d stopped.\n",
				nprocs, nrun, nslep, nzomb, nstop);
		usedram = nprocs*32;
		if (!nomemstat) 
			printf("Mem: %dk average, %dk used, %dk free, %dk kernel.\n",
				totalram, usedram, totalram-usedram, kram);
		clreol();
		if (c != '\0') {
			ioctl(fileno(stdin), TTY_COOKED);
			if (c==' ') {
				c='\0';
				continue;
			}
			if (c=='\014') {
				cls();
				c='\0';
				goto again;
			}
			if (c=='q' || c=='Q') {
				cls();
				return 0;
			}
			if (c=='t' || c=='T') {
				noprocstat = 1 - noprocstat;
				pnprocs = -1;	/* redraw screen */
				c='\0';
				goto again;
			}
			if (c=='i' || c=='I') {
				runonly = 1 - runonly;
				pnprocs = -1;	/* redraw screen */
				c='\0';
				goto again;
			}
			if (c=='m' || c=='M') {
				nomemstat = 1 - nomemstat;
				pnprocs = -1;	/* redraw screen */
				c='\0';
				goto again;
			}
			if (c=='k' || c=='K') {
				c='\0';
				killp();
				continue;
			}
			if (c=='r' || c=='R') {
				c='\0';
				renice();
				continue;
			}
			if (c=='u' || c=='U') {
				c='\0';
				if (securemode) continue;
				printf("Which user (UID, -1 for all): ");
				kuid = input(-1);
				useronly = (kuid >= 0);
				continue;
			}				
			if (c=='s' || c=='S') {
				c='\0';
				if (securemode) continue;
				delay = -1;
				while (delay < 0) {
					setcursor();
					printf("New delay (in seconds): ");
					delay=input(0);
				}
				goto again;
			}
			if (c=='n' || c=='N' || c=='#') {
				c='\0';
				printf("Maximum display of processes: ");
				maxdisp=input(MAXDISP);
				if (maxdisp < 0) maxdisp=1;
				if (maxdisp > MAXDISP) maxdisp=MAXDISP;
				pnprocs=-1;
				goto again;
			}
			if (c=='h' || c=='H' || c=='?') {
				help();
				pnprocs = -1;
				c='\0';
				goto again;
			}
			printf("Unknown command `%c' -- hit `h' for help.\a\n", c);
		} else putchar('\n');
		printf("PID   PPID  PRIO NICE USER     STAT\tSIZE \%%CPU \%%MEM TIME     COMMAND\n");
		nprocs = 0;
		nrun = 0;
		nslep = 0;
		nzomb = 0;
		nstop = 0;
		procsdisp = 0;
		for (p = (ptptr)info.ptr, i = 0; i < info.size; ++i, ++p) {
			if (p->p_status == 0)
				continue;
			nprocs++;
			pdata.u_pid=p->p_pid;
			if (runonly && p->p_status != P_RUNNING &&
				p->p_status != P_READY) continue;
			if (useronly && p->p_uid != kuid) continue;
			if (p->p_status != P_ZOMBIE) {
				if (getfsys(GI_PDAT, &pdata) < 0) 
					continue;
				psignal = pdata.u_cursig;
				/* process CPU time */
				ptimes = ticks2seconds(&pdata.u_utime);
				temptime = seconds2uzixtime(ptimes);
				str = ctime(&temptime);
				strncpy(cputime, &str[11],8);
				/* %CPU */
				diff = difftime(&now, &pdata.u_time);
				pcpu = (uchar)(((unsigned long)(ptimes*(unsigned long)100))/((unsigned long)diff));
			} else {
				psignal = 0;
				strcpy(cputime, "--:--:--");
				pcpu = 0;
				strcpy(pdata.u_name, "?");
			}
			if (procsdisp >= maxdisp) continue;
			procsdisp++;
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
			pmem=(psize*100)/totalram;
			/* convert pmem to a string terminated by k or M */
			j=psize;	/* process size in kbytes */
			if (j<1000) {	/* I know that 1Mb=1024kb, but who cares? */
			 sprintf(pssize, "%3dk", j);
			} else {
			 j = j / 1024;	/* too dirty... do it better! */
			 sprintf(pssize, "%3dM", j);
			}
			/* show info */
			printf("%-5d %-5d %-4d %-4d %-8s %s\t%-4s %3d%c %3d%c %s %s\n",
				p->p_pid, p->p_pptr->p_pid, p->p_cprio, p->p_nice,
				username, mapstat(p->p_status),	pssize, pcpu, 
				'%', pmem, '%', cputime, pdata.u_name);
		}
		setcursor();
		c = '\0';
		ioctl(fileno(stdin), TTY_RAW_UNBUFF);
		if (delay > 0) {
			time(&temptime); 
			secs = convtime(&temptime);
			while (convtime(&temptime) - secs < delay) {
				time(&temptime);
				if (read(fileno(stdin), &c, 1) != 0) break;
			}
		}
		else read(fileno(stdin), &c, 1);
	}
}

