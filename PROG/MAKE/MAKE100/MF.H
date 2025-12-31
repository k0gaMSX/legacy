/*--- MF.H ------------------------------------------------------------------*/

extern int     mfln;	       /* current line# of makefile */
extern char    mfcl;	       /* current column# of makefile */
extern char    mfname[13];     /* current filename from makefile */


#define    SPILLC	'\\'    /* spill character */
#define    COMMC	'#'     /* comment character */
#define    MFEXT	".MF"   /* default makefile extension */


VOID ProcMf();
