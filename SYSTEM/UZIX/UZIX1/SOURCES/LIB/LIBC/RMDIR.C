/* rmdir.c
 */
#include <unistd.h>
#include <string.h>
#include <paths.h>
#include <errno.h>
#include <sys/stat.h>
#include <syscalls.h>

int rmdir(path)
	char *path;
{
	struct stat statbuf;
	char newpath[PATHLEN];
	direct_t dir;
	int fd;

	if (strlen(path)+3+1 > sizeof(newpath)) {
		errno = ENAMETOOLONG;
		goto Err;
	}
	if (stat(path, &statbuf) != 0)
		goto Err;
	if ((statbuf.st_mode & S_IFDIR) == 0) {
		errno = ENOTDIR;
		goto Err;
	}
	if ((fd = open(path, 0)) < 0)
		goto Err;
	while (read(fd, (char *) &dir, sizeof(dir)) == sizeof(dir)) {
		if (dir.d_ino == 0 || 
		    0 == strcmp((char *)dir.d_name, ".") || 
		    0 == strcmp((char *)dir.d_name, ".."))
			continue;
		close(fd);
		errno = ENOTEMPTY;
		goto Err;
	}
	close(fd);
	strcpy(newpath, path);
	strcat(newpath, "/.");
	if (unlink(newpath) != 0)	/* remove path/. */
		goto Err;
	strcat(newpath, ".");
	if (unlink(newpath) != 0)	/* remove path/.. */
		goto Err;
	if (unlink(path) != 0)		/* remove path */
Err:		return -1;
	return 0;
}

