/* mem.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */
#include <string.h>

#ifdef MAKE_ALL
#define L_memcpy
#define L_memccpy
#define L_memchr
#define L_memset
#define L_memcmp
#define L_memmove
#endif
