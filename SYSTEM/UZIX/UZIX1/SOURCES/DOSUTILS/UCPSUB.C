/*
 * UZIX - UNIX Implementation for MSX
 * (c) 1997-2001 Arcady Schekochikhin
 *		 Adriano C. R. da Cunha
 *
 * UZIX is based on UZI (UNIX Zilog Implementation)
 * UZI is a UNIX kernel clone written for Z-80 systems.
 * All code is public domain, not being based on any AT&T code.
 *
 * The author, Douglas Braun, can be reached at:
 *	7696 West Zayante Rd.
 *	Felton, CA 95018
 *	oliveb!intelca!mipos3!cadev4!dbraun
 *
 * This program is under GNU GPL, read COPYING for details
 *
 */

/**********************************************************
 Subroutines for UCP
**********************************************************/

#include "utildos.h"
#include "xfs.h"
#include "fcntl.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "sys\ioctl.h"
#include "sys\stat.h"
#endif
#ifdef _MSX_DOS
#include "..\include\stdio.h"
#include "..\include\stdlib.h"
#include "..\include\string.h"
#include "..\include\unixio.h"
#else
#include <c:\tc\include\stdio.h>
#include <c:\tc\include\stdlib.h>
#include <c:\tc\include\string.h>
#include <c:\tc\include\dir.h>
#include <c:\tc\include\io.h>
#endif

#define PF	printf

extern uchar *syserror;

int xls __P((char *option, char *path));
int xchmod __P((char *path, char *modes));
int xumask __P((char *masks));
int xmknod __P((char *path, char *modes, char *devs, char *devs1));
int xmkdir __P((char *path));
int xget __P((char *arg, char *unixn, int binflag));
int xput __P((char *arg, char *dosn, int binflag));
int xtype __P((char *arg));
int xdump __P((char *arg, char *start, char *end));
int xunlink __P((char *path));
int xrmdir __P((char *path));
int xdf __P((void));
#ifdef PC_HOSTED
int ldir __P((char *s1));
#endif
#ifdef _MSX_DOS
extern int memicmp __P((char *s1, char *s2, int t));
extern unsigned char tolower __P((unsigned char c));
extern int chdir __P((char *s1));
#endif

extern int eq __P((char *, char *));
extern void pse __P((void));

int devdir __P((int stat));
char *prot __P((int stat));
void dols __P((int d, char *path, int wide));

#ifdef _MSX_DOS
#include "ucp.msx"
#endif

#ifdef PC_HOSTED
int ldir(char *s1) {
	char s[130];

	printf("DOS files:\n");
	sprintf(s, "dir %s", s1);
	return system(s);
}
#endif

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

void dols(d, path, wide)
	int d;
	char *path;
	int wide;
{
	int i, fd;
	direct_t buf;
	char dname[512];
	struct stat statbuf;

	while (UZIXread(d, (char *) &buf, sizeof(direct_t)) == sizeof(direct_t)) {
		if (buf.d_name[0] == '\0')
			continue;
		dname[0] = '\0';
		if (!eq(path,".")) {
			strcpy(dname, path);
			strcat(dname, "/");
		}
		strncat(dname, buf.d_name, DIRNAMELEN);
		fd = UZIXopen(dname, O_SYMLINK);
		i = (fd >= 0) ? UZIXfstat(fd, &statbuf) :
				UZIXstat(dname, &statbuf);
		if (i) {
			PF("ls: can't stat %s\n", dname);
			if (fd >= 0)
				UZIXclose(fd);
			continue;
		}
		if ((statbuf.st_mode & S_IFMT) == S_IFDIR)
			strcat(dname, "/");
		if (!wide) {
			if (S_ISDEV(statbuf.st_mode))
				PF("%3d,%-5d",
					MAJOR(statbuf.st_rdev),
					MINOR(statbuf.st_rdev));
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
				i = UZIXread(fd, dname, sizeof(dname)-1);
				dname[i] = 0;
				PF(" -> %s", dname);
				UZIXclose(fd);
			}
		} else {
			printf("%s", dname);
			i = strlen(dname) + 1;
			if ((statbuf.st_mode & S_IFMT) == S_IFLNK) putchar('@');
			else if (((statbuf.st_mode & S_IFMT) != S_IFDIR) &&
			    ((statbuf.st_mode & S_IEXEC) +
			    (statbuf.st_mode & S_IGEXEC) +
			    (statbuf.st_mode & S_IOEXEC) != 0)) putchar('*');
			else i--;
			if (i < 16) putchar('\t');
			if (i < 8) putchar('\t');
		}
		if (!wide) putchar('\n');
	}
	if (wide) putchar('\n');
}

int xls(option, thepath)
	char *thepath, *option;
	
