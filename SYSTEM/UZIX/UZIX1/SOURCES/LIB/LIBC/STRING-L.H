/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */
#include <string.h>

#ifdef MAKE_ALL
#define L_strlen
#define L_strcat
#define L_strcpy
#define L_strcmp
#define L_strncat
#define L_strncpy
#define L_strncmp
#define L_strchr
#define L_strrchr
#define L_strdup
#define L_strcspn
#define L_stricmp
#define L_strnicmp
#define L_strpbrk
#define L_strsep
#define L_strspn
#define L_strstr
#define L_strtok
#endif

/* This is a basic string package; it includes the most used functions:
 *
 * strlen strcat strcpy strcmp strncat strncpy strncmp strchr strrchr strdup
 * strcspn stricmp strnicmp strpbrk strspn strstr strtok
 */
