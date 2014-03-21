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
 TTY device driver
**********************************************************/

#define NEED__DEVTTY
#define NEED__DEVIO
#define NEED__MACHDEP
#define NEED__PROCESS
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#include "sys\ioctl.h"
#endif
#include "unix.h"
#include "extern.h"

#ifndef TABSIZE
#define TABSIZE 8
#endif

#ifndef TTYSIZ
#define TTYSIZ 80
#endif

#ifndef EOFKEY
#define EOFKEY	('D' & 037)
#endif

static char ctrlcp = 0;
static char ttysleep = 0;
#ifdef UZIX_MODULE
static char queuedctrlc = 0;
#endif

uint _getc __P((void));
void _putc __P((uchar));

STATIC uchar ttyinbuf[TTYSIZ];	/* terminal lookahead buffer */
STATIC uchar rawmode;

#ifdef __KERNEL__
STATIC queue_t ttyinq = {	/* terminal lookahead queue descriptor */
	ttyinbuf,
	ttyinbuf,
	ttyinbuf,
	TTYSIZ,
	0,
	TTYSIZ/2
};

STATIC uchar suspendflag;	/* Flag for ^S/^Q */
STATIC uchar flshflag;		/* Flag for ^O */
#else /* __KERNEL__ */
uchar _xbdos __P((uint, uchar));
#endif /* __KERNEL__ */

#ifdef PC_HOSTED
#include "devtty.mtc"
#else
#ifdef MSX_HOSTED
#include "devtty.msx"
#else
#endif
#endif

/* read from device */
GBL int tty_read(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
#ifdef __KERNEL__
	uchar ch;
	count_t nread = 0;

	NOTUSED(minor);
	NOTUSED(rawflag);
	/* we need no more then u_count chars */
	while (nread < UDATA(u_count)) {
		for (;;) {
			_di();
			if (remq(&ttyinq, &ch))
				break;	/* there are char in input queue */
			_ei();
			if (rawmode == 2) goto NoKey;
			ttysleep = 1;	/* flag tty is sleeping (waiting for a char) */
			psleep(&ttyinq); /* wait for char */
			if (ctrlcp) break;	/* we got char! */
			ttysleep = 0;
			if (UDATA(u_ptab)->p_intr || 
			    UDATA(u_cursig) ||
			    UDATA(u_ptab)->p_pending) {	   /* messy */
retintr:			UDATA(u_error) = EINTR;
				return (-1);	/* interrupted by signal */
			}
		}
		if (ctrlcp) {	/* char is CTRL+C while tty was sleeping */
			sendsig(UDATA(u_ptab), SIGINT);	/* so, send SIGINT to process that was sleeping */
			ctrlcp = 0;
			goto retintr;
		}
		_ei();
		if (nread++ == 0 && ch == EOFKEY)
NoKey:			return 0;		/* EOF */
		*(UDATA(u_base))++ = ch;
		if (!rawmode && ch == '\n')
			break;			/* LF teminates input */
	}
	return nread;
#else /* __KERNEL__ */
	int nread;

	NOTUSED(minor);
	NOTUSED(rawflag);
	ttyinbuf[0] = UDATA(u_count) < sizeof(ttyinbuf)-2 ?
				UDATA(u_count) : sizeof(ttyinbuf)-2;
	ttyinbuf[1] = 0;
	_xbdos((uint)ttyinbuf, 10);	/* Read console buffer */
	_xbdos('\n', 2);

	nread = ttyinbuf[1];
	ttyinbuf[nread + 2] = '\n';
	bcopy(ttyinbuf + 2, UDATA(u_base), nread + 1);
	return (ttyinbuf[2] == EOFKEY ? -1 : nread + 1);
#endif /* __KERNEL__ */
}

/* write data to device */
GBL int tty_write(minor, rawflag)
	uchar minor;
	uchar rawflag;
{
#ifdef __KERNEL__
	count_t towrite = UDATA(u_count);

	NOTUSED(minor);
	NOTUSED(rawflag);
	ERASECURSOR();
	while (towrite != 0) {
		--towrite;
		for (;;) {	/* Wait on the ^S/^Q flag */
			_di();
			if (!suspendflag)
				break;
			/* wait for ^Q/^O or signal */
			psleep(&suspendflag);
			if (UDATA(u_ptab)->p_intr || 
			    UDATA(u_cursig) ||
			    UDATA(u_ptab)->p_pending) {	   /* messy */
				UDATA(u_error) = EINTR;
				DISPLAYCURSOR();
				return (-1);	/* interrupted by signal */
			}
		}
		_ei();
		if (!flshflag) _putc(*UDATA(u_base)++);
	}
	DISPLAYCURSOR();
	return UDATA(u_count);
#else /* __KERNEL */
	uint count = UDATA(u_count);

	NOTUSED(minor);
	NOTUSED(rawflag);
	while (UDATA(u_count)-- != 0) {
		if (*(UDATA(u_base)) == '\n')
			_xbdos('\r', 2);
		_xbdos((uint)*(UDATA(u_base)), 2);
		UDATA(u_base) = UDATA(u_base) + 1;
	}
	return count;
#endif /* __KERNEL */
}

