/*
	(C) Copyrighted by ASCII corp., 1988
		All rights Reserved.

		File:   gcal.c
*/
#pragma nonrec
#include <stdio.h>
#include <glib.h>

#define	GETDATE		0x2a
#define	getdate(regs)	regs.bc = (NAT)GETDATE, callx((NAT)5, &regs)
#define	ESC		(char)27

#define	BLACK		(TINY)1
#define	DARKBLUE	(TINY)4
#define DARKRED		(TINY)6
#define	CYAN		(TINY)7
#define	RED		(TINY)8
#define	LIGHTRED	(TINY)9
#define	DARKYELLOW	(TINY)10
#define	LIGHTYELLOW	(TINY)11
#define	WHITE		(TINY)15

#define	P_LINE		CYAN
#define	S_LINE		LIGHTRED
#define	I_LINE		LIGHTYELLOW
#define	FORE		WHITE
#define BACK		DARKBLUE
#define	BORD		DARKBLUE
#define ARROW		LIGHTRED
#define DATE		CYAN
#define FRAME		LIGHTYELLOW
#define LENGTH		DARKYELLOW
#define LEN_CENTER	DARKRED
#define SIDE		DARKRED
#define SUNDAY		RED
#define SATUDAY		CYAN
#define WEEKDAY		WHITE

VOID	newline(), tab();
VOID	gprint();

static	int	daytab[2][14] = {{31,31,28,31,30,31,30,31,31,30,31,30,31,31},
				  {31,31,29,31,30,31,30,31,31,30,31,30,31,31}};
static	TINY	colortab[3] = {P_LINE, S_LINE, I_LINE};
int		date1[6], date2[3];
int		wk[2];
int		dycnt[2];
char		*mon[2];
char		s[100];
char		buffer[1024];

unsigned	ctotal, btotal;
BOOL		bleap , cleap;

main(argc, argv)
int	argc;
char	*argv[];
{
	VOID	setdate();
	VOID	cal(), bio(), arrow();
	VOID	retn_txtmd();
	VOID	putusage(), putmesage(), puthlp();

	TINY	i;
	REGS	tm;

	ginit();

	s[0] = '\0';

	if(argc < 2)
		putusage();
	for(i = 1; i < argc; i ++) {
		if(*(argv[i]) == '/')
			switch(toupper(*(argv[i] + 1))) {
				case 'H':
					puthlp();
			}
		strcat(s, argv[i]);
		strcat(s, "/");
	}
	setdate(s);
	if(date1[3] == 0 && date1[4] == 0 && date1[5] == 0) {
		getdate(tm);
		date1[3] = tm.hl;		/* check's year  */
		date1[4] = tm.de / 256;		/* check's month */
		date1[5] = tm.de % 256;		/* check's day	 */
	}
	cleap = (date1[3]%4 == 0) ? 1 : 0;
	bleap = (date1[0]%4 == 0) ? 1 : 0;

	putmesage();

	color(FORE, BACK, BORD);
	screen(msx2() ? (TINY)5 : (TINY)2);
	inispr((TINY)0);
	cls();
	boxline(0, 0, 255, 121, FRAME, PSET);
	cal();
	boxline(0, 121, c_xmax, c_ymax, FRAME, PSET);
	bio();
	arrow();
	retn_txtmd();
}

VOID	setdate(s)
char	*s;	
{
	int	oatoi();

	TINY	i;

	for(i = 0; i < 7; i ++) {
		date1[i] = oatoi(&s);
		if(*s == '/' || *s == '-') 
			s ++;
	}
}

int	oatoi(pp)
char	**pp;
{
	int	count;
	char	cc;

	count = 0;
	while (isdigit(cc = **pp)) {
  		count = count * 10 + cc - '0';
     		(*pp) ++;    
	}
	return (count);
}

VOID	cal()
{
	VOID	cal_head(), cal_body();

	cal_head();
	cal_body();
}

VOID	cal_head()
{
	unsigned	day_total();
	VOID		cal_title();

	static	char	*montab[] = {"", "January", "February", "March",
					"April", "May", "June", "July",
					"August", "September", "October",
					"November", "December", "January"};

	unsigned	total;
	TINY		i;

	ctotal = day_total(date1[3], date1[4], date1[5], cleap);
	btotal = day_total(date1[0], date1[1], date1[2], bleap);
	total = ctotal - date1[5];
	for(i = 0; i < 2; i ++) {
		wk[i] = (total+2) % 7;
		mon[i] = montab[date1[4]+i];
		dycnt[i] = 1;
		total += daytab[cleap][date1[4]];
	}
	glocate(0, 118);
	cal_title();
}

