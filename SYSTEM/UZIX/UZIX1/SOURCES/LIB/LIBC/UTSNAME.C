/*
 * utsname.c for UZIX
 * by A&L Software 1999
 *
 */

#include <utsname.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#ifdef __TURBOC__
#include <..\kernel\unix.h>
#endif
#ifdef HI_TECH_C
#include <unix.h>
#endif

int uname (__utsbuf)
	struct utsname *__utsbuf;
{
	struct s_kdata kdata;
	int i;

	getfsys(GI_KDAT, &kdata);
	strcpy(__utsbuf->sysname,kdata.k_name);
	strcpy(__utsbuf->nodename,kdata.k_name);
	for (i=0;i<strlen(__utsbuf->nodename);i++)
		__utsbuf->nodename[i]=tolower(__utsbuf->nodename[i]);
	strcpy(__utsbuf->release,kdata.k_release);
	strcpy(__utsbuf->version,kdata.k_version);
	strcpy(__utsbuf->machine,kdata.k_machine);
	strcpy(__utsbuf->domainname,"(localhost)");
	return 0;
}
