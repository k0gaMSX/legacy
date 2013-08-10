/*
**	IO.H
**	Low-level nonbuffered file I/O
**
**	(c) 1995, SOLID	
*/

#ifndef	_C_TYPES_
#include <types.h>
#endif

#define	SEEK_SET	0
#define	SEEK_CUR	1
#define	SEEK_END	2

#define	OPEN_MAX	16

#define	O_RDONLY	0
#define	O_WRONLY	1
#define	O_RDWR		1
#define	O_CREAT		0x39
#define	O_EXCL		0x04
#define	O_TRUNC		0x31
#define	O_APPEND	0x40
#define	O_TEMP		0x80

int	open	();	/* opens/creates a file */
#define	_open	open
int	creat	();	/* creates file */
#define	_creat	creat
size_t	read	();	/* read file */
#define	_read	read
size_t	write	();	/* write file */
#define	_write	write
char	isatty	();	/* return NZ if FD is console I/O */
BOOL	_seek	();	/* sets file pointer */
BOOL	_tell	();	/* returns current position */

int	ioctl	();
int	ioctla	();	/* io ctl for devices in DOS2 */

int	fcntl	();	/* different file control in MISIX */
char	fcntla	();	/* same */

char	close	();	/* close file */
#define	_close	close

char	unlink	();	/* delete file */
char	remove	();	/* delete file */

int	dup	();	/* duplicate handle */
char	dup2	();	/* force duplicate handle */

char	bdos	();
int	bdosh	();
