/*
**	mem.h
**	Memory manipulation functions
**
**	(c) 1995, SOLID
*/

#ifndef	_C_TYPES_
#include <types.h>
#endif

void	*memchr	();	/* search for a character in memory block */
int	 memcmp	();	/* compare two memory blocks */
void	*memcpy	();	/* copy memory block */
void	*memmove();	/* copy memory block */
void	*memset();	/* fill memory with byte */
void	 movmem();	/* ASCII C 1.0 memory copy */
void	 setmem();	/* ASCII C 1.0 memory fill */
