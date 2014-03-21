/*
 *	_fnum() - converts floating numbers to ascii decimal
 *	representations.
 */

#ifndef uchar
#define	uchar	unsigned char
#endif

#define	putc(c)	*ptmp++ = c
#define	buf	(xbuf+2)

extern double	_frndint();
extern int	strlen(char *);
extern int	abs(int);

void _fnum(double val, char fmt, int prec, char *ptmp);

void _fnum(val, fmt, prec, ptmp)
double	val;
char	fmt;
int	prec;
char	*ptmp;
{
	register char *	cp, * xp;
	int		exp, efmt = 0;
	char		digs;
	short		twid;
	uchar		sign;
	char		xbuf[60];

	if ((fmt & 223) == 'E') efmt = 2;
	if ((fmt & 223) == 'G') efmt = 1;
	if(prec < 0)
		prec = 6;
	twid = 0;
	if(val < 0.0) {
		val = -val;
		sign = 1;
	} else
		sign = 0;
	exp = 0;
	if(efmt == 0 && prec == 0)
		val = _frndint(val);		/* round to integer */
	_fbcd(val, &exp, buf);
	cp = buf;
	while(*cp == '0')
		cp++;
	if(*cp == 0)		/* all zero */
		cp--;
	if(strlen(cp) > 1) {
		xp = cp+strlen(cp)-1;
		while(*xp == '0') {			/* remove trailing zeros */
			*xp-- = 0;
			exp++;
		}
	} else if(*cp == '0')
		exp = 0;
	cp[-1] = '0';
	digs = strlen(cp);	/* number of significant digits */
	if(efmt == 0 && prec == 0 || efmt == 1 && exp >= 0 && exp <= 5+prec) {
		/* use d format */
		if(exp  < 0) {	/* too much precision */
			char	c;
	
			xp = cp+digs+exp;
			c = *xp;
			*xp = 0;
			if(c >= '5')
				for(;;)
					if((*--xp += 1) == '9'+1)
						*xp = '0';
					else
						break;
			if(xp < cp)
				cp = xp;
			digs = strlen(cp);
			exp = 0;
		}
		if(sign)
			putc('-');
		while(*cp)
			putc(*cp++);
		while(exp > 0) {
			putc('0');
			exp--;
		}
		putc(0);
		return;
	}
	if(efmt == 1 && exp >= 5 || exp + digs < -4)
		efmt++;
	if(efmt >= 2) {		/* use e format */
		if(digs > prec+1) {	/* need to round it */
			char	c;
loop:
			xp = cp+prec+1;
			exp += digs-(prec+1);
			c = *xp;
			*xp = 0;
			if(c >= '5')
				for(;;)
					if((*--xp += 1) == '9'+1)
						*xp = '0';
					else
						break;
			if(xp < cp)
				cp = xp;
			digs = strlen(cp);
			if(digs > prec+1)
				goto loop;
		}
		exp += digs - 1;		/* allow for moving dec. pt. */
		prec -= digs - 1;
		if(sign)
			putc('-');
		putc(*cp++);
		putc('.');
		while(*cp)
			putc(*cp++);
		while(prec > 0) {
			putc('0');
			prec--;
		}
		putc('e');
		if(exp < 0) {
			exp = -exp;
			putc('-');
		} else
			putc('+');
		if(exp >= 100) {
			putc(exp / 100 + '0');
			exp %= 100;
		}
		putc(exp / 10 + '0');
		putc(exp % 10 + '0');
		putc(0);
		return;
	}
	/* here for f format */
	if(exp + prec < 0) {	/* too much precision */
		char	c;

		xp = cp+digs+exp+prec;
		c = *xp;
		*xp = 0;
		if(c >= '5')
			for(;;)
				if((*--xp += 1) == '9'+1)
					*xp = '0';
				else
					break;
		if(xp < cp)
			cp = xp;
		digs = strlen(cp);
		exp = -prec;
	}
	prec += exp;
	digs = -digs;
	if(sign)
		putc('-');
	if(exp <= digs) {
		putc('0');
		putc('.');
		while(exp < digs) {
			putc('0');
			exp++;
		}
	}
	while(*cp) {
		putc(*cp++);
		if(++digs == exp)
			putc('.');
	}
	while(exp > 0) {
		putc('0');
		prec--;
		if(--exp == 0)
			putc('.');
	}
	while(prec > 0) {
		putc('0');
		prec--;
	}
	putc(0);
	return;
}
