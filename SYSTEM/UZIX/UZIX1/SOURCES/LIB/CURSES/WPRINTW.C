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
/* Wprintw(win,fmt,args) does a printf() in window 'win'.	*/
/****************************************************************/
int wprintw(WINDOW *win, char *fmt, ...)
{
  va_start(args, fmt);

  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(win, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}
#else
/****************************************************************/
/* Wprintw(win,fmt,args) does a printf() in window 'win'.	*/
/****************************************************************/
int wprintw(WINDOW *win, char *fmt, ...)
{
  va_list args;
  
  va_start(args, fmt);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(win, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}
#endif