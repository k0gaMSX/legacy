/* Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */
#include <stdio.h>
#include <unistd.h>
#include <alloc.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

typedef unsigned char BOOL;

#define	BUF_SIZE	1024

/* Return 1 if a filename is a directory.
 * Nonexistant files return 0.
 */
BOOL isadir(name)
	char *name;
{
	struct stat statbuf;

	if (stat(name, &statbuf) < 0)
		return 0;
	return S_ISDIR(statbuf.st_mode);
}

/* Copy one file to another, while possibly preserving its modes, times,
 * and modes.  Returns 1 if successful, or 0 on a failure with an
 * error message output.  (Failure is not indicted if the attributes cannot
 * be set.)
 */
BOOL copyfile(srcname, destname, setmodes)
	char *srcname;
	char *destname;
	BOOL setmodes;
{
	int rfd, wfd;
	int rcc, wcc;
	char *bp, *buf;
	struct stat statbuf1, statbuf2;
	struct utimbuf times;

	if (stat(srcname, &statbuf1) < 0) {
		perror(srcname);
		return 0;
	}
	if (stat(destname, &statbuf2) < 0) {
		statbuf2.st_ino = -1;
		statbuf2.st_dev = -1;
	}
	if ((statbuf1.st_dev == statbuf2.st_dev) &&
	    (statbuf1.st_ino == statbuf2.st_ino)) {
		fprintf(stderr, "Copying file \"%s\" to itself\n", srcname);
		return 0;
	}
	if ((rfd = open(srcname, 0)) < 0) {
		perror(srcname);
		return 0;
	}
	if ((wfd = creat(destname, statbuf1.st_mode)) < 0) {
		perror(destname);
		close(rfd);
		return 0;
	}
	buf = malloc(BUF_SIZE);
	while ((rcc = read(rfd, buf, BUF_SIZE)) > 0) {
		for (bp = buf; rcc > 0; bp += wcc, rcc -= wcc) {
			if ((wcc = write(wfd, bp, rcc)) < 0) {
				perror(destname);
Err:				close(rfd);
				close(wfd);
				return 0;
			}
		}
	}
	if (rcc < 0) {
		perror(srcname);
		goto Err;
	}
	close(rfd);
	if (close(wfd) < 0) {
		perror(destname);
		return 0;
	}
	if (setmodes) {
		chmod(destname, statbuf1.st_mode);
		chown(destname, statbuf1.st_uid, statbuf1.st_gid);
		times.actime = statbuf1.st_atime;
		times.modtime = statbuf1.st_mtime;
		utime(destname, &times);
	}
	return 1;
}

/* Build a path name from the specified directory name and file name.
 * If the directory name is NULL, then the original filename is returned.
 * The built path is in a static area, and is overwritten for each call.
 */
char *buildname(dirname, filename)
	char *dirname;
	char *filename;
{
	char *cp;
	static char buf[PATHLEN];

	if ((dirname == NULL) || (*dirname == '\0'))
		return filename;
	if ((cp = strrchr(filename, '/')) != NULL)
		filename = cp + 1;
	strcpy(buf, dirname);
	strcat(buf, "/");
	strcat(buf, filename);
	return buf;
}

int main(argc, argv)
	char	**argv;
{
	char *lastarg = argv[argc - 1];
	BOOL dirflag = isadir(lastarg);

	if (argc < 3) {
		fprintf(stderr, "usage: cp srcname ... dstname\n");
		return 1;
	}
	if ((argc > 3) && !dirflag) {
		fprintf(stderr, "%s: not a directory\n", lastarg);
		return 1;
	}
	while (argc-- > 2) {
		char *destname = lastarg;
		char *srcname = *++argv;

		if (isadir(srcname)) {
			fprintf(stderr,"%s is a directory\n", srcname);
		} else {
			if (dirflag)
				destname = buildname(destname, srcname);
			copyfile(srcname, destname, 1);
		}
	}
	return 0;
}

