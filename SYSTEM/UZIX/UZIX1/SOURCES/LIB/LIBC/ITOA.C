/* numeric/string conversions package
 */

#include "cvt.h"

/**************************** ltoa.c ****************************/
#ifdef L_itoa
/*
 * filename - ltoa.c
 *
 * function(s)
 *	  itoa	    - converts an integer to a string
 *	  ltoa	    - converts a long to a string
 *	  ultoa     - converts an unsigned long to a string
 *	  __longtoa - converts a long to a character string
 */

/*
Name		__longtoa - converts a long to a character string
Usage		char *__longtoa (unsigned long value, char *strP, int radix,
					char maybeSigned, char hexStyle);
Prototype in	stdlib.h

Description	converts a long to a character string. see itoa below.

Return value	pointer to the string
*/
/*#pragma warn -use*/
char *__longtoa(unsigned long value, char *strP, int radix,
			char maybeSigned, char hexStyle) {
	char buf[34];
	register char *di = strP, *si = buf;
#ifdef __TURBOC__
	int *p = (int *)&value;

	hexStyle -= 10;
	/* If the request is invalid, generate an empty result */
	if (radix > 36 || radix < 2)
		goto lta_end;
	if (((int *)&value)[1] < 0 && maybeSigned) {
		*di++ = '-';
		value = -value;
	}
	/* Now loop, taking each digit as modulo radix, and reducing the value
	 * by dividing by radix, until the value is zeroed.  Note that
	 * at least one loop occurs even if the value begins as 0,
	 * since we want "0" to be generated rather than "".
	 */
	/*  BX = radix,  CX:AX = value */
	_CX = radix;
	if (((int *)&value)[1] == 0)
		goto lta_shortLoop;

lta_longLoop:
	do {
		_AX = ((int *)&value)[1];
		__emit__(0x33,0xD2); /* xor dx,dx */
		__emit__(0xF7,0xF1); /* div cx */
		p[1] = _AX;
		_AX = ((int *)&value)[0];
		__emit__(0xF7,0xF1); /* div cx */
		p[0] = _AX;
		*si++ = _DL;
	} while (p[1] != 0);	/* value does not fit in 16 bits */
	goto lta_shortTest;

lta_shortLoop:
	 do {
		_AX = ((int *)&value)[0];
		__emit__(0x33,0xD2); /* xor dx,dx */
		__emit__(0xF7,0xF1); /* div cx */
		p[0] = _AX;
		*si++ = _DL;
lta_shortTest:	;
	} while (p[0] != 0);
	/* The value has now been reduced to zero and the
	 * digits are in the buffer.
	 */
	_CX = si-buf;	/* CX = length of numeral */
	/* The digits in the buffer must now be copied in reverse order into
	 *  the target string, translating to ASCII as they are moved.
	 */
	while ((int)--_CX >= 0) {
		_AL = *--si;
		if (_AL < 10)
			_AL += '0';
		else	_AL += hexStyle;
		*di++ = _AL;
	}
#else
	uint *p = (uint *)&value;
	uchar al, cx;

	hexStyle -= 10;
	/* If the request is invalid, generate an empty result */
	if (radix > 36 || radix < 2)
		goto lta_end;
	if (p[1] & 0x8000 && maybeSigned) {
		*di++ = '-';
		value = -value;
	}
	/* Now loop, taking each digit as modulo radix, and reducing the value
	 * by dividing by radix, until the value is zeroed.  Note that
	 * at least one loop occurs even if the value begins as 0,
	 * since we want "0" to be generated rather than "".
	 */
	if (p[1] == 0)
		goto lta_shortLoop;
	do {
		*si++ = (uchar)(value % radix);
		value /= radix;
	} while (p[1] != 0);	/* value does not fit in 16 bits */
	goto lta_shortTest;

lta_shortLoop:
	 do {
		*si++ = (uchar)((uint)value % radix);
		p[0] = ((uint)value / radix);
lta_shortTest:	;
	} while (p[0] != 0);
	/* The value has now been reduced to zero and the
	 * digits are in the buffer.
	 */
	cx = (uchar)(si-buf);	/* length of numeral */
	/* The digits in the buffer must now be copied in reverse order into
	 *  the target string, translating to ASCII as they are moved.
	 */
	while (cx != 0) {
		al = *--si;
		if (al < 10)
			al += '0';
		else	al += hexStyle;
		*di++ = al;
		--cx;
	}
#endif
	/* terminate the output string with a zero. */
lta_end:
	*di = 0;
	return	strP;		/* return a pointer to the string */
}
/*#pragma warn .use*/

/*
Name		itoa  - converts an integer to a string
		ltoa  - converts a long to a string
		ultoa - converts an unsigned long to a string

Usage		char *itoa(int value, char *strP, int radix);
		char *ltoa(long value, char *strP, int radix);
		char *ultoa(unsigned long value, char *strP, int radix);

Prototype in	stdlib.h

Description	These functions  convert value to a  null-terminated string
		and  store the	result in  string. With  itoa, value  is an
		integer;  with ltoa  it is  a  long;  with ultoa  it is  an
		unsigned long.	__longtoa is the  internal routine used for
		all these conversions to ASCII.

		radix specifies the base to be used in converting value. it
		must be between  2 and 36 (inclusive). With  itoa and ltoa,
		if value is negative, and  radix is 10, the first character
		of string is  the minus sign (-). This does  not occur with
		ultoa. Also, ultoa performs no overflow checking.

		maybeSigned is treated as a boolean. If false then value is
		treated  as unsigned  long and	no sign  will be  placed in
		*strP.

		hexStyle  may take  the values	'a' or	'A' and  determines
		whether lower or  upper case alphabetics are used  when the
		radix is 11 or greater.

		Note: The space  allocated for string must be  large enough
		to hold the returned  string including the terminating null
		character (\0).  itoa can return  up to 17  bytes; ltoa and
		ultoa, up to 33 bytes.

Return value	All these functions return a pointer to string. There is no
		error return.
*/
char *itoa(value, strP, radix)
	int value;
	char *strP;
	int radix;
{
	char hex = 'A';

	if (radix < 0) {
		hex = 'a';
		radix = -radix;
	}
	return	__longtoa ((radix == 10) ? (long) value :
			   (unsigned long)((unsigned)value),
			   strP, radix, 1, hex);
}
#endif

