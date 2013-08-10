/*
	(C) Copyrighted by ASCII corp., 1988
		All rights Reserved.

		File:	den.c
*/
#include <stdio.h>
#include <math.h>

#define	USECURSES	/*  if this switch is defined, use MSX-CURSES */
#ifdef	USECURSES
#include <curses.h>
#endif

#pragma	nonrec

#define	double	XDOUBLE
#define	long	SLONG

#define	SDEPTH	20
#define	DMODE using[4]
#define	OPNUM	10

typedef	struct {
	long	*(*func)();
	TINY	priority;
	} OPT;

int	debug = 0;
int	vsp = 0;
int	osp = 0;
long	vstack[SDEPTH];
OPT	ostack[SDEPTH];
long	mem[10];

TINY	pbase = 0;	/*  priority base  */
long	x = {0, 0, 0, 0};
long	work;
char	using[] = "%11lD\n";
char	number[] = "0123456789abcdef";
char	*sbuf;
WINDOW	*wndw, *swin1, *swin2;

VOID
help()
{
static	char	hlpmsg[] = "\
All clear : A\n\
Clear     : C\n\
Number    : 0 1 2 3 4 5 6 7 8 9 a b c d e f\n\
Operation : ( ) * / % + - & | ^ =(ret)\n\
+/-       : _\n\
Mem recall: m[0-9]\n\
Mem in    : M[0-9]\n\
Mem +     : M+[0-9]\n\
Mem -     : M-[0-9]\n\
Mem allclr: MA\n\
String cal: Sstring\n\
Radix     : D U X O\n\
Function  : ~ < > [ ] { }\n\
Quit      : Q\n\
Help      : ?\n\n";
#ifndef	USECURSES
	puts(hlpmsg);
#else
	mvwaddstr(swin2, 0, 0, hlpmsg);
	wrefresh(swin2);
#endif
	}

VOID
dispstk()
{
	int	i;

	for(i = 0; i < vsp; i++) {
		printf("%11ld\n\t\t%d\n", &vstack[i], (int)ostack[i].priority);
		}
	printf("vsp:%d   osp:%d\n\n", vsp, osp);
	}

VOID
disp(rfrsh)
BOOL	rfrsh;
{
	if(rfrsh) {
#ifndef	USECURSES
		printf("\033A");
		putchar(DMODE);
		putchar(' ');
		printf(using, &x);
#else
		mvwaddch(swin1, 0, 0, DMODE);
		waddch(swin1, ' ');
		wprintw(swin1, using, &x);
		wrefresh(swin1);
#endif
		}
	}

VOID
vpush(p)
long	*p;
{
	char	*msg = "Value stack overflow\n\n";
	if(vsp < SDEPTH) {
		slcpy(&vstack[vsp], p);
		vsp++;
		}
	else {
#ifndef	USECURSES
		puts(msg);
#else
		mvwaddstr(swin2, 0, 0, msg);
		wrefresh(swin2);
#endif
		
		}
	}

long	*
vpop(p)
long	*p;
{
	char	*msg = "Value stack underflow\n\n";
	if(vsp > 0) {
		vsp--;
		slcpy(p, &vstack[vsp]);
		}
	else {
#ifndef	USECURSES
		puts(msg);
#else
		mvwaddstr(swin2, 0, 0, msg);
		wrefresh(swin2);
#endif
		}
	return(p);
	}

VOID
vclr()
{
	vsp = 0;
	}

STATUS
vdat()
{
	if(vsp)
		return(OK);
	else
		return(ERROR);
	}

VOID
opush(p)
OPT	*p;
{
	char	*msg = "Ope stack overflow\n\n";
	if(osp < SDEPTH) {
		ostack[osp].func = p->func;
		ostack[osp].priority = p->priority;
		osp++;
		}
	else {
#ifndef	USECURSES
		puts(msg);
#else
		mvwaddstr(swin2, 0, 0, msg);
		wrefresh(swin2);
#endif
		}
	}

OPT	*
opop(p)
OPT	*p;
{
	char	*msg = "Ope stack underflow\n\n";
	if(osp > 0) {
		osp--;
		p->func = ostack[osp].func;
		p->priority = ostack[osp].priority;
		}
	else {
#ifndef	USECURSES
		puts(msg);
#else
		mvwaddstr(swin2, 0, 0, msg);
		wrefresh(swin2);
#endif
		}
	return(p);
	}

VOID
oclr()
{
	osp = 0;
	}

long *(*odat())()
{
	if(osp)
		return(ostack[osp].func);
	else
		return(NULL);
	}

char	*
index(s, c)
char	*s, c;
{
	char	cc;

	while(cc = *s) {
		if(c == cc)
			return(s);
		s++;
		}
	return(NULL);
	}

