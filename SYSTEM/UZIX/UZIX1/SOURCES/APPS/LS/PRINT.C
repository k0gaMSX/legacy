/*
 * Copyright (c) 1989 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Michael Fischbein.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that: (1) source distributions retain this entire copyright
 * notice and comment, and (2) distributions including binaries display
 * the following acknowledgement:  ``This product includes software
 * developed by the University of California, Berkeley and its contributors''
 * in the documentation or other materials provided with the distribution
 * and in all advertising materials mentioning features or use of this
 * software. Neither the name of the University nor the names of its
 * contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef lint
static char sccsid[] = "@(#)print.c	5.22 (Berkeley) 5/10/90";
#endif /* not lint */

#include <types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <pwd.h>
#include <grp.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
/*
#include <utmp.h>
#include <tzfile.h>
*/
#include "ls.h"

#define UT_NAMESIZE 4

#ifdef _UZI_280_
char *user[11] = {
		"root","usr1","usr2","usr3","usr4","usr5",
		"usr6","usr7","usr8","usr9","none"
		};
#endif

char *
user_from_uid(uid,n)
unsigned uid,n;
{
	return(getpwuid(uid)->pw_name);
}	

char *
group_from_gid(gid,n)
{
#ifdef _UZI_280_
	return(user_from_uid(gid,n));
#else
	return(getgrgid(gid)->gr_name);
#endif
}

#define	SUID	04000
#define	SGID	02000
#define	ROWN	0400
#define	WOWN	0200
#define	XOWN	0100
#define	RGRP	040
#define	WGRP	020
#define	XGRP	010
#define	ROTH	04
#define	WOTH	02
#define	XOTH	01
#define	STXT	01000
int	m1[] = { 1, ROWN, 'r', '-' };
int	m2[] = { 1, WOWN, 'w', '-' };
int	m3[] = { 2, SUID, 's', XOWN, 'x', '-' };
int	m4[] = { 1, RGRP, 'r', '-' };
int	m5[] = { 1, WGRP, 'w', '-' };
int	m6[] = { 2, SGID, 's', XGRP, 'x', '-' };
int	m7[] = { 1, ROTH, 'r', '-' };
int	m8[] = { 1, WOTH, 'w', '-' };
int	m9[] = { 2, STXT, 't', XOTH, 'x', '-' };

int	*m[] = { m1, m2, m3, m4, m5, m6, m7, m8, m9};

strmode(st,modep)
int st;
char * modep;
{
	register int **mp;
	int n;

	n = 0;
	for (mp = &m[0]; mp < &m[9];) {
		modep[n] = s_elect(*mp++, st);
		n++;
	}
	modep[n]=0;
}

char 
s_elect(pairp, st)
int *pairp;
int st;
{
	register int n, *ap;

	ap = pairp;
	n = *ap++;
	while (--n>=0 && (st&*ap++)==0)
		ap++;
	return *ap; 
}

	
void printscol(stats, num)
	register LS *stats;
	register int num;
{
	for (; num--; ++stats) {
		(void)printaname(stats);
		(void)putchar('\n');
	}
}

void printlong(stats, num)
	LS *stats;
	register int num;
{
	char modep[15];

	if (f_total)
		(void)printf("total %ld\n", 
		    stats[0].st_btotal/1024l);
	for (; num--; ++stats) {
		if (f_inode)
			(void)printf("%6u ", stats->lstat.st_ino);
		if (f_size)
			(void)printf("%8ld ", 
			    stats->lstat.st_size);
		(void)strmode(stats->lstat.st_mode, modep);
		(void)printf("%s %3u %-10s ", modep, stats->lstat.st_nlink,
		    user_from_uid(stats->lstat.st_uid, 0));
		if (f_group)
			(void)printf("%-10s ",
			    group_from_gid(stats->lstat.st_gid, 0));
		if (S_ISDEV(stats->lstat.st_mode))
			(void)printf("%3d, %-3d ", (stats->lstat.st_rdev >> 8),
			    (stats->lstat.st_rdev & 0xFF));
		else
			(void)printf("%8ld ", 
				stats->lstat.st_size);
		if (f_accesstime)
			printtime(&stats->lstat.st_atime);
		else if (f_statustime)
			printtime(&stats->lstat.st_ctime);
		else
			printtime(&stats->lstat.st_mtime);
		(void)printf("%s", stats->name);
		if (f_type)
			(void)printtype(stats->lstat.st_mode);
		if (S_ISLNK(stats->lstat.st_mode))
			printlink(stats->name);
		(void)putchar('\n');
	}
}

