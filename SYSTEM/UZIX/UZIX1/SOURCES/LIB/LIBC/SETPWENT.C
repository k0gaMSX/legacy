/* setpwent.c
 */

#include "passwd.h"

#ifdef L_setpwent
/*
 * setpwent(), endpwent(), and getpwent() are included in the same object
 * file, since one cannot be used without the other two, so it makes sense to
 * link them all in together.
 */
/* file descriptor for the password file currently open */
static int pw_fd = -1;
char *_path_passwd = _PATH_PASSWD;

void setpwent() {
	if (pw_fd != -1)
		close(pw_fd);
	pw_fd = open(_path_passwd, O_RDONLY | O_BINARY);
	if (pw_fd==-1) printf("ERRNO %d opening password\n",errno);
}

void endpwent(void) {
	if (pw_fd != -1)
		close(pw_fd);
	pw_fd = -1;
}

struct passwd *getpwent(void) {
	if (pw_fd != -1)
		return __getpwent(pw_fd);
	return NULL;
}
#endif

