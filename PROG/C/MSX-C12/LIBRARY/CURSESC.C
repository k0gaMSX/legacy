/*
	(C) Copyrighted by ASCII corp., 1988
		All rights Reserved.

		File:	cursesc.c
*/
/*  Bug detected on Fri. JAN-22th   fixed */
/*               on Man. JAN-25th   fixed */

#pragma nonrec
#define EXTERN

#include    <stdio.h>
#include    <curses.h>

WINDOW *_mknew(lines, cols, begin_y, begin_x)
int     lines, cols, begin_y, begin_x;
{
    WINDOW  *win;
    INDEXLIN *index;
    int     i;

    if((win = (WINDOW *)alloc(sizeof(WINDOW))) == NULL)
	return(NULL);

    if((index = (INDEXLIN *)alloc(sizeof(INDEXLIN) * (lines + 1))) == NULL) {
	free((char *)win);
	return(NULL);
    }

    win->_flags = 0;

    if(begin_x + cols == (int)COLS) {
	win->_flags |= _ENDLINES;
	if(begin_x == 0 && lines == (int)LINES && begin_y == 0)
	    win->_flags |= _FULLWIN;
	if(begin_y + lines == (int)LINES)
	    win->_flags |= _SCROLLWIN;
    }

    index->_ins_del = 1;
    win->_index =  (++index);

    for(i = 0; i < lines; i++, index++) {
	index->_ins_del = 1;
	index->_firstch = index->_lastch = _NOCHANGE;
    }

    win->_maxy = (TINY)lines;
    win->_maxx = (TINY)cols;
    win->_cury = win->_curx = (TINY)0;
    win->_begy = begin_y;
    win->_begx = begin_x;
    win->_scroll = win->_leave = FALSE;
    win->_clear = ((lines == (int)LINES) && (cols == (int)COLS));

    return(win);
}

WINDOW *newwin(lines, cols, begin_y, begin_x)
int     lines, cols, begin_y, begin_x;
{

    WINDOW  *win;
    INDEXLIN *index;
    char    *wbuf, *p;
    int     i, j;

    if(lines < 0 || lines > (int)LINES || cols < 0 || cols > (int)COLS)
	return(NULL);
    if(lines == 0)
	lines = (int)LINES - begin_y;
    if(cols == 0)
	cols = (int)COLS - begin_x;

    if((win = _mknew(lines, cols, begin_y, begin_x)) == NULL)
	return(NULL);

    if((wbuf = alloc(lines * cols)) == NULL) {
	free((char *)win);
	free((char *)index);
	return(NULL);
    }

    index = win->_index;

    for(i = 0; i < lines; i++, index++) {
	index->_y = wbuf;
	for(j = 0; j <  cols; j++)
	    *wbuf++ = SPACE;
    }
    return(win);
}

STATUS touchwin(win)
WINDOW *win;
{
    TINY y, maxx, maxy;
    INDEXLIN *index;

    index = win->_index;
    maxx = win->_maxx - 1;
    maxy = win->_maxy;

    index[-1]._ins_del = 1;
    for(y = 0 ; y < maxy; y++, index++) {
	index[0]._ins_del = 1;
	index[0]._firstch = 0;
	index[0]._lastch = maxx;
    }
    return(OK);
}

STATUS mvwin(win, y, x)
WINDOW  *win;
int     y, x;
{
#ifdef BUG1_22
    if(win->_maxy + y > LINES || win->_maxx + x > COLS)
#else
    if((int)win->_maxy + y > (int)LINES || (int)win->_maxx + x > (int)COLS
	|| y < 0 || x < 0)
#endif
	return(ERROR);

    win->_begy = y;
    win->_begx = x;
    touchwin(win);
    return(OK);
}

VOID delwin(win)
WINDOW *win;
{
    if(!(win->_flags & _SUBWIN))
	free(win->_index[0]._y);

    free((char *)&(win->_index[-1]));
    free((char *)win);
}

VOID endwin()
{
    delwin(curscr);
    delwin(stdscr);
}

WINDOW *initscr()
{
    COLS = *LINLEN;
    LINES = *CRTCNT + *CNFDFG;

    raw();
    echo();

    if((curscr = newwin((int)LINES, (int)COLS, 0, 0)) == NULL)
	return(NULL);

    return(stdscr = newwin((int)LINES, (int)COLS, 0, 0));
}

