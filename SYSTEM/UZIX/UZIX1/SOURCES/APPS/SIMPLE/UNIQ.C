/* U N I Q . C
 *
 * Read a file, writing unique (or non-unique) lines.
 *
 * uniq [-options] [-fields] [+letters] [file]
 *
 * Uniq reads a sorted input file, writing each unique line.
 * The following options are defined:
 *	-u	Only print unique lines.
 *	-d	Only print duplicate lines.
 *	-c	Print the number of times each line occurred along with
 *		the line.
 *	-z	As -c, but print outal numbers.
 *	-N.M	Skip over the first N words before checking
 *		for uniqueness.
 *		Skip over the first M letters (in the indicated field).
 *		Note that fields are skipped before letters.
 *	+L	Compare only L letters.
 *
 * A word is defined as "optional spaces or tabs" followed by text up to
 * the first space, tab, or end of line.
 *
 * uniq read from stdin (or file) and write to the stdout.
 *
 * This program is licensed under GNU GPL license.
 *
 */
 
#include <stdio.h>
#include <ctype.h>
#include <alloc.h>
#include <string.h>
#include <stdlib.h>

#define MAXLINE 3000

int	skip_fields = 0;		/* Number of fields to skip */
int	skip_letters = 0;		/* Number of letters to skip */
int	check_letters = 0;		/* Number of letters to test */
int	linecount = 0;			/* How many repetitions */
int	countmode = 0;			/* Counted output */
int	mode = 0;			/* Mode byte, if any */
char	*line1 = NULL;			/* Input buffer 1 */
char	*line2 = NULL;			/* Input buffer 2 */

char *hlp[] = {
	"usage: uniq [-udcz] -[WORDS].[LETTERS] [+LENGTH] [file]",
	"\tu - print unique lines",
	"\td - print duplicated lines",
	"\tc - print the number of times each line occurred",
	"\t    along with the line.",
	"\tz - as -c, but print octal numbers",
	"\tWORDS - skip over the first WORDS words before checking",
	"\tLETTERS - skip over the first LETTERS letters",
	"\tLENGTH - compare only LENGTH letters",
	"\tfile - input file name (stdin if omitted)",
	0
};

void error(char *s1,char *s2) {
	fprintf(stderr, "uniq: %s %s\n", s1, s2 ? s2 : "");
	exit(1);
}

void help(void) {
	register int i = 0;

	while (hlp[i])
		fprintf(stderr,"%s\n",hlp[i++]);
	exit(1);
}

/*
 * Return zero if they don't match.  If they do, return 1.
 */
int equals(char *old, char *new) {
	if (check_letters > 0)
		return (strncmp(old, new, check_letters) == 0);
	return (strcmp(old, new) == 0);
}

/*
 * Output this line.
 */
void output(char *line) {
	if ((mode == 'u' && linecount > 1) || (mode == 'd' && linecount <= 1))
		return;
	if (countmode == 'c')
		printf("%5d\t", linecount);
	else if (countmode == 'z')
		printf("%06o\t", linecount);
	fputs(line,stdout);
}

/* Read a line. return NULL on end of file.  If not end of file, return
 * a pointer to the first byte of the field to check.
 */
char *getline(char *line) {
	register int count;
	register char c, *lp = line;

	if (fgets(lp,MAXLINE,stdin) == NULL)
		return NULL;
	for (count = 0; count < skip_fields; ++count) {
		for (; (c = *lp) == ' ' || c == '\t'; ++lp)
			;
		for (; (c = *lp) != ' ' && c != '\t'; ++lp)
			if (!c)
				return lp;
	}
	for (count = 0; count++ < skip_letters && *lp; ++lp)
		;
	return lp;
}

/*
 * Read lines as long as new == old.  Return a pointer to the field to
 * test in new.	 Exit the program on end of file.
 */
char *check(char *new, char *old, char *oldpos) {
	register char *lp;		/* Random line pointer */

	for (linecount = 0;; ) {
		++linecount;
		if ((lp = getline(new)) == NULL) {
			output(old);
			exit(1);
		}
		if (!equals(oldpos, lp))
			break;
	}
	output(old);
	return lp;
}

void main(int argc, char *argv[]) {
	register char *argp;/* Argument pointer */
	register char c;	/* Temp character */
	register char *lp;	/* Line buffer pointer */

	if ((line1 = (char *)malloc(MAXLINE+1)) == NULL ||
	    (line2 = (char *)malloc(MAXLINE+1)) == NULL)
		error("Not enough memory",0);

	while (--argc > 0) {
		argp = *++argv;
		switch (c = *argp++) {
		case '?':
			help();
		case '+':
			check_letters = atoi(argp);
			break;
		case '-':
			while ((c = *argp++) != 0) {
				switch (c = tolower(c)) {
				case 'c':
				case 'z':
					countmode = c;
					break;
				case 'u':
				case 'd':
					mode = c;
					break;
				default:
					if (!isdigit(c))
						error("Bad switch",*argv);
					for (lp = --argp; isdigit(*lp); ++lp)
						;
					if (lp != argp)
						skip_fields = atoi(argp);
					if (*lp == '.')
						skip_letters = atoi(++lp);
				}
			}
			break;
		default:
			if (freopen(*argv,"rt",stdin) == NULL)
				error("Can't open file",*argv);
		}
	}
	/* Here we go */
	if ((lp = getline(line2)) == 0)		/* Prime the pump */
		exit(1);
	for (;;) {
		lp = check(line1, line2, lp);
		lp = check(line2, line1, lp);
	}
}
