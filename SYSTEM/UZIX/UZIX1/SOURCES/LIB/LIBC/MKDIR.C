/* mkdir.c
 */
#include <unistd.h>
#include <sys/stat.h>

int mkdir(path, mode)
	char *path;
	mode_t mode;
{
	return mknod(path, S_IFDIR | (mode & S_UMASK), 0);
}

