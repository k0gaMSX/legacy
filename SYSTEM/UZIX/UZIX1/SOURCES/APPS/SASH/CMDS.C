/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Most simple built-in commands are here.
 */
#include "sash.h"

#include <fcntl.h>
#include <signal.h>
#include <pwd.h>
#include <grp.h>
#include <utime.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <paths.h>
#pragma warn -par

#ifdef CMD_SLEEP
void do_sleep(argc, argv)
	int argc;
	char *argv[];
{
	int sec = 1;

	if (argc > 1)
		sec = atoi(argv[1]);
	sleep(sec);
}
#endif	/* CMD_SLEEP */

#ifdef CMD_ECHO_LIGHT
void do_echo(argc, argv)
	int argc;
	char *argv[];
{
	BOOL first = TRUE;
	BOOL nonl = FALSE;

	if (argc > 1 && strcmp(argv[0],"-n") == 0) {
		--argc;
		++argv;
		++nonl;
	}
	while (--argc > 0) {
		if (!first)
			fputc(' ', stdout);
		first = FALSE;
		fputs(*++argv, stdout);
	}
	if (!nonl)
		putchar('\n');
	fflush(stdout);
}
#endif	/* CMD_ECHO_LIGHT */

#ifdef CMD_ECHO
static BOOL __doesc(p, _nonl)
	char *p;
	BOOL _nonl;
{
	int i, n;
	BOOL nonl = _nonl;
	char ch;

	while ((ch = *p++) != 0) {
		if (ch == '\\') {
			switch (*p++) {
			case 'c':	nonl = 1;	continue;
			case 'a':	ch = 7; 	break;
			case 'b':	ch = '\b';	break;
			case 'f':	ch = '\f';	break;
			case 'n':	ch = '\n';	break;
			case 'r':	ch = '\r';	break;
			case 't':	ch = '\t';	break;
			case 'v':	ch = '\v';	break;
			case '\\':	ch = '\\';	break;
			case 'x':
				n = 0;
				for (i = 2; --i >= 0; ++p) {
					ch = *p - '0';
					if (ch > 'a'-'0')
						ch = *p - 'a' + 10;
					else if (ch > 'A'-'0')
						ch = *p - 'A' + 10;
					if (ch < 0 || ch > 15)
						break;
					n <<= 4;
					n += ch;
				}
				ch = n;
				break;
			case '0': case '1': case '2': case '3':
			case '4': case '5': case '6': case '7':
				n = 0;
				for (i = 3, --p; --i >= 0; ++p) {
					ch = *p - '0';
					if (ch < 0 || ch > 7)
						break;
					n <<= 3;
					n += ch;
				}
				ch = n;
				break;
			default:	ch = *p;	break;
			}
		}
		fputc(ch, stdout);
	}
	return (nonl);
}

void do_echo(argc, argv)
	int argc;
	char *argv[];
{
	BOOL first = 1, esc = 0, nonl = 0;
	char *p;
	int i;

	for (i = 1; i < argc; ++i) {
		p = argv[i];
		if (p[0] == '-') {
			for (++p; *p; ++p) {
				switch (*p) {
				case 'n':	nonl = 1; break;
				case 'e':	esc = 1; break;
				default:	goto Print;
				}
			}
		}
		else	break;
	}
Print:	for (; i < argc; ++i) {
		p = argv[i];
		if (!first)
			fputc(' ', stdout);
		first = 0;
		if (esc)
			nonl = __doesc(p, nonl);
		else	fputs(p, stdout);
	}
	if (!nonl)
		fputc('\n', stdout);
}
#endif	/* CMD_ECHO */

#ifdef CMD_PWD
void do_pwd(argc, argv)
	int argc;
	char *argv[];
{
	char buf[PATHLEN];

	if (getcwd(buf, PATHLEN) == NULL) {
		perror("Can't get current directory");
		return;
	}
	fputs(buf, stdout);
	putchar('\n');
	fflush(stdout);
}
#endif	/* CMD_PWD */

void do_cd(argc, argv)
	int argc;
	char *argv[];
{
	char *path;

	if (argc > 1)
		path = argv[1];
	else {
		if ((path = getenv("HOME")) == NULL) {
			fprintf(stderr, "No HOME environment variable\n");
			return;
		}
	}
	if (chdir(path) < 0)
		perror(path);
}

