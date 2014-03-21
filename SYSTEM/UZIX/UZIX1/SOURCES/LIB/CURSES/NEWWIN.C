#include <stdlib.h>
#include <malloc.h>
#include <curses.h>
#include "curspriv.h"

#include "makenew.c"

/****************************************************************/
/* Newwin() creates a new window with size num_lines * num_co-	*/
/* Lumns, and origin begx,begy relative to the SCREEN. Special	*/
/* Case: if num_lines and/or num_columns is 0, the remainder of	*/
/* The screen is used.						*/
/****************************************************************/
WINDOW *newwin(num_lines, num_columns, begy, begx)
int num_lines, num_columns, begy, begx;
{
  WINDOW *win;
  int *ptr;
  int i, j;

  if (num_lines == 0) num_lines = LINES - begy;
  if (num_columns == 0) num_columns = COLS - begx;
  if ((win = makenew(num_lines, num_columns, begy, begx)) == (WINDOW *) ERR)
	return((WINDOW *) ERR);
  for (i = 0; i < num_lines; i++) {	/* make and clear the lines */
	if ((win->_line[i] = (int *)calloc(num_columns, sizeof(int))) == NULL){
		for (j = 0; j < i; j++)	/* if error, free all the data */
			free(win->_line[j]);
		free(win->_minchng);
		free(win->_maxchng);
		free(win->_line);
		free(win);
		return((WINDOW *) ERR);
	} else {
		for (ptr = win->_line[i]; ptr < win->_line[i] + num_columns;)
			*ptr++ = ' ' | ATR_NRM;
	}
  }
  return(win);
}
