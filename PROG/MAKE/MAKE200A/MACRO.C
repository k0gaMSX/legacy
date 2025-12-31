/*--- MACRO.C ----------------------------------------------------------------
Macro routines
Include file for MAKE.COM, The MSX Maniac, 8-Apr-1995 */


#include <stdio.h>
#include "macro.h"
#include "error.h"

#define MACROKEYWORDSIZE  64	/* maximum size of macro keywords */

/* #define DEBUGMACRO */

VOID EasyMacro();
BOOL MacParse();
VOID MacReplace();

/*------------------------------------------------------------- Variables ---*/
char **MACtbuf; 	/* Macro Temporary buffer */
BOOL macromf = FALSE;	/* TRUE if 'makefile'-input from MacStr, FALSE if
			   input from makefile */

/*--- ChainMacro() -----------------------------------------------------------
ù function: chain macro
ù input:    pointer to macro keyword (MacKey), pointer to macro string (MacStr)
ù output:   filled easy variables
ù return:   none */

VOID ChainMacro(MacKey, MacStr)
char *MacKey, *MacStr;
{

#ifdef DEBUGMACRO
   puts("ChainMacro\n");
#endif

   if (GetMacroString(MacKey)) {
      free(m_str);

#ifdef DEBUGMACRO
       puts("\tMacro keyword found.\n");
#endif

   }
   else {		 /* Chain new macro */

#ifdef DEBUGMACRO
      puts("\tMacro keyword not found.\n");
#endif

      EasyMacro(m_row->MacNxt = (MacRow *) Ealloc(sizeof(struct MacRow)));
      m_row->MacNxt = NULL;		/* Terminate macro chain */
      strcpy(m_row->MacKey = Ealloc(strlen(MacKey) + 1), MacKey);
   }
   strcpy(m_row->MacStr = Ealloc(strlen(MacStr) + 1), MacStr);

#ifdef DEBUGMACRO
   printf("\tMacRow: $%4X\n", (char *) m_row);
   printf("\tMacKey: %s\n", m_row->MacKey);
   printf("\tMacStr: %s\n", m_row->MacStr);
#endif

}

/*--- EasyMacro() ------------------------------------------------------------
ù function: fill easy variables with macro data
ù input:    pointer to macro structure
ù output:   filled easy variables
ù return:   none */

VOID EasyMacro(MacPointer)
MacRow *MacPointer;
{
   m_row = MacPointer;
   m_key = MacPointer->MacKey;
   m_str = MacPointer->MacStr;
   m_nxt = MacPointer->MacNxt;
}


/*--- GetMacroString() -------------------------------------------------------
ù function: Get macro string
ù input:    pointer to macro keyword
ù return:   pointer to macro string, NULL if macro not found */

char *GetMacroString(MacKey)
char *MacKey;
{

#ifdef DEBUGMACRO
   puts("GetMacroString\n");
#endif

   m_nxt = &MacBase;
   do {
      EasyMacro(m_nxt);

#ifdef DEBUGMACRO
      printf("\tComparing %s <-> %s\n", MacKey, m_key);
#endif

      if (strcmp(MacKey, m_key) == 0)
	 return (m_str);
   } while (m_nxt);
   return (NULL);
}


/*--- MacInit() --------------------------------------------------------------
ù function: Initialise macro routines */

VOID MacInit() {
				/* temporary buffer for macro keyword */
   MACtbuf = (char **) Ealloc((size_t) MACROKEYWORDSIZE);
}


/*--- MacParse() -------------------------------------------------------------
ù function: Parse string MacStr recursive into macro keywords
ù input:    First character (relative position from start of string) of
	    keyword to parse
ù output:   MACtbuf contains macro keyword as ASCIIZ string
ù return:   YES if macro keyword replaced, NO if not */


