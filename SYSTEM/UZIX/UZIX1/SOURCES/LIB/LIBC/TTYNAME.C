/* ttyname.c
 */
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dirent.h>

char *ttyname(fd)
	int fd;
{
	static char name[MAXNAMLEN];
	static char dev[] = "/dev";
	struct stat st, dst;
	struct dirent *d;
	char *ret = NULL;
	DIR *fp;
	int noerr = errno;

	if (fstat(fd, &st) < 0)
		return 0;
	if (!isatty(fd)) {
		errno = ENOTTY;
		return 0;
	}
	fp = opendir(dev);
	if (fp == 0)
		return 0;
	strcpy(name, dev);
	strcat(name, "/");
	while ((d = readdir(fp)) != 0) {
		if (strlen(d->d_name) > sizeof(name) - sizeof(dev) - 1)
			continue;
		strcpy(name + sizeof(dev), d->d_name);
		if (stat(name, &dst) == 0 &&
		    st.st_dev == dst.st_dev && 
		    st.st_ino == dst.st_ino) {
			ret = name;
			break;
		}
	}
	closedir(fp);
	errno = noerr;
	return ret;
}
