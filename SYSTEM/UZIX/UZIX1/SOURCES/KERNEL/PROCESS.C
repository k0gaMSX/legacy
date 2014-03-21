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
 Processes management
**********************************************************/

#define NEED__DEVTTY
#define NEED__DEVIO
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
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"

LCL void swapin(void); /* __P((void)); */
LCL ptptr nextready __P((void));
LCL void newproc __P((ptptr p));
LCL ptptr ptab_alloc __P((void));
LCL void shootdown __P((uint));

STATIC void *_stkptr;	/* Temp storage for swapin/swapout/dofork */
STATIC int _newid;	/* Temp storage for dofork */
STATIC ptptr _pp;	/* Temp storage for swapin/swapout/dofork */

/* Common strings. They are here to save memory */
static char *notfound = "no %s, error %d";
static char *bininit = "/bin/init";

/* Init() */
GBL void init(VOID) {
	static char *arg[2] = {"init", NULL};
	
	/* there is no need to fill with zeros the structures not initialized,
	   in the bss segment (such as ptab, fs_tab, modtab, etc), since UZI.AS
	   already did it.
	*/
	rdtod();
	ptotal = 1;
	bzero(UDATA_ADDR, sizeof(udata_t));
	UDATA(u_insys) = 1;	/* flag - in kernel */
	UDATA(u_mask) = 022;	/* standard user mask */

	bfill(UDATA(u_files),-1,sizeof(UDATA(u_files)));
	bcopy(UZIX,UDATA(u_name),5);
	bufinit();
	d_init();	/* initialize all devices */

	d_open(TTYDEV); /* Open the console tty device */
	swap_open();	/* Open the swaper */
	/* Create the context for the first process */
	initproc = ptab_alloc();
	UDATA(u_ptab) = initproc;
	swap_alloc(initproc->p_swap);
	newproc(initproc);
	initproc->p_status = P_RUNNING;
	kprintf("\nMounting root fs: ");
	root_dev = (*(uchar *)BDRVADDR);
#ifdef CHOOSE_BOOT
	{
	char bootchar;

	UDATA(u_base) = &bootchar;
	UDATA(u_count) = 1;
	cdread(TTYDEV);
	root_dev += bootchar - '0';
	}
#endif
#ifdef USETEST
	tester(0);
#endif
	/* Mount the root device */
	if (fmount(root_dev, NULL, 0))
		panic(notfound, "filesystem",UDATA(u_error));
	if ((root_ino = (inoptr)i_open(root_dev, ROOTINODE)) == 0)
		panic(notfound, "root", UDATA(u_error));
	kprintf("ok\n");
	UDATA(u_root) = root_ino;	/* already referenced in i_open() */
	UDATA(u_cwd) = root_ino;
	i_ref(root_ino);
	rdtime(&UDATA(u_time));

	/* Run /init and starting roll! */
	UDATA(u_argn1) = (int) ("/dev/console");
	UDATA(u_argn2) = O_RDONLY;
	sys_open();	/* stdin */
	UDATA(u_argn2) = O_WRONLY;
	sys_open();	/* stdopen */
	sys_open();	/* stderr */
#ifdef USETEST
	tester(1);
#endif
	UDATA(u_argn1) = (int) (bininit);
	UDATA(u_argn2) = (int) (&arg[0]);
	UDATA(u_argn3) = (int) (&arg[1]);
	sys_execve();
	panic(notfound, bininit, UDATA(u_error));
	/* NORETURN */
}

/* shootdown() */
LCL void shootdown(val)
	uint val;
{
	sys_sync();
	swap_close();
	kprintf("%s stopped (%p)\n", UZIX, val);
	_abort(0);
}

/* psleep() puts a process to sleep on the given event.
 * If another process is runnable, it swaps out the current one
 * and starts the new one.
 * Normally when psleep is called, the interrupts have already been
 * disabled. An event of 0 means a pause(), while an event equal
 * to the process's own ptab address is a wait().
 */
