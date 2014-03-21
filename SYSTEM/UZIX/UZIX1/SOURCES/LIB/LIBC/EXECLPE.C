/* execlpe.c
 *
 * function(s)
 *	  execlpe - load and execute a program
 */

#include "exec.h"

#ifdef L_execlpe
int execlpe(pathP, arg0)
	char *pathP;
	char *arg0;
{
	register char **p = &arg0;

	/* Find the end of the argument list */
	while (*p++)
		;
	return execve(_findPath(pathP), &arg0, (char **)*p);
}
#endif

