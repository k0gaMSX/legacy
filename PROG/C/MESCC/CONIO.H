#ifndef CONIO_H

#define CONIO_H

/*	conio.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Console I/O.

	Copyright (c) 1999-2007 Miguel I. Garcia Lopez

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2, or (at your option) any
	later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

	Revisions:

	22 Jan 2001 : Last revision.
	16 Apr 2007 : GPL'd.
	21 Apr 2007 : Changed puts to ANSI compatibility.
	15 May 2007 : Bug solved - added LF output to puts.

	Public:

	int getch(void)
	int getchar(void)
	int putchar(int ch)
	int puts(char *str)

	Notes:

	All output functions send LF as CR and LF.
*/

#asm
	;Input char from console.
	;Return value in A.
xci
	LD	C,6
	LD	E,255
	CALL	5
	OR	A
	JR	Z,xci
	RET

	;Output char to console.
	;Entry value in A.
	;If A=LF then output CR and LF.
xco
	CP	10
	JR	Z,xco3
	LD	E,A
xco2
	LD	C,2
	JP	5
xco3
	LD	E,13
	CALL	xco2
	LD	E,10
	JR	xco2

#endasm

/*	int getch(void)

	Wait for a char from console, and return
	ascii code without echo to console.
*/

#asm

getch
	CALL	xci
	LD	H,0
	LD	L,A
	RET
#endasm

/*	int getchar(void)

	Wait for a char from console, and return
	ascii code with echo to console.
*/

#asm

getchar
	CALL	getch

#endasm

/*	int putchar(int c)

	Output a char to console, and return ascii code.
*/

#asm

putchar
	PUSH	HL
	LD	A,L
	CALL	xco
	POP	HL
	RET

#endasm

/*	int puts(char *str)

	Output str + LF to console. Return non zero.
*/

#asm

puts
	LD	A,(HL)
	OR	A
	JR	Z,puts2
	PUSH	HL
	CALL	xco
	POP	HL
	INC	HL
	JR	puts
puts2
	LD	A,10
	CALL	xco
	LD	HL,1
	RET	

#endasm

#endif
