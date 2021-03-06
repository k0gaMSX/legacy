
/*
	(C) Copyright by ASCII Corporation, 1989
		All rights Reserved.

	File: stdlib.c		Standard Library

	Includes following functions
		abs	min	max	atoi	qsort
		getenv	putenv	perror
*/
#pragma	nonrec
#include <stdio.h>
#include <bdosfunc.h>

#define	PATH_FIRST	(TINY)0	/*  set pathtop		      in _cutpath() */
#define PATH_NEXT	(TINY)1	/*  get 1 path & return tail  in _cutpath() */
#define issp(c)		((c) == ' ' || (c) == '\t')	/*  space or tab  */

int     abs(n)
int     n;
{
    return (n < 0 ? -n : n);
}

int     min(x, y)
int     x, y;
{
    return (x < y ? x : y);
}

int     max(x, y)
int     x, y;
{
    return (x > y ? x : y);
}

int     atoi(s)
char    *s;
{
    int     val = 0;
    int     sign = 1;
    while (*s == ' ' || *s == '\t')
	s++;
    switch (*s) {
    case '-':
	sign = -1;
    case '+':
	s++;
    }
    while ('0' <= *s && *s <= '9')
	val = val * 10 + (*s++ - '0');  /* character operation */
    return (val * sign);
}

VOID    _swp(width, x, y)
size_t  width;
char    *x, *y;
{
    char    temp;
    for (; width > 0; width --) {
	temp = *x;
	*x = *y;
	*y = temp;
	x++;
	y++;
    }
}

VOID    qsort(base, n, width, compar)
char    *base;
unsigned n;
size_t  width;
int     (*compar)();
{
    char    *piv, *i, *j;
    char    *lv[20], *uv[20];
    int     p;

    lv[0] = base;   uv[0] = base + (n - 1)*width;
    p = 0;
    while (p >= 0) {
	if (lv[p] >= uv[p]) {
	    --p;
	    continue;
	}
	i = lv[p] - width;      piv = j = uv[p];
	while (i < j) {
	    for (i += width; (*compar)(i, piv) < 0; i += width)
		;
	    for (j -= width; j > i; j -= width)
		if ((*compar)(j, piv) <= 0)
		    break;
	    if (i < j)
		_swp(width, i, j);
	}
	_swp(width, i, uv[p]);
	if (i - lv[p] < uv[p] - i) {
	    lv[p+1] = lv[p];
	    uv[p+1] = i - width;
	    lv[p] = i + width;
	}
	else {
	    lv[p+1] = i + width;
	    uv[p+1] = uv[p];
	    uv[p] = i - width;
	}
	++p;
    }
}

char	*getenv(var)		/*  get environment  */
char	*var;			/*  var : varname to get  */
{				/*  this routine always allocates  */
	char	env[256];	/*  temporaly area  */
	char	*p;

	if(calla(BDOS, 0, (int)var, 0xff00 + (int)_GENV, (int)env))
		return(NULL);		/*  invalid envionment name  */
	if((p = alloc(strlen(env)+1)) == NULL)	/*  always alloc  */
		return(NULL);		/*  no memory  */
	return(strcpy(p, env));		/*  copy to static area  */
}

STATUS	putenv(env)		/*  set environment  */
char	*env;			/*  <varname>=<value>  */
{				/*  first '=' is used as delimiter*/
	char	st, *p;

	if((p = strchr(env, '=')) == NULL)
		return(ERROR);	/*  Invalid style(no delimiter)  */
	*p = '\0';		/*  end mark of varname  */
	st = calla(BDOS, 0, (int)env, (int)_SENV, (int)(p + 1));
	*p = '=';		/*  restore delimiter  */
	if(st)
		return(ERROR);
	else
		return(OK);
}

/*  cut out path  */
char	*_cutpath(mode, p)
TINY	mode;
char	*p;
{
	static	char	*path = NULL;
	char	c, lastch;

	if (mode == PATH_FIRST) {		/*  p: path string  */
		path = p;
	} else if (mode == PATH_NEXT) {		/*  p: area to store  */
		if (path == NULL)
			return (NULL);
		lastch = '\0';
	/*  skip head delimiter  */
		while ((c = *path) == ';' || issp(c))
			path++;
	/*  cut out 1 path  */
		while ((c = *path) != ';' && !issp(c) && c != '\0') {
			*p++ = lastch = c;
			path++;
		}
		if (lastch == '\0')
			return (path = NULL);	/*  not exist path  */
		*p = '\0';	/*  make terminater  */
	}
	return (p);		/*  return tail pointer  */
}


VOID	perror(msg)	/*  print previous error from dos  */
char	*msg;
{
	XREG	r;
	char	errmsg[64];

	r.bc = (unsigned)_ERROR;
	callxx(BDOS, &r);
	r.bc = r.bc & 0xff00 | (unsigned)_EXPLAIN;
	r.de = (unsigned)errmsg;	/*  error msg by dos  */
	callxx(BDOS, &r);
	if(msg != NULL || *msg != '\0') {
		fputs(msg, stderr);
		fputs(": ", stderr);
	}
	fputs(r.de, stderr);
	putc('\n', stderr);
}

      