/* do ioctl on device */
GBL int tty_ioctl(minor, req, ptr)
	uchar minor;
	int req;
	void *ptr;
{
#ifdef __KERNEL__
	uchar ret = rawmode;	/* for 'rawmode' query! */

	NOTUSED(minor);
	NOTUSED(ptr);
	if ((uchar)req == TTY_RAW_UNBUFF)	rawmode = 2;
	else if ((uchar)req == TTY_RAW) 	rawmode = 1;
	else if ((uchar)req == TTY_COOKED)	rawmode = 0;
	else	return -1;
	return ret;
#else	/* __KERNEL__ */
	NOTUSED(minor);
	NOTUSED(req);
	NOTUSED(ptr);

	return rawmode;
#endif	/* __KERNEL__ */
}

#ifdef __KERNEL__
/* This tty polling routine checks to see if the keyboard data arrived.
 * If so it adds the character to the tty input queue, echoing and
 * processing backspace and carriage return.  If the queue contains a full
 * line, it wakes up anything waiting on it.  If it is totally full, it
 * beeps at the user.
 */
GBL int tty_poll(VOID) {
	uchar oc;
#ifdef PC_HOSTED
	register uint c;
#endif
	register int found = 0;

again:
#ifdef UZIX_MODULE
	if (queuedctrlc) goto ctrlc;	/* CTRL+C pressed? go processing */
#endif
#ifdef PC_HOSTED
	if ((c = _getc()) == 0)
		return found;
	oc = c;
#else
	if ((oc = _getc()) == 0)
		return found;
#endif
	if (rawmode) {
		insq(&ttyinq, oc);
		goto Wake;
	}
	if (oc == ('O' & 037)) {	/* ^O */
		flshflag = !flshflag;
		oc = ('Q' & 037);	/* remove suspend flag if any */
	}
	if (oc == ('C' & 037)) {	/* ^C pressed now */
#ifdef UZIX_MODULE
ctrlc:		if (IS_MODULE() && !ttysleep) { /* or if tty is sleeping, go process CTRL+C (see below) */
			queuedctrlc = 1;	/* flag CTRL+C pressed while module is active process */
			return 0;
		}
#endif
		kputs("^C\n");
#ifdef UZIX_MODULE
		queuedctrlc = 0;		/* CTRL+C processed */
#endif
		clrq(&ttyinq);
		suspendflag = 0;
		flshflag = 0;
		if (!ttysleep) sendsig(UDATA(u_ptab), SIGINT);
		else {
			ctrlcp = 1;
			goto Wake;
		}
	}
	else if (oc == ('S' & 037))	/* ^S */
		suspendflag = 1;
	else if (oc == ('Q' & 037)) {	/* ^Q */
		suspendflag = 0;
		wakeup(&suspendflag);
		return 1;
	}
	else if (oc == '\b' || oc == 127) {		/* backspace/delete */
		if (uninsq(&ttyinq, &oc)) {
			if (oc == '\n')
				insq(&ttyinq, oc); /* Don't erase past newline */
			else if (oc == '\t') {
				for (oc = 0; oc < TABSIZE; oc++) { /* what else we need? */
					kputs("\b \b");
					/* just erasing 8 chars is buggy */
				}
			}
			else kputs("\b \b");
		}
	}
	else {
		if (oc == '\r') 	/* treat CR as LF */
			oc = '\n';
		if (insq(&ttyinq, oc)) {
			if (oc >= ' ' || oc == '\n' || oc == '\t')
				_putc(oc);	/* echo char */
		}
		else	_putc('\007');	/* Beep if no more room */
	}
	if (oc == '\n' || oc == EOFKEY) /* EOL or EOF */
Wake:		wakeup(&ttyinq);
	++found;
	goto again;		/* Loop until the uart has no data ready */
}
#endif
