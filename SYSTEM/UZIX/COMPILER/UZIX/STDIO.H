#ifndef __STDIO_H
#define __STDIO_H
#ifndef __TYPES_H
#include <types.h>
#endif
#include <stdarg.h>

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

#define _IOFBF		0x00	/* full buffering */
#define _IOLBF		0x01	/* line buffering */
#define _IONBF		0x02	/* no buffering */
#define __MODE_BUF	0x03	/* Modal buffering dependent on isatty */

#define __MODE_FREEBUF	0x04	/* Buffer allocated with malloc, can free */
#define __MODE_FREEFIL	0x08	/* FILE allocated with malloc, can free */

#define __MODE_READ	0x10	/* Opened in read only */
#define __MODE_WRITE	0x20	/* Opened in write only */
#define __MODE_RDWR	0x30	/* Opened in read/write */

#define __MODE_READING	0x40	/* Buffer has pending read data */
#define __MODE_WRITING	0x80	/* Buffer has pending write data */

#define __MODE_EOF	0x100	/* EOF status */
#define __MODE_ERR	0x200	/* Error status */
#define __MODE_UNGOT	0x400	/* Buffer has been polluted by ungetc */

#ifdef __MSDOS__
#define __MODE_IOTRAN	0x1000	/* MSDOS nl <-> cr,nl translation */
#else
#define __MODE_IOTRAN	0
#endif

/* when you add or change fields here, be sure to change the initialization
 * in stdio_init and fopen */
struct __stdio_file {
	uchar	*bufpos;	/* the next byte to write to or read from */
	uchar	*bufread;	/* the end of data returned by last read() */
	uchar	*bufwrite;	/* highest address writable by macro */
	uchar	*bufstart;	/* the start of the buffer */
	uchar	*bufend;	/* the end of the buffer; ie the byte after
				   the last malloc()ed byte */
	int	fd;		/* the file descriptor associated with the stream */
	int	mode;
	char	unbuf[8];	/* The buffer for 'unbuffered' streams */
	struct __stdio_file * next;
};

#define EOF	(-1)
#ifndef NULL
#define NULL	(0)
#endif

typedef struct __stdio_file FILE;

extern FILE stdin[1];
extern FILE stdout[1];
extern FILE stderr[1];

#ifdef x__MSDOS__
#define putc(c, fp) fputc(c, fp)
#define getc(fp) fgetc(fp)
#else
#define putc(c, stream) \
	(((stream)->bufpos >= (stream)->bufwrite) ? \
		fputc((c), (stream)) : \
		(uchar) (*(stream)->bufpos++ = (c)))
#define getc(stream)	\
	(((stream)->bufpos >= (stream)->bufread) ? \
		fgetc(stream) : \
		(*(stream)->bufpos++))
#endif

#define putchar(c)	putc((c), stdout)
#define getchar()	getc(stdin)

extern char *gets __P((char *));

extern int _putchar __P((int));
extern int _getchar __P((void));

#define ferror(fp)	(((fp)->mode&__MODE_ERR) != 0)
#define feof(fp)	(((fp)->mode&__MODE_EOF) != 0)
#define clearerr(fp)	((fp)->mode &= ~(__MODE_EOF|__MODE_ERR))
#define fileno(fp)	((fp)->fd)

/* These two call malloc */
extern int setvbuf __P((FILE*, char*, int, size_t));
#define setlinebuf(__fp)	setvbuf((__fp), (char*)0, _IOLBF, 0)

/* These don't */
extern void setbuffer __P((FILE*, char*, size_t));
#define setbuf(__fp, __buf)	setbuffer((__fp), (__buf), BUFSIZ)

extern int fgetc __P((FILE*));
extern int fputc __P((int, FILE*));
extern int ungetc __P((int, FILE*));

extern int fclose __P((FILE*));
extern int fflush __P((FILE*));
#define stdio_pending(fp) ((fp)->bufread > (fp)->bufpos)
extern char *fgets __P((char*, size_t, FILE*));
extern FILE *__fopen __P((char*, int, FILE*, char*));

#if 1
#define fopen(__file, __mode)	      __fopen((__file), -1, (FILE*)0, (__mode))
#define freopen(__file, __mode, __fp) __fopen((__file), -1, (__fp), (__mode))
#define fdopen(__file, __mode)	__fopen((char*)0, (__file), (FILE*)0, (__mode))
#else
extern FILE * fopen __P((char *__file, char *__mode));
extern FILE * freopen __P((char *__file, char *__mode, int __fp));
extern FILE * fdopen __P((int __fd, char *__mode));
#endif

extern int fputs __P((void *, FILE*));
extern int puts __P((void *));

extern int fread __P((void *, size_t, size_t, FILE *));
extern int fwrite __P((void *, size_t, size_t, FILE *));

extern int fseek __P((FILE *fp, long offset, int whence));
extern long ftell __P((FILE *fp));

extern int printf __P((char*, ...));
extern int fprintf __P((FILE*, char*, ...));
extern int sprintf __P((char*, char*, ...));

extern int vprintf __P((char*, va_list));
extern int vfprintf __P((FILE*, char*, va_list));
extern int vsprintf __P((char*, char*, va_list));

#if 0
typedef int (*_printer_func_t) __P((int, void *));
extern int _vprinter(_printer_func_t prt, void *, char *, ...));
#endif

extern int scanf __P((char*, ...));
extern int fscanf __P((FILE*, char*, ...));
extern int sscanf __P((char*, char*, ...));

extern int vscanf __P((char*, va_list));
extern int vfscanf __P((FILE*, char*, va_list));
extern int vsscanf __P((char*, char*, va_list));

extern void perror __P((char *__s));
extern char *strerror __P((int __errno));

extern char *tmpnam __P((char *buf));

extern int rename __P((char *oldname, char *newname));
extern void rewind __P((FILE *fp));
extern FILE *popen __P((char *, char *));
extern int pclose __P((FILE *));

#endif /* __STDIO_H */
