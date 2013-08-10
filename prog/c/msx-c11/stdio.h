/*

	STDIO.H         Standard header file (Ver 1.1)

*/

/****** common types and constants ******/

#define NULL    0               /* constant for pointer */

typedef unsigned size_t;
typedef char    TINY;
typedef char    VOID;
typedef char    BOOL;

				/* constants for BOOL */
#define TRUE    1
#define FALSE   0
#define YES     1
#define NO      0

typedef char    STATUS;

				/* constants for STATUS */
#define OK              0
#define ERROR           -1
#define WILDCARD        -2


/****** buffered I/O functions ******/

typedef struct  {
	TINY    serial;         /* is not 0 when serial device */
	char    mode;           /* file mode - R, W, R/W */
	char    *ptr;           /* next character position */
	int     count;          /* number of characters left */
	char    *base;          /* location of buffer */
	int     fd;             /* file descriptor */
	size_t  bufsiz;         /* size of bufer */
}       FILE;

#define _NFILES         10      /* maximum number of buffered I/O */
#define BUFSIZ          1024    /* default buffer size of fopen */

extern  FILE    _iob[_NFILES];

#define stdin   (&_iob[0])
#define stdout  (&_iob[1])
#define stderr  (&_iob[2])

#define EOF     -1

#define ungetch ugetch  /* for poor linker with 6 chars symbol */

FILE    *fopen(.);
int     getc(),     getchar();
char    *fgets(),   *gets();
int     fscanf(.),  scanf(.);
STATUS  putc(),     putchar(),
	fputs(),    puts(),
	fprintf(.), printf(.);
STATUS  ungetc(),   ungetch();
STATUS  fclose();

STATUS  fsetbin(), fsettext();  /* non-standard */


/****** simulated unix system calls ******/

typedef int     FD;             /* file descriptor */

FD      creat(), open();
int     read(), write();
STATUS  rename(), unlink();
STATUS  close();

VOID    execl(.), execv(), exit();
char    *sbrk();


/****** misc. functions ******/

char    *alloc();
#define malloc(size) alloc(size)
VOID    free();

typedef int     jmp_buf[2];
int     setjmp();
VOID    longjmp();

int     abs(), max(), min();
VOID    qsort();


/****** string-handling routines ******/

VOID    sprintf(.);
int     sscanf(.), atoi();

int     strcmp();
size_t  strlen();
char    *strcpy(), *strcat();

VOID    memset(), memcpy();
VOID    setmem(), movmem();


/****** character types ******/

#define isalpha(c)      (isupper(c) || islower(c))
#define isupper(c)      ('A' <= (c) && (c) <= 'Z')
#define islower(c)      ('a' <= (c) && (c) <= 'z')
#define isdigit(c)      ('0' <= (c) && (c) <= '9')
#define isspace(c)      ((c) == ' ' || '\t' <= (c) && (c) <= '\r')
#define iscntrl(c)      ((c) < ' ' || (c) == '\177')

char    toupper();
char    tolower();


/****** MSX-DOS dependent functions ******/

char    getch();                /* direct console input without echo */
char    getche();               /* direct console input with echo */
BOOL    kbhit();
VOID    sensebrk();

VOID    rsvstk();
int     expargs();


/****** hardware (Z80) dependent functions ******/

char    inp();
VOID    outp();
int     call();
char    calla();
