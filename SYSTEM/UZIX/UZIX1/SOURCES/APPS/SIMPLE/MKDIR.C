/* mkdir.c
 */
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

static unsigned short newmode;

static int make_dir __P((char *name, int f));
static void wr2 __P((char *s));

static int make_dir(name,f)
	char *name;
	int f;
{
	char *line, iname[256];

	strcpy(iname, name);
	line = rindex(iname,'/');
	if ((line != NULL) && (line != iname) && f) {
		while ((line > iname) && (*line == '/'))
			--line;
		line[1] = 0;
		make_dir(iname,1);
	}
	return mkdir(name, newmode) && !f;
}

static void wr2(s)
	char *s;
{
	write(STDERR_FILENO, s, strlen(s));
}

int main (argc,argv)
	int argc;
	char **argv;
{
	char *p;
	int i, n, parent = 0, er = 0;

	newmode = 0666 & ~umask(0);

	argc--;
	argv++;
	while ((argc > 0) && (**argv == '-')) {
		argc--;
		p = *argv++ ;
		while (*++p) switch (*p) {
			case 'm':
				argc--;
				p = *argv++ ;
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
				p--;	/* *p=0, exit while/switch loop */
				break;
			case 'p':
				++parent;
				break;
			default:
				wr2("Unknown option\n");
				return 0;
		}
	}

	if (argc < 1) {
		wr2("usage: mkdir [-p] [-m mode] dirname ...\n");
		return 1;
	}

	for (i = 0; i < argc; i++) {
		p = argv[i];
		n = strlen(p)-1;
		while (p[n] == '/')
			p[n--] = '\0';
		if (make_dir(p,parent)) {
			wr2("mkdir: cannot create directory ");
			wr2(p);
			wr2("\n");
			er = 1;
		}
	}
	return er;
}

