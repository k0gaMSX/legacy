/*

	LIB2.C  Standard library functions  -- PART II (Ver 1.1)

		 8-Jul-85       MSX-DOS version
				debug   _exec
		11-Jul-85       change  CPMREAD -> BLKREAD
				change  CPMWRITE -> BLKWRITE
		16-Jul-85       set recsize = 1
		10-Aug-85       change  _fflush() to put one CPMEOF
				For Ver 1.1
		14-Jul-87       change  _getcon() -> use line input
				change  fgets  -> use only getc
				change  ungetc -> return OK or ERROR
				add     getch  -> 1 char input from CON
				move    _exec,execl,execv  to LIBK.C
		20-Oct-87       debug   getch, expargs, fopen
		30-Oct-87       debug   _chkserial
				ver 1.10s

	This file contains following functions.

	getch           getche          kbhit           sensebrk
	_getcon
	_getfcb         _freefcb        _alocfcb        _isfn
	_pars1          _parsefn        _chkdrv         _setupfcb
	_filename       _cmp            expargs         rename
	unlink          write           read            _seek
	close           open            creat
	_fillbuf        _flushbuf       _putc           putc
	_getc           ungetc          getc            fclose
	_closeall       fsetbin         fsettext        _strequ
	_chkserial      fopen           fputs           fgets
	putchar         ungetch         getchar         puts
	gets

	The functions whose name begin with underscore character
	are only used internally.
*/

#include        "stdio.h"
#include        "bdosfunc.h"
#pragma         nonrec

#define CPMEOF  '\032'      /* CP/M end of file character */
#define MAXLINE 255

/********************************************************/
/*                                                      */
/*              Console I/O functions                   */
/*                                                      */
/********************************************************/

char    getch()
{
    return (bdos(DIRIN));
}

char    getche()
{
    return (bdos(CONIN));
}

BOOL    kbhit()
{
    return (bdos(CONST));
}

VOID    sensebrk()
{
    bdos(CONST);
}



int     _getcon()
{
    static char buff[MAXLINE+4];
    static int  count = 0;
    static char *ptr;

    char    c;

    if  (count == 0) {
	buff[0] = MAXLINE;
	bdos(GETLIN, buff); bdos(CONOUT, '\n');
	count = buff[1];
	ptr = &buff[2] + count;
	*ptr++ = '\r'; *ptr = '\n'; count += 2;
	ptr = &buff[2];
	}
    c = *ptr++; count--;

    if (c == CPMEOF) { /* End of File */
	count = 0;
	return (EOF);
	}

    return(c);
}



/********************************************************/
/*                                                      */
/*              Raw I/O functions                       */
/*                                                      */
/********************************************************/

#define _NFCBS  20

#define _READ    01
#define _WRITE   02
#define _EOF     04
#define _OVF    010
#define _BINARY 020


FCB     *_xio[_NFCBS] = {};     /* to be initialized to zero */

FCB     *_getfcb(fd)
FD      fd;
{
    if (fd < 0 || _NFCBS <= fd)
	return (NULL);
    return (_xio[fd]);
}

VOID    _freefcb(fd)
FD      fd;
{
    FCB     *fcb;

    if ((fcb = _getfcb(fd)) != NULL) {
	free(fcb);
	_xio[fd] = NULL;
    }
}

FD      _alocfcb()
{
    unsigned i;

    for (i = 0; i < _NFCBS; i++) {
	if (_xio[i] == NULL)
	    if ((_xio[i] = (FCB *)alloc(sizeof(FCB))) != NULL)
		return (i);
	    else
		break;
    }
    return (ERROR);
}



BOOL    _isfn(c)
char    c;
{
    switch (c) {
    case '=':   /* argument separator */
    case ';':
    case ',':
    case '+':   /* filespec separator */
    case '/':   /* switch prefix */
    case '"':   /* other stuff */
    case '[':
    case ']':
    case ':':   /* file field separator */
    case '.':
    case 0x7f:  /* other control characters */
    case 0xff:
	return (NO);
    default:
	if (c <= ' ')
	    return (NO);
    }
    return (YES);
}


char    *_pars1(s, d, n)
char    *s, *d;
TINY    n;
{
    for (; _isfn(*s); d++, s++) {
	if (n) {
	    n--;
	    if ((*d = toupper(*s)) == '*') {
		n++;
		while (n) {
		    n--;
		    *d++ = '?';
		}
	    }
	}
    }
    return (s);
}


