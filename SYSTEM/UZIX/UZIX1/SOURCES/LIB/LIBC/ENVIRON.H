/* Environment processing package
 */
#define const
#include <stdlib.h>
#include <string.h>

#ifdef MAKE_ALL
#define L_getenv
#define L_putenv
#define L_setenv
#endif
