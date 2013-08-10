/*

	LIB1.C  Standard library functions  -- PART I (Ver 1.1)

		30-Oct-87       ver 1.10s

	This file contains following functions.

	atoi
	strcat          strcmp          strcpy          strlen
	toupper         tolower
	_swp            qsort
	abs             min             max
	sbrk            rsvstk          free            alloc

	The functions whose name begin with underscore character
	are only used internally.
*/

#include "stdio.h"
#pragma nonrec

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


char    toupper(c)
char    c;
{
    return (islower(c) ? c - 'a' + 'A' : c);
}


char    tolower(c)
char    c;
{
    return (isupper(c) ? c - 'A' + 'a' : c);
}


int     strcmp(s, t)
char    *s, *t;
{
    for (; *s == *t; s++, t++)
	if (*s == '\0')
	    return (0);
    return ((int) *s - (int) *t);
}


char    *strcat(d, s)
char    *d, *s;
{
    char    *head = d;
    while (*d)
	d++;
    while (*d++ = *s++)
	;
    return (head);
}


char    *strcpy(d, s)
char    *d, *s;
{
    char    *head = d;
    while (*d++ = *s++)
	;
    return (head);
}


size_t  strlen(s)
char    *s;
{
    char    *head = s;
    while (*s)
	s++;
    return (s - head);
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



/*
	Math
*/

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


/*
	Storage management functions
*/

size_t  _torelance = 1000;      /* default size of stack space */

char    *sbrk(n)
size_t  n;
{
    extern  char    _endx[];    /* end of data segment's address */

    static  char    *memtop = _endx;
    char    stack[0];
    char    *temp;

    if (stack - memtop - _torelance < n)
	return (ERROR);
    temp = memtop;
    memtop += n;
    return (temp);
}

VOID    rsvstk(n)
size_t  n;
{
    _torelance = n;
}




typedef char    ALIGN;

typedef union header {
	    struct  {
		union header    *ptr;
		unsigned        size;
	    }   s;

	    ALIGN   x;
	}   HEADER;

HEADER  _base;
HEADER  *_allocp = NULL;

VOID    free(ap)
char    *ap;
{
    HEADER  *p, *q;

    p = (HEADER *)ap - 1;
    for (q = _allocp; !(q < p && p < q->s.ptr); q = q->s.ptr)
	if (q >= q->s.ptr && (q < p || p < q->s.ptr))
	    break;
    if (p + p->s.size == q->s.ptr) {
	p->s.size += q->s.ptr->s.size;
	p->s.ptr = q->s.ptr->s.ptr;
    }
    else
	p->s.ptr = q->s.ptr;
    if (q + q->s.size == p) {
	q->s.size += p->s.size;
	q->s.ptr = p->s.ptr;
    }
    else
	q->s.ptr = p;
    _allocp = q;
}

char    *alloc(nbytes)
size_t  nbytes;
{
    HEADER  *p, *q, *cp;
    int     nunits;

    nunits = 1 + (nbytes + sizeof(HEADER) - 1) / sizeof(HEADER);
    if ((q = _allocp) == NULL) {
	_base.s.ptr = _allocp = q = &_base;
	_base.s.size = 0;
    }
    for (p = q->s.ptr; ; q = p, p = p->s.ptr) {
	if (p->s.size >= nunits) {
	    if (p->s.size == nunits)
		q->s.ptr = p->s.ptr;
	    else {
		p->s.size -= nunits;
		p += p->s.size;
		p->s.size = nunits;
	    }
	    _allocp = q;
	    return ((char *)(p + 1));
	}
	if (p == _allocp) {
	    if ((cp = (HEADER *)sbrk(nunits * sizeof(HEADER))) == ERROR)
		return (NULL);
	    cp->s.size = nunits;
	    free(cp + 1);
	    p = _allocp;
	}
    }
}
