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

void main(argc, argv)
	int argc;
	char **argv;
{
	int ro = 0;
	char *str, buf[256];
	FILE *fd;

	argc--;
	argv++;
	while ((argc > 0) && (**argv == '-')) {
		argc--;
		str = *argv++ ;
		while (*++str) switch (*str) {
			case 'r':
				++ro;
				break;
			default:
				fprintf(stderr, "Unknown option\n");
				return;
		}
	}
	if (argc != 2) {
		fprintf(stderr, "usage: mount [-r] devname dirname\n");
		return;
	}
	if (mount(argv[0], argv[1], ro) < 0) {
		perror("mount failed");
		return;
	}
	if (NULL == (fd = fopen("/etc/mtab", "a"))) {
		perror("can't update /etc/mtab");
		return;
	}
	sprintf(buf,"%s\t%s\tr%c\n", argv[0], argv[1], ro ? 'o' : 'w');
	if (fputs(buf, fd) == EOF)
		perror("can't update /etc/mtab");
	fclose(fd);
}

