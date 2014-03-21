#include <string.h>
#include <curses.h>
#include "curspriv.h"

#ifdef MSX
static char printscanbuf[128];	/* buffer used during I/O */
#else
static char printscanbuf[513];	/* buffer used during I/O */
#endif

#ifdef _ANSI
/****************************************************************/
/* Printw(fmt,args) does a printf() in stdscr.			*/
/****************************************************************/
int printw(char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(stdscr, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}				/* printw */
#else
/****************************************************************/
/* Printw(fmt,args) does a printf() in stdscr.			*/
/****************************************************************/
int printw(char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(stdscr, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}				/* printw */
#endif