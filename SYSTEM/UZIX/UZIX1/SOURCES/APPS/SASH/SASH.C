/* Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Stand-alone shell for system maintainance for Linux.
 * This program should NOT be built using shared libraries.
 */

/* Changes:
 *
 * 1999-2001: Adriano Cunha <adrcunha@dcc.unicamp.br>
 *	   some bugfix
 *	   added background processing ('&')
 *	   added 'light' versions of ls/cat/more
 *         added option -c 
 *	   allow comments in command line ('#')
 *	   shell scripts can't define the shell used. used environment SH
 *	   ls_light/background process/command() bugfix
 *	   background processes now tell their pid
 *	   new version of 'echo' with escape sequences handling
 *	   default prompt now is user@node$
 *	   if SASH is the primary shell, it executes ~/.loginrc
 *	   added stdin/stdout redirection (>, <, >>)
 *	   added pipe capability between two commands
 *	   added '!!' command (repeat last command line)
 */
 
#include "sash.h"
#include <signal.h>
#include <errno.h>
#include <paths.h>
#include <sys/ioctl.h>
#include <utsname.h>
#include <fcntl.h>
#include <sys/wait.h>
#pragma warn -par

#if defined(MSX_UZIX_TARGET) || defined(PC_UZIX_TARGET)
#define UZIX
#endif

static char *version = "1.0f";

typedef struct {
	char	*name;
	char	*usage;
	void	(*func) __P((int, char **));
	unsigned char minargs;
	unsigned char maxargs;
} CMDTAB;

typedef struct {
	char	*name;
	char	*value;
} ALIAS;

static ALIAS *aliastable;
static int aliascount;

static FILE *sourcefiles[MAXSOURCE];
static int sourcecount;

static BOOL intcrlf = TRUE;
static char *prompt;

static int stdinfd_bkp;
static int stdoutfd_bkp;

BOOL	intflag;

BOOL	_coption = FALSE;

#ifdef UZIX
BOOL	inscript = FALSE;
static	FILE* scriptfd;
#define	in_script	inscript = TRUE
#define not_in_script	inscript = FALSE
#else
#define	in_script
#define not_in_script
#endif



static void readfile __P((char *name));
static void command __P((char *cmd));
static BOOL trybuiltin __P((int argc, char **argv));
static void runcmd __P((int argc, char **argv));
static ALIAS *findalias __P((char *name));
static void showprompt __P((void));
static void catchint __P((signal_t));
static void catchquit __P((signal_t));
static void command2 __P((int argc, char *argv[]));
static void restoreredir __P((void));

