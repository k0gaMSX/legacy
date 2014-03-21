/* F L D . C	05.08.90, BAS
 *
 * Read and concatenate fields from in file
 *
 ********* -p not implemented!!!! **********
 *
 *	FLD -u -p -z* -[b t s? i? fm1.n1,m2.n2] {infiles} >outfile
 *
 *	-?/-h	- Help
 *	-u	- unpack tabs
 *	-p	- pack tabs
 *	-z*	- skip first * spaces
 *	-b	- skip head field's spaces
 *	-t	- remove trailing spaces
 *	-s?	- output fields separator
 *	-i?	- input fields separator
 *	-fm1.n1,m2.n2 - define field
 *	-f#	- get field from tty
 *
 *	Values after "-f" define starting and ending pos of fielld:
 *
 *		m1.n1	field start (first char of field)
 *		m2.n2	field end (first char not in field)
 *
 *	Value 'm' define num of fields, skipped from begin of line.
 *	(0 means - no skip).
 *
 *	Value 'n' define num of chars, skipped in selected field
 *
 *	If "m1.n1" omitted, field started from line begin
 *	If "m2.n2" omitted, field continues to line end
 *	Excluding omitted "m2.n2", omitting any of four values means
 *	"use 0 for this value".
 *
 *	If defined -b, heading spaces will be skipped after 'm', but before
 *	'n' is applyed.
 *
 *	If defined -t, trailing spaces of filed will be deleted.
 *
 *	If defined -i?, char '?' declare input fileds separator.
 *
 *	If defined -s?, char '?' will be printed after the mentioned field.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#ifndef __P(x)
#define __P(x)	x
#endif
 
typedef unsigned char BOOL;

typedef struct {
	char	*fstr;
	char	lbl;
	char	tbl;
	char	term;
	char	sep;
	int	s_f, s_o;
	int	e_f, e_o;
} FIELD;

#define MAXLIN	512
#define MAXFLD	10

FIELD	fld[MAXFLD];
int	fp = 0,
	nufp = 0;
char	*lin = NULL;	/* буфер строки */
BOOL	uflag = 0;	/* флаг распаковки табуляторов */
int	zval = 0;	/* число пропускаемых пробелов */

FILE	*fin = stdin,
	*fou = stdout;
char	*nfin = "<stdin>",
	*nfou = "<stdout>";

char *hlp[] = {
	"usage: fld -u -z* -[bs?t?i?fm1.n1,m2.n2 {infiles} >outfile",
	"\t-?/-h\t- help",
	"\t-u\t- unpack tabs (enable absolute positions)",
	"\t-z*\t- remove first * blanks",
	"\t-b\t- Skip leading blanks of field",
	"\t-t\t- Kill trailing blanks of field",
	"\t-s?\t- Field separator for output",
	"\t-i?\t- Field separator for input",
	"\t-fm1.n1,m2.n2 - Setup field",
	"\t\t# - Get field from user",
	"\t\tm1.n1 - Start of the field (first printable char)",
	"\t\tm2.n2 - End of the field (first nonprintable char)",
	"\t\t\t'm' - number of fields to skip, from the",
	"\t\t\tstart of the data line (0 means 'skip no fields').",
	"\t\t\t'n' - number of bytes to skip in the field.",
	0
};

void help __P((void));
void error __P((char *s1, char *s2));
char *aton __P((char *p, int *num));
char *skp __P((BOOL l, int n, char *s));
char *nxt __P((char *s, char t));
char *fnd __P((int sf, int so, int ef, int eo, BOOL lbl, BOOL tbl, char term, char **eof));
char *getstr __P((char *p));
int gts __P((char **p));
void getfld __P((char *cp));
void slice __P((void));
int lget __P((char *s));

void help() {
	int i = 0;

	while (hlp[i])
		fprintf(stderr,"%s\n",hlp[i++]);
}

void error(char *s1,char *s2) {
	fprintf(stderr, "fld: %s %s\n", s1, s2 ? s2 : "");
	exit(1);
}

/* unsigned ASCII to decimal
 * end on non digit, return ptr to terminator
 */
char *aton(char *p, int *num) {
	register int n = 0;
	register char c;

	while (c = *p++, isdigit(c))
		n = 10*n + (c - '0');
	*num = n;
	return p-1;
}

char *skp(l,n,s)
	BOOL l;
	int n;
	char *s;
{
	if (l)
		while (isspace(*s))
			++s;
	while (n-- && *s++)
		;
	return s;
}

char *nxt(s,t)
	char *s, t;
{
	if (t) {
		while(*s && *s++ != t)
			;
	}
	else {
		while (isspace(*s))
			++s;
		while (*s && !isspace(*s))
			++s;
	}
	return s;
}

/* return ptrs to field start/end */
char *fnd(sf, so, ef, eo, lbl, tbl, term, eof)
	int	sf, so; 	/* start fields & chars to skip */
	int	ef, eo; 	/* end fields & chars to skip */
	BOOL	lbl;		/* skip leading whitespace flag */
	BOOL	tbl;		/* kill trailing whitespace flag */
	char	term;		/* field terminator, if not 0 */
	char	**eof;		/* eof pointer */
{
	register char *sp;		/* start pointer */
	register char *ep;		/* end pointer */
	register int i;

	/* skip over fields */
	for (sp = lin, i = sf; i-- > 0; )
		sp = nxt(sp, term);
	i = ef - sf;
	ep = sp;
	sp = skp(lbl,so,sp);
	if (ef >= 0) {
		if (i < 0) {
			i = ef;
			ep = lin;
		}
		while (i-- > 0)
			ep = nxt(ep, term);
		ep = skp(lbl,eo,ep);
		if (tbl)
			while(ep > sp && isspace(ep[-1]))
				--ep;
		*eof = (ep < sp) ? sp : ep;
	}
	else	*eof = lin + strlen(lin);
	return (sp);
}

