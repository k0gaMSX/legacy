/* execvp.c
 *
 * function(s)
 *	  execvp - load and execute a program
 */

#include "exec.h"

#ifdef L_execvp
int execvp(pathP, argv)
	char *pathP;
	char *argv[];
{
	return execve(_findPath(pathP), argv, environ);
}
#endif

