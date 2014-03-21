/* readdir.c	readdir implementation
 *
 */
#include <unistd.h>
#include <alloc.h>
#include <dirent.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>

struct dirent *readdir(dir)
	register DIR *dir;
{
	direct_t direntry;
	register struct dirent *buf;

	if (dir == NULL || dir->dd_buf == NULL || dir->dd_fd == 0) {
		errno = EFAULT;
Err:		return NULL;
	}
	direntry.d_name[0] = 0;
	while (direntry.d_name[0] == 0)
		if (read(dir->dd_fd, &direntry, sizeof(direntry)) != sizeof(direntry))
			goto Err;
	buf = dir->dd_buf;
	buf->d_ino = direntry.d_ino;
	buf->d_off = dir->dd_loc++;
	strncpy(buf->d_name, (char *)direntry.d_name, DIRNAMELEN);
	buf->d_name[DIRNAMELEN] = 0;
	buf->d_reclen = strlen(buf->d_name);
	return buf;
}
