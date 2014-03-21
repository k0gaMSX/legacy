#ifndef CPM_H

#define CPM_H

/*	cpm.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	CP/M functions.

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

	19 Oct 2000 : Last revision.
	17 Apr 2004 : Added renfile function
	16 Apr 2007 : GPL'd.
*/


#asm

;	void setdma(void *ptr)
;
;	Fija direccion dma.

setdma:
	LD	C,26
	EX	DE,HL
	JP	5

;	int makefile(void *fcb)
;
;	Crea fichero. Devuelve codigo BDOS.

makefile:
	LD	C,22
bdosfile
	EX	DE,HL
	CALL	5
	LD	H,0
	LD	L,A
	RET

;	int killfile(void *fcb)
;
;	Borra fichero. Devuelve codigo BDOS.

killfile:
	LD	C,19
	JR	bdosfile

;	int renfile(void *fcb)
;
;	Renombra fichero. Devuelve codigo BDOS.

renfile:
	LD	C,23
	JR	bdosfile

;	int openfile(void *fcb)
;
;	Abre fichero. Devuelve codigo BDOS.

openfile:
	LD	C,15
	JR	bdosfile

;	int closefile(void *fcb)
;
;	Cierra fichero. Devuelve codigo BDOS.

closefile:
	LD	C,16
	JR	bdosfile

;	int findfile(void *fcb)
;
;	Busca fichero. Devuelve codigo BDOS.

findfile:
	LD	C,17
	JR	bdosfile

;	int findnext(void)
;
;	Busca siguiente fichero. Devuelve codigo BDOS.

findnext:
	LD	C,18
	JR	bdosfile

;	int readseq(void *fcb)
;
;	Lectura secuencial. Devuelve codigo BDOS.

readseq:
	LD	c,20
	JR	bdosfile

;	int writeseq(void *fcb)
;
;	Escritura secuencial. Devuelve codigo BDOS.

writeseq:
	LD	c,21
	JR	bdosfile


;	int bdos_a(int c,int de)
;
;	Llamada a BDOS. Devuelve valor del reg. A.

bdos_a:
	POP	HL
	POP	DE
	POP	BC
	PUSH	BC
	PUSH	DE
	PUSH	HL

	CALL	5

	LD	H,0
	LD	L,A

	RET

;	int setfcb(char *fname, char *fcb)
;
;	Devuelve 0 si ok, otro si error

setfcb:
	POP	BC
	POP	DE
	POP	HL
	PUSH	HL		;HL = Puntero a fname
	PUSH	DE		;DE = Puntero a fcb
	PUSH	BC

	INC	HL		;Se ha especificado unidad A: ... P: ?
	LD	A,(HL)
	DEC	HL
	CP	':'
	JR	NZ,sfcbdef
	LD	A,(HL)
	CALL	sfcbupp
	CP	'A'
	JR	C,sfcberr
	CP	'P' + 1
	JR	NC,sfcberr
	SUB	'A' - 1
	INC	HL
	INC	HL
	JR	sfcbdrv

sfcbdef
	XOR	A		;Unidad por defecto

sfcbdrv
	LD	(DE),A		;Fijar unidad en fcb
	INC	DE

sfcbnam
	LD	C,'.'		;Fijar nombre en fcb
	LD	B,8
	CALL	sfcbtok
	LD	A,B
	CP	8
	JR	Z,sfcberr
	LD	A,(HL)
	OR	A
	JR	Z,sfcbtyp
	CP	'.'
	JR	NZ,sfcberr
	INC	HL

sfcbtyp
	LD	C,0		;Fijar tipo en fcb
	LD	B,3
	CALL	sfcbtok
	LD	A,(HL)
	OR	A
	JR	NZ,sfcberr

	LD	A,0		;Fijar ceros en fcb sobrante
	LD	B,24
	CALL	sfcbset

	LD	HL,0		;Ok, fin
	RET

	;Entrada de error para sfcbtok

sfcbtke
	POP	HL		;Quitar direccion de la pila

sfcberr
	LD	HL,1		;Error, fin
	RET

	;Fijar token (nombre o tipo)
	;
	;Entrada:
	;	C = Caracter de terminacion ('.' para nombre, 0 para tipo)
	;	B = Maxima longitud del token (8 para nombre, 3 para tipo)
	;
	;Salida:
	;	B = Longitud restante

sfcbtok
	LD	A,(HL)		;Fin de cadena ?
	OR	A
	JR	Z,sfcbspc
	CP	C		;Caracter de terminacion ?
	JR	Z,sfcbspc
	CP	'*'		;Comodin ?
	JR	Z,sfcbamb

	;A partir de aqui, solo se aceptan caracteres validos

	CP	'#'		;# $ %
	JR	C,sfcbtke
	CP	'%' + 1
	JR	C,sfcbtks
	CP	'0'		;0 ... 9
	JR	C,sfcbtke
	CP	'9' + 1
	JR	C,sfcbtks
	CALL	sfcbupp		;? @ A ... Z
	CP	'?'
	JR	C,sfcbtke
	CP	'Z' + 1
	JR	C,sfcbtks
	CP	'_'		;_
	JR	NZ,sfcbtke

sfcbtks
	LD	(DE),A		;Fijar caracter del token en fcb
	INC	HL
	INC	DE
	DJNZ	sfcbtok		;Continuar hasta agotar la longitud
	RET

	;Fija resto del token con espacios,
	;y devuelve el contador de longitud tal y como estaba
	;para posterior comprobacion

sfcbspc
	LD	A,' '
	LD	C,B
	CALL	sfcbset
	LD	B,C
	RET

	;Fija '?' en el resto del token
	;y deja contador de longitud a cero

sfcbamb
	LD	A,'?'
	INC	HL

	;Rellena un area de memoria
	;
	;Entrada:
	;	DE = Direccion
	;	B  = Longitud
	;	A  = Byte

sfcbset
	LD	(DE),A
	INC	DE
	DJNZ	sfcbset
	RET

	;Convierte caracter a mayusculas
	;
	;Entrada:
	;	A = Caracter
	;
	;Salida:
	;	A = Caracter convertido a mayusculas si era a ... z

sfcbupp
	CP	'a'
	RET	C
	CP	'z' + 1
	RET	NC
	SUB	32
	RET

#endasm

#endif
