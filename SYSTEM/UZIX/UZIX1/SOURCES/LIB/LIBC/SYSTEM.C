/* system.c
 */
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <paths.h>
#include <sys/wait.h>

int system(command)
	char *command;
{
	sig_t save_quit, save_int;
	int wait_ret, pid, wait_val = -1;
	static char *argv[4] = { "sh", "-c", 0, 0 };

	if (command == NULL)
		return 1;
	save_quit = (sig_t)signal(SIGQUIT, SIG_IGN);
	save_int = (sig_t)signal(SIGINT, SIG_IGN);
	if ((pid = fork()) < 0)
		goto Ret;	/* return -1 */
	if (pid == 0) { 	/* child */
		signal(SIGQUIT, SIG_DFL);
		signal(SIGINT, SIG_DFL);
		argv[2] = command;
		execve(_PATH_BSHELL, argv, environ);
		abort();
	}
	/* Signals are not absolutly guaranteed with vfork */
	signal(SIGQUIT, SIG_IGN);
	signal(SIGINT, SIG_IGN);
	do {
		if ((wait_ret = wait(&wait_val)) == -1) {
			wait_val = -1;
			break;
		}
	} while (wait_ret != pid);
Ret:	signal(SIGQUIT, save_quit);
	signal(SIGINT, save_int);
	return wait_val;
}
