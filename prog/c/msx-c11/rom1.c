/*
	ROM programming example	-	simple debugger
*/


#pragma	nonrec


typedef	char	VOID, BOOL, TINY, BYTE, REG;
typedef	unsigned nat;


extern	VOID	putcon();
extern	char	getcon();
extern	BOOL	consts();
extern	VOID	throw(), catch();




char	line[80], *lp;
BYTE	*datap;


#define	putch(c)	putcon(c)
#define	getch()		getcon()


VOID	putcrlf()
{
	putch('\r');
	putch('\n');
}

VOID	putback()
{
	putch('\b'); putch(' '); putch('\b');
}



VOID	sensebrk()
{
	if (consts()) {
		getch();
		throw();
	}
}


VOID	error()
{
	putcrlf();
	putch('?');
	throw();
}




char	toupper(c)
char	c;
{
	return ('a' <= c && c <= 'z' ? c - 'a' + 'A' : c);
}



VOID	getline()
{
	char	c, *p;
	TINY	ct;


	p = lp = line;
	ct = 0;
	for (;;)
		switch (c = getch()) {
		case '\b':
			if (ct != 0) {
				p--;
				ct--;
				putback();
			}
			break;
		case '\r': case '\n':
			*p = '\0';
			putch('\r');
			return;
		case '\030':
			p = line;
			for (;  ct != 0;  ct--)
				putback();
			break;
		default:
			if (c >= ' ') {
				*p++ = toupper(c);
				ct++;
				putch(c);
			}
		}
}



TINY	inhex(c)
char	c;
{
	if ((c -= '0') <= 9 || 10 <= (c -= 'A'-'0'-10) && c <= 15)
		return (c);
	return (-1);
}



nat	gethex()
{
	char	c;
	nat	v;

	v = 0;
	for (;  (c = inhex(*lp)) != -1;  lp++)
		v = v * 16 + c;
	return (v);
}



nat	getdata()
{
	if (inhex(*lp) == -1)
		error();
	return (gethex());
}
	


nat	ogetdata(p)
nat	p;
{
	switch(*lp) {
	case ',':
	case '\0':
		return (p);
	default:
		return (getdata());
	}
}


#define	getaddr()	((BYTE *)getdata())
#define	ogetaddr(p)	((BYTE *)ogetdata((nat)p))


VOID	chkecomma()
{
	if (*lp != '\0' && *lp++ != ',')
		error();
}


VOID	chkend()
{
	if (*lp != '\0')
		error();
}


VOID	puthex(n)
TINY	n;
{
	putch(n < 10 ? n + '0' : n + 'A' - 10);
}


VOID	puthxb(n)
TINY	n;
{
	puthex(n >> 4);
	puthex(n & 0x0f);
}



VOID	puthxw(n)
nat	n;
{
	puthxb((TINY)(n >> 8));
	puthxb((TINY)(n & 0xff));
}



VOID	xdump()
{
	char	*p, *q;
	BYTE	*from, *to;
	TINY	ct;

	from = ogetaddr(datap);
	chkecomma();
	to = ogetaddr(from + 16*8 - 1);
	chkend();
	for (p = from;  from <= p && p <= to;  p += 16) {
		sensebrk();
		putcrlf();
		puthxw(p);
		putch(' ');
		q = p;  ct = 16;
		do {
			puthxb(*q++);
			putch(' ');
		} while (--ct != 0);
		putch(' ');
		q = p;  ct = 16;
		do {
			putch((*q & 0x7f) < ' ' ? '.' : *q);
			q++;
		} while (--ct != 0);
	}
	datap = p;
}	




VOID	xsubst()
{
	BYTE	*p;

	p = ogetaddr(datap);
	chkend();

	for (;;) {
		putcrlf();
		puthxw(p);
		putch(' ');
		putch(' ');
		puthxb(*p);
		putch(' ');
		getline();
		switch (line[0]) {
		case '.':
			return;
		case '^':
			p--;
			break;
		case '\0':
			p++;
			break;
		default:
			*p++ = getdata();
			chkend();
		}
	}
}





typedef	struct	{
	char	mnemo;
	VOID	(*func)();
}	TBENTRY;

TBENTRY	comtbl[] = {
	{'D', xdump},
	{'S', xsubst},
	{'\0', error}
};




VOID	_main()
{
	TBENTRY	*p;
	char	c;

	for (;;) {
		putcrlf();
		putch('>');
		getline();
		if (line[0] == '\0')
			continue;
		lp = &line[1];
		for (p = comtbl;  c = p->mnemo;  p++)
			if (c == line[0])
				break;
		(*p->func)();
	}
}


VOID	main()
{
	datap = 0x0000;
	catch(_main);
}
