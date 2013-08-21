/*
**
**	SYSLIB.H
**	a header for a system library SLIB
**	(c) 1995, SOLID
*/


#ifndef	__SOLIDC__	/* for ASCII C */
typedef	char	void;
#endif

typedef	unsigned	uint;
typedef	char		BYTE;
typedef	char		BOOL;
typedef	char		*PCHAR;
typedef int		*PINT;
typedef unsigned 	WORD;



typedef	struct _fcb {
	char	dc;
	char	name[8];
	char	ext[3];
	char	do_not_care1[2];
	uint	recsize;
	char	fsize[4];
	uint	date;
	uint	time;
	char	do_not_care2[9];
	char	randomrec[4];
}FCB;

typedef	char	int_t[5];



BOOL	_sense();	/* Sense CTRL/C */
void	kilbat();	/* terminate batch */
void	setfcb();	/* setup FCB, add default extension */
void	_setupfcb();	/* setup FCB */
int	atoi();		/* string to number */
int	memcmp();	/* compare memory */
int	strcmp();	/* compare strings */
char	toupper();	/* a -> A */
char	tolower();	/* A -> a */
uint	strlen();	/* length of string */
char	*strcpy();	/* copy string */
char	*strcat();	/* concatenate */
char	*memchr();	/* mem find char */
char	*strchr();	/* char find */
char	*strrchr();	/* char find */
void	*movmem();	/* move memory */
void	*memmov();	/* move memory */
void	*memcpy();	/* move memory */
void	*setmem();	/* fill memory */
void	*memset();	/* memset */
void	putdec();	/* print number */
void	putch();	/* print */
void	putc();		/* print */
void	puts();		/* print string */
void	*brk();		/* set free memory pointer */
void	*sbrk();	/*allocate mem*/

#define	malloc(a)	(sbrk(a))
#define	free(a)		(sbrk(0))

char	getch();	/* BIOS get char */
void	hexw();		/* word in hex */
void	hexb();		/* byte in hex */
char	bdos();		/* MSXDOS call */
uint	bdosh();	/* MSXDOS call */
uint	abs();		/* absolute value of int */
uint	time();		/* returns JIFFY */
void	_exit();	/* RST 0 */
void	exit();		/* exit */
void	atexit();	/* adds exit hook */

extern	char	*_argv;

#define	isalpha(c)	(isupper(c) || islower(c))
#define	isupper(c)	('A' <= (c) && (c) <= 'Z')
#define	islower(c)	('a' <= (c) && (c) <= 'z')
#define	isdigit(c)	('0' <= (c) && (c) <= '9')
#define	isspace(c)	((c) == ' ' || (c) == '\t' || (c) == '\n')

#define	poke(a,b)	*((BYTE *)(a))=b
#define	peek(a)		(*((BYTE *)(a)))
#define	pokew(a,b)	*((WORD *)(a))=b
#define	peekw(a)       	(*((WORD *)(a)))

#define	NULL	0
#define	ERROR	(-1)
#define	OK	0
#define	CPMEOF	((char)0x1a)
#define	QUIT_CH	((char)0x03)		/*	Control-C		*/

char	inp();		/* in from port */
void	outp();		/* out to port */
void	screen();	/* sets screen mode */
void	vpoke();	/* write VRAM */
char	vpeek();	/* read VRAM */
void	di();		/* DI */
void	ei();		/* EI */
void	vdp();		/* write VDP */
char	vdpstat();	/* read VDP */
void	sethook();	/* intercepts hook */
void	reshook();	/* restore hook */
void	nexthook();	/* call next hook */