char    *_parsefn(fn, fcb)
char    *fn;
FCB     *fcb;
{
    char    dc;

    dc = toupper(*fn) - 'A' + 1;
    if (dc && dc <= MAXDRIVE && *(fn+1) == ':') {   /* drive */
	fcb->dc = dc;
	fn += 2;
    }
    if (_isfn(*fn)) {                               /* name */
	memset(fcb->name, ' ', sizeof(fcb->name));
	fn = _pars1(fn, fcb->name, 8);
    }
    if (*fn == '.') {                               /* type */
	memset(fcb->type, ' ', sizeof(fcb->type));
	fn = _pars1(++fn, fcb->type, 3);
    }
    return (fn);
}


STATUS  _chkdrv(dc)
TINY    dc;
{
    if (dc == 0)
	return (OK);
    if (MAXDRIVE <= --dc)
	return (ERROR);
    return (((unsigned)bdosh(LOGVEC) >> dc & 1)? OK: ERROR);
}


STATUS  _setupfcb(name, fcb)
char    *name;
FCB     *fcb;
{
    char    *p;
    TINY    i;

    memset(fcb, '\0', sizeof(FCB));
    memset(fcb->name, ' ', 8 + 3);

    name = _parsefn(name, fcb);

    if (_chkdrv(fcb->dc) == ERROR)
	return (ERROR);

    for (p = fcb->name, i = 8 + 3; i != 0; i--)
	if (*p++ == '?')
	    break;

    return ((*name)? ERROR: (i)? WILDCARD: OK);
}


char    *_filename(dir, fn)
struct {
	char    dc, name[8], type[3], filler[21];
}       *dir;
char    *fn;
{
    TINY    i;
    char    c, *p;

    if (dir->dc) {
	*fn++ = dir->dc - 1 + 'A';
	*fn++ = ':';
    }
    for (i = 8, p = dir->name; i && (c = *p) != ' '; i--, p++)
	*fn++ = c;
    for (i = 3, p = dir->type; i && (c = *p) != ' '; i--, p++) {
	if (i == 3)
	    *fn++ = '.';
	*fn++ = c;
    }
    *fn = '\0';
    return (fn);
}



int     _cmp(p, q)
char    **p, **q;
{
    return (strcmp(*p, *q));
}


int     expargs(argc, argv, maxargc, xargv)
int     argc, maxargc;
char    *argv[], *xargv[];
{
    auto struct {
	    char    dc, name[8], type[3], filler[21];
    }       dir;

    FCB     sf;
    int     xargc, topc, i;
    char    rc, c, *p, **topv, fn[20];

    xargc = 0;
    while (--argc >= 0) {
	p = *argv++;
	if (_setupfcb(p, &sf) == WILDCARD) {
	    topv = xargv;   topc = xargc;
	    bdos(SETDMA, &dir);
	    for (rc=bdos(SEARF, &sf); rc!=BDOSERR; rc=bdos(SEARN)) {
		if (xargc >= maxargc)
		    return (ERROR);
		dir.dc = sf.dc;

		p = _filename(&dir, fn);

		if ((p = sbrk(p - fn + 1)) == ERROR) {
		    return (ERROR);
		}
		strcpy(p, fn);
		*xargv++ = p;
		xargc++;
	    }
	    qsort(topv, xargc - topc, sizeof(char *), _cmp);
	}
	else {
	    if (xargc >= maxargc)
		return (ERROR);
	    *xargv++ = p;
	    xargc++;
	}
    }
    return (xargc);
}




STATUS  unlink(filename)
char    *filename;
{
    FCB     fcb;

    if (_setupfcb(filename, &fcb) == ERROR) /* wildcard is OK */
	return (ERROR);
    return ((bdos(DELETE, &fcb) == BDOSERR)? ERROR: OK);
}


STATUS  rename(oldname, newname)
char    *oldname, *newname;
{
    FCB     ofcb, nfcb;

    if (_setupfcb(oldname, &ofcb) != OK   /* wildcard is ERROR */
    ||  _setupfcb(newname, &nfcb) != OK)  /* wildcard is ERROR */
	return (ERROR);
    memcpy((char *)&ofcb + 16, &nfcb, 1 + 8 + 3);
    return ((bdos(RENAME, &ofcb) == BDOSERR)? ERROR: OK);
}


int     write(fd, buf, bytes)
FD      fd;
char    *buf;
size_t  bytes;
{
    FCB     *fcb;

    if ((fcb = _getfcb(fd)) == NULL || !(fcb->mode & _WRITE))
	return (ERROR);
    bdos(SETDMA, buf);
    return (bdosh(BLKWRITE, fcb, bytes));
}


int     read(fd, buf, bytes)
FD      fd;
char    *buf;
size_t  bytes;
{
    FCB     *fcb;

    if ((fcb = _getfcb(fd)) == NULL || !(fcb->mode & _READ))
	return (ERROR);
    bdos(SETDMA, buf);
    return (bdosh(BLKREAD, fcb, bytes));
}


