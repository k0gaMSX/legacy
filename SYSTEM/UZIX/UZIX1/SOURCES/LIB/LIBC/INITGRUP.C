/* initgrup.c	groups implementation
 */
 
#include "grp-l.h"

#ifdef L_initgrou
int initgroups(user, gid)
	char *user;
	int gid;
{
	register struct group *group;
	int group_list[GR_MAX_GROUPS];
	register char **tmp_mem;
	int num_groups;

	num_groups = 0;
	group_list[num_groups] = gid;
	setgrent();
	while (num_groups < GR_MAX_GROUPS && (group = getgrent()) != NULL) {
		if (group->gr_gid != gid) {
			tmp_mem = group->gr_mem;
			while (*tmp_mem != NULL) {
				if (!strcmp(*tmp_mem, user)) {
					num_groups++;
					group_list[num_groups] = group->gr_gid;
				}
				tmp_mem++;
			}
		}
	}
	endgrent();
	return setgroups(num_groups, group_list);
}
#endif
