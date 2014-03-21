/* grp-l.h	groups implementation
 */
#include <types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <paths.h>
#include <stdio.h>
#include <errno.h>
#include <grp.h>

#ifdef MAKE_ALL
#define	L_fgetgren
#define	L_getgrgid
#define	L_getgrnam
#define	L_setgrent
#define	L_initgroup
#define	L_getgrent
#endif
