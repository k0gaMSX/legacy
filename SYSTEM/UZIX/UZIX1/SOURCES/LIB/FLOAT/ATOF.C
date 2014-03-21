#include	<stdlib.h>
#include	<math.h>
#include	<ctype.h>

double atof(s)
	register char * s;
{
	char	sign, expsign;
	short	exp, eexp;
	double	l = 0, ten = 10.0;

	while (isspace(*s))
		++s;
	expsign = sign = 0;
	if (*s == '-') {
		++s;
		sign = 1;
	}
	while (*s == '0')
		++s;
	for (exp = 0; isdigit(*s); ++s) {
		l *= ten;
		l += (double)(*s - '0');
	}
	if (*s == '.') {
		for (++s; isdigit(*s); ++s) {
			--exp;
			l *= ten;
			l += (double)(*s - '0');
		}
	}
	eexp = 0;
	if (*s == 'e' || *s == 'E') {
		if (*++s == '-') {
			++expsign;
			++s;
		}
		else if (*s == '+')
			++s;
		for (; isdigit(*s); ++s) {
			eexp *= 10;
			eexp += (*s - '0');
		}
		if (expsign)
			eexp = -eexp;
	}
	for (exp += eexp; exp < 0; ++exp)
		l /= ten;
	for (; exp > 0; --exp)
		l *= ten;
	if (sign)
		l = -l;
	return l;
}

