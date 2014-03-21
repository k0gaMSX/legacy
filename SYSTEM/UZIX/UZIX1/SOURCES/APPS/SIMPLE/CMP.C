/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <string.h>

int main(argc, argv)
	int argc;
	char **argv;
{
	int fd1, fd2;
	int cc1, cc2, sts = 0;
	long pos;
	char *srcname, *destname, *lastarg;
	char *bp1, *bp2, buf1[512], buf2[512];
	struct stat statbuf1, statbuf2;
	
	if (argc < 3) {
		/*fprintf(stderr, "usage: cmp [-cls] file1 [file2]\n");*/
		fprintf(stderr, "usage: cmp file1 file2\n");
		return 0;
	}
	if (stat(argv[1], &statbuf1) < 0) {
		perror(argv[1]);
		return 9;
	}
	if (stat(argv[2], &statbuf2) < 0) {
		perror(argv[2]);
		return 9;
	}
	if ((statbuf1.st_dev == statbuf2.st_dev) &&
	    (statbuf1.st_ino == statbuf2.st_ino))
	{
		printf("Files are links to each other\n");
		return 9;
	}
	if (statbuf1.st_size != statbuf2.st_size) {
		printf("Files are different sizes\n");
		return 9;
	}
	if ((fd1 = open(argv[1], 0)) < 0) {
		perror(argv[1]);
		return 9;
	}
	if (argc == 2)
		fd2 = 1;
	else if ((fd2 = open(argv[2], 0)) < 0) {
		perror(argv[2]);
		close(fd1);
		return 9;
	}
	for (pos = 0; ; ) {
		if ((cc1 = read(fd1, buf1, sizeof(buf1))) < 0) {
			perror(argv[1]);
			goto Eof;
		}
		if ((cc2 = read(fd2, buf2, sizeof(buf2))) < 0) {
			perror(argv[2]);
			goto Eof;
		}
		if ((cc1 == 0) && (cc2 == 0)) {
			printf("Files are identical\n");
			goto Eof;
		}
		if (cc1 < cc2) {
			sts = 2;
			printf("First file is shorter than second\n");
			goto Eof;
		}
		if (cc1 > cc2) {
			sts = 2;
			printf("Second file is shorter than first\n");
			goto Eof;
		}
		if (memcmp(buf1, buf2, cc1) == 0) {
			pos += cc1;
			continue;
		}
		for (bp1 = buf1, bp2 = buf2; *bp1++ == *bp2++; ++pos)
			;
		printf("Files differ at byte position %ld\n", pos);
		sts = 1;
		goto Eof;
	}
Eof:	close(fd1);
	close(fd2);
	return sts;
}

