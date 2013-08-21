/*
**
**	setjmp.h
**	Nonlocal jump definition
**	(c) 1995, SOLID
*/

typedef	struct
{
	unsigned	j_sp;
	unsigned	j_iy;
	unsigned	j_pc;
}	jmp_buf;

int	setjmp	();		/* set nonlocal jump return point */
void	longjmp	();		/* do a nonlocal jump */

