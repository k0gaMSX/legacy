/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * Definitions for stand-alone shell for system maintainance for Linux.
 */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <ctype.h>
#include "sashcfg.h"

#define PATHLEN 	256
#define CMDLEN		256	/* 512 *//* 32k is too little memory... */
#define MAXARGS 	200
#define ALIASALLOC	20
#define STDIN		0
#define STDOUT		1
#define MAXSOURCE	10

#ifndef isblank
#define isblank(ch)	(((ch) == ' ') || ((ch) == '\t'))
#endif
#define isquote(ch)	(((ch) == '"') || ((ch) == '\''))
#ifndef isdecimal
#define isdecimal(ch)	(((ch) >= '0') && ((ch) <= '9'))
#endif
#ifndef isoctal
#define isoctal(ch)	(((ch) >= '0') && ((ch) <= '7'))
#endif

typedef unsigned char BOOL;

#define FALSE	((BOOL) 0)
#define TRUE	((BOOL) 1)

extern	BOOL	intflag;

extern	void	do_alias(int argc, char *argv[]);
extern	void	do_cd(int argc, char *argv[]);
extern	void	do_chroot(int argc, char *argv[]);
extern	void	do_exec(int argc, char *argv[]);
extern	void	do_exit(int argc, char *argv[]);
extern	void	do_prompt(int argc, char *argv[]);
extern	void	do_source(int argc, char *argv[]);
extern	void	do_umask(int argc, char *argv[]);
extern	void	do_unalias(int argc, char *argv[]);
extern	void	do_help(int argc, char *argv[]);
extern	void	do_ln(int argc, char *argv[]);
extern	void	do_cp(int argc, char *argv[]);
extern	void	do_mv(int argc, char *argv[]);
extern	void	do_rm(int argc, char *argv[]);
extern	void	do_chmod(int argc, char *argv[]);
extern	void	do_mkdir(int argc, char *argv[]);
extern	void	do_rmdir(int argc, char *argv[]);
extern	void	do_mknod(int argc, char *argv[]);
extern	void	do_chown(int argc, char *argv[]);
extern	void	do_chgrp(int argc, char *argv[]);
extern	void	do_sync(int argc, char *argv[]);
extern	void	do_more(int argc, char *argv[]);
extern	void	do_cmp(int argc, char *argv[]);
extern	void	do_touch(int argc, char *argv[]);
extern	void	do_trace(int argc, char *argv[]);
extern	void	do_ls(int argc, char *argv[]);
extern	void	do_dd(int argc, char *argv[]);
extern	void	do_tar(int argc, char *argv[]);
extern	void	do_mount(int argc, char *argv[]);
extern	void	do_umount(int argc, char *argv[]);
extern	void	do_setenv(int argc, char *argv[]);
extern	void	do_pwd(int argc, char *argv[]);
extern	void	do_echo(int argc, char *argv[]);
extern	void	do_kill(int argc, char *argv[]);
extern	void	do_grep(int argc, char *argv[]);
extern	void	do_ed(int argc, char *argv[]);
extern	void	do_sleep(int argc, char *argv[]);

extern	void	do_cat(int argc, char *argv[]);
extern	void	do_cat_more(int argc, char *argv[], int mode);

extern	char	*modestring __P((int mode));
extern	char	*timestring __P((time_t *t));
extern	BOOL	isadir __P((char *name));
extern	BOOL	copyfile __P((char *srcname, char *destname, BOOL setmodes));
extern	char	*buildname __P((char *dirname, char *filename));
extern	int	expandwildcards __P((char *name, int maxargc, char **retargv));
extern	int	namesort(char **, char **);
extern	BOOL	match __P((char *text, char *pattern));
extern	BOOL	makeargs __P((char *cmd, int *argcptr, char ***argvptr));
extern	BOOL	makestring __P((int argc, char *argv[], char *buf, int buflen));
extern	char	*getchunk __P((int size));
extern	void	freechunks __P((void));
extern	long	sizeval __P((off_t *));

/* END CODE */
