/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Utility routines.
 */
#include "sash.h"

#include <dirent.h>
#include <time.h>
#include <utime.h>
#include <sys/stat.h>

#define BUF_SIZE 1024

#define CHUNKINITSIZE	4

typedef struct chunk CHUNK;
struct chunk {
	CHUNK *next;
	char data[CHUNKINITSIZE];	/* actually of varying length */
};

static CHUNK *chunklist;

/* Allocate a chunk of memory (like malloc).
 * The difference, though, is that the memory allocated is put on a
 * list of chunks which can be freed all at one time.  You CAN NOT free
 * an individual chunk.
 */
char *getchunk(size)
	int size;
{
	CHUNK *chunk;

	if (size < CHUNKINITSIZE)
		size = CHUNKINITSIZE;
	size += sizeof(CHUNK) - CHUNKINITSIZE;
	if ((chunk = (CHUNK *)malloc(size)) == NULL)
		return NULL;
	chunk->next = chunklist;
	chunklist = chunk;
	return chunk->data;
}

/* Free all chunks of memory that had been allocated since the last
 * call to this routine.
 */
void freechunks() {
	while (chunklist) {
		CHUNK *chunk = chunklist;

		chunklist = chunk->next;
		free((char *) chunk);
	}
}

#ifdef FUNC_MODESTRING
/*
 * Return the standard ls-like mode string from a file mode.
 * This is static and so is overwritten on each call.
 */
char *modestring(mode)
	int mode;
{
	static char buf[12];
	strcpy(buf, "----------");

	/* Fill in the file type. */
	if (S_ISDIR(mode))		buf[0] = 'd';
	if (S_ISCHR(mode))		buf[0] = 'c';
	if (S_ISBLK(mode))		buf[0] = 'b';
#ifdef	S_ISLNK
	if (S_ISLNK(mode))		buf[0] = 'l';
#endif
	/* Now fill in the normal file permissions. */
	if (mode & S_IRUSR)		buf[1] = 'r';
	if (mode & S_IWUSR)		buf[2] = 'w';
	if (mode & S_IXUSR)		buf[3] = 'x';

	if (mode & S_IRGRP)		buf[4] = 'r';
	if (mode & S_IWGRP)		buf[5] = 'w';
	if (mode & S_IXGRP)		buf[6] = 'x';

	if (mode & S_IROTH)		buf[7] = 'r';
	if (mode & S_IWOTH)		buf[8] = 'w';
	if (mode & S_IXOTH)		buf[9] = 'x';

	/* Finally fill in magic stuff like suid and sticky text. */
	if (mode & S_ISUID)	buf[3] = ((mode & S_IXUSR) ? 's' : 'S');
	if (mode & S_ISGID)	buf[6] = ((mode & S_IXGRP) ? 's' : 'S');
	if (mode & S_ISVTX)	buf[9] = ((mode & S_IXOTH) ? 't' : 'T');
	return buf;
}
#endif	/* FUNC_MODESTRING */

#ifdef FUNC_TIMESTRING
/*
 * Get the time to be used for a file.
 * This is down to the minute for new files, but only the date for old files.
 * The string is returned from a static buffer, and so is overwritten for
 * each call.
 */
char *timestring(t)
	time_t *t;
{
	time_t now;
	struct tm *ttime,*tnow;
	int ty, tyd;
	char  *str;
	static char buf[26];

	time(&now);
	tnow = localtime(&now);
	ty = tnow->tm_year;
	tyd = tnow->tm_yday;
	ttime = localtime(t);
	str = ctime(t);
	strcpy(buf, &str[4]);
	buf[12] = '\0';
	if ((ttime->tm_year != ty) || (ttime->tm_yday > tyd)) {
/*	if ((t > now) || (t < now - 365 * 24 * 60 * 60L)) {*/
		strcpy(&buf[7], &str[20]);
		buf[11] = '\0';
	}
	return buf;
}
#endif	/* FUNC_TIMESTRING */

#ifdef FUNC_ISADIR
/*
 * Return TRUE if a filename is a directory.
 * Nonexistant files return FALSE.
 */
BOOL isadir(name)
	char *name;
{
	struct stat statbuf;

	if (stat(name, &statbuf) < 0)
		return FALSE;
	return S_ISDIR(statbuf.st_mode);
}
#endif	/* FUNC_ISADIR */

