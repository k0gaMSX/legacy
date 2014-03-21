#ifndef __UNISTD_H
#define __UNISTD_H
#ifndef __TYPES_H
#include <types.h>
#endif
#include <syscalls.h>

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

#define STDIN_FILENO	0
#define STDOUT_FILENO	1
#define STDERR_FILENO	2

extern int mkdir __P((char *, mode_t));
extern int rmdir __P((char *));

extern long tell __P((int));
extern off_t lseek __P((int, off_t, int));

extern int isatty __P((int));

extern int lstat __P((char *, void *));
extern int readlink __P((char *, char *, int));

extern char **environ;

extern char * _findPath __P((char *pathname));
extern int execl __P((char *pathname, char *arg0, ...));
extern int execle __P((char *pathname, char *arg0, ...));
extern int execlp __P((char *pathname, char *arg0, ...));
extern int execlpe __P((char *pathname, char *arg0, ...));
extern int execv __P((char *pathname, char *argv[]));
extern int exect __P((char *pathname, char *argv[], char *envp[]));
extern int execvp __P((char *pathname, char *argv[]));
extern int execvpe __P((char *pathname, char *argv[], char *envp[]));

extern char *ttyname __P((int));
extern int system __P((char *));
extern int pause __P((void));
extern int fork __P((void));
extern char *getcwd __P((char *, int));

#ifndef __STDLIB_H
extern void exit __P((int));
#endif

#ifndef R_OK
#define R_OK	4	/* Test for read permission.  */
#define W_OK	2	/* Test for write permission.  */
#define X_OK	1	/* Test for execute permission.  */
#define F_OK	0	/* Test for existence.	*/
#endif

#endif /* __UNISTD_H */
