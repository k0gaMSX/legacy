/* fgetpwen.c
 */

#include "passwd.h"
 
#ifdef L_fgetpwen
struct passwd *fgetpwent(file)
	FILE *file;
{
	if (file == NULL) {
		errno = EINTR;
		return NULL;
	}
	return __getpwent(fileno(file));
}
#endif

