/*

	LIB3.C  Standard library functions  -- PART III (Ver 1.1)


				For Ver 1.1
		18-Jul-87       change  _scn, scanf, fscanf, sscanf
					to use getc().
				change  return code from scan.
				add     _scnret, _getach, _sscn, _sscn2
		21-Oct-87       rename  _sscn2 to _suget
				debug   _igs, _bc, _scn, _suget
				remove  _scnret, _getach
		30-Oct-87       debug   _spr, _sspr
				ver 1.10s

	This file contains following functions.

	_gv2            _uspr           _spr            printf
	fprintf         _sspr           sprintf
	_igs            _bc             _scn            scanf
	fscanf          _sscn           _sung           sscanf

	The functions whose name begin with underscore character
	are only used internally.
*/

#include        "stdio.h"
#pragma         nonrec

unsigned _gv2(p)
char    **p;
{
    unsigned n;
    char    c;      /* char must be unsigned */

    for (n = 0; (c = **p - '0') < 10; (*p)++)
	n = n * 10 + c;
    return (n);
}


recursive TINY  _uspr(str, n, radix)
char    **str;
unsigned n;
TINY    radix;
{
    TINY    len;
    char    r;

    len = (n >= radix) ? _uspr(str, n/radix, radix) : 0;
    r = n % radix;
    *(*str)++ = (r < 10) ? r + '0' : r - 10 + 'A';
    return (len + 1);
}


STATUS  _spr(fmt, outfunc, ___)
char    **fmt;
STATUS  (*outfunc)();
char    *___;           /* pointer for any type */
{
    char    c, *format;
    char    buf[10], *ptr, padch;
    TINY    radix;
    BOOL    dflag, leftjust;
    int     field, digits, *param;

    format = *fmt++;
    param = (int *)fmt;

    while (c = *format++) {
	if (c == '%') {
	    ptr = buf;
	    digits = 6;
	    leftjust = dflag = NO;
	    if (*format == '-') {
		format++;
		leftjust = YES;
	    }
	    padch = ((c = *format) == '0') ? '0' : ' ';
	    field = isdigit(c) ? _gv2(&format) : 0;
	    if ((c = *format++) == '.') {
		digits = _gv2(&format);
		dflag = YES;
		c = *format++;
	    }
	    switch (toupper(c)) {

	    case 'X':
		radix = 16;     goto nums;
	    case 'O':
		radix = 8;      goto nums;
	    case 'D':
		if (*param < 0) {
		    *param = -*param;
		    *ptr++ = '-';
		    field--;
		}
	    case 'U':
		radix = 10;

	    nums:
		field -= _uspr(&ptr, *param++, radix);
		goto pad;

	    case 'S':
		ptr = (char *)*param++;
		field -= strlen(ptr);
		goto spad;

	    case 'C':
		*ptr++ = *param++;
		field--;
	    pad:
		*ptr = '\0';
		ptr = buf;
		dflag = NO;

	    spad:
		if (!leftjust)
		    while (field-- > 0)
		    if ((*outfunc)(padch, ___) == ERROR)
			return (ERROR);
		while (*ptr) {
		    if (!dflag || digits > 0) {
		    if ((*outfunc)(*ptr, ___) == ERROR)
			return (ERROR);
		    digits--;
		    }
		    ptr++;
		}
		if (leftjust)
		    while (field-- > 0)
		    if ((*outfunc)(' ', ___) == ERROR)
			return (ERROR);
		break;

	    case '\0':
		return (OK);
	    default:
		if ((*outfunc)(c, ___) == ERROR)
		    return (ERROR);
	    }
	}
	else if ((*outfunc)(c, ___) == ERROR)
	    return (ERROR);
    }
    return (OK);
}



STATUS  printf(nargs, format)
int     nargs;
char    *format;
{
    return (_spr(&format, putc, stdout));
}

STATUS  fprintf(nargs, iobuf, format)
int     nargs;
FILE    *iobuf;
char    *format;
{
    return (_spr(&format, putc, iobuf));
}

