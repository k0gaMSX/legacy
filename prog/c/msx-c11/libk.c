/*

	LIBK.C  MSX-C standard kernel functions (Ver 1.1)

		14-Jul-87       move _exec, execl, execv from lib2
				change _main
		30-Oct-87       debug _getfn, _setarg, _main
				ver 1.10s

	This file contains following functions.

	exit            _exec           execl           execv
	_main

	The functions whose name begin with underscore character
	are only used internally.
 */

#include    "stdio.h"
#include    "bdosfunc.h"
#pragma     nonrec

#define DEFFCB          0x5c            /* default FCB */
#define COMLEN          (*(char *)0x80) /* command length */
#define COMLIN          ((char *)0x81)  /* command line */
#define TPA             0x0100
#define sizeofLOADER    0x30            /* size of _chai() */

#define MAXARGS         64
#define MAXCOM          128

STATUS  _chkdrv(), _setupfcb();         /* functions in lib2.c */
char    *_parsefn(), *_filename();


jmp_buf _ckenv;                         /* kernel environment */
char    _execpgm[20];

VOID    exit(code)
int     code;
{
    longjmp(_ckenv, code & 0x00ff | 0x0100);    /* return to kernel */
}


char    *_skipsp(s)  /* skip leading blanks */
char    *s;
{
    char    c;

    while ((c = *s) == ' ' || c == '\t')
	s++;
    return (s);
}


char    *_getfn(fn, buf)
char    *fn, *buf;
{
    static  char deffcb[12] = {
		0,' ',' ',' ',' ',' ',' ',' ',' ','C','O','M'
	    };

    FCB     fcb;

    memcpy(&fcb, deffcb, 12);
    fn = _parsefn(fn, &fcb);
    _filename(&fcb, buf);
    return (fn);
}


VOID    _setarg(s)
char    *s;
{
    char *d;

    d = COMLIN + COMLEN;
    if (d < TPA && COMLEN != 0)
	*d++ = ' ';
    while (d < TPA && (*d = *s)) {
	d++;    s++;
    }
    COMLEN = d - COMLIN;
}


char    *_deffcb(fn, fcb)
char    *fn;
char    *fcb;
{
    memset(fcb, '\0', 16);
    memset(fcb+1, ' ', 11);
    return(_parsefn(_skipsp(fn), fcb));
}


char    _execgo(progname)
char    *progname;
{
    VOID    _chai();

    auto struct {
	FCB     fcb;
	char    Loader[sizeofLOADER];
    }   chain;  /* on stack */

    if (_setupfcb(progname, &chain.fcb) != OK   /* wild card is ERROR */
	||  bdos(OPEN, &chain.fcb) == BDOSERR) {
	fputs("Can't exec: ", stderr); fputs(progname, stderr);
    }
    else {
	/* set first and second defalut FCB */
	_deffcb(_deffcb(COMLIN, DEFFCB), DEFFCB+16);

	/* relocate _chai() */
	memcpy(chain.Loader, _chai, sizeofLOADER);

	/* let's go */
	(*(VOID (*)())chain.Loader)(&chain.fcb);
    }
}


VOID    _exec(progname, nargs, param)
int     nargs;
char    *progname, **param;
{
    _getfn(progname, _execpgm);

    COMLEN = 0;
    /* set up command line arguments */
    for (; nargs && *param != NULL; nargs--, param++) {
	_setarg(*param);
    }
    longjmp(_ckenv, 2 << 8);    /* return to kernel */
}


VOID    execl(nargs, progname, args)
int     nargs;
char    *progname, *args;
{
    if (nargs < 1) {
	fputs("execl: progname is missing", stderr);
	exit(1);
    }
    _exec(progname, nargs - 1, &args);
}


VOID    execv(progname, argv)
char    *progname, **argv;
{
    int     nargs;
    char    **p;

    for (p = argv, nargs = 0; *p++; nargs++)
	;
    _exec(progname, nargs, argv);
}


VOID    _unquote(s)
char    *s;
{
    char    *d;
    BOOL    quote;

    /* unquote quoted string in-place */
    d = s;
    if (*s == '"') {
	s++;
	quote = YES;
	while (*s) {
	    switch (*s) {
	    case '"':
		if (quote = !quote) /* paired quote */
		    *d++ = *s;
		s++;
		break;

	    case '\\':
		switch (*++s) {
		case '\0':
		    break;
		case 'N':
		case 'n':
		    *d++ = '\n';
		    s++;
		    break;
		case 'R':
		case 'r':
		    *d++ = '\r';
		    s++;
		    break;
		defalut:
		    *d++ = *s++;
		    break;
		}
		break;

	    default:
		*d++ = *s++;
		break;
	    }
	}
	*d = '\0';
    }
}


