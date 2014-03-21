/* rmdir.c
 */
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

unsigned short newmode;

static void wr2 __P((char *s));

static void wr2(s)
	char *s;
{
	write(STDERR_FILENO, s, strlen(s));
}

int remove_dir(name, f)
	char *name;
	int f;
{
	int er, era = 2;
	char *line;

	while ((er = rmdir(name)) == 0 &&
	       (line = rindex(name, '/')) != NULL &&
	       f) {
		while (line > name && *line == '/')
			*line-- = 0;
		era = 0;
	}
	return (er && era);
}

int main(argc, argv)
	int argc;
	char **argv;
{
	char *p;
	int i, n, parent = 0, er = 0;

	if (argv[1][0] == '-' && argv[1][1] == 'p')
		parent = 1;
	newmode = 0666 & ~umask(0);
	for (i = parent + 1; i < argc; i++) {
		p = argv[i];
		n = strlen(p)-1;
		if (p[0] != '-') {
			while (p[n] == '/')
				p[n--] = '\0';
			if (remove_dir(p, parent)) {
				perror(argv[0]);
				er = 1;
			}
		}
		else {
			wr2("usage: rmdir [-p] directory...\n");
			return 1;
		}
	}
	return er;
}
