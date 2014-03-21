/*
 * UZIX - UNIX Implementation for MSX
 * (c) 1997-2001 Arcady Schekochikhin
 *		 Adriano C. R. da Cunha
 *
 * UZIX is based on UZI (UNIX Zilog Implementation)
 * UZI is a UNIX kernel clone written for Z-80 systems.
 * All code is public domain, not being based on any AT&T code.
 *
 * The author, Douglas Braun, can be reached at:
 *	7696 West Zayante Rd.
 *	Felton, CA 95018
 *	oliveb!intelca!mipos3!cadev4!dbraun
 *
 * This program is under GNU GPL, read COPYING for details
 *
 */

/**********************************************************
 UZIX utilities:

 UCP: to manipulate files on an UZIX disk.
 Usage:	ucp [-p1y] d: [@filename]
**********************************************************/

#define __MAIN__COMPILATION

#include "xfs.h"
#include "utildos.h"
#include "fcntl.h"
#ifdef SEPH
#include "sys\ioctl.h"
#include "sys\stat.h"
#endif
#ifdef _MSX_DOS
#include ".\include\stdio.h"
#include ".\include\stdlib.h"
#include ".\include\string.h"
#include ".\include\unixio.h"
#include ".\include\ctype.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#include <c:\tc\include\string.h>
#include <c:\tc\include\ctype.h>
#include <c:\tc\include\dir.h>
#include <c:\tc\include\io.h>
#endif

FILE *in = stdin;
int rdev = -1;
uchar *syserror = &udata.u_error;
uchar cwd[128+1];
uchar line[128+1];
uchar f_pause = 0;

int xls __P((char *option, char *path));
int xchmod __P((char *path, char *modes));
int xumask __P((char *masks));
int xmknod __P((char *path, char *modes, char *devs, char *devs1));
int xmkdir __P((char *path));
int xget __P((char *arg, char *unixn, int binflag));
int xput __P((char *arg, char *dosn, int binflag));
int xtype __P((char *arg));
int xdump __P((char *arg, char *start, char *end));
int xunlink __P((char *path));
int xrmdir __P((char *path));
int xdf __P((void));
extern int ldir __P((char *s1));
#ifdef _MSX_DOS
extern int memicmp __P((char *s1, char *s2, int t));
extern int chdir __P((char *s1));
#endif

void pse __P((void));
void dohelp __P((void));
int eq __P((char *, char *));
int execute __P((char *cmd, char *a1, char *a2, char *a3, char *a4));

char *help[] = {
#ifndef _MSX_DOS
	"!<external_command>",
#endif
	"exit|quit",
	"root d:",
	"df",
	"pwd",
	"ls [-l] [dirname[/filename]]",
	"cd dirname",
	"lcd dosdirname",
	"ldir [filemask]",
	"umask mask",
	"mkdir name",
	"mknod name mode major minor",
	"chmod mode name",
	"[b]get dosfilename [uzixfilename]",
	"[b]put uzixfilename [dosfilename]",
	"type|cat filename",
	"dump filename [startblk [endblk]]",
	"[s]ln srcname dstname",
	"rm [dirname/]filename",
	"rmdir dirname",
	"mount devicename dirname",
	"umount devicename",
	"success|failure label",
	NULL
};

void pse(VOID) {
	if (f_pause) {
		fprintf(stderr,"Press ENTER>");
		fflush(stderr);
		fgets(line,128,stdin);
	}
}

void dohelp(VOID) {
	int i = 0;

	while (help[i] != NULL)
		PF("%s\n",help[i++]);
}

int eq(s1,s2)
	char *s1;
	char *s2;
{
	return (stricmp(s1,s2) == 0);
}

int execute(cmd, a1, a2, a3, a4)
	char *cmd, *a1, *a2, *a3, *a4;
{
	if (rdev < 0)	{
		PF("error: root device not mounted\n");
		pse();
	}
	else if (eq(cmd, "ls"))
		xls (a1, a2);
	else if (eq(cmd, "umask"))
		xumask(*a1 ? a1 : "0");
	else if (eq(cmd, "cd")) {
		if (*a1) {
			if (UZIXchdir(a1)) {
				PF("cd: error %s\n", stringerr[*syserror]);
				pse();
			}
			else	strcpy(cwd, a1);
		}
	}
	else if (eq(cmd, "pwd")) {
		PF("%s\n",cwd);
	}
	else if (eq(cmd, "mkdir")) {
		if (*a1)
			xmkdir(a1);
	}
	else if (eq(cmd, "mknod")) {
		if (*a1 && *a2 && *a3 && *a4)
			xmknod(a1, a2, a3, a4);
	}
	else if (eq(cmd, "chmod")) {
		if (*a1 && *a2)
			xchmod(a1, a2);
	}
	else if (eq(cmd, "ln")) {
		if (*a1 && *a2)
			UZIXlink(a1, a2);
	}
	else if (eq(cmd, "sln")) {
		if (*a1 && *a2)
			UZIXsymlink(a1, a2);
	}
	else if (eq(cmd, "get")) {
		if (*a1)
			xget(a1, a2, 0);
	}
	else if (eq(cmd, "bget")) {
		if (*a1)
			xget(a1, a2, 1);
	}
	else if (eq(cmd, "put")) {
		if (*a1)
			xput(a1, a2, 0);
	}
	else if (eq(cmd, "bput")) {
		if (*a1)
			xput(a1, a2, 1);
	}
	else if (eq(cmd, "type") || eq(cmd, "cat")) {
		if (*a1)
			xtype(a1);
	}
	else if (eq(cmd, "dump")) {
		if (*a1)
			xdump(a1, a2, a3);
	}
	else if (eq(cmd, "rm")) {
		if (*a1)
			xunlink(a1);
	}
	else if (eq(cmd, "df"))
			xdf();
	else if (eq(cmd, "rmdir")) {
		if (*a1)
			xrmdir(a1);
	}
	else if (eq(cmd, "mount")) {
		if (*a1 && *a2 && UZIXmount(a1, a2, 0) != 0) {
			PF("mount: error %s\n", stringerr[*syserror]);
			pse();
		}
	}
	else if (eq(cmd, "umount")) {
		if (*a1 && UZIXumount(a1) != 0) {
			PF("umount: error %s\n", stringerr[*syserror]);
			pse();
		}
	}
	else	return	1;
	return 0;
}

