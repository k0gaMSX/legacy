/*
**	TYPES.H
**	general types definition for ASCII or SOLID C
**
**	(c) 1995, SOLID
*/


#ifndef	_C_TYPES_
#define _C_TYPES_

#ifndef	__SOLIDC__
typedef	char void;
#endif

typedef	char	BYTE;
typedef	char	TINY;
typedef	char	BOOL;

typedef	unsigned uint;
typedef	uint	WORD;


#define	NULL	0
#define	FALSE	0
#define	TRUE	1

#ifndef	_SIZE_T
#define	_SIZE_T
typedef	unsigned	size_t;
#endif

#endif


