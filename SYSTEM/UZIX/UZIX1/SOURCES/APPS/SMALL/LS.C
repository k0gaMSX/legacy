/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * The "ls" built-in command.
 *
 * with addictions of sevew@home.com (option -C), ajr@ecs.soton.ac.uk
 * (made -C default) and claudio@pos.inf.ufpr.br (-F)
 *
 * 1999 - Adapted to UZIX by Archi Skekochikhin and Adriano Cunha
 *        fixed multi-column and class bugs for single files
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <alloc.h>
#include <dirent.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <utime.h>
#include <sys/stat.h>
#include <unistd.h>

#define LISTSIZE	256

typedef unsigned char BOOL;

#ifdef	S_ISLNK
#define LSTAT	lstat
#else
#define LSTAT	stat
#endif

/*
 * Flags for the LS command.
 */
#define LSF_LONG	0x01
#define LSF_DIR 	0x02
#define LSF_INODE	0x04
#define LSF_MULT	0x08
#define LSF_FILE	0x10
#define LSF_DOWN	0x20
#define LSF_ALL 	0x40
#define LSF_OCT 	0x80
#define LSF_UNSORT	0x100
#define LSF_CLASS	0x200

/* klugde */
#define COLS 80

static char **list;
static int listsize;
static int listused;
static int flags;
static int cols = 0, col = 0;
static char fmt[10] = "%s";
static char bkpfmt[10]="%s";

void lsfile __P((char *, struct stat *, int));
char *modestring __P((int mode));
char *timestring __P((time_t *t));
int namesort __P((char **p1, char **p2));

#define sizeval(p)	(*(p))

void main(argc, argv)
	int argc;
	char **argv;
{
	static char *def[1] = {"."};

	char *cp, *name, **newlist, fullname[PATHLEN];
	int len, maxlen, num;
	struct stat statbuf;
	struct dirent *dp;
	BOOL endslash;
	DIR *dirp;
	int i;

	if ((list = (char **) malloc(LISTSIZE * sizeof(char *))) == NULL) {
		fprintf(stderr, "No memory for ls buffer\n");
		return;
	}
	listsize = LISTSIZE;
	listused = 0;
	flags = 0;
	for (--argc, ++argv; argc > 0 && argv[0][0] == '-'; --argc, ++argv) {
		for (cp = *argv + 1; *cp; ++cp) {
			switch (*cp) {
			case 'h':
				printf("usage: ls [-dilfaouRF] [pattern]\n");
				return;
			case 'd': flags |= LSF_DIR;	break;
			case 'i': flags |= LSF_INODE;	break;
			case 'l': flags |= LSF_LONG;	break;
			case 'f': flags |= LSF_FILE;	break;
			case 'a': flags |= LSF_ALL;	break;
			case 'o': flags |= LSF_OCT;	break;
			case 'u': flags |= LSF_UNSORT;	break;
			case 'R': flags |= LSF_DOWN;	break;
			case 'F': flags |= LSF_CLASS;	break;
			default:
				fprintf(stderr, "Unknown option -%c\n", *cp);
				return;
			}
		}
	}
	if (argc == 0) {
		argc = 1;
		argv = def;
	}
	if (argc > 1)
		flags |= LSF_MULT;
	while (--argc >= 0) {
		name = *argv++;
		endslash = (*name && (name[strlen(name) - 1] == '/'));
		if (LSTAT(name, &statbuf) < 0) {
			perror(name);
			continue;
		}
		if ((flags & LSF_DIR) || (!S_ISDIR(statbuf.st_mode))) {
			strcpy(bkpfmt, fmt);
			maxlen = DIRNAMELEN;
			cp = strchr(name, '/');
			if (cp != NULL) maxlen += (unsigned int)cp-(unsigned int)name+1;
			maxlen += 2;
			cols = (COLS - 1) / maxlen;
			sprintf (fmt, "%%-%d.%ds", maxlen, maxlen);
			lsfile(name, &statbuf, flags);
			strcpy(fmt, bkpfmt);
			continue;
		}
		/* Do all the files in a directory. */
		if ((dirp = opendir(name)) == NULL) {
			perror(name);
			continue;
		}
		if (flags & LSF_MULT)
			printf("\n%s:\n", name);
		while ((dp = readdir(dirp)) != NULL) {
			if (dp->d_name[0] == '\0')
				continue;
			if (!(flags & LSF_ALL) && dp->d_name[0] == '.')
				continue;
			fullname[0] = '\0';
			if ((*name != '.') || (name[1] != '\0')) {
				strcpy(fullname, name);
				if (!endslash)
					strcat(fullname, "/");
			}
			strcat(fullname, dp->d_name);
			if (listused >= listsize) {
				newlist = realloc(list,
				     ((sizeof(char **)) * (listsize + LISTSIZE)));
				if (newlist == NULL) {
					fprintf(stderr, "No memory for ls buffer\n");
					break;
				}
				list = newlist;
				listsize += LISTSIZE;
			}
			if ((list[listused] = strdup(fullname)) == NULL) {
				fprintf(stderr, "No memory for filenames\n");
				break;
			}
			listused++;
		}
		closedir(dirp);
		/* Sort the files. */
		if (!(flags & LSF_UNSORT))
			qsort((char *) list, listused,
				sizeof(char *), (cmp_func_t)namesort); /**/
		/* Get list entry size for multi-column output. */
		if (~flags & LSF_LONG) {
			for (maxlen = i = 0; i < listused; i++) {
				if (NULL != (cp = strrchr(list[i], '/')))
					cp++;
				else 	cp = list[i];
				if ((len = strlen (cp)) > maxlen)
					maxlen = len;
			}
			maxlen += 2;
			cols = (COLS - 1) / maxlen;
			sprintf (fmt, "%%-%d.%ds", maxlen, maxlen);
		}
		/* Now finally list the filenames. */
		for (num = i = 0; i < listused; i++, free(name)) {
			name = list[i];
			if (LSTAT(name, &statbuf) < 0) {
				perror(name);
				continue;
			}
			if (((flags & LSF_DIR) && !S_ISDIR(statbuf.st_mode)) ||
			    ((flags & LSF_FILE) && S_ISDIR(statbuf.st_mode)))
				continue;
			if ((cp = strrchr(name, '/')) != 0)
				++cp;
			else	cp = name;
			if (flags & LSF_ALL || *cp != '.') {
				lsfile(cp, &statbuf, flags);
				num++;
			}
		}
		if ((~flags & LSF_LONG) && /*(num % cols))*/ (col != 0)) {
			col = 0;
			fputc('\n', stdout);
		}
		listused = 0;
	}
	if ((~flags & LSF_LONG) && /*(num % cols))*/ (col != 0))
		fputc('\n', stdout);
	fflush(stdout);
}

