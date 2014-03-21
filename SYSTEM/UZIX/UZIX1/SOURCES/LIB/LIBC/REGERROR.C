/* regerror.c
 */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <regexp.h>

void regerror(s)
	char *s;
{
#ifdef ERRAVAIL
	error("regexp: %s", s);
#else
	fprintf(stderr, "regexp(3): %s", s);
	exit(1);
#endif
}
