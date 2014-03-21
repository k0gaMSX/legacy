#include <string.h>
#include <curses.h>
#include "curspriv.h"

#ifdef MSX
static char printscanbuf[128];	/* buffer used during I/O */
#else
static char printscanbuf[513];	/* buffer used during I/O */
#endif

/****************************************************************/
/* Scanw(fmt,args) gets a string via stdscr, then scans the	*/
/* String using format 'fmt' to extract the values and put them	*/
/* In the variables pointed to the arguments.			*/
/****************************************************************/
int scanw(fmt, A1, A2, A3, A4, A5)
char *fmt;
char *A1;
int A2, A3, A4, A5;	/* really pointers */
{
  wrefresh(stdscr);		/* set cursor */
  if (wgetstr(stdscr, printscanbuf) == ERR)	/* get string */
	return(ERR);
  return(sscanf(printscanbuf, fmt, A1, A2, A3, A4, A5));
}				/* scanw */