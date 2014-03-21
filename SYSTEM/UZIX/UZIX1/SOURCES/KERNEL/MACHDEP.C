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
 Additional machine dependent subroutines for kernel
**********************************************************/

#define NEED__DEVTTY
#define NEED__DEVIO
#define NEED__MACHDEP
#define NEED__PROCESS
#define NEED__DISPATCH
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#endif
#include "unix.h"
#include "extern.h"

#ifdef __KERNEL__
long unix __P((uint callno, ... /*uint arg1, uint arg2, uint arg3, uint arg4*/));
LCL long unixret __P((void));
#endif /* __KERNEL__ */

#ifdef PC_HOSTED
#include "machdep.mtc"
#else
#ifdef MSX_HOSTED
#include "machdep.msx"
#else
#endif
#endif

/* Architecture specific init.
 * This is called at the very beginning to initialize everything.
 * It is the equivalent of main()
 */
GBL void arch_init(VOID) {
#ifdef __KERNEL__
	_di();
	tempstack();
	initsys();	/* Initialize system dependent parts */
	TICKSPERMIN = TICKSPERSEC * 60;
	MAXTICKS = TICKSPERSEC / 10;	/* 100 ms timeslice */
	_ei();
	ARCH_INIT;	/* MACRO */
	init(); 	/* NORETURN */
#else /* __KERNEL__ */
	inint = 0;
	UDATA(u_euid) = 0;
	UDATA(u_insys) = 1;
	UDATA(u_mask) = 022;
#endif /* __KERNEL__ */
}

#ifdef __KERNEL__
/* This adds two tick counts together.
 * The t_time field holds up to sixty second of ticks,
 * while the t_date field counts minutes
 */
GBL void addtick(t1, t2)
	register time_t *t1, *t2;
{
	t1->t_time += t2->t_time;
	t1->t_date += t2->t_date;
	while (t1->t_time >= TICKSPERMIN) {
		t1->t_time -= TICKSPERMIN;
		++t1->t_date;
	}
}

/* add one tick to time
 * The t_time field holds up to sixty second of ticks,
 * while the t_date field counts minutes
 */
GBL void incrtick(t)
	register time_t *t;
{
	++t->t_time;
	while (t->t_time >= TICKSPERMIN) {
		t->t_time -= TICKSPERMIN;
		++t->t_date;
	}
}
#endif	/* __KERNEL__ */

GBL void rdtime(tloc)
	register time_t *tloc;
{
#ifndef __KERNEL__
	rdtod();
#endif /* __KERNEL__ */
	_di();
	*tloc = tod;
	_ei();
}

GBL void panic(s, a1, a2, a3)
	char *s;
	void *a1, *a2, *a3;
{
	_di();
	++inint;
	kprintf("\nPANIC: ");
	kprintf(s,a1,a2,a3);
	kputchar('\n');
#if 0
	idump();
#endif
	_abort(99);
}

/* warning() prints warning message to console */
GBL void warning(s, a1, a2, a3)
	char *s;
	void *a1, *a2, *a3;
{
	kprintf("WARNING: ");
	kprintf(s,a1,a2,a3);
	kputchar('\n');
}

#ifdef __KERNEL__
/* kputs() prints zero-terminated character string to console */
GBL void kputs(s)
	register char *s;
{
	while (*s)
		kputchar((uchar)*(s++));
}
#endif

#if DEBUG > 0
/* _idump() dumps state of all inodes
 */
STATIC void _idump(VOID) {
	register inoptr ip = i_tab;

	kprintf("Inodes:\tMAGIC\tDEV\tNUM\tMODE\tNLINK\t(DEV)\tREFS\tDIRTY\n");
	while (ip < i_tab + ITABSIZE) {
		kprintf("#%d\t%d\t%p\t%u\t%06o\t%d\t%p\t%d\t%d\n",
			ip - i_tab, ip->c_magic, ip->c_dev, ip->c_num,
			ip->c_node.i_mode, ip->c_node.i_nlink,
			DEVNUM(ip), ip->c_refs, ip->c_dirty);
		++ip;
	}
}

/* _pdump() dumps state of all processes
 */
STATIC void _pdump(VOID) {
	register ptptr pp = ptab;

	kprintf("Proc:\tSTATUS\tWAIT\tPID\tPPTR\tALARM\tPENDING\tIGNORED\tBREAK\tSP\n");
	while (pp < ptab + PTABSIZE) {
		kprintf("#%d\t%d\t%p\t%d\t%d\t%d\t%p\t%p\t%p\t%p\n",
			pp - ptab, pp->p_status, pp->p_wait, pp->p_pid,
			pp->p_pptr - ptab, pp->p_alarm, pp->p_pending,
			pp->p_ignored, pp->p_break, pp->p_sp);
		++pp;
	}
}

