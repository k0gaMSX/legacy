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

#define NEED__DEVIO
#define NEED__FILESYS
#define NEED__MACHDEP
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "sys\stat.h"
#endif
#include "unix.h"
#include "extern.h"

/* Implementation of system calls */

#define ISIZE(ino)	((ino)->c_node.i_size)

/* shortcuts for 'udata' access */
#define UWHERE		(UDATA(u_offset))
#define UBAS		(UDATA(u_base))
#define UCNT		(UDATA(u_count))
#define UERR		(UDATA(u_error))

#ifdef __KERNEL__

LCL int repack __P((char **argp, char **envp, uchar check));
LCL void *scop __P((register char **argv, uchar cnt, char *to, char *real));
LCL uint ssiz __P((register char **argv, uchar *cnt, char **smin));
LCL void exec2 __P((void));

STATIC uint __argc;
STATIC char **__argv;
STATIC char **__envp;

/* check for arguments size */
LCL uint ssiz(argv, cnt, smin)
	register char **argv;
	uchar *cnt;
	char **smin;
{
	char *p, *mi = *smin;
	uint n = 0;

	*cnt = 1;
	while ((p = *argv++) != NULL) {
		if (p < mi)	mi = p;
		while (++n, *p++ != '\0')
			;
		++(*cnt);
	}
	*smin = mi;
	return n;
}

/* copy arguments vector */
LCL void *scop(argv, cnt, to, real)
	register char **argv;
	uchar cnt;
	char *to, *real;
{
	char *s, **a = (char **)to, *q = to + sizeof(char *) * cnt;

	while ((s = *argv++) != NULL) {
		*a++ = real;
		while (++real, (*q++ = *s++) != '\0')
			;
	}
	*a = NULL;
	return q;
}

/* move all arguments to top of program memory or check their size */
/* for move, stack can't be near the top of program memory and */
/* PROGBASE area is used as draft area */
LCL int repack(argp, envp, check)
	char **argp;
	char **envp;
	uchar check;
{
	uint tot, et, asiz, esiz;
	uchar acnt, ecnt;
	register char *p = (void *)PROGBASE;
	char *amin = (void *)UZIXBASE;

	asiz = ssiz(argp, &acnt, &amin);
	esiz = ssiz(envp, &ecnt, &amin);

	tot = (asiz + sizeof(char *) * acnt) +
	      (et = esiz + sizeof(char *) * ecnt);
	if ((uint)p + tot > (uint)amin) {	/* p == PROGBASE! */
		UERR = ENOMEM;
Err:		return 1;	/* no room for args */
	}
	if (check) {
		if ((uint)UBAS > (uint)(UZIXBASE - 1 - tot)) {
			UERR = E2BIG;
			goto Err;	/* no room for args */
		}
		goto Ok;
	}
	p = scop(argp, acnt, p, (char *)(UZIXBASE - 1 - et - asiz));
	scop(envp, ecnt, p, (char *)(UZIXBASE - 1 - esiz));
	__envp = (char **)(UZIXBASE - 1 - et);
	__argv = (char **)(UZIXBASE - 1 - tot);
	__argc = acnt-1;
	bcopy((void *)PROGBASE, __argv, tot);
Ok:	return 0;
}

