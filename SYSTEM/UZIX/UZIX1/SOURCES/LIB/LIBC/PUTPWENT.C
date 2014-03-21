/* putpwent.c
 */

#include "passwd.h"

#ifdef L_putpwent
int putpwent(pwd, f)
	struct passwd *pwd;
	FILE * f;
{
	if (pwd == NULL || f == NULL) {
		errno = EINVAL;
		return -1;
	}
	if (fprintf(f, "%s:%s:%u:%u:%s:%s:%s\n", 
			pwd->pw_name, pwd->pw_passwd,
		    	pwd->pw_uid, pwd->pw_gid, pwd->pw_gecos,
		    	pwd->pw_dir, pwd->pw_shell) < 0)
		return -1;
	return 0;
}
#endif