STATUS  _seek(fd, offset, mode)
FD      fd;
int     offset;
TINY    mode;
{
    FCB     *fcb;

    if (2 < mode || (fcb = _getfcb(fd)) == NULL)
	return (ERROR);
    if (mode == 0) {
	fcb->recpos[0] = fcb->recpos[1] = 0;
    }
    else if (mode == 2) {
	fcb->recpos[0] = fcb->filesize[0];
	fcb->recpos[1] = fcb->filesize[1];
    }
    /* simulate (long) += (int) */
    if (offset < 0)
	--fcb->recpos[1];
    if ((fcb->recpos[0] += offset) < (unsigned)offset)
	++fcb->recpos[1];
    return (OK);
}


STATUS  close(fd)
FD      fd;
{
    FCB     *fcb;
    STATUS  cond;

    if ((fcb = _getfcb(fd)) == NULL)
	return (ERROR);
    cond = bdos(CLOSE, fcb);
    _freefcb(fd);
    return ((cond == BDOSERR)? ERROR: OK);
}


FD      open(filename, mode)
char    *filename;
int     mode;
{
    FD      fd;
    FCB     *fcb;

    if (mode < 0 || 2 < mode || (fd = _alocfcb()) == ERROR)
	return (ERROR);
    if (_setupfcb(filename, fcb=_getfcb(fd)) != OK /* wildcard is ERROR */
    ||  bdos(OPEN, fcb) == BDOSERR) {
	_freefcb(fd);
	return (ERROR);
    }
    fcb->mode = mode + 1;   /*      0 -> _READ,             *
			     *      1 -> _WRITE,            *
			     *      2 -> _READ | _WRITE     */
    fcb->recsize = 1;
    return (fd);
}


FD      creat(filename)
char    *filename;
{
    FD      fd;
    FCB     *fcb;

    if ((fd = _alocfcb()) == ERROR)
	return (ERROR);
    if (_setupfcb(filename, fcb=_getfcb(fd)) != OK /* wildcard is ERROR */
    ||  bdos(CREATE, fcb) == BDOSERR) {
	_freefcb(fd);
	return (ERROR);
    }
    fcb->mode = _WRITE;
    fcb->recsize = 1;
    return (fd);
}



/********************************************************/
/*                                                      */
/*              Bufferred I/O functions                 */
/*                                                      */
/********************************************************/

#define CON     1
#define LST     2
#define AUX     3
#define NUL     4


FILE    _iob[_NFILES] = {
	{},             /* stdin */
	{},             /* stdout */
	{CON, _WRITE},  /* stderr */
};


STATUS  _flushbuf(fp)
FILE    *fp;
{
    size_t  sz;

    if ((fp->mode & _OVF) || !(fp->mode & _WRITE))
	return (ERROR);
    sz = fp->bufsiz - fp->count;
    if (sz != write(fp->fd, fp->base, sz)) {
	fp->mode |= _OVF;
	return (ERROR);
    }
    fp->ptr = fp->base;
    fp->count = fp->bufsiz;
    return (OK);
}


STATUS  _fillbuf(fp)
FILE    *fp;
{
    if ((fp->mode & _EOF) || !(fp->mode & _READ)) {
	return (ERROR);
    }
    if ((fp->count = read(fp->fd, fp->base, fp->bufsiz)) == 0) {
	fp->mode |= _EOF;
	return (ERROR);
    }
    fp->ptr = fp->base;
    return (OK);
}


STATUS  _putc(c, fp)
char    c;
FILE    *fp;
{
    switch (fp->serial) {
    case 0:
	if (fp->count == 0  && _flushbuf(fp) == ERROR)
	    return (ERROR);
	fp->count--;
	*fp->ptr++ = c;
	break;
    case CON:
	bdos(CONOUT, c);
	break;
    case LST:
	bdos(LSTOUT, c);
	break;
    case AUX:
	bdos(AUXOUT, c);
    case NUL:
	break;
    default:
	return (ERROR);
    }
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
    return (OK);
}


int     _getc(fp)
FILE    *fp;
{
    int     c;

    switch (fp->serial) {
    case 0:
	if (fp->count == 0 && _fillbuf(fp) == ERROR)
	    return (EOF);
	fp->count--;
	return (*fp->ptr++);
    case CON:
    case AUX:
	if (c = fp->count) {
	    fp->count = 0;
	    return (c & 0x00ff);
	}
	return (fp->serial == CON)? _getcon(): bdos(AUXIN);
    default:
	return (EOF);
    }
}