recursive BOOL MacParse(FirstChar)
int  FirstChar;     /* FirstChar points to first character of macro keyword */
{
   char ci;
   char mcchar;
   int ii;
   BOOL replaced = FALSE;

#ifdef DEBUGMACRO
   puts("MacParse\n");
#endif

   ii = FirstChar;
   ci = 0;				/* for MACtbuf */
   while(TRUE) {
      mcchar = MacStr[ii++];
      switch(mcchar) {
      case '\0':
      case '\n':
      case ' ':
      case '\t':
	 MError(3, 6);
	 break;
      case ')':
	 replaced = TRUE;
	 MacReplace(FirstChar);
	 return;
	 break;
      case '$':
	 if (MacStr[ii] == '(') {         /* '$(' ? */
	    MacParse(++ii);		     /* Yes.. parse macro keyword */
	    break;
	 }

	 /* No.. (just '$'); store '$' via the default option so leave this
	    case just above the 'default' case with no 'break' statement! */

      default:				  /* Store macro keyword */
	 (*MACtbuf)[ci++] = mcchar;
	 (*MACtbuf)[ci] = '\0';
	 break;
      }
   }
   return(replaced);
}


/*--- MacProcess(string) -----------------------------------------------------
ù function: replace (nested) macrokeyword(s) with macro string(s)
ù input:    address of pointer to string
ù output:   pointer points to completed string
ù return:   YES if macro keywords replaced, NO if not
ù note:     Nesting continues just as long each macro keyword has been
	    processed by a (recursive) call to MacReplace(). */

BOOL MacProcess(string)
char **string;
{
   int	ci = 0;       /* relative position in MacStr */
   char mcchar;
   BOOL replaced = FALSE;

   MacStr = *string;

#ifdef DEBUGMACRO
   puts("MacProcess\n");
   printf("\tMacStr contains: %s\n", MacStr);
#endif
   mcchar = MacStr[ci++];
   while(mcchar != '\0' && mcchar != '\n') {
      if (mcchar == '$') {
	 if (MacStr[ci] == '(') {       /* "$(" ? */
	    replaced = MacParse(++ci);
	    ci = 0;			/* Start searching all over again to
					   detect nested macro definitions */
	 }
      }
      mcchar = MacStr[ci++];
   }
   *string = MacStr;
   return(replaced);
}


/*--- MacReplace() -----------------------------------------------------------
ù function: replace macro keyword included in MacStr with macro string
ù input:    start position of macro keyword in MacStr, MACtbuf contains macro
	    keyword
ù output:   newly allocated MacStr with macro keyword replaced by macro string
ù return:   none */

VOID MacReplace(FirstChar)
int FirstChar;
{
   char *Mac2Str;		/* pointer to newly allocated MacStr */
   char *cip;

#ifdef DEBUGMACRO
   puts("MacReplace\n");
#endif

   if (cip = GetMacroString(*MACtbuf)) {

#ifdef DEBUGMACRO
   printf("\tFound macro string: %s\n", cip);
#endif

	 /* len(string) - len(keyword) - len("$()") + len(macro string) +
	    len('\0') */
      Mac2Str = Ealloc(strlen(MacStr) - strlen(*MACtbuf) - 3 + strlen(cip) + 1);

	 /* copy string untill keyword: len(pos(Firstchar) - len("$(") */
      strncpy(Mac2Str, MacStr, FirstChar - 2);
      Mac2Str[FirstChar - 2] = '\0';

#ifdef DEBUGMACRO
   printf("\t%d Characters have been copied, so Mac2Str contains first part:\
\n\t\t %s\n", FirstChar - 2, Mac2Str);
#endif

	 /* concatenate */
      strcat(Mac2Str, cip);

#ifdef DEBUGMACRO
   printf("\tMac2Str contains also macro string: %s\n");
#endif

      strcat(Mac2Str, MacStr + FirstChar + 1 + strlen(*MACtbuf));
      free(MacStr);
      MacStr = Mac2Str;

#ifdef DEBUGMACRO
   printf("\tMacStr contains: %s\n", MacStr);
#endif

   }
   else
      MError(3, 7);
}
