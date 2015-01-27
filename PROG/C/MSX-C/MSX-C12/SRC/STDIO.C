
/*
	(C) Copyright by ASCII Corporation, 1989
		All rights Reserved.

	File: stdio.c		Bufferred Input/Output Functions

	Includes following functions
		fflush	flushall	setvbuf	setbuf	putc
		ungetc	getc		putchar	ungetch	getchar
		fclose	fcloseall	fopen	fputs	fgets
		fsetbin	fsettext 	puts	gets	fread
		fwrite	clearerr	printf	fprintf	sprintf
		scanf	fscanf		sscanf	
*/
#pragma	nonrec
#include <stdio.h>

char    _buffs[_NFILES] = {};		/*  buffer for no buffering  */

FILE    _iob[_NFILES] = {
		{YES, _IOREAD,_buffs+0, 0, _buffs+0, 0, 1},	/* stdin  */
		{YES, _IOWRT, _buffs+1, 1, _buffs+1, 1, 1},	/* stdout */
		{YES, _IOWRT, _buffs+2, 1, _buffs+2, 2, 1},	/* stderr */
		{YES, _IOWRT, _buffs+3, 1, _buffs+3, 3, 1},	/* stdaux */
		{YES, _IOWRT, _buffs+4, 1, _buffs+4, 4, 1}	/* stdprn */
};	    /* serial mode     	ptr count   base   fd bufsiz */


STATUS  fflush(fp)
FILE    *fp;
{
	extern  STATUS  _seek();

	size_t  sz;

	if (fp->base == NULL)
		return (ERROR);
	if ((fp->mode & _IOWRT) && !ferror(fp)) {
		sz = fp->bufsiz - fp->count;
		if (sz != write(fileno(fp), fp->base, sz)) {
			fp->mode |= _IOOVF;
			return (ERROR);
		}
		fp->ptr = fp->base;
		fp->count = fp->bufsiz;
	} else if (fp->mode & _IOREAD)
		_seek(fileno(fp), -fp->count, (char)1);
	else
		return (ERROR);
	return (OK);
}


TINY    flushall()
{
	FILE    *fp;
	TINY	n;		/*  stream counter in use  */

	n = 0;
	for (fp = stdin; fp < stdin + _NFILES; fp++)
		if (fp->mode) {
			n++;
			fflush(fp);
		}
	return (n);
}


VOID    _flshserial()
{
	FILE    *fp;

	for (fp = stdin; fp < stdin + _NFILES; fp++)
		if (fp->serial & (_IOSERI | _IOLBF))
			fflush(fp);
}


STATUS	setvbuf(fp, buf, mode, size)
FILE	*fp;
char	*buf;
int	mode, size;
{
	BOOL	nobuf;

	fflush(fp);
	if (fp->mode & _IOMYBUF)
		free(fp->base);
	fp->mode &= ~(_IOMYBUF | _IOEOF | _IOOVF);
	nobuf = FALSE;
	switch (mode) {
	case	_IONBF:
		nobuf = TRUE;
	case	_IOLBF:
	case	_IOFBF:
		fp->serial = (fp->serial & ~(_IONBF | _IOLBF)) | mode;
		fp->bufsiz  = ((nobuf) ? 1 : size);
		fp->count = (fp->mode & _IOREAD) ? 0 : fp->bufsiz;
		fp->ptr = fp->base = (nobuf) ? _buffs + (fp - stdin) : buf;
		return (OK);
	default:
		return (ERROR);
	}
}

VOID	setbuf(fp, buf)
FILE	*fp;
char	*buf;		/*  points allocated buffer(size BUFSIZ)  */
{
	setvbuf(fp, buf, (buf != NULL)? _IOFBF : _IONBF, BUFSIZ);
}


STATUS  _putc(c, fp)
char    c;
FILE    *fp;
{
	if (fp->base == NULL) {
		if ((fp->ptr = fp->base = alloc(fp->bufsiz)) == NULL)
			return(ERROR);
		else
			fp->mode |= _IOMYBUF;
	}
	*fp->ptr++ = c;
	if (--fp->count <= 0  && fflush(fp) == ERROR)
		return (ERROR);
	return (OK);
}


STATUS  putc(c, fp)
char    c;
FILE    *fp;
{
	if (c == '\n' && !(fp->mode & _BINARY))
		if (_putc('\r', fp) == ERROR)
			return (ERROR);
	if (_putc(c, fp) == ERROR)
		return (ERROR);
	if (c == '\n' && (fp->serial & _IOLBF))
		return(fflush(fp));
	if (fp->serial & _IONBF)
		return (fflush(fp));
	return(OK);
}


STATUS  _fillbuf(fp)
FILE    *fp;
{
	if (feof(fp) || !(fp->mode & _IOREAD))
		return (ERROR);
	if (fp->base == NULL) {
		if ((fp->base = alloc(fp->bufsiz)) == NULL)
			return(ERROR);
		else
			fp->mode |= _IOMYBUF;
	}
	if ((fp->count = read(fileno(fp), fp->base, fp->bufsiz)) == 0) {
		fp->mode |= _IOEOF;
		return (ERROR);
	}
	fp->ptr = fp->base;
	return (OK);
}


