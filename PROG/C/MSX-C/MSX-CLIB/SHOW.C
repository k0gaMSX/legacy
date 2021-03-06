/*
	(C) Copyrighted by ASCII corp., 1988
		All rights Reserved.

		File:	show.c
*/
#pragma nonrec

#include <stdio.h>
#include <curses.h>

#define CTRLT   '\024'
#define RANGE   (TINY)5
#define HLINES  9
#define HCOLS   24

/*                           |--------+---------+   */
char *helpmes[HLINES] = {   "**Available commands**",
			    "------------------------",
			    "ESC   Show another file",
			    "SPACE Show next page",
			    "DOWN  Scroll up 5 lines",
			    "RET   Scroll up a line",
			    "Q/q   Quit",
			    "?/h   Display this",
			    "Hit any key to exit..."
			};
BOOL WFILE;

typedef struct {
	FILE     *fp;
	WINDOW   *win;
	char     *fn;
	unsigned ln;
	} FWIN;

STATUS help(curwin)
WINDOW *curwin;
{
    static WINDOW *hwin = NULL;
    int i;

    if((int)COLS < HCOLS + 2)
	return(ERROR);

    if(hwin == NULL)
	if((hwin = newwin(0, 0, (int)LINES - (HLINES + 2),
	   (int)COLS - (HCOLS + 2))) == NULL)
	    return(ERROR);

    werase(hwin);
    box(hwin, '|', '-');
    for(i = 1; i <= HLINES; i++)
	mvwprintw(hwin, i, 1, "%s", helpmes[i - 1]);
    wrefresh(hwin);

    while(!kbhit());
    wgetch(stdscr);
    overwrite(curwin, hwin);
    wrefresh(hwin);
    return(OK);
}

STATUS ins1(fp, win, buffer)
FILE    *fp;
WINDOW  *win;
char    *buffer;
{
    if(fgets(buffer, (int)COLS + 1, fp) != NULL) {
	scrollok(win, TRUE);
	scroll(win);
	scrollok(win, FALSE);
	wmove(win, (int)win->_maxy - 1, 0);
	waddstr(win, buffer);
	return(OK);
    } else
	return(ERROR);
}

STATUS *_1line(fp, win, buffer)
FILE    *fp;
WINDOW  *win;
char    *buffer;
{
    TINY y, x;

    if(fgets(buffer, (int)COLS + 1, fp) != NULL){
	waddstr(win, buffer);
	return(OK);
    } else
	return(ERROR);
}

TINY scrnful(fp, win, buffer, lin)
FILE    *fp;
WINDOW  *win;
char    *buffer;
TINY    lin;
{
    TINY i, j;

    for(i = 0 ; i < lin; i++) {
	if(_1line(fp, win, buffer) == ERROR)
	    break;
    }
    if(i != lin)
	wclrtobot(win);

    return(i);
}

VOID showwin(win, fn, ln, subw)
WINDOW *win, *subw;
char *fn;
unsigned ln;
{
    static WINDOW *lastwin = NULL;

    if(win != lastwin) {
	lastwin = win;
	touchwin(win);
	mvwprintw(subw, 0, 5, "%-12s", fn);
    }
    mvwprintw(subw, 0, 23, "%06u", ln);
    wrefresh(subw);
    wrefresh(win);
}

VOID excwin(fwin)
FWIN *fwin[];
{
    FWIN *save;

    save = fwin[0];
    fwin[0] = fwin[1];
    fwin[1] = save;
}

VOID    beep();         /* real function definition is in 'msxbios' */

