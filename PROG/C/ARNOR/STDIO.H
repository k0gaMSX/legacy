/*********************************
**         BSC C System         **
**                              **
**     Standard Header File     **
**                              **
**       ARNOR VERSION          **
**                              **
*********************************/

#define NULL   ((char *)0)
#define EOF    (-1)
#define TRUE    1
#define FALSE   0

typedef struct
{
  char handle;
  char mode;
  char error;
} FILE ;

#define MAXFILES 20

extern FILE _iob[];

#define stdin   (&_iob[0])
#define stdout  (&_iob[1])
#define stderr  (&_iob[2])
#define stdprn  (&_iob[3])

#define isalnum(x) (isalpha(x) || isdigit(x))
#define isalpha(x) (isupper(x) || islower(x))
#define isascii(x) ((x)<128 && (x)>=0)
#define iscntrl(x) (((x)>=0 && (x)<32) || (x)=127)
#define isdigit(x) ((x)<='9' && (x)>='0')
#define isgraph(x) ((x)>32 && (x)<127)
#define islower(x) ((x)<='z' && (x)>='a')
#define isprint(x) ((x)>=32 && (x)<127)
#define ispunct(x) (isprint(x) && !isalnum(x))
#define 