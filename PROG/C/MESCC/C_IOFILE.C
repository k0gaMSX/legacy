/*	c_iofile.c

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	I/O file module.

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

	16 Jan 2001 : Last revision.
	16 Apr 2007 : GPL'd.
*/

#ifndef C_MAIN_H
#include "c_main.h"
#endif

#define C_IFILES 4	/* Max. input files */

int	fi_fps[3],	/* FILE *fp    */
	fi_lines[3];	/* line number */

char fi_names[45];	/* Buffer for input file names (15*(SC_IFILES-1)) */

/*	Values for current input file
*/

FILE *fi_fp;
char fi_name[15];
int fi_line;
int fi_eof;

int fi_files;		/* Opened input files */

#define ERTMFLS	"Too many active files"
#define EROPEN	"Can't open"
#define ERWRITE	"Can't write"
#define ERCLOSE	"Can't close"

init_files()
{
	fi_files=0;

	return 0;
}

fi_open(fname)
char *fname;
{
	if(fi_files)
	{
		if(fi_files==C_IFILES)
			errfile(ERTMFLS,fname);

		fi_fps[fi_files-1]=fi_fp;
		strcpy(fi_names+(fi_files-1)*15,fi_name);
		fi_lines[fi_files-1]=fi_line;
	}

	if((fi_fp=fopen(fname,"r"))==0)
		errfile(EROPEN,fname);

	strcpy(fi_name,fname);
	fi_line=fi_eof=0;

	++fi_files;
}

fi_ch()
{
	if(fi_eof!=EOF)
	{
#ifdef C_ICRLF
		while((fi_eof=fgetc(fi_fp))=='\r');

		if(fi_eof==0x1A)
			fi_eof=EOF;
#else
		if((fi_eof=fgetc(fi_fp))==0x1A)
			fi_eof=EOF;
#endif
	}

	return fi_eof;
}

fi_close()
{
	if(fclose(fi_fp))
		errfile(ERCLOSE,fi_name);

	if(--fi_files)
	{
		fi_fp=fi_fps[fi_files-1];
		strcpy(fi_name,fi_names+(fi_files-1)*15);
		fi_line=fi_lines[fi_files-1];
		fi_eof=0;
	}
}

FILE *fo_fp;
char fo_name[15];

fo_open(fname)
char *fname;
{
	if((fo_fp=fopen(fname,"w"))==0)
		errfile(EROPEN,fname);

	strcpy(fo_name,fname);
}

fo_close()
{
	if(fclose(fo_fp))
		errfile(ERCLOSE,fo_name);
}

fo_ch(c)
int c;
{
#ifdef C_OCRLF
	if(c=='\n')
		fputc('\r',fo_fp);
#endif
	if(fputc(c,fo_fp)==EOF)
		errfile(ERWRITE,fo_name);

	return c;
}

fo_str(s)
char *s;
{
	while(*s)
		fo_ch(*s++);
}

fo_nl()
{
	fo_ch('\n');
}

fo_colon()
{
	fo_ch(':');
}

fo_line(s)
char *s;
{
	fo_str(s);fo_nl();
}

fo_dec(n)
int n;
{
	int i;
	if(n<0)
	{
		/* Possible $8000 can't be negatived */
		/*if((number^0xFFFF)==0x7FFF){outstr("0-32768");return;}*/
		fo_ch('0');
		fo_ch('-');
		n=-n;
	}
	if(i=n/10)
		fo_dec(i);
	fo_ch(n%10+'0');
}
