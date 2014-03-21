/* execlp.c
 *
 * function(s)
 *	  execlp - load and execute a program
 */

#include "exec.h"

#ifdef L_execlp
int execlp(pathP, arg0)
	char *pathP;
	char *arg0;
{
	return execve(_findPath(pathP), &arg0, environ);
}
#endif