static CMDTAB cmdtab[] = {
#ifdef CMD_ALIAS
	"alias", "[name [command]]", do_alias,	1, MAXARGS,
#endif
	"cd", "[dirname]", do_cd, 1, 2,
#ifdef CMD_CHGRP
	"chgrp", "gid filename ...", do_chgrp, 3, MAXARGS,
#endif
#ifdef CMD_CAT_MORE
	"cat", "filename ...", do_cat, 1, MAXARGS,
#endif
#ifdef CMD_CHMOD
	"chmod", "mode filename ...", do_chmod, 3, MAXARGS,
#endif
#ifdef CMD_CHOWN
	"chown", "uid filename ...", do_chown, 3, MAXARGS,
#endif
#ifdef CMD_CHROOT
	"chroot", "dir", do_chroot, 2, 2,
#endif
#ifdef CMD_CMP
	"cmp", "filename1 filename2", do_cmp, 3, 3,
#endif
#ifdef CMD_CP
	"cp", "srcname ... destname", do_cp, 3, MAXARGS,
#endif
#ifdef CMD_DD
	"dd", "if=name of=name [bs=n] [count=n] [skip=n] [seek=n]", do_dd, 3, MAXARGS,
#endif
#ifdef CMD_ECHO_LIGHT
	"echo", "[-n] [args] ...", do_echo, 1, MAXARGS,
#endif
#ifdef CMD_ECHO
	"echo", "[-ne] [args] ...", do_echo, 1, MAXARGS,
#endif
#ifdef CMD_ED
	"ed", "[filename]", do_ed, 1, 2,
#endif
#ifdef CMD_EXEC
	"exec", "filename [args]", do_exec, 2, MAXARGS,
#endif
	"exit", "[status]", do_exit, 1, 2,
#ifdef CMD_GREP
	"grep", "[-in] word filename ...", do_grep, 3, MAXARGS,
#endif
#ifdef CMD_HELP
	"help", "", do_help, 1, MAXARGS,
#endif
#ifdef CMD_KILL
	"kill", "[-sig] pid ...", do_kill, 2, MAXARGS,
#endif
#ifdef CMD_LN
	"ln", "[-s] srcname ... destname", do_ln, 3, MAXARGS,
#endif
	"logout", "", do_exit, 1, 1,
#ifdef CMD_LS
	"ls", "[-lid] filename ...", do_ls, 1, MAXARGS,
#endif
#ifdef CMD_LS_LIGHT
	"ls", "[-l] [dirname]", do_ls, 1, 3,
#endif
#ifdef CMD_MKDIR
	"mkdir", "dirname ...", do_mkdir, 2, MAXARGS,
#endif
#ifdef CMD_MKNOD
	"mknod", "filename type major minor", do_mknod, 5, 5,
#endif
#if defined(CMD_CAT_MORE) || defined(CMD_MORE)
	"more", "filename ...", do_more, 1, MAXARGS,
#endif
#ifdef CMD_MOUNT
	"mount", "[-t type] devname dirname", do_mount, 3, MAXARGS,
#endif
#ifdef CMD_MV
	"mv", "srcname ... destname", do_mv, 3, MAXARGS,
#endif
	"prompt", "string", do_prompt, 2, MAXARGS,
#ifdef CMD_PWD
	"pwd", "", do_pwd, 1, 1,
#endif
	"quit", "", do_exit, 1, 1,
#ifdef CMD_RM
	"rm", "filename ...", do_rm, 2, MAXARGS,
#endif
#ifdef CMD_RMDIR
	"rmdir", "dirname ...", do_rmdir, 2, MAXARGS,
#endif
#ifdef CMD_SET
	"set", "[name[ value]]", do_setenv, 1, 3,
#endif
#ifdef CMD_SLEEP
	"sleep", "[sec]", do_sleep, 1, 2,
#endif
	"source", "filename", do_source, 2, 2,
#ifdef CMD_SYNC
	"sync", "", do_sync, 1, 1,
#endif
#ifdef CMD_TAR
	"tar", "[xtv]f devname filename ...", do_tar, 2, MAXARGS,
#endif
#ifdef CMD_TOUCH
	"touch", "filename ...", do_touch, 2, MAXARGS,
#endif
	"trace", "{on}", do_trace, 1, 2,
#ifdef CMD_UMASK
	"umask", "[mask]", do_umask, 1, 2,
#endif
#ifdef CMD_MOUNT
	"umount", "filename", do_umount, 2, 2,
#endif
#ifdef CMD_ALIAS
	"unalias", "name", do_unalias, 2, 2,
#endif
	{ NULL },
	"?", "", runcmd, 1, MAXARGS
};

#ifdef CMD_HELP
void do_help(argc, argv)
	int argc;
	char **argv;
{
	CMDTAB *cmdptr;

	for (cmdptr = cmdtab; cmdptr->name; cmdptr++)
		printf("%-10s %s\n", cmdptr->name, cmdptr->usage);
}
#endif	/* CMD_HELP */

void closefiles() {
	while (--sourcecount >= 0) {
		if (sourcefiles[sourcecount] != stdin
#ifdef UZIX
			&& ((inscript && sourcefiles[sourcecount] != scriptfd) || !inscript)
#endif
			)
				fclose(sourcefiles[sourcecount]);
	}
}