WINDOW *subwin(win, lines, cols, begin_y, begin_x)
WINDOW  *win;
int     lines, cols, begin_y, begin_x;
{
    WINDOW *nwin;
    int i, offx, offy;
    INDEXLIN *index, *nindex;
    char    *ly;

#ifdef BUG1_22
    offy =  ((TINY)begin_y - (TINY)win->_begy);
    offx = ((TINY)begin_x - (TINY)win->_begx);
#else
    offy =  begin_y - win->_begy;
    offx =  begin_x - win->_begx;
#endif

    if(offy < 0 || offx < 0
      || lines > (int)win->_maxy - offy || cols > (int)win->_maxx - offx)
       return(NULL);

    if(lines == 0)
	lines = (int)win->_maxy - offy;

    if(cols == 0)
	cols = (int)win->_maxx - offx;

    if((nwin = _mknew(lines, cols, begin_y, begin_x)) == NULL)
	return(NULL);

    nwin->_flags |= _SUBWIN;

    for(index = win->_index + offy, nindex = nwin->_index, i = 0;
	i < lines; i++ , index++, nindex++)
	 nindex->_y = index->_y + offx;

    return(nwin);
}

/* Move logical cursor on stdscr */
STATUS wmove(win, y, x)
WINDOW  *win;
int     y, x;
{
    if(x >= (int)win->_maxx || y >= (int)win->_maxy || x < 0 || y < 0)
	return(ERROR);

    win->_curx = (TINY)x;
    win->_cury = (TINY)y;

    return(OK);
}

STATUS move(y, x)
int y, x;
{
    return(wmove(stdscr, y, x));
}

VOID _clrlin(str, start, cols)  /* Fill a line with SAPCE */
char *str;
TINY start, cols;
{
    str += start;
    while(start < cols) {
	*str++ = SPACE;
	start++;
    }
}

VOID werase(win)
WINDOW *win;
{
    TINY cy, cx;
    INDEXLIN *idp;

    for(idp = win->_index, cy = 0; cy < win->_maxy; cy++, idp++) {
	_clrlin(idp[0]._y, (TINY)0, win->_maxx);
	idp[0]._firstch = 0;
	idp[0]._lastch =  (int)win->_maxx - 1;
    }
    win->_curx = win->_cury = (TINY)0;
}

VOID erase()
{
    werase(stdscr);
}


/* copy a memory block to another */
VOID        memmove(d, s, n)
char        *d;
char        *s;
unsigned    n;
{
    if (d <= s)
	while (n) {
	    *d++ = *s++;
	    n--;
	}
    else {
	d += n;
	s += n;
	while (n) {
	    *--d = *--s;
	    n--;
	}
    }
}

VOID _rotate(win, ins_del)
WINDOW  *win;
BOOL    ins_del;
{

    INDEXLIN *index, saver;
    TINY     counter, i, cury, lines;
    BOOL     nocur, idf;

    nocur = (win != curscr);
    cury = win->_cury;
    index = win->_index;
    lines = win->_maxy;
    idf = FALSE;

    if(ins_del == INSERT) {      /*Case of Insert*/
	memmove((char *)&saver, (char *)(index + lines - 1),
		sizeof(INDEXLIN));
	if(index[(int)cury - 1]._ins_del > 1){
	    (index[(int)cury - 1]._ins_del)--;
	    saver._ins_del = 1;
	    saver._firstch = 0;
	    saver._lastch = win->_maxx - 1;
	    idf = TRUE;
	} else
	    saver._ins_del = 0;

	memmove((char *)(index + cury + 1), (char *)(index + cury),
		sizeof(INDEXLIN) * ((unsigned)lines - 1 - (unsigned)cury));

    }else {                     /* Case of delete */
	memmove((char *)&saver, (char *)(index + cury),
		sizeof(INDEXLIN));

	(index[(int)cury - 1]._ins_del) += saver._ins_del;
	saver._ins_del = 0;
	/*Shift memory*/
	memmove((char *)(index + cury), (char *)(index + cury + 1),
		sizeof(INDEXLIN) * ((unsigned)lines - 1 - (unsigned)cury));
    }

    if(win->_maxx == COLS) {
	if(idf == FALSE)
	    saver._firstch = _NOCHANGE;
    } else {
	saver._firstch = 0;
	saver._lastch = win->_maxx - 1;
    }

    _clrlin(saver._y, (TINY)0, win->_maxx);     /* Clear line */

    if(ins_del == INSERT)
	memmove((char *)(index + cury), (char *)&saver,
		sizeof(INDEXLIN));
    else
	memmove((char *)(index + lines - 1), (char *)&saver,
		sizeof(INDEXLIN));

}


