/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * The "ls" built-in command.
 */
#include "sash.h"
#ifdef CMD_LS

#include <dirent.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <sys/stat.h>

#define LISTSIZE	256

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

static char **list;
static int listsize;
static int listused;

static void lsfile __P((char *, struct stat *, int));

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
	int len;

	struct passwd *pwd;
	struct group *grp;
	char buf[PATHLEN], *cp = buf;

	*cp = '\0';
	if (flags & LSF_INODE) {
		sprintf(cp, "%5d ", statbuf->st_ino);
		cp += strlen(cp);
	}
	if (flags & LSF_LONG) {
		cp += strlen(strcpy(cp, modestring(statbuf->st_mode)));
		sprintf(cp, "%3d ", statbuf->st_nlink);
		cp += strlen(cp);
#if 0
		if (!useridknown || (statbuf->st_uid != userid)) {
			if ((pwd = getpwuid(statbuf->st_uid)) != NULL)
				strcpy(username, pwd->pw_name);
			else	sprintf(username, "%d", statbuf->st_uid);
			userid = statbuf->st_uid;
			useridknown = TRUE;
		}
		sprintf(cp, "%-8s ", username);
		cp += strlen(cp);
		if (!groupidknown || (statbuf->st_gid != groupid)) {
			if ((grp = getgrgid(statbuf->st_gid)) != NULL)
				strcpy(groupname, grp->gr_name);
			else	sprintf(groupname, "%d", statbuf->st_gid);
			groupid = statbuf->st_gid;
			groupidknown = TRUE;
		}
		sprintf(cp, "%-8s ", groupname);
		cp += strlen(cp);
#endif
		if (S_ISDEV(statbuf->st_mode))
			sprintf(cp, "%-8d ", statbuf->st_rdev);
		else	sprintf(cp, "%8ld ", sizeval(&statbuf->st_size));
		cp += strlen(cp);
		sprintf(cp, " %-12s ", timestring(&statbuf->st_mtime));
	}
	fputs(buf, stdout);
	fputs(name, stdout);
#ifdef	S_ISLNK
	if ((flags & LSF_LONG) && S_ISLNK(statbuf->st_mode)) {
		if ((len = readlink(name, buf, PATHLEN - 1)) >= 0) {
			buf[len] = '\0';
			printf(" -> %s", buf);
		}
	}
#endif
	fputc('\n', stdout);
}

