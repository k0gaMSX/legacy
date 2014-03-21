/* execvpe.c
 *
 * function(s)
 *	  execvpe - load and execute a program
 */

#include "exec.h"

#ifdef L_execvpe
int execvpe(pathP, argv, envV)
	char *pathP;
	char *argv[];
	char *envV[];
{
	return execve(_findPath(pathP), argv, envV);
}
#endif

