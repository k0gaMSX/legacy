/* lstat.c	lstat implementation for UZIX
 */
#include <unistd.h>
#include <fcntl.h>
#include <syscalls.h>

int lstat(name, buf)
	char *name;
	void *buf;
{
	int sts, fd = open(name, O_SYMLINK);

	if (fd < 0)
		sts = stat(name, buf);
	else {
		sts = fstat(fd, buf);
		close(fd);
	}
	return sts;
}
