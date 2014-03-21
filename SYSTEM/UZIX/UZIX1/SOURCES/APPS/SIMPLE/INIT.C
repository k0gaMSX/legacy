/* init.c
 */

/* the use of 'firsttime' var for erasing /etc/mtab isn't the best solution.
 * if init can't spawn the first tty, but can respawn it or spawn the second,
 * /etc/mtab will not be erased and initialized.
 */

/* #define NO_RTC
 * causes init to ask and set system clock when executed at first time
 */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <paths.h>
#include <signal.h>
#include <string.h>
#include <time.h>
#include <unix.h>
#include <sys/wait.h>

#define LOGIN	 _PATH_LOGIN

static firsttime = 1;

struct exec_struct {
	char *tty_name;
	char *sh_name;
	int pid;
};

#define NUM_TTYS 1

struct exec_struct tty_list[NUM_TTYS] = {
	{ _PATH_CONSOLE, LOGIN }
};

void process_inittab() {
	FILE *fdm;
	char cmd[64], *p;
	static char *_argv[2] = { 0, 0 };
	int pid;
	
        if ((fdm = fopen("/etc/inittab", "r")) != NULL) {
		while (!feof(fdm)) {
			if (fgets(cmd, sizeof(cmd)-1, fdm)==NULL) break;
			if (cmd[0] != '#') {
				if (NULL != (p = strchr(cmd, '\n'))) *p=0;
				if (cmd[0] > ' ') {
					pid = fork();
					if (pid==-1) {
						printf("init: can't execute %s\n", cmd);
						continue;
					}
					if (pid==0) {
						_argv[0] = cmd;
						execve(cmd, _argv, environ);
						printf("init: can't execute %s\n", cmd);
						exit(1);
					}
					wait(&pid);
				}
			}
		}
		fclose(fdm);
	}
}					

int determine_tty(int pid) {
	int i;

	for (i = 0; i < NUM_TTYS; i++) {
		if (pid == tty_list[i].pid)
			return i;
	}
	return -1;
}

void generate_mtab() {
	info_t info;
	fsptr fsys;
	int j;
	char mtabline[] = "/dev/fdX\t/\trw\n";
	char *s = "failed";
	FILE *fdm;
		
	printf("Updating /etc/mtab: ");
	for (j = 0; j < 8; ++j) {
		if (0 == getfsys(j, &info) && (fsys = (fsptr)info.ptr) != NULL
		   && fsys->s_mounted && fsys->s_mntpt == NULL) {
			j = MINOR(fsys->s_dev);
			unlink("/etc/mtab");
			mtabline[7] = j + '0';
			if ((fdm = fopen("/etc/mtab", "w")) != NULL) {
				if (fputs(mtabline, fdm) != EOF) s = "ok";
				fclose(fdm);
			}
			break;
		}
	}
	printf("%s\n", s);
}		

int spawn_tty(unsigned num, char **argv) {
	char *s;
	int pid, fd;

	struct exec_struct *p = &tty_list[num];

	if (num >= NUM_TTYS)
		exit(-1);
	if ((pid = fork()) != 0) {	/* error/parent */
		firsttime = 0;
		p->pid = pid;
		return pid;
	}
	/* child - must open own tty */
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);
	if ((fd = open(p->tty_name, O_RDWR)) < 0)
		exit(-2);
	dup2(fd, STDOUT_FILENO);
	dup2(fd, STDERR_FILENO);
	if (firsttime) {
		generate_mtab();		
		process_inittab();
		printf("Spawning tty #%d (%s): ok\n", num, p->tty_name);
	}
	setenv("TTY", p->tty_name, 1);
	setenv("TERM",
#ifdef MSX_UZIX_TARGET
			"vt52"
#endif
#ifdef PC_UZIX_TARGET
			"ansi"
#endif
				, 1);
	for (s = p->sh_name; s[1] != 0; ++s)
		;
	while (s > p->sh_name && s[-1] != '/')
		--s;
	argv[0] = s;
	printf("Starting login...\n\n");
	execve(p->sh_name, argv, environ);
	exit(-3);
}

#ifdef NO_RTC
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
#endif

VOID main(int argc, char *argv[]) {
	int i, pid, fd, rv;
#ifdef NO_RTC
	char buf[40], *p;
	struct tm tt;
	time_t mytimet;
#endif

	(void)argc;
	signal(SIGINT, SIG_IGN);
/*	signal(SIGKILL, SIG_IGN);	/* can't caught KILL!!! */
	signal(SIGABRT, SIG_IGN);
	setenv("PATH", _PATH_DEFPATH, 0);
	setenv("HOME", "/", 0);
#ifdef NO_RTC
	for (;;) {
		printf("Enter date/time (hh:mm[:ss] dd/mm/yyyy): ");
		fflush(stdout);
		read(0, buf, 39);
		p=strchr(buf, '\n');
		*p=0;
		p=strchr(buf, ' ');
		*p=0;
		if (!conv_time(buf, p+1, &tt)) {
			printf("Bad date/time format\n");
			continue;
		}
		mytimet = mktime(&tt);
		if (stime(&mytimet) < 0) {
			printf("Error setting clock\n");
		}
		break;
	}	
#endif
	for (i = 0; i < NUM_TTYS; i++)
		spawn_tty(i, argv);
	/* reopen init's tty */
	close(STDIN_FILENO);
	fd = open(_PATH_CONSOLE, O_RDWR);
	dup2(fd, STDOUT_FILENO);
	dup2(fd, STDERR_FILENO);
#if DEBUG > 0
	printf("INIT's PID is %d\n",getpid()); fflush(stdout);
#endif
	while (1) {
		pid = wait(&rv);
#if DEBUG > 0
		printf("process #%d returns %d,%d\n",
			pid, (unsigned char)(rv >> 8), (unsigned char)rv);
#endif
		fflush(stdout);
		if ((i = determine_tty(pid)) >= 0) {
			printf("\nRespawning tty #%d (%s): ok\n",
				i, tty_list[i].tty_name);
			fflush(stdout);
			tty_list[i].pid = 0;
			spawn_tty(i, argv);
		}
	}
}

