/* Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * jun/99: Adriano Cunha <adrcunha@dcc.unicamp.br>
 *	   added /etc/mtab update
 */
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(argc, argv)
	int argc;
	char **argv;
{
	FILE *fdi, *fdo;
	int i, fnd = 0;
	char buf[256], *p, c;

	if (argc != 2) {
		fprintf(stderr, "usage: umount mountpoint\n");
		return 0;
	}
	if (umount(argv[1]) < 0) {
		perror(argv[1]);
		return 1;
	}
	if ((fdi = fopen("/etc/mtab", "r")) == NULL) {
		perror("can't open /etc/mtab");
		return 2;
	}
	if ((fdo = fopen("/etc/mtab.tmp", "w")) == NULL) {
		perror("can't backup /etc/mtab");
		return 2;
	}
	for (i = 0; !feof(fdi); i++) {
		fgets(buf, sizeof(buf)-1, fdi);
		if (NULL == (p = strchr(buf, '\t')))
			continue;
		c = *p;
		*p = 0;
		if (0 == strcmp(buf,argv[1])) {
			++fnd;
			continue;
		}
		*p = c;
		fputs(buf, fdo);
		fflush(fdo);
	}
	fclose(fdi);
	fclose(fdo);
	if (i < 1) {
		errno = EFAULT;
		perror("can't backup /etc/mtab");
Unl:		unlink("/etc/mtab.tmp");
		return 2;
	}
	if (fnd == 0) {
		perror("/etc/mtab not correctly updated");
		goto Unl;
	}
	if (unlink("/etc/mtab")) {
		perror("can't replace /etc/mtab");
		goto Unl;
	}
	if (rename("/etc/mtab.tmp", "/etc/mtab")) {
		perror("can't rename /etc/mtab.tmp to /etc/mtab");
		return 3;
	}
	return 0;
}

