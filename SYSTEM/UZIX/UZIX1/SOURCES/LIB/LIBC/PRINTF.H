/* printf.c
 *    Dale Schumacher			      399 Beacon Ave.
 *    (alias: Dalnefre')		      St. Paul, MN  55104
 *    dal@syntel.UUCP			      United States of America
 *
 * Altered to use stdarg, made the core function vfprintf.
 * Hooked into the stdio package using 'inside information'
 * Altered sizeof() assumptions, now assumes all integers except chars
 * will be either
 *  sizeof(xxx) == sizeof(long) or sizeof(xxx) == sizeof(short)
 *
 * -RDB
 */
#ifdef MAKE_ALL
#define L_printf
#define L_sprintf
#define L_fprintf
#define L_vprintf
#define L_vsprintf
#define L_vfprintf
#ifndef HI_TECH_C
#define FLOATS
#endif
#endif

#include <types.h>
#include <fcntl.h>
#if 1
#include <stdarg.h>
#define va_strt      va_start
#else
#include <varargs.h>
#define va_strt(p,i) va_start(p)
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

