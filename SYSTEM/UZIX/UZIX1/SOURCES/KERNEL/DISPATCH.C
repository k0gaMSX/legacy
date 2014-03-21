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
 Dispatch table for system calls
**********************************************************/

#define NEED__DISPATCH
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#endif
#include "unix.h"
#include "extern.h"

typedef int (*DT)(void);

#define P(a)
#define X(f)	((DT)(f))

GBL DT disp_tab[] = {
/*00*/	X(sys_access)	P((char *path, mode_t mode)),
	X(sys_alarm)	P((uint secs)),
	X(sys_brk)	P((char *addr)),
	X(sys_chdir)	P((char *dir)),
	X(sys_chmod)	P((char *path, mode_t mode)),
/*05*/	X(sys_chown)	P((char *path, int owner, int group)),
	X(sys_close)	P((int uindex)),
	X(sys_getset)	P((int what, int parm)),
	X(sys_dup)	P((int oldd)),
	X(sys_dup2)	P((int oldd, int newd)),
/*10*/	X(sys_execve)	P((char *name, char *argv[], char *envp[])),
	X(sys_exit)	P((int val)),
	X(sys_fork)	P((void)),
	X(sys_statfstat)	P((int fd, char *buf)),
	X(sys_getfsys)	P((int dev, struct info_t *buf)),
/*15*/	X(sys_ioctl)	P((int fd, int request, void *data)),
	X(sys_kill)	P((int pid, int sig)),
	X(sys_link)	P((char *oldname, char *newname)),
	X(sys_mknod)	P((char *name, mode_t mode, int dev)),
	X(sys_mountumount)	P((char *spec, char *dir, int rwflag)),
/*20*/	X(sys_open)	P((char *name, int flag)),
	X(sys_pause)	P((void)),
	X(sys_pipe)	P((int fildes[2])),
	X(sys_readwrite)	P((int d, char *buf, uint nbytes)),
	X(sys_sbrk)	P((uint incr)),
/*25*/	X(sys_lseek)	P((int file, off_t offset, int whence)),
	X(sys_signal)	P((int sig, int (*func)())),
	X(sys_statfstat)	P((char *path, char *buf)),
	X(sys_stime)	P((time_t *tvec)),
	X(sys_sync)	P((void)),
/*30*/	X(sys_time)	P((time_t *tvec)),
	X(sys_times)	P((struct tms *buf)),
	X(sys_mountumount)	P((char *spec)),
	X(sys_unlink)	P((char *path)),
	X(sys_utime)	P((char *path, struct utimbuf *)),
/*35*/	X(sys_waitpid)	P((int pid, int *statloc, int options)),
	X(sys_readwrite)	P((int d, char *buf, uint nbytes)),
	X(sys_reboot)	P((char p1, char p2)),
	X(sys_symlink)	P((char *oldname, char *newname)),
/*39*/	X(sys_chroot)	P((char *path)),
#ifdef UZIX_MODULE
	X(sys_reg)	P((uint sig, int(*func)())),
	X(sys_dereg)	P((uint sig)),
	X(sys_callmodu)	P((uint sig, uint fcn, char *args, int argsize)),
	X(sys_repfmodu) P((int pid, int fcn, char *repladdr, int replysize)),
/*44*/	X(sys_modreply) P((uint sig, int fcn, char *repladdr)),
#endif
};

GBL uchar dtsize = sizeof(disp_tab)/sizeof(disp_tab[0]);

#if DEBUG > 1
GBL char *disp_names[] = {
/*00*/	"access",
	"alarm",
	"brk",
	"chdir",
	"chmod",
/*05*/	"chown",
	"close",
	"getset",
	"dup",
	"dup2",
/*10*/	"execve",
	"exit",
	"fork",
	"fstat",
	"getfsys",
/*15*/	"ioctl",
	"kill",
	"link",
	"mknod",
	"mount",
/*20*/	"open",
	"pause",
	"pipe",
	"read",
	"sbrk",
/*25*/ 	"seek",
	"signal",
	"stat",
	"stime",
	"sync",
/*30*/	"time",
	"times",
	"umount",
	"unlink",
	"utime",
/*35*/	"waitpid",
	"write",
	"reboot",
	"symlink",
/*39*/	"chroot",
#ifdef UZIX_MODULE
	"reg",
	"dereg",
	"callmodu",
	"repfmodu",
/*44*/	"modreply",
#endif
};
#endif

