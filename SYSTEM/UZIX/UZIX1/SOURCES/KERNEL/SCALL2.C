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
 Implementation of system calls
**********************************************************/

#define NEED__FILESYS
#define NEED__MACHDEP
#define NEED__PROCESS
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "fcntl.h"
#include "sys\stat.h"
#endif
#include "unix.h"
#include "extern.h"

/* Implementation of system calls */

#define IBLK(ino)	((ino)->c_node.i_size.o_blkno)
#define IOFF(ino)	((ino)->c_node.i_size.o_offset)

/* definitions for 'udata' access */
#define UWHERE		(UDATA(u_offset))
#define UBLK		(UWHERE.o_blkno))
#define UOFF		(UWHERE.o_offset))
#define UBAS		(UDATA(u_base))
#define UCNT		(UDATA(u_count))
#define UERR		(UDATA(u_error))

#ifdef __KERNEL__

GBL int Min __P((int, int));

/* return a pointer to p_tab of process pid only */
/* user must own process pid or be the superuser */
LCL ptptr findprocess(pid)
	int pid;
{
	register ptptr p = ptab;
	while (p < ptab + PTABSIZE) {
		if (p->p_pid == pid) {
			if (UDATA(u_ptab)->p_uid == p->p_uid || super()) {
					return p;
			}
			else {
				UERR = EPERM;
				goto Err;
			}
		}
		++p;
	}
	UERR = EINVAL;
Err:	return NULL;
}

/********************************************
 SYSCALL pipe(int fildes[2]);
*******************************************/
#define fildes ((uint *)UDATA(u_argn1))

LCL void filldesc(uchar oft, uchar access, inoptr ino) {
	oft_t *op;
	
	op = &of_tab[oft];
	op->o_ptr = 0;
	op->o_inode = ino;
	op->o_access = access;
}

GBL int sys_pipe(VOID) {
	uchar u1, u2, oft1 = (uchar)-1, oft2 = (uchar)-1;
	inoptr ino;

	/* uf_alloc doesn't alloc an entry in user file table,
	   just returns the first free entry. so you must set it
	   before allocating another, or you'll get the same entry
	*/

	if ((ino = i_open(root_dev, NULLINO)) == NULL) {
		UERR = ENOMEM;
		goto Err;
	}
	if ((u1 = uf_alloc()) == (uchar)-1 ||
	    (oft1 = oft_alloc()) == (uchar)-1) {
		UERR = ENOENT;
		goto Err1;
	}
	UDATA(u_files)[u1] = oft1;	/* read side */
	filldesc(oft1, O_RDONLY, ino);

	if ((u2 = uf_alloc()) == (uchar)-1 ||
	    (oft2 = oft_alloc()) == (uchar)-1) {
		UDATA(u_files)[u1] = -1; 	/* free user file table entry */
		UERR = ENOENT;
		goto Err2;
	}
	/* fill in pipe descriptors */
	UDATA(u_files)[u2] = oft2;	/* write side */
	filldesc(oft2, O_WRONLY, ino);

	/* No permissions necessary on pipes */
	ino->c_node.i_mode = S_IFPIPE | 0777;
	ino->c_node.i_nlink = 0;	/* a pipe is not in any directory */
	++ino->c_refs;			/* count two sides of pipe */

	fildes[0] = u1;
	fildes[1] = u2;

	return 0;

Err2:	if (oft2 != (uchar)-1) oft_deref(oft2);
Err1:	if (oft1 != (uchar)-1) oft_deref(oft1);
Err:	return (-1);
}
#undef fildes

/**********************************
 SYSCALL stime(time_t *tvec)
**********************************/
#define tvec (time_t *)UDATA(u_argn1)
GBL int sys_stime(VOID) {
	if (super()) {
		sttime(tvec);
		return 0;
	}
	UERR = EPERM;
	return (-1);
}
#undef tvec

