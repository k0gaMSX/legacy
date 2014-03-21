#ifndef __ERRNO_H
#define __ERRNO_H
#ifndef __TYPES_H
#include <types.h>
#endif

/* Error codes */		/*- if not used */
#define EPERM		1		/* 1 Operation not permitted */
#define ENOENT		2		/* 2 No such file or directory */
#define ESRCH		3	/*-*/	/* 3 No such process */
#define EINTR		4		/* 4 Interrupted system call */
#define EIO		5		/* 5 I/O error */
#define ENXIO		6		/* 6 No such device or address */
#define E2BIG		7		/* 7 Arg list too long */
#define ENOEXEC 	8		/* 8 Exec format error */
#define EBADF		9		/* 9 Bad file number */
#define ECHILD		10		/* 10 No child processes */
#define EAGAIN		11		/* 11 Try again */
#define ENOMEM		12		/* 12 Out of memory */
#define EACCES		13		/* 13 Permission denied */
#define EFAULT		14		/* 14 Bad address */
#define ENOTBLK 	15		/* 15 Block device required */
#define EBUSY		16		/* 16 Device or resource busy */
#define EEXIST		17		/* 17 File exists */
#define EXDEV		18		/* 18 Cross-device link */
#define ENODEV		19		/* 19 No such device */
#define ENOTDIR 	20		/* 20 Not a directory */
#define EISDIR		21		/* 21 Is a directory */
#define EINVAL		22		/* 22 Invalid argument */
#define ENFILE		23		/* 23 File table overflow */
#define EMFILE		24	/*-*/	/* 24 Too many open files */
#define ENOTTY		25	/*-*/	/* 25 Not a typewriter */
#define ETXTBSY 	26	/*-*/	/* 26 Text file busy */
#define EFBIG		27	/*-*/	/* 27 File too large */
#define ENOSPC		28		/* 28 No space left on device */
#define ESPIPE		29		/* 29 Illegal seek */
#define EROFS		30	/*-*/	/* 30 Read-only file system */
#define EMLINK		31	/*-*/	/* 31 Too many links */
#define EPIPE		32		/* 32 Broken pipe */
#define EDOM		33	/*-*/	/* 33 Math argument out of domain of func */
#define ERANGE		34	/*-*/	/* 34 Math result not representable */
#define EDEADLK 	35	/*-*/	/* 35 Resource deadlock would occur */
#define ENAMETOOLONG	36	/*-*/	/* 36 File name too long */
#define ENOLCK		37	/*-*/	/* 37 No record locks available */
#define EINVFNC 	38		/* 38 Function not implemented */
#define ENOTEMPTY	39	/*-*/	/* 39 Directory not empty */
#define ELOOP		40	/*-*/	/* 40 Too many symbolic links encountered */
#define ESHELL		41	/*-*/	/* 41 It's a shell script */
#define ENOSYS		EINVFNC

#define __ERRORS	40

extern int sys_nerr;
extern char *sys_errlist[];
extern int errno;

extern char *strerror __P((int _errno));

#endif

