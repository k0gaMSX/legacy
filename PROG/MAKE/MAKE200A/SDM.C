/*--- SDM.C ------------------------------------------------------------------
State Diagnose Makefile
Include file for MAKE.COM, The MSX Maniac, May-1994 */


#include <stdio.h>
#include "sdm.h"
#include "macro.h"
#include "main.h"
#include "error.h"


STATUS _ffirst();		/* MSX-C internal function (CLIBMAC.MAC) */
char   *_p_path();		/* MSX-C internal function (CLIBMAC.MAC) */

#define  MFEXT	       ".MF"     /* default makefile extension */
   /* maximum size of mf lines */
#define  MFLINELENGTH  (size_t) 256

/*
   /* nunits (used by alloc() and free()) of MFLINELENGTH */
#define  MFLINENUNITS  (1+(MFLINELENGTH + sizeof(HEADER) - 1)/sizeof(HEADER))
*/


#define  COMMC	       '#'       /* default comment character */
#define  SPILLC1       '\\'      /* default spill character */
#define  SPILLC2       '/'       /* default spill character */

/* #define DEBUGSDM */

char RdChMf();
char *RdLnMf();
VOID *SDMbase();
VOID *SDMcomment();
VOID *SDMground();
VOID *SDMmacro();
VOID *SDMmaster();
VOID *SDMoperation();
VOID *SDMslave();
VOID *SDMspill();
VOID *SDMstring();
VOID *SDMsubstitute();
char SkipMfSpace();
VOID UnRdChMf();

/*------------------------------------------------------------- Variables ---*/
BOOL macroded;		/* internal variable for functions to keep track if
			   input is being taken from MacStr (TRUE) */
FILE *MF;		/* Makefile */
char mfchar;		/* current character from makefile */
int  mfNunits;		/* nunits of SDMtbuf (as used by alloc() & free()) */
char *pidpf;		/* pointer to part of drive/path/file ASCIIZ string */
VOID *((*SDMfunction)()); /* pointer to SDM function returning pointer to void;
			     must be initialized to SDAbase()! */
char *SDMobuf;		/* dynamically allocated SDM Operation buffer */
char *SDMpobuf; 	/* pointer to SDMobuf (operation buffer) */
char *SDMsbuf;		/* dynamically allocated SDM String buffer */
char *SDMpsbuf; 	/* pointer to SDMsbuf (string buffer) */
char *SDMtbuf;		/* dynamically allocated SDM Temporary buffer */
char *SDMptbuf; 	/* pointer to SDMtbuf (temp buffer) */
char spill = '\0';      /* flowcontrol SDMbase */
BOOL usemf;		/* TRUE if using makefile, FALSE if using stdin */


/*--- Extension() ------------------------------------------------------------
ù function:  Check if filename extension is defined
ù input:     pointer to filename string
ù return:    TRUE if filename at least contains a '.' */

BOOL Extension(filename)
char *filename;
{
   while (*filename)
      if (*filename++ == '.')
	 return(TRUE);
   return(FALSE);
}


/*--- RdChMf() ---------------------------------------------------------------
ù function: Read character from SDMptbuf (makefile line or macro string)
ù return:   next character from SDMtbuf */

char RdChMf() {
   if ((int) ++mfcl > MFLINELENGTH)
      MError(4, 4);
   return(*SDMptbuf++);
}


/*--- RdLnMf() ---------------------------------------------------------------
ù function: Read line from makefile or stdin. Replace macro strings.
ù input:    - Global variable usemf = TRUE if input from makefile; FALSE if
	    if input from stdin.
ù return:   pointer to string; NULL if end of file or error occurs */

char *RdLnMf() {

#ifdef DEBUGSDM
   puts("RdLnMf\n");
#endif

   mfln++;

      /* If someone - e.g. MacProcess() - has changed the size of SDMtbuf,
	 resize it. Caution: sizeof is calculated in 'nunits'. */

   if (((HEADER *)SDMtbuf - 1)->s.size != mfNunits) {

#ifdef DEBUGSDM
      puts("\tSDMtbuf has been resized\n");
#endif

      free(SDMtbuf);
      SDMtbuf = Ealloc(MFLINELENGTH);
   }

#ifdef DEBUGSDM
   printf("\tReading line %d from makefile\n", mfln);
#endif

   mfcl = 0;
   if (usemf)
      return(fgets(SDMptbuf = SDMtbuf, MFLINELENGTH, MF));
   else
      return(gets(SDMptbuf = SDMtbuf, MFLINELENGTH));
}


/*--- SDMbase() --------------------------------------------------------------
ù function: get makefile line
ù return:   SDMfunction */

