
#include	<signal.h>

extern void (* __sigvec[NSIG])(int);


void (*
signal(sig, action))()
int sig;
void (* action)(int);
{
	void (*	prev)();

	if (sig <= 0 || sig >= NSIG || sig == SIGQUIT)
		return SIG_ERR;

	prev = __sigvec[sig];
	__sigvec[sig] = action;
	return prev;
}

