/* mknod.c
 */
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define makedev(maj, min)  (((maj) << 8) | (min))

static void wr2 __P((char *s));

static void wr2(s)
	char *s;
{
	write(STDERR_FILENO, s, strlen(s));
}

int main(argc,argv)
	int argc;
	char **argv;
{
	unsigned newmode, filetype, major = 0, minor = 0;
	char *p;

	newmode = 0666 & ~umask(0);

	if (strcmp(argv[1],"-m") == 0) {
		argc-=2;
		argv+=2;
		p = *argv;
		if (*p >= '0' && *p <= '7') {
			for (newmode = 0; *p >= '0' && *p <= '7'; ++p) {
				newmode <<= 3;
				newmode += *p - '0';
			}
			if (*p) {
				wr2("Bad octal mode\n");
				return 1;
			}
		}
	}
	if (argc == 2 || argc == 5) {
		if (argc == 5) {
			switch(argv[2][0]) {
			case 'b':	filetype = S_IFBLK;	break;
			case 'c':	
			case 'u':	filetype = S_IFCHR;	break;
			default:	goto Usage;
			}
			major = atoi(argv[3]);
			minor = atoi(argv[4]);
		}
		else	filetype = S_IFREG;
		if (mknod(argv[1], newmode | filetype, (major << 8) | minor)) {
			wr2("mknod: cannot make device ");
			wr2(argv[1]);
			wr2("\n");
			return 1;
		}
	}
	else {
Usage:		wr2("usage: mknod [-m mode] name [b|c|u major minor]\n");
	}
	return 0;
}

