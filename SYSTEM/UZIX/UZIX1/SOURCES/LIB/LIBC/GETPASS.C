/* getpass.c
 */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys\ioctl.h>

static char *_gets(buf, len)
	char *buf;
	int len;
{
	int ch, i = 0;
	
	while (i < len) {
		if ((ch = _getchar()) == EOF && i == 0)
			return NULL;
#if 0
		if (ch >= ' ')
			_putchar(ch);
		else {
			_putchar('^');
			_putchar(ch + '@');
		}
#endif
		if ((ch == 'C' & 037) || (ch == 'Z' & 037))
			return NULL;
		if (ch == '\n' || ch == '\r')
			break;
		buf[i++] = ch;
	}
	buf[i] = 0;
	return buf;
}

char *getpass(prompt)
	char *prompt;
{
	static char result[128];
	int raw;

	/* display the prompt */
	fputs(prompt, stdout);
	fflush(stdout);
	raw = ioctl(STDIN_FILENO, TTY_RAW);
	/* read the input */
	if (_gets(result, sizeof(result) - 1) == NULL)
		result[0] = 0;
	if (!raw)
		ioctl(STDIN_FILENO, TTY_COOKED);
	return result;
}
