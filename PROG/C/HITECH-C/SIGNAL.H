/*
 *	Signal definitions for CP/M
 */

typedef unsigned char sig_atomic_t;

#define	SIGINT	1		/* control-C */
#define SIGILL	2		/* illegal instruction */
#define SIGFPE	3		/* floating point exception */
#define	SIGSEGV	4		/* segmentation violation */
#define SIGTERM	5		/* software termination signal */

#ifndef SIGABRT
#define SIGABRT	6		/* Abnormal termination */
#endif

#define SIGQUIT 7		/* control-stop */
#define SIGUSR1 8		/* User signal 1 */
#define SIGUSR2 9		/* User signal 2 */
#define NSIG	10		/* Number of signals */


#define	SIG_DFL	((void (*)(int))0)	/* default action is to exit */
#define	SIG_IGN	((void (*)(int))1)	/* ignore them */
#define SIG_ERR ((void (*)(int))-1)	/* error in signal call */

extern int raise(int);
extern void (*	signal(int, void (*)(int)))(int);
