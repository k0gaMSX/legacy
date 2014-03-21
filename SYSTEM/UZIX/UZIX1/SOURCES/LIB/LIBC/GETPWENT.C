/* getpwent.c
 */

#include "passwd.h"

#ifdef L_getpwent
#define PWD_BUFFER_SIZE 256

struct passwd *__getpwent(pwd_fd)
	int pwd_fd;
{
	static char line_buff[PWD_BUFFER_SIZE];
	static struct passwd passwd;

	char *field_begin, *endptr, *gid_ptr, *uid_ptr;
	int i, line_len;

	/* We use the restart label to handle malformatted lines */
restart:
	/* Read the passwd line into the static buffer using a minimal of syscalls. */
	if ((line_len = read(pwd_fd, line_buff, PWD_BUFFER_SIZE)) <= 0)
		return NULL;
	if ((field_begin = strchr(line_buff, '\n')) != NULL) {
		*field_begin++ = '\0';
		lseek(pwd_fd, (long) ((field_begin - line_buff) - line_len), SEEK_CUR);
		if (field_begin[-2] == '\r')
			field_begin[-2] = '\0';
	}
	else {	/* The line is too long - skip it. :-\ */
		do {
			if ((line_len = read(pwd_fd, line_buff, PWD_BUFFER_SIZE)) <= 0)
				return NULL;
		} while (0 == (field_begin = strchr(line_buff, '\n')));
		lseek(pwd_fd, (long) (field_begin - line_buff) - line_len + 1, SEEK_CUR);
		goto restart;
	}
	if (*line_buff == '#' ||
	    *line_buff == ' ' ||
	    *line_buff == '\n' ||
	    *line_buff == '\t')
		goto restart;
	/* We've read the line; now parse it. */
	field_begin = line_buff;
	for (i = 0; i < 7; i++) {
		switch (i) {
		case 0: passwd.pw_name = field_begin;		break;
		case 1: passwd.pw_passwd = field_begin; 	break;
		case 2: uid_ptr = field_begin;			break;
		case 3: gid_ptr = field_begin;			break;
		case 4: passwd.pw_gecos = field_begin;		break;
		case 5: passwd.pw_dir = field_begin;		break;
		case 6: passwd.pw_shell = field_begin;		break;
		}
		if (i < 6) {
			field_begin = strchr(field_begin, ':');
			if (field_begin == NULL)
				goto restart;
			*field_begin++ = '\0';
		}
	}
	passwd.pw_gid = (int)strtoul(gid_ptr, &endptr, 10);
	if (*endptr != '\0')
		goto restart;
	passwd.pw_uid = (int)strtoul(uid_ptr, &endptr, 10);
	if (*endptr != '\0')
		goto restart;
	return &passwd;
}
#endif
