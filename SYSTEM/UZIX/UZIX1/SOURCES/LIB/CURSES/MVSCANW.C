#include <string.h>
#include <curses.h>
#include "curspriv.h"

#ifdef MSX
static char printscanbuf[128];	/* buffer used during I/O */
#else
static char printscanbuf[513];	/* buffer used during I/O */
#endif

/****************************************************************/
/* Mvscanw(y,x,fmt,args) moves stdscr's cursor to a new posi-	*/
/* Tion, then gets a string via stdscr and scans the string	*/
/* Using format 'fmt' to extract the values and put them in the	*/
/* Variables pointed to the arguments.				*/
/****************************************************************/
int mvscanw(y, x, fmt, A1, A2, A3, A4, A5)
int y;
int x;
char *fmt;
char *A1;
int A2, A3, A4, A5;	/* really pointers */
{
  if (wmove(stdscr, y, x) == ERR) return(ERR);
  wrefresh(stdscr);		/* set cursor */
  if (wgetstr(stdscr, printscanbuf) == ERR)	/* get string */
	return(ERR);
  return(sscanf(printscanbuf, fmt, A1, A2, A3, A4, A5));
}				/* mvscanw */