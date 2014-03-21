/* tee.c
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
	int fd, bytes = 0;
	unsigned char buf[BUFSIZ];

	if (argc != 2) {
		write(STDERR_FILENO, "usage: tee filename\n", 20);
		return 0;
	}
	if ((fd = creat(argv[1], 0666)) <= 0) {
		write(STDERR_FILENO, "tee: can't create file\n", 23);
		return 1;		/* missing file */
	}
	while ((bytes = read(STDIN_FILENO, buf, sizeof(buf))) > 0) {
		if (write(fd, buf, bytes) != bytes ||
		    write(STDOUT_FILENO, buf, bytes) != bytes)
			return 2;	/* write error - no space */
	}
	close(fd);
	return 0;
}