/* exec2() second step of execve - executed on system stack! */
LCL void exec2(VOID) {
	register char **p, *progptr;
	register blkno_t pblk;
	uchar blk = 0;
	char *buf;

	/* Read in the rest of the program */
	progptr = (char *)PROGBASE;
	while (blk <= UCNT) {
		if ((pblk = bmap(UDATA(u_ino), blk, 1)) != NULLBLK) {
			buf = bread(UDATA(u_ino)->c_dev, pblk, 0);
			if (buf != NULL) {
				bcopy(buf, progptr, BUFSIZE);
				brelse((bufptr)buf);
			}
		}
		progptr += BUFSIZE;
		++blk;
	}
	i_deref(UDATA(u_ino));
	/* Zero out the free memory */
	bzero(progptr, (uint) ((char *)__argv - progptr));
	UDATA(u_ptab)->p_break = (void *)(((exeptr)PROGBASE)->e_bss);
	UDATA(u_break) = (void *)(((exeptr)PROGBASE)->e_bss);
#if DEBUG > 1
	UDATA(u_traceme) = 0;
#endif
	/* Fill in UDATA(u_name */
	bcopy(*__argv, UDATA(u_name), DIRNAMELEN);
	/* Shove argc and the address of argv just below argv */
	p = __argv;
	*--__argv = (char *) __envp;
	*--__argv = (char *) p;
	*--__argv = (char *) __argc;
#ifdef UZIX_MODULE
	RESET_MODULE();
#endif
	/* Machine dependant jump into the program, first setting the stack */
	doexec((uint)__argv);	/* NORETURN */
}

/*********************************************************
 SYSCALL execve(char *name, char *argv[], char *envp[]);
*********************************************************/
#define name (char *)UDATA(u_argn1)
#define argv (char **)UDATA(u_argn2)
#define envp (char **)UDATA(u_argn3)
GBL int sys_execve(VOID) {
	register inoptr ino;
	register uchar *buf;
	register sig_t *sp;
	uchar magic;
	uint mblk;

	if ((ino = namei(name, NULL, 1)) == 0) {
		UERR = ENOENT;
		goto Err1;
	}
	mblk = (uint)ISIZE(ino);	/* image length in bytes */
	if (PROGBASE + ISIZE(ino) >= UZIXBASE) { /* long operation! */
		UERR = ENOMEM;
		goto Ret;
	}
	if ((getperm(ino) & S_IOEXEC) == 0 ||
	      getmode(ino) != S_IFREG ||
	      (ino->c_node.i_mode & (S_IEXEC | S_IGEXEC | S_IOEXEC)) == 0) {
		UERR = EACCES;
		goto Ret;
	}
	/* save information about program size in blocks/top */
	UCNT = (mblk + BUFSIZE - 1) >> BUFSIZELOG;
	UBAS = (void *)(PROGBASE + mblk + 1024); /* min +1K stack */
	/* Read in the first block of the new program */
	buf = bread(ino->c_dev, bmap(ino, 0, 1), 0);
	if (buf == NULL) goto Ret;
	magic = ((exeptr)buf)->e_magic;
	if (brelse((bufptr)buf) != 0) goto Ret;
	if (magic != EMAGIC) {
		if (((uchar *)buf)[0] == '#' && ((uchar *)buf)[1] == '!')
			UERR = ESHELL;
		else	UERR = ENOEXEC;
		goto Ret;
	}
	setftim(ino, A_TIME);	/* set access time */
	/* Turn off caught signals */
	sp = UDATA(u_sigvec);
	while (sp < (UDATA(u_sigvec) + NSIGS)) {
		if ((sig_t)(*sp) != SIG_IGN)
			*(sig_t *)sp = SIG_DFL;
		++sp;
	}
	/* Here, check the setuid stuff. No other changes need be
	 * made in the user data
	 */
	if (ino->c_node.i_mode & S_ISUID) UDATA(u_euid) = ino->c_node.i_uid;
	if (ino->c_node.i_mode & S_ISGID) UDATA(u_egid) = ino->c_node.i_gid;
	/* At this point, we are committed to reading in and executing
	 * the program. We switch to a local stack, and pass to it the
	 * necessary parameter: ino
	 */
	UDATA(u_ino) = ino;	/* Temporarly stash these here */
	if (repack(argv, envp, 1))	/* Check args size */
		goto Ret;
	tempstack();
	repack(argv, envp, 0);	/* Move arguments */
	exec2();

Ret:	i_deref(ino);
Err1:	return (-1);
}
#undef name
#undef argv
#undef envp

#ifdef UZIX_MODULE

#define proc_page0 UDATA(u_ptab)->p_swap[0]
#define proc_page1 UDATA(u_ptab)->p_swap[1]
static void *stkbkp = NULL;

