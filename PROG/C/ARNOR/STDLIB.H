/* system functions */


extern long bdos() ;
extern int bios() ;
extern void call() ;
extern long filesize() ;
extern void firmware() ;
extern int getdrive() ;
extern char inp() ;
extern void outp() ;
extern char peek() ;
extern void poke() ;
extern int rename() ;
extern int seldrive() ;
extern void setfcb() ;
extern void settime() ;
extern void time() ;
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

extern char *calloc() ;
extern void free() ;
extern mallblock *mallinfo() ;
extern char *malloc() ;


/* string and memory functions */


extern char *index() ;
extern char *memchr() ;
extern int memcmp() ;
extern char *memcpy() ;
extern char *memset() ;
extern void movmem() ;
extern char *strcat() ;
extern char *strchr() ;
extern int strcmp() ;
extern int strcmpl() ;
extern char *strcpy() ;
extern int strcspn() ;
extern char *strdup() ;
extern int strlen() ;
extern char *strlwr() ;
extern char *strncat() ;
extern char *strncpy() ;
extern char *strpbrk() ;
extern char *strrchr() ;
extern char *strrev() ;
extern char *strset() ;
extern int strspn() ;
extern char *strtok() ;
extern char *strupr() ;


/* conversion routines */


extern double atof() ;
extern int atoi() ;
extern long atol() ;
extern char *ecvt() ;
extern char *fcvt() ;
extern char *gcvt() ;
extern double strtod() ;
extern long strtol() ;
extern int toascii() ;
extern int tolower() ;
extern int toupper() ;


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

extern int busypr() ;
extern int prch() ;
extern void setpr() ;


/* high level i/o functions */


typedef struct
{
  char handle ;
  char mode ;
  char error ;
} FILE ;

extern int fbinary() ;
extern int fclose() ;
extern int feof() ;
extern int fflush() ;
extern int fgetc() ;
extern char *fgets() ;
extern FILE *fopen() ;
extern int fprintf() ;
extern int fputc() ;
extern int fputs() ;
extern int fread() ;
extern FILE *freopen() ;
extern int fscanf() ;
extern long fseek() ;
extern long ftell() ;
extern int ftext() ;
extern int fwrite() ;
extern char getc() ;
extern char *gets() ;
extern int getw() ;
extern int printf() ;
extern int putc() ;
extern int puts() ;
extern int putw() ;
extern void rewind() ;
extern int scanf() ;
extern int sprintf() ;
extern int sscanf() ;
extern int ungetc() ;


/* character classification */

/*
These are provided as macros
Remove the comment delimiters to use function versions

#undef isalnum
#undef isalnum
#undef isalpha
#undef isascii
#undef iscntrl
#undef isdigit
#undef isgraph
#undef islower
#undef isprint
#undef ispunct
#undef isspace
#undef isupper
#undef isxdigit
extern int isalnum() ;
extern int isalpha() ;
extern int isascii() ;
extern int iscntrl() ;
extern int isdigit() ;
extern int isgraph() ;
extern int islower() ;
extern int isprint() ;
extern int ispunct() ;
extern int isspace() ;
extern int isupper() ;
extern int isxdigit() ;
*/
 