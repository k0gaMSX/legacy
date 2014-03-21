/* fgetgren.c	groups implementation
 */
 
#include "grp-l.h"

#ifdef L_fgetgren
struct group *fgetgrent(file)
	FILE *file;
{
	if (file == NULL) {
		errno = EINTR;
		return NULL;
	}
	return __getgrent(fileno(file));
}
#endif
