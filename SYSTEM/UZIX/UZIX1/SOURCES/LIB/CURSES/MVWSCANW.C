#include <string.h>
#include <curses.h>
#include "curspriv.h"

#ifdef MSX
static char printscanbuf[128];	/* buffer used during I/O */
#else
static char printscanbuf[513];	/* buffer used during I/O */
#endif

/****************************************************************/
/* Mvwscanw(win,y,x,fmt,args) moves window 'win's cursor to a	*/
/* New position, then gets a string via 'win' and scans the	*/
/* String using format 'fmt' to extract the values and put them	*/
/* In the variables pointed to the arguments.			*/
/****************************************************************/
int mvwscanw(win, y, x, fmt, A1, A2, A3, A4, A5)
WINDOW *win;
int y;
int x;
char *fmt;
char *A1;
int A2, A3, A4, A5;	/* really pointers */
{
  if (wmove(win, y, x) == ERR) return(ERR);
  wrefresh(win);		/* set cursor */
  if (wgetstr(win, printscanbuf) == ERR)	/* get string */
	return(ERR);
  return(sscanf(printscanbuf, fmt, A1, A2, A3, A4, A5));
}				/* mvwscanw */
