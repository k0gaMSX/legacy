#ifndef CPM_H
#include <cpm.h>
#endif

#ifndef ALLOC_H
#include <alloc.h>
#endif

#ifndef FILEIO_H

#define FILEIO_H

/*	fileio.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	File I/O.

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

	19 Mar 2001 : Last revision.
	17 Apr 2004 : Added functions: fread, fwrite, remove, rename.
	16 Apr 2007 : GPL'd.
	20 Apr 2007 : Quit "rt" and "wt" modes. Now "r" and "w" are text modes.

	FILE *fopen(char *fname, char *fmode)
	int fclose(FILE *fp)
	int fgetc(FILE *fp)
	int fputc(int ch, FILE *fp)
	int feof(FILE *fp)
	int ferror(FILE *fp)
	int fread(char *ptr, int size, int nobj, FILE *fp)
	int fwrite(char *ptr, int size, int nobj, FILE *fp)
	int remove(char *fname)
	int rename(char *oldname, char *newname)

	int xfgetc(FILE *fp)
	int xfputc(int ch, FILE *fp)
*/

/*	DEFINICIONES ESTANDAR
*/

#define FILE unsigned char
#define EOF (-1)

#ifndef NULL
#define NULL	0
#endif

/*	DEFINICIONES PRIVADAS
*/

#define XF_READ   1	/* Read mode */
#define XF_WRITE  2	/* Write mode */
#define XF_BIN	4	/* Binary mode */
#define XF_EOF	8	/* End of file */
#define XF_ERR	16	/* I/O error */

#define XF_IMOD	0	/* Modo (1 byte) */
#define XF_IPOS	1	/* Posicion en buffer (1 byte) */
#define XF_IBUF	2	/* Datos buffer (128 bytes) */
#define XF_IFCB	130	/* Datos FCB (36 bytes) */

#define XF_ISIZ	166	/* Longitud de la estructura */

/*	FILE *fopen(char *fname, char *fmode)

	Apertura de archivo. Devuelve puntero a FILE, o NULL
	en caso de error.
	Valores validos para 'fmode':

		"rb"	Lectura binario.
		"r"	Lectura texto.
		"wb"	Escritura binario.
		"w"	Escritura texto.

	En lectura de texto, '\r' es ignorado, '\n' es fin de linea.

	En escritura de texto, '\n' se convierte a '\r' mas '\n'.
*/

fopen(fname,fmode)
char *fname, *fmode;
{
	int mode,i;
	FILE *fp;
	
	/* Establecer el modo de apertura */

	if(*fmode=='r')
		mode = XF_READ;
	else if(*fmode=='w')
		mode = XF_WRITE;
	else
		return NULL;

	if(*(fmode+1)=='b')
		mode |= XF_BIN;
	else if(*(fmode+1))
		return NULL;

	/* Obtener memoria */

	if(!(fp=malloc(XF_ISIZ)))
		return NULL;

	/* Crear fcb no ambiguo */

	if(setfcb(fname,fp+XF_IFCB))
	{
		free(fp);
		return NULL;
	}

	for(i=1;i<12;i++)
	{
		if(*(fp+XF_IFCB+i)=='?')
		{
			free(fp);
			return NULL;
		}
	}

	/* Abrir fichero */

	setdma(fp+XF_IBUF);

	if(mode & XF_READ)
	{
		if(openfile(fp+XF_IFCB)==255)
		{
			free(fp);
			return NULL;
		}

		fp[XF_IPOS]=128;	/* No hay datos en buffer */
	}
	else
	{
		if(findfile(fp+XF_IFCB)!=255)
		{
			if(killfile(fp+XF_IFCB)==255)
			{
				free(fp);
				return NULL;
			}
		}

		if(makefile(fp+XF_IFCB)==255)
		{
			free(fp);
			return NULL;
		}

		fp[XF_IPOS]=0;	/* No hay datos en buffer */
	}

	/* Fijar indicadores */

	fp[XF_IMOD]=mode;	/* Modo de apertura */

	/* Devolver puntero a canal */

	return fp;
}

/*	int fgetc(FILE *fp)

	Lee un caracter y devuelve su valor, o EOF en caso de error.
*/

fgetc(fp)
FILE *fp;
{
	int c;

	/* Fichero abierto para lectura y sin errores? */

	if(!(fp[XF_IMOD] & XF_READ) || fp[XF_IMOD] & (XF_EOF + XF_ERR))
		return EOF;

	/* Leer caracter */

	c=xfgetc(fp);

	if(!(fp[XF_IMOD] & XF_BIN))
	{
		while(c=='\r')
			c=xfgetc(fp);

		if(c==0x1A)
		{
			fp[XF_IMOD]|=XF_EOF;
			c=EOF;
		}
	}

	/* Devolver caracter */

	return c;
}

/*	int xfgetc(FILE *fp)

	Funcion auxiliar para fgetc. Devuelve siguiente caracter,
	o EOF en caso de error.
*/

xfgetc(fp)
FILE *fp;
{
	/* Leer registro si hace falta */

	if(fp[XF_IPOS]==128)
	{
		setdma(fp+XF_IBUF);

		if(readseq(fp+XF_IFCB))
		{
			fp[XF_IMOD]|=XF_EOF;
			return EOF;
		}	

		fp[XF_IPOS]=0;
	}

	/* Obtener caracter e incrementar posicion */

	return *(fp + XF_IBUF + fp[XF_IPOS]++);
}