#ifdef FUNC_COPYFILE
/*
 * Copy one file to another, while possibly preserving its modes, times,
 * and modes.  Returns TRUE if successful, or FALSE on a failure with an
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
		return FALSE;
	}
	if (stat(destname, &statbuf2) < 0) {
		statbuf2.st_ino = -1;
		statbuf2.st_dev = -1;
	}
	if ((statbuf1.st_dev == statbuf2.st_dev) &&
	    (statbuf1.st_ino == statbuf2.st_ino)) {
		fprintf(stderr, "Copying file \"%s\" to itself\n", srcname);
		return FALSE;
	}
	if ((rfd = open(srcname, 0)) < 0) {
		perror(srcname);
		return FALSE;
	}
	if ((wfd = creat(destname, statbuf1.st_mode)) < 0) {
		perror(destname);
		close(rfd);
		return FALSE;
	}
	buf = malloc(BUF_SIZE);
	while ((rcc = read(rfd, buf, BUF_SIZE)) > 0) {
		if (intflag) {
Err:			close(rfd);
			close(wfd);
			return FALSE;
		}
		for (bp = buf; rcc > 0; bp += wcc, rcc -= wcc) {
			if ((wcc = write(wfd, bp, rcc)) < 0) {
				perror(destname);
				goto Err;
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
		return FALSE;
	}
	if (setmodes) {
		chmod(destname, statbuf1.st_mode);
		chown(destname, statbuf1.st_uid, statbuf1.st_gid);
		times.actime = statbuf1.st_atime;
		times.modtime = statbuf1.st_mtime;
		utime(destname, &times);
	}
	return TRUE;
}
#endif	/* FUNC_COPYFILE */

#ifdef FUNC_BUILDNAME
/*
 * Build a path name from the specified directory name and file name.
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
#endif	/* FUNC_BUILDNAME */

/* Sort routine for list of filenames */
int namesort(p1, p2)
	char **p1;
	char **p2;
{
	return strcmp(*p1, *p2);
}

/* Routine to see if a text string is matched by a wildcard pattern.
 * Returns TRUE if the text is matched, or FALSE if it is not matched
 * or if the pattern is invalid.
 *  *		matches zero or more characters
 *  ?		matches a single character
 *  [abc]	matches 'a', 'b' or 'c'
 *  \c		quotes character c
 *  Adapted from code written by Ingo Wilken.
 */
BOOL match(text, pattern)
	char *text, *pattern;
{
	int ch;
	BOOL found;
	char *retrypat = NULL;
	char *retrytxt = NULL;

	while (*text || *pattern) {
		switch (ch = *pattern++) {
		case '*':
			retrypat = pattern;
			retrytxt = text;
			break;

		case '[':
			found = FALSE;
			while ((ch = *pattern++) != ']') {
				if (ch == '\\')
					ch = *pattern++;
				if (ch == '\0')
					return FALSE;
				if (*text == ch)
					found = TRUE;
			}
			if (!found) {
				pattern = retrypat;
				text = ++retrytxt;
			}
			/* fall into next case */
		case '?':
			if (*text++ == '\0')
				return FALSE;
			break;

		case '\\':
			if ((ch = *pattern++) == '\0')
				return FALSE;
			/* fall into next case */
		default:
			if (*text == ch) {
				if (*text)
					text++;
				break;
			}
			if (*text) {
				pattern = retrypat;
				text = ++retrytxt;
				break;
			}
			return FALSE;
		}
		if (pattern == NULL)
			return FALSE;
	}
	return TRUE;
}

/* Expand the wildcards in a filename, if any.
 * Returns an argument list with matching filenames in sorted order.
 * The expanded names are stored in memory chunks which can later all
 * be freed at once.  Returns zero if the name is not a wildcard, or
 * returns the count of matched files if the name is a wildcard and
 * there was at least one match, or returns -1 if either no filenames
 * matched or too many filenames matched (with an error output).
 */