{
	int d, wide = 1;
	char *path = option;
	struct stat statbuf;

	if (eq(option, "-l")) {
		wide = 0;
		path = thepath;
	}
	if (!*path) path = ".";
	if (UZIXstat(path, &statbuf) != 0) {
		PF("ls: can't stat %s\n", path);
		pse();
	}
	else if ((statbuf.st_mode & S_IFMT) != S_IFDIR) {
		PF("ls: %s is not a directory\n", path);
		pse();
	}
	else if ((d = UZIXopen(path, 0)) < 0) {
		PF("ls: can't open %s\n", path);
		pse();
	}
	else {
		dols(d, path, wide);
		UZIXclose(d);
	}
	return 0;
}

/* just to make syntax equal to Solaris, Linux, etc */
int xchmod(modes, path)
	char *path, *modes;
{
	int mode = -1;

	sscanf(modes, "%o", &mode);
	if (mode == -1) {
		PF("chmod: bad mode\n");
		pse();
		return (-1);
	}
	if (UZIXchmod(path, mode)) {
		PF("_chmod: error %s\n", stringerr[*syserror]);
		pse();
		return (-1);
	}
	return 0;
}

int xumask(masks)
	char *masks;
{
	int mask = -1;

	if (masks == NULL) {
		mask = UZIXumask(0);
		UZIXumask(mask);
		PF("%3o\n", mask);
	}
	else {
		sscanf(masks, "%o", &mask);
		if (mask == -1) {
			PF("umask: bad mask\n");
			pse();
			return (-1);
		}
		UZIXumask(mask);
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
		pse();
		return (-1);
	}
	if ((mode & S_IFMT) != S_IFBLK && (mode & S_IFMT) != S_IFCHR) {
		PF("mknod: mode is not device\n");
		pse();
		return (-1);
	}
	if (major == -1 || minor == -1) {
		PF("mknod: bad device numbers\n");
		pse();
		return (-1);
	}
	dev = MKDEV(major, minor);
	if (UZIXmknod(path, mode, dev) != 0) {
		PF("_mknod: error %s\n", stringerr[*syserror]);
		pse();
		return (-1);
	}
	return (0);
}

int xmkdir(path)
	char *path;
{
	if (UZIXmknod(path, S_IFDIR | 0777, 0) != 0) {
		PF("mkdir: mknod error %s\n", stringerr[*syserror]);
		pse();
		return (-1);
	}
	return 0;
}

int xget(arg, unixn, binflag)
	char *arg;
	char *unixn;
	int binflag;
{
	int d, nread;
	FILE *fp = fopen(arg, binflag ? "rb" : "r");
	char cbuf[BUFSIZE];

	if (fp == NULL) {
		PF("Source file not found\n");
		pse();
		return (-1);
	}
	if (*unixn == 0) {
		unixn = arg+strlen(arg);
		while (--unixn > arg) {
			if (*unixn == '\\' || *unixn == ':') {
				++unixn;
				break;
			}
		}
	}
	d = UZIXcreat(unixn, 0666);
	if (d < 0) {
		PF("Cant open uzix file %s, error %s\n",
			unixn, stringerr[*syserror]);
		pse();
		return (-1);
	}
	for (;;) {
		nread = fread(cbuf, 1, BUFSIZE, fp);
		if (nread == 0)
			break;
		if (UZIXwrite(d, cbuf, nread) != nread) {
			PF("_write: error %s\n", stringerr[*syserror]);
			fclose(fp);
			UZIXclose(d);
			pse();
			return (-1);
		}
	}
	fclose(fp);
	UZIXclose(d);
	return (0);
}

int xput(arg, dosn, binflag)
	char *arg;
	char *dosn;
	int binflag;
{
	int d, nread;
	FILE *fp;
	char cbuf[BUFSIZE];

	d = UZIXopen(arg, 0);
	if (d < 0) {
		PF("Can't open uzix file %s, error %s\n",
				arg, stringerr[*syserror]);
		pse();
		return (-1);
	}
	if (*dosn == 0) {
		dosn = arg+strlen(arg);
		while (--dosn > arg) {
			if (*dosn == '\\' || *dosn == ':') {
				++dosn;
				break;
			}
		}
	}
	fp = fopen(dosn, binflag ? "wb" : "w");
	if (fp == NULL) {
		PF("Can't open destination file %s\n",dosn);
		pse();
		return (-1);
	}
	for (;;) {
		if ((nread = UZIXread(d, cbuf, BUFSIZE)) == 0)
			break;
		if (fwrite(cbuf, 1, nread, fp) != nread) {
			PF("fwrite error\n");
			fclose(fp);
			UZIXclose(d);
			pse();
			return (-1);
		}
	}
	fclose(fp);
	UZIXclose(d);
	return (0);
}