/* idump() dumps state of all system datas
 */
GBL void idump(VOID) {
	kprintf("%s: Errno %d, root #%d, Insys=%d, ptab #%d, callno=%d, cwd #%d, usp %p\n",
		UDATA(u_name),
		UDATA(u_error), root_ino - i_tab,
		UDATA(u_insys), UDATA(u_ptab) - ptab,
		UDATA(u_callno), UDATA(u_cwd) - i_tab,
		UDATA(u_ptab)->p_sp);
	_idump();
	_pdump();
	bufdump();
}
#endif

#ifdef __KERNEL__
/*
 */
STATIC void __itoa (unsigned value, char *strP, uchar radix) {
	char buf[34];
	register char *_di = strP, *_si = buf;
	uchar len;

	do {
		*_si++ = (char)(value % radix);
		value /= radix;
	} while (value != 0);
	/* The value has now been reduced to zero and the
	 * digits are in the buffer.
	 */
	/* The digits in the buffer must now be copied in reverse order into
	 *  the target string, translating to ASCII as they are moved.
	 */
	len = (uchar)(_si-buf);
	while (len != 0) {
		--len;
		radix = (uchar)*--_si;
		*_di++ = (char)((uchar)radix + (((uchar)radix < 10) ? '0' : 'A'-10));
	}
	/* terminate the output string with a zero. */
	*_di ='\0';
}

/*
 */
GBL char *itoa(value, strP, radix)
	register int value;
	char *strP;
	int radix;
{
	char *p = strP;

	if (radix == 0) {
		if (value < 0) {
			*p++ = '-';
			value = -value;
		}
		radix = 10;
	}
	__itoa((unsigned)value,p,(unsigned)radix);
	return strP;
}

/* Short version of printf for printing to kernel */
GBL void kprintf(fmt)
	char *fmt;
{
	register int base;
	uchar l, w, c, pad, s[7], *p, *q, **arg = (uchar **)&fmt + 1;
	int len = 0;

	while ((w = (uchar)*fmt++) != 0) {
		if (w != '%') {
			kputchar(w);
			continue;
		}
		pad = (uchar)(*fmt == '0' ? '0' : ' ');
		w = 0;
		while (*fmt >= '0' && *fmt <= '9') {
			w *= 10;
			w += (uchar)(*fmt - '0');
			++fmt;
		}
		s[1] = 0;
		p = s;
		len = 0x7FFF;
		switch (c = (uchar)*fmt++) {
		case 'c':
			s[0] = *(uchar *)arg++;
			break;
		case 'd': base = 0;	goto prt;
		case 'o': base = 8;	goto prt;
		case 'b': base = 2;	goto prt;
		case 'u': base = 10;	goto prt;
		case 'p':
			w = 4;
			pad = '0';
		case 'x':
			base = 16;
prt:			itoa(*(int *)arg++, (char *)s, base);
			break;
		case 'n':
			p = *arg++;
			len = *(int *)arg++;
			break;
		case 's':
			p = *arg++;
			break;
		default:
			s[0] = c;
			break;
		}
		if (w) {
			l = 0;
			q = p;
			while (--len != 0 && *q++ != 0)
				++l;
			w -= l;
			while ((int)w-- > 0)
				kputchar(pad);
		}
		kputs((char *)p);
	}
}
#endif

#ifndef bcopy
#ifndef PC_HOSTED
#ifndef MSX_HOSTED
/* Copy source to destination */
GBL void bcopy(src, dst, count)
	register void *src, *dst;
	uint count;
{
	while (count-- != 0)
		*((uchar *)dst)++ = *((uchar *)src)++;
}

/* Zeroing the memory area */
GBL void bzero(ptr,count)
	register void *ptr;
	register uint count;
{
	while (count-- != 0)
		*((uchar *)ptr)++ = '\0';
}

/* Filling the memory area */
GBL void bfill(ptr,val,count)
	register void *ptr;
	uchar val;
	register uint count;
{
	while (count-- != 0)
		*((uchar *)ptr)++ = val;
}
#endif /* MSX_HOSTED */
#endif /* PC_HOSTED */
#endif /* bcopy */

#ifdef __KERNEL__

extern char *disp_names[];