#ifdef CMD_CHROOT
void do_chroot(argc, argv)
	int argc;
	char *argv[];
{
	char *path = argv[1];

	if (chroot(path) < 0)
		perror(path);
}
#endif

#ifdef CMD_MKDIR
void do_mkdir(argc, argv)
	int argc;
	char *argv[];
{
	while (--argc > 0) {
		if (mkdir(argv[1], 0777) < 0)
			perror(argv[1]);
		argv++;
	}
}
#endif	/* CMD_MKDIR */

#ifdef CMD_MKNOD
void do_mknod(argc, argv)
	int argc;
	char *argv[];
{
	char *cp;
	int major;
	int mode = 0666;

	if (strcmp(argv[2], "b") == 0)
		mode |= S_IFBLK;
	else if (strcmp(argv[2], "c") == 0)
		mode |= S_IFCHR;
	else {
		fprintf(stderr, "Bad device type\n");
		return;
	}
	for (major = 0, cp = argv[3]; isdecimal(*cp); ++cp) {
		major *= 10;
		major += *cp - '0';
	}
	if (*cp || (major < 0) || (major > 255)) {
		fprintf(stderr, "Bad major number\n");
		return;
	}
	if (mknod(argv[1], mode, major) < 0)
		perror(argv[1]);
}
#endif	/* CMD_MKNOD */

#ifdef CMD_RMDIR
void do_rmdir(argc, argv)
	int argc;
	char *argv[];
{
	while (--argc > 0) {
		if (rmdir(argv[1]) < 0)
			perror(argv[1]);
		argv++;
	}
}
#endif	/* CMD_RMDIR */

#ifdef CMD_SYNC
void do_sync(argc, argv)
	int argc;
	char *argv[];
{
	sync();
}
#endif	/* CMD_SYNC */

#ifdef CMD_RM
void do_rm(argc, argv)
	int argc;
	char *argv[];
{
	struct stat sbuf;
	int j;

	while (--argc > 0) {
		j = lstat(argv[1], &sbuf);
		if (j != 0) j = stat(argv[1], &sbuf);
		if (j == 0) {
			if ((sbuf.st_mode & S_IFDIR) != 0) {
				fprintf(stderr, "rm: %s is a directory\n",argv[1]);
				return;
			}
		}
		if ((j != 0) || (unlink(argv[1]))) perror(argv[1]);
		argv++;
	}
}
#endif	/* CMD_RM */

#ifdef CMD_CHMOD
void do_chmod(argc, argv)
	int argc;
	char *argv[];
{
	int mode = 0;
	char *cp = argv[1];

	while (isoctal(*cp))
		mode = (mode << 3) + (*cp++ - '0');
	if (*cp) {
		fprintf(stderr, "Mode must be octal\n");
		return;
	}
	for (--argc, ++argv; --argc > 0; ++argv) {
		if (chmod(argv[1], mode) < 0)
			perror(argv[1]);
	}
}
#endif	/* CMD_CHMOD */


#ifdef CMD_CHOWN
void do_chown(argc, argv)
	int argc;
	char *argv[];
{
	int uid;
	char *cp = argv[1];
	struct stat statbuf;

	if (isdecimal(*cp)) {
		for (uid = 0; isdecimal(*cp); ++cp) {
			uid *= 10;
			uid += *cp - '0';
		}
		if (*cp) {
			fprintf(stderr, "Bad uid value\n");
			return;
		}
	}
	else {
		struct passwd *pwd = getpwnam(cp);

		if (pwd == NULL) {
			fprintf(stderr, "Unknown user name\n");
			return;
		}
		uid = pwd->pw_uid;
	}
	for (--argc, ++argv; --argc > 0; ) {
		argv++;
		if ((stat(*argv, &statbuf) < 0) ||
		    (chown(*argv, uid, statbuf.st_gid) < 0))
			perror(*argv);
	}
}
#endif	/* CMD_CHOWN */