GBL void psleep(event)
	void *event;
{
	register pstate_t sts = P_PAUSE;
	ptptr pt = UDATA(u_ptab);

	_di();
	if (pt->p_status != P_RUNNING)
		panic("psleep: voodoo");
	if (UDATA(u_ptab)->p_pending == 0) {	/* pending signals */
		if (event) {
			sts = (event == pt) ? P_WAIT : P_SLEEP;
		}
		pt->p_status = sts;
		pt->p_wait = event;
		pt->p_intr = 0;
	}
	else	pt->p_intr = 1;
	_ei();
	swapout();	/* Swap us out, and start another process */
	/* Swapout doesn't return until we have been swapped back in */
}

/* Wakeup() looks for any process waiting on the event,
 * and make them runnable.
 * If event is null this procedure will wakeup all paused processes.
 */
GBL void wakeup(event)
	void *event;
{
	register ptptr p = ptab;

	_di();
	while (p < ptab+PTABSIZE) {
		if ((uchar)(p->p_status) >= P_READY && p->p_wait == event) {
			p->p_status = P_READY;
			p->p_wait = NULL;
		}
		++p;
	}
	_ei();
}

/* Nextready() returns the process table pointer of a runnable process.
 * It is actually the scheduler.
 * If there are none, it loops.  This is the only time-wasting loop in the
 * system.
 */
LCL ptptr nextready(VOID) {
	static ptptr pp = ptab; /* Pointer for round-robin scheduling */
	register ptptr p = pp;

	for (;;) {
		if (++p >= ptab + PTABSIZE)
			p = ptab;
		if (p == pp) {		/* Loop closed */
#if DEBUG > 0
			/* sys_sync() causes system to access disk very
			   often and slowing down UZIX if running on
			   floppy. since it's just for wasting time, it
			   was supressed on non-debug versions.
			 */
			sys_sync();	/* waste time by sync */
#endif
			/* ok, no ready process was found. so, let's
			   enable interrupts and maybe clk_int() can
			   cleanup process table to us */
			__ei();
			/* and let's call tty_poll(), so user don't think
			   we are frozen and we also collect keyboard data */
			tty_poll();
		}
		if ((uchar)p->p_status == P_RUNNING)
			panic("nextready: extra running");
		if ((uchar)p->p_status == P_READY)
			return (pp = p);
	}
}

/* Swapout() swaps out the current process, finds another that is READY,
 * possibly the same process, and swaps it in.
 * When a process is restarted after calling swapout,
 * it thinks it has just returned from swapout().
 */
GBL void swapout(VOID) {
#ifndef LOC_UDATA
	/* Auto variables must conform to swapin/dofork autos ! */
	auto udata_t ud;
#endif

	chksigs();		/* See if any signals are pending */
	_pp = nextready();	/* Get a new process */
	/* If there is nothing else to run, just return */
	if (_pp == UDATA(u_ptab)) {
		UDATA(u_ptab)->p_status = P_RUNNING;
		runticks = 0;
		/* UDATA(u_ptab)->p_cprio-1;	/* add only one tick! */
		return;
	}
#ifndef LOC_UDATA
	/* Save the user data structure on stack */
	bcopy(UDATA_ADDR,&ud,sizeof(udata_t));
#endif
	/* Save the stack pointer and critical registers */
	/* push 1	; ret status
	 * push si, di, bp
	 * _stkptr = (void *)_SP;
	 */
#define __SAVEALL	swapout_SAVEALL
#ifdef PC_HOSTED
#include "process.mtc"
#else
#ifdef MSX_HOSTED
#include "process.msx"
#else
#endif
#endif
	UDATA(u_ptab)->p_sp = _stkptr;	/* save SP in core memory */
#ifdef	LOC_UDATA
	UDATA(u_ptab)->p_udata = UDATA_ADDR; /* back link to static udata */
#else
	UDATA(u_ptab)->p_udata = &ud;	/* back link to saved udata */
#endif
#ifndef MEMBANKING
	if (*(uint *)UDATA(u_ptab)->p_swap != 0) /* not in-core process */
		swap_write(UDATA(u_ptab)->p_swap);
#endif
	/* Swap the next process in, and return into its context. */
	swapin();
	/* NORETURN */
	panic("swapin failed");
}