/* unix() is the system calls dispatcher */
GBL long unix(uint callno, ... /* arg1, arg2, arg3, arg4*/)
/*	register uchar callno; */
/*	uint arg1, arg2, arg3, arg4; */
{
	uint *ap;
	
	_di();
	/* we must DI because interrupt can occur before we get
	   user arguments. if a signal is handled, user maybe call a
	   system call and corrupts the arguments */
	ap = (uint *)(((char *)&callno) + sizeof(callno));
#if DEBUG > 1
	if ((uint)UDATA(u_break)+256 > (uint)ap)
		panic("PID #%d: stack to deep (%x/%x)\n",
			UDATA(u_ptab)->p_pid, ap, UDATA(u_break));
#endif
	if ((uchar)callno > dtsize) {
		UDATA(u_error) = EINVFNC;
		/* we know we're not called during interrupt, so we can force EI */
		__ei();
		return -1;
	}
	UDATA(u_argn1) = ap[0]; /*arg1*/
	UDATA(u_argn2) = ap[1]; /*arg2*/
	UDATA(u_argn3) = ap[2]; /*arg3*/
	UDATA(u_argn4) = ap[3]; /*arg4*/
	UDATA(u_callno) = (uchar)callno;
	UDATA(u_insys)++;
	UDATA(u_error) = 0;
	/* now we're safe. calltrap() will not occur with insys > 0 */
	/* we know we're not called during interrupt, so we can force EI */
	__ei();
	tty_poll();
#if DEBUG > 0
	clk_int();
#endif
#if DEBUG > 1
	if (traceon || UDATA(u_traceme))
		kprintf("\t\t%4d %s(%p=\"%n\", %p, %p, %p)\n",
			UDATA(u_ptab)->p_pid, disp_names[UDATA(u_callno)],
			ap[0], ap[0] < 0x100 ? "" : (char *)ap[0],
			12, ap[1], ap[2], ap[3]);
#endif
	/* Branch to correct routine */
	UDATA(u_retval) = (*disp_tab[UDATA(u_callno)])();
#if DEBUG > 1
	if (traceon || UDATA(u_traceme))
		kprintf("\t\t%4d\t%s() ret %p, err %d\n",
			UDATA(u_ptab)->p_pid, disp_names[UDATA(u_callno)],
			UDATA(u_retval), UDATA(u_error));
#endif
	chksigs();
	_di();
	if (runticks >= UDATA(u_ptab)->p_cprio) {
		UDATA(u_ptab)->p_status = P_READY;
		swapout();
	}
	_ei();
	if (--UDATA(u_insys) == 0)
		calltrap();	/* Call trap routine if necessary */
	return unixret();
}
#endif /* __KERNEL__ */

/* Min() calculate minimal of two numbers
 * Must be function not macro!
 */
GBL int Min(a, b)
	int a, b;
{
	return (b < a ? b : a);
}

#ifdef NO_RTC
/* Update software emulated clock */
void updttod() {
	uchar t1, t2, t3, d1, d2;
	uint d3, i;
	
	t1 = ++tod_sec;
	t2 = ((tod.t_time >> 5) & 63);
	t3 = ((tod.t_time >> 11) & 31);
	d1 = (tod.t_date & 31);
	d2 = ((tod.t_date >> 5) & 15);
	d3 = ((tod.t_date >> 9) & 127)+1980;
	if (t1 > 59) {t2++; t1=0;};
	if (t2 > 59) {t3++; t2=0;};
	if (t3 > 23) {d1++; t3=0;};
	if (d2==2) {
		i=d3/4;
		if (i*4==d3) { /* leap year */
			if (d1>29) goto march;
		} else
			if (d1>28) {
march:				d1=1;
				d2++;
			};
	} else {
		if ((d2<8 && d2%2==1) || (d2>7 && d2%2==0)) {
			if (d1>31) goto newmonth;
		} else {        /* 30 days per month */
			if (d1>30) {
newmonth:			d1=1;
				d2++;
			}
		}
	}
	if (d2>12) {d2=1; d3++;};
	d3-=1980;
	tod.t_time = (((int)t3 << 8) << 3) |    /* hours in 24h format */
		     ((int)t2 << 5) |           /* min */
		     (t1 >> 1);                 /* sec/2 */
	tod.t_date = (((int)d3 << 8) << 1) |    /* year relative to 1980 */
		     ((int)d2 << 5) |           /* mon */
		     d1;                        /* day */
	tod_sec = t1;
}       
#endif	/* NO_RTC */

