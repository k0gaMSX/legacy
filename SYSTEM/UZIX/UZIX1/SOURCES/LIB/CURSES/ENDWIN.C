#include <curses.h>
#include "curspriv.h"
#include <termcap.h>

int endwin()
{
  extern char *me;

  curs_set(1);
  poscur(LINES - 1, 0);
  refresh();
#if 0
  tputs(me, 1, outc);
#endif
  delwin(stdscr);
  delwin(curscr);
  delwin(_cursvar.tmpwin);
#if 0
  resetty();
#endif
  return(OK);
}
