/* getpwnam.c
 */

#include "passwd.h"

#ifdef L_getpwnam
struct passwd *getpwnam(name)
	char *name;
{
	struct passwd *pwd;

	if (name == NULL) {
		errno = EINVAL;
		return NULL;
	}
	setpwent();
	while ((pwd = getpwent()) != NULL) {
		if (!strcmp(pwd->pw_name, name))
			break;
	}
	endpwent();
	return pwd;
}
#endif

