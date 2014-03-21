/* getpw.c
 */

#include "passwd.h"

#ifdef L_getpw
int getpw(uid, buf)
	int uid;
	char *buf;
{
	struct passwd *pwd;

	if (buf == NULL) {
		errno = EINVAL;
		return -1;
	}
	if ((pwd = getpwuid(uid)) == NULL)
		return -1;
	sprintf(buf, "%s:%s:%u:%u:%s:%s:%s",
			pwd->pw_name,
			pwd->pw_passwd,
			pwd->pw_uid, pwd->pw_gid,
			pwd->pw_gecos,
			pwd->pw_dir,
			pwd->pw_shell);
	return 0;
}
#endif

