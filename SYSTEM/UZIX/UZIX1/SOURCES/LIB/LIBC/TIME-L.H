/* TIME-L.H	Time conversion and time related package
 *
 */
#include <time.h>
#include <string.h>

#ifndef TZ_MOSCOW
#ifndef TZ_BRAZIL
#define TZ_BRAZIL
#endif
#endif

#ifdef MAKE_ALL
#define L_asctime
#define L_ctime
#define L_gmtime
#define L_localtim
#define L_tzset
#define L_clock
#define L_mktime
#define L_difftime
#define L_convtime
#endif
