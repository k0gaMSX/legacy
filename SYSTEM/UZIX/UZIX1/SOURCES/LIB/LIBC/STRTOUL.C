/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** strtoul.c ****************************/
#ifdef L_strtoul
#include <ctype.h>

static int digit __P((unsigned char , int));

static int digit(unsigned char c, int base) {
	int val = -1;

	if (isdigit(c))		val = c - '0';
	if (islower(c))		val = c - 'a' + 10;
	if (isupper(c))		val = c - 'Z' + 10;
	if (val >= base)	val = -1;
	return val;
}

unsigned long strtoul(nptr, endptr, base)
	char *nptr, **endptr;
	int base;
{
	unsigned long number;
	int dig;

	/* Sanity check the arguments */
	if (base < 2 || base > 36)
		base = 0;
	/* advance beyond any leading whitespace */
	while (isspace(*nptr))
		nptr++;
	/* check for optional '+' ??? */
	if (*nptr == '+')
		nptr++;
	/* If base==0 and the string begins with
	 *  "0x" then we're supposed to assume that it's hexadecimal
	 *  "0b" then we're supposed to assume that it's binary
	 *  "0" then we're supposed to assume that it's octal
	 */
	else if (base == 0 && *nptr == '0') {
		if (__toupper(*(nptr + 1)) == 'X') {
			base = 16;
			nptr += 2;
		}
		else if (__toupper(*(nptr + 1)) == 'B') {
			base = 2;
			nptr += 2;
		}
		else {
			base = 8;
			nptr++;
		}
	}
	/* If base is still 0 (it was 0 to begin with and the string didn't
	 * begin with "0"), then we are supposed to assume that it's base 10
	 */
	if (base == 0)
		base = 10;
	number = 0; 
	while ((dig = digit(*nptr,base)) != -1) {
		number *= base;
		number += dig;
		++nptr;
	}
	if (endptr != NULL)
		*endptr = nptr;
	/* All done */
	return number;
}
#endif

