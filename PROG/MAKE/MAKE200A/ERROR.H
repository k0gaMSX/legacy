/*--- ERROR.H --------------------------------------------------------------*/

char *Ealloc();
VOID MError();

   /* Redeclaration of FIB to avoid using BDOSFUNC.H with all the defines */

typedef unsigned LONG[2];

typedef struct {
	TINY    fib_id;		/* always 0xff (ID for FIB)		*/
	char    name[13];	/* file name as an ASCIZ string		*/
	TINY    attr;		/* file attribute			*/
	unsigned fibtime;	/* time of last modification		*/
	unsigned fibdate;	/* date of last modification		*/
	unsigned firstclu;	/* first cluster in chain		*/
	LONG    filesize;	/* file size in bytes			*/
	TINY    dc;		/* logical drive			*/
	TINY    dummy[38];	/* internal information			*/
} FIB;


typedef struct MacRow {        /* Macro structure */
   char 	   *MacKey;    /* Macro keyword */
   char 	   *MacStr;    /* Macro string */
   struct MacRow   *MacNxt;    /* Pointer to next macro definition */
} MacRow;


typedef struct node {
   char 	*name;		       /* pointer to drive/path/file ASCIIZ */
   struct node	*left;		       /* pointer to left record */
   struct node	*right; 	       /* pointer to right record */
   struct node	*prev;		       /* pointer to previous record */
   unsigned	date;		       /* date */
   unsigned	time;		       /* time */
   int		attr;		       /* attribute */
   BOOL 	resetAttr;	       /* TRUE if archive bit must be reset */
   BOOL 	backDone;	       /* TRUE if backup has been done */
   BOOL 	Aupdate;	       /* YES if archive bit set */
   BOOL 	Tupdate;	       /* YES if new time compared to master */
} node;


   /* Union as used by free() & alloc(). SDM's RdLnMf() uses this union to
      check if sizeof SDMtbuf has changed */

typedef union header {
   struct {
      union header *ptr;
      unsigned	   size;
   } s;
   char x;
} HEADER;


extern BOOL	    ALIFE;
extern char	    CurrDir[64+3];
extern char	    **dpf;
extern char	    *ErrFile;
extern BOOL	    f_Aupdate;
extern BOOL	    f_backDone;
extern unsigned     f_date;
extern node	    *f_left;
extern char	    *f_name;
extern node	    *f_node;
extern node	    *f_prev;
extern BOOL	    f_resetAttr;
extern node	    *f_right;
extern unsigned     f_time;
extern BOOL	    f_Tupdate;
extern node	    leaf;
extern char	    *m_key;
extern MacRow	    *m_nxt;
extern MacRow	    *m_row;
extern char	    *m_str;
extern MacRow	    MacBase;
extern char	    *MacStr;
extern char	    *makefile;
extern char	    mfcl;
extern FIB	    MFIB;
extern char	    mfHandle;
extern int	    mfln;
extern char	    OptX, OptY, OptB, OptL, OptA, OptMX, OptMB, OptT, OptXB;

