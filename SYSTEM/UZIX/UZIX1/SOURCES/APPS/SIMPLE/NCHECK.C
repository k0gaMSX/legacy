/* ncheck   name check			  Author:  Raymond Michiels */

#include <stdlib.h>
#include <stdio.h>
#include <types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <unistd.h>
#include <unix.h>

#ifndef PATH_MAX
#define PATH_MAX 128
#endif

ino_t *ilist;
int iflag = 0, aflag = 0, sflag = 0, nr_inodes = 0, opt, skip_len;
char *progname;
char *filesystem = NULL;
char *mnt_point = NULL;
char path[PATH_MAX];

extern int optind;
extern char *optarg;

#ifndef _PROTOTYPE
#define _PROTOTYPE(x,y)		x y
#endif

_PROTOTYPE(int main, (int argc, char **argv));
_PROTOTYPE(void usage, (void));
_PROTOTYPE(void myexit, (int n));
_PROTOTYPE(void readilist, (char *p));
_PROTOTYPE(int inlist, (ino_t inode));
_PROTOTYPE(int dotfile, (char *fullname));
_PROTOTYPE(int toprint, (struct stat *statbuf, char *name));
_PROTOTYPE(void traverse, (char *dirname));

void myexit(n)		/* maybe I could use something like _cleanup() */
int n;
{
  if (filesystem != NULL)
	umount(filesystem);
  if (mnt_point != NULL)
	rmdir(mnt_point);
  exit(n);
}


void usage()
{
  fprintf(stderr, "usage: %s [ -i numbers] [-s] [-a] file_system\n", progname);
  myexit(1);
}


void readilist(p)
char *p;
{
  ilist = (ino_t *)malloc(strlen(p)/2+1);
  if (ilist == NULL) {
	fprintf(stderr, "couldn't malloc i-node list\n");
	myexit(1);
  }
  do {
	if (*p == ',') p++;	/* skip comma's */
	if (!isdigit(*p)) {
		fprintf(stderr, "malformed i-node list\n");
		myexit(1);
	}
	ilist[nr_inodes++] = atoi(p);
  } while ((p = strchr(p, ',')) != NULL);
}


int inlist(inode)
ino_t inode;
{
  int i;

  for (i = 0; i < nr_inodes; i++) {
	if (ilist[i] == inode)
		return(1);
  }
  return(0);
}


int dotfile(fullname)
char *fullname;
{
  char *name;

  name = strrchr(fullname, '/') + 1;

  return(!(strcmp(name, ".") && strcmp(name, "..")));
}


int toprint(statbuf, name)
struct stat *statbuf;
char *name;
{
#define S_SPECIAL(x) (x & (S_ISUID | S_ISGID) || S_ISCHR(x) || S_ISBLK(x))

  return ((!iflag || inlist(statbuf->st_ino)) &&
	(aflag || !dotfile(name)) &&
	(!sflag || S_SPECIAL(statbuf->st_mode)));
}


void traverse(dirname)
char *dirname;
{
  struct dirent *dirent;
  DIR *dir;
  struct stat statbuf;
  int len;

  len = strlen(dirname);
  if (stat(dirname, &statbuf) < 0) {
	fprintf(stderr, "could not stat %s: %s\n", dirname, strerror(errno));
	return;
  }
  if (toprint(&statbuf, dirname))
	printf("%5ld %s\n", (long) statbuf.st_ino, dirname+skip_len);

  if (!dotfile(dirname) && S_ISDIR(statbuf.st_mode)) {
	if ((dir = opendir(dirname)) == NULL) {
		fprintf(stderr, "could not open %s: %s\n", dirname,
			strerror(errno));
		return;
	}
	dirname[len++] = '/';
	while ((dirent = readdir(dir)) != NULL) {
		strcpy(dirname+len, dirent->d_name);
		traverse(dirname);
	}
	closedir(dir);
  }
}


int main(argc, argv)
int argc;
char *argv[];
{
  FILE *mtb;
  char line[128];
  char mf1[32], mf2[32], mf3[32], mf4[32], mf5[32];
  int r;

  progname = argv[0];

  while ((opt = getopt(argc, argv, "i:as")) != EOF) {
	switch (opt) {
	case 'i':
		if (nr_inodes > 0)
			usage();
		iflag = 1;
		readilist(optarg);
		break;
	case 'a':
		aflag = 1;
		break;
	case 's':
		sflag = 1;
		break;
	}
  }
  if (optind > argc-1)
	usage();
  filesystem = argv[optind];

  /* See if device is mounted already by searching mtab (old or new) */
  if ((mtb = fopen("/etc/mtab", "r")) == NULL) {
	fprintf(stderr, "%s: No /etc/mtab found.\n", progname);
	myexit(1);
  }
  path[0] = '\0';
  while (!feof(mtb)) {	/* see if mounted already */
  if (fgets(line, 128, mtb)) {
  	mf1[0] = mf2[0] = mf3[0] = mf4[0] = mf5[0] = '\0';
  	r = sscanf(line, "%s%s%s%s%s", mf1, mf2, mf3, mf4, mf5);
		if (!strcmp(filesystem, mf1)) {
			if (r > 4)
				strcpy(path, mf5);	/* hmmm.. old mtab */
			else {
				if (!strcmp(mf3, "root"))
					strcpy(path, "/");	/* old mtab */
				else
					strcpy(path, mf2);	/* new mtab */
			}
			break;
		}
	}
  }
  fclose(mtb);
  if (!path[0]) {	/* not mounted so mount temporarily */
  	mnt_point = tmpnam((char *)NULL);
  	mkdir(mnt_point, 0777);
  	if (mount(filesystem, mnt_point, 1) < 0) {
		perror("mount");
		myexit(1);
	  }
	  strcpy(path, mnt_point);
  }
  skip_len = strlen(path);
  
  traverse(path);
  myexit(0);

  /* NOTREACHED */
  return(0);
}
