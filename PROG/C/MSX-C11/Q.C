/***************************/
/*    MSX-C sample program */
/***************************/

#pragma nonrec
#include <stdio.h>

TINY        line();
unsigned    rnd();
VOID        chgmod();
VOID        totext();
TINY        *color();
VOID        cls();

typedef struct {
	int     x1;
	int     y1;
	int     x2;
	int     y2;
	TINY    bc;
} DATA;


#define LINES 80
#define LOG_OP (TINY)3  /*xor*/

int         tmpx, tmpy, incx, incy;

/**If MSX2, use screen mode 8**/
BOOL        MSX2 = TRUE;
int         xmax = 255;
int         ymax = 211;
int         cmax = 255;


VOID draw(c, p)
TINY    c;
DATA    *p;
{

	if (!MSX2)
		p->bc = (TINY)0;

	line(p->x1, p->y1, p->x2, p->y2, p->bc, LOG_OP);   /*Erase*/


	if ((tmpx += incx) < 0 || tmpx > xmax) {
		incx = -incx;
		tmpx += incx;
	}

	if ((tmpy += incy) < 0 || tmpy > ymax) {
		incy = -incy;
		tmpy += incy;
	}

	p->x1 = p->x2;
	p->y1 = p->y2;
	p->x2 = tmpx;
	p->y2 = tmpy;
	p->bc = c;
	line(p->x1, p->y1, p->x2, p->y2, p->bc, LOG_OP);   /*Draw*/
}

# define EXBRSA (TINY *)(0xfaf8) /*Work area for MSX2 sub-rom slot  address*/
				 /*Used to know MSX version number.        */
TINY *setup()
{
	TINY *prev;   /*Previous color*/

	if (*(EXBRSA))/*If MSX2*/
		chgmod((TINY)8);
	else {
		MSX2 = FALSE;
		ymax = 191;
		cmax = 15;
		chgmod((TINY)2);
	}

	prev = color((TINY)cmax, (TINY)0, (TINY)0); /*Save previous color*/
	cls();
	return(prev); /*Return previous color*/
}


main()
{
	DATA    l[LINES];
	DATA    *p = &l[0];
	TINY    i, c, *prev;

	prev = setup();  /*adapt valiables to screen mode*/

	for (i = 0; i < LINES; i++, p++) {
		p->x1 = 0;
		p->y1 = 0;
		p->x2 = 0;
		p->y2 = 0;
		p->bc = (TINY)0;
	}

	tmpx = rnd((unsigned)xmax);
	tmpy = rnd((unsigned)ymax);

	while (!kbhit()) {
		c = (TINY)rnd((unsigned)cmax + 1);  /*Color*/
		incx = rnd((unsigned)11) - 5;       /*Range (-5) to 5*/
		incy = rnd((unsigned)11) - 5;
		p = &l[0];
		for (i = 0; i < LINES; i++)
			draw(c, p++);
	}

	color(prev[0], prev[1], prev[2]);           /*Previous color*/
	totext();                                   /*Return to text mode*/
}