int expandwildcards(name, maxargc, retargv)
	char *name;
	int maxargc;
	char *retargv[];
{
	DIR *dirp;
	struct dirent *dp;
	int dirlen, matches;
	char *patt, *cp1, *cp2, *cp3, dirname[PATHLEN];

	if ((patt = strrchr(name, '/')) != NULL)
		patt++;
	else	patt = name;
	cp1 = strchr(name, '*');
	cp2 = strchr(name, '?');
	cp3 = strchr(name, '[');
	if ((cp1 == NULL) && (cp2 == NULL) && (cp3 == NULL))
		return 0;
	if ((cp1 && (cp1 < patt)) ||
	    (cp2 && (cp2 < patt)) ||
	    (cp3 && (cp3 < patt))) {
		fprintf(stderr, "Wildcards only implemented for last filename component\n");
		return -1;
	}
	dirname[0] = '.';
	dirname[1] = '\0';
	if (patt != name) {
		memcpy(dirname, name, patt - name);
		dirname[patt - name - 1] = '\0';
		if (dirname[0] == '\0') {
			dirname[0] = '/';
			dirname[1] = '\0';
		}
	}
	if ((dirp = opendir(dirname)) == NULL) {
		perror(dirname);
		return -1;
	}
	dirlen = strlen(dirname);
	if (patt == name) {
		dirlen = 0;
		dirname[0] = '\0';
	}
	else if (dirname[dirlen - 1] != '/') {
		dirname[dirlen++] = '/';
		dirname[dirlen] = '\0';
	}
	matches = 0;
	while ((dp = readdir(dirp)) != NULL) {
		if (dp->d_name[0] == 0 ||
		    !strcmp(dp->d_name, ".") ||
		    !strcmp(dp->d_name, "..") ||
		    !match(dp->d_name, patt))
			continue;
		if (matches >= maxargc) {
			cp1 = "Too many filename matches\n";
Err:			fprintf(stderr, cp1);
			closedir(dirp);
			return -1;
		}
		if ((cp1 = getchunk(dirlen + strlen(dp->d_name) + 1)) == NULL) {
			cp1 = "No memory for filename\n";
			goto Err;
		}
		if (dirlen)
			memcpy(cp1, dirname, dirlen);
		strcpy(cp1 + dirlen, dp->d_name);
		retargv[matches++] = cp1;
	}
	closedir(dirp);
	if (matches == 0) {
		fprintf(stderr, "No matches\n");
		return -1;
	}
	qsort((char *) retargv, matches, sizeof(char *), (cmp_func_t)namesort);
	return matches;
}

/* Take a command string, and break it up into an argc, argv list.
 * The returned argument list and strings are in static memory, and so
 * are overwritten on each call.  The argument array is ended with an
 * extra NULL pointer for convenience.	Returns TRUE if successful,
 * or FALSE on an error with a message already output.
 */
BOOL makeargs(cmd, argcptr, argvptr)
	char *cmd;
	int *argcptr;
	char ***argvptr;
{
	char *cp;
	int argc;
	static char strings[CMDLEN + 1];
	static char *argtable[MAXARGS + 1];

	/* Copy the command string and then break it apart
	 * into separate arguments.
	 */
	memset(strings, 0, CMDLEN);
	for (argc = 0, cp = strcpy(strings, cmd); *cp; ) {
		if (argc >= MAXARGS) {
			fprintf(stderr, "Too many arguments\n");
			return FALSE;
		}
		argtable[argc++] = cp;
		while (*cp && !isblank(*cp))
			cp++;
		while (isblank(*cp))
			*cp++ = '\0';
	}
	argtable[argc] = NULL;
	*argcptr = argc;
	*argvptr = argtable;
	return TRUE;
}

/* Make a NULL-terminated string out of an argc, argv pair.
 * Returns TRUE if successful, or FALSE if the string is too long,
 * with an error message given.  This does not handle spaces within
 * arguments correctly.
 */
BOOL makestring(argc, argv, buf, buflen)
	int argc;
	char **argv, *buf;
	int buflen;
{
	while (argc-- > 0) {
		int len = strlen(*argv);

		if (len >= buflen) {
			fprintf(stderr, "Argument string too long\n");
			return FALSE;
		}
		strcpy(buf, *argv++);
		buf += len;
		buflen -= len;
		if (argc)
			*buf++ = ' ';
		buflen--;
	}
	*buf = '\0';
	return TRUE;
}

/* Calculate long size from off_t */
long sizeval(p)
	off_t *p;
{
	return *p;
}