STATUS scroll(win)
WINDOW *win;
{
    TINY cy, cx;
    cx = win->_curx;
    cy = win->_cury;

    if(!win->_scroll)
	return(ERROR);

    wmove(win, 0, 0);

    _rotate(win, (BOOL)DELETE);
    wmove(win, (int)cy, (int)cx);
}


VOID wclreol(win)
WINDOW  *win;
{
    TINY    cx, cy, maxx;
    INDEXLIN  *idp;

    cx = win->_curx;
    maxx =  win->_maxx;

    idp = win->_index + win->_cury;
    _clrlin(idp[0]._y, cx, maxx);

    if(idp[0]._firstch > cx || idp[0]._firstch == _NOCHANGE)
	idp[0]._firstch = cx;

    idp[0]._lastch =  maxx - 1;
}

VOID clrtoeol()
{
    wclreol(stdscr);
}

VOID wclrbot(win)
WINDOW *win;
{
    TINY    cx, cy, maxx;
    INDEXLIN *idp;


    cx = win->_curx;
    cy = win->_cury;

    maxx =  win->_maxx;

    idp = win->_index + cy;
    _clrlin(idp[0]._y, cx, maxx);
    if(idp[0]._firstch > (int)cx || idp[0]._firstch == _NOCHANGE)
	idp[0]._firstch = cx;

    idp[0]._lastch =  (int)maxx - 1;

    for(cy++, idp++; cy < win->_maxy; idp++, cy++) {
	_clrlin(idp[0]._y, (TINY)0, maxx);
	idp[0]._firstch = 0;
	idp[0]._lastch =  (int)maxx - 1;
    }
}

VOID clrtobot()
{
    wclrbot(stdscr);
}

STATUS _waddch(win, ch)
WINDOW *win;
char ch;
{
    TINY    cx, cy, maxx, maxy;
    int     *firstch, *lastch;
    int     fc, lc;
    INDEXLIN *index;
    char    tempc;
    cx = win->_curx;
    cy = win->_cury;

    maxx = win->_maxx;
    maxy = win->_maxy;

    if(cx >= maxx || cy >= maxy || cx < 0 || cy < 0)
	return(ERR);

    index = (INDEXLIN *)(win->_index + cy);
    firstch = (int *)&(index->_firstch);
    lastch = (int *)&(index->_lastch);

    if((tempc = index->_y[cx] ) != ch) {
	if(*firstch == _NOCHANGE)
	    *firstch = *lastch = (int)cx;
	else if((int)cx < *firstch)
	    *firstch = (int)cx;
	else if((int)cx > *lastch)
	    *lastch = (int)cx;
    }
    index->_y[cx] = ch;
    if(++cx >= maxx) {
	cx = (TINY)0;
	if(++cy >= maxy) {
	    if(win->_scroll) {
		scroll(win);
		--cy;
	    } else {
		index->_y[maxx - 1] = SPACE;
		if(*lastch == *firstch)
		    *firstch = _NOCHANGE;
		else if(ch != tempc)
		    (*lastch)--;
		return(ERROR);
	    }
	}
    }

    win->_curx = cx;
    win->_cury = cy;
    return(OK);
}

