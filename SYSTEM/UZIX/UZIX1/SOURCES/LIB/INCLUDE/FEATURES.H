#ifndef __FEATURES_H
#define __FEATURES_H

#ifndef __STDC__
#ifdef HI_TECH_C
#define __STDC__	1
#endif
#endif

/* Define prototypes shell for non-ANSI compilers */
#ifdef __TURBOC__

#define VOID	void
#define __P(a)	a
#define __const const

void __cli__();
void __sti__();
void __int__(int);
void __emit__();

#define di()	__cli__()
#define ei()	__sti__()

#define geninterrupt(i) __int__(i)
#define FP_OFF(fp)	((unsigned)(fp))
#define FP_SEG(fp)	((unsigned)((unsigned long)(fp) >> 16))

#else
#ifdef __STDC__

#ifndef VOID
#define VOID	void
#endif
#ifndef __P
#define __P(a)	a
#endif
#define __const const

#else	/* K&R */

#ifndef VOID
#define VOID
#endif
#ifndef __P
#define __P(a)	()
#endif
#define __const
#define volatile
#define void	char

#endif	/* __STDC__ */
#endif	/* __TURBOC__ */

#include <sys/cdefs.h>

#endif

