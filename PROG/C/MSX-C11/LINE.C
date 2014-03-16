/**********************************************************************/
/*                                                                    */
/*      LINE    draws a line                                          */
/*                                                                    */
/*      Calls the DOGRPH routine of BASIC interpreter with;           */
/*                                                                    */
/*              Start coordinate in ([BC],[DE])                       */
/*              End coordinate in (GXPOS,GYPOS)                       */
/*              Attribute in (ATRBYT)                                 */
/*              Logical operation code in (LOGOPR)                    */
/*                                                                    */
/**********************************************************************/

typedef char    TINY;
typedef char    VOID;

#define DOGRPH  ((VOID (*)())0x593c)    /* BASIC line draw routine */

#define ATRBYT  (*(TINY *)0xf3f2)       /* color attribute */
#define LOGOPR  (*(TINY *)0xfb02)       /* logical operator */
#define SCRMOD  (*(TINY *)0xfcaf)       /* screen mode */
#define GXPOS   (*(unsigned *)0xfcb3)   /* graphics cursor X */
#define GYPOS   (*(unsigned *)0xfcb5)   /* graphics cursor Y */

VOID    calbas();

TINY    line( x1, y1, x2, y2, color, log_op )
unsigned        x1, y1;                 /* start coordinate */
unsigned        x2, y2;                 /* end coordinate */
TINY            color;                  /* color code */
TINY            log_op;                 /* logical operation */
{
    GXPOS  = x2;        /* set 2nd X coordinate */
    GYPOS  = y2;        /* set 2nd Y coordinate */
    ATRBYT = color;     /* set color attribute */
    LOGOPR = log_op;    /* set logical operator */

    calbas( DOGRPH, x1, y1 );
}
