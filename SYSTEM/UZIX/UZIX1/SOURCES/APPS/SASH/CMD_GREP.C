/*
 * Copyright (c) 1993 by David I. Bell
 * Permission is granted to use, distribute, or modify this source,
 * provided that this copyright notice remains intact.
 *
 * The "grep" built-in command.
 */
#include "sash.h"

#ifdef CMD_GREP

static BOOL search __P((char *, char *, BOOL));

/*
 * See if the specified word is found in the specified string.
 */
static BOOL search(string, word, ignorecase)
	char *string;
	char *word;
	BOOL ignorecase;
{
	char *cp1, *cp2;
	int lowfirst, ch1, ch2, len = strlen(word);

	if (!ignorecase) {
		while (TRUE) {
			if ((string = strchr(string, word[0])) == NULL)
				return FALSE;
			if (memcmp(string, word, len) == 0)
				return TRUE;
			string++;
		}
	}
	/* Here if we need to check case independence.
	 * Do the search by lower casing both strings.
	 */
	lowfirst = *word;
	if (isupper(lowfirst))
		lowfirst = tolower(lowfirst);
	while (TRUE) {
		while (*string &&
		       *string != lowfirst &&
		       (!isupper(*string) || (tolower(*string) != lowfirst)))
			++string;
		if (*string == '\0')
			break;
		cp1 = string;
		cp2 = word;
		do {
			if (*cp2 == '\0')
				return TRUE;
			ch1 = *cp1++;
			if (isupper(ch1))
				ch1 = tolower(ch1);
			ch2 = *cp2++;
			if (isupper(ch2))
				ch2 = tolower(ch2);
		} while (ch1 == ch2);
		string++;
	}
	return FALSE;
}

void do_grep(argc, argv)
	int argc;
	char  **argv;
{
	FILE *fp;
	long line;
	BOOL tellname;
	char *word, *name, *cp, buf[1024];
	BOOL ignorecase = FALSE;
	BOOL tellline = FALSE;

	argc--;
	argv++;
	if (**argv == '-') {
		argc--;
		cp = *argv++;
		while (*++cp) {
			switch (*cp) {
			case 'i': ++ignorecase;	break;
			case 'n': ++tellline; break;
			default:
				fprintf(stderr, "Unknown option -%c\n",*cp);
				return;
			}
		}
	}
	word = *argv++;
	argc--;
	tellname = (argc > 1);
	while (argc-- > 0) {
		name = *argv++;
		if ((fp = fopen(name, "r")) == NULL) {
			perror(name);
			continue;
		}
		for (line = 0; fgets(buf, sizeof(buf), fp); ) {
			if (intflag) {
				fclose(fp);
				return;
			}
			line++;
			cp = &buf[strlen(buf) - 1];
			if (*cp != '\n')
				fprintf(stderr, "%s: Line too long\n", name);
			if (search(buf, word, ignorecase)) {
				if (tellname)	printf("%s: ", name);
				if (tellline)	printf("%d: ", line);
				fputs(buf, stdout);
			}
		}
		if (ferror(fp))
			perror(name);
		fclose(fp);
	}
}
#endif	/* CMD_GREP */
