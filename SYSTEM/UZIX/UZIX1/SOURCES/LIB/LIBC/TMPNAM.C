/* tmpnam.c
 *
 * function(s)
 *	  __mkname - builds a file name of the form TMPXXXXX.$$$
 *	  tmpnam   - builds a unique file name
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <paths.h>
#include <syscalls.h>
 
static	char	template[64];
unsigned long	_tmpnum;

static char *__mkname __P((char *s, unsigned long num));

/*
Name		__mkname - builds a file name of the form /tmp/NNNNNNN
Usage		char * __mkname(char *s, unsigned long num);
Return value	a file name of the form /tmp/NNNNNNN
*/
static char *__mkname(s, num)
	char *s;
	unsigned long num;
{
	/* If no buffer provided, use internal template */
	if (s == NULL)
		s = template;
	strcpy(s, _PATH_TMP);
	ultoa(num, s + strlen(s), 10);
	return s;
}

/* tmpnam - builds a unique file name
 * Usage	char *tmpnam(char *s);
 * Prototype in	stdio.h
 * Return value	a unique temporary file name
 */
char *tmpnam(s)
	char *s;
{
	do {
		s = __mkname(s, _tmpnum += 13);
	} while (access(s, 0) != -1);
	return s;
}