VOID	cal_body()
{
	VOID	cal_print();

	TINY	i;

	while(dycnt[0] <= daytab[cleap][date1[4]] ||
				dycnt[1] <= daytab[cleap][date1[4] + 1]) {
		for(i = 0; i < 2; i ++) {
			tab((int)3*wk[i]);
			while(wk[i] < 7) {
				cal_print(i);
				if(i != 1 || wk[1] != 6)
					tab((int)1);
				wk[i] ++;
				dycnt[i] ++;
			}
			if(i == 1)
				c_lastx = 4;
			else
				tab((int)1);  
			wk[i] = 0;
		}
	}
	newline();
}	

VOID	cal_print(i)
TINY	i;
{
	VOID	cgcolor();

	if(dycnt[i] <= daytab[cleap][date1[4] + i]) {
		sprintf(buffer, "%2d", dycnt[i]);
		cgcolor();
	}
	else
		tab((int)2);
}

VOID	cal_title()
{
	VOID	cgcolor();

	static	char	*weektab[] = {"Su ", " M ", "Tu ", " W ", "Th ", " F ",
					"Sa"};

	TINY	i, j;

	newline();
	sprintf(buffer, "   %8s / %4d       %8s / %4d",
	    mon[0], date1[3], mon[1], (date1[4] == 12) ? date1[3]+1 : date1[3]);
	gprint();
	newline();
	for(i = 0; i < 2; i ++) {
		for(j = 0; j < 7; j ++) {
			sprintf(buffer, "%s", weektab[j]);
			cgcolor();
		}
		tab((int)2);
	}
	c_lastx = 4;
}

VOID	bio()
{
	VOID	bio_head(), bio_body(), bio_foot();

	bio_head();
	bio_body();
	bio_foot();
}

VOID	bio_head()
{
	static	char	leveltab[] = "+0-"; 

	int	i, j;
	char	*k;

	glocate(6, 1);
	c_fore = DATE;
	sprintf(buffer, " birthday %4d/%2d/%2d  checkday %4d/%2d/%2d",
		date1[0], date1[1], date1[2], date1[3], date1[4], date1[5]);
	gprint();
	line(10, 72, 250, 72, SIDE, PSET);
	for(i = 10; i < 251; i += 6)
		line(i , 32, i, 112, (i == 130) ? LEN_CENTER : LENGTH, PSET);
	k = leveltab;
	for(j = 43; j <= 93; j += 25) {
		glocate(4, j);
		sprintf(buffer, "%c", *k++);
		gprint();
	}
}

VOID	bio_body()
{
	VOID	bio_print();

	int	i;
	TINY	*j;

	j = colortab;
	for(i = 23; i <= 33; i += 5)
		bio_print(i, *j++);
}
VOID	bio_foot()
{
	static	char	*headtab[] = {"physical", "sensitive", "intellectual"};

	TINY	i;

	glocate(22, 113);
	for(i = 0; i < 3; i ++) {
		c_lastx += 12;
		c_fore = colortab[i];
		sprintf(buffer, "%s", headtab[i]);
		gprint();
	}
}

VOID	bio_print(t, co)
int	t;
TINY	co;
{
	int	sine();

	int	x, y, keepx, keepy;
	int	d;
	int	i;
	BOOL	sw = 0;
	
	if((ctotal-btotal) < 20)
		i = btotal - ctotal;
	else
		i = -20;
	keepx = x = 10 + (i + 20) * 6;
	for(; i <= 20; i ++, x += 6) {
		d = (ctotal-btotal + i) % t * 360 / t;
		y = sine(d) * 40 / 100;
		if(sw == 0) {
			keepy = y;
			sw = 1;
		}
		line(keepx, 72-keepy, x, 72-y, (TINY)co, PSET);
		keepx = x;
		keepy = y;
	}
}

VOID	arrow()
{
	VOID	move_arrow();

	static 	TINY	arrow[] = {56, 56, 56, 56, 254, 124, 56, 16};

	int	x;

	sprite((TINY)0, arrow);
	x = 20;
	while(x != 999) {
		move_arrow(x);
		switch((int)getch()) {
			case	28:
				x = (x + 1) % 41;
				break;
			case	29:
				x = (x + 40) % 41;
				break;
			case	'Q':
			case	'q':
			case	ESC:
				x = 999;
				break;
		}
	}	
}

VOID	move_arrow(x)
int	x;
{
	VOID	total_day(), chgprnt_day();

	static	TINY	arr_clr[] = {ARROW, ARROW, ARROW, ARROW,
				     ARROW, ARROW, ARROW, ARROW};

	if(msx2())
		colspr((TINY)0, arr_clr);
	putspr((TINY)0, x*6+7, 23, ARROW, (TINY)0);                   
	if(!msx2()) {
		c_fore = BACK;
		chgprnt_day();
	}
	total_day(ctotal-20 + x);
	c_fore = ARROW;
	chgprnt_day();
}