int xtype(arg)
	char   *arg;
{
	int nread;
	int d = UZIXopen(arg, 0);
	char cbuf[BUFSIZE];

	if (d < 0) {
		PF("Can't open uzix file %s, error %s\n",
			arg, stringerr[*syserror]);
		pse();
		return (-1);
	}
	for (;;) {
		if ((nread = UZIXread(d, cbuf, BUFSIZE)) <= 0)
			break;
		fwrite(cbuf, 1, nread, stdout);
	}
	UZIXclose(d);
	return (0);
}

int xdump(arg, start, end)
	char *arg, *start, *end;
{
	int nread;
	char buf[BUFSIZE];
	uint i, j, k, d, blk, blkstart, blkend;

	d = UZIXopen(arg, 0);
	if (d < 0) {
		PF("Can't open uzix file %s, error %s\n",
				arg, stringerr[*syserror]);
		pse();
		return (-1);
	}
	if (*start)
		blkstart = atoi(start);
	else	blkstart = 0;
	if (*end)
		blkend = atoi(end);
	else	blkend = 0xFFFF;
	if (blkend < blkstart)
		blkend = blkstart;
	blk = blkstart;
	while (blk <= blkend && (nread = UZIXread(d, buf, BUFSIZE)) > 0) {
		PF("Block %d (0x%x)\n",blk,blk);
		i = 0;
		while (i < ((nread + 15) >> 4)) {
			PF("%04x\t", blk*BUFSIZE + (i<<4));
			for (j = 0; j < 16; ++j) {
				k = buf[(i<<4)+j] & 0xFF;
				if (k < 0x10)
					PF("0%x ", k);
				else	PF("%x ", k);
			}
			PF(" |");
			for (j = 0; j < 16; ++j) {
				k = buf[(i<<4)+j] & 0xFF;
				if (k < ' ' || k == 0177 || k == 0377)
					k = '.';
				PF("%c", k);
			}
			PF("|\n");
			++i;
		}
		PF("\n");
		++blk;
	}
	UZIXclose(d);
	return nread;
}

int xunlink(path)
	char *path;
{
	int i, fd = UZIXopen(path, O_SYMLINK);
	struct stat statbuf;

	if (fd >= 0) {
		i = UZIXfstat(fd, &statbuf);
		UZIXclose(fd);
	}
	else	i = UZIXstat(path, &statbuf);
	if (i) {
		PF("unlink: can't stat %s\n", path);
		pse();
		return (-1);
	}
	if ((statbuf.st_mode & S_IFMT) == S_IFDIR) {
		PF("unlink: %s directory\n", path);
		pse();
		return (-1);
	}
	if (UZIXunlink(path) != 0) {
		PF("_unlink: error %s\n", stringerr[*syserror]);
		pse();
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

	if (UZIXstat(path, &statbuf) != 0) {
		PF("rmdir: can't stat %s\n", path);
		pse();
		return (-1);
	}
	if ((statbuf.st_mode & S_IFDIR) == 0) {
		PF("rmdir: %s not directory\n", path);
		pse();
		return (-1);
	}
	if ((fd = UZIXopen(path, 0)) < 0) {
		PF("rmdir: %s unreadable\n", path);
		pse();
		return (-1);
	}
	while (UZIXread(fd, (char *) &dir, sizeof(dir)) == sizeof(dir)) {
		if (dir.d_ino == 0 ||
		    eq(dir.d_name, ".") ||
		    eq(dir.d_name, ".."))
			continue;
		PF("rmdir: %s not empty\n", path);
		UZIXclose(fd);
		pse();
		return (-1);
	}
	UZIXclose(fd);
	strcpy(newpath, path);
	strcat(newpath, "/.");
	if (UZIXunlink(newpath) != 0)
		PF("rmdir: can't unlink \".\", error %s\n", stringerr[*syserror]);
	strcat(newpath, ".");
	if (UZIXunlink(newpath) != 0)
		PF("rmdir: can't unlink \"..\", error %s\n", stringerr[*syserror]);
	if (UZIXunlink(path) != 0) {
		PF("rmdir: _unlink error %s\n", stringerr[*syserror]);
		pse();
		return (-1);
	}
	return (0);
}

int xdf() {
	uint j;
	fsptr fsys;
	info_t info;

	for (j = 0; j < 8; ++j) {
		if (!UZIXgetfsys(j, &info) &&
		    (fsys = (fsptr)info.ptr)->s_mounted) {
			PF("Drive %c: %u/%u blocks used/free, "
				"%u/%u inodes used/free\n",
			       j + 65,
			       (fsys->s_fsize - fsys->s_isize) - fsys->s_tfree - fsys->s_reserv,
			       fsys->s_tfree,
			       (DINODESPERBLOCK * fsys->s_isize - fsys->s_tinode),
			       fsys->s_tinode);
		}
	}
	return 0;
}