/* Swapin()
 */
LCL void swapin(void) {
#ifndef LOC_UDATA
	/* Auto variables must conform to swapout/dofork autos ! */
	auto udata_t ud;
#endif
	tempstack();	/* CAN'T ACCESS STACK NOW !!! */
	swap_read(_pp->p_swap);
	/* STACK OF NEW PROCESS NOW AVAILABLE */
	/* Now we must restore stack frame */
	_stkptr = _pp->p_sp;
	/* _SP = (uint)_stkptr
	 * pop bp, di, si
	 */
#define __RESTFRAME	swapin_RESTFRAME
#ifdef PC_HOSTED
#include "process.mtc"
#else
#ifdef MSX_HOSTED
#include "process.msx"
#else
#endif
#endif
#ifndef LOC_UDATA
	/* At this point stack reloaded to swapout state and
	   ud available for usage
	 */
	bcopy(&ud,UDATA_ADDR,sizeof(udata_t));
#endif
	if (_pp != UDATA(u_ptab))
		panic("mangled swapin");
	_di();
	_pp->p_status = P_RUNNING;
	runticks = 0;
	_ei();
	if (REFRESH_VECTORS())
		setvectors();
	inint = 0;	/* is this right, inint=0 for swapped in process? */
	/* Restore to pre-swapout state */
	/* pop ax
	 * mov sp,bp
	 * pop bp
	 * ret
	 */
#define __RETFROM	swapin_RETFROM
#ifdef PC_HOSTED
#include "process.mtc"
#else
#ifdef MSX_HOSTED
#include "process.msx"
#else
#endif
#endif
}

/* dofork() implements forking.
 * This function can have no arguments
 */
GBL int dofork(VOID) {
#ifndef LOC_UDATA
	/* Auto variables must conform to swapin/swapout autos ! */
	auto udata_t ud;
#endif

	if (NULL == (_pp = ptab_alloc())) {	/* Can't allocate ptab entry */
		goto Err;
	}
	if (swap_alloc(_pp->p_swap)) {		/* Can't allocate swap area */
		_pp->p_status = P_EMPTY;	/* Free ptab entry */
Err:		UDATA(u_error) = EAGAIN;
		return (-1);
	}
	ptotal++;				/* add process */
	_di();
	UDATA(u_ptab)->p_status = P_READY;	/* Parent is READY */
	_newid = _pp->p_pid;			/* Child ident */
#ifndef LOC_UDATA
	bcopy(UDATA_ADDR,&ud,sizeof(udata_t));	/* Put user data onto stack */
#endif
	/* Save the stack pointer and critical registers.
	 * When the process is swapped back in, it will be as
	 * if it returns with the value of the childs pid.
	 */
	/* push _newid
	 * push si, di, bp
	 * _stkptr = (void *)_SP
	 */
#define __SAVENEWID	dofork_SAVENEWID
#ifdef PC_HOSTED
#include "process.mtc"
#else
#ifdef MSX_HOSTED
#include "process.msx"
#else
#endif
#endif
	UDATA(u_ptab)->p_sp = _stkptr;	/* save parent stack pointer */
#ifdef MEMBANKING
	swap_dup(UDATA(u_ptab)->p_swap, _pp->p_swap);
#else
	if (*(uint *)(UDATA(u_ptab)->p_swap) != 0) /* not in-core process */
		swap_write(UDATA(u_ptab)->p_swap);  /* swap out parent image */
#endif
	/* repair child stack pointer */
	/* add sp, 2*4 */
#define __DROPSTACK	dofork_DROPSTACK
#ifdef PC_HOSTED
#include "process.mtc"
#else
#ifdef MSX_HOSTED
#include "process.msx"
#else
#endif
#endif
	/* Make a new (child) process table entry, etc. */
	newproc(_pp);
	UDATA(u_ptab)->p_status = P_RUNNING;
	_ei();
	return 0;	/* Return to child */
}