STATUS  ungetc(c, fp)
char    c;
FILE    *fp;
{
    if (!(fp->mode & _READ))
	return (ERROR);
    switch (fp->serial) {
    case 0:
	if (fp->base < fp->ptr) {
	    *--fp->ptr = c;
	    fp->count++;
	}
	return (OK);
    case CON:
    case AUX:
	fp->count = (c | 0xff00);
	return (OK);
    default:
	return (ERROR);
    }
}


int     getc(fp)
FILE    *fp;
{
    int     c;

    if (fp->mode & _BINARY)
	return (_getc(fp));

    while ((c = _getc(fp)) == '\0')
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


STATUS  fclose(fp)
FILE    *fp;
{
    STATUS  cond;

    if (fp == NULL)
	return (ERROR);
    cond = OK;
    if (!fp->serial) {
	if (fp->mode & _WRITE) {
	    if (!(fp->mode & _BINARY))
		_putc(CPMEOF, fp);
	    cond = _flushbuf(fp);
	}
	if (cond == ERROR)
	    close(fp->fd);
	else
	    cond = close(fp->fd);
	free(fp->base);
    }
    fp->mode = 0;
    return (cond);
}


VOID    _closeall()
{
    unsigned i;
    FILE    *p;

    for (p = _iob; p < _iob + _NFILES; p++)
	if (p->mode)
	    fclose(p);
    for (i = 0; i < _NFCBS; i++)
	if (_getfcb(i))
	    close(i);
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


BOOL    _strequ(s, t)
char    *s, *t;
{
    while (*s)
	if (*s++ != toupper(*t++))
	    return (NO);
    if (*t != ' ')
	return (NO);
    return (YES);
}


TINY    _chkserial(s)
char    *s;
{
    FCB     fcb;

    if (_setupfcb(s, &fcb) != OK)
	return (ERROR);
    return ((_strequ("CON", fcb.name))? CON:
	    (_strequ("LST", fcb.name) || _strequ("PRN", fcb.name))? LST:
	    (_strequ("AUX", fcb.name))? AUX:
	    (_strequ("NUL", fcb.name))? NUL:
					0);
}


FILE    *fopen(nargs, xfn, xmode, xbsiz)
int     nargs;
char    *xfn, *xmode;
size_t  xbsiz;
{
    char    *filename, mode;
    TINY    bmod;
    size_t  bsiz;
    FILE    *p;

    if (nargs < 1 || 3 < nargs )
	return (NULL);
    filename = xfn;
    mode = (nargs == 1)? 'R': toupper(*xmode);
    bmod = (nargs != 1 && toupper(xmode[1]) == 'B')? _BINARY: 0;
    bsiz = (nargs == 3)? xbsiz: BUFSIZ;
    for (p = _iob; p < _iob + _NFILES; ++p)
	if (p->mode == 0)
	    break;
    if (p >= _iob + _NFILES)
	return (NULL);
    if (p->serial = _chkserial(filename)) { /* serial devices */
	if (p->serial == ERROR || p->serial == LST && mode == 'R')
	    return (NULL);
	p->mode = ((mode == 'R')? _READ: _WRITE) | bmod;
	p->count = '\0';        /* no char is ungotten */
	return (p);
    }

    if ((p->base = alloc(bsiz)) == NULL)    /* alloc.  buffer */
	return (NULL);
    p->bufsiz = bsiz;
    switch (mode) {
    case 'R':
	if ((p->fd = open(filename, 0)) == ERROR) {
	    free(p->base);
	    return (NULL);
	}
	p->mode = _READ | bmod;
	p->count = 0;
	break;
    case 'A':
    case 'W':
	if (mode == 'A' && (p->fd = open(filename, 2)) != ERROR) {
	    if (bmod)
		_seek(p->fd, 0, 2);
	    else {
		p->mode = _READ;
		p->count = 0;
		while (getc(p) != EOF)  /* inefficient!! */
		    ;
		_seek(p->fd, -p->count, 1);
	    }
	}
	else if ((p->fd = creat(filename)) == ERROR) {
	    free(p->base);
	    return (NULL);
	}
	p->mode = _WRITE | bmod;
	p->count = bsiz;
	p->ptr = p->base;
	break;
    default:
	free(p->base);
	return (NULL);
    }
    return (p);
}



STATUS  fputs(s, fp)
char    *s;
FILE    *fp;
{
    char    c;

    while (c = *s++) {
	if (putc(c, fp) == ERROR)
	    return (ERROR);
    }
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
    while (--n != 0 && (c = getc(fp)) != EOF) {
	if ((*cptr++ = c) == '\n')
	    break;
    }
    *cptr = '\0';
    return (c == EOF && cptr == s)? NULL: s;
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
