/* getgrent.c	groups implementation
 */
 
#include "grp-l.h"

#ifdef L_getgrent
#define	GR_MAX_LINE_LEN	200
/* This is the core group-file read function.  It behaves exactly like
 * getgrent() except that it is passed a file descriptor.  getgrent()
 * is just a wrapper for this function.
 */
struct group *__getgrent(grp_fd)
	int grp_fd;
{
	static char line_buff[GR_MAX_LINE_LEN];
	static char *members[GR_MAX_MEMBERS+1];
	static struct group group;

	char *field_begin, *endptr;
	int member_num, line_len;
	register char *ptr;

	/* We use the restart label to handle malformatted lines */
restart:
	/* Read the line into the static buffer */
	if ((line_len = read(grp_fd, line_buff, GR_MAX_LINE_LEN)) <= 0)
		return NULL;
	if ((field_begin = strchr(line_buff, '\n')) != NULL) {
		*field_begin++ = '\0';
		lseek(grp_fd, (long) ((field_begin - line_buff) - line_len), SEEK_CUR);
		if (field_begin[-2] == '\r')
			field_begin[-2] = '\0';
	}
	else {	/* The line is too long - skip it :-\ */
		do {
			if ((line_len = read(grp_fd, line_buff, GR_MAX_LINE_LEN)) <= 0)
				return NULL;
		} while (0 == (field_begin = strchr(line_buff, '\n')));
		lseek(grp_fd, (long) ((field_begin - line_buff) - line_len + 1), SEEK_CUR);
		goto restart;
	}
	if (*line_buff == '#' || 
	    *line_buff == ' ' || 
	    *line_buff == '\n' ||
	    *line_buff == '\t')
		goto restart;
	/* Now parse the line */
	group.gr_name = line_buff;
	if ((ptr = strchr(line_buff, ':')) == NULL)
		goto restart;
	*ptr++ = '\0';

	group.gr_passwd = ptr;
	if ((ptr = strchr(ptr, ':')) == NULL)
		goto restart;
	*ptr++ = '\0';

	field_begin = ptr;
	if ((ptr = strchr(ptr, ':')) == NULL)
		goto restart;
	*ptr++ = '\0';

	group.gr_gid = (int)strtol(field_begin, &endptr, 10);
	if (*endptr != '\0')
		goto restart;

	field_begin = ptr;
	member_num = 0; 
	while ((ptr = strchr(ptr, ',')) != NULL) {
		*ptr = '\0';
		ptr++;
		members[member_num] = field_begin;
		field_begin = ptr;
		if (member_num < GR_MAX_MEMBERS)
			member_num++;
	}
	if (*field_begin == '\0')
		members[member_num] = NULL;
	else {
		members[member_num] = field_begin;
		members[member_num + 1] = NULL;
	}
	group.gr_mem = members;
	return &group;
}
#endif