/* Newproc() fixes up the tables for the child of a fork
 */
LCL void newproc(p)
	register ptptr p;	/* New process table entry */
{
	register uchar *j;

	/* Note that ptab_alloc clears most of the entry */
	_di();
	runticks = 0;
	p->p_pptr = UDATA(u_ptab);		/* parent */
	p->p_ignored = UDATA(u_ptab)->p_ignored; /* inherited signal masks */
	p->p_uid = UDATA(u_ptab)->p_uid; 	/* inherited user id */
	p->p_cprio = MAXTICKS;			/* timeslice */
	p->p_nice = 0;				/* nice value */
#ifdef UZIX_MODULE
	RESET_MODULE();
#endif
	UDATA(u_ptab) = p;
	bzero(&UDATA(u_utime), 4 * sizeof(time_t)); /* Clear tick counters */
	rdtime(&UDATA(u_time));
	UDATA(u_cursig) = UDATA(u_error) = 0;
	if (UDATA(u_cwd))  i_ref(UDATA(u_cwd));	 /* add ref to current dir */
	if (UDATA(u_root)) i_ref(UDATA(u_root)); /* add ref to current root */
	j = UDATA(u_files);
	while (j != UDATA(u_files) + UFTSIZE) {
		if (!freefileentry(*j))
			++of_tab[*j].o_refs;	/* add ref to inherited files */
		j++;
	}
	_ei();
}

/* Ptab_alloc() allocates a new process table slot, and fills
 * in its p_pid field with a unique number.
 */
LCL ptptr ptab_alloc(VOID) {
	static uint nextpid = 0;
	register ptptr p, pp = ptab;

	_di();
	while (pp < ptab+PTABSIZE) {
		if ((uchar)(pp->p_status) == P_EMPTY)
			goto Found;
		++pp;
	}
	_ei();
	return NULL;

	/* See if next pid number is unique */
Found:	p = pp;
Loop:	if (++nextpid & 0x8000) 	/* pid always positive value! */
		nextpid = 1;
	pp = ptab;
	while (pp < ptab+PTABSIZE) {
		if ((uchar)pp->p_status != P_EMPTY && pp->p_pid == nextpid)
			goto Loop;
		++pp;
	}
	bzero(pp = p, sizeof(ptab_t));
	p->p_pid = nextpid;
	p->p_status = P_FORKING;
	_ei();
	return pp;
}

/* doexit() destroys current process and doing all cleanups
 */
GBL void doexit(val, val2)
	uchar val;
	uchar val2;
{
	register uchar j;
	register ptptr p;

#ifdef UZIX_MODULE
	clear_module_reqs(UDATA(u_ptab)->p_pid);
#endif
	_di();
	UDATA(u_ptab)->p_status = P_ZOMBIE;	/* don't swapout me! */
	/* close all opened files */
	j = UFTSIZE - 1;
	while (j-- != 0) {
		if (!freefileentry(UDATA(u_files)[j]))
			doclose(j);
	}
	i_deref(UDATA(u_root));
	i_deref(UDATA(u_cwd));
	sys_sync();	/* Not necessary, but a good idea. */
	UDATA(u_ptab)->p_exitval = (val << 8) | val2;	/* order is important */
	/* Set child's parent to init (UZI180/280 sets to our parent) */
	p = ptab;
	while (p < ptab+PTABSIZE) {
		if ((uchar)(p->p_status) != P_EMPTY &&
		    p->p_pptr == UDATA(u_ptab) && p != UDATA(u_ptab))
			p->p_pptr = initproc; /* UDATA(u_ptab)->p_pptr; */
		++p;
	}
	swap_dealloc(UDATA(u_ptab)->p_swap);	/* free process swap area */
	/* Stash away child's execution tick counts in process table,
	 * overlaying some no longer necessary stuff.
	 */
	addtick(&UDATA(u_utime), &UDATA(u_cutime));
	addtick(&UDATA(u_stime), &UDATA(u_cstime));
	bcopy(&UDATA(u_utime), &(UDATA(u_ptab)->p_break), 2 * sizeof(time_t));
	/* Wake up a waiting parent, if any. */
	if (UDATA(u_ptab) != initproc)
		wakeup(UDATA(u_ptab)->p_pptr);
	_ei();
	if (--ptotal == 0)
		shootdown(UDATA(u_ptab)->p_exitval);
	_pp = nextready();
	swapin();
	/* NORETURN */
}

