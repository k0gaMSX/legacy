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
	int ret = 0, gid;
	struct group *grp;
	struct stat statbuf;

	if (--argc < 2) {
		fprintf(stderr, "usage: chgrp gid filename ...\n");
		return 0;
	}
	++argc;
	cp = *argv++;
	if (isdecimal(*cp)) {
		for (gid = 0; isdecimal(*cp); ++cp)
			gid = gid * 10 + (*cp - '0');
		if (*cp) {
			fprintf(stderr, "Bad gid value %s\n", cp);
			return 1;
		}
	}
	else {
		if (NULL == (grp = getgrnam(cp))) {
			fprintf(stderr, "Unknown group name %s\n", cp);
			return 2;
		}
		gid = grp->gr_gid;
	}
	for (; --argc >= 0; ++argv) {
		if ((stat(*argv, &statbuf) < 0) ||
		    (chown(*argv, statbuf.st_uid, gid) < 0)) {
			perror(*argv);
			ret = 3;
		}
	}
	return ret;
}