/*********************************
 SYSCALL times(struct tms *buf);
*********************************/
#define buf ((struct tms *)UDATA(u_argn1))
GBL int sys_times(VOID) {
	if (valadr(buf, sizeof(struct tms))) {
		_di();
		bcopy(&UDATA(u_utime), buf, 4 * sizeof(time_t));
		bcopy(&ticks, &buf->tms_etime, sizeof(time_t));
		_ei();
		return (0);
	}
	return (-1);
}
#undef buf

/**********************************
 SYSCALL brk(char *addr);
**********************************/
#define addr ((char *)UDATA(u_argn1))
GBL int sys_brk(VOID) {
	auto char dummy;	/* A thing to take address of */

	/* A hack to get approx val of stack ptr. */
	if ((uint)addr < PROGBASE || (addr + 256) >= &dummy) {
		UERR = ENOMEM;
		return (-1);
	}
	UDATA(u_ptab)->p_break = addr;
	UDATA(u_break) = addr;
	return 0;
}
#undef addr

/************************************
 SYSCALL sbrk(uint incr);
************************************/
#define incr UDATA(u_argn1)
GBL int sys_sbrk(VOID) {
	register char *oldbrk = UDATA(u_break);

	if (incr) {
		incr = incr + (uint)oldbrk;
		if ((uint)incr < (uint)oldbrk || sys_brk()) /* argument already on place */
			return (-1);
	}
	return (int)oldbrk;
}
#undef incr

/**************************************
 SYSCALL waitpid(int pid, int *statloc, int options);
**************************************/
#define pid (int)UDATA(u_argn1)
#define statloc (int *)UDATA(u_argn2)
#define options (int)UDATA(u_argn1)
GBL int sys_waitpid(VOID) {
	register ptptr p;

	if (statloc > (int *)UZIXBASE) {
		UERR = EFAULT;
		goto Err;
	}
	_di();
	/* See if we have any children. */
	p = ptab;
	while (p < ptab + PTABSIZE) {
		if ((uchar)(p->p_status) != P_EMPTY &&
		    p->p_pptr == UDATA(u_ptab) &&
		    p != UDATA(u_ptab)) {
			_ei();
			return dowait();
		}
		++p;
	}
	UERR = ECHILD;
	_ei();
Err:	return -1;
}
#undef pid
#undef statloc
#undef options

/**************************************
 SYSCALL exit(int val);
**************************************/
#define val (int)UDATA(u_argn1)
GBL int sys_exit(VOID) {
	doexit(val, 0);
	return -1;
}
#undef val

/**************************************
 SYSCALL fork(void);
**************************************/
GBL int sys_fork(VOID) {
	return dofork();
}

/**************************************
 SYSCALL pause(void);
**************************************/
GBL int sys_pause(VOID) {
	psleep(NULL);	/* P_PAUSE */
	UERR = EINTR;
	return (-1);
}

/****************************************
 SYSCALL signal(int sig, void (*func)());
****************************************/
#define sig (signal_t)UDATA(u_argn1)
#define func (void (*) __P((signal_t)))UDATA(u_argn2)
GBL int sys_signal(VOID) {
	register int retval = -1;

	_di();
	/* SIGKILL & SIGSTOP can't be caught !!!*/
	if (sig == __NOTASIGNAL ||
	   (uchar)sig == SIGKILL ||
	   (uchar)sig > NSIGS) {
		UERR = EINVAL;
		goto Err;
	}
	if (func == SIG_IGN)
		UDATA(u_ptab)->p_ignored |= sigmask(sig);
	else {
		if ((sig_t)func != SIG_DFL &&
		    ((uint)func < PROGBASE ||
		     (uint)func >= UZIXBASE)) {
			UERR = EFAULT;
			goto Err;
		}
		UDATA(u_ptab)->p_ignored = UDATA(u_ptab)->p_ignored & ~(sigmask(sig));
	}
	retval = (int)UDATA(u_sigvec)[sig-1];
	UDATA(u_sigvec)[sig-1] = func;
Err:	_ei();
	return (retval);
}
#undef sig
#undef func