/* dowait()
 */
#define pid (int)UDATA(u_argn1)
#define statloc (int *)UDATA(u_argn2)
#define options (int)UDATA(u_argn3)
GBL int dowait()
{
	register ptptr p;
	int retval;
	
	for (;;) {
		/* Search for an exited child */
		_di();
		p = ptab;
		while (p < ptab+PTABSIZE) {
			if (p->p_pptr == UDATA(u_ptab) && /* my own child! */
			   (uchar)(p->p_status) == P_ZOMBIE) {
				retval = p->p_pid;
			    	/* if (pid < -1)...
			    	   wait for any child whose group ID is equal
			    	   to the absolute value of PID
			    	   - NOT IMPLEMENTED -
			    	   
			    	   if (pid == 0)...
			    	   wait for any child whose group ID is equal
			    	   to the group of the calling process
			    	   - NOT IMPLEMENTED -
			    	   
			    	   if option == WUNTRACED...
			    	   - NOT IMPLEMENTED -
			    	*/
			    	if (pid > 0) if (retval != pid) continue;
				if (statloc != NULL)
					*statloc = p->p_exitval;
				p->p_status = P_EMPTY;	/* free ptab now! */
				/* Add in child's time info.
				 * It was stored on top of p_alarm in the childs
				 * process table entry
				 */
				addtick(&UDATA(u_cutime), (time_t *)&(p->p_break)+0);
				addtick(&UDATA(u_cstime), (time_t *)&(p->p_break)+1);
				_ei();
				return retval;
			}
			++p;
		}
		if (options & WNOHANG != 0) {
			UDATA(u_error) = ECHILD;
			return 0;
		}
		/* Nothing yet, so wait */
		psleep(UDATA(u_ptab));	/* P_WAIT */
		if (UDATA(u_ptab)->p_intr) {
			UDATA(u_error) = EINTR;
			return -1;
		}
	}
}
#undef options
#undef statloc
#undef pid

/* Calltrap() deal with a pending caught signal, if any.
 * udata.u_insys should be false.
 * Remember: the user may never return from the trap routine!
 */
GBL void calltrap(VOID) {
	void (*curvec) __P((signal_t)); /* for HTC call throught regs */
	register signal_t cursig = UDATA(u_cursig);
	long oldretval;
	uchar olderrno;

	if (cursig != __NOTASIGNAL && cursig <= NSIGS) {
		curvec = UDATA(u_sigvec)[cursig-1];
		UDATA(u_cursig) = __NOTASIGNAL;
		UDATA(u_sigvec)[cursig-1] = SIG_DFL; /* Reset to default */
		/* calltrap was called by unix() or service(), so it
		   can't erase previous contents of retval/errno! */
		oldretval = *(long *)&(UDATA(u_retval));
		olderrno = UDATA(u_error);
		_ei();
		(*curvec)(cursig);
		_di();
		*(long *)&(UDATA(u_retval)) = oldretval;
		UDATA(u_error) = olderrno;
	}
}

/* chksigs() sees if the current process has any signals set,
 * and deals with them
 */
