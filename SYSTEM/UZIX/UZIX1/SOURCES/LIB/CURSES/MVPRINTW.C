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
/* Mvprintw(fmt,args) moves the stdscr cursor to a new posi-	*/
/* Tion, then does a printf() in stdscr.			*/
/****************************************************************/
int mvprintw(int y, int x, char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  if (wmove(stdscr, y, x) == ERR) return(ERR);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(stdscr, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}
#else
/****************************************************************/
/* Mvprintw(fmt,args) moves the stdscr cursor to a new posi-	*/
/* Tion, then does a printf() in stdscr.			*/
/****************************************************************/
int mvprintw(int y, int x, char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  if (wmove(stdscr, y, x) == ERR) return(ERR);
  vsprintf(printscanbuf, fmt, &args);
  if (waddstr(stdscr, printscanbuf) == ERR) return(ERR);
  return(strlen(printscanbuf));
}
#endif