VOID *SDMbase() {
char *EOMF;		/* End Of MakeFile */

#ifdef DEBUGSDM
   puts("SDMbase\n");
#endif

   do { 				/* Process makefile untill EOF */
      EOMF = RdLnMf();

#ifdef DEBUGSDM
   printf("\tLine: %s", SDMptbuf);
#endif

	 switch(mfchar = RdChMf()) {
	 case COMMC:
	    return((VOID *) SDMcomment);
	    break;
	 case '\0':
	 case '\n':
	    break; /* Break to read next line */
	 default:
	    UnRdChMf();
	    MacProcess(&SDMptbuf);
	    return((VOID *) SDMground);
	    break;
	 }
   } while (EOMF);
   OBDeinit();
   return(NULL);
}


/*--- SDMcomment() -----------------------------------------------------------
ù function: process makefile comment
ù return:   pointer to SDMfunction */

VOID *SDMcomment() {

#ifdef DEBUGSDM
   puts("SDMcomment\n");
   puts(SDMptbuf);
#endif

   return((VOID *) SDMbase);
}


/*--- SDMground() ------------------------------------------------------------
ù function: Process makefile line
ù return:   SDMfunction */

VOID *SDMground() {

#ifdef DEBUGSDM
   puts("SDMground\n");
#endif

      switch(spill) {
      case '\0':
	 switch(mfchar = RdChMf()) {
	 case '\0':
	 case '\n':
	    return((VOID *) SDMbase);
	 case ' ':
	 case '\t':
	    return((VOID *) SDMoperation);
	    break;
	 default:

#ifdef DEBUGSDM
	    printf("\tdefault: mfchar = %c (0x%X)\n", mfchar, (int) mfchar);
#endif
	    UnRdChMf();
	    return((VOID *) SDMstring);
	    break;
	 }
	 break;
      case 'O':
	 return((VOID *) SDMoperation);
	 break;
      case 'F':
	 return((VOID *) SDMslave);
	 break;
      case 'M':
	 return((VOID *) SDMmacro);
	 break;
      default:
	 MError(1, 1);
	 break;
      }
   return(NULL);
}


/*--- SDMmacro() -------------------------------------------------------------
ù function: process makefile macro definition
ù return: pointer to SDMfunction */

VOID *SDMmacro() {

#ifdef DEBUGSDM
   puts("SDMmacro\n");
   puts(SDMptbuf);
#endif

   return((VOID *) SDMbase);
}


/*--- SDMmanager() -----------------------------------------------------------
ù function: provide makefile-characters-eating-functions with makefile
	    characters
ù input:    none
ù return:   none */

VOID SDMmanager() {

#ifdef DEBUGSDM
   puts("SDMmanager\n");
   printf("\tmakefile (%04X) from SDA: %s\n", makefile, makefile);
#endif

   if (makefile != NULL) {

      SDMobuf = Ealloc(MFLINELENGTH);
      SDMsbuf = Ealloc(MFLINELENGTH);
      SDMtbuf = Ealloc(MFLINELENGTH);
      mfNunits = 1 + (MFLINELENGTH + sizeof(HEADER) - 1) / sizeof(HEADER);

#ifdef DEBUGSDM
      printf("\tmakefile already with extension: %s\n", makefile);
#endif

      if (! Extension(makefile)) {
	 strcat(makefile, MFEXT);

#ifdef DEBUGSDM
	 printf("\tmakefile with MFEXT: %s\n", makefile);
#endif

      }
      if ((MF = fopen(makefile, "r")))
	 usemf = TRUE;
      else {
	 ErrFile = makefile;
	 MError(5, 0);
      }
   }
   else {				/* Search for makefile */
      if (_ffirst("*.MF", &MFIB, (TINY) 0) != OK)
	 MError(0, 10);
      makefile = MFIB.name;

#ifdef DEBUGSDM
      printf("\tMFIB.name (0x%04X) contains: %s\n", MFIB.name, MFIB.name);
      printf("\tmakefile found in current directory: %s\n", makefile);
#endif

      SDMmanager();		/* Start SDMmanager again, using makefile */
   }

   SDMfunction = SDMbase;
		/* Call subsequent SDMfunctions untill one returns NULL */
   while (SDMfunction = (VOID *(*)()) (*SDMfunction)()) {

#ifdef DEBUGSDM
   printf("\tSDMfunction returns: $%4X\n", SDMfunction);
#endif

   }
}


/*--- SDMmaster() ------------------------------------------------------------
ù function: process master filename from makefile
ù input:    SDMsbuf contains master filename
ù return:   pointer to SDMfunction */

VOID *SDMmaster() {

#ifdef DEBUGSDM
   printf("SDMmaster: %s\n", SDMsbuf);
#endif

   OBMaster(SDMsbuf);
   mfchar = SkipMfSpace();
   switch(mfchar) {
   case '\n':
   case '\0':
      return((VOID *) SDMbase);
      break;
   default:
      UnRdChMf();
      return((VOID *) SDMslave);
      break;
   }
}


