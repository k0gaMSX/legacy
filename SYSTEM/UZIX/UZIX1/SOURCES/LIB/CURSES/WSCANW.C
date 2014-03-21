#include <string.h>
#include <curses.h>
#include "curspriv.h"

#ifdef MSX
static char printscanbuf[128];	/* buffer used during I/O */
#else
static char printscanbuf[513];	/* buffer used during I/O */
#endif

/****************************************************************/
/* Wscanw(win,fmt,args) gets a string via window 'win', then	*/
/* Scans the string using format 'fmt' to extract the values	*/
/* And put them in the variables pointed to the arguments.	*/
/****************************************************************/
int wscanw(win, fmt, A1, A2, A3, A4, A5)
WINDOW *win;
char *fmt;
char *A1;
int  A2, A3, A4, A5;	/* really pointers */
{
  wrefresh(win);		/* set cursor */
  if (wgetstr(win, printscanbuf) == ERR)	/* get string */
	return(ERR);
  return(sscanf(printscanbuf, fmt, A1, A2, A3, A4, A5));
}				/* wscanw */