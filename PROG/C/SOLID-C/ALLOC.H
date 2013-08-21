/*
**	ALLOC.H
**	Memory management functions
**
**	(c) 1995, SOLID
*/


#ifndef	_C_TYPES_
#include <types.h>
#endif

void	free	();	/* free malloc'd memory */
void	* malloc();	/* allocate memory */
void	* sbrk	();	/* move free memory pointer arg bytes higher */
int	brk	();	/* set free memory pointer */
void	* calloc();	/* allocate object array, zero memory */