#define	TAB	8

void printcol(stats, num)
	LS *stats;
	int num;
{
	extern int termwidth;
	register int base, chcnt, cnt, col, colwidth;
	int endcol, numcols, numrows, row;

	colwidth = 14 /*(int)stats[0].st_maxlen*/;
	if (f_inode)
		colwidth += 6;
	if (f_size)
		colwidth += 8;
	if (f_type)
		colwidth += 1;

	colwidth = (colwidth + TAB) & ~(TAB - 1);
	if (termwidth < 2 * colwidth) {
		printscol(stats, num);
		return;
	}

	numcols = termwidth / colwidth;
	numrows = num / numcols;
	if (num % numcols)
		++numrows;
	if (f_size && f_total)
		(void)printf("total %ld\n", 
		    stats[0].st_btotal/1024l);
	for (row = 0; row < numrows; ++row) {
		endcol = colwidth;
		for (base = row, chcnt = col = 0; col < numcols; ++col) {
			chcnt += printaname(stats + base);
			if ((base += numrows) >= num)
				break;
			while ((cnt = (chcnt + TAB & ~(TAB - 1))) <= endcol) {
				(void)putchar('\t');
				chcnt = cnt;
			}
			endcol += colwidth;
		}
		putchar('\n');
	}
}

/*
 * print [inode] [size] name
 * return # of characters printed, no trailing characters
 */
int
printaname(lp)
	LS *lp;
{
	int chcnt;

	chcnt = 0;
	if (f_inode) {
		chcnt += 6; 
		printf("%5u ", lp->lstat.st_ino);
	}
	if (f_size) {
		chcnt += 9; 
		printf("%8ld ",
		    lp->lstat.st_size);
	}
	chcnt += strlen(lp->name);
	printf("%s", lp->name);
	
	if (f_type)
		chcnt += printtype(lp->lstat.st_mode);
	return(chcnt);
}

void printtime(ftime)
	time_t *ftime;
{
	int i;
	char *longstring;
	time_t now;

	time(&now);
	longstring = ctime(ftime);
	for (i = 4; i < 11; ++i)
		(void)putchar(longstring[i]);

#define DAYSPERNYEAR	365L
#define SECSPERDAY	86400L
 
#define	SIXMONTHS	((DAYSPERNYEAR / 2L) * SECSPERDAY)
 	if (difftime(ftime, &now) > SIXMONTHS)
		for (i = 11; i < 19; ++i)
			(void)putchar(longstring[i]);
	else {
		for (i = 0; i < 4; ++i) (void)putchar(' ');
		for (i = 20; i < 24; ++i)
			(void)putchar(longstring[i]);
	}
	(void)putchar(' ');
}

int printtype(mode)
	int	mode;
{
	if (f_longform) return(0);
	switch(mode & S_IFMT) {
	case S_IFDIR:
		(void)putchar('/');
		return(1);
#ifdef S_ISLNK
	case S_IFLNK:
		(void)putchar('@');
		return(1);
#endif
#ifdef S_ISSOCK
	case S_IFSOCK:
		(void)putchar('=');
		return(1);
#endif
#ifdef S_ISFIFO
	case S_IFPIPE:
		(void)putchar('|');
		return(1);
#endif
	}
	if (mode & (S_IXUSR | S_IXGRP | S_IXOTH)) {
		(void)putchar('*');
		return(1);
	}
	return(0);
}

#define MAXPATHLEN 20

void printlink(name)
	char *name;
{
	int lnklen = 0;
	char path[MAXPATHLEN + 1];

	if ((lnklen = readlink(name, path, MAXPATHLEN)) == -1) {
		(void)fprintf(stderr, "\nls: %s: %s\n", name, strerror(errno));
		return;
	}
	path[lnklen] = '\0';
	(void)printf(" -> %s", path);
}