VOID
opll(func)
long	*(*func)();
{
	long	a, b;

	vpop(&a);
	vpop(&b);
	(*func)(&a, &b, &a);
	vpush(&a);
	}

BOOL
oneop(c)
char	c;
{
	BOOL	rfrsh = YES;
	long	*(*func)();
	TINY	pri;
	OPT	before, current;

	switch(c) {
		case	'|':
			current.func = slor;
			current.priority = pbase + 0;
			break;
		case	'^':
			current.func = slxor;
			current.priority = pbase + 1;
			break;
		case	'&':
			current.func = sland;
			current.priority = pbase + 2;
			break;
		case	'+':
			current.func = sladd;
			current.priority = pbase + 3;
			break;
		case	'-':
			current.func = slsub;
			current.priority = pbase + 3;
			break;
		case	'%':
			current.func = (DMODE == 'D') ? slmod : ulmod;
			current.priority = pbase + 4;
			break;
		case	'*':
			current.func = slmul;
			current.priority = pbase + 4;
			break;
		case	'/':
			current.func = (DMODE == 'D') ? sldiv : uldiv;
			current.priority = pbase + 4;
			break;
		default:
			current.func = 0;
			current.priority = pbase + 0;
		}
	while(odat()) {
		opop(&before);
		if(current.priority <= before.priority) {
			opll(before.func);
			}
		else {
			opush(&before);
			break;
			}
		}
	opush(&current);
	return(rfrsh);
	}
VOID
onefunc(c)
char	c;
{
	switch(c) {
		case	'~':
			slnot(&x, &x);
			break;
		case	'_':
			slneg(&x, &x);
			break;
		case	'<':
			slsll(&x, &x, (TINY)1);
			break;
		case	'>':
			if(DMODE == 'D')
				slsra(&x, &x, (TINY)1);
			else
				slsrl(&x, &x, (TINY)1);
			break;
		case	'[':
			slrlc(&x, &x, (TINY)1);
			break;
		case	']':
			slrrc(&x, &x, (TINY)1);
			break;
		case	'{':
			slrl(&x, &x, (TINY)1);
			break;
		case	'}':
			slrr(&x, &x, (TINY)1);
			break;
		}
	}

char
keyin(s)
char	*s;
{
static	char	*strin = NULL;
	char	c;

	if(s != NULL) {		/*  only for set strin  */
		strin = s;
		return(*s);
		}
	if(strin == NULL || *strin == '\0')
		c = getch();
	else {
		c = *strin++;
		if(*strin == '\0')
			strin = NULL;
		}
	return(c);
	}
	
VOID
clr(c)
char	c;
{
	switch(c) {
		case	'A':
			vclr();
			oclr();
		case	'C':
			*((int *)(&x)+1) = *(int *)&x = 0;
			break;
		}
	}

TINY
chradix(c)
char	c;
{
	DMODE = c;
	switch(c) {
		case	'D':
		case	'U':
			return(10);
		case	'X':
			return(16);
		case	'O':
			return(8);
		}
	}

VOID
numin(n, radix, vin)
TINY	n;
TINY	radix;
BOOL	vin;
{
	if(!vin)
		clr('C');
	if(DMODE == 'D' && slcmp(slabs(NULL, &x),"\xcc\xcc\xcc\xc") > 0)
		slmod(&x,&x,atosl(NULL, "100000000"));
	if(DMODE == 'U' && slcmp(&x,"\x99\x99\x99\x19") > 0)
		ulmod(&x,&x,atosl(NULL, "100000000"));
	*((int *)&work+1) = *(int *)&work = 0;
	work.byte[0] = (char)radix;
	slmul(&x, &x, &work);
	work.byte[0] = n;
	if(DMODE == 'D' && slsgn(&x) < 0)
		slsub(&x, &x, &work);
	else
		sladd(&x, &x, &work);
	}

VOID
numbs(c, radix, vin)
char	c;
TINY	radix;
BOOL	vin;
{
	if(vin) {
		*((int *)&work+1) = *(int *)&work = 0;
		work.byte[0] = (char)radix;
		if(DMODE == 'D')
			sldiv(&x, &x, &work);
		else
			uldiv(&x, &x, &work);
		}
	}

VOID
memac()
{
	long	*p;
	
	*((int *)&work+1) = *(int *)&work = 0;
/*  initalize memory  */
	for(p = mem; p < mem + 10; p++)
		slcpy(p, &work);
	}

