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
 *
 *	@(#)ls.h	5.10 (Berkeley) 4/8/90
 */

#define printfcn p_fcn
#define printtype p_type
#define printtime p_time
#define printlink p_link
#define printlong p_long
#define f_listalldot f_a_d
#define f_listdot    f_dot
#define f_listdir    f_dir

typedef struct _lsstruct {
	char *name;			/* file name */
	int len;			/* file name length */
	struct stat lstat;		/* lstat(2) for file */
	long	st_btotal, 
		st_maxlen;
} LS;

/*
 * overload -- we probably have to save blocks and/or maxlen with the lstat
 * array, so tabdir() stuffs it into unused fields in the first stat structure.
 * If there's ever a type larger than u_long, fix this.  Any calls to qsort
 * must save and restore the values.
 */
/*
#define	st_btotal	st_flags
#define	st_maxlen	st_gen
*/

extern int errno;

extern int f_accesstime;	/* use time of last access */
extern int f_group;		/* show group ownership of a file */
extern int f_inode;		/* print inode */
extern int f_kblocks;		/* print size in kilobytes */
extern int f_longform;		/* long listing format */
extern int f_singlecol;		/* use single column output */
extern int f_size;		/* list size in short listing */
extern int f_statustime;	/* use time of last mode change */
extern int f_total;		/* if precede with "total" line */
extern int f_type;		/* add type character for non-regular files */

#ifndef S_ISDIR
#define S_ISDIR(n)  (((n)&F_MASK) == F_DIR)
#endif
#ifndef S_ISBLK
#define S_ISBLK(n)  (((n)&F_MASK) == F_BDEV)
#endif
#ifndef S_ISCHR
#define S_ISCHR(n)  (((n)&F_MASK) == F_CDEV)
#endif

#define cmpfunc(x)	x(LS *a, LS *b)

void doargs(int argc, char **argv);
void usage();
void nomem();
int cmpfunc(namecmp);
int cmpfunc(revnamecmp);
int cmpfunc(modcmp);
int cmpfunc(revmodcmp);
int cmpfunc(acccmp);
int cmpfunc(revacccmp);
int cmpfunc(statcmp);
int cmpfunc(revstatcmp);
void printscol(LS *stats, int num);
void printlong(LS *stats, int num);
void printcol(LS *stats, int num);
void displaydir(LS *stats, int num);
void prcopy(char *src, char *dest, int len);
void bcopy(char *src, char *dest, int len);
void subdir (LS *lp);
int tabdir(LS *lp, LS **s_stats, char **s_names);
char s_elect(int *pairp, int st);
int printaname(LS *lp);
void printtime(time_t *ftime);
int printtype(int mode);
void printlink(char *name);
