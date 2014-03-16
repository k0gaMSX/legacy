/* system functions */


extern long bdos() ;
extern void setfcb() ;
extern int unlink() ;
extern int version() ;


/* memory allocation functions */


typedef struct _mallinfo
{
  unsigned  limalloc ;
  unsigned  nfree ;
  unsigned  nalloc ;
  unsigned  nblocks ;
} mallblock ;

extern void free() ;
extern mallblock *mallinfo() ;
extern char *malloc() ;


/* string and memory functions */


extern char *strcat() ;
extern char *strchr() ;
extern int strcmp() ;
extern char *strcpy() ;
extern int strlen() ;
extern char *strncat() ;
extern char *strncpy() ;


/* conversion routines */


extern double strtod() ;
extern long strtol() ;


/* miscellaneous functions */


extern void abort() ;
/*
#undef abs
extern int abs() ;
*/
extern int drsearch() ;
extern void execv() ;
extern void exit() ;
extern void longjmp() ;
extern int setjmp() ;
extern void _exec() ;
extern void _exit() ;
extern char *_getsp() ;
extern char *_getlim() ;
extern void _putlim() ;


/* low level i/o */


extern int close() ;
extern long lseek() ;
extern int open() ;
extern int read() ;
extern int write() ;
extern int _fchret() ;
extern int _feof() ;
extern int _finch() ;
extern int _foutch() ;
extern long _ftell() ;

extern void cursoff() ;
extern void curson() ;
extern void getcurs() ;
extern void getwin() ;
extern void invoff() ;
extern void invon() ;
extern void putch() ;
extern void rdmatrix() ;
extern void selwin() ;
extern void setcurs() ;
extern void setwin() ;
extern int unwrchar() ;
extern void wrchar() ;
extern void wrmatrix() ;

extern void escoff() ;
extern void escon() ;
extern int getch() ;
extern int getche() ;
extern int kbhit() ;
extern void ungetch() ;


/* high level i/o functions */


typedef struct
{
  char handle ;
  char mode ;
  char error ;
} FILE ;

extern int fclose() ;
extern int feof() ;
extern int fgetc() ;
extern char *fgets() ;
extern FILE *fopen() ;
extern int fprintf() ;
extern int fputc() ;
extern int fputs() ;
extern int fread() ;
extern long fseek() ;
extern long ftell() ;
extern int fwrite() ;
extern char getc() ;
extern char *gets() ;
extern int getw() ;
extern int printf() ;
extern int putc() ;
extern int puts() ;
extern int putw() ;
extern int ungetc() ;