void execfile(argc, argv)
	int argc;
	char *argv[];
{
	int i;

	execvp(argv[0], argv);
	if (errno == ESHELL) {
		for (i = argc+1; i > 0; --i)
			argv[i] = argv[i-1];		
		argv[0] = getenv("SH");
		execvp(argv[0], argv);
	}
	perror(argv[0]);
}

void do_trace(argc, argv)
	int argc;
	char **argv;
{
	if (argc == 1)
		systrace(0);
	else	systrace(atoi(argv[1]));
}

#ifdef CMD_ALIAS
void do_alias(argc, argv)
	int argc;
	char **argv;
{
	char *name, *value, buf[CMDLEN];
	ALIAS  *alias;
	int count;

	if (argc < 2) {
		count = aliascount;
		for (alias = aliastable; count-- > 0; alias++)
			printf("%s\t%s\n", alias->name, alias->value);
		return;
	}
	name = argv[1];
	if (argc == 2) {
		alias = findalias(name);
		if (alias)
			printf("%s\n", alias->value);
		else	fprintf(stderr, "Alias \"%s\" is not defined\n", name);
		return;
	}
	if (strcmp(name, "alias") == 0) {
		fprintf(stderr, "Cannot alias \"alias\"\n");
		return;
	}
	if (!makestring(argc - 2, argv + 2, buf, CMDLEN))
		return;
	value = malloc(strlen(buf) + 1);
	if (value == NULL) {
		fprintf(stderr, "No memory for alias value\n");
		return;
	}
	strcpy(value, buf);
	alias = findalias(name);
	if (alias) {
		free(alias->value);
		alias->value = value;
		return;
	}
	if ((aliascount % ALIASALLOC) == 0) {
		count = aliascount + ALIASALLOC;
		if (aliastable)
			alias = (ALIAS *) realloc(aliastable, sizeof(ALIAS *) * count);
		else	alias = (ALIAS *) malloc(sizeof(ALIAS *) * count);
		if (alias == NULL) {
			free(value);
			fprintf(stderr, "No memory for alias table\n");
			return;
		}
		aliastable = alias;
	}
	alias = &aliastable[aliascount];
	alias->name = malloc(strlen(name) + 1);
	if (alias->name == NULL) {
		free(value);
		fprintf(stderr, "No memory for alias name\n");
		return;
	}
	strcpy(alias->name, name);
	alias->value = value;
	aliascount++;
}

void do_unalias(argc, argv)
	int argc;
	char **argv;
{
	ALIAS *alias;

	while (--argc > 0) {
		if ((alias = findalias(*++argv)) == NULL)
			continue;
		free(alias->name);
		free(alias->value);
		aliascount--;
		alias->name = aliastable[aliascount].name;
		alias->value = aliastable[aliascount].value;
	}
}
#endif	/* CMD_ALIAS */

/*
 * Look up an alias name, and return a pointer to it.
 * Returns NULL if the name does not exist.
 */
static ALIAS *findalias(name)
	char *name;
{
	ALIAS *alias;
	int count = aliascount;

	for (alias = aliastable; count-- > 0; alias++) {
		if (strcmp(name, alias->name) == 0)
			return alias;
	}
	return NULL;
}

void do_source(argc, argv)
	int argc;
	char **argv;
{
	in_script;
	readfile(argv[1]);
	not_in_script;
}

#ifdef CMD_EXEC
void do_exec(argc, argv)
	int argc;
	char **argv;
{
	char *name = argv[1];

	if (access(name, 4)) {
		perror(name);
		return;
	}
	closefiles();
	execv(name, argv);
	perror(name);
	exit(1);
}
#endif

void do_prompt(argc, argv)
	char **argv;
{
	char *cp, buf[CMDLEN];

	if (!makestring(argc - 1, argv + 1, buf, CMDLEN))
		return;
	if ((cp = malloc(strlen(buf) + 2)) == NULL) {
		fprintf(stderr, "No memory for prompt\n");
		return;
	}
	strcpy(cp, buf);
	strcat(cp, " ");
	if (prompt)
		free(prompt);
	prompt = cp;
}

