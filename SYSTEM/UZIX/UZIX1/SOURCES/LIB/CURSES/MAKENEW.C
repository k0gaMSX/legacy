/****************************************************************/
/* Makenew() allocates all data for a new window except the	*/
/* Actual lines themselves.					*/
/****************************************************************/

static WINDOW *makenew(num_lines, num_columns, begy, begx)
int num_lines, num_columns, begy, begx;
{
  int i;
  WINDOW *win;

  /* Allocate the window structure itself */
  if ((win = (WINDOW *) malloc(sizeof(WINDOW))) == NULL) 
	return((WINDOW *) ERR);

  /* Allocate the line pointer array */
  if ((win->_line = (int **) calloc(num_lines, sizeof(int *))) == NULL) {
	free(win);
	return((WINDOW *) ERR);
  }

  /* Allocate the minchng and maxchng arrays */
  if ((win->_minchng = (int *) calloc(num_lines, sizeof(int))) == NULL) {
	free(win);
	free(win->_line);
	return((WINDOW *) ERR);
  }
  if ((win->_maxchng = (int *) calloc(num_lines, sizeof(int))) == NULL) {
	free(win);
	free(win->_line);
	free(win->_minchng);
	return((WINDOW *) ERR);
  }

  /* Initialize window variables */
  win->_curx = 0;
  win->_cury = 0;
  win->_maxy = num_lines - 1;
  win->_maxx = num_columns - 1;
  win->_begy = begy;
  win->_begx = begx;
  win->_flags = 0;
  win->_attrs = ATR_NRM;
  win->_tabsize = 8;
  win->_clear = FALSE;
  win->_leave = FALSE;
  win->_scroll = FALSE;
  win->_nodelay = FALSE;
  win->_keypad = FALSE;
  win->_regtop = 0;
  win->_regbottom = num_lines - 1;

  /* Init to say window unchanged */
  for (i = 0; i < num_lines; i++) {
	win->_minchng[i] = 0;
	win->_maxchng[i] = num_columns - 1;
  }

  /* Set flags for window properties */
  if ((begy + num_lines) == LINES) {
	win->_flags |= _ENDLINE;
	if ((begx == 0) && (num_columns == COLS) && (begy == 0))
		win->_flags |= _FULLWIN;
  }				/* if */
  if (((begy + num_lines) == LINES) && ((begx + num_columns) == COLS))
	win->_flags |= _SCROLLWIN;
  return(win);
}