BOOL
memin()		/*  Min, M+, M-, MAC(Memory All Clear)  */
{
	long	*p;		/*  Min	: 'M0'  ~ 'M9'	*/
	char	c, cc;		/*  M+	: 'M+0' ~ 'M+9'	*/
	BOOL	vin = YES;	/*  M-	: 'M-0' ~ 'M-9'	*/
				/*  MAC	: 'MA'		*/
	c = keyin(NULL);
	if(isdigit(c)) {
		slcpy(&mem[c - '0'], &x);
		vin = NO;
		}
	else if(c == '+' || c == '-') {
		cc = keyin(NULL);
		if(isdigit(cc)) {
			vin = NO;
			p = &mem[cc - '0'];
			if(c == '+')
				sladd(p, p, &x);
			else
				slsub(p, p, &x);
			}
		}
	else if(c == 'A')
		memac();
	return(vin);
	}

BOOL
memrecall()		/*  MR(Memory Recall)  */
{
	char	c;		/*  MR : 'm0' ~ 'm9'  */
	BOOL	vin = YES;

	c = keyin(NULL);
	if(isdigit(c)) {
		slcpy(&x, &mem[c - '0']);
		vin = NO;
		}
	return(vin);
	}

VOID
dewa(c)
char	c;
{
	OPT	forequ;

	switch(c) {
		case	'\n':
		case	'=':
			pbase = 0;
		case	')':
			vpush(&x);
			while(odat()) {
				opop(&forequ);
				if(forequ.priority >= pbase)
					opll(forequ.func);
				else {
					opush(&forequ);
					break;
					}
				}
			vpop(&x);
			if(pbase >= OPNUM)
				pbase -= OPNUM;
		}
	}
	
VOID
strin()
{
	char	*msg = "Not enough memory\n\n";
	if(sbuf == NULL)
		if((sbuf = alloc(1024)) == NULL) {
#ifndef	USECURSES
			fprintf(stderr, msg);
#else
			mvwaddstr(swin2, 0, 0, msg);
			wrefresh(swin2);
#endif
			return;
			}
#ifndef	USECURSES
	gets(sbuf);
	putchar('\n');
#else
	echo();
	mvwgetstr(swin2, 0, 0, sbuf);
	wclear(swin2);
	noecho();
#endif
	keyin(sbuf);
	}

main(argc, argv)
int	  argc;
char	**argv;
{
	char	c;
	char	*p;
	TINY	radix;
	BOOL	vin, rfrsh;
#ifdef	USECURSES
	BOOL	usesw2;
#endif

	if(argc >= 2 && strcmp(argv[1], "-d") == 0) {
		debug = -1;
		}

	memac();
#ifdef	USECURSES
	initscr();
	if(COLS >= 45) {
		wndw  = newwin(18, 45, 3, 15);
		swin1 = subwin(wndw,  1, 15, 3, 15);
		swin2 = subwin(wndw, 17, 45, 4, 15);
	} else {
		wndw  = newwin(19, 30, 0, 0);
		swin1 = subwin(wndw,  1, 15, 0, 0);
		swin2 = subwin(wndw, 18, 30, 1, 0);
	}
	if(wndw == NULL) {
		fprintf(stderr, "Not enough screen size or memory\n");
		exit(1);
	}
	noecho();
	usesw2 = NO;
#endif
	radix = chradix('D');
	vin = NO;		/*  value input  */
	disp((BOOL)YES);
	while((c = keyin(NULL)) != 'Q') {
#ifdef	USECURSES
		if(usesw2) {
			wclear(swin2);
			wrefresh(swin2);
			usesw2 = NO;
			}
#endif
		rfrsh = YES;
		if(c == '?') {
			help();
#ifdef	USECURSES
			usesw2 = YES;
#endif
			}
		else if(index("AC", c))
			clr(c);
		else if(index("DUXO", c))
			radix = chradix(c);
		else if(c == 'M') {	 /*  Min  M+  M-  MAC  */
			if(!memin())
				vin = NO;
			}
		else if(c == 'm') {	/*  MR  */
			if(!memrecall())
				vin = NO;
			}
		else if(c == '\b')
			numbs(c, radix, vin);
		else if(index(")=\n", c)) {
			dewa(c);
			vin = NO;
			}
		else if(c == '(') {
			if(pbase < 240)
				pbase += OPNUM;
			clr('C');
			vin = NO;
			}
		else if(index("*/%+-&^|", c)) {
			vpush(&x);
			rfrsh = oneop(c);
			vpop(&x);
			vpush(&x);
			vin = NO;
			}
		else if(index("~_<>[]{}", c))
			onefunc(c);
		else if((p = index(number, c)) && ((TINY)(c=p-number)<radix)){
			numin(c, radix, vin);
			vin = YES;
			}
		else if(c == '!') {
			if(debug)
				dispstk();
			}
		else if(c == 'S') {
			strin();
#ifdef	USECURSES
			usesw2 = YES;
#endif
			}
		else
			rfrsh = NO;
		disp(rfrsh);
		}
#ifdef	USECURSES
	clear();
	refresh();
	endwin();
#endif
	}
                                         