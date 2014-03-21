/* getgrgid.c	groups implementation
 */

#include "grp-l.h"

#ifdef L_getgrgid
struct group *getgrgid(gid)
	int gid;
{
	struct group *group;

	setgrent();
	while ((group = getgrent()) != NULL) {
		if (group->gr_gid == gid)
			break;
	}
	endgrent();
	return group;
}
#endif