/*	int fputc(int c, FILE *fp)

	Escritura de caracter. Devuelve su valor, o EOF en
	caso de error.
*/

fputc(c,fp)
int c;
FILE *fp;
{
	/* Fichero abierto para escritura y sin error ? */

	if(!(fp[XF_IMOD] & XF_WRITE) || fp[XF_IMOD] & (XF_EOF + XF_ERR))
		return EOF;

	if(!(fp[XF_IMOD] & XF_BIN))
	{
		if(c=='\n')
		{
			if(xfputc('\r',fp)==EOF)
				return EOF;
		}
	}

	return xfputc(c,fp);
}

/*	int xfputc(int c, FILE *fp)

	Funcion auxiliar para fputc. Devuelve valor del
	caracter escrito, o EOF en caso de error.
*/

xfputc(c,fp)
int c;
FILE *fp;
{

	/* Almacenar caracter e incrementar posicion */

	*(fp + XF_IBUF + fp[XF_IPOS]++)=c;

	/* Escribir registro si hace falta */

	if(fp[XF_IPOS]==128)
	{
		setdma(fp + XF_IBUF);

		if(writeseq(fp + XF_IFCB))
		{
			fp[XF_IMOD]|=XF_ERR;
			return EOF;
		}	

		fp[XF_IPOS]=0;
	}

	/* Devolver caracter */

	return c;
}

/*	int fclose(FILE *fp)

	Cerrado de fichero. Devuelve 0 en caso de exito,
	EOF en caso de error.
*/

fclose(fp)
FILE *fp;
{
	if(fp[XF_IMOD] & XF_WRITE)
	{
		while(fp[XF_IPOS])
		{
			if(xfputc(0x1A, fp)==EOF)
				return EOF;
		}
	}

	/* Cerrar el fichero */

	if(closefile(fp + XF_IFCB)==255)
		return EOF;

	/* Liberar memoria */

	free(fp);

	/* Ok, fichero cerrado */

	return 0;
}

/*	int feof(FILE *fp)

	Devuelve un valor distinto de cero si se ha llegado
	al final del fichero.
*/

feof(fp)
FILE *fp;
{
	return fp[XF_IMOD] & XF_EOF;
}

/*	int ferror(FILE *fp)

	Devuelve un valor distinto de cero si se origino
	un error en el fichero.
*/

ferror(fp)
FILE *fp;
{
	return fp[XF_IMOD] & XF_ERR;
}

/*	int fread(char *ptr, int size, int nobj, FILE *fp)

	Lee nobj objetos de tamanyo size y los pone en ptr.
	Devuelve el numero de objetos leidos.
*/

fread(ptr, size, nobj, fp)
unsigned char *ptr;
int size, nobj;
FILE *fp;
{
	int cobj, csize, c;

	if(!(fp[XF_IMOD] & XF_READ) || fp[XF_IMOD] & (XF_EOF + XF_ERR))
		return EOF;

	for(cobj=0; cobj!=nobj; ++cobj)
	{
		for(csize=0; csize!=size; ++csize)
		{
			c=xfgetc(fp);

			if(!(fp[XF_IMOD] & XF_BIN))
			{
				while(c=='\r')
					c=xfgetc(fp);

				if(c==0x1A)
				{
					fp[XF_IMOD]|=XF_EOF;
					c=EOF;
				}
			}

			if(c==EOF)
				return cobj;

			*ptr++=c;
		}
	}

	return cobj;
}

/*	int fwrite(char *ptr, int size, int nobj, FILE *fp)

	Escribe nobj objetos de tamanyo size desde ptr.
	Devuelve el numero de objetos escritos.
*/

fwrite(ptr, size, nobj, fp)
unsigned char *ptr;
int size, nobj;
FILE *fp;
{
	int cobj, csize;

	if(!(fp[XF_IMOD] & XF_WRITE) || fp[XF_IMOD] & (XF_EOF + XF_ERR))
		return EOF;

	for(cobj=0; cobj!=nobj; ++cobj)
	{
		for(csize=0; csize!=size; ++csize)
		{
			if(!(fp[XF_IMOD] & XF_BIN))
			{
				if(*ptr=='\n')
				{
					if(xfputc('\r',fp)==EOF)
						return cobj;
				}
			}

			if(xfputc(*ptr++,fp)==EOF)
				return cobj;
		}
	}

	return cobj;
}

/*	int remove(char *fname)

	Borra un archivo. Devuelve un valor distinto de cero si hay error.
*/

remove(fname)
char *fname;
{
	char fcb[36];

	if(!setfcb(fname, fcb))
	{
		if(killfile(fcb)!=0xFF)
			return 0;
	}

	return 1;
}

/*	int rename(char *oldname, char *newname)

	Renombra un archivo. Devuelve un valor distinto de cero si hay error.
*/

rename(oldname, newname)
char *oldname, *newname;
{
	char fcb[52];

	if(!setfcb(oldname, fcb) && !setfcb(newname, fcb+16))
	{
		if(renfile(fcb)!=0xFF)
			return 0;
	}

	return 1;
}

#endif
