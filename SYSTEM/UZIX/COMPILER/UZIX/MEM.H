#ifndef __MEM_H
#define __MEM_H
#ifndef __TYPES_H
#include <types.h>
#endif
#include <stddef.h>

#ifdef _MSX_DOS 	/* HI-TECH-C/MSX-DOS	MEM.H */

#ifndef _STDDEF
typedef int		ptrdiff_t;	/* result type of pointer difference */
typedef unsigned	size_t; 	/* type yielded by sizeof */
#define _STDDEF
#define offsetof(ty, mem)	((int)&(((ty *)0)->mem))
#endif	_STDDEF

#ifndef NULL
#define NULL	((void *)0)
#endif	NULL

extern int	errno;			/* system error number */

extern void *	memcpy __P ((void *, void *, size_t));
extern void *	memmove __P ((void *, void *, size_t));
extern int	memcmp __P ((void *, void *, size_t));
extern void *	memchr __P ((void *, int, size_t));
extern void *	memset __P ((void *, int, size_t));

#else		/* UZIX-hosted	MEM.H */

/* Basic mem functions */
extern void * memcpy __P ((void*, void*, size_t));
extern void * memccpy __P ((void*, void*, int, size_t));
extern void * memchr __P ((void*, int, size_t));
extern void * memset __P ((void*, int, size_t));
extern int memcmp __P ((void*, void*, size_t));
extern void * memmove __P ((void*, void*, size_t));

/* BSDisms */
#define index strchr
#define rindex strrchr
#define strcasecmp stricmp
#define strncasecmp strnicmp

#ifdef	z80
#pragma inline(memcpy)
#pragma inline(memset)
#pragma inline(strcpy)
#pragma inline(strlen)
#pragma inline(strcmp)
#endif

#endif		/* END OF DEFINITION	MEM.H */
#endif
