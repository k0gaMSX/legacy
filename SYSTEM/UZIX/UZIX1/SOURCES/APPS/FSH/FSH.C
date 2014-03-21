/*
 * fsh, the Fudeba SHell
 * version 1.0
 * by A&L Software 1999
 *
 * heavily based on UZIX UCP
 * also based on David Bell's SASH
 * intended to be a VERY simple and basic shell, even smaller than SASH
 *
 * This program is released under GNU GPL license.
 *
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys\ioctl.h>
#include <sys\stat.h>

#define PF	printf
#define VERSION	"1.0"

uchar cwd[128+1];
uchar line[128+1];

int xls __P((char *path));
int xchmod __P((char *path, char *modes));
int xumask __P((char *masks));
int xmknod __P((char *path, char *modes, char *devs, char *devs1));
int xmkdir __P((char *path));
int xtype __P((char *arg));
int xunlink __P((char *path));
int xrmdir __P((char *path));
void xsetenv __P((char *va1, char *va2));
int xdf __P((void));

void dohelp __P((void));
int eq __P((char *, char *));
int execute __P((char *cmd, char *a1, char *a2, char *a3, char *a4));

char *help[] = {
	"cat filename",
	"cd dirname",
	"chmod mode name",
	"df",
	"exit",
	"help",
	"ln srcname dstname",
	"logout",
	"ls [dirname[/filename]]",
	"mkdir name",
	"mknod name mode major minor",
	"pwd",
	"umask mask",
	"rm [dirname/]filename",
	"rmdir dirname",
	"set [var=value]",
	"sln srcname dstname",
	NULL
};

char *stringerr[] = {
	"FSH internal error",
	"operation not permitted",
	"no such file or directory",
	"no such process",
	"interrupted system call",
	"I/O error",
	"no such device or address",
	"arg list too long",
	"exec format error",
	"bad file number",
	"no child processes",
	"try again",
	"out of memory",
	"permission denied",
	"bad address",
	"block device required",
	"device or resource busy",
	"file exists",
	"cross-device link",
	"no such device",
	"not a directory",
	"is a directory",
	"invalid argument",
	"file table overflow",
	"too many open files",
	"not a typewriter",
	"text file busy",
	"file too large",
	"no space left on device",
	"illegal seek",
	"read-only file system",
	"too many links",
	"broken pipe",
	"math argument out of domain of func",
	"math result not representable",
	"resource deadlock would occur",
	"file name too long",
	"no record locks available",
	"function not implemented",
	"directory not empty",
	"too many symbolic links encountered",
	"it's a shell script"
};

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

int memicmp(char *s1, char *s2, int t) {
	while (--t >= 0) {
		if (tolower(*s1) != tolower(*s2))
			return -1;
		++s1;
		++s2;
	}
	return 0;
}

int execute(cmd, a1, a2, a3, a4)
	char *cmd, *a1, *a2, *a3, *a4;
{
	if (eq(cmd, "ls"))
		xls (*a1 ? a1 : ".");
	else if (eq(cmd, "umask"))
		xumask(*a1 ? a1 : "0");
	else if (eq(cmd, "cd")) {
		if (*a1) {
			if (chdir(a1))
				PF("cd: %s\n", stringerr[errno]);
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
			link(a1, a2);
	}
	else if (eq(cmd, "sln")) {
		if (*a1 && *a2)
			symlink(a1, a2);
	}
	else if (eq(cmd, "cat")) {
		if (*a1)
			xtype(a1);
	}
	else if (eq(cmd, "rm")) {
		if (*a1)
			xunlink(a1);
	}
	else if (eq(cmd, "df"))
			xdf();
	else if (eq(cmd, "set"))
			xsetenv(a1, a2);
	else if (eq(cmd, "rmdir")) {
		if (*a1)
			xrmdir(a1);
	}
	else	return	1;
	return 0;
}

void do_exec(cmd, a1, a2, a3, a4)
	char *cmd, *a1, *a2, *a3, *a4;
{
	int pid1 = 0, pid2 = 0, bgp = 0, status, i;
	int argc = 0;
	char *argv[6];

	argv[0] = cmd;
	argv[1] = a1;
	argv[2] = a2;
	argv[3] = a3;
	argv[4] = a4;
	for (i = 0; i < 5; i++)
		if (*argv[i]) argc++;
	argv[argc] = NULL;
	bgp = (strcmp(argv[argc-1],"&") == 0);
	if (bgp) argv[--argc] = 0; 
	if ((pid1 = fork()) < 0) {
		PF("fsh: fork failed\n");
		return;
	}
	if (pid1) {
		status = 0;
		if (bgp)
			printf("[%d]: %s\n", pid1, argv[0]);
		else
			while ((((pid2 = wait(&status)) < 0) && 
				(errno == EINTR)) || (pid2 != pid1));
		ioctl(STDIN_FILENO, TTY_COOKED);
		if (status & 0x00ff) {
			fprintf(stderr, "pid %d: %s (signal %d)\n", pid1,
				(status & 0x80) ? "core dumped" : "killed",
				(status & 0x7f));
		}
		return;
	}
	/* We are the child, so run the program. */
	execvp(argv[0], argv);
	if (errno == ESHELL) {
		for (i = argc+1; i > 0; --i)
			argv[i] = argv[i-1];
		argv[0] = "/bin/fsh";
		execvp(argv[0], argv);
	}
	PF("%s: %s\n",argv[0], stringerr[errno]);
	exit(1);
}

int main(argc, argv)
	int argc;
	char *argv[];
{
	FILE *in = stdin;
	int count, lasterr, quiet, skip = 0;
	char cmd[30], a1[30], a2[30], a3[30], a4[30];

	signal(SIGINT, SIG_IGN);
	signal(SIGABRT, SIG_IGN);
	getcwd(cwd, 128+1-1);
	quiet = !isatty(fileno(in));
	if (!quiet)
		PF("FSH vr. " VERSION "\n");
	for (;;) {
		if (!quiet) {
			PF("\r] ");
			fflush(stdout);
			skip = 0;
		}
		if (fgets(line,128,in) == NULL)
			break;
		cmd[0] = a1[0] = a2[0] = a3[0] = '\0';
		count = sscanf(line, "%s %s %s %s %s", cmd, a1, a2, a3, a4);
		if (count == 0 || cmd[0] == '#' || cmd[0] == ':')
			goto Cont;
		else if (eq(cmd, "exit") || eq(cmd, "logout"))
			break;
		else if (eq(cmd, "help"))
			dohelp();
		else if (execute(cmd, a1, a2, a3, a4))
			do_exec(cmd, a1, a2, a3, a4);
Cont:		lasterr = errno;
	}
	return 0;
}

