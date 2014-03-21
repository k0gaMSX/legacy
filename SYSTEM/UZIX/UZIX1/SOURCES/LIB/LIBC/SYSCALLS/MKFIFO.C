/********** MSX-UZIX version of syscalls ************/
/* UNIX mkfifo(char *name, mode_t mode); */

#include "syscalls.h"
#include <sys/stat.h>
#include "unix.h"

#ifdef L_mkfifo
UNIX mkfifo(char *name, mode_t mode) {
	return mknod(name, mode | S_IFPIPE, (dev_t) 0);
}
#endif
