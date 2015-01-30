/*
**	STDIO.H
**
**      Definitions for stream input/output.
**	(c) 1995, SOLID
*/

#ifndef	_C_TYPES_
#include <types.h>
#endif

#ifndef	_STD_LIB_
#include <stdlib.h>
#endif


#define	EOF	(-1)

#define	BUFSIZ	512			/* Default buffer size	*/

typedef	struct
{
	unsigned	flags;		/* status of this stream	*/
	int		level;		/* number of characters in buffer */
	char		* curp;		/* current pointer in buffer	*/
	int		fd;		/* fd for low-level i/o	*/
	char		* buffer;	/* base of buffer	*/
	char		hold;		/* for ungetc */
	short		token;		/* ???? */
	char	dummy;	/* ????? bug fix by Tatsu */
}	FILE;

typedef	long	fpos_t;		/* file offset type	*/

/*
**      "flags" bits definitions
*/
#define _F_RDWR 0x0003                  /* Read/write flag      */
#define _F_READ 0x0001                  /* Read only file       */
#define _F_WRIT 0x0002                  /* Write only file      */
#define _F_BUF  0x0004                  /* Malloc'ed Buffer data */
#define _F_LBUF 0x0008                  /* line-buffered file   */
#define _F_ERR  0x0010                  /* Error indicator      */
#define _F_EOF  0x0020                  /* EOF indicator        */
#define _F_BIN  0x0040                  /* Binary file indicator */
#define _F_IN   0x0080                  /* Data is incoming     */
#define _F_OUT  0x0100                  /* Data is outgoing     */
#define _F_TERM 0x0200                  /* File is a terminal   */

/*	3rd argument for fseek function.	*/
#define	SEEK_CUR	1
#define	SEEK_END	2
#define	SEEK_SET	0


#define	OPEN_MAX	16

extern	FILE	_iob[];

#define	stdin	(&_iob[0])	/* standart input stream	*/
#define	stdout	(&_iob[1])	/* standart output stream	*/
#define	stderr	(&_iob[2])	/* standart perror stream	*/


int	printf(.);
int	sprintf(.);
int	fprintf(.);
int	scanf(.);
int	sscanf(.);
int	fscanf(.);

void	clearerr();

FILE	*fdopen();
FILE	*fopen();
FILE	*freopen();

void	fclosall();
BOOL	fclose();
size_t	fread();
size_t	fwrite();

char	*gets();
BOOL	puts();
char	getchar();
char	putchar();
char	*fgets();
char	fputs();
char	fgetc();
char	fputc();
char	ungetc();
BOOL	fflush();
void	rewind();

BOOL	fgetpos();
BOOL	fsetpos();


#define	fileno(a)	((a)->fd)
#define	ferror(a)	((a)->flags & _F_ERR)
#define	feof(a)		((a)->flags & _F_EOF)

#define	fgetchar	getc(stdin)
#define	fputchar(c)	putc((c),stdout)
