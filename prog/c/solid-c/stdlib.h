/*
**	STDLIB.H
**
**      Copyright (c) MicroGenSf 1988, 1991
**      All Rights Reserved.
*/

#ifndef	_C_TYPES_
#include <types.h>
#endif

#ifndef	_STD_LIB_
#define	_STD_LIB_
extern	int	    errno;

void	* bsearch();
void	qsort();
int	atoi();
int	strtol();
int	abs();
int	min();
int	max();
int	rand();
int	srand();
void	exit();
void	_exit();
int	atexit();
#endif