void do_ls(argc, argv)
	int argc;
	char  **argv;
{
	static char *def[2] = {"-ls", "."};

	char *cp, *name, **newlist, fullname[PATHLEN];
	struct stat statbuf;
	struct dirent *dp;
	BOOL endslash;
	int i, flags;
	DIR *dirp;

	if (listsize == 0) {
		if ((list = (char **) malloc(LISTSIZE * sizeof(char *))) == NULL) {
			fprintf(stderr, "No memory for ls buffer\n");
			return;
		}
		listsize = LISTSIZE;
	}
	listused = 0;
	flags = 0;
	if ((argc > 1) && (argv[1][0] == '-')) {
		argc--;
		for (cp = *(++argv) + 1; *cp; ++cp) {
			switch (*cp) {
			case 'd': flags |= LSF_DIR;	break;
			case 'i': flags |= LSF_INODE;	break;
			case 'l': flags |= LSF_LONG;	break;
			default:
				fprintf(stderr, "Unknown option -%c\n", *cp);
				return;
			}
		}
	}
	if (argc <= 1) {
		argc = 2;
		argv = def;
	}
	if (argc > 2)
		flags |= LSF_MULT;
	while (--argc > 0) {
		name = *(++argv);
		endslash = (*name && (name[strlen(name) - 1] == '/'));
		if (LSTAT(name, &statbuf) < 0) {
			perror(name);
			continue;
		}
		if ((flags & LSF_DIR) || (!S_ISDIR(statbuf.st_mode))) {
			lsfile(name, &statbuf, flags);
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
			if (intflag)
				break;
			if (dp->d_name[0] == '\0')
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
		qsort((char *) list, listused, 
			sizeof(char *), (cmp_func_t)namesort); /**/
		/* Now finally list the filenames. */
		for (i = 0; i < listused; i++, free(name)) {
			name = list[i];
			if (LSTAT(name, &statbuf) < 0) {
				perror(name);
				continue;
			}
			if ((cp = strrchr(name, '/')) != 0)
				++cp;
			else	cp = name;
			lsfile(cp, &statbuf, flags); /**/
		}
		listused = 0;
	}
	fflush(stdout);
}
#endif	/* CMD_LS */

#ifdef CMD_LS_LIGHT
#include "sys\stat.h"
#include <fcntl.h>
#define MINOR(dev)		((uchar)(dev))
#define MAJOR(dev)		((uchar)((dev) >> 8))

int devdir(stat)
	int stat;
{
	stat &= S_IFMT;

	switch (stat) {
	case S_IFDIR:	return 'd';
	case S_IFPIPE:	return 'p';
	case S_IFBLK:	return 'b';
	case S_IFCHR:	return 'c';
	case S_IFLNK:	return 'l';
	}
	return '-';
}

char *prot(stat)
	int stat;
{
	static char _prots[8][4] = {
		"---", "--x", "-w-", "-wx",
		"r--", "r-x", "rw-", "rwx"
	};
	return _prots[stat & 7];
}

void lsfiles(d, path, wide)
	int d;
	char *path;
	int wide;
{
	int i, fd, pathsize;
	direct_t buf;
	char *dname;
	struct stat statbuf;

	pathsize = strlen(path);
	while (read(d, (char *) &buf, sizeof(direct_t)) == sizeof(direct_t)) {
		if (buf.d_name[0] == '\0')
			continue;
		dname = path;
		dname[pathsize] = '\0';
		if (strcmp(path,".") != 0) {
			strcat(dname, "/");
		} else dname = path + pathsize;
		strncat(dname, buf.d_name, DIRNAMELEN);
		fd = open(dname, O_SYMLINK);
		i = (fd >= 0) ? fstat(fd, &statbuf) :
				stat(dname, &statbuf);
		if (i) {
			perror(dname);
			if (fd >= 0)
				close(fd);
			continue;
		}
		if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
			strcat(dname, "/");
		if (wide==0) {
			if (S_ISDEV(statbuf.st_mode))
				printf("%3d,%-5d",
					MAJOR(statbuf.st_rdev),
					MINOR(statbuf.st_rdev));
			else	printf("%-9ld", statbuf.st_size);
			printf(" %c%s%s%s %2d @%-5u %s",
			       devdir(statbuf.st_mode),
			       prot(statbuf.st_mode >> 6),
			       prot(statbuf.st_mode >> 3),
			       prot(statbuf.st_mode >> 0),
			       statbuf.st_nlink,
			       statbuf.st_ino,
			       dname);
			if ((statbuf.st_mode & S_IFMT) == S_IFLNK) {
				dname[0] = 0;
				i = read(fd, dname, 128);
				dname[i] = 0;
				printf(" -> %s", dname);
				close(fd);
			}
		} else {
			printf("%s",dname);
			i = strlen(dname) + 1;
			if ((statbuf.st_mode & S_IFMT) == S_IFLNK) putchar('@');
			else if (((statbuf.st_mode & S_IFMT) != S_IFDIR) &&
			    ((statbuf.st_mode & S_IEXEC)+
			    (statbuf.st_mode & S_IGEXEC)+
			    (statbuf.st_mode & S_IOEXEC) !=0 )) putchar('*');
			else i--;
			if (i < 16) putchar('\t');
			if (i < 8) putchar('\t');
		}
		if (!wide) putchar('\n');
	}
	if (wide) putchar('\n');
}

void do_ls(argc, argv)
	int argc;
	char  **argv;
{
	int d,wide = 1;
	struct stat statbuf;
	char path[512];

	if (argc == 1) strcpy(path,".");
	if (argc == 2)
		if (strcmp(argv[1],"-l") == 0) {
			wide = 0;
			strcpy(path,".");
		} else strcpy(path,argv[1]);
	if (argc == 3) {
		if (strcmp(argv[1],"-l") != 0) {
			fprintf(stderr,"Unknown option %s\n",argv[1]);
			return;
		}
		wide = 0;
		strcpy(path,argv[2]);
	}
	if (lstat(path, &statbuf) != 0) perror(path);
	else if ((statbuf.st_mode & S_IFMT) != S_IFDIR) perror(path);
	else if ((d = open(path, 0)) < 0) perror(path);
	else {
		lsfiles(d, path, wide);
		close(d);
	}
	return;
}
#endif	/* CMD_LS_LIGHT */