/* Get field from tty */
char *getstr(char *p) {
	char *s, *q;

	if (*p == 0) {
		printf("-fld>");
		fflush(stdout);
		if (fgets(p = lin, 80, stdin) == NULL)
			exit(0);
		if ((s = strrchr(p, '\n')) != NULL)
			*s = 0;
	}
	s = q = p;
	while ((*q++ = gts(&s)) != 0)
		;
	if ((q = malloc(strlen(p)+1)) != NULL)
		strcpy(q,p);
	else	error("No memory for field",p);
	return q;
}

/* Process escape sequence */
int gts(char **p) {
	register char *s = *p;
	register char c = *s++;
	register int i;

	if (c == '\\') {
		c = *s;
		if (c & 0100)
			c &= 0137;
		if (c == 'T')		c = '\t';
		else if (c == 'S')	c = ' ';
		else if (c == 'N')	c = '\n';
		else if (c == 'F')	c = '\f';
		else if (c == 'V')	c = '\v';
		else if (c >= '0' && c <= '7') {
			c = 0;
			for (i = 3; --i >= 0 && (*s >= '0' && *s <= '7'); ++s)
				c = (c<<3) + (*s-'0');
			goto Ret;
		}
		else	c = *s;
		if (*s)
			++s;
	}
Ret:	*p = s;
	return c;
}

/* get field definition */
void getfld(char *cp) {
	register FIELD *x = &fld[fp];

	if (fp >= MAXFLD)
		error("Too many fields at",cp);

	if (*cp == '#') {
		x->fstr = getstr(++cp);
		++nufp;
		return;
	}

	x->s_f = x->s_o = x->e_f = x->e_o = 0;

	cp = aton(cp,&x->s_f);
	if (*cp == '.')
		cp = aton(++cp,&x->s_o);
	if (*cp == ',') {
		cp = aton(++cp,&x->e_f);
		if (*cp == '.')
			cp = aton(++cp,&x->e_o);
	}
	if (*cp)
		error("Illegal field definition",cp-1);
/*	x->e_f = -1;
*/
}

void slice() {
	register int i;
	register FIELD *x;
	register char *b;
	static char *e;

	while (lget(lin)) {
		for (i = 0; i < fp; i++) {
			x = &fld[i];
			if ((b = x->fstr) != NULL) {
				fputs(b,fou);
				continue;
			}
			b = fnd(x->s_f,x->s_o,x->e_f,x->e_o,
				x->lbl,x->tbl,x->term,&e);
			while (b < e)
				fputc(*b++,fou);
			if (i < fp-1)
				fputc(x->sep ? x->sep : '\t',fou);
		}
		fputc('\n',fou);
		if (ferror(fou))
			error("Error write output file",nfou);
	}
}

int lget(s)
	char *s;
{
	register int c;
	register int pos;
	static char *p;

	for (pos = 0; (c = fgetc(fin)) != EOF && c != '\n'; ) {
		if (uflag && c == '\t')
			for (c = 8 - (pos&7); --c >= 0; )
				s[pos++] = ' ';
		else	s[pos++] = c;
	}
	if (ferror(fin))
		error("Error read input file",nfin);
	s[pos] = '\0';
	for (pos = zval, p = s; --pos >= 0; ++p)
		if (*p != ' ')
			break;
	if (s != p)
		strcpy(s,p);
	return c != EOF;
}

int main(argc, argv)
	register int argc;
	register char *argv[];
{
	static char *p;
	register char c;
	register int ac = argc, nf = 0;

	if ((lin = (char *)malloc(MAXLIN+1)) == NULL)
		error("Not enough memory",0);

	for (ac = 1; ac < argc; ++ac) {
		c = *(p = argv[ac]);
		if (c == '-') {
			argv[ac] = NULL;
			++p;
			while(p != 0 && (c = *p++) != 0) {
				switch (tolower(c)) {
				case '?':
				case 'h':
					help();
					return 0;

				case 'u':
					++uflag;
					break;

				case 'z':
					p = aton(p,&zval);
					break;

				case 'b':
					++fld[fp].lbl;
					break;

				case 't':
					++fld[fp].tbl;
					break;

				case 's':
					fld[fp].sep = gts(&p);
					break;

				case 'i':
					fld[fp].term = gts(&p);
					break;

				case 'f':
					getfld(p);
					++fp;
					p = NULL;
					break;

				default:
					error("Illegal switch",p-1);
					break;
				}
			}
		}
		else	++nf;
	}
	if (fp == 0 || fp == nufp) {
		fld[fp].e_f = -1;
		fp++;
/*		remark("Warning - default field\n",0);	/**/
	}
	if (nf > 0) {
		for (ac = 1; ac < argc; ++ac) {
			if ((nfin = argv[ac]) != NULL) {
				if ((fin = fopen(nfin,"r")) == NULL)
					error("Can't open input file",nfin);
				slice();
				fclose(fin);
			}
		}
	}
	else	slice();
	fclose(fou);
	return 0;
}