int     _getc(fp)
FILE    *fp;
{
	int     c;

	if (fp->count == 0 && _fillbuf(fp) == ERROR)
		return (EOF);
	fp->count--;
	return (*fp->ptr++);
}


STATUS  ungetc(c, fp)
char    c;
FILE    *fp;
{
	if (!(fp->mode & _IOREAD) || (fp->base >= fp->ptr))
		return (ERROR);
	*--fp->ptr = c;
	fp->count++;
	return (OK);
}


int     getc(fp)
FILE    *fp;
{
	int     c;

	if (fp->serial & (_IOSERI | _IOLBF))
		_flshserial();
	if (fp->mode & _BINARY)
		return (_getc(fp));
	while ((char)(c = _getc(fp)) == '\0')
		;
	switch (c) {
	case CPMEOF:
		ungetc((char)c, fp);
		return(EOF);
	case '\r':
		if ((c = _getc(fp)) != '\n') {
			ungetc((char)c, fp);
			return('\r');
		}
	}
	return (c);
}


STATUS  putchar(c)
char    c;
{
	return (putc(c, stdout));
}


VOID    ungetch(c)
char    c;
{
	return (ungetc(c, stdin));
}


int     getchar()
{
	return (getc(stdin));
}


STATUS  fclose(fp)
FILE    *fp;
{
	STATUS  cond;

	if (fp == NULL)
		return (ERROR);
	cond = OK;
	if (fp->mode & _IOWRT) {
		if (!(fp->mode & _BINARY))
			putc(CPMEOF, fp);
		cond = fflush(fp);
	}
	if (cond == ERROR)
		close(fileno(fp));
	else
		cond = close(fileno(fp));
	if (fp->mode & _IOMYBUF)
		free(fp->base);		/*  allocated by _fillbuf or _putc  */
	fp->mode = 0;
	return (cond);
}


TINY	fcloseall()
{
	FILE	*fp;
	STATUS	cond = OK;
	TINY	count = 0;

	for(fp = stdprn + 1; fp < stdin + _NFILES; fp++)
		if(fp->mode) {		/*  only opened stream  */
			if(fclose(fp) == ERROR)
				cond = ERROR;
			else
				count++;
		}
	return(cond == ERROR ? ERROR : count);
}


STATUS  fsettext(fp)
FILE    *fp;
{
	fp->mode &= ~_BINARY;
	return (OK);
}


STATUS  fsetbin(fp)
FILE    *fp;
{
	fp->mode |= _BINARY;
	return (OK);
}


FILE    *fopen(nargs, xfn, xmode, xbsiz)
unsigned nargs;
char    *xfn, *xmode;
size_t  xbsiz;
{
	char    *filename, mode;
	TINY    bmod;
	size_t  bsiz;
	FILE    *p;

	extern  STATUS  _seek();

	if (nargs < 1 || 3 < nargs )
		return (NULL);
	filename = xfn;
	mode = (nargs == 1)? 'R': toupper(*xmode);
	bmod = (nargs != 1 && toupper(xmode[1]) == 'B')? _BINARY: 0;
	bsiz = (nargs == 3)? xbsiz: BUFSIZ;
	/* search for an empty iob */
	for (p = stdin; p < stdin + _NFILES; ++p)
		if (p->mode == 0)
			goto found_iob;
	return (NULL);

found_iob:
	p->base = NULL;		/*  alloc buf when actually reading/writing  */
	p->bufsiz = bsiz;
	switch (mode) {
	case 'R':
		if ((fileno(p) = open(filename, O_RDONLY)) == ERROR)
			return (NULL);
		p->mode = _IOREAD | bmod;
		p->count = 0;
		break;
	case 'A':
	case 'W':
		if(mode == 'A' && (fileno(p)=open(filename,O_RDWR)) != ERROR) {
			if (bmod)
				_seek(fileno(p), 0, (char)2);
			else {
				p->mode = _IOREAD;	/* text mode */
				p->count = 0;
				while (getc(p) != EOF)  /* inefficient!! */
					;
				/* set pointer to EOF */
				_seek(fileno(p), -p->count, (char)1);
			}
		}
		else if ((fileno(p) = creat(filename)) == ERROR)
			return (NULL);
		p->mode = _IOWRT | bmod;
		p->count = bsiz;
		p->ptr = p->base;
		break;
	default:
		return (NULL);
	}
	p->serial = (TINY)isatty(fileno(p));
	return (p);
}


STATUS  fputs(s, fp)
char    *s;
FILE    *fp;
{
	char    c;

	while (c = *s++)
		if (putc(c, fp) == ERROR)
			return (ERROR);
	return (OK);
}


char    *fgets(s, n, fp)
char    *s;
int     n;
FILE    *fp;
{
	int     c;
	char    *cptr;

	cptr = s;
	while (--n != 0 && (c = getc(fp)) != EOF)
		if ((*cptr++ = c) == '\n')
			break;
	*cptr = '\0';
	return (c == EOF && cptr == s)? NULL: s;
}