void usage(void) {
	fprintf(stderr, 
		"usage: ucp [switches] [dev] [indirect]\n"
		"\tswitches:\n"
		"\t\t-p - pause after error\n"
		"\t\t-1 - don't mount root\n"
		"\t\t-y - don't ask user for UZIX disk\n"
		"\tdev:\n"
		"\t\t0..7\n"
		"\t\tA:..Z:\n"
		"\tindirect:\n"
		"\t\t@filename\n"
		"\t\t@ filename\n"
	);
	xexit(1);
}

int main(argc, argv)
	int argc;
	char *argv[];
{
	int count, lasterr, quiet, skip = 0, _rdev;
	uchar waitdisk = 1;
	char *s, cmd[30], a1[30], a2[30], a3[30], a4[30];

#ifdef _MSX_DOS
	initenv();
	cursor(0);
#endif
	for (++argv; --argc > 0; ) {
		s = *argv++;
		if (*s == '-') {
			switch (*++s) {
			case 'p': case 'P':
				f_pause = 1;
				break;
			case '1':
				rdev = -1;
				break;
			case 'y': case 'Y':
				waitdisk = 0;
				break;
			default:
				usage();
			}
		}
		else if (*s == '@') {
			if (in != stdin) {
				fprintf(stderr,"Input file already redirected\n");
				xexit(1);
			}
			if (*++s == '\0') {
				if (--argc <= 0)
					usage();
				s = *argv++;
			}
			if (NULL == (in = fopen(s,"rt"))) {
				fprintf(stderr,"Can't redirect input to file %s\n",s);
				xexit(1);
			}
		}
		else if (isdigit(*s) && s[1] == '\0') {
			rdev = *s - '0';
		}
		else if (isalpha(*s) && s[1] == ':') {
			rdev = ((*s & 0xDF) - 'A');
		}
		else	usage();
	}
	xfs_init(rdev, waitdisk);
	strcpy(cwd, "/");
	quiet = !isatty(fileno(in));
	if (!quiet)
		PF("UCP ready!\n");
	lasterr = 0;
	for (;;) {
		if (!quiet) {
			PF("\ruzix: ");
			skip = 0;
		}
		if (fgets(line,128,in) == NULL)
			break;
		if (quiet) {
			if (skip && memicmp(line,a1,strlen(a1))) {
				putchar('#');
				fputs(line,stdout);
				goto Cont;
			}
			if (skip && (memicmp(line,a1,strlen(a1))==0)) --skip;
			fputs(line,stdout);
		}
		cmd[0] = a1[0] = a2[0] = a3[0] = '\0';
		count = sscanf(line, "%s %s %s %s %s", cmd, a1, a2, a3, a4);
		if (count == 0 || cmd[0] == '#' || cmd[0] == ':')
			goto Cont;
		if (*cmd == 0)
			UZIXsync();
		else if (eq(cmd, "exit") || eq(cmd, "quit"))
			break;
#ifndef _MSX_DOS
		else if (cmd[0] == '!') {
			s = strchr(line, '\n');
			if (s != NULL) *s='\0';
			for (s = line; *s++ != '!'; )
				;
			while (*s == ' ' || *s == '\t')
				++s;
			system(s);
		}
#endif
		else if (eq(cmd, "?"))
			dohelp();
		else if (eq(cmd, "success")) {
			if (!lasterr)
				++skip;
		}
		else if (eq(cmd, "failure")) {
			if (lasterr)
				++skip;
		}
		else if (eq(cmd, "root")) {
			if (rdev >= 0) {
				PF("root: root device already mounted!\n");
				pse();
			}
			else {
				if (isdigit(*a1))
					_rdev = *a1 - '0';
				else	_rdev = (*a1 & 0xDF) - 'A';
				if ((unsigned)_rdev <= 8) {
					rdev = _rdev;
					xfs_init(rdev, waitdisk);
					strcpy(cwd, "/");
				} 
				else {
					PF("root: invalid drive %c.\n",*a1);
					pse();
				}
			}
		}
		else if (eq(cmd, "lcd")) {
			if (*a1 && chdir(a1)) {
				PF("lcd: can't chdir to %s\n", a1);
				pse();
			}
		}
		else if (eq(cmd, "ldir")) {
			ldir(*a1 ? a1 : "*.*");
		}
		else if (execute(cmd, a1, a2, a3, a4)) {
			PF("Unknown command - use ?\n");
			pse();
		}
Cont:		lasterr = *syserror;
		*syserror = 0;
	}
	xfs_end();
#ifdef _MSX_DOS
	cursor(255);
#endif
	return 0;
}

