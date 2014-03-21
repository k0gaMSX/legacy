/* dirname.c
 */
#include <unistd.h>
#include <string.h>

void strip_trailing_slashes(path)
	char *path;
{
	char *last = path + strlen(path) - 1;

	while (last > path && *last == '/')
		*last-- = '\0';
}

int main (argc, argv)
	int argc;
	char **argv;
{
	char *line, *p;

	if (argc == 2) {
		strip_trailing_slashes(p = argv[1]);
		line = rindex(p, '/');
		if (line == NULL) {
			p[0] = '.';
			p[1] = 0;
		}
		else {
			while (line > p && *line == '/')
				--line;
			line[1] = 0;
		}
		write(STDOUT_FILENO, p, strlen(p));
		write(STDOUT_FILENO,"\n", 1);
		return 0;
	} else {
		write(STDOUT_FILENO, "usage: dirname filename\n",24);
		return 1;
	}
}

