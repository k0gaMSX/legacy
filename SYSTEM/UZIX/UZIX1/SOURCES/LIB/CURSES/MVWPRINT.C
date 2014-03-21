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
/* Mvwprintw(win,fmt,args) moves the window 'win's cursor to	*/
/* A new position, then does a printf() in window 'win'.	*/
/****************************************************************/
int mvwprintw(WINDOW *win, int y, int x, char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  if (wmove(win, y, x) == ERR) return(ERR);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(win, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}				/* mvwprintw */
#else
/****************************************************************/
/* Mvwprintw(win,fmt,args) moves the window 'win's cursor to	*/
/* A new position, then does a printf() in window 'win'.	*/
/****************************************************************/
int mvwprintw(WINDOW *win, int y, int x, char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  if (wmove(win, y, x) == ERR) return(ERR);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(win, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}				/* mvwprintw */
#endif