VOID    _main(s)
char    *s;         /* command argument */
{
    extern VOID     main();
    extern VOID     _closeall();
    extern VOID     _initrap(),_endtrap();

    static char     defio[] = "con";
    static char     wmode[] = "w";
    static char     pipeout[] = "*:|out";
    static char     pipein[] = "<*:|";      /* for next process */

    static char     *stdifn, *stdofn, *head;
				/* these must survive setjump() */
    int     argc;
    char    **argv;

    char    c, *d;
    BOOL    quoted;
    int     exitcode;          /* exit() */


    if ((exitcode = setjmp(_ckenv)) == 0) {
	_initrap();

	stdifn = stdofn = defio;

	argc = 0;
	argv = (char **)sbrk(sizeof(char *) * MAXARGS);

	d = sbrk(MAXCOM);           /* buffer for command line copy */
	*d++ = '\0';
	argv[argc++] = d;

	while ((c = *(s = _skipsp(s))) && c != '|' && c != ';') {

	    if (c == '<') {         /* redirect input */
		s++;
		*d++ = '<';
		stdifn = d;
	    }
	    else if (c == '>') {    /* redirect output */
		s++;
		if (*s == '>') {    /* append output */
		    s++;
		    *wmode = 'a';
		}
		*d++ = '>';
		*d++ = '>';
		stdofn = d;
	    }
	    else {
		argv[argc++] = d;
	    }
	    s = _skipsp(s);
	    quoted = NO;
	    head = d;

	    do {    /* get token */
		c = *d++ = *s++;
		if (c == '"') {
		    quoted = ~quoted;
		}
		else if (c == '\\') /* allow whatever next to '\' */
		    if (*s)
			*d++ = *s++;

	    } while ((c = *s) && (quoted || c != ' ' && c != '\t'));

	    *d++ = '\0';
	    _unquote(head);
	}
	argv[argc] = NULL;

	head = s = strcpy(d, s); /* save arguments for next process */

	if (*s == '|') { /* pipe line */
	    s++;
	    if (*s == '|') { /* I am exec'ed and pipe'd */
		s++;
		*wmode = 'a';
		head++;
	    }
	    if ((c = toupper(*s)) != '@' && _chkdrv(c - '@') != ERROR) {
		s++;
		pipein[1] = *(stdofn = pipeout) = c;
	    }
	    else {
		stdofn = pipeout + 2;
		pipein[1] = '|'; pipein[2] = '\0';
	    }
	    if (*s != ' ' && *s != '\t') {
		fputs("bad temporary drive ", stderr); putc(c, stderr);
		exit(1);
	    }
	}

	if (fopen(stdifn, "r") == NULL) {
	    fputs("can't open: ", stderr); fputs(stdifn, stderr);
	    exit(1);
	}

	if (fopen(stdofn, wmode) == NULL) {
	    fputs("can't make: ", stderr); fputs(stdofn, stderr);
	    exit(1);
	}
	main(argc, argv);
	exit(0);
    }

    /* exit() or exec() comes here */
    _endtrap();
    _closeall();

    c = *(s = head); /* reload rest of the argument */

    switch(exitcode >> 8) {
    case 1: /* comes here from exit() */
	d = stdifn;
	if (*d++) {
	    if (*d-- == ':')
		d += 2;
	    if (*d == '|')
		unlink(stdifn);
	}
	if ((exitcode & 0xff) != 0 || c == '\0')
	    return;

	/* execute next program */
	s++;
	COMLEN = 0;
	if (c == '|') { /* pipe */
	    unlink(pipein + 1);
	    rename(stdofn, pipein + 1);
	    _setarg(pipein);
	    s++;
	}
	/* get filename token and skip over it */
	s = _skipsp(_getfn(_skipsp(s), _execpgm));
	break;

    case 2: /* comes here from exec() */
	if (stdifn != defio)
	    _setarg(stdifn - 1);
	if (stdofn != defio)
	    if (c != '|')
		_setarg(stdofn - 2);
	    else
		*--s = '|';
	break;

    case 3: /* comes here when aborted */
	(***(VOID (***)())0xf325)(); /* jump to system abort routine */
	return;
    }
    _setarg(s);
    _execgo(_execpgm);
}
