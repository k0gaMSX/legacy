/*
**	CONIO.H
**	Low level console functions
**
**	(c) 1997, SOLID
*/


#ifndef	_C_TYPES_
#include <types.h>
#endif

int	getch	();
int	getche	();
int	putch	();
void	cputs	();

void	gotoxy	();
void	clrscr	();
void	home	();

char	kbhit();
void	putdec();

int	cprintf(.);
