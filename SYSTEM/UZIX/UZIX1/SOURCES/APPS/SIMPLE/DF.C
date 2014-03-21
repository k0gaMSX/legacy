/* df.c
 * descripton:	 summarize filesystems space
 * author:	 Archi Schekochikhin
 * modified:	 Adriano Cunha <adrcunha@dcc.unicamp.br>
 *		 added /etc/mtab query for getting fs name and mounting point
 * license:	 GNU Public License version 2
 */

#include <stdio.h>
#include <syscalls.h>
#include <unix.h>
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>

typedef unsigned char BOOL;

void findmntp(dev_t dev, inoptr ino, char *mpoint, char *fsysdev) {
	int i;
	FILE *fd;
	struct stat statbuf;
	char buf[256], *p, *p1;

	(void)ino;
	strcpy(mpoint,"?");
	if ((fd = fopen("/etc/mtab", "r")) == NULL) 
		return;
	while (!feof(fd)) {
		fgets(buf, sizeof(buf)-1, fd);
		if (NULL == (p = strchr(buf, '\t')))
			continue;
		p1 = p + 1;
		*p = '\0';
		stat(buf, &statbuf);
		if (statbuf.st_rdev == dev) {
			strcpy(fsysdev, buf);
			if (NULL == (p = strchr(p1, '\t')))
				continue;
			*p = '\0';
			strcpy(mpoint, p1);
			fclose(fd);
			return;
		}
	}
	fclose(fd);
	return;
}

int main(argc, argv)
	int argc;
	char *argv[];
{
	BOOL iflag = 0, kflag = 0, nflag = 0;
	info_t info;
	fsptr fsys;
	int i, j;
	char *p, mpoint[128], fsysdev[128];

	for (i = 1; i < argc; ++i) {
		p = argv[i];
		if (p[0] == '-') {
			for (++p; *p; ++p) {
				switch (*p) {
				case 'i':	iflag = 1;	break;
				case 'k':	kflag = 1;	break;
				case 'n':	nflag = 1;	break;
				default:
					printf("usage: %s [-ikn]\n", argv[0]);
					return 0;
				}
			}
		}
		else	break;
	}
	if (iflag)
		printf("Filesystem\tInodes\tIUsed\tIFree\t%%IFree\tMounted on\n");
	if (kflag)
		printf("Filesystem\tSize(Kb) Used\t Free\t %%Free\tMounted on\n");
	if (!iflag && !kflag)
		printf("Filesystem\tBlocks\t Used\t Free\t %%Free\tMounted on\n");
	if (i < argc) {
		for (; i < argc; ++i) {
			p = argv[i];
		}
	}
	else {
		for (j = 0; j < 8; ++j) {
			if (0 == getfsys(j, &info) &&
			    (fsys = (fsptr)info.ptr) != NULL &&
			    fsys->s_mounted) {
				int t = iflag ? 8 * fsys->s_isize : fsys->s_fsize - fsys->s_reserv;
				int u = iflag ? (t - fsys->s_tinode) :
						(t - fsys->s_isize) - fsys->s_tfree;
				int f = iflag ? fsys->s_tinode : fsys->s_tfree;
				int prc;

				if (!iflag && kflag) {
					t /= 2;
					u /= 2;
					f /= 2;
				}
				if ((prc = t/100) != 0)
					prc = f/prc;
				strcpy(mpoint, "?");
				sprintf(fsysdev, "%d", j);
				if (!nflag) {
					findmntp(fsys->s_dev, 
						 fsys->s_mntpt, 
						 mpoint, fsysdev);
				}
				printf("%-16s %6u\t%5u\t%5u\t%3u%%\t%s\n",
					fsysdev, t, u, f, prc,
					fsys->s_mntpt ? mpoint : "/");
			}
		}
	}
	return 0;
}

