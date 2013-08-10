/**********************************************************************/
/*                                                                    */
/*      COLOR   changes the color of the screen                       */
/*                                                                    */
/*      Sets FORCLR, BAKCLR and BDRCLR, and calls BIOS CHGCLR.        */
/*      Returns the previous setting of these colors.                 */
/*                                                                    */
/**********************************************************************/

typedef char    TINY;
typedef char    VOID;

#define FORCLR  (*(TINY *)0xf3e9)       /* foreground color */
#define BAKCLR  (*(TINY *)0xf3ea)       /* background color */
#define BDRCLR  (*(TINY *)0xf3eb)       /* border color */

VOID    chgclr();

TINY    *color( fore, back, bord )
TINY    fore, back, bord;
{
    static  TINY prev[3];   /* previous color */

    prev[0] = FORCLR;       /* save previous colors */
    prev[1] = BAKCLR;
    prev[2] = BDRCLR;

    FORCLR = fore;          /* set new colors */
    BAKCLR = back;
    BDRCLR = bord;

    chgclr();

    return (prev);          /* return previous colors */
}
