/* renice.c	 vr. 1.0
 * descripton:	 change processes priority
 * author:	 Adriano Cunha <adrcunha@dcc.unicamp.br>
 * license:	 GNU Public License version 2
 */

#include <stdio.h>
#include <syscalls.h>
#include <unix.h>
#include <string.h>
#include <pwd.h>
#include <stdlib.h>

#define	 CHG_PID	1
#define	 CHG_GRP	2
#define	 CHG_USER	3
#define	 NONE		0

int verifynice(char nice) {
	if (nice < -20 || nice > 19) {
		printf("renice: invalid priority value\n");
		exit(1);
	}
}

int main(argc, argv) 
	int argc;
	char **argv;
{
	char *pp, *nicestr;
	char oldnice, nice, useridknown, niced;
	char mode = CHG_PID;
	info_t info;
	ptptr p;
	int i, value, err = 0;
	struct passwd *pwd;
	struct s_pdata pdata;

	argc--;
	argv++;
	if (argc < 2) {
		printf("usage: renice [+]prio [[-p] pid...] [-g pgrp...] [-u user...]\n");
		exit(1);
	}
	nicestr = *argv++;
	verifynice(nice = atoi(nicestr));
	argc--;
	getfsys(GI_PTAB, &info);
	while (argc > 0) {
		argc--;
		pp = *argv++ ;
		if (!strcmp("-p", pp)) {
			mode = CHG_PID;
			continue;
		}
		if (!strcmp("-g", pp)) {
			mode = CHG_GRP;
			continue;
		}
		if (!strcmp("-u", pp)) {
			mode = CHG_USER;
			continue;
		}
		value = atoi(pp);
		if (mode == CHG_USER) {
			if ((pwd = getpwnam(pp)) != NULL) value = pwd->pw_uid;
			else {
				printf("renice: unknown user %s\n", pp);
				exit(1);
			}
		}
		niced = 0;
		for (p = (ptptr)info.ptr, i = 0; i < info.size; ++i, ++p) {
			if (p->p_status < P_READY) continue;
			if (mode == CHG_PID && p->p_pid != value) continue;
			if (mode == CHG_USER && p->p_uid != value) continue;
			if (mode == CHG_GRP) {
				pdata.u_pid = p->p_pid;
				if (getfsys(GI_PDAT, &pdata) < 0) continue;
				if (pdata.u_gid != value) continue;
			}
			oldnice = p->p_nice;
			nice = atoi(nicestr);
			if (*nicestr == '+') nice = oldnice + atoi(++nicestr);
			verifynice(nice);
			if (setprio(p->p_pid, nice) < 0) {
				printf("PID %d: %s\n", p->p_pid, strerror(errno));
				err = 1;
			}
			niced = 1;
		}
		if (!niced) {
			printf("renice: no process found with");
			if (mode == CHG_PID) printf(" pid %d\n", value);
			if (mode == CHG_GRP) printf(" group id %d\n", value);
			if (mode == CHG_USER) printf(" owner %s\n", pp);
			err = 1;
		}
	}
	return (err);
}

