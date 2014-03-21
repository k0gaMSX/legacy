/* 
 * UZIX syscall for MSX-implementation
 */

#include <syscalls.h>

#ifndef SYSCADDR
#define SEPH
#include "unix.h"
#endif

#define UNIX	int
#define UNIXL	long
#define UNIXV	void

#define UZIX_MODULE

#ifndef __DOS__

#ifdef MAKE_ALL
#define L___syscall
#define L_access
#define L_alarm
#define L_brk
#define L_chdir
#define L_chroot
#define L_chmod
#define L_chown
#define L_close
#define L_creat
#define L_dup
#define L_dup2
#define L_execve
#define L_exit
#define L_fork
#define L_fstat
#define L_getfsys
#define L_ioctl
#define L_kill
#define L_link
#define L_symlink
#define L_mknod
#define L_mkfifo
#define L_mount
#define L_open
#define L_pause
#define L_pipe
#define L_read
#define L_sbrk
#define L_lseek
#define L_signal
#define L_stat
#define L_stime
#define L_sync
#define L_time
#define L_times
#define L_umount
#define L_unlink
#define L_utime
#define L_waitpid
#define L_write
#define L_reboot

#define L_getgid
#define L_getegid
#define L_getpid
#define L_getppid
#define L_getuid
#define L_geteuid
#define L_getprio
#define L_setgid
#define L_setuid
#define L_setprio
#define L_umask
#define L_systrace
#endif

#endif