VOID    _show(fwin, subw)
FWIN    *fwin[];
WINDOW  *subw;
{
    char *buffer, com;
    TINY i, num, numcpy, _lines;

    noecho();
    _lines = LINES - 1;

    if((buffer = alloc((unsigned)COLS + 1)) == NULL) {
	fprintf(stderr,"Not enough memory for internal buffer\n");
	return;
    }
    if(scrnful(fwin[0]->fp, fwin[0]->win, buffer, _lines) != _lines)
	fwin[0]->fp = NULL;

    if(WFILE) {
	if(scrnful(fwin[1]->fp, fwin[1]->win, buffer, _lines) != _lines)
	    fwin[1]->fp = NULL;
    }

    waddstr(subw, "File:");
    mvwaddstr(subw, 0, 18, "Line:");
    fwin[1]->ln = fwin[0]->ln = 1;
    showwin(fwin[0]->win, fwin[0]->fn, fwin[0]->ln, subw);

    while(1) {
	num = RANGE;
	com = wgetch(stdscr);
	switch(com) {
	    case '?':
	    case 'h':
	    case 'H':
		if(help(fwin[0]->win) == ERROR)
		    beep();

		break;
	    case ESC:
		if(WFILE) {
		    excwin(fwin);
		    showwin(fwin[0]->win, fwin[0]->fn, fwin[0]->ln, subw);
		}
		break;
	    case SPACE:
		wmove(fwin[0]->win, 0, 0);
		if(fwin[0]->fp != NULL) {
		    if((i = scrnful(fwin[0]->fp, fwin[0]->win,
			buffer, _lines)) != _lines) {
			fwin[0]->fp = NULL;
		    }
		} else {
		    beep();
		    break;
		}
		fwin[0]->ln += (unsigned)i;
		showwin(fwin[0]->win, fwin[0]->fn, fwin[0]->ln, subw);
		break;
	    case LF:
		num = 1;
	    case CTRLT:
	    case DOWN:
		numcpy = num;
		if(fwin[0]->fp != NULL) {
		    for(numcpy = num;
			numcpy && ins1(fwin[0]->fp, fwin[0]->win, buffer) == OK;
			numcpy--);
		    if(numcpy)
			fwin[0]->fp = NULL;
		} else {
		    beep();
		    break;
		}
		fwin[0]->ln += (unsigned)num - (unsigned)numcpy;
		showwin(fwin[0]->win, fwin[0]->fn, fwin[0]->ln, subw);
		break;
	    case 'Q':
	    case 'q':
		return;
	    default:
		;
	}
    }
} /*end of _show*/


main(argc, argv)
int     argc;
char    **argv;
{
    FWIN *fwin[2];
    FWIN fw, fw1;
    WINDOW *subw;

    WFILE = FALSE;

    if(argc < 2 || argc > 3) {              /* 2 file names can be specified */
	fprintf(stderr,"Bad argument.\n");
	exit(1);
    }

    if((fw.fp = fopen(argv[1], "r")) == NULL) {
	fprintf(stderr,"%s: File not found.\n", argv[1]);
	exit(1);
    }

    if(initscr() == NULL) {
	fprintf(stderr,"Not enough memory for CURSES system.\n");
	exit(1);
    }

    if((fw.win = newwin((int)LINES - 1, 0, 1, 0)) == NULL) {
	fprintf(stderr,"Not enough memory for WINDOW.\n");
	exit(1);
    }

    fw.fn = argv[1];

    if(argc == 3) {
	if((fw1.fp = fopen(argv[2], "r")) == NULL) {
	    fprintf(stderr, "%s: File not found.\n", argv[2]);
	    exit(1);
	}
	if((fw1.win = newwin((int)LINES - 1, 0, 1, 0)) == NULL) {
	    fprintf(stderr, "Not enough memory for WINDOW.\n");
	    exit(1);
	}
	fw1.fn = argv[2];
	WFILE = TRUE;
    }

    if((subw = newwin(1, 0, 0, 0)) == NULL) {
	fprintf(stderr, "Not enough memory for WINDOW.\n");
	exit(1);
    }

    fwin[0] = &fw;
    fwin[1] = &fw1;
    _show((FWIN *)fwin, subw);         /* Main program routine */
    delwin(fw.win);                    /* Close windows */
    if(WFILE)
	delwin(fw1.win);
    delwin(subw);
    endwin();
    exit(0);
}
                                                                                                            