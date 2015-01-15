
#include <signal.h>


void
abort(void)
{
	raise(SIGABRT);
}
