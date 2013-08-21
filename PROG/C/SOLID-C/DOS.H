/*
**	dos.h
**	Definitions for dealing with MSXDOS
**
**	(C) 1995, SOLID
*/


#ifndef	_SIZE_T
#define	_SIZE_T
typedef	unsigned	size_t;
#endif

#ifndef	NULL
#define	NULL	0
#endif

/*	Variables:	*/
extern	int		_argc;
extern	char 	    * * _argv;
extern	char		_os_ver;



/*	DOS types:	*/
struct  WORDREGS
{  unsigned af, bc, de, hl, ix, iy;
};

struct  BYTEREGS
{  char  psw, a, c, b, e, d, l, h;
};

union  REGS
{  struct  WORDREGS x;
  struct  BYTEREGS h;
};


struct  time  {
  unsigned char  ti_min;	/* Minutes */
  unsigned char  ti_hour;	/* Hours */
  unsigned char  ti_hund;	/* Hundredths of seconds */
  unsigned char  ti_sec;	/* Seconds */
};

struct  date  {
  int    da_year;	/* Year */
  char    da_day;	/* Day of the month */
  char    da_mon;	/* Month (1 = Jan) */
};

#define	OPEN_MAX	16

char	bdos  		();	/* DOS call return status */
int 	bdosh		();	/* DOS call return int */
void	intdos  	();	/* DOS call, parameters and return as REGS */

void	callslt		();	/* call to any slot */

void	enable		();	/* enable interrupts	*/
void	disable		();	/* disable interrupts	*/

int	absread  	();	/* read sectors */
int	abswrite	();	/* write sectors */

int	getdisk 	();	/* get default drive */
void	getdate 	();  	/* get struct date */
void	gettime 	();	/* get struct time */
void	setdate 	();  	/* set system date */
int	setdisk 	();	/* set default disk */
void	setdta 		();	/* set DMA CPM 1Ah */
void	settime		();	/* set system time */
void	setverify	();	/* set RAW verify mode */
