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
 UZIX system calls wrappers, used by UZIX utilities
**********************************************************/

#ifndef _XFS_H
#define _XFS_H

#include "uzix.h"
#include "unix.h"
#include "extern.h"

extern char *stringerr[];

extern void xfs_init __P((dev_t bootdev, uchar waitfordisk));
extern void xfs_end __P((void));
extern int UZIXopen __P((char *name, int flag/*, ...*/));
extern int UZIXclose __P((int uindex));
extern int UZIXcreat __P((char *name, mode_t mode));
extern int UZIXlink __P((char *name1, char *name2));
extern int UZIXsymlink __P((char *name1, char *name2));
extern int UZIXunlink __P((char *path));
extern int UZIXread __P((int d, char *buf, uint nbytes));
extern int UZIXwrite __P((int d, char *buf, uint nbytes));
extern int UZIXseek __P((int file, uint offset, int flag));
extern int UZIXchdir __P((char *dir));
extern int UZIXmknod __P((char *name, mode_t mode, int dev));
extern void UZIXsync __P((void));
extern int UZIXaccess __P((char *path, int mode));
extern int UZIXchmod __P((char *path, mode_t mode));
extern int UZIXchown __P((char *path, int owner, int group));
extern int UZIXstat __P((char *path, void *buf));
extern int UZIXfstat __P((int fd, void *buf));
extern int UZIXdup __P((int oldd));
extern int UZIXdup2 __P((int oldd, int newd));
extern int UZIXumask __P((int mask));
extern int UZIXioctl __P((int fd, int request, void *data));
extern int UZIXmount __P((char *spec, char *dir, int rwflag));
extern int UZIXumount __P((char *spec));
extern int UZIXtime __P((void *tvec));

extern int UZIXgetfsys __P((dev_t dev, void *buf));
#endif
