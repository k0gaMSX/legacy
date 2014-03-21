/* rewindir.c	rewinddir implementation
 *
 */
#include <unistd.h>
#include <alloc.h>
#include <dirent.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>

void rewinddir(dir)
	register DIR *dir;
{
	if (dir == NULL || dir->dd_buf == NULL || dir->dd_fd == 0) {
		errno = EFAULT;
		return;
	}
	dir->dd_loc = 0;
	lseek(dir->dd_fd, 0L, SEEK_SET);
}