/*
 * Sort routine for list of filenames.
 */
int namesort(p1, p2)
	char **p1;
	char **p2;
{
	return strcmp(*p1, *p2);
}

/*
 * Return the standard ls-like mode string from a file mode.
 * This is static and so is overwritten on each call.
 */
static char *modestring(mode)
	int mode;
{
	static char buf[12];

	if (flags & LSF_OCT) {
		sprintf(buf, "%06o", mode);
		return buf;
	}
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

/*
 * Do an LS of a particular file name according to the flags.
 */
static void lsfile(name, statbuf, flags)
	char *name;
	struct stat *statbuf;
	int flags;
{
	static char username[12];
	static int userid;
	static BOOL useridknown;
	static char groupname[12];
	static int groupid;
	static BOOL groupidknown;
	char class;

	struct passwd *pwd;
	struct group *grp;
	char buf[PATHLEN], *cp = buf;
	int len;

	*cp = '\0';
	if (flags & LSF_INODE) {
		sprintf(cp, "%5d ", statbuf->st_ino);
		cp += strlen(cp);
	}
	if (flags & LSF_LONG) {
		cp += strlen(strcpy(cp, modestring(statbuf->st_mode)));
		sprintf(cp, "%3d ", statbuf->st_nlink);
		cp += strlen(cp);
		if (!useridknown || (statbuf->st_uid != userid)) {
			if ((pwd = getpwuid(statbuf->st_uid)) != NULL)
				strcpy(username, pwd->pw_name);
			else	sprintf(username, "%d", statbuf->st_uid);
			userid = statbuf->st_uid;
			useridknown = 1;
		}
		sprintf(cp, "%-8s ", username);
		cp += strlen(cp);
		if (!groupidknown || (statbuf->st_gid != groupid)) {
			if ((grp = getgrgid(statbuf->st_gid)) != NULL)
				strcpy(groupname, grp->gr_name);
			else	sprintf(groupname, "%d", statbuf->st_gid);
			groupid = statbuf->st_gid;
			groupidknown = 1;
		}
		sprintf(cp, "%-8s ", groupname);
		cp += strlen(cp);
		if (S_ISDEV(statbuf->st_mode))
			sprintf(cp, "%3d,%-3d  ",
				statbuf->st_rdev >> 8, statbuf->st_rdev & 0xFF);
		else	sprintf(cp, "%8ld ", sizeval(&statbuf->st_size));
		cp += strlen(cp);
		sprintf(cp, " %-12s ", timestring(&statbuf->st_mtime));
	}
	fputs(buf, stdout);
	if (flags & LSF_CLASS) {
		if (S_ISLNK (statbuf->st_mode)) class = '@';
		else if (S_ISDIR (statbuf->st_mode)) class = '/';
		else if (S_IEXEC & statbuf->st_mode) class = '*';
#ifdef S_ISFIFO
		else if (S_ISFIFO (statbuf->st_mode)) class = '|';
#endif
#ifdef S_ISSOCK
		else if (S_ISSOCK (statbuf->st_mode)) class = '=';
#endif
	}
	printf(fmt, name);
	if (flags & LSF_CLASS) fputc(class, stdout);
#ifdef	S_ISLNK
	if ((flags & LSF_LONG) && S_ISLNK(statbuf->st_mode)) {
		if ((len = readlink(name, buf, PATHLEN - 1)) >= 0) {
			buf[len] = '\0';
			printf(" -> %s", buf);
		}
	}
#endif
	if (flags & LSF_LONG || ++col == cols) {
		fputc('\n', stdout);
		col = 0;
	}
}