STATUS  puts(s)
char    *s;
{
	return (fputs(s, stdout));
}


char    *gets(s, n)
char    *s;
int     n;
{
	return (fgets(s, n, stdin));
}

int	fread(buf, size, count, fp)
char	*buf;
int	size, count;
FILE	*fp;
{
	int	s, c, ct;

	ct = count;
	while(ct > 0) {
		s = size;
		while(s--) {
			if((c = getc(fp)) == EOF)
				return(count - ct);
			*buf++ = (char)c;
		}
		ct--;		/*  complete 1 item  */
	}
	return(count);
}

int	fwrite(buf, size, count, fp)
char	*buf;
int	size, count;
FILE	*fp;
{
	int	s, ct;

	ct = count;
	while(ct > 0) {
		s = size;
		while(s--) {
			if(putc(*buf, fp) == ERROR)
				return(count - ct);
			buf++;
		}
		ct--;		/*  complete 1 item  */
	}
	return(count);
}

VOID	clearerr(fp)
FILE	*fp;
{
	(fp)->mode &= ~(_IOOVF | _IOEOF);
}

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


STATUS	_spr(param, outfunc, ___)
int	*param;
STATUS	(*outfunc)();
char	*___;           /* pointer for any type */
{
	char	c, *format;
	char	buf[15], *ptr, padch;
	TINY	radix;
	BOOL	dflag, leftjust;
	int     field, digits;

	format = (char *)*param++;

	while (c = *format++) {
	if (c == '%') {
		ptr = buf;
		digits = 6;
		leftjust = dflag = NO;
		if (*format == '-') { 
			format++;
			leftjust = YES;
		}
		if((padch = *format) != '0')
			padch = ' ';
		field = _gv2(&format);
		if (*format == '.') {
			format++;
			digits = _gv2(&format);
			dflag = YES;
		}
		switch (toupper(c = *format++)) {
		case 'D':
			if (*param < 0) {
				*param = -*param;
				*ptr++ = '-';
				field--;
			}
		case 'U':
			radix = 10;
			goto nums;
		case 'X':
			radix = 16;
			goto nums;
		case 'O':
			radix = 8;
	nums:
			field -= _uspr(&ptr, *param++, radix);
			goto pad;


		case 'S':
			ptr = (char *)*param++;
		field -= (dflag && strlen(ptr) > digits ? digits: strlen(ptr));
			goto spad;

		case 'C':
			*ptr++ = *param++;
			field--;
	pad:
			*ptr = '\0';
			ptr = buf;
			dflag = NO;
	spad:
			if (!leftjust) {
				if(c != 'S' && c != 'C' && padch == '0' && *ptr == '-') {
					if ((*outfunc)('-', ___) == ERROR)
						return (ERROR);
					ptr++;
				}
				while (field-- > 0)
					if ((*outfunc)(padch, ___) == ERROR)
						return (ERROR);
			}
			while (c = *ptr++) {
				if (!dflag || digits-- > 0) {
					if ((*outfunc)(c, ___) == ERROR)
						return (ERROR);
				}
			}
			if (leftjust)
				while (field-- > 0)
					if ((*outfunc)(' ', ___) == ERROR)
						return (ERROR);
			break;

		case '\0':
			return (OK);
		default:
			goto cout;
		}
	}
	else
	cout:
		if ((*outfunc)(c, ___) == ERROR)
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

int	_scn(param, infunc, ___, ugfunc)
int	**param;
int	(*infunc)();
char	*___;		/* pointer to FILE or (char *) */
int	(*ugfunc)();
{
	char	*format, fmtchar;
	BOOL	assign, matched;
	TINY	radix;
	int	c, n, s;
	int	value;

	format = (char *)*param++;
	n = 0;
	matched = YES;
	while (matched && (fmtchar = *format++)) {
	if (fmtchar == '%') {
		if (!(assign = !(*format == '*')))
			format++;
		switch (fmtchar = toupper(*format++)) {
		case 'D':
		case 'U':
			radix = 10;
			goto val;
		case 'X':
			radix = 16;
			goto val;
		case 'O':
			radix = 8;
	val:
			c = _igs(infunc, ___);
			s = 1;	/*  sign  */
			if (fmtchar == 'D' && c == '-') {
				s = -1;	/*  sign  */
				c = (*infunc)(___);
			}
			value = 0;
			if (_bc((char)c, radix) != ERROR) {
				while ((fmtchar=_bc((char)c,radix)) != ERROR) {
					value = value * radix + fmtchar;
					c = (*infunc)(___);
					}
			if (assign) {
				**param++ = value * (int)s;
				n++;
				}
			}
		else
			matched = NO;
		break;

		case 'S':
			if ((c = _igs(infunc, ___)) != EOF) {
				s = (int)*param;
				while (c != EOF && !isspace((char)c)) {
					if (assign)
						*(char *)s++ = c;
					c = (*infunc)(___);
				}
				if (assign) {
					*(char *)s = '\0';
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
		(*ugfunc)((char)c, ___);	/* prepare for next scan */
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

                                                                             