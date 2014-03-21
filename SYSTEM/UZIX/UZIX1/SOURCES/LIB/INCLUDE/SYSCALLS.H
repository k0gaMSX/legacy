/* SYSCALLS.H
 */
#ifndef __SYSCALLS_H
#define __SYSCALLS_H
#ifndef __TYPES_H
#include <types.h>
#endif
#ifndef __SIGNAL_H
#include <signal.h>
#endif

#ifndef __DOS__

extern int errno;

#ifndef __STDLIB_H
extern void _exit __P((int val));
#endif

extern int access __P((char *path, int mode));
extern int alarm __P((uint secs));
extern int brk __P((char *addr));
extern int chdir __P((char *dir));
extern int chroot __P((char *dir));
extern int chmod __P((char *path, mode_t mode));
extern int chown __P((char *path, int owner, int group));
extern int close __P((int uindex));
extern int creat __P((char *name, mode_t mode));
extern int dup __P((int oldd));
extern int dup2 __P((int oldd, int newd));
extern int execve __P((char *name, char *argv[], char *envp[]));
extern int fork __P((void));
extern int fstat __P((int fd, void *buf));
extern int getfsys __P((int dev, void *buf));
extern int getgid __P((void));
extern int getpid __P((void));
extern int getppid __P((void));
extern int getuid __P((void));
extern int geteuid __P((void));
extern int getegid __P((void));
extern int getprio __P((void));
extern int ioctl __P((int fd, int request, ...));
extern int kill __P((int pid, int sig));
extern int link __P((char *oldname, char *newname));
extern int symlink __P((char *oldname, char *newname));
extern int mknod __P((char *name, mode_t mode, int dev));
extern int mkfifo __P((char *name, mode_t mode));
extern int mount __P((char *spec, char *dir, int rwflag));
extern int open __P((char *name, uint flag, ...));
extern int pause __P((void));
extern int pipe __P((int fildes[2]));
extern int read __P((int d, void *buf, uint nbytes));
extern int sbrk __P((uint incr));
extern off_t lseek __P((int file, off_t offset, int whence));
extern int setgid __P((int gid));
extern int setuid __P((int uid));
extern int setprio __P((int pid, char prio));
extern sig_t signal __P((signal_t sig, sig_t func));
extern int stat __P((char *path, void *buf));
extern int stime __P((time_t *tvec));
extern int sync __P((void));
extern time_t time __P((time_t *tvec));
extern int times __P((struct tms *buf));
extern int utime __P((char *path, struct utimbuf *buf));
extern int umask __P((int mask));
extern int umount __P((char *spec));
extern int unlink __P((char *path));
extern int wait __P((int *statloc));
extern int write __P((int d, void *buf, uint nbytes));
extern int reboot __P((char p1, char p2));
extern int systrace __P((int onoff));

#ifdef UZIX_MODULE
extern int modulereg __P((uint sig, int (*func)()));
extern int moduledereg __P((uint sig));
extern int modulecall __P((uint sig, uint fcn, char *args, int argsize));
extern int modulereply __P((uint sig, int fcn, char *repladdr));
extern int modulesendreply __P((int pid, int fcn, char *repladdr, int replysize));
#endif

#else	/* running under MS-DOS */

#include "types.h"
#include <io.h>
#include <dir.h>
#include <alloc.h>
#include <errno.h>
#include <fcntl.h>
#include <process.h>

extern int alarm(uint secs);
extern int chown(char *path, int owner, int group);
extern int fork(void);
extern int getfsys(int dev, void *buf);
extern int getgid(void);
extern int getppid(void);
extern int getuid(void);
extern int geteuid(void);
extern int getegid(void);
extern int getprio(void);
extern int kill(int pid, int sig);
extern int link(char *name1, char *name2);
extern int mknod(char *name, mode_t mode, int dev);
extern int mount(char *spec, char *dir, int rwflag);
extern int pause(void);
extern int pipe(int fildes[2]);
extern int setgid(int gid);
extern int setuid(int uid);
extern int stime(time_t *tvec);
extern int sync(void);
extern time_t time(time_t *tvec);
extern int times(struct tms *buf);
extern int umount(char *spec);
extern int wait(int *statloc);
extern int reboot(char p1, char p2);
extern int systrace(int onoff);

#endif	/* __DOS__ */
#endif	/* __SYSCALLS_H */