LCL modtabptr searchmodule (int sig) {
	modtabptr mtable=&modtab;

	while  (mtable != modtab + MTABSIZE) {
		if (mtable->sig==sig) 
			return mtable;
		++mtable;
	}
	UERR=ESRCH;
	return NULL;
}

/* call module handler */
LCL int callmodu2(uint sign, uint fcn, char *args, int argsize, int pid) {
#ifdef PC_UZIX_TARGET
	uchar TEMPDBUF[512];		/* possible problem: stack too deep */
#else
/* MSX already defines TEMPDBUF as a 512bytes buffer */
#endif
	static modtabptr mtable;
	static uint _fcn;
	static uint _argsiz;
	static int _ppid;
	static ptptr _p;

	if (sign == NULL) goto Err;
	if ((mtable = searchmodule(sign)) == NULL) goto Err;
	_di();
	_p = UDATA(u_ptab);
	_ppid = pid == 0 ? _p->p_pid : pid;
	_fcn=fcn;
	_argsiz=argsize;
	if (argsize > 0) bcopy(args, (uchar *)TEMPDBUF, argsize);
	NOTUSED(fcn);		/* this is a trick for HTC. if you remove this,
				   if the above IF is false, HTC will jump the
				   #asm below */
#define	__SAVESTACK	callmodu2_SAVESTACK
#ifdef MSX_UZIX_TARGET
#include "process.msx"
#endif
#ifdef PC_UZIX_TARGET
#include "process.mtc"
#endif
	tempstack();
	swap_read(mtable->page);	/* swap_read can't do ei()! */
	_fcn=mtable->fcn_hnd(_fcn, _ppid, (uchar *)TEMPDBUF, _argsiz);
	_di();
	swap_read(_p->p_swap);
#define	__RESTSTACK	callmodu2_RESTSTACK
#ifdef MSX_UZIX_TARGET
#include "process.msx"
#endif
#ifdef PC_UZIX_TARGET
#include "process.mtc"
#endif
	_ei();
	if (_fcn!=0) {
		UERR=_fcn;
Err:		return -1;
	}
	return 0;
}

/* clear waiting replies from module to the exited process */
void clear_module_reqs(int pid) {
	modreplyptr mreply;
	modtabptr mtable=&modtab;

	for (mreply=modreply; mreply < modreply + RTABSIZE; ++mreply) {
		if (mreply->pid==pid) mreply->sig = 0;
	}
	/* tell modules that the queries/replies for this
	 * process can be erased
	 */
	while  (mtable != modtab + MTABSIZE) {
		callmodu2(mtable->sig, 0, NULL, -1, pid);
		if (mtable->page[0]==proc_page0 && mtable->page[1]==proc_page1) {
			mtable->sig=0;
			RESET_MODULE();
		}
		++mtable;
	}
}

/*********************************************************
 SYSCALL reg(uint sig, int (*func)());
*********************************************************/
#define sign (uint)UDATA(u_argn1)
#define func (void (*))UDATA(u_argn2)
GBL int sys_reg(VOID) {
	modtabptr mtable=&modtab;
	
	while  (mtable != modtab + MTABSIZE) {
		if (mtable->sig==0) goto fnd; 
		++mtable;
	}
	UERR=ENOMEM;
	return -1;
fnd:	mtable->sig = sign;
	mtable->fcn_hnd = func;
	mtable->page[0] = proc_page0;
	mtable->page[1] = proc_page1;
	SET_MODULE();
	return 0;
}
#undef func
#undef sign

/*********************************************************
 SYSCALL dereg(uint sig);
*********************************************************/
#define sign (uint)UDATA(u_argn1)
GBL int sys_dereg(VOID) {
	modtabptr mtable;
	
	if ((mtable = searchmodule(sign)) == NULL) goto Err;
	if (!super() && 
		(mtable->page[0]!=proc_page0 || mtable->page[1]!=proc_page1)) {
		UERR=EPERM;
Err:		return -1;
	}
	/* we should search for a waiting reply on reply table and return
	   EBUSY if the table is not clear... */
	mtable->sig=0;
	RESET_MODULE();
	return 0;
}
#undef func
#undef sign