#ifdef CMD_CHGRP
void do_chgrp(argc, argv)
	char *argv[];
{
	int gid;
	struct stat statbuf;
	char *cp = argv[1];

	if (isdecimal(*cp)) {
		for (gid = 0; isdecimal(*cp); ++cp) {
			gid *= 10;
			gid += *cp - '0';
		}
		if (*cp) {
			fprintf(stderr, "Bad gid value\n");
			return;
		}
	}
	else {
		struct group *grp = getgrnam(cp);

		if (grp == NULL) {
			fprintf(stderr, "Unknown group name\n");
			return;
		}
		gid = grp->gr_gid;
	}
	for (--argc, ++argv; --argc > 0; ) {
		argv++;
		if ((stat(*argv, &statbuf) < 0) ||
		    (chown(*argv, statbuf.st_uid, gid) < 0))
			perror(*argv);
	}
}
#endif	/* CMD_CHGRP */

#ifdef CMD_TOUCH
void do_touch(argc, argv)
	int argc;
	char *argv[];
{
	int fd;
	char *name;
	struct utimbuf now;

	time(&now.actime);
	now.modtime = now.actime;
	while (--argc > 0) {
		name = *(++argv);
		if ((fd = open(name, O_CREAT | O_WRONLY | O_EXCL, 0666)) >= 0) {
			close(fd);
			continue;
		}
		if (utime(name, &now) < 0)
			perror(name);
	}
}
#endif	/* CMD_TOUCH */

#ifdef CMD_MV
void do_mv(argc, argv)
	int argc;
	char *argv[];
{
	char *srcname, *destname, *lastarg = argv[argc - 1];
	int dirflag = isadir(lastarg);

	if ((argc > 3) && !dirflag) {
		fprintf(stderr, "%s: not a directory\n", lastarg);
		return;
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
		if (rename(srcname, destname) >= 0)
			continue;
		if (errno != EXDEV) {
			perror(destname);
			continue;
		}
		if (!copyfile(srcname, destname, TRUE))
			continue;
		if (unlink(srcname) < 0)
			perror(srcname);
	}
}
#endif	/* CMD_MV */

