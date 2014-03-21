/* execv.c
 *
 * function(s)
 *	  execv - load and execute a program
 */

#include "exec.h"

#ifdef L_execv
int execv(pathP, argv)
	char *pathP;
	char *argv[];
{
	return execve(pathP, argv, environ);
}
#endif