STATUS  _sspr(c, ptr)
char    c, **ptr;
{
    *(*ptr)++ = c;
    return (OK);
}

VOID    sprintf(nargs, buffer, format)
int     nargs;
char    *buffer, *format;
{
    _spr(&format, _sspr, &buffer);
    *buffer = '\0';
}




int     _igs(func, ___)
int     (*func)();
char    *___;           /* pointer to FILE or (char *) */
{
    int     c;

    while ((c = (*func)(___)) != EOF && isspace((char)c))
	;
    return (c);
}

TINY    _bc(c, b)
char    c;
TINY    b;
{
    if (isalpha(c))
	c = toupper(c) - 'A' + 10;
    else if (isdigit(c))
	c -= '0';
    else
	return (ERROR);
    return ((c < b)? c: ERROR);
}

int     _scn(fmt, infunc, ___, ugfunc)
char    **fmt;
int     (*infunc)();
char    *___;           /* pointer to FILE or (char *) */
int     (*ugfunc)();
{
    char    *format, fmtchar, *s;
    BOOL    assign, matched;
    TINY    radix, valc;
    int     c, **param, n, sign, value;

    format = *fmt++;
    param = (int **)fmt;
    n = 0;
    matched = YES;
    while (matched && (fmtchar = *format++)) {
	if (fmtchar == '%') {
	    assign = YES;
	    if ((fmtchar = *format++) == '*') {
		assign = NO;
		fmtchar = *format++;
	    }
	    switch (fmtchar = toupper(fmtchar)) {
	    case 'X':
		radix = 16; goto val;
	    case 'O':
		radix = 8;  goto val;
	    case 'U':
	    case 'D':
		radix = 10;
	    val:
		c = _igs(infunc, ___);
		sign = 1;
		if (fmtchar == 'D' && c == '-') {
		    sign = -1;
		    c = (*infunc)(___);
		    }
		if (_bc((char)c, radix) != ERROR) {
		    value = 0;
		    while ((valc = _bc((char)c, radix)) != ERROR) {
			value = value * radix + valc;
			c = (*infunc)(___);
		    }
		    if (assign) {
			**param++ = value * sign;
			n++;
		    }
		}
		else
		    matched = NO;
		break;

	    case 'S':
		if ((c = _igs(infunc, ___)) != EOF) {
		    s = (char *)*param;
		    while (c != EOF && !isspace((char)c)) {
			if (assign)
			    *s++ = c;
			c = (*infunc)(___);
		    }
		    if (assign) {
			*s = '\0';
			param++;
			n++;
		    }
		}
		break;

	    case 'C':
		if ((c = (*infunc)(___)) != EOF) {
		    if (assign) {
			*((char *)*param++) = c;
			n++;
		    }
		    continue;
		}
		break;

	    default:
		return (n);
	    }
	}
	else if (isspace(fmtchar)) {
	    c = _igs(infunc, ___);
	}
	else {
	    if ((c = (*infunc)(___)) == fmtchar)
		continue;
	    matched = NO;
	}
	/* comes here with unmatched character in c */
	if (c == EOF)
	    return ((n == 0)? EOF: n);
	else
	    (*ugfunc)((char)c, ___);    /* prepare for next scan */
    }
    return (n);
}



int     scanf(nargs, format)
int     nargs;
char    *format;
{
    return (_scn(&format, getc, stdin, ungetc));
}

int     fscanf(nargs, iobuf, format)
int     nargs;
FILE    *iobuf;
char    *format;
{
    return (_scn(&format, getc, iobuf, ungetc));
}

int     _sscn(ptr)
char    **ptr;
{
    char    c;

    if ((c = *(*ptr)++) == '\0') {
	(*ptr)--;
	return (EOF);
    }
    return (c);
}

VOID    _suget(c, ptr)
char    c;
char    **ptr;
{
    --(*ptr);
}

int     sscanf(nargs, line, format)
int     nargs;
char    *line, *format;
{
    return (_scn(&format, _sscn, &line, _suget));
}