VOID	chgprnt_day()
{
	glocate(222, 10);
	sprintf(buffer, "%2d/%2d", date2[1], date2[2]);
	gprint();
}

VOID	retn_txtmd()
{
	totext();
	color(WHITE, BLACK, BLACK);
}

VOID	newline()
{
	c_lastx = 4;
	c_lasty += 8;
}

VOID	tab(times)
int	times;	
{
	char	*p;
	TINY	i;

	p = buffer;
	for(i = 0; i < times; i ++)
		*p ++ = ' ';
	*p = '\0';
	gprint();
}

VOID	cgcolor()
{
	if(4 <= c_lastx && c_lastx <= 16 || 128 <= c_lastx && c_lastx <= 148)
		c_fore = SUNDAY;
	if(106 <= c_lastx && c_lastx <= 124 || 238 <= c_lastx && c_lastx <= 256)
		c_fore = SATUDAY;
	gprint();
	c_fore = WEEKDAY;
}

VOID	gprint()
{
	char	*p;

	p = buffer;
	while(*p != '\0') {
		if(c_lastx < c_xmax) 
			c_lastx -= 2;
		grpprt(*p++, PSET);
	}
	buffer[0] = '\0';
}

unsigned	day_total(yy, mm, dd, leap)
unsigned	yy, mm, dd;
BOOL		leap;
{
	unsigned	total;
	TINY		i;

	total = (yy-1901)*365 + (yy-1901)/4;
	for(i = 1; i < mm; i ++)
		total += daytab[leap][i];
	total += dd;
	return(total);
}

VOID		total_day(total)
unsigned	total;
{
	unsigned	i;
	unsigned	y, m, d;
	BOOL		leap;

	y = total / 365;
	i = y * 365 + y / 4;
	if(i >= total)
		y --;
	total -= y * 365 + y / 4;
	leap = ((y % 4 == 3) ? 1 : 0);
	for(m = 1; total > (unsigned)daytab[leap][m]; m ++)
		total -= (unsigned)daytab[leap][m];
	d = total;
	y += 1901;

	date2[0] = y;
	date2[1] = m;
	date2[2] = d;
}

int	sine(deg)
int	deg;
{
	static	TINY	s[] = { 0,  5, 10, 16, 21, 26, 31, 36, 41, 45,
				 50, 54, 59, 63, 67, 71, 74, 78, 81, 84,
				 87, 89, 91, 93, 95, 97, 98, 99, 99, 100, 100};
	int	d = deg;
	int	v = 1;

	if(d >= 180) {
		d = 360 - d;
		v = -1;
	}
	if(d >= 90)
		d = 180 - d;
	d /= 3;
	return(v * (int)s[d]);
}

VOID	putusage()
{
	fprintf(stderr, "\
usage: gcal <yyyy/mm/dd> [<yyyy/mm/dd>]\n\
             (birthday)    (checkday)\n");
	exit(1);
}

VOID	putmesage()
{
	if(date1[3] == 2079 && date1[4] > 4) {
		fprintf(stderr, "\
Invalid check date\n\
Outputs calendar 1980/01 - 2079/04\n");
		exit(1);
	}
	if(date1[3] < 1980 || date1[3] > 2079 || date1[4] < 1 || date1[4] > 12
			|| date1[5] < 1 || date1[5] > daytab[cleap][date1[4]]) {
		fprintf(stderr, "\
Invalid check date (Checkday ... 1980/01/01 - 2079/04/30)\n");
		exit(1);
	}
	if(date1[0] < 1901 || date1[0] > date1[3] || date1[1] < 1 || date1[1] >
	             12 || date1[2] < 1 || date1[2] > daytab[bleap][date1[1]]) {
		fprintf(stderr, "\
Invalid birth date (Birthday ... 1901/01/01 - today)\n");
		exit(1);
	}
	if(date1[0] >= date1[3] && date1[1] >= date1[4] && date1[2] > date1[5]) {
		fprintf(stderr, "\
Invalid birth date\n\
Birthday is more than checkday\n"); 
		exit(1);
	}
}

VOID	puthlp()
{
/*---------------------------------------*/
	printf("\
          MSX-C Library HELP GCAL\n\
===========================================\n");
	printf("\
GCAL   gives   2   months   calendar   and\n\
your   Biorythm for 41 days.\n");
	printf("\n\
usage: gcal[/h] <yyyy/mm/dd> [<yyyy/mm/dd>]\n\
\n\
		<yyyy-mm-dd> [<yyyy-mm-dd>]\n\
			or\n\
		<yyyy mm dd> [<yyyy mm dd>]\n\
		 (birthday)    (checkday)\n");
	printf("\
     /h ... help\n");
	exit(1);
}
                                        