/**************************************
 SYSCALL kill(int pid, int sig);
**************************************/
#define pid (int)UDATA(u_argn1)
#define sig (int)UDATA(u_argn2)
GBL int sys_kill(VOID) {
	register ptptr p;

	if (sig == __NOTASIGNAL || (uchar)sig >= NSIGS || pid <= 1) {
		UERR = EINVAL;
Err:		return -1;
	}
	if ((p = findprocess(pid)) == NULL) goto Err;
	sendsig(p, sig);
	return 0;
}
#undef pid
#undef sig

/********************************
 SYSCALL alarm(uint secs);
********************************/
#define secs (uint)UDATA(u_argn1)
GBL int sys_alarm(VOID) {
	register int retval;

	_di();
	retval = UDATA(u_ptab)->p_alarm;
	UDATA(u_ptab)->p_alarm = secs;
	_ei();
	return retval;
}
#undef secs

/********************************
 SYSCALL reboot(char p1, char p2);
********************************/
#define p1 (char)UDATA(u_argn1)
#define p2 (char)UDATA(u_argn2)
GBL int sys_reboot(VOID) {
	if (p1 == 'm' && p2 == 'e')
		_abort(0);
	return EFAULT;
}
#undef p1
#undef p2

/***********************************
 SYSCALL getset(int what, int parm1 ...);
***********************************/
#define what (int)UDATA(u_argn1)
#define parm1 (int)UDATA(u_argn2)
#define parm2 (int)UDATA(u_argn3)
GBL int sys_getset(VOID) {
	register int old;
	register ptptr p;
	register char nice;

	switch (what) {
	case GET_PID:
		return (UDATA(u_ptab)->p_pid);
	case GET_PPID:
		return (UDATA(u_ptab)->p_pptr->p_pid);
	case GET_UID:
		return (UDATA(u_ptab)->p_uid);
	case SET_UID:
		if (super() || UDATA(u_ptab)->p_uid == parm1) {
			UDATA(u_ptab)->p_uid = parm1;
			UDATA(u_euid) = parm1;
			goto Ok;
		}
		break;
	case GET_EUID:
		return (UDATA(u_euid));
	case GET_GID:
		return (UDATA(u_gid));
	case SET_PRIO:
		/* parm1 = PID, parm2 = nice value */
		if ((p = findprocess(parm1)) == NULL) goto Err;
		nice = Min((char)parm2, PRIO_MAX);
		if (nice < PRIO_MIN) nice = PRIO_MIN;
		if (!super()) if (nice < 0) nice = 0;
		p->p_nice = nice;
		p->p_cprio = (nice < 1) ? 
			(((-nice)*(TICKSPERSEC - MAXTICKS)) / (- PRIO_MIN)) + MAXTICKS
			:
			1 + (((PRIO_MAX - nice) * MAXTICKS) / PRIO_MAX);
		goto Ok;
	case GET_EGID:
		return (UDATA(u_egid));
	case GET_PRIO:
		return (UDATA(u_ptab)->p_cprio); /* must be p_prio */
	case SET_GID:
		if (super() || UDATA(u_gid) == parm1) {
			UDATA(u_gid) = parm1;
			UDATA(u_egid) = parm1;
			goto Ok;
		}
		break;
	case SET_UMASK:
		old = UDATA(u_mask);
		UDATA(u_mask) = parm1 & S_UMASK;
		return old;
	case SET_TRACE:
#if DEBUG > 1
		if (parm1 < 0)			traceon = 1;
		else if (parm1 > 0)		UDATA(u_traceme) = 1;
		else if (UDATA(u_traceme))	UDATA(u_traceme) = 0;
		else				traceon = 0;
#endif
		goto Ok;
	}
	UERR = EPERM;
Err:	return (-1);
Ok:	return 0;
}
#undef what
#undef parm1
#undef parm2
#undef nice

#else
/***********************************
 SYSCALL getset(int what, int parm);
***********************************/
#define what (int)UDATA(u_argn1)
#define parm (int)UDATA(u_argn2)
GBL int sys_getset(VOID) {
	int old;

	switch (what) {
	case SET_UMASK:
		old = UDATA(u_mask);
		UDATA(u_mask) = parm & S_UMASK;
		return old;
	}
	UERR = EPERM;
	return (-1);
}
#undef what
#undef parm

#endif	/* __KERNEL__ */

