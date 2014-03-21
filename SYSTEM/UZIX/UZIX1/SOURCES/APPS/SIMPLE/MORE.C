/* Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * jun/99: Adriano Cunha <adrcunha@dcc.unicamp.br>
 *         added piped input capability
 *
 * set/99: Adriano Cunha <adrcunha@dcc.unicamp.br>
 *         added next file indication and rewind command
 */
#include <stdio.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <paths.h>
#include <fcntl.h>

void main(argc, argv)
	int argc;
	char **argv;
{
	FILE *fp;
	int ch, line, col, viastdin = 0, tty = STDIN_FILENO;
	char *name, buf[8];

	if (argc < 2) {
		if (isatty(STDIN_FILENO)) {
			fprintf(stderr, "usage: more filename ...\n");
			return;
		} else {
			viastdin=1;
			argc++;
			tty = open(_PATH_CONSOLE, O_RDONLY);
		}
	}
	ioctl(tty, TTY_RAW);
	while (argc-- > 1) {
Again:		if (!viastdin) {
			name = *(++argv);
			if ((fp = fopen(name, "r")) == NULL) {
				perror(name);
				continue;
			}
	 		printf("<< %s >>\n", name);
	 	} else fp=stdin;
		line = 1;
		col = 0;
		while (fp && ((ch = fgetc(fp)) != EOF)) {
			switch (ch) {
				case '\n':
					line++;
				case '\r':
					col = 0;
					break;
				case '\t':
					col = ((col + 1) | 0x07) + 1;
					break;
				case '\b':
					if (col > 0)
						col--;
					break;
				default:
					col++;
			}
			putchar(ch);
			if (col >= 80) {
				col -= 80;
				line++;
			}
			if (line < 24)
				continue;
			if (col > 0)
				putchar('\n');
			printf("--More--");
			if (argc > 1) printf(" (Next file: %s)", *(argv+1)?*(argv+1):"none");
			fflush(stdout);
			if (read(tty, buf, 1) < 0) {
				if (fp)
					fclose(fp);
				break;
			}
			col = 0;
			ch = buf[0];
			if (ch == ':') {
				putchar(':');
				if (read(tty, buf, 1) < 0) {
					if (fp)
						fclose(fp);
					break;
				}
				ch = buf[0];
			}
			putchar('\n');
			switch (ch) {
				case 'P':
				case 'p':
					argc += 2;
					argv -= 2;
					fclose(fp);
					fp = NULL;
					break;
				case 'N':
				case 'n':
					fclose(fp);
					fp = NULL;
					break;
				case 'Q':
				case 'q':
					fclose(fp);
					goto End;
				case '\'':
					argc++;
					argv--;
					fclose(fp);
					fp = NULL;
					break;
				case '\n':
				case '\r':
					--line;
					continue;
			}
			line = 1;
		}
		if (col > 0) putchar('\n');
		if (fp && !viastdin)
			fclose(fp);
	}
End:	ioctl(tty, TTY_COOKED);
	if (viastdin) close(tty);
}

