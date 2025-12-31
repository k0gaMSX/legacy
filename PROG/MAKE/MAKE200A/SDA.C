/*--- SDA.C ------------------------------------------------------------------
State Diagnose Arguments
Include file for MAKE.COM, The MSX Maniac, 17-Dec-1994
*/


#include <stdio.h>
#include "sda.h"
#include "macro.h"
#include "error.h"

/* #define DEBUGSDA */

VOID *SDAbase();
VOID *SDAdrivespec();
VOID *SDAmacro();
VOID *SDAmakefile();
VOID *SDAoption();
VOID *SDAstring();

int  argcPublic;
char **argvPublic;

char OptM = FALSE;	/* Temporary storage of the /m option; results in
			   either OptMX or OptMB being TRUE */
VOID *((*SDAfunction)());   /* pointer to SDA function returning pointer to
			       void; must be initialized to SDAbase()! */
char *SDApargv; 	/* SDA pointer to argument vector string */
char *SDAtbuf;		/* dynamically allocated SDA Temporary buffer */
char *SDAptbuf; 	/* pointer to SDAtbuf (temporary buffer) */


/*--- SDAbase() --------------------------------------------------------------
ù function: get argument string
ù input:    argc/argv
ù return:   SDAfunction */

VOID *SDAbase() {

#ifdef DEBUGSDA
   puts("SDAbase\n");
#endif

   while (--argcPublic > 0) {

#ifdef DEBUGSDA
      printf("\targcPublic: %d\n", argcPublic);
#endif

      while (*++argvPublic) {	       /* get next argument vector */

#ifdef DEBUGSDA
	 printf("\targvPublic: %s\n", *argvPublic);
#endif

	 switch (*(SDApargv = *argvPublic)) {
	 case '\x20' :
	    SDApargv++;
	    return((VOID *) SDAbase);
	    break;
	 case '/' :
	    return((VOID *) SDAoption);
	    break;
	 default :
	    return((VOID *) SDAstring);
	    break;
	 }
      }
   }
   return(NULL);
}


/*--- SDAdrivespec() ---------------------------------------------------------
ù function: get drive/path/file specification for backup
ù input:    none
ù return:   SDAfunction */

VOID *SDAdrivespec() {

#ifdef DEBUGSDA
   puts("SDAdrivespec\n");
#endif

   *(SDAptbuf = SDAtbuf) = '\0';
   while(*SDApargv && *SDApargv != '/')
      *SDAptbuf++ = *SDApargv++;
   if (SDAptbuf == SDAtbuf)
      MError(0, 6);
   *SDAptbuf = '\0';

#ifdef DEBUGSDA
   printf("\tSDAtbuf: %s\n", SDAtbuf);
#endif

   strcpy(dpf = (char **) Ealloc(strlen(SDAtbuf) + 1), SDAtbuf);
   switch(*SDApargv) {
   case '\0':
      return((VOID *) SDAbase);
      break;
   default:
      return((VOID *) SDAoption);
      break;
   }
}


/*--- SDAmacro ---------------------------------------------------------------
ù function: store macro from argument string
ù input:    extern buffer SDAtbuf contains macro keyword, extern variable
	    SDApargv points to argument (macro) string
ù return:   SDAfunction */

VOID *SDAmacro() {

#ifdef DEBUGSDA
   puts("SDAmacro\n");
#endif

   ChainMacro(SDAtbuf, SDApargv);
   return((VOID *) SDAbase);
}


/*--- SDAmakefile ------------------------------------------------------------
ù function: store makefile from argument string
ù input:    none
ù return:   SDAfunction */

VOID *SDAmakefile() {

#ifdef DEBUGSDA
   puts("SDAmakefile\n");
#endif

   if (makefile != NULL)
      MError(0, 7);
   makefile = Ealloc(strlen(SDAtbuf) + 1);
   strcpy(makefile, SDAtbuf);

#ifdef DEBUGSDA
   printf("\tMakefile: %s\n", makefile);
#endif

   return((VOID *) SDAbase);
}


/*--- SDAmanager() -----------------------------------------------------------
ù function: provide argument-characters-eating-functions with argument strings
	    and perform overall argument check
ù input:    none
ù return:   none */

VOID SDAmanager() {

#ifdef DEBUGSDA
   puts("SDAmanager\n");
#endif

   SDAtbuf = Ealloc((size_t) 256);
   SDAfunction = SDAbase;
		/* Call subsequent SDAfunctions untill one returns NULL */
   while (SDAfunction = (VOID *(*)()) (*SDAfunction)()) {

#ifdef DEBUGSDA
      printf("\tSDAfunction returns: $%4X\n", SDAfunction);
#endif

   }

   free(SDAtbuf);

      /* Perform overall argument check */

   if (OptT && OptB == FALSE)
      MError(0, 8);
   if (OptA && OptX == FALSE)
      MError(0, 4);

#ifdef DEBUGSDA
      printf("\tOptXB: %c\n", OptXB);
#endif

   if (OptM) {
      switch(OptXB) {
      case 'X' :
	 OptMX = TRUE;
	 break;
      case 'B' :
	 OptMB = TRUE;
	 break;
      default :
	 if (OptB == FALSE && OptX == FALSE)
	    MError(0, 9);
	 if (OptB)
	    OptMB = TRUE;
	 else
	    OptMX = TRUE;
	 break;
      }
   }
}


/*--- SDAoption() ------------------------------------------------------------
ù function: Get option from argument string
ù input:    none
ù return:   SDAfunction */

VOID *SDAoption() {

#ifdef DEBUGSDA
   puts("SDAoption\n");
#endif

   while (*SDApargv++) {
      switch(toupper(*SDApargv)) {
      case 'B':
	 OptB = (OptL) ? MError(0, 1) : TRUE;
	 OptXB = (OptX || OptY) ? 'X' : ' ';
	 SDApargv++;
	 return((VOID *) SDAdrivespec);
	 break;
      case 'L':
	 OptL = (OptB) ? MError(0, 1) : TRUE;
	 OptXB = (OptX || OptY) ? 'X' : ' ';
	 SDApargv++;
	 return((VOID *) SDAdrivespec);
	 break;
      case 'X':
	 OptX = (OptY) ? MError(0, 5) : TRUE;
	 OptXB = (OptL || OptB) ? 'B' : ' ';
	 break;
      case 'Y':
	 OptY = (OptX) ? MError(0, 5) : TRUE;
	 OptXB = (OptL || OptB) ? 'B' : ' ';
	 break;
      case 'A':
	 OptA = TRUE;
	 break;
      case 'M':
	 OptM = TRUE;
	 break;
      case 'T':
	 OptT = TRUE;
	 break;
      case '/':
	 break;
      case '\0':
	 return((VOID *) SDAbase);
	 break;
      default:
	 MError(0, 0);
	 break;
      }
   }
   return((VOID *) SDAbase);
}


/*--- SDAstring() ------------------------------------------------------------
ù function: get string from argument string
ù input:    none
ù return:   SDAfunction */

VOID *SDAstring() {

#ifdef DEBUGSDA
   puts("SDAstring\n");
#endif
   *(SDAptbuf = SDAtbuf) = '\0';
   while (*SDApargv && *SDApargv != '=')
      *SDAptbuf++ = *SDApargv++;
   *SDAptbuf = '\0';

   switch(*SDApargv) {
   case '=':
      if (!strlen(SDAtbuf))
	 MError(0,2);
      SDApargv++;
      return((VOID *) SDAmacro);
      break;
   default:
      return((VOID *) SDAmakefile);
      break;
   }
}
