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

#define NEED__SCALL
#define NEED__DEVIO
#define NEED__DEVFLOP
#define NEED__FILESYS

#include "uzix.h"
#ifdef _MSX_DOS
#include "..\include\stdio.h"
#include "..\include\stdlib.h"
#include "signal.h"
#include "fcntl.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#endif
#include "xfs.h"

char *stringerr[] = {
	"0",
	"1 Operation not permitted",
	"2 No such file or directory",
	"3 No such process",
	"4 Interrupted system call",
	"5 I/O error",
	"6 No such device or address",
	"7 Arg list too long",
	"8 Exec format error",
	"9 Bad file number",
	"10 No child processes",
	"11 Try again",
	"12 Out of memory",
	"13 Permission denied",
	"14 Bad address",
	"15 Block device required",
	"16 Device or resource busy",
	"17 File exists",
	"18 Cross-device link",
	"19 No such device",
	"20 Not a directory",
	"21 Is a directory",
	"22 Invalid argument",
	"23 File table overflow",
	"24 Too many open files",
	"25 Not a typewriter",
	"26 Text file busy",
	"27 File too large",
	"28 No space left on device",
	"29 Illegal seek",
	"30 Read-only file system",
	"31 Too many links",
	"32 Broken pipe",
	"33 Math argument out of domain of func",
	"34 Math result not representable",
	"35 Resource deadlock would occur",
	"36 File name too long",
	"37 No record locks available",
	"38 Function not implemented",
	"39 Directory not empty",
	"40 Too many symbolic links encountered",
	"41 It's a shell script"
};

GBL void xfs_init(bootdev, waitfordisk)
	dev_t bootdev;
	uchar waitfordisk;
{
	arch_init();
	bufinit();
	d_init();
	/* User's file table */
	bfill(udata.u_files, -1, sizeof(udata.u_files));
	/* Open the console tty device */
	if (d_open(TTYDEV) != 0)
		panic("no tty");
	if ((root_dev = bootdev) != (NULLDEV)) {
#ifdef _MSX_DOS
		if (waitfordisk) {
			printf("Insert disk and press RETURN: ");
			while (getchar() != '\n')
				;
		}
#endif
		/* Mount the root device */
		if (fmount(root_dev, NULL, 0))
			panic("no filesys");
		if ((root_ino = i_open(root_dev, ROOTINODE)) == 0)
			panic("no root");
		udata.u_cwd = root_ino;
		udata.u_root = root_ino;
		i_ref(root_ino);
	}
	rdtime(&udata.u_time);
}

GBL void xfs_end(void) {
	register int j;

	for (j = 0; j < UFTSIZE; ++j) {
		if ((udata.u_files[j] & 0x80) == 0)
			doclose(j);
	}
	UZIXsync();		/* Not necessary, but a good idea. */
}

GBL int UZIXopen(name, flag)
	char *name;
	int flag;
{
	udata.u_argn1 = (uint)name;
	udata.u_argn2 = (uint)flag;
	udata.u_argn3 = (uint)0;
	return sys_open();
}

GBL int UZIXclose(uindex)
	int uindex;
{
	udata.u_argn1 = uindex;
	return sys_close();
}

GBL int UZIXcreat(name, mode)
	char *name;
	mode_t mode;
{
	udata.u_argn1 = (uint)name;
	udata.u_argn2 = O_CREAT|O_WRONLY|O_TRUNC;
	udata.u_argn3 = (uint)mode;
	return sys_open();
}

GBL int UZIXlink(name1, name2)
	char *name1;
	char *name2;
{
	udata.u_argn1 = (uint)name1;
	udata.u_argn2 = (uint)name2;
	return sys_link();
}

GBL int UZIXsymlink(name1, name2)
	char *name1;
	char *name2;
{
	udata.u_argn1 = (uint)name1;
	udata.u_argn2 = (uint)name2;
	return sys_symlink();
}

GBL int UZIXunlink(path)
	char   *path;
{
	udata.u_argn1 = (uint)path;
	return sys_unlink();
}

