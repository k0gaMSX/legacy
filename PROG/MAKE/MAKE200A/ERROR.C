/*--- ERROR.C ---------------------------------------------------------------*/

#include <stdio.h>
#include "error.h"


BOOL	ALIFE;		   /* TRUE if file-tree was expanded with new node */
char	CurrDir[64+3];	   /* Current directory */
char	**dpf;		    /* drive/path/file specification string for backup */
char	*ErrFile;	   /* Filename string to use in error output */
BOOL	  f_Aupdate;	   /* Easy file-node variables */
BOOL	  f_backDone;
char	  *f_name;
unsigned  f_date;
node	 *f_node;
node	 *f_left;
node	 *f_prev;
BOOL	 f_resetAttr;
node	 *f_right;
unsigned  f_time;
BOOL	  f_Tupdate;
char	*m_key; 	   /* Easy macro variables */
MacRow	*m_nxt;
MacRow	*m_row;
char	*m_str;
MacRow	MacBase = {"$", "$", NULL};  /* Base of macro chain */
char	*MacStr;	   /* Global pointer to string with macro keywords to
			      replace */
char	*makefile = NULL;  /* makefilename, NULL if not defined */
char	mfcl = 0;	   /* Current column of makefile */
FIB	MFIB;		   /* File Info Block for common use */
char	mfHandle;	   /* Handle for makefile */
int	mfln = 0;	   /* Current line of makefile */
char OptX = FALSE;	/* TRUE if operations must be output for modified files
			   only */
char OptY = FALSE;	/* TRUE if operations must be output for all files */
char OptB = FALSE;	/* TRUE if backup commands must be output for modified
			   files only. Modification check is done on archive
			   attribute */
char OptL = FALSE;	/* TRUE if backup commands must be output for all
			   files */
char OptA = FALSE;	/* TRUE if modification check of /x must be done on the
			   archive attribute instead of comparing file times.
			   Can never be specified without option /x */
char OptMX = FALSE;	/* TRUE if modification check of /x must be done on the
			   archive attribute - instead of comparing file times
			   - and the archive attribute must be reset after */
char OptMB = FALSE;	/* TRUE if archive attribute must be reset after the
			   modification check of /b */
char OptT = FALSE;	/* TRUE if modification check of /b must be done by
			   comparing file times instead of checking the
			   archive attribute. Must always be used with the /b
			   option */
char OptXB = ' ';       /* - X: first output operations, secondly output backup
			   commands
			   - B: first output backup commands, secondly output
			   operations
			   - other: means /x and /b are NOT both specified */


/*--- Ealloc() ---------------------------------------------------------------
ù function: terminate with error code on error with alloc()
ù input:    alloc-pointer for nbytes */

char *Ealloc(nbytes)
size_t nbytes;
{
   char *cpi;

   if ((cpi = alloc(nbytes)) == NULL)
      MError(1, 0);
   return(cpi);
}


/*--- MError() ---------------------------------------------------------------
ù function: exit program with error string output
ù input:    error specie, error number
ù ouput:    error string to the standard output */

char *ErrAr[] = {				       /* 0: Argument errors */
   "invalid option",
   "option /B and /L both specified",
   "invalid macro name",
   "filename expected as first parameter",
   "option /A without option /X specified",
   "option /X and /Y both specified",
   "backup drive/path not specified",
   "makefile twice specified",
   "option /T without option /B specified",
   "option /M without option /B or /X specified",
   "makefile not specified"
};
char *ErrMe[] = {			    /* 1: Memory and internal errors */
   "not enough memory",
   "SDMbase switch unknown",
   "SDMoperation switch unknown",
   "SDMstring switch unknown",
   "SDMslave switch unknown"
};
char *ErrTr[] = {					   /* 2: Tree errors */
   "node already exists"
};
char *ErrMf[] = {				       /* 3: Makefile errors */
   "spill character used in middle of line",
   "invalid filename character",
   "filename too long",
   "no master defined",
   "line too long",
   "inconsistent relation; master already defined as slave",
   "unexpected end of macro keyword",
   "undefined macro keyword",
   "syntax error",
   "invalid filename"
};
char *ErrDs[] = {					/* 5: DOS file errors */
   "file %s not found",
   "error closing file %s"
};

VOID MError(species, number)
int species, number;
{
   char ErrStr[80];

   switch(species) {
   case 0:	/* Switch errors */
      strcpy(ErrStr, ErrAr[number]);
      break;
   case 1:	/* Memory errors */
      strcpy(ErrStr, ErrMe[number]);
      break;
   case 2:	/* Tree errors */
      strcpy(ErrStr, ErrTr[number]);
      break;
   case 3:	/* Makefile errors */
      sprintf(ErrStr, "line %d column %d: ", mfln, (int) mfcl);
      strcat(ErrStr, ErrMf[number]);
      break;
   case 5:	/* DOS file errors */
      sprintf(ErrStr, ErrDs[number], ErrFile);
      break;
   }
   fputs(ErrStr, stderr);
   fputs("\n", stderr);
   exit(1);
}





