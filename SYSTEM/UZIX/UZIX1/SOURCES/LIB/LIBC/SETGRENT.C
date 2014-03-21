/* setgrent.c	groups implementation
 */
 
#include "grp-l.h"

#ifdef L_setgrent
/*
 * setgrent(), endgrent(), and getgrent() are mutually-dependent functions,
 * so they are all included in the same object file, and thus all linked
 * in together.
 */
static int grp_fd = -1;
char *_path_group = _PATH_GROUP;

void setgrent() {
	if (grp_fd != -1)
		close(grp_fd);
	grp_fd = open(_path_group, O_RDONLY | O_BINARY);
}

void endgrent() {
	if (grp_fd != -1)
		close(grp_fd);
	grp_fd = -1;
}

struct group *getgrent() {
	if (grp_fd == -1)
		return NULL;
	return __getgrent(grp_fd);
}
#endif
