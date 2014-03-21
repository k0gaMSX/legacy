#ifndef __UTIME_H
#define __UTIME_H
#ifndef __TYPES_H
#include <types.h>
#endif

extern int utime __P ((char *__filename, struct utimbuf *__utimebuf));

#endif

