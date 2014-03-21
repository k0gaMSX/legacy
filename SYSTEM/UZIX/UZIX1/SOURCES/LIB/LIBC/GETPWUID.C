/* getpwuid.c
 */

#include "passwd.h"

#ifdef L_getpwuid
struct passwd *getpwuid(uid)
	int uid;
{
	struct passwd *pwd;

	setpwent();
	while ((pwd = getpwent()) != NULL) {
		if (pwd->pw_uid == uid)
			break;
	}
	endpwent();
	return pwd;
}
#endif