#ifdef CMD_LN
void do_ln(argc, argv)
	int argc;
	char *argv[];
{
	int dirflag;
	char *srcname, *destname, *lastarg;

	if (argv[1][0] == '-') {
		if (strcmp(argv[1], "-s")) {
			fprintf(stderr, "Unknown option\n");
			return;
		}
		if (argc != 4) {
			fprintf(stderr, "Wrong number of arguments for symbolic link\n");
			return;
		}
#ifdef	S_ISLNK
		if (symlink(argv[2], argv[3]) < 0)
			perror(argv[3]);
#else
		fprintf(stderr, "Symbolic links are not allowed\n");
#endif
		return;
	}
	/* Here for normal hard links. */
	lastarg = argv[argc - 1];
	dirflag = isadir(lastarg);
	if ((argc > 3) && !dirflag) {
		fprintf(stderr, "%s: not a directory\n", lastarg);
		return;
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
}
#endif	/* CMD_LN */

#ifdef CMD_CP
void do_cp(argc, argv)
	char *argv[];
{
	char *srcname, *destname, *lastarg = argv[argc - 1];
	BOOL dirflag = isadir(lastarg);

	if ((argc > 3) && !dirflag) {
		fprintf(stderr, "%s: not a directory\n", lastarg);
		return;
	}
	while (argc-- > 2) {
		destname = lastarg;
		srcname = *++argv;
		if (dirflag)
			destname = buildname(destname, srcname);
		copyfile(srcname, destname, FALSE);
	}
}
#endif	/* CMD_CP */

#ifdef CMD_MOUNT
void do_mount(argc, argv)
	int argc;
	char *argv[];
{
	char *str;
	BOOL ro = FALSE;

	for (--argc, ++argv; argc > 0 && **argv == '-'; ) {
		for (--argc, str = *argv++; *++str; ) {
			switch (*str) {
			case 'r':
				ro = TRUE;
				break;
			default:
				fprintf(stderr, "Unknown option -%c\n",*str);
				return;
			}
		}
	}
	if (argc != 2) {
		fprintf(stderr, "Wrong number of arguments for mount\n");
		return;
	}
	if (mount(argv[0], argv[1], ro) < 0)
		perror("mount failed");
}
#endif	/* CMD_MOUNT */

#ifdef CMD_MOUNT
void do_umount(argc, argv)
	int argc;
	char *argv[];
{
	if (umount(argv[1]) < 0)
		perror(argv[1]);
}
#endif	/* CMD_MOUNT */

#ifdef CMD_CMP
void do_cmp(argc, argv)
	int argc;
	char *argv[];
{
	long pos;
	int fd1, fd2;
	int cc1, cc2;
	struct stat statbuf1, statbuf2;
	char *bp1, *bp2, buf1[BUFSIZ], buf2[BUFSIZ];

	if (stat(argv[1], &statbuf1) < 0) {
		perror(argv[1]);
		return;
	}
	if (stat(argv[2], &statbuf2) < 0) {
		perror(argv[2]);
		return;
	}
	if ((statbuf1.st_dev == statbuf2.st_dev) &&
	    (statbuf1.st_ino == statbuf2.st_ino)) {
		printf("Files are links to each other\n");
		return;
	}
	if (memcmp(&statbuf1.st_size,&statbuf2.st_size,sizeof(statbuf1.st_size))) {
		printf("Files are different sizes\n");
		return;
	}
	if ((fd1 = open(argv[1], 0)) < 0) {
		perror(argv[1]);
		return;
	}
	if ((fd2 = open(argv[2], 0)) < 0) {
		perror(argv[2]);
		close(fd1);
		return;
	}
	for (pos = 0; ; ) {
		if (intflag)
			goto closefiles;
		if ((cc1 = read(fd1, buf1, sizeof(buf1))) < 0) {
			perror(argv[1]);
			goto closefiles;
		}
		if ((cc2 = read(fd2, buf2, sizeof(buf2))) < 0) {
			perror(argv[2]);
			goto closefiles;
		}
		if ((cc1 == 0) && (cc2 == 0)) {
			printf("Files are identical\n");
			goto closefiles;
		}
		if (cc1 < cc2) {
			printf("First file is shorter than second\n");
			goto closefiles;
		}
		if (cc1 > cc2) {
			printf("Second file is shorter than first\n");
			goto closefiles;
		}
		if (memcmp(buf1, buf2, cc1) == 0) {
			pos += cc1;
			continue;
		}
		for (bp1 = buf1, bp2 = buf2; *bp1++ == *bp2++; ++pos)
			;
		printf("Files differ at byte position %ld\n", pos);
		goto closefiles;
	}

closefiles:
	close(fd1);
	close(fd2);
}
#endif	/* CMD_CMP */

#ifdef CMD_CAT_MORE
void do_cat(argc, argv)
	int argc;
	char *argv[];
{
	do_cat_more(argc,argv,CMDCAT);
}

void do_more(argc, argv)
	int argc;
	char *argv[];
{
	do_cat_more(argc,argv,CMDMORE);
}
#endif

#ifdef CMD_MORE
void do_more(argc, argv)
#endif
#ifdef CMD_CAT_MORE
void do_cat_more(argc, argv, mode)
#endif
#if defined(CMD_MORE) || defined(CMD_CAT_MORE)
	int argc;
	char *argv[];
#ifdef CMD_CAT_MORE
	int mode;
#endif
{
	FILE *fp;
	int ch, line, col, tty = STDIN_FILENO;
	char *name, buf[80];
	BOOL viastdin = FALSE;

	if (argc < 2) {
		if (isatty(STDIN_FILENO)) {
			return;
		} else {
			viastdin = TRUE;
			argc++;
			tty = open(_PATH_CONSOLE, O_RDONLY);
		}
	}
	ioctl(tty, TTY_RAW);
	while (--argc > 0) {
		if (!viastdin) {
			name = *(++argv);
			if ((fp = fopen(name, "r")) == NULL) {
				perror(name);
				continue;
			}
		} else fp = stdin;
		if (!viastdin)
#ifdef CMD_CAT_MORE
		    if (mode == CMDMORE)
#endif
			printf("<< %s >>\n", name);
		line = 1;
		col = 0;
		while (fp && ((ch = fgetc(fp)) != EOF)) {
			switch (ch) {
			case '\r':
				col = 0;
				break;
			case '\n':
				line++;
				col = 0;
				break;
			case '\t':
				col = ((col + 1) | 0x07) + 1;
				break;
			case '\b':
				if (col > 0)
					col--;
				break;
			default:
				col++;
			}
			putchar(ch);
			if (col >= 80) {
				col -= 80;
				line++;
			}
			if
#ifdef CMD_CAT_MORE
			   (
#endif
			    (line < 24)
#ifdef CMD_CAT_MORE
					|| (mode==CMDCAT))
#endif
				continue;
			if (col > 0)
				putchar('\n');
			printf("--More--");
			if (argc > 1) 
				printf(" (Next file: %s)", *(argv+1)?*(argv+1):"none");
			fflush(stdout);
			if ((intflag) || (read(tty, buf, 1) < 0)) {
				if (fp)
					fclose(fp);
				goto End;
			}
			ch = buf[0];
			if (ch == ':') {
				putchar(':');
				if ((intflag) || (read(tty, buf, 1) < 0)) {
					if (fp)
						fclose(fp);
					goto End;
				}
				ch = buf[0];
			}
			putchar('\n');
			switch (ch) {
			case 'P':
			case 'p':
				argc += 2;
				argv -= 2;
				fclose(fp);
				fp = NULL;
				break;
			case 'N':
			case 'n':
				fclose(fp);
				fp = NULL;
				break;
			case '\'':
				argc++;
				argv--;
				fclose(fp);
				fp = NULL;
				break;
			case 'Q':
			case 'q':
				fclose(fp);
				goto End;
			case '\n':
			case '\r':
				--line;
				continue;
			}
			col = 0;
			line = 1;
		}
		if (col > 0) putchar('\n');
		if (fp && !viastdin)
			fclose(fp);
	}
End: ioctl(tty, TTY_COOKED);
     if (viastdin) close(tty);
}
#endif	/* CMD_MORE / CMD_CAT_MORE */

void do_exit(argc, argv)
	int argc;
	char *argv[];
{
	exit(argc > 1 ? atoi(argv[1]) : 0);
}

#ifdef CMD_SET
void do_setenv(argc, argv)
	int argc;
	char *argv[];
{
	int len;
	char *p, **env = environ;

	if (argc == 1) {
		while (*env)
			printf("%s\n", *env++);
		return;
	}
	if (argc == 2) {
		len = strlen(p = argv[1]);
		if (p[len-1] != '=') {
			for (; *env; ++env) {
				if (strlen(*env) > len &&
				    env[0][len] == '=' &&
				    memcmp(p, *env, len) == 0) {
					printf("%s\n", &env[0][len + 1]);
					break;
				}
			}
			return;
		}
		p[len-1] = '\0';
		unsetenv(p);
		return;
	}
	setenv(argv[1], argv[2], 1);
}
#endif	/* CMD_SET */

#ifdef CMD_UMASK
void do_umask(argc, argv)
	int argc;
	char *argv[];
{
	char *cp;
	int mask;

	if (argc <= 1) {
		mask = umask(0);
		umask(mask);
		printf("%03o\n", mask);
		return;
	}
	for (mask = 0, cp = argv[1]; isoctal(*cp); ++cp) {
		mask <<= 3;
		mask += *cp - '0';
	}
	if (*cp || (mask & ~0777)) {
		fprintf(stderr, "Bad umask value\n");
		return;
	}
	umask(mask);
}
#endif	/* CMD_UMASK */

#ifdef CMD_KILL
void do_kill(argc, argv)
	int argc;
	char  *argv[];
{
	char *cp;
	int pid, sig = SIGTERM;

	if (argv[1][0] == '-') {
		cp = &argv[1][1];
		if (strnicmp(cp,"SIG",3) == 0)
			cp += 3;
		if (stricmp(cp, "HUP") == 0)		sig = SIGHUP;
		else if (stricmp(cp, "INT") == 0)	sig = SIGINT;
		else if (stricmp(cp, "QUIT") == 0)	sig = SIGQUIT;
		else if (stricmp(cp, "KILL") == 0)	sig = SIGKILL;
		else if (stricmp(cp, "TERM") == 0)	sig = SIGTERM;
		else {
			for (sig = 0; isdecimal(*cp); ++cp) {
				sig *= 10;
				sig += *cp++ - '0';
			}
			if (*cp) {
				fprintf(stderr, "Unknown signal\n");
				return;
			}
		}
		argc--;
		argv++;
	}
	while (--argc > 0) {
		for (pid = 0, cp = *++argv; isdecimal(*cp); ++cp)  {
			pid *= 10;
			pid += *cp - '0';
		}
		if (*cp) {
			fprintf(stderr, "Non-numeric pid\n");
			return;
		}
		if (kill(pid, sig) < 0)
			perror(*argv);
	}
}
#endif	/* CMD_KILL */

