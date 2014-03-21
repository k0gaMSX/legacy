/* passwd.h
 */
 
/* OBS.: getpwuid gets the first password entry that has the given UID.
         it DOESN'T look for GID, so entries with different GIDs and
         equal UID will be treated as equal
*/      

#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <paths.h>
#include <types.h>
#include <errno.h>
#include <stdio.h>
#include <pwd.h>

#ifdef MAKE_ALL
#define	L_fgetpwen
#define	L_getpw
#define	L_getpwnam
#define	L_getpwuid
#define	L_putpwent
#define	L_setpwent
#define	L_getpwent
#endif

