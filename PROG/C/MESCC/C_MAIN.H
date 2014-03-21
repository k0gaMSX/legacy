/*	c_main.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Main header.

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

	17 Jan 2001 : Last revision.
	16 Apr 2007 : GPL'd.
*/

#ifndef C_MAIN_H

#define C_MAIN_H

/*	WHAT COMPILER WILL USE YOU TO COMPILE Small C ?

	You can define:	CC_SMALLC	Small C
			CC_TURBOC	Turbo C
			CC_PCC		PCC - Personal C Compiler
*/

#define CC_SMALLC

/*	DEFINITIONS FOR EACH COMPILER

	You must define the folowing:

	NULL		Null value.
	TRUE		True value.
	FALSE		False value.

	FILE		For file i/o functions.
	EOF		End of file/error value for file i/o functions.

	C_ICRLF		If fgetc need CR/LF translation.
	C_OCRLF		If fputc need CR/LF translation.

	C_CONSTLOHI	If const 'AB' is saved as BA in int.

	C_USEPRINTF	If you want use printf/fprintf/sprintf in
			console/file/mem output functions.
*/

/*	DEFINITIONS FOR SMALL C
*/

#ifdef CC_SMALLC

/*#define NULL	0*/
#define TRUE	1
#define FALSE	0

/*#define C_ICRLF*/
/*#define C_OCRLF*/

/*#define EOF	(-1)*/
/*#define FILE	char*/

#endif

/*	DEFINITIONS FOR TURBO C
*/

#ifdef CC_TURBOC

#define NULL	0
#define TRUE	1
#define FALSE	0

#define EOF	(-1)
#define FILE	char

#define C_CONSTLOHI

#endif

/*	DEFINITIONS FOR PCC - PERSONAL C COMPILER
*/

#ifdef CC_PCC

#define NULL	0
#define TRUE	1
#define FALSE	0

#define C_ICRLF

#define EOF	(-1)
#define FILE	int

#endif

/*	COMMON DEFS.
*/

#define VERSION	"Mike's Enhanced Small C Compiler v1.01 - 27 May 2007"

#define ERCONST	"Must be constant"

#define ERARRSZ "Illegal array size"
#define ERARRPT "Illegal *[]"
#define ERARGNB "Illegal arguments number"
#define ERARGNM	"Need argument name"

/*#define ERNEGSZ	"Illegal negative size"*/ /* VER */


/*#define ERILDEC "Illegal declaration"*/

#define ERFUNDE	"Illegal function declaration"
/*#define ERARGIN	"Illegal argument name"*/ /* VER */
/*#define ERARGTY	"Illegal number or argument type"*/ /* VER */
#define ERSYMNM	"Illegal symbol name"

#define ERALDEF	"Already defined"
#define EROFGLB	"Global symbol table full"
#define EROFLOC	"Local symbol table full"
#define ERTMWHI	"Too many active while's"
#define ERNOWHI	"No active while's"
#define EREXWHI	"Need a while"
#define ERLTLNG	"Line too long"
#define ERTMCAS	"Too many active case's"

#define OUT_PRG 0
#define OUT_LIB 1
#define OUT_ASM 2

/*	STRING POOL
*/

#define STRBUF_SIZ	6000

/*	INPUT LINE
*/

#define LN_SIZ	256
#define LN_MAX	255

/*	SYMBOL TABLE FORMAT
*/

#define SY_NAME		0
#define SY_IDENT	12
#define SY_TYPE		13
#define SY_STORAGE	14
#define SY_OFFSET	15

#define SYMSIZE		17

/*	SYMBOL NAME SIZE
*/

#define NAME_SIZ	12
#define NAME_MAX	11

/*	IDENT
*/

#define ID_VAR	1
#define ID_ARR	2
#define ID_PTR	3
#define ID_FUN	4

/*	TYPE
*/

#define TY_CHAR		1
#define TY_INT		2
#define TY_UCHAR	5
#define TY_UINT		6

/*	STORAGE
*/

#define ST_EXTERN	1
#define ST_STATIK	2
#define ST_STKLOC	3

#endif
