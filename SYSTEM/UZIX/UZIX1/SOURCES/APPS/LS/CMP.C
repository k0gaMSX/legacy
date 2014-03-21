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
static char sccsid[] = "@(#)cmp.c	5.2 (Berkeley) 4/8/90";
#endif /* not lint */

#include <types.h>
#include <sys/stat.h>
#include <string.h>
#include "ls.h"

int namecmp(a, b)
	LS *a, *b;
{
	return(strcmp(a->name, b->name));
}

int revnamecmp(a, b)
	LS *a, *b;
{
	return(strcmp(b->name, a->name));
}

modcmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined (PC_UZIX_TARGET)
	long n,m;
	n = a->lstat.st_mtime;

	m = b->lstat.st_mtime;

	return (n < m);
#else
	return(a->lstat.st_mtime.t_date < b->lstat.st_mtime.t_date ||
	       a->lstat.st_mtime.t_time < b->lstat.st_mtime.t_time);
#endif
}

revmodcmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined(PC_UZIX_TARGET)
	long n,m;
	n = (long)a->lstat.st_mtime;

	m = (long)b->lstat.st_mtime; 

	return (m < n);
#else
	return(b->lstat.st_mtime.t_time < a->lstat.st_mtime.t_time ||
	       b->lstat.st_mtime.t_date < a->lstat.st_mtime.t_date);
#endif
}

acccmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined(PC_UZIX_TARGET)
	long n,m;
	n = (long)a->lstat.st_atime;

	m = (long)b->lstat.st_atime;

	return (n < m);
#else
	return(a->lstat.st_atime.t_time < b->lstat.st_atime.t_time ||
	       a->lstat.st_atime.t_date < b->lstat.st_atime.t_date);
#endif
}

revacccmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined(PC_UZIX_TARGET)
	long n,m;
	n = (long)a->lstat.st_atime;

	m = (long)b->lstat.st_atime; 

	return (m < n);
#else
	return(b->lstat.st_atime.t_time < a->lstat.st_atime.t_time ||
		b->lstat.st_atime.t_date < a->lstat.st_atime.t_date);
#endif
}

statcmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined(PC_UZIX_TARGET)
	long n,m;
	n = (long)a->lstat.st_ctime;

	m = (long)b->lstat.st_ctime;

	return (n < m);
#else
	return(a->lstat.st_ctime.t_time < b->lstat.st_ctime.t_time ||
		a->lstat.st_ctime.t_date < b->lstat.st_ctime.t_date);
#endif
}

revstatcmp(a, b)
	LS *a, *b;
{
#if !defined(MSX_UZIX_TARGET) && !defined(PC_UZIX_TARGET)
	long n,m;
	n = (long)a->lstat.st_ctime;

	m = (long)b->lstat.st_ctime;

	return (m < n);
#else
	return(b->lstat.st_ctime.t_time < a->lstat.st_ctime.t_time ||
		b->lstat.st_ctime.t_date < a->lstat.st_ctime.t_date);
#endif
}
