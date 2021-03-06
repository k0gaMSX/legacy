/* Accelerated MSXDOS versions of the following console functions
 * (defined in conio.h):
 *
 * char     getch(void);
 * char     getche(void);
 * void     putch(int);
 * void     ungetch(int);
 * int	    kbhit(void);
 *
 * added new function:
 *
 * void     cursor(int);		[ 1 = on,  0 = off ]
 *
 * Use this file to update the Hitech-C standard library libc.lib. The
 * object file getch.obj is a manually optimized version, ready to
 * insert into libc.lib.
 *
 * PGN 10/93
 *
 */

#include	<cpm.h>

static short	pushback;

cursor(onoff)
uchar onoff;
{
	 (*(uchar *)0xfca9) = onoff;	    /* 0=off, else csr on */
	 (*(uchar *)0xfcaa) = onoff;	    /* cursor style=line  */
}


chget()
{
#asm
	psect	text
	push	ix
	push	iy
	ld	ix,09fh
	ld	iy,(0fcc0h)
	call	01ch
	ld	l,a
	ld	h,0
	pop	iy
	pop	ix
	jp	cret
#endasm
}


getch()
{
	short	c;

	if(c = pushback) {
		pushback = 0;
		return c;
	}
	return (c = (chget() & 0xFF));
}


/* get with echo */

getche()
{
	short	c;

	if(c = pushback) {
		pushback = 0;
		return c;
	}
	putch (c = (chget() & 0xFF));
	return (c);
}

ungetch(c)
unsigned char	c;
{
	pushback = c;
}

putch(c)
unsigned char	c;
{
#asm
	psect	text
	push	ix
	push	iy
	ld	a,(ix+6)
	ld	ix,0a2h
	ld	iy,(0fcc0h)
	call	01ch
	pop	iy
	pop	ix
	jp	cret
#endasm
}


kbhit()
{
#asm
	psect	text
	ld	hl,(0f3fah)	; getpnt
	ld	a,(0f3f8h)	; putpnt
	cp	l
	ld	hl,1
	jp	nz,cret 	; if NZ then keypressed
	ld	hl,0
	jp	cret
#endasm
}




                                                                                                                         