void wr1(s)
	char *s;
{
	write(STDOUT, s, strlen(s));
}

/*
 * Display the prompt string.
 */
static void showprompt() {
	wr1(prompt ? prompt : "> ");
}

static void catchint(t) 
	signal_t t;
{
	signal(SIGINT, catchint);
	intflag = TRUE;
	if (intcrlf)
		wr1("\n");
}

static void catchquit(t) 
	signal_t t;
{
	signal(SIGQUIT, catchquit);
	intflag = TRUE;
	if (intcrlf)
		wr1("\n");
}

#ifdef PIPECMD
static BOOL pipecmd(argc, argv)
	int argc;
	char *argv[];
{
	int i, npipes = 0, pipe_fd[2], pid1, pid2, thepipe;
	
	for (i=0; i < argc; i++) if (!strcmp(argv[i], "|")) {
		npipes++;
		thepipe = i;
	}
	if (npipes == 0) return FALSE;
	if (npipes > 1) {
		printf("sh: only one pipe allowed\n");
		return TRUE;
	}
	if (pipe(pipe_fd) < 0) {
		perror("pipe failed");
		return TRUE;
	}
	if ((pid1 = fork()) < 0) {
		perror("fork failed");
		goto piperr;
	}
	if (!pid1) {
		closefiles();
		close(pipe_fd[0]);	/* close pipe_read, stdout */
		close(1);		/* stdout = pipe_write */
		dup2(pipe_fd[1], 1);
		argv[thepipe] = 0;
		_coption = FALSE;
		command2(thepipe, argv);
		exit(1);
	}
	if ((pid2 = fork()) < 0) {
		perror("fork failed");
		goto piperr;
	}
	if (!pid2) {
		closefiles();
		close(pipe_fd[1]);	/* close pipe_write, stdin */
		close(0);		/* stdin = pipe_read */
		dup2(pipe_fd[0], 0);
		for (i = thepipe+1; i < argc; i++) argv[i-thepipe-1] = argv[i];
		i = argc - thepipe - 1;
		argv[i] = 0;
		_coption = FALSE;
		command2(i, argv);
		exit(1);
	}
	close(pipe_fd[1]);
	close(pipe_fd[0]);
	for (i=0; i<2;) if ((npipes=wait(&thepipe))==pid1 || npipes==pid2) i++;
piperr:		close(pipe_fd[0]);
		close(pipe_fd[1]);
		return TRUE;
}		
#endif

void reportchildexit(int pid, int status) {
	if (status & 0x00ff) {
		fprintf(stderr, "pid %d: %s (signal %d)\n", pid,
				(status & 0x80) ? "core dumped" : "killed",
				(status & 0x7f));
	} else {
		fprintf(stderr, "pid %d: Done\n");
	}
}

/* Setup redirection */
int redir(argc, argv)
	int *argc;
	char *argv[];
{
	int i, redirected, fd, ffd, total;
	char *err;
	
	total = 0;
	redirected = 0;
	stdinfd_bkp = -1;
	stdoutfd_bkp = -1;
	for (i = 1; i < *argc; i++) {
		if (!strcmp(argv[i],"<")) {
			fd = open(argv[i+1], O_RDONLY);
			ffd = fileno(stdin);
			redirected = 1;
		}
		if (!strcmp(argv[i],">")) {
			fd = creat(argv[i+1], 0666);
			ffd = fileno(stdout);
			redirected = 1;
		}
		if (!strcmp(argv[i],">>")) {
			fd = open(argv[i+1], O_WRONLY|O_APPEND);
			ffd = fileno(stdout);
			redirected = 1;
		}
		if (redirected) {
			if (fd < 0) {
				err = argv[i+1];
				goto redirerr;
			}
			if (ffd == fileno(stdout)) {
				stdoutfd_bkp=dup(ffd);
			}
			if (ffd == fileno(stdin)) {
				stdinfd_bkp=dup(ffd);
			}
			if (dup2(fd, ffd) < 0) {
				err = "redirection";
redirerr:			restoreredir();
				perror(err);
				return -1;
			}
			close(fd);
			argv[i] = 0;
			argv[i+1] = 0;
			total += 2;
		}
		redirected = 0;
	}
	*argc = *argc - total;
	return 0;
}

