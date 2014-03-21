/********** MSX-UZIX version of syscalls ************/
/* UNIX creat(char *name, mode_t mode); */

#include "syscalls.h"
#include "fcntl.h"

#ifdef L_creat
UNIX creat(char *name, mode_t mode) {
	return open(name,O_CREAT|O_WRONLY|O_TRUNC,mode);
}
#endif


