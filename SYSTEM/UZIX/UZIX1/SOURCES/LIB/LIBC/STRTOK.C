/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strtok ************************************/
#ifdef L_strtok
static char *olds = 0;

/* Parse S into tokens separated by characters in DELIM.
   If S is NULL, the last string strtok() was called with is
   used.  For example:
	char s[] = "-abc=-def";

	x = strtok(s, "-");		// x = "abc"
	x = strtok(NULL, "=-"); 	// x = "def"
	x = strtok(NULL, "=");		// x = NULL
					// s = "abc\0-def\0"
*/
char *strtok(s, delim)
	register char *s;
	register char *delim;
{
	char *token;

	if (s == 0) {
		if (olds == 0)
			return 0;
		s = olds;
	}
	/* Scan leading delimiters.  */
	s += strspn(s, delim);
	if (*s == '\0') {
		olds = 0;
		return 0;
	}
	/* Find the end of the token.  */
	token = s;
	s = strpbrk(token, delim);
	if (s == 0)
		/* This token finishes the string.	 */
		olds = 0;
	else {
		/* Terminate the token and make OLDS point past it.  */
		*s = '\0';
		olds = s + 1;
	}
	return token;
}
#endif