static void restoreredir() {
	if (stdinfd_bkp != -1) {
		close(STDIN_FILENO);
		dup2(stdinfd_bkp, STDIN_FILENO);
		close(stdinfd_bkp);
		stdinfd_bkp = -1;
	}
	if (stdoutfd_bkp != -1) {
		close(STDOUT_FILENO);
		dup2(stdoutfd_bkp, STDOUT_FILENO);
		close(stdoutfd_bkp);
		stdoutfd_bkp = -1;
	}
}

/* Execute the specified command */
static void runcmd(argc, argv)
	int argc;
	char *argv[];
{
	int pid1 = 0, pid2 = 0, status = 0, bgp = 0;
#if 0
	register char *cp;
	BOOL magic = FALSE;

	for (cp = cmd; *cp; cp++) {
		if ((*cp >= 'a') && (*cp <= 'z') ||
		    (*cp >= 'A') && (*cp <= 'Z') ||
		    isdecimal(*cp) ||
		    isblank(*cp))
			continue;
		if ((*cp == '.') || (*cp == '/') || (*cp == '-') ||
		    (*cp == '+') || (*cp == '=') || (*cp == '_') ||
		    (*cp == ':') || (*cp == ','))
			continue;
		magic = TRUE;
	}
	if (magic) {
		printf("%s: no such file or directory\n", cmd);
		return;
	}
#endif
	/* No magic characters in the command, so do the fork and exec ourself.
	 * If this fails with ENOEXEC, then run the shell anyway since it might
	 * be a shell script.
	 */
	bgp = (strcmp(argv[argc-1],"&") == 0);
	if (bgp) argv[--argc] = 0; 
	if ((pid1 = fork()) < 0) {
		perror("fork failed");
		return;
	}
	if (pid1) {
		status = 0;
		intcrlf = FALSE;
		if (bgp)
			printf("[%d]: %s\n", pid1, argv[0]);
		else {
			for (;;) {
				pid2 = wait(&status);
				if (pid2 == pid1) break;
				if (pid2 < 0) {
					if (errno == EINTR) continue;
					break;
				}
				reportchildexit(pid2, status);
			}
			if (status & 0x00ff) reportchildexit(pid1, status);
		}
		intcrlf = TRUE;
		ioctl(STDIN_FILENO, TTY_COOKED);
		return;
	}
	/* We are the child, so run the program. */
	/* First close any extra file descriptors we have opened. */
	/* UZIX maintins a global list of opened files. So we can't close
	 * the script file, if we are under a script.
	 */
	while (--sourcecount >= 0) {
		if (sourcefiles[sourcecount] != stdin
#ifdef UZIX
			&& ((inscript && sourcefiles[sourcecount] != scriptfd) || !inscript)
#endif
			)
				fclose(sourcefiles[sourcecount]);
	}
	/* Redirect the output and input if specified and execute application */
	if (redir(&argc, argv) == 0) execfile(argc, argv);
	exit(1);
}

/* Try to execute a built-in command.
 * Returns TRUE if the command is a built in, whether or not the
 * command succeeds.  Returns FALSE if this is not a built-in command.
 */
