#ifndef __SIGNAL_H
#define __SIGNAL_H
#ifndef __TYPES_H
#include <types.h>
#endif

#define NSIGS		16	/* Number of signals <= 16 */

/* signals values */
typedef enum {
	__NOTASIGNAL = 0,
	SIGHUP, 		/* Hangup detected on controlling terminal
				   or death of a controlling process */
	SIGINT, 		/* Interrupt from keyboard */
	SIGQUIT,		/* Quit from keyboard */
	SIGILL, 		/* Illegal instruction */
	SIGTRAP,		/* Trace/breakpoint trap */
	SIGIOT, 		/* IOT trap. A synonym for SIGABRT */
	SIGABRT = SIGIOT,	/* Abort signal from abort */
	SIGUSR1,		/* User's signal 1 */
	SIGUSR2,		/* User's signal 2 */
	SIGKILL,		/* Kill signal */
	SIGPIPE,		/* Broken pipe: write to pipe with no readers */
	SIGALRM,		/* Timer signal from alarm */
	SIGTERM,		/* Termination signal */
	SIGURG,			/* Urgent signal */
	SIGCONT,		/* Continue process */
	SIGSTOP,		/* Stop process */
#define __NUMOFSIGNALS SIGSTOP
	/* this signals defined only for compatibility */
	SIGBUS, 		/* Bus error */
	SIGFPE, 		/* Floating point exception */
	SIGSEGV,		/* Invalid memory reference */
	SIGSYS, 		/* Bad argument to routine */
	SIGTTIN,
	SIGTOUT
} signal_t;

#if __NUMOFSIGNALS > NSIGS
 error Too many signals defined
#endif

#define sigmask(sig) (1<<((sig)-1)) 	/* signal mask */

typedef uint sigset_t;			/* at least 16 bits */

/* Type of a signal handler.  */
typedef void (*sig_t) __P((signal_t));

#define SIG_DFL ((sig_t)0)	/* default signal handling */
#define SIG_IGN ((sig_t)1)	/* ignore signal */
#define SIG_ERR ((sig_t)-1)	/* error return from signal */

#if 0
struct sigaction {
	sig_t sa_handler;
	sigset_t sa_mask;
	uint sa_flags;
	void (*sa_restorer)( /*void*/ );
};
#endif

extern char *sys_siglist[];

#endif

