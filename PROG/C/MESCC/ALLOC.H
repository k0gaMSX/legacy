#ifndef ALLOC_H

#define ALLOC_H

/*	alloc.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Dynamic memory functions.

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

	13 Dec 2000 : Last revision.
	16 Apr 2007 : GPL'd.

	Public:

	void *malloc(unsigned int size)
	void free(void *)

	Private:

	int xmgetint(int *ptr)
	void xmputint(int *ptr, int val)

	Notes:

	Each memory block contains following data:

	unsigned int size;	Size of data
	char used;		0=No, 1=Yes
	char data[size];
*/

/*	RUNTIME VARIABLES
*/

extern char *ccfreefirst;
extern unsigned int ccfreebytes;

/*	PRIVATE VARIABLES
*/

char	xmallocini,		/* if initialized == 0x69 */
	*xmalloctop,		/* First block */
	*xmallocend;		/* Last block */

/*	void *malloc(unsigned int size)

	Memory allocation.

	Return pointer, or NULL if not enough memory.
*/

malloc(size)
unsigned size;
{
	char *memptr;
	unsigned memsize;

	/* Need initialization ? */

	if(xmallocini!=0x69)
	{
		if(ccfreebytes < 7)
			return 0;

		xmalloctop=ccfreefirst;
		xmallocend=xmalloctop + ccfreebytes - 3;

		xmputint(xmalloctop,ccfreebytes - 6);
		xmalloctop[2]=0;

		xmputint(xmallocend,0);
		xmallocend[2]=1;

		xmallocini=0x69;
	}

	/* Search free block */

	for(memptr=xmalloctop; memptr<xmallocend; memptr+=memsize+3)
	{
		memsize=xmgetint(memptr);

		if(memsize >= size && memptr[2]==0)
		{
			memptr[2]=1;

			if(memsize >= size + 3)
			{
				xmputint(memptr,size);
				xmputint(memptr+size+3,memsize-size-3);
				*(memptr+size+5)=0;
			}

			return memptr + 3;
		}
	}

	return 0;
}

/*	void free(void *ptr)

	Dealloc memory.
*/

free(ptr)
char *ptr;
{
	char *memptr;
	unsigned memsize;

	/* Make free */

	*(ptr - 1)=0;

	/* Compact block if possible */

	for(memptr=xmalloctop; memptr<xmallocend; memptr+=memsize+3)
	{
		memsize=xmgetint(memptr);

		if(memptr[2]==0 && *(memptr+memsize+5)==0)
		{
			memsize+=xmgetint(memptr+memsize+3)+3;

			if(*(memptr+memsize+5)==0)
				memsize+=xmgetint(memptr+memsize+3)+3;

			xmputint(memptr,memsize);

			return;
		}
	}
}

/*	int xmgetint(int *ptr)

	Get a int from ptr.
*/

xmgetint(ptr)
int *ptr;
{
	return *ptr;
}

/*	void xmputint(int *ptr, int val)

	Put a int into ptr.
*/

xmputint(ptr, val)
int *ptr, val;
{
	*ptr=val;
}

#endif