GBL int UZIXread(d, buf, nbytes)
	int d;
	char *buf;
	uint nbytes;
{
	udata.u_argn1 = (uint)d;
	udata.u_argn2 = (uint)buf;
	udata.u_argn3 = (uint)nbytes;
	udata.u_callno = 23;
	return sys_readwrite();
}

GBL int UZIXwrite(d, buf, nbytes)
	int d;
	char *buf;
	uint nbytes;
{
	udata.u_argn1 = (uint)d;
	udata.u_argn2 = (uint)buf;
	udata.u_argn3 = (uint)nbytes;
	udata.u_callno = 36;
	return sys_readwrite();
}

GBL off_t UZIXlseek(file, offset, flag)
	int file;
	off_t offset;
	int flag;
{
	udata.u_argn1 = (uint)file;
	udata.u_argn2 = (uint)offset;
	udata.u_argn3 = (uint)(offset >> 16);
	udata.u_argn4 = (uint)flag;
	return sys_lseek();
}

GBL int UZIXchdir(dir)
	char *dir;
{
	udata.u_argn1 = (uint)dir;
	return sys_chdir();
}

GBL int UZIXmknod(name, mode, dev)
	char *name;
	mode_t mode;
	int dev;
{
	udata.u_argn1 = (uint)name;
	udata.u_argn2 = (uint)mode;
	udata.u_argn3 = (uint)dev;
	return sys_mknod();
}

GBL void UZIXsync() {
	sys_sync();
}

GBL int UZIXaccess(path, mode)
	char *path;
	int mode;
{
	udata.u_argn1 = (uint)path;
	udata.u_argn2 = (uint)mode;
	return sys_access();
}

GBL int UZIXchmod(path, mode)
	char *path;
	mode_t mode;
{
	udata.u_argn1 = (uint)path;
	udata.u_argn2 = (uint)mode;
	return sys_chmod();
}

GBL int UZIXchown(path, owner, group)
	char *path;
	int owner;
	int group;
{
	udata.u_argn1 = (uint)path;
	udata.u_argn2 = (uint)owner;
	udata.u_argn3 = (uint)group;
	return sys_chown();
}

GBL int UZIXstat(path, buf)
	char *path;
	void *buf;
{
	udata.u_argn1 = (uint)path;
	udata.u_argn2 = (uint)buf;
	udata.u_callno = 27;
	return sys_statfstat();
}

GBL int UZIXfstat(fd, buf)
	int fd;
	void *buf;
{
	udata.u_argn1 = (uint)fd;
	udata.u_argn2 = (uint)buf;
	udata.u_callno = 13;
	return sys_statfstat();
}

GBL int UZIXdup(oldd)
	int oldd;
{
	udata.u_argn1 = (uint)oldd;
	return sys_dup();
}

GBL int UZIXdup2(oldd, newd)
	int oldd;
	int newd;
{
	udata.u_argn1 = (uint)oldd;
	udata.u_argn2 = (uint)newd;
	return sys_dup2();
}

GBL int UZIXumask(mask)
	int mask;
{
	udata.u_argn1 = (uint)SET_UMASK;
	udata.u_argn2 = (uint)mask;
	return sys_getset();
}

GBL int UZIXgetfsys(dev, buf)
	dev_t dev;
	void *buf;
{
	udata.u_argn1 = (uint)dev;
	udata.u_argn2 = (uint)buf;
	return sys_getfsys();
}

GBL int UZIXioctl(fd, request, data)
	int fd;
	int request;
	void *data;
{
	udata.u_argn1 = (uint)fd;
	udata.u_argn2 = (uint)request;
	udata.u_argn3 = (uint)data;
	return sys_ioctl();
}

GBL int UZIXmount(spec, dir, rwflag)
	char *spec;
	char *dir;
	int rwflag;
{
	udata.u_argn1 = (uint)spec;
	udata.u_argn2 = (uint)dir;
	udata.u_argn3 = (uint)rwflag;
	udata.u_callno = 19;
	return sys_mountumount();
}

GBL int UZIXumount(spec)
	char *spec;
{
	udata.u_argn1 = (uint)spec;
	udata.u_callno = 32;
	return sys_mountumount();
}

GBL int UZIXtime(tvec)
	void *tvec;
{
	udata.u_argn1 = (uint)tvec;
	return sys_time();
}

