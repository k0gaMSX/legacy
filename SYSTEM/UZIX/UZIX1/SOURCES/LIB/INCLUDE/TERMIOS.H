#ifndef __TERMIOS_H
#define __TERMIOS_H
#ifndef __TYPES_H
#include <types.h>
#endif

extern int cfgetispeed __P ((struct termios *__termios_p));
extern int cfgetospeed __P ((struct termios *__termios_p));
extern int cfsetispeed __P ((struct termios *__termios_p, int __speed));
extern int cfsetospeed __P ((struct termios *__termios_p, int __speed));

extern void cfmakeraw  __P ((struct termios *__t));

extern int tcsetattr __P ((int __fd, int __opt, struct termios *__termios_p));
extern int tcgetattr __P ((int __fildes, struct termios *__termios_p));
extern int tcdrain __P ((int __fildes));
extern int tcflow __P ((int __fildes, int __action));
extern int tcflush __P ((int __fildes, int __queue_selector));
extern int tcsendbreak __P ((int __fildes, int __duration));
extern int tcgetpgrp __P ((int __fildes));
extern int tcsetpgrp __P ((int __fildes, int __pgrp_id));

#endif

