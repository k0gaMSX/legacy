/* getgrnam.c	groups implementation
 */
 
#include "grp-l.h"

#ifdef L_getgrnam
struct group *getgrnam(name)
	char *name;
{
	struct group *group;

	if (name == NULL) {
		errno = EINVAL;
		return NULL;
	}
	setgrent();
	while ((group = getgrent()) != NULL) {
		if (!strcmp(group->gr_name, name))
			break;
	}
	endgrent();
	return group;
}
#endif
