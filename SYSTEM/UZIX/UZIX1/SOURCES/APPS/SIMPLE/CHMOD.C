/* C H M O D . C
 *
 * Usage: chmod asciimode|octalmode file(s)
 * Where:
 *	asciimode: the mode to set, use [ugoa][-+][rwx] to:
 *		apply to (u)ser, (g)roup, (o)ther or (a)ll [default: u]
 *		remove(-) or set(+) bits [required],
 *		apply to the (r)ead, (w)rite, e(x)ec bits
 *	octalmode: mode as an octal number
 *	file(s): the files to process
 */
#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>

static int buildmask(register char *s, int *owner, int *setflag, 
			int *readmode, int *writemode, int *execmode) {
	register int state = 0;

	*owner = *readmode = *writemode = *execmode = 0;
	for (; *s; ++s) {
		switch (state) {
		case 0:	/* expecting owner info */
			if (*s == 'u')		*owner |= S_IRWXU;
			else if (*s == 'g')	*owner |= S_IRWXG;
			else if (*s == 'o')	*owner |= S_IRWXO;
			else if (*s == 'a')	*owner |= (S_IRWXU | S_IRWXG | S_IRWXO);
			else if (*s == '-' || *s == '+') {
				*owner |= S_IRWXU;
				s--;
			}
			else	return 0;
			state = 1;
			break;
			
		case 1:	/* expecting set or remove info */
			if (*s == '-')		*setflag = 0;
			else if (*s == '+')	*setflag = 1;
			else	return 0;
			state = 2;
			break;
		
		case 2:	/* expecting modebits info */
			if (*s == 'r')		*readmode = (S_IRUSR|S_IRGRP|S_IROTH);
			else if (*s == 'w')	*writemode = (S_IWUSR|S_IWGRP|S_IWOTH);
			else if (*s == 'x')	*execmode = (S_IXUSR|S_IXGRP|S_IXOTH);
			else	return 0;
			break;
		}
	}
	return 1;		/* successful parsing */
}

int main(argc, argv)
	int argc;
	char **argv;
{
	int owner, setflag, readmode, writemode, execmode, newmode;
	int octal = 0, ret = 0, mode;
	char *cp = *++argv;
	struct stat statbuf;

	if (--argc == 0) {
		fprintf(stderr, "usage: chmod asciimode|octalmode filename ...\n");
		return 0;
	}
	if (*cp >= '0' && *cp <= '7') {
		for (mode = 0; *cp >= '0' && *cp <= '7'; ++cp) {
			mode <<= 3;
			mode += *cp - '0';
		}
		if (*cp) {
			fprintf(stderr, "Bad octal mode\n");
			return 1;
		}
		octal = 1;
	}
	else if (!buildmask(cp, &owner, &setflag, &readmode,
			    &writemode, &execmode)) {
		fprintf(stderr, "Bad ascii mode %s\n", cp);
		return 1;
	}
	while (--argc >= 1) {
		cp = *++argv;
		if (stat(cp, &statbuf)) {
			fprintf(stderr, "Can't stat ");
			perror(cp);
			++ret;
			continue;
		}
		if (octal)
			newmode = mode;
		else {
			newmode = statbuf.st_mode;
			if (setflag)
				newmode |= (readmode | writemode | execmode) & owner;
			else 	newmode &= ~((readmode | writemode | execmode) & owner);
		}
		if (chmod(cp, newmode)) {
			++ret;
			fprintf(stderr, "Problems setting octal mode %o for ",
				       newmode);
			perror(cp);
		}
	}
	return ret;
}
