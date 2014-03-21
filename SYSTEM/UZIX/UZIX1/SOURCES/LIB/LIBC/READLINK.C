/* readlink.c	readlink implementation for UZIX
 */
#include <unistd.h>
#include <fcntl.h>
#include <syscalls.h>

int readlink(name, buf, size)
	char *name;
	char *buf;
	int size;
{
	int sts, fd = open(name, O_SYMLINK);

	if (fd < 0)
		return -1;
	sts = read(fd, buf, size);
	close(fd);
	return sts;
}
