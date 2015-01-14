
#include	<signal.h>
#include	"cpm.h"

void (* __sigvec[NSIG])(int);

int
raise(int sig)
{
	void (*handler)(int);
	static char msg1[] = "Fatal error - program aborted\r\n$";
	static char msg2[] = "Signal received\r\n$";

	if (sig <= 0 || sig >= NSIG)
		return -1;
	if ((handler = __sigvec[sig]) == SIG_IGN)
		return 0;
	if (handler == SIG_DFL) {
		bdos(9, (sig == SIGABRT) ? msg1 : msg2);
		exit(-1);
	}
	(*handler)(sig);
	return 0;
}

