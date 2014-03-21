/* numeric/string conversions package
 */

#include "cvt.h"

#ifdef FLOAT
/**************************** strtod.c ****************************/
#ifdef L_strtod
#include <ctype.h>

double strtod(nptr, endptr)
	register char *nptr, **endptr;
{
	double number, mult;
	int digits, negative, exp, exp_negative, exponent;

	/* advance beyond any leading whitespace */
	while (isspace(*nptr))
		nptr++;
	/* check for optional '+' or '-' */
	negative = 0;
	if (*nptr == '-') {
		++negative;
		++nptr;
	}
	else if (*nptr == '+')
		++nptr;
	while (*nptr == '0')
		nptr++;
	exponent = digits = 0;
	number = 0; 
	while (isdigit(*nptr)) {
		if (digits > 33)
			++exponent;
		else {
			number *= 10;
			number += (*nptr - '0');
		}
		++nptr;
		++digits;
	}
	if (*nptr == '.') {
		++nptr;
		if (digits == 0) {
			while (*nptr == '0') {
				--exponent;
				++nptr;
			}
		}
		while (isdigit(*nptr)) {
			if (digits > 33)
				;
			else {
				number *= 10;
				number += (*nptr - '0');
				--exponent;
			}
			++nptr;
			++digits;
		}
	}
	if (*nptr == 'e' || *nptr == 'E') {
		nptr++;
		exp_negative = 0;
		if (*nptr == '-') {
			++exp_negative;
			++nptr;
		}
		else if (*nptr == '+')
			++nptr;
		exp = 0; 
		while (isdigit(*nptr)) {
			exp *= 10;
			exp += (*nptr++ - '0');
		}
		if (number != 0) {
			if (exp_negative)
				exp = -exp;
			mult = 10;
			if ((exp += exponent) < 0) {
				exp = -exp;
				mult = 0.1;
			}
			while (exp-- != 0)
				number *= mult;
		}
	}
	if (negative)
		number = -number;
	if (endptr != NULL)
		*endptr = nptr;
	return number;
}
#endif
#endif