STATUS  waddch(win, ch)
WINDOW  *win;
char    ch;
{
    TINY i, cx, cy;

    cx = win->_curx;
    cy = win->_cury;

    switch(ch) {
	case TAB:
	    i = TABS - (cx % TABS) + cx;

	    if(i > win->_maxx - 1)

#ifdef BUG1_25
		i = win->_maxx - 1;
	    for(; cx <= i; cx++) {
#else
		i = win->_maxx;
	    for(; cx < i; cx++) {
#endif
		if(_waddch(win, SPACE) == ERROR)
		    return(ERROR);
	    }
	    break;

	case CR:
	    win->_curx = 0;
	    break;

	case LF:
	    wclreol(win);
/*
	    if(NL)
		win->_curx = 0;
 */
	    if(++cy >= win->_maxy) {
		if(win->_scroll) {
		    cy--;
		    scroll(win);
		} else
		    return(ERROR);
	    } else
		(win->_cury)++;
	    win->_curx = (TINY)0;
	    win->_cury = cy;
	    break;

	default:
	    if(iscntrl(ch)) {
		if(_waddch(win,'^') == ERR)
		    return(ERR);
		if(ch == DEL)
		    ch = '?';
		else
		    ch = ch + '\100';
	    }
	    return(_waddch(win,ch));
    }
    return(OK);
}

STATUS addch(ch)
char ch;
{
    return(waddch(stdscr, ch));
}

STATUS waddstr(win, str)
WINDOW *win;
char *str;
{
    while(*str != '\0') {
	if(waddch(win, *str++) == ERROR)
	    return(ERROR);
    }

    return(OK);
}

STATUS addstr(str)
char *str;
{
    return(waddstr(stdscr, str));
}

STATUS wdelch(win)
WINDOW *win;
{
    TINY maxx, curx, cury;
    INDEXLIN *idp;
    char *cp, *sp, *ep;
    int *firstch;

    cury = win->_cury;
    curx = win->_curx;
    idp = win->_index + cury;

    firstch = &(idp[0]._firstch);

    maxx = win->_maxx;
    ep = idp[0]._y + (maxx - 1);
    sp = idp[0]._y + curx + 1;
    cp = sp - 1;
    while(cp < ep)
	*cp++ = *sp++;

    *cp = SPACE;

    idp[0]._lastch = maxx - 1;
    if(*firstch == _NOCHANGE || *firstch > curx)
	*firstch = curx;
    return(OK);
}

STATUS delch()
{
    return(wdelch(stdscr));
}

/* Insert a charcter */
STATUS winsch(win, ch)
WINDOW *win;
char ch;
{
    char *cp, *ep, *sp;
    TINY x, maxy, maxx, curx;
    int *firstch;
    INDEXLIN *idp;

    maxy = win->_maxy;
    maxx = win->_maxx;
    curx = win->_curx;

    idp = win->_index + win->_cury;

    firstch = &(idp[0]._firstch);

    sp = idp[0]._y + curx;
    cp = idp[0]._y + maxx - 1;
    ep = cp - 1;

    while ( cp > sp)
	*cp-- = *ep--;
    *cp = ch;

    idp[0]._lastch = maxx - 1;
    if(*firstch == _NOCHANGE || *firstch > curx)
	*firstch = curx;

    if(win->_cury == maxy - 1  && idp[0]._y[maxx - 1] != SPACE) {
	if (win->_scroll) {
	    scroll(win);
	    win->_cury--;
	} else {
	    idp[0]._y[maxx - 1] = SPACE;
	    return(ERROR);
	}
    }
    return(OK);
}

STATUS insch(ch)
char ch;
{
    return(winsch(stdscr, ch));
}


STATUS box(win, vert, hor)
WINDOW *win;
char vert, hor;
{
    char *top, *bot, *tp, *bp;
    INDEXLIN *index;
    TINY x, y, i;

    x = win->_maxx - 1;
    y = win->_maxy;

    index = win->_index;
    tp = top = (index[0])._y;
    bp = bot = (index[y - 1])._y;

    for(tp++, bp++, i = 1; i < x; i++)
	*tp++ = *bp++ = hor;

    for(i = 0; i < y; i++, index++)
	index[0]._y[0] = index[0]._y[x] = vert;

    if(!win->_scroll && (win->_flags & _SCROLLWIN))
	top[0] = top[x] = bot[0] = bot[x] = SPACE;

    return(touchwin(win));
}


VOID wdeleteln(win)
WINDOW *win;
{
     _rotate(win, (BOOL)DELETE);
}

VOID deleteln()
{
    _rotate(stdscr, (BOOL)DELETE);
}

VOID winsertln(win)
WINDOW  *win;
{
     _rotate(win, (BOOL)INSERT);
}

VOID insertln()
{
     _rotate(stdscr, (BOOL)INSERT);
}

VOID overwrite(win1, win2)
WINDOW  *win1, *win2;
{
    int cx, cy, offy, maxx, maxy, dify, difx;
    INDEXLIN *index;
    char *ch;

    maxy = (win1->_maxy > win2->_maxy)? (int)win1->_maxy: (int)win2->_maxy;
    maxx = (win1->_maxx > win2->_maxx)? (int)win1->_maxx: (int)win2->_maxx;
    dify = win1->_begy - win2->_begy;
    difx = win1->_begx - win2->_begx;

    index = win1->_index;

    for(cy = 0; cy < maxy; cy++, index++) {
	offy = cy + dify;
	if(wmove(win2, offy, 0) != ERROR) {
	    for(cx = 0; cx < maxx; cx++) {
		if(wmove(win2, offy, cx + difx) != ERROR) {
		    if(waddch(win2, index[0]._y[cx]) == ERROR)
			break;
		}
	    }
	}
    }
}

VOID _deleteln(num)
int num;
{
    while(num--){
	putch(ESC);
	putch('M');
	_rotate(curscr, DELETE);
    }
}

VOID _insertln(num)
int num;
{
    while(num--){
	putch(ESC);
	putch('L');
	_rotate(curscr, INSERT);
    }
}

VOID _move(y, x)
TINY y, x;
{
    wmove(curscr, (int)y, (int)x);
    putch(ESC);
    putch('Y');
    putch(y + SPACE);
    putch(x + SPACE);
}

VOID _clrtobot()    /* Clear to bottom of screen. */
{
    wclrbot(curscr);
    putch(ESC);
    putch('J');
}

VOID _harddel(win)
WINDOW *win;
{
    TINY y, cy, cntr, lines;
    INDEXLIN *idp, *s_index;
    int  insdel;
    TINY begy;
    int  flag;

    lines = win->_maxy;
    begy = (TINY)win->_begy;
    flag = win->_flags;
    s_index = win->_index;

    /* Pass1: scanning "insdel" to find deleted lines, and delete them. */
    /* by escape sequence. */
    for(cntr = 0, idp = s_index, y = 0 ; y < lines; y++, idp++) {

	if((insdel = idp[-1]._ins_del)  > 0) {
	    if(insdel > 1) {
		if(--insdel > lines)
		    insdel = lines;
		cy = curscr->_cury = cntr + begy;
		_move(cy, (TINY)0);
		_deleteln(insdel);

		if(!(flag & _SCROLLWIN)) {
		    curscr->_cury = cy = lines + begy - insdel;
		    _move(cy, 0);
		    _insertln(insdel);
		}

		idp[-1]._ins_del = 1;
	    }
	    cntr++;
	}
    }
}

VOID _touchl(index, y, maxy, maxx)
INDEXLIN *index;
TINY y, maxy, maxx;
{
    for(;y <= maxy; index++, y++) {
	index[0]._ins_del = 1;
	index[0]._firstch = 0;
	index[0]._lastch = maxx;
    }
}

VOID _hardins(win)
WINDOW *win;
{
    TINY y,  howmany, lines;
    INDEXLIN *idp, *s_index;
    TINY begy, begx, cury, curx;
    int  flag, insdel;

    cury = win->_cury;
    curx = win->_curx;

    lines = win->_maxy;
    begy = (TINY)win->_begy;
    begx = (TINY)win->_begx;
    flag = win->_flags;
    s_index = win->_index;

    for(y = howmany = (TINY)0, idp = s_index; y < lines; y++, idp++) {
	if(!(insdel = idp[0]._ins_del)) {
	    howmany++;
	    idp[0]._ins_del = 1;
	} else if(howmany) {
	    if(howmany > lines)
		howmany = lines;

	    if(!(flag & _SCROLLWIN)) {
		curscr->_cury = begy + lines - howmany;
		_move(curscr->_cury, 0);
		_deleteln((int)howmany);
	    }
	    curscr->_cury = y - howmany +begy;
	    _move(curscr->_cury, (TINY)0);
	    _insertln((int)howmany);
	    howmany = 0;
	}
    }
    if(howmany)
	win->_index[lines - howmany]._ins_del = 0;

#ifdef DEBUG
    if(howmany) {
	y = lines - howmany;
	_touchl(win->_index + y, y, lines - (TINY)1, win->_maxx - (TINY)1);
/*
	if(flag & _SCROLLWIN) {
	    _move(LINES - howmany, 0);
	    _clrtobot();
	} else {
	    wmove(win, (int)lines - (int)howmany, 0);
	    wclrtobot(win);
	    wmove(win, cury, curx);
	}
*/
    }
#endif
}

VOID _putcc(count, y, x, begy, begx, stdy)
TINY *count, y, x, begy, begx;
char **stdy;
{
    if(*count >= 4) {/*Which is more efficient moving cursor*/
		   /*or put as many blanks as count.*/
		   /*"_move" calls "putch" 4 times*/
	_move(y + begy, x + begx);
	*count = 0;
    }else {
	*stdy -= *count;
	while(*count){
	    putch(*(*stdy)++);
	    (*count)--;
	}
    }
}


VOID _refine(idpc, idps, begy, begx, y)
INDEXLIN *idpc, *idps;
TINY begy, begx, y;
{
    int firstch, lastch, x;
    char *stdy, *cury;
    TINY count;

    count = 0;
    firstch = idps[0]._firstch;
    lastch = idps[0]._lastch;

    for(stdy = (idps[0]._y + firstch) ,
	cury = (idpc[0]._y + firstch + begx),
	x = firstch; x <= lastch;
	stdy++, cury++, x++) { /*Start of nested loop*/

	if(*stdy != *cury) {
	    *cury = *stdy;
	    if(count)
		_putcc(&count, y, x, begy, begx, &stdy);

	    putch(*stdy);
	} else
	    count++;        /*Logical cursor moved.*/
    } /*End of nested loop*/
}

VOID _cputs(str, num)
char *str;
int num;
{
    char ch, *_str;
    TINY cnt;
    for(cnt = 0;(ch = *str++) && num--;) {
	if(ch == SPACE)
	    cnt++;
	else{
	    while(cnt){
		putch(SPACE);
		cnt--;
	    }
	    putch(ch);
	}
    }
    if(cnt) {
	putch(ESC);
	putch('K');
    }
}

/* Internal routine to implement refresh() */
VOID _wrefresh(win)
WINDOW *win;
{
    TINY     y, begy, begx, lines;
    INDEXLIN *idps, *idpc;
    int firstch;

    lines = win->_maxy;
    begy = (TINY)win->_begy;
    begx = (TINY)win->_begx;

    /*Normal refreshing*/
    for(idps = win->_index, idpc = curscr->_index + begy, y = 0;
	y < lines; y++, idps++, idpc++) {

	if(idps[0]._firstch != _NOCHANGE) {
	    _move(y + begy, (TINY)idps[0]._firstch + begx);

	    if((idps[0]._firstch == 0) &&
	      (idps[0]._lastch == (int)win->_maxx - 1) &&
	      (win->_flags & _ENDLINES)) {
		_cputs(idps[0]._y, (int)win->_maxx);
		memmove(idpc[0]._y + begx, idps[0]._y, (unsigned)win->_maxx);
	    } else
		_refine(idpc, idps, begy, begx, y);

	    idps[0]._lastch = idps[0]._firstch = _NOCHANGE;
	}
    } /*End of large loop*/
}


VOID offcur()       /*Cursor off*/
{
    putch(ESC);
    putch('x');
    putch('5');
}

VOID oncur()        /* Cursor on */
{
    putch(ESC);
    putch('y');
    putch('5');
}

VOID _tclin(win)
WINDOW *win;
{
    INDEXLIN *index;
    TINY y, maxy;

    maxy = win->_maxy;
    index = win->_index - 1;
    for(y = 0; y <= maxy; y++, index++) {
	if(index[0]._ins_del != 1) {
	    _touchl(index, y, maxy, win->_maxx - 1);
	    break;
	}
    }
}

STATUS wrefresh(win)      /* Refresh screen */
WINDOW *win;
{
#ifdef DEBUG
    static  WINDOW *lastw = NULL;
    TINY begy, begx;
#endif
    BOOL curwin;

#ifdef DEBUG
    begy = (TINY)win->_begy;
    begx = (TINY)win->_begx;
#endif
    curwin = (BOOL)(win == curscr);
    offcur();

    if(win->_clear || curscr->_clear || curwin) {
	if((win->_flags & _FULLWIN) || curscr->_clear) {
	    putch(FF);
	    werase(curscr);
	    curscr->_cury = (TINY)0;
	    curscr->_curx = (TINY)0;
	    curscr->_clear = FALSE;
	}
	win->_clear = FALSE;

    }
#ifdef DEBUG
    if(win != lastw) {
	lastw = win;
	touchwin(win);
    } else if(win->_maxx == COLS) {
#else
    if(win->_maxx == COLS) {
#endif
	_harddel(win);    /* Hardware scroll */
	_hardins(win);
#ifdef DEBUG
    } else
#else
    }
#endif
	_tclin(win);
    _wrefresh(win);

#ifdef DEBUG
    curscr->_cury = win->_cury + begy;
    curscr->_curx = win->_curx + begx;
    _move(curscr->_cury, curscr->_curx);
#else
    _move(win->_cury + (TINY)win->_begy, win->_curx + (TINY)win->_begx);
#endif
    oncur();
    return(OK);
}

STATUS  refresh()
{
    return(wrefresh(stdscr));
}
                             