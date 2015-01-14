/*
 *	Assertion - use liberally for debugging. Defining NDEBUG
 *	turns assertions off.
 *	assert(exp) where exp is non-zero does nothing, while
 *	assert(exp) where exp evaluates to zero aborts the program
 *	with a message like
 *
 *	Assertion failed: prog.c line 123: "exp"
 *
 */

#ifndef	NDEBUG
extern int _fassert(int, char *, char *);
#define	assert(exp)  ((void)((exp) ? 0 : _fassert(__LINE__, __FILE__, "exp")))
#else
#define	assert(exp)
#endif