/*********************************************************
 SYSCALL callmodu(uint sig, uint fcn, char *args, int argsize);
*********************************************************/
#define sign (uint)UDATA(u_argn1)
#define fcn (uint)UDATA(u_argn2)
#define args (char *)UDATA(u_argn3)
#define argsize (int)UDATA(u_argn4)
GBL int sys_callmodu(VOID) {
	if (argsize < 0 || argsize > BUFSIZE) {
		UERR=EINVAL;
		return -1;
	}
	return callmodu2(sign, fcn, args, argsize, 0);
}
#undef sign
#undef fcn
#undef args
#undef argsize

/*********************************************************
 SYSCALL modreply(int sig, int fcn, char *repladdr);
*********************************************************/
#define sign (uint)UDATA(u_argn1)
#define fctn (uint)UDATA(u_argn2)
#define repladdr (uint)UDATA(u_argn3)
/* send module reply to the process that requested module function */
GBL int sys_modreply(VOID) {
	modtabptr mtable;
	modreplyptr mreply;
	struct swap_mmread pp;
	int p_id;
	
	if ((mtable = searchmodule(sign)) == NULL) {
		goto Err;
	}
	p_id = (UDATA(u_ptab))->p_pid;
	pp.mm[0]=mtable->page[0];
	pp.mm[1]=mtable->page[1];
	for (mreply=modreply; mreply < modreply + RTABSIZE; ++mreply) {
		if (mreply->sig==sign && mreply->pid==p_id && mreply->fcn==fctn) {
			pp.buf = (void *)repladdr;
			pp.size = mreply->replysize;
			pp.offset = (uint)(mreply->replyaddr);
			if (swap_mmread(&pp) < 0) {
reperr:				UERR=EIO;
				goto Err1;
			}
			if (callmodu2(sign, fctn, NULL, -1, 0) < 0) goto reperr;	/* clear module reply table */
			mreply->sig=0;
			return 0;
		}
	}
	/* since this syscall is called essentialy by a library, the common
	   structure is "while (modreply()<0)". so, the module must be executed
	   to answer the call. so, let's not waste CPU calling this syscall
	   over and over again and returning -1 until process timeslice expires.
	   let's give other processes their bit of CPU */
	/* no reply found for this query */
	UERR=ENXIO;
Err1:	runticks = UDATA(u_ptab)->p_cprio;
Err:	return -1;
}
#undef sign
#undef fctn
#undef repladdr

/*********************************************************
 SYSCALL repfmodu(int pid, int fcn, char *repladdr, int replysize);
*********************************************************/
#define p_id (uint)UDATA(u_argn1)
#define fcnt (uint)UDATA(u_argn2)
#define repladdr (char *)UDATA(u_argn3)
#define reply_size (uint)UDATA(u_argn4)
/* put module reply in the reply table to the waiting process */
GBL int sys_repfmodu(VOID) {
	modtabptr mtable=&modtab;
	modreplyptr mreply;

	while  (mtable != modtab + MTABSIZE) {
		if (mtable->page[0]==proc_page0 && mtable->page[1]==proc_page1)
			goto fnd;
		++mtable;
	}
	UERR=ESRCH;
	goto Err;
fnd:
	for (mreply=modreply; mreply < modreply + RTABSIZE; ++mreply) {
		if (mreply->sig==0) {
			mreply->sig=mtable->sig;
			mreply->fcn=fcnt;
			mreply->pid=p_id;
			mreply->replyaddr=repladdr;
			mreply->replysize=reply_size;
			return 0;
		}
	}
	UERR=ENXIO;
Err:	return -1;
}
#undef p_id
#undef fcnt
#undef repladdr
#undef reply_size

#endif  /* UZIX_MODULE */

#endif	/* __KERNEL__ */
