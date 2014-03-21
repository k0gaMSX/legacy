/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#ifdef MAKE_ALL
#define L_stdio
#define L_fputc
#define L_fgetc
#define L_putchar
#define L_getchar
#define L_fflush
#define L_fgets
#define L_gets
#define L_fputs
#define L_puts
#define L_fread
#define L_fwrite
#define L_rewind
#define L_fseek
#define L_ftell
#define L_fopen
#define L_fclose
#define L_setbuff
#define L_setvbuf
#define L_ungetc
#endif

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <types.h>
#include <malloc.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>

#ifndef STATIC
#define STATIC
#endif

extern FILE *__IO_list; 	/* For fflush at exit */
#ifndef Inline_init
#define Inline_init __stdio_init_vars()
STATIC void __stdio_init_vars __P((void));
#endif

