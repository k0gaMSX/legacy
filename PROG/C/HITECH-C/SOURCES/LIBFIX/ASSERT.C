
#include	<stdio.h>
#include	<stdlib.h>

int
_fassert(line, file, exp)
char *	file, * exp;
int	line;
{
	fprintf(stderr, 
		"Assertion failed: %s line %d: \"%s\"\n", file, line, exp);
	abort();
}
