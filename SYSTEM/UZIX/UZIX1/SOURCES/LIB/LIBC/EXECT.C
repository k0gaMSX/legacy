/* exect.c
 *
 * function(s)
 *	  exect - load and execute a program
 */

#include "exec.h"

#ifdef L_exect
int exect(pathP, argv, envV)
	char *pathP;
	char *argv[];
	char *envV[];
{
	return execve(pathP, argv, envV);
}
#endif

