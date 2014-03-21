/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>
#include <sys/stat.h>

#define isdecimal(ch)	(((ch) >= '0')	&& ((ch) <= '9'))

int main(int argc, char *argv[]) {
	char *cp;
	int ret = 0, uid;
	struct passwd *pwd;
	struct stat statbuf;

	if (--argc < 2) {
		fprintf(stderr, "usage: chown uid filename ...\n");
		return 1;
	}
	++argv;
	cp = *argv++;
	if (isdecimal(*cp)) {
		for (uid = 0; isdecimal(*cp); ++cp)
			uid = uid * 10 + (*cp - '0');
		if (*cp) {
			fprintf(stderr, "Bad uid value %s\n", cp);
			return 2;
		}
	}
	else {
		if (NULL == (pwd = getpwnam(cp))) {
			fprintf(stderr, "Unknown user name %s\n", cp);
			return;
		}
		uid = pwd->pw_uid;
	}
	for (; --argc >= 0; ++argv) {
		if ((stat(*argv, &statbuf) < 0) ||
		    (chown(*argv, uid, statbuf.st_gid) < 0)) {
			perror(*argv);
			ret = 3;
		}
	}
	return ret;
}
