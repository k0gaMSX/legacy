/* execle.c
 *
 * function(s)
 *	  execle - load and execute a program
 */

#include "exec.h"

#ifdef L_execle
int execle(pathP, arg0)
	char *pathP;
	char *arg0;
{
	register char **p = &arg0;

	/* Find the end of the argument list */
	while (*p++)
		;
	return execve(pathP, &arg0, (char **)*p);
}
#endif

