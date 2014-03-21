#ifndef __TERMIOS_H
#define __TERMIOS_H
#ifndef __TYPES_H
#include <types.h>
#endif

#define NCCS 32

/* c_iflag flag constants */
#define IGNPAR	1
#define INPCK	2
#define ICRNL	4
#define IXON	8
#define IXOFF	16

/* c_oflag flag constants */
#define ONLCR	1

/* c_cflag flag constants */
#define CS6	1
#define CS7	2
#define CS8	3
#define CSTOPB	4
#define PARENB	8
#define PARODD	16
#define CRTSCTS 32

extern int cfgetispeed __P ((struct termios *__termios_p));
extern int cfgetospeed __P ((struct termios *__termios_p));
extern int cfsetispeed __P ((struct termios *__termios_p, int __speed));
extern int cfsetospeed __P ((struct termios *__termios_p, int __speed));

extern void cfmakeraw  __P ((struct termios *__t));

#define tcsetattr(fd, opt, p)	ioctl(fd, opt, p)
/* extern int tcsetattr __P ((int __fd, int __opt, struct termios *__termios_p)); */
extern int tcgetattr __P ((int __fildes, struct termios *__termios_p));
extern int tcdrain __P ((int __fildes));
extern int tcflow __P ((int __fildes, int __action));
extern int tcflush __P ((int __fildes, int __queue_selector));
extern int tcsendbreak __P ((int __fildes, int __duration));
extern int tcgetpgrp __P ((int __fildes));
extern int tcsetpgrp __P ((int __fildes, int __pgrp_id));

struct termios {
	uchar c_iflag;		/* input mode flags */
	uchar c_oflag;		/* output mode flags */
	uchar c_cflag;		/* control mode flags */
	uchar c_lflag;		/* local mode flags */
	char c_line;		/* line discipline */
	char c_cc[NCCS];	/* control characters */
	int c_ispeed;		/* input speed */
	int c_ospeed;		/* output speed */
};
	
#endif

