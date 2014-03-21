/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

typedef unsigned char BOOL;

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
	int argc;
	char **argv;
{
	char *srcname, *destname;
	char *lastarg = argv[argc - 1];
	int dirflag = isadir(lastarg);

	if (argc < 3) {
		fprintf(stderr, "usage: ln [-s] srcname ... destname\n");
		return 1;
	}
	if (argv[1][0] == '-') {
		if (strcmp(argv[1], "-s")) {
			fprintf(stderr, "Unknown option %s\n", argv[1]);
			return 1;
		}
		if (argc != 4) {
			fprintf(stderr, "Wrong number of arguments for symbolic link\n");
			return 1;
		}
#ifdef	S_ISLNK
		if (symlink(argv[2], argv[3]) < 0)
			perror(argv[3]);
#else
		fprintf(stderr, "Symbolic links are not allowed\n");
#endif
		return 0;
	}
	/* Here for normal hard links */
	if ((argc > 3) && !dirflag) {
		fprintf(stderr, "%s: not a directory\n", lastarg);
		return 1;
	}
	while (argc-- > 2) {
		srcname = *(++argv);
		if (access(srcname, 0) < 0) {
			perror(srcname);
			continue;
		}
		destname = lastarg;
		if (dirflag)
			destname = buildname(destname, srcname);
		if (link(srcname, destname) < 0) {
			perror(destname);
			continue;
		}
	}
	return 0;
}

