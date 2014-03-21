/* kitten (baby-cat)
 * (C) 1997 Chad Page
 *
 * jun/99: Adriano Cunha <adrcunha@dcc.unicamp.br>
 *         added piped input capability
 */

#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>

int main(argc, argv)
	int argc;
	char **argv;
{
	int fd, i = 1, bytes = 0, viastdin = 0;
	unsigned char buf[BUFSIZ];
	char *p;

	if (argc < 2) {
		if (isatty(STDIN_FILENO)) {
			write(STDERR_FILENO, "usage: cat filename ...\n", 20);
			return 0;
		} else {
			argc++;
			viastdin = 1;
		}
	}
	while (i < argc) {
		i++;
		if (!viastdin) {
			p=argv[i-1];
			if ((fd = open(p, O_RDONLY)) <= 0) {
				write(STDERR_FILENO, "cat: can't open file\n", 21);
				continue;		/* missing file */
			}
		} else fd = STDIN_FILENO;
		while ((bytes = read(fd, buf, sizeof(buf))) > 0) {
			if (write(STDOUT_FILENO, buf, bytes) != bytes)
				return 2;	/* write error - no space */
		}
		if (!viastdin) close(fd);
	}
	return 0;
}