/*--- SDMoperation() ---------------------------------------------------------
ù function: process makefile operation
ù return:   pointer to SDMfunction */

VOID *SDMoperation() {
   char mfchar;
   char *cpi, ci = 0;

#ifdef DEBUGSDM
   puts("SDMoperation\n");
#endif

   *(SDMpobuf = SDMobuf) = '\0';
   mfchar = SkipMfSpace();
   while (TRUE) {
      switch (mfchar) {
      case '\0':
	 OBOperation(SDMobuf);
	 return((VOID *) SDMbase);
	 break;
      case COMMC:
	 OBOperation(strcat(SDMobuf, "\n"));
	 return((VOID *) SDMcomment);
	 break;
      case SPILLC1:
      case SPILLC2:
	 cpi = SDMptbuf;		   /* Temporarily store SDMptbuf */
	 if (SkipMfSpace() == '\n') {
	    OBOperation(SDMobuf);
	    spill = 'O';
	    return((VOID *) SDMbase);
	    break;
	 }
	 else

	       /* Spill character isn't last character on line, so keep
		  processing operation characters */

	    SDMptbuf = cpi;	  /* Restore SDMptbuf & goto case default! */
      default:
	 *SDMpobuf++ = mfchar;
	 *SDMpobuf = '\0';
	 mfchar = RdChMf();
	 break;
      }
   }
}


/*--- SDMslave() -------------------------------------------------------------
ù function: process makefile slave
ù return:   pointer to SDMfunction */

VOID *SDMslave() {
   char mfchar;
   char ci = 0;

#ifdef DEBUGSDM
   puts("SDMslave\n");
#endif

   *(SDMpsbuf = SDMsbuf) = '\0';
   mfchar = SkipMfSpace();
   while (TRUE) {
      switch (mfchar) {
      case ' ':
	 OBSlave(SDMsbuf);
	 return((VOID *) SDMslave);
	 break;
      case '\0':
      case '\n':
	 OBSlave(SDMsbuf);
	 return((VOID *) SDMbase);
	 break;
      case '#':
	 return((VOID *) SDMbase);
	 break;
      case '\\':
      case '/':
	 OBSlave(SDMsbuf);
	 if (SkipMfSpace() == '\n') {
	    spill = 'F';
	    return((VOID *) SDMbase);
	    break;
	 }
	 else {
	    UnRdChMf(); 	   /* Unread character */
	    UnRdChMf(); 	   /* Unread spill character */
	 }
      default:
	 *SDMpsbuf++ = mfchar;
	 *SDMpsbuf = '\0';
	 mfchar = RdChMf();
	 break;
      }
   }
}


/*--- SDMstring() ------------------------------------------------------------
ù function: process makefile string
ù return:   pointer to SDMfunction */

VOID *SDMstring() {
   char mfchar;
   char ci = 0;

#ifdef DEBUGSDM
   puts("SDMstring\n");
#endif

   *(SDMpsbuf = SDMsbuf) = '\0';
   while (TRUE) {
      switch (mfchar = RdChMf()) {
      case ':':
	 return((VOID *) SDMmaster);
	 break;
      case '=':
	 return((VOID *) SDMmacro);
	 break;

/*	case '$':
	 return((VOID *) SDMsubstitute);
	 break;
*/

      case '\0':
      case '\n':
	 MError(3, 8);
	 break;
      default:
	 *SDMpsbuf++ = mfchar;
	 *SDMpsbuf = '\0';
	 break;
      }
   }
}



/* ... NESTING COMMENT ...
/*--- SDMsubstitute() --------------------------------------------------------
ù function: Substitute macro string
ù return:   pointer to SDMfunction */

VOID *SDMsubstitute() {

#ifdef DEBUGSDM
   puts("SDMsubstitute\n");
#endif

   MacStr = SDMptbuf;
   FillInMacroString();
   macromf = TRUE;
   return((VOID *) SDMbase);
}
... END OF NESTING COMMENT ... */



/*--- SkipMfSpace() ----------------------------------------------------------
ù function: Skip spaces in makefile line
ù return:   first non-space character from makefile line*/

char SkipMfSpace() {
   char mfchar;

   do {
      mfchar = RdChMf();
   } while (mfchar == ' ' || mfchar == '\t');
   return(mfchar);
}


/*--- UnRdChMf() -------------------------------------------------------------
ù function: Unread character from makefile line (SDMtbuf) or macro buffer
	    (MacStr) */

VOID UnRdChMf() {

#ifdef DEBUGSDM
   puts("UnRdChMf\n");
#endif

   SDMptbuf--;
   mfcl--;

#ifdef DEBUGSDM
   printf("\tSDMtbuf contains: %s\n", SDMtbuf);
   printf("\tSDMptbuf points to: %s\n", SDMptbuf);
#endif

}

