#include <stdlib.h>
#include <curses.h>
#include "curspriv.h"

#include "makenew.c"

/****************************************************************/
/* Subwin() creates a sub-window in the 'orig' window, with	*/
/* Size num_lines * num_columns, and with origin begx, begy	*/
/* Relative to the SCREEN. Special case: if num_lines and/or	*/
/* Num_columns is 0, the remainder of the original window is	*/
/* Used. The subwindow uses the original window's line buffers	*/
/* To store it's own lines.					*/
/****************************************************************/
WINDOW *subwin(orig, num_lines, num_columns, begy, begx)
WINDOW *orig;
int num_lines, num_columns, begy, begx;
{
  WINDOW *win;
  int i, j, k;

  /* Make sure window fits inside the original one */
  if (begy < orig->_begy || begx < orig->_begx ||
		      (begy + num_lines) > (orig->_begy + orig->_maxy) ||
		      (begx + num_columns) > (orig->_begx + orig->_maxx) )
	return((WINDOW *) ERR);

  if (num_lines == 0) num_lines = orig->_maxy - (begy - orig->_begy);
  if (num_columns == 0) num_columns = orig->_maxx - (begx - orig->_begx);
  if ((win = makenew(num_lines, num_columns, begy, begx)) == (WINDOW *) ERR)
	return((WINDOW *) ERR);

  /* Set line pointers the same as in the original window */
  j = begy - orig->_begy;
  k = begx - orig->_begx;
  for (i = 0; i < num_lines; i++) win->_line[i] = (orig->_line[j++]) + k;
  win->_flags |= _SUBWIN;
  return(win);
}