static BOOL trybuiltin(argc, argv)
	int argc;
	char **argv;
{
	char *newargv[MAXARGS+1];
	int oac, newargc, matches, redirstat;
	CMDTAB *cmdptr = cmdtab - 1;

	do {
		cmdptr++;
		if (cmdptr->name == NULL) {
			++cmdptr;
			break;
		}
	} while (strcmp(argv[0], cmdptr->name));

	/* Give a usage string if the number of arguments is
	 * too large or too small (or --help given).
	 */
	redirstat = redir(&argc, argv);
	if ((argc < cmdptr->minargs) || (argc > cmdptr->maxargs) ||
	    argc == 2 && !strcmp(argv[1], "--help") && cmdptr->func != runcmd) {
		fprintf(stderr, "usage: %s %s\n",
			cmdptr->name, cmdptr->usage);
builtinend:	restoreredir();
		return TRUE;
	}
	/* Check here for several special commands which do not
	 * have wildcarding done for them.
	 */
	if (
	    (cmdptr->func == do_prompt)
#ifdef CMD_ALIAS
		|| (cmdptr->func == do_alias)
#endif
#ifdef CMD_LS_LIGHT
		|| (cmdptr->func == do_ls)
#endif
	) {
		if (redirstat == 0) {
			(*cmdptr->func)(argc, argv); 
			goto builtinend;
		}
		return TRUE;
	}
	/* Now for each command argument, see if it is a wildcard, and if so,
	 * replace the argument with the list of matching filenames.
	 */
	newargv[0] = argv[0];
	newargc = 1;
	for (oac = 0; ++oac < argc; ) {
		if ((matches = expandwildcards(argv[oac], MAXARGS - newargc, 
					newargv + newargc)) < 0)
			return TRUE;
		if ((newargc + matches) >= MAXARGS) {
			fprintf(stderr, "Too many arguments\n");
			goto builtinend;
		}
		if (matches == 0)
			newargv[newargc++] = argv[oac];
		else	newargc += matches;
	}
	newargv[newargc] = NULL;
	if (redirstat == 0) {
		(*cmdptr->func)(newargc, newargv);
		goto builtinend;
	}
	return TRUE;
}

/* Parse and execute one null-terminated command line string.
 * This breaks the command line up into words and go execute it,
 * being it a builtin command, alias or external application.
 */
static void command(cmd)
	char *cmd;
{
	char **argv;
	int argc;
	
	intflag = FALSE;
	freechunks();
	while (isblank(*cmd))
		cmd++;
	if ((*cmd == '\0') || !makeargs(cmd, &argc, &argv))
		return;
	command2(argc, argv);
}

/*
 * This checks to see if the command is an alias, expands wildcards
 * and executes the command.
 */
static void command2(argc, argv)
	int argc;
	char *argv[];
{
	ALIAS *alias;
	int s;
	char *buf, *cmd;
	
	/* Search for the command in the alias table. If it is found,
	 * then replace the command name with the alias, and append
	 * any other arguments to it.
	 */
	if ((alias = findalias(argv[0])) != NULL) {
		if ((buf = malloc(PATHLEN+1)) == NULL) {
			fprintf(stderr, "No memory\n");
			return;
		}
		cmd = strcpy(buf, alias->value);
		while (--argc > 0) {
			strcat(cmd, " ");
			strcat(cmd, *++argv);
		}
		s = makeargs(cmd, &argc, &argv);
		free(buf);
		if (!s)
			return;
	}
	/* Now look for the command in the builtin table,
	 * and execute the command if found.
	 */
#ifdef PIPECMD
	if (pipecmd(argc, argv)) return;
#endif
	if (trybuiltin(argc, argv))
		return;
	/* Not found, run the program along the PATH list. */
	if (_coption) {
		if (!access(argv[0], 4)) execvp(argv[0], argv);
		perror(argv[0]);
		return;
	}
	runcmd(argc, argv); 
}

/* Read commands from the specified file.
 * A null name pointer indicates to read from stdin.
 */
