/* scanf.c
 */
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#ifdef MAKE_ALL
#define L_scanf
#define L_sscanf
#define L_fscanf
#define L_vscanf
#define L_vsscanf
#define L_vfscanf
#ifndef HI_TECH_C
#define	FLOATS
#endif
#endif

#if 1
#include <stdarg.h>
#define va_strt      va_start
#else
#include <varargs.h>
#define va_strt(p,i) va_start(p)
#endif