GBL void chksigs(VOID) {
	register uchar j;

	_di();
	if (UDATA(u_ptab)->p_pending != 0) {
		j = 1;
		while (j != NSIGS+1) {
			sigset_t mask = sigmask(j);
			sig_t vect = (UDATA(u_sigvec)[j-1]);
			if ((mask & UDATA(u_ptab)->p_pending) != 0) {
				if (vect == SIG_DFL) {
					_ei();
					doexit(0, j);
				}
				if (vect != SIG_IGN) {
					/* Arrange to call the user routine at return */
					UDATA(u_ptab)->p_pending &= ~mask;
					UDATA(u_cursig) = j;
					break;	/* don't check next signals! */
				}
			}
			++j;
		}
	}
	_ei();
}

/* Ssig() send signal sig to process p and maybe
 * move process to ready-state
 */
GBL void ssig(proc, sig)
	register ptptr proc;
	signal_t sig;
{
	register pstate_t stat;
	sigset_t mask = sigmask(sig);

	_di();
	if (proc == NULL || (uchar)(proc->p_status) <= P_ZOMBIE)
		goto Ret;	/* Presumably was killed just now */
	if (proc->p_ignored & mask)
		goto Ret;
	stat = proc->p_status;
	/* check for interruptable sleeping states */
	if ((uchar)stat == P_PAUSE ||
	    (uchar)stat == P_WAIT ||
	    (uchar)stat == P_SLEEP) {
		proc->p_status = P_READY;
		proc->p_wait = NULL;
		proc->p_intr = 1;
	}
	proc->p_pending |= mask;
Ret:	_ei();
}

/* Sendsig() send signal sig to process p
 * (or to all processes if p == NULL)
 */
GBL void sendsig(p, sig)
	register ptptr p;
	signal_t sig;
{
	if (p)
		ssig(p, sig);
	else {
		p = ptab;
		while (p < ptab+PTABSIZE) {
			if ((uchar)(p->p_status) > P_ZOMBIE)
				ssig(p, sig);
			++p;
		}
	}
}

/* Clk_int() is the clock interrupt routine.
 * Its job is to increment the clock counters, increment the tick count
 * of the running process, and either swap it out if it has been in long
 * enough and is in user space or mark it to be swapped out if in system
 * space.
 * Also it decrements the alarm clock of processes.
 * This must have no automatic or register variables
 */
GBL int clk_int(VOID) {
	static ptptr p;

	/* Increment processes and global tick counters */
	incrtick(&ticks);
	if ((uchar)(UDATA(u_ptab)->p_status) == P_RUNNING)
		incrtick(UDATA(u_insys) ? &UDATA(u_stime) : &UDATA(u_utime));
	/* Do once-per-second things */
	if (++sec == TICKSPERSEC) {
		/* Update global time counters */
		sec = 0;
#ifdef NO_RTC
		updttod();	/* Really update time-of-day if no RTC */
#else
		rdtod();	/* Get updated time-of-day */
#endif
		/* Update process alarm clocks */
		p = ptab;
		while (p < ptab+PTABSIZE) {
			if (p->p_alarm) {
				if (--p->p_alarm == 0)
					sendsig(p, SIGALRM);
			}
			++p;
		}
	}
	/* Check run time of current process */
	if (++runticks >= UDATA(u_ptab)->p_cprio &&
	    !UDATA(u_insys) &&
	    (uchar)(UDATA(u_ptab)->p_status) == P_RUNNING) { /* Time to swap out */
		_di();
		UDATA(u_insys)++;
		UDATA(u_inint) = inint;
		/* If inint == 0 then it will cause interrupts to be enabled
		 * while doing do_swap. swapin is responsible for ei().
		 */
		UDATA(u_ptab)->p_status = P_READY;
		swapout();
		_di();
		UDATA(u_insys)--;	/* We have swapped back in */
		inint = UDATA(u_inint);
		/*
		  we can't return to service with inint=0, or --inint
		  will do inint=255, so service will never be called again
		*/
	}
	return 0;
}