static void readfile(name)
	char *name;
{
	FILE *fp;
	int cc, pid;
	BOOL ttyflag;
	/* making buf static doesn't causes stack going 512 bytes deep */
#ifdef MSX_UZIX_TARGET
	static char buf[CMDLEN];
	static char bufold[CMDLEN];
#else
	char buf[CMDLEN];
	char bufold[CMDLEN];
#endif

	if (sourcecount >= MAXSOURCE) {
		fprintf(stderr, "SASH: nesting too deep\n");
		return;
	}
	fp = stdin;
	if (name) {
		if ((fp = fopen(_findPath(name), "r")) == NULL) {
			perror(name);
			return;
		}
	}
	sourcefiles[sourcecount++] = fp;
#ifdef UZIX
	if (inscript) scriptfd = fp;
#endif
	ttyflag = isatty(fileno(fp));
	while (TRUE) {
		if (ttyflag) {
			fflush(stdout);
			showprompt();
		}
		if (intflag && !ttyflag && (fp != stdin)) {
			fclose(fp);
			sourcecount--;
			return;
		}
		memset(buf, 0, CMDLEN);
		if (fgets(buf, CMDLEN - 1, fp) == NULL) {
			if (ferror(fp) && (errno == EINTR)) {
				clearerr(fp);
				continue;
			}
			break;
		}
		cc = strlen(buf);
		if (buf[cc - 1] == '\n')
			cc--;
		while ((cc > 0) && isblank(buf[cc - 1]))
			cc--;
		buf[cc] = '\0';
		if (buf[0]=='!' && buf[1]=='!') {
			cc = CMDLEN - 1 - strlen(buf) + 2 - strlen(bufold);
			if (cc > 0) {
				strcat(bufold, &buf[2]);
				strcpy(buf, bufold);
			} else strcpy(buf, bufold);
		}
		if (buf[0] != 0) strcpy(bufold, buf);
		if (buf[0] != '#') command(buf);
		pid = waitpid(WAIT_ANY, &cc, WNOHANG);
		if (pid > 0) reportchildexit(pid, cc);
	}
	if (ferror(fp)) {
		perror("Reading command line");
		if (fp == stdin)
			exit(1);
	}
	clearerr(fp);
	if (fp != stdin)
		fclose(fp);
	sourcecount--;
}

void readprofile(path, name)
	char *path, *name;
{
	char *buf;

	if ((buf = malloc(PATHLEN+1)) == NULL) {
		fprintf(stderr, "SASH: no memory for profile %s\n", name);
		exit(1);
	}
	/* read profile */
	strcpy(buf, path);
	if (buf[strlen(buf)-1]!='/') strcat(buf, "/");
	strcat(buf, name);
	if ((access(buf, 0) == 0) || (errno != ENOENT)) {
		in_script;
		readfile(buf);
		not_in_script;
	}
	free(buf);
}

void main(argc, argv)
	int argc;
	char **argv;
{
	char *cp, *buf;
	int i = 0;

	if (argc == 1) {
		printf("SASH (ver. %s)\n", version);
		fflush(stdout);
	}

	signal(SIGINT, catchint);
	signal(SIGQUIT, catchquit);

	if (getenv("PATH") == NULL)
		setenv("PATH", _PATH_DEFPATH, 0);
	if (getenv("SH") == NULL) {
		setenv("SH", _PATH_BSHELL, 0);
		i = 1;
	}
	if ((cp = getenv("HOME")) != NULL) {
		readprofile(cp, ".aliasrc");
		readprofile(cp, ".sashrc");
	}
	if (strcmp(argv[1],"-c") == 0) {
		if ((buf = malloc(PATHLEN+1)) == NULL) {
			fprintf(stderr, "SASH: no memory for prompt\n");
			exit(1);
		}
		strcpy(buf, "");
		for (i = 2; i < argc; i++) {
			strcat(buf, argv[i]);
			strcat(buf, " ");
		}
		strcat(buf,"\0");
		_coption = TRUE;
		command(buf);
		free(buf);
		exit(0);
	}
	if (i == 1) readprofile(cp, ".loginrc");
	if ((cp = getenv("USER")) != NULL) {
		struct utsname name;
		
		if ((buf = malloc(20)) != NULL) {
			strcpy(buf, "");
			strcpy(buf, cp);
			strcat(buf, "@");
			if (uname(&name) != -1) {
				strcat(buf, name.nodename);
				strcat(buf, "$");
				cp = argv[1];
				argv[1] = buf;
				do_prompt (2, argv);
				argv[1] = cp;
			}
			free(buf);
		}
	}
	if (argc > 1) do_source(argc, argv); else readfile(NULL);
	exit(0);
}

