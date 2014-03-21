#include <curses.h>
#include "curspriv.h"

/* Winsch() inserts character 'c' at the cursor position in
   window 'win'. The cursor is advanced.
*/

int winsch(_win, c)
WINDOW *_win;
char c;
{
  int *temp1;
  int *temp2;
  int *end;
  int x = _win->_curx;
  int y = _win->_cury;
  int maxx = _win->_maxx;

  if ((c < ' ') && (c == '\n' || c == '\r' || c == '\t' || c == '\b'))
	return(waddch(_win, c));
  end = &_win->_line[y][x];
  temp1 = &_win->_line[y][maxx];
  temp2 = temp1 - 1;
  if (c < ' ')			/* if CTRL-char make space for 2 */
	temp2--;
  while (temp1 > end) *temp1-- = *temp2--;
  _win->_maxchng[y] = maxx;
  if ((_win->_minchng[y] == _NO_CHANGE) || (_win->_minchng[y] > x))
	_win->_minchng[y] = x;
  return(waddch(_win, c));	/* fixes CTRL-chars too */
}				/* winsch */
