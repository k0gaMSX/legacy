#ifndef _FCNTL_H
#define _FCNTL_H

#define O_RDONLY	0
#define O_WRONLY	1
#define O_RDWR		2

/* Flag values for open only */
#define O_CREAT 	0x0100	/* create and open file */
#define O_TRUNC 	0x0200	/* open with truncation */
#define O_NEW		0x0400	/* create only if not exist */
#define O_SYMLINK	0x0800	/* open symlink as file */

/* a file in append mode may be written to only at its end. */
#define O_APPEND	0x2000	/* to end of file */
#define O_EXCL		0x4000	/* exclusive open */
#define O_BINARY	0x8000	/* not used in unix */

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

#endif

