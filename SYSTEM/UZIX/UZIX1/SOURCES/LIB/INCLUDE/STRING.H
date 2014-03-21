#ifndef __STRING_H
#define __STRING_H
#ifndef __TYPES_H
#include <types.h>
#endif
#include <stddef.h>

#ifdef _MSX_DOS 	/* HI-TECH-C/MSX-DOS	STRING.H */

/* String functions */

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
extern char *	strcpy __P ((char*, char*));
extern char *	strncpy __P ((char *, char *, size_t));
extern char *	strcat __P ((char*, char*));
extern char *	strncat __P ((char *, char *, size_t));
extern int	memcmp __P ((void *, void *, size_t));
extern int	strcmp __P ((char*, char*));
extern int	strncmp __P ((char *, char *, size_t));
extern size_t	strcoll __P ((char *, size_t, char *));
extern void *	memchr __P ((void *, int, size_t));
extern size_t	strcspn __P ((char *, char *));
extern char *	strpbrk __P ((char *, char *));
extern size_t	strspn __P ((char *, char *));
extern char *	strstr __P ((char *, char *));
extern char *	strtok __P ((char *, char *));
extern void *	memset __P ((void *, int, size_t));
extern char *	strerror __P ((int));
extern size_t	strlen __P ((char *));
extern char *	strchr __P ((char *, int));
extern char *	strrchr __P ((char *, int));

#else		/* UZIX-hosted	STRING.H */

/* Basic string functions */
extern size_t strlen __P ((char* __str));

extern char * strcat __P ((char*, char*));
extern char * strcpy __P ((char*, char*));
extern int strcmp __P ((char*, char*));

extern char * strncat __P ((char*, char*, size_t));
extern char * strncpy __P ((char*, char*, size_t));
extern int strncmp __P((char*, char*, size_t));

extern int stricmp __P((char*, char*));
extern strnicmp __P((char*, char*, size_t));

extern char * strchr __P ((char*, int));
extern char * strrchr __P ((char*, int));
extern char * strdup __P ((char*));

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

/* Other common BSD functions */
char *strpbrk __P ((char *, char *));
char *strsep __P ((char **, char *));
char *strstr __P ((char *, char *));
char *strtok __P ((char *, char *));
size_t strcspn __P ((char *, char *));
size_t strspn __P ((char *, char *));

#ifdef	z80
#pragma inline(memcpy)
#pragma inline(memset)
#pragma inline(strcpy)
#pragma inline(strlen)
#pragma inline(strcmp)
#endif

#endif		/* END OF DEFINITION	STRING.H */
#endif
