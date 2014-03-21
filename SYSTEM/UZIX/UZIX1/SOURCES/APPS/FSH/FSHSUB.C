/*
 * fsh, the Fudeba SHell
 * version 1.0
 * by A&L Software 1999
 *
 * FSH internal commands
 *
 * This program is released under GNU GPL license.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <types.h>
#include <unix.h>
#include <signal.h>
#include <sys\ioctl.h>
#include <sys\stat.h>

extern char *stringerr[];

#define PF		printf

int xls __P((char *path));
int xchmod __P((char *path, char *modes));
int xumask __P((char *masks));
int xmknod __P((char *path, char *modes, char *devs, char *devs1));
int xmkdir __P((char *path));
int xtype __P((char *arg));
int xunlink __P((char *path));
int xrmdir __P((char *path));
void xsetenv __P((char *va1, char *va2));
int xdf __P(());

extern int eq __P((char *, char *));

int devdir __P((int stat));
char *prot __P((int stat));
void dols __P((int d, char *path));

int devdir(stat)
	int stat;
{
	stat &= S_IFMT;

	switch (stat) {
	case S_IFDIR:	return 'd';
	case S_IFPIPE:	return 'p';
	case S_IFBLK:	return 'b';
	case S_IFCHR:	return 'c';
	case S_IFLNK:	return 'l';
	}
	return '-';
}

char *prot(stat)
	int stat;
{
	static char _prots[8][4] = {
		"---", "--x", "-w-", "-wx",
		"r--", "r-x", "rw-", "rwx"
	};
	return _prots[stat & 7];
}

void xsetenv(va1, va2)
	char *va1, *va2;
{
	int len;
	char *p, **env = environ;

	if (!*va1) {
		while (*env)
			printf("%s\n", *env++);
		return;
	}
	if (*va1 && !*va2) {
		len = strlen(p = va1);
		if (p[len-1] != '=') {
			for (; *env; ++env) {
				if (strlen(*env) > len &&
		    		    env[0][len] == '=' &&
		    		    memcmp(p, *env, len) == 0) {
					printf("%s\n", &env[0][len + 1]);
					break;
				}
			}
			return;
		}
		p[len-1] = '\0';
		unsetenv(p);
		return;
	}
	setenv(va1, va2, 1);
}

void dols(d, path)
	int d;
	char *path;
{
	int i, fd;
	direct_t buf;
	char dname[512];
	struct stat statbuf;

	while (read(d, (char *) &buf, sizeof(direct_t)) == sizeof(direct_t)) {
		if (buf.d_name[0] == '\0')
			continue;
		dname[0] = '\0';
		if (!eq(path,".")) {
			strcpy(dname, path);
			strcat(dname, "/");
		}
		strncat(dname, buf.d_name, DIRNAMELEN);
		fd = open(dname, O_SYMLINK);
		i = (fd >= 0) ? fstat(fd, &statbuf) :
				stat(dname, &statbuf);
		if (i) {
			PF("ls: can't stat %s\n", dname);
			if (fd >= 0)
				close(fd);
			continue;
		}
		if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
			strcat(dname, "/");
		if (S_ISDEV(statbuf.st_mode))
			PF("%3d,%-5d",
				statbuf.st_rdev >> 8,
				statbuf.st_rdev & 0xFF);
		else	PF("%-9ld", statbuf.st_size);
		PF(" %c%s%s%s %2d @%-5u %s",
		       devdir(statbuf.st_mode),
		       prot(statbuf.st_mode >> 6),
		       prot(statbuf.st_mode >> 3),
		       prot(statbuf.st_mode >> 0),
		       statbuf.st_nlink,
		       statbuf.st_ino,
		       dname);
		if ((statbuf.st_mode & S_IFMT) == S_IFLNK) {
			dname[0] = 0;
			i = read(fd, dname, sizeof(dname)-1);
			dname[i] = 0;
			PF(" -> %s", dname);
			close(fd);
		}
		PF("\n");
	}
}

int xls(path)
	char *path;
{
	int d;
	struct stat statbuf;

	if (stat(path, &statbuf) != 0)
		PF("ls: can't stat %s\n", path);
	else if ((statbuf.st_mode & S_IFMT) != S_IFDIR)
		PF("ls: %s isn't a directory\n", path);
	else if ((d = open(path, 0)) < 0)
		PF("ls: can't open %s\n", path);
	else {
		dols(d, path);
		close(d);
	}
	return 0;
}

int xchmod(modes, path)
	char *path, *modes;
{
	int mode = -1;

	sscanf(modes, "%o", &mode);
	if (mode == -1) {
		PF("chmod: bad mode\n");
		return (-1);
	}
	if (chmod(path, mode)) {
		PF("chmod: %s\n", stringerr[errno]);
		return (-1);
	}
	return 0;
}

int xumask(masks)
	char *masks;
{
	int mask = -1;

	if (masks == NULL) {
		mask = umask(0);
		umask(mask);
		PF("%3o\n", mask);
	}
	else {
		sscanf(masks, "%o", &mask);
		if (mask == -1) {
			PF("umask: bad mask\n");
			return (-1);
		}
		umask(mask);
	}
	return 0;
}

int xmknod(path, modes, devs, devs1)
	char *path, *modes, *devs, *devs1;
{
	int dev, major = -1, minor = -1, mode = -1;

	sscanf(modes, "%o", &mode);
	sscanf(devs, "%d", &major);
	sscanf(devs1, "%d", &minor);
	if (mode == -1) {
		PF("mknod: bad mode\n");
		return (-1);
	}
	if ((mode & S_IFMT) != S_IFBLK && (mode & S_IFMT) != S_IFCHR) {
		PF("mknod: mode isn't device\n");
		return (-1);
	}
	if (major == -1 || minor == -1) {
		PF("mknod: bad device numbers\n");
		return (-1);
	}
	dev = major*256+minor;
	if (mknod(path, mode, dev) != 0) {
		PF("mknod: %s\n", stringerr[errno]);
		return (-1);
	}
	return (0);
}

int xmkdir(path)
	char *path;
{
	if (mknod(path, S_IFDIR | 0777, 0) != 0) {
		PF("mkdir: %s\n", stringerr[errno]);
		return (-1);
	}
	return 0;
}

int xtype(arg)
	char   *arg;
{
	int nread;
	int d = open(arg, 0);
	char cbuf[BUFSIZE];

	if (d < 0) {
		PF("Can't open file %s, %s\n",
			arg, stringerr[errno]);
		return (-1);
	}
	for (;;) {
		if ((nread = read(d, cbuf, BUFSIZE)) <= 0)
			break;
		fwrite(cbuf, 1, nread, stdout);
	}
	close(d);
	return (0);
}

int xunlink(path)
	char *path;
{
	int i, fd = open(path, O_SYMLINK);
	struct stat statbuf;

	if (fd >= 0) {
		i = fstat(fd, &statbuf);
		close(fd);
	}
	else	i = stat(path, &statbuf);
	if (i) {
		PF("unlink: can't stat %s\n", path);
		return (-1);
	}
	if ((statbuf.st_mode & S_IFMT) == S_IFDIR) {
		PF("unlink: %s is a directory\n", path);
		return (-1);
	}
	if (unlink(path) != 0) {
		PF("unlink: %s\n", stringerr[errno]);
		return (-1);
	}
	return (0);
}

int xrmdir(path)
	char *path;
{
	int fd;
	struct stat statbuf;
	char newpath[100];
	direct_t dir;

	if (stat(path, &statbuf) != 0) {
		PF("rmdir: can't stat %s\n", path);
		return (-1);
	}
	if ((statbuf.st_mode & S_IFDIR) == 0) {
		PF("rmdir: %s isn't a directory\n", path);
		return (-1);
	}
	if ((fd = open(path, 0)) < 0) {
		PF("rmdir: %s is unreadable\n", path);
		return (-1);
	}
	while (read(fd, (char *) &dir, sizeof(dir)) == sizeof(dir)) {
		if (dir.d_ino == 0 ||
		    eq(dir.d_name, ".") ||
		    eq(dir.d_name, ".."))
			continue;
		PF("rmdir: %s isn't empty\n", path);
		close(fd);
		return (-1);
	}
	close(fd);
	strcpy(newpath, path);
	strcat(newpath, "/.");
	if (unlink(newpath) != 0)
		PF("rmdir: can't remove \".\", %s\n", stringerr[errno]);
	strcat(newpath, ".");
	if (unlink(newpath) != 0)
		PF("rmdir: can't remove \"..\", %s\n", stringerr[errno]);
	if (unlink(path) != 0) {
		PF("rmdir: %s\n", stringerr[errno]);
		return (-1);
	}
	return (0);
}

int xdf() {
	uint j;
	fsptr fsys;
	info_t info;

	for (j = 0; j < 8; ++j) {
		if (!getfsys(j, &info) &&
		    (fsys = (fsptr)info.ptr)->s_mounted) {
			PF("Filesystem %d: %u/%u blocks used/free, "
				"%u/%u inodes used/free\n",
			       j,
			       (fsys->s_fsize - fsys->s_isize) - fsys->s_tfree - fsys->s_reserv,
			       fsys->s_tfree,
			       (DINODESPERBLOCK * fsys->s_isize - fsys->s_tinode),
			       fsys->s_tinode);
		}
	}
	return 0;
}

