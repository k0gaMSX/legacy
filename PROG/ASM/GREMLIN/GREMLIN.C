/**************************************************************/
/*                                                            */
/*                          gremlin.c                         */
/*                                                            */
/*          ....    ....    .................     .....       */
/*          ....    ....   ...................   .....        */
/*         ------  ------ --------------------- -----         */
/*         ------  ------ ------           ---------          */
/*        ++++++++++++++++ ++++++++++++     +++++++           */
/*        ++++++++++++++++  ++++++++++++    +++++++           */
/*       ***** ****** *****        ******  *********          */
/*       ***** ****** ******************* ***** *****         */
/*      #####   ####   ################# #####   #####        */
/*      #####   ####   ################ #####     #####       */
/*                                                            */
/*              Gremlin: Z80 & R800 Disassembler              */
/*                                                            */
/*   Version Bianca-3-0 (2nd Ver., 4th Build, No Revision)    */
/*                                                            */
/*   This  is  the C source  file of "Gremlin: MSX Z80/R800   */
/*   Disassembler". This  program is `public domain', i.e.,   */
/*   anyone  may  modify  it,  as  needed  or  wanted,  and   */
/*   distribute without express  permission of its  author.   */
/*   It is, consequently, a `freeware', which means nothing   */
/*   can be charged  for it. If a modified version of it is   */
/*   sold commercially, this file MUST  be included  within   */
/*   the pack  and the customers explicitly  notified about   */
/*   its existence and contents. Thank  you all for reading   */
/*   and agreeing with this.                                  */
/*                                                            */
/*      This  file was  created, edited and  programmed       */
/*      in  1998-2004 by  Cyberknight Masao Kawata  for       */
/*      "Unicorn Dreams Artwork Programs". For contact:       */
/*                                                            */
/*       E-Mail    : cyberknight@myrealbox.com                */
/*                   cyberknight@gawab.com                    */
/*                   unicorndreams@gmail.com                  */
/*       Home Page : http://welcome.to/unicorndreams          */
/*                   http://unicorndreams.cjb.net             */
/*                                                            */
/*   Based on fMSX's "dasm.c" file, Japan MSX Magazine, the   */
/*   Brazilian  book "MSX - Linguagem de Maquina - Assembly   */
/*   Z80" (MSX Machine Language) by Rossini & Figueredo and   */
/*   the invaluable help of Ricardo Bittencourt.              */
/*                                                            */
/**************************************************************/

/* Libraries.                                                 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* Constants Definitions.                                     */

#define MaxLabelSiz        63


/* Flag Definitions                                           */

/* "Mode" flags:                                              */

#define UseR800OpCodes     (unsigned long) 0x00000001L
#define ShowAddresses      (unsigned long) 0x00000002L
#define Use8CharAddress    (unsigned long) 0x00000004L
#define ShowJROffset       (unsigned long) 0x00000008L
#define ShowOpCodes        (unsigned long) 0x00000010L
#define ShowCharacters     (unsigned long) 0x00000020L
#define ShowControlChar    (unsigned long) 0x00000040L
#define ShowCPUTimes       (unsigned long) 0x00000080L
#define AddWaitStates      (unsigned long) 0x00000100L
#define NoBreakAfterJmp    (unsigned long) 0x00000200L
#define LeadingZero        (unsigned long) 0x00000400L
#define CompactMode        (unsigned long) 0x00000800L
#define ShowUppercase      (unsigned long) 0x00001000L
#define CapitalizeLabels   (unsigned long) 0x00002000L
#define EndAddressSet      (unsigned long) 0x00004000L
#define LastByteSet        (unsigned long) 0x00008000L
#define DefinedLabels      (unsigned long) 0x00010000L
#define ShowAllLabels      (unsigned long) 0x00020000L
#define DiscardDefLabel    (unsigned long) 0x00040000L
#define GenerateLabels     (unsigned long) 0x00080000L
#define RemoveAmbiguity    (unsigned long) 0x00100000L


/* Label Status:                                              */

#define ByteLabel       (unsigned char) '\x01'
#define WordLabel       (unsigned char) '\x02'
#define LabelDefined    (unsigned char) '\x40'
#define LabelDisplayed  (unsigned char) '\x80'


/* Exit status codes:                                         */

#define Okay            0
#define UnknownOption   1
#define NotEnoughMem    2
#define FileNotFound    3
#define LabelTooLong    4
#define UnclosedLabel   5
#define BadNumericPar   6
#define SyntaxError     7
#define MissingPar      8


/* Global Variables and Structures.                           */

char
  *Gremlin[8]=
  { "Ruby","Emerald","Sapphire","Golden","Snowy","Sand","Fire","Flying"},
  *Version="Bianca-3-0";

struct
  Label
  { char
      *Name;
    unsigned int
      Value;
    unsigned char
      Status;
    struct Label
      *Next;
  };


/* Functions' Definitions.                                    */

struct Label
  *SearchLabelVal        /* Label Search Function.            */
  ( struct Label *LP,    /* Label Pointer.                    */
    int Value,           /* Search Value.                     */
    unsigned char ValTyp /* Search Status.                    */
  )
{ struct Label
    *APtr=LP;            /* Auxiliar Label Pointer.           */

  while ((APtr!=NULL)&&(((APtr->Status&'\x3F')!=ValTyp)||(APtr->Value<Value)))
    APtr=APtr->Next;

  if ((APtr!=NULL)&&((APtr->Status&'\x3F')==ValTyp)&&(APtr->Value==Value))
  { APtr->Status|=LabelDisplayed;
    return(APtr);
  }
  else
    return(NULL);
}


void
  AddAutoLabel           /* Add Auto-generated Label.         */
  ( struct Label *Head,  /* Label List Head.                  */
    unsigned int Address /* Label Address.                    */
  )
{ struct Label
    *NPtr,               /* New Label Pointer.                */
    *APtr;               /* Auxiliar Label Pointer.           */

  if (Head->Next!=NULL)
    if (Head->Next->Value>Address)
    { if ((NPtr=(struct Label *)malloc(sizeof(struct Label)))==NULL)
      { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
        exit(NotEnoughMem);
      }

      if ((NPtr->Name=(char *)malloc(strlen(Head->Name)+5))==NULL)
      { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
        exit(NotEnoughMem);
      }

      sprintf(NPtr->Name,"%s%04X",Head->Name,Address);
      NPtr->Value=Address;
      NPtr->Status=WordLabel;
      NPtr->Next=Head->Next;
      Head->Next=NPtr;
    }
    else
    { APtr=Head->Next;

      while ((APtr->Next!=NULL)&&((APtr->Next->Status&'\x3F')<=WordLabel)&&(APtr->Next->Value<Address))
        APtr=APtr->Next;

      if (!(((APtr->Next->Status&'\x3F')==WordLabel)&&(APtr->Next->Value==Address)))
      { if ((NPtr=(struct Label *)malloc(sizeof(struct Label)))==NULL)
        { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
          exit(NotEnoughMem);
        }

        if ((NPtr->Name=(char *)malloc(strlen(Head->Name)+5))==NULL)
        { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
          exit(NotEnoughMem);
        }

        sprintf(NPtr->Name,"%s%04X",Head->Name,Address);
        NPtr->Value=Address;
        NPtr->Status=WordLabel;
        NPtr->Next=APtr->Next;
        APtr->Next=NPtr;
      }
    }
  else
  { if ((NPtr=(struct Label *)malloc(sizeof(struct Label)))==NULL)
    { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
      exit(NotEnoughMem);
    }

    if ((NPtr->Name=(char *)malloc(strlen(Head->Name)+5))==NULL)
    { fprintf(stderr,"The Unicorn couldn't make room enough to generate automatic labels.\n");
      exit(NotEnoughMem);
    }

    sprintf(NPtr->Name,"%s%04X",Head->Name,Address);
    NPtr->Value=Address;
    NPtr->Status=WordLabel;
    NPtr->Next=NULL;
    Head->Next=NPtr;
  }

  fprintf(stderr,".");
}


unsigned int
  MDA                           /* MSX Disassembler Function. */
  ( unsigned char *St,          /* Mnemonic String.           */
    unsigned char *DataBuf,     /* File Data Buffer.          */
    unsigned long AddBase,      /* Address Base.              */
    unsigned long *Mode,        /* Mode Flags.                */
    struct Label *LP,           /* Label Pointer.             */
    char *TimeTable             /* Instruction Time Table.    */
  )
{ /* Definition of the  Instruction Sets  and Time Tables for */
  /* Z80 and R800  processors: the  tabulation  spaces of the */
  /* double quotes are for  visual purposes  only, but  those */
  /* inside are part of the mnemonic.                         */


  /* Basic Sets.                                              */

  char
    *Z80[256]=
    { "nop",        "ld   bc,#",  "ld   (bc),a","inc  bc",     "inc  b",     "dec  b",     "ld   b,*",   "rlca",       "ex   af,af'","add  hl,bc", "ld   a,(bc)","dec  bc",   "inc  c",   "dec  c",  "ld   c,*",   "rrca",
      "djnz @",     "ld   de,#",  "ld   (de),a","inc  de",     "inc  d",     "dec  d",     "ld   d,*",   "rla",        "jr   @\n",   "add  hl,de", "ld   a,(de)","dec  de",   "inc  e",   "dec  e",  "ld   e,*",   "rra",
      "jr   nz,@",  "ld   hl,#",  "ld   (#),hl","inc  hl",     "inc  h",     "dec  h",     "ld   h,*",   "daa",        "jr   z,@",   "add  hl,hl", "ld   hl,(#)","dec  hl",   "inc  l",   "dec  l",  "ld   l,*",   "cpl",
      "jr   nc,@",  "ld   sp,#",  "ld   (#),a", "inc  sp",     "inc  (hl)",  "dec  (hl)",  "ld   (hl),*","scf",        "jr   c,@",   "add  hl,sp", "ld   a,(#)", "dec  sp",   "inc  a",   "dec  a",  "ld   a,*",   "ccf",
      "ld   b,b",   "ld   b,c",   "ld   b,d",   "ld   b,e",    "ld   b,h",   "ld   b,l",   "ld   b,(hl)","ld   b,a",   "ld   c,b",   "ld   c,c",   "ld   c,d",   "ld   c,e",  "ld   c,h", "ld   c,l","ld   c,(hl)","ld   c,a",
      "ld   d,b",   "ld   d,c",   "ld   d,d",   "ld   d,e",    "ld   d,h",   "ld   d,l",   "ld   d,(hl)","ld   d,a",   "ld   e,b",   "ld   e,c",   "ld   e,d",   "ld   e,e",  "ld   e,h", "ld   e,l","ld   e,(hl)","ld   e,a",
      "ld   h,b",   "ld   h,c",   "ld   h,d",   "ld   h,e",    "ld   h,h",   "ld   h,l",   "ld   h,(hl)","ld   h,a",   "ld   l,b",   "ld   l,c",   "ld   l,d",   "ld   l,e",  "ld   l,h", "ld   l,l","ld   l,(hl)","ld   l,a",
      "ld   (hl),b","ld   (hl),c","ld   (hl),d","ld   (hl),e", "ld   (hl),h","ld   (hl),l","halt",       "ld   (hl),a","ld   a,b",   "ld   a,c",   "ld   a,d",   "ld   a,e",  "ld   a,h", "ld   a,l","ld   a,(hl)","ld   a,a",
      "add  a,b",   "add  a,c",   "add  a,d",   "add  a,e",    "add  a,h",   "add  a,l",   "add  a,(hl)","add  a,a",   "adc  a,b",   "adc  a,c",   "adc  a,d",   "adc  a,e",  "adc  a,h", "adc  a,l","adc  a,(hl)","adc  a,a",
      "sub  b",     "sub  c",     "sub  d",     "sub  e",      "sub  h",     "sub  l",     "sub  (hl)",  "sub  a",     "sbc  a,b",   "sbc  a,c",   "sbc  a,d",   "sbc  a,e",  "sbc  a,h", "sbc  a,l","sbc  a,(hl)","sbc  a,a",
      "and  b",     "and  c",     "and  d",     "and  e",      "and  h",     "and  l",     "and  (hl)",  "and  a",     "xor  b",     "xor  c",     "xor  d",     "xor  e",    "xor  h",   "xor  l",  "xor  (hl)",  "xor  a",
      "or   b",     "or   c",     "or   d",     "or   e",      "or   h",     "or   l",     "or   (hl)",  "or   a",     "cp   b",     "cp   c",     "cp   d",     "cp   e",    "cp   h",   "cp   l",  "cp   (hl)",  "cp   a",
      "ret  nz",    "pop  bc",    "jp   nz,#",  "jp   #\n",    "call nz,#",  "push bc",    "add  a,*",   "rst  &00H",  "ret  z",     "ret\n",      "jp   z,#",   "?ERROR",    "call z,#", "call #",  "adc  a,*",   "rst  &08H",
      "ret  nc",    "pop  de",    "jp   nc,#",  "out  (*),a",  "call nc,#",  "push de",    "sub  *",     "rst  &10H",  "ret  c",     "exx",        "jp   c,#",   "in   a,(*)","call c,#", "?ERROR",  "sbc  a,*",   "rst  &18H",
      "ret  po",    "pop  hl",    "jp   po,#",  "ex   (sp),hl","call po,#",  "push hl",    "and  *",     "rst  &20H",  "ret  pe",    "jp   (hl)\n","jp   pe,#",  "ex   de,hl","call pe,#","?ERROR",  "xor  *",     "rst  &28H",
      "ret  p",     "pop  af",    "jp   p,#",   "di",          "call p,#",   "push af",    "or   *",     "rst  &30H",  "ret  m",     "ld   sp,hl", "jp   m,#",   "ei",        "call m,#", "?ERROR",  "cp   *",     "rst  &38H"},

    *R800[256]=
    { "nop",           "ld    .bc,#",   "ld    [.bc],.a","inc   .bc",      "inc   .b",      "dec   .b",      "ld    .b,*",    "rola",          "xch   .af,.af'","add   .hl,.bc","ld    .a,[.bc]","dec   .bc",    "inc   .c",   "dec   .c",   "ld    .c,*",    "rora",
      "dbnz  @",       "ld    .de,#",   "ld    [.de],.a","inc   .de",      "inc   .d",      "dec   .d",      "ld    .d,*",    "rolca",         "short br @\n",  "add   .hl,.de","ld    .a,[.de]","dec   .de",    "inc   .e",   "dec   .e",   "ld    .e,*",    "rorca",
      "short bnz @",   "ld    .hl,#",   "ld    [#],.hl", "inc   .hl",      "inc   .h",      "dec   .h",      "ld    .h,*",    "adj   .a",      "short bz @",    "add   .hl,.hl","ld    .hl,[#]", "dec   .hl",    "inc   .l",   "dec   .l",   "ld    .l,*",    "not   .a",
      "short bnc @",   "ld    .sp,#",   "ld    [#],.a", "inc   .sp",       "inc   [.hl]",   "dec   [.hl]",   "ld    [.hl],*", "setc",          "short bc @",    "add   .hl,.sp","ld    .a,[#]",  "dec   .sp",    "inc   .a",   "dec   .a",   "ld    .a,*",    "notc",
      "ld    .b,.b",   "ld    .b,.c",   "ld    .b,.d",   "ld    .b,.e",    "ld    .b,.h",   "ld    .b,.l",   "ld    .b,[.hl]","ld    .b,.a",   "ld    .c,.b",   "ld    .c,.c",  "ld    .c,.d",   "ld    .c,.e",  "ld    .c,.h","ld    .c,.l","ld    .c,[.hl]","ld    .c,.a",
      "ld    .d,.b",   "ld    .d,.c",   "ld    .d,.d",   "ld    .d,.e",    "ld    .d,.h",   "ld    .d,.l",   "ld    .d,[.hl]","ld    .d,.a",   "ld    .e,.b",   "ld    .e,.c",  "ld    .e,.d",   "ld    .e,.e",  "ld    .e,.h","ld    .e,.l","ld    .e,[.hl]","ld    .e,.a",
      "ld    .h,.b",   "ld    .h,.c",   "ld    .h,.d",   "ld    .h,.e",    "ld    .h,.h",   "ld    .h,.l",   "ld    .h,[.hl]","ld    .h,.a",   "ld    .l,.b",   "ld    .l,.c",  "ld    .l,.d",   "ld    .l,.e",  "ld    .l,.h","ld    .l,.l","ld    .l,[.hl]","ld    .l,.a",
      "ld    [.hl],.b","ld    [.hl],.c","ld    [.hl],.d","ld    [.hl],.e", "ld    [.hl],.h","ld    [.hl],.l","halt",          "ld    [.hl],.a","ld    .a,.b",   "ld    .a,.c",  "ld    .a,.d",   "ld    .a,.e",  "ld    .a,.h","ld    .a,.l","ld    .a,[.hl]","ld    .a,.a",
      "add   .a,.b",   "add   .a,.c",   "add   .a,.d",   "add   .a,.e",    "add   .a,.h",   "add   .a,.l",   "add   .a,[.hl]","add   .a,.a",   "addc  .a,.b",   "addc  .a,.c",  "addc  .a,.d",   "addc  .a,.e",  "addc  .a,.h","addc  .a,.l","addc  .a,[.hl]","addc  .a,.a",
      "sub   .a,.b",   "sub   .a,.c",   "sub   .a,.d",   "sub   .a,.e",    "sub   .a,.h",   "sub   .a,.l",   "sub   .a,[.hl]","sub   .a,.a",   "subc  .a,.b",   "subc  .a,.c",  "subc  .a,.d",   "subc  .a,.e",  "subc  .a,.h","subc  .a,.l","subc  .a,[.hl]","subc  .a,.a",
      "and   .a,.b",   "and   .a,.c",   "and   .a,.d",   "and   .a,.e",    "and   .a,.h",   "and   .a,.l",   "and   .a,[.hl]","and   .a,.a",   "xor   .a,.b",   "xor   .a,.c",  "xor   .a,.d",   "xor   .a,.e",  "xor   .a,.h","xor   .a,.l","xor   .a,[.hl]","xor   .a,.a",
      "or    .a,.b",   "or    .a,.c",   "or    .a,.d",   "or    .a,.e",    "or    .a,.h",   "or    .a,.l",   "or    .a,[.hl]","or    .a,.a",   "cmp   .a,.b",   "cmp   .a,.c",  "cmp   .a,.d",   "cmp   .a,.e",  "cmp   .a,.h","cmp   .a,.l","cmp   .a,[.hl]","cmp   .a,.a",
      "ret   nz",      "pop   .bc",     "bnz   #",       "br    #\n",      "call  nz,#",    "push  .bc",     "add   .a,*",    "brk   &00H",    "ret   z",       "ret\n",        "bz    #",       "?ERROR",       "call  z,#",  "call  #",    "addc  .a,*",    "brk   &08H",
      "ret   nc",      "pop   .de",     "bnc   #",       "out   [*],.a",   "call  nc,#",    "push  .de",     "sub   .a,*",    "brk   &10H",    "ret   c",       "xchx",         "bc    #",       "in    .a,[*]", "call  c,#",  "?ERROR",     "subc  .a,*",    "brk   &18H",
      "ret   po",      "pop   .hl",     "bpo   #",       "xch   [.sp],.hl","call  po,#",    "push  .hl",     "and   .a,*",    "brk   &20H",    "ret   pe",      "br    [.hl]\n","bpe   #",       "xch   .de,.hl","call  pe,#", "?ERROR",     "xor   .a,*",    "brk   &28H",
      "ret   p",       "pop   .af",     "bp    #",       "di",             "call  p,#",     "push  .af",     "or    .a,*",    "brk   &30H",    "ret   m",       "ld    .sp,.hl","bm    #",       "ei",           "call  m,#",  "?ERROR",     "cmp   .a,*",    "brk   &38H"},

    *TZ80R800[256]=
    { "\x04\x04\x01\x01\x01","\x0A\x0A\x01\x03\x03","\x07\x07\x01\x02\x02","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x0B\x0B\x01\x01\x01","\x07\x07\x01\x02\x02","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\xF3\xF8\x01\xFE\xFE","\x0A\x0A\x01\x03\x03","\x07\x07\x01\x02\x02","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\xF4\x0C\x01\xFD\x03","\x0B\x0B\x01\x01\x01","\x07\x07\x01\x02\x02","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\xF4\xF9\x01\xFD\xFE","\x0A\x0A\x01\x03\x03","\x10\x10\x01\x05\x05","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\xF4\xF9\x01\xFD\xFE","\x0B\x0B\x01\x01\x01","\x10\x10\x01\x05\x05","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\xF4\xF9\x01\xFD\xFE","\x0A\x0A\x01\x03\x03","\x0D\x0D\x01\x04\x04","\x06\x06\x01\x01\x01","\x0B\x0B\x01\x04\x04","\x0B\x0B\x01\x04\x04","\x0A\x0A\x01\x03\x03","\x04\x04\x01\x01\x01","\xF4\xF9\x01\xFD\xFE","\x0B\x0B\x01\x01\x01","\x0D\x0D\x01\x04\x04","\x06\x06\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x07\x07\x01\x02\x02","\x07\x07\x01\x02\x02","\x07\x07\x01\x02\x02","\x07\x07\x01\x02\x02","\x07\x07\x01\x02\x02","\x07\x07\x01\x02\x02","\x04\x04\x01\x02\x02","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x04\x04\x01\x01\x01","\x07\x07\x01\x02\x02","\x04\x04\x01\x01\x01",
      "\xF5\xFB\x01\xFD\xFF","\x0A\x0A\x01\x03\x03","\xF6\xF6\x01\xFD\xFD","\xF6\x0A\x01\xFD\x03","\xEF\xF6\x01\xFB\xFD","\x0B\x0B\x01\x04\x04","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04","\xF5\xFB\x01\xFD\xFF","\xF6\x0A\x01\xFD\x03","\xF6\xF6\x01\xFD\xFD","\x00\x00\x00\x00\x00","\xEF\xF6\x01\xFB\xFD","\x11\x11\x01\x05\x05","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04",
      "\xF5\xFB\x01\xFD\xFF","\x0A\x0A\x01\x03\x03","\xF6\xF6\x01\xFD\xFD","\x0B\x0B\x01\x03\x03","\xEF\xF6\x01\xFB\xFD","\x0B\x0B\x01\x04\x04","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04","\xF5\xFB\x01\xFD\xFF","\x04\x04\x01\x01\x01","\xF6\xF6\x01\xFD\xFD","\x0B\x0B\x01\x03\x03","\xEF\xF6\x01\xFB\xFD","\x00\x00\x00\x00\x00","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04",
      "\xF5\xFB\x01\xFD\xFF","\x0A\x0A\x01\x03\x03","\xF6\xF6\x01\xFD\xFD","\x13\x13\x01\x05\x05","\xEF\xF6\x01\xFB\xFD","\x0B\x0B\x01\x04\x04","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04","\xF5\xFB\x01\xFD\xFF","\xFC\x04\x01\xFF\x01","\xF6\xF6\x01\xFD\xFD","\x04\x04\x01\x01\x01","\xEF\xF6\x01\xFB\xFD","\x00\x00\x00\x00\x00","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04",
      "\xF5\xFB\x01\xFD\xFF","\x0A\x0A\x01\x03\x03","\xF6\xF6\x01\xFD\xFD","\x04\x04\x01\x02\x02","\xEF\xF6\x01\xFB\xFD","\x0B\x0B\x01\x04\x04","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04","\xF5\xFB\x01\xFD\xFF","\x06\x06\x01\x01\x01","\xF6\xF6\x01\xFD\xFD","\x04\x04\x01\x01\x01","\xEF\xF6\x01\xFB\xFD","\x00\x00\x00\x00\x00","\x07\x07\x01\x02\x02","\x0B\x0B\x01\x04\x04"},


  /* &HCB Sets.                                               */

    *Z80CB[256]=
    { "rlc  b",  "rlc  c",  "rlc  d",  "rlc  e",  "rlc  h",  "rlc  l",  "rlc  (hl)",  "rlc  a",  "rrc  b",  "rrc  c",  "rrc  d",  "rrc  e",  "rrc  h",  "rrc  l",  "rrc  (hl)",  "rrc  a",
      "rl   b",  "rl   c",  "rl   d",  "rl   e",  "rl   h",  "rl   l",  "rl   (hl)",  "rl   a",  "rr   b",  "rr   c",  "rr   d",  "rr   e",  "rr   h",  "rr   l",  "rr   (hl)",  "rr   a",
      "sla  b",  "sla  c",  "sla  d",  "sla  e",  "sla  h",  "sla  l",  "sla  (hl)",  "sla  a",  "sra  b",  "sra  c",  "sra  d",  "sra  e",  "sra  h",  "sra  l",  "sra  (hl)",  "sra  a",
      "?",       "?",       "?",       "?",       "?",       "?",       "?",          "?",       "srl  b",  "srl  c",  "srl  d",  "srl  e",  "srl  h",  "srl  l",  "srl  (hl)",  "srl  a",
      "bit  0,b","bit  0,c","bit  0,d","bit  0,e","bit  0,h","bit  0,l","bit  0,(hl)","bit  0,a","bit  1,b","bit  1,c","bit  1,d","bit  1,e","bit  1,h","bit  1,l","bit  1,(hl)","bit  1,a",
      "bit  2,b","bit  2,c","bit  2,d","bit  2,e","bit  2,h","bit  2,l","bit  2,(hl)","bit  2,a","bit  3,b","bit  3,c","bit  3,d","bit  3,e","bit  3,h","bit  3,l","bit  3,(hl)","bit  3,a",
      "bit  4,b","bit  4,c","bit  4,d","bit  4,e","bit  4,h","bit  4,l","bit  4,(hl)","bit  4,a","bit  5,b","bit  5,c","bit  5,d","bit  5,e","bit  5,h","bit  5,l","bit  5,(hl)","bit  5,a",
      "bit  6,b","bit  6,c","bit  6,d","bit  6,e","bit  6,h","bit  6,l","bit  6,(hl)","bit  6,a","bit  7,b","bit  7,c","bit  7,d","bit  7,e","bit  7,h","bit  7,l","bit  7,(hl)","bit  7,a",
      "res  0,b","res  0,c","res  0,d","res  0,e","res  0,h","res  0,l","res  0,(hl)","res  0,a","res  1,b","res  1,c","res  1,d","res  1,e","res  1,h","res  1,l","res  1,(hl)","res  1,a",
      "res  2,b","res  2,c","res  2,d","res  2,e","res  2,h","res  2,l","res  2,(hl)","res  2,a","res  3,b","res  3,c","res  3,d","res  3,e","res  3,h","res  3,l","res  3,(hl)","res  3,a",
      "res  4,b","res  4,c","res  4,d","res  4,e","res  4,h","res  4,l","res  4,(hl)","res  4,a","res  5,b","res  5,c","res  5,d","res  5,e","res  5,h","res  5,l","res  5,(hl)","res  5,a",
      "res  6,b","res  6,c","res  6,d","res  6,e","res  6,h","res  6,l","res  6,(hl)","res  6,a","res  7,b","res  7,c","res  7,d","res  7,e","res  7,h","res  7,l","res  7,(hl)","res  7,a",
      "set  0,b","set  0,c","set  0,d","set  0,e","set  0,h","set  0,l","set  0,(hl)","set  0,a","set  1,b","set  1,c","set  1,d","set  1,e","set  1,h","set  1,l","set  1,(hl)","set  1,a",
      "set  2,b","set  2,c","set  2,d","set  2,e","set  2,h","set  2,l","set  2,(hl)","set  2,a","set  3,b","set  3,c","set  3,d","set  3,e","set  3,h","set  3,l","set  3,(hl)","set  3,a",
      "set  4,b","set  4,c","set  4,d","set  4,e","set  4,h","set  4,l","set  4,(hl)","set  4,a","set  5,b","set  5,c","set  5,d","set  5,e","set  5,h","set  5,l","set  5,(hl)","set  5,a",
      "set  6,b","set  6,c","set  6,d","set  6,e","set  6,h","set  6,l","set  6,(hl)","set  6,a","set  7,b","set  7,c","set  7,d","set  7,e","set  7,h","set  7,l","set  7,(hl)","set  7,a"},

    *R800CB[256]=
    { "rol   .b",  "rol   .c",  "rol   .d",  "rol   .e",  "rol   .h",  "rol   .l",  "rol   [.hl]",  "rol   .a",  "ror   .b",  "ror   .c",  "ror   .d",  "ror   .e",  "ror   .h",  "ror   .l",  "ror   [.hl]",  "ror   .a",
      "rolc  .b",  "rolc  .c",  "rolc  .d",  "rolc  .e",  "rolc  .h",  "rolc  .l",  "rolc  [.hl]",  "rolc  .a",  "rorc  .b",  "rorc  .c",  "rorc  .d",  "rorc  .e",  "rorc  .h",  "rorc  .l",  "rorc  [.hl]",  "rorc  .a",
      "shl   .b",  "shl   .c",  "shl   .d",  "shl   .e",  "shl   .h",  "shl   .l",  "shl   [.hl]",  "shl   .a",  "shra  .b",  "shra  .c",  "shra  .d",  "shra  .e",  "shra  .h",  "shra  .l",  "shra  [.hl]",  "shra  .a",
      "?",         "?",         "?",         "?",         "?",         "?",         "?",            "?",         "shr   .b",  "shr   .c",  "shr   .d",  "shr   .e",  "shr   .h",  "shr   .l",  "shr   [.hl]",  "shr   .a",
      "bit   0,.b","bit   0,.c","bit   0,.d","bit   0,.e","bit   0,.h","bit   0,.l","bit   0,[.hl]","bit   0,.a","bit   1,.b","bit   1,.c","bit   1,.d","bit   1,.e","bit   1,.h","bit   1,.l","bit   1,[.hl]","bit   1,.a",
      "bit   2,.b","bit   2,.c","bit   2,.d","bit   2,.e","bit   2,.h","bit   2,.l","bit   2,[.hl]","bit   2,.a","bit   3,.b","bit   3,.c","bit   3,.d","bit   3,.e","bit   3,.h","bit   3,.l","bit   3,[.hl]","bit   3,.a",
      "bit   4,.b","bit   4,.c","bit   4,.d","bit   4,.e","bit   4,.h","bit   4,.l","bit   4,[.hl]","bit   4,.a","bit   5,.b","bit   5,.c","bit   5,.d","bit   5,.e","bit   5,.h","bit   5,.l","bit   5,[.hl]","bit   5,.a",
      "bit   6,.b","bit   6,.c","bit   6,.d","bit   6,.e","bit   6,.h","bit   6,.l","bit   6,[.hl]","bit   6,.a","bit   7,.b","bit   7,.c","bit   7,.d","bit   7,.e","bit   7,.h","bit   7,.l","bit   7,[.hl]","bit   7,.a",
      "clr   0,.b","clr   0,.c","clr   0,.d","clr   0,.e","clr   0,.h","clr   0,.l","clr   0,[.hl]","clr   0,.a","clr   1,.b","clr   1,.c","clr   1,.d","clr   1,.e","clr   1,.h","clr   1,.l","clr   1,[.hl]","clr   1,.a",
      "clr   2,.b","clr   2,.c","clr   2,.d","clr   2,.e","clr   2,.h","clr   2,.l","clr   2,[.hl]","clr   2,.a","clr   3,.b","clr   3,.c","clr   3,.d","clr   3,.e","clr   3,.h","clr   3,.l","clr   3,[.hl]","clr   3,.a",
      "clr   4,.b","clr   4,.c","clr   4,.d","clr   4,.e","clr   4,.h","clr   4,.l","clr   4,[.hl]","clr   4,.a","clr   5,.b","clr   5,.c","clr   5,.d","clr   5,.e","clr   5,.h","clr   5,.l","clr   5,[.hl]","clr   5,.a",
      "clr   6,.b","clr   6,.c","clr   6,.d","clr   6,.e","clr   6,.h","clr   6,.l","clr   6,[.hl]","clr   6,.a","clr   7,.b","clr   7,.c","clr   7,.d","clr   7,.e","clr   7,.h","clr   7,.l","clr   7,[.hl]","clr   7,.a",
      "set   0,.b","set   0,.c","set   0,.d","set   0,.e","set   0,.h","set   0,.l","set   0,[.hl]","set   0,.a","set   1,.b","set   1,.c","set   1,.d","set   1,.e","set   1,.h","set   1,.l","set   1,[.hl]","set   1,.a",
      "set   2,.b","set   2,.c","set   2,.d","set   2,.e","set   2,.h","set   2,.l","set   2,[.hl]","set   2,.a","set   3,.b","set   3,.c","set   3,.d","set   3,.e","set   3,.h","set   3,.l","set   3,[.hl]","set   3,.a",
      "set   4,.b","set   4,.c","set   4,.d","set   4,.e","set   4,.h","set   4,.l","set   4,[.hl]","set   4,.a","set   5,.b","set   5,.c","set   5,.d","set   5,.e","set   5,.h","set   5,.l","set   5,[.hl]","set   5,.a",
      "set   6,.b","set   6,.c","set   6,.d","set   6,.e","set   6,.h","set   6,.l","set   6,[.hl]","set   6,.a","set   7,.b","set   7,.c","set   7,.d","set   7,.e","set   7,.h","set   7,.l","set   7,[.hl]","set   7,.a"},

    *TZ80R800CB[256]=
    { "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02",
      "\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x08\x08\x02\x02\x02","\x0F\x0F\x02\x05\x05","\x08\x08\x02\x02\x02"},


  /* &HDD/&HFD Sets.                                          */

    *Z80X[256]=
    { "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?","add  %,bc", "?",         "?",     "?","?","?",          "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?","add  %,de", "?",         "?",     "?","?","?",          "?",
      "?",          "ld   %,#",   "ld   (#),%", "inc  %",     "?",          "?",          "?",          "?",          "?","add  %,%",  "ld   %,(#)","dec  %","?","?","?",          "?",
      "?",          "?",          "?",          "?",          "inc  (%^)",  "dec  (%^)",  "ld   (%^),*","?",          "?","add  %,sp", "?",         "?",     "?","?","?",          "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "ld   b,(%^)","?",          "?","?",         "?",         "?",     "?","?","ld   c,(%^)","?",
      "?",          "?",          "?",          "?",          "?",          "?",          "ld   d,(%^)","?",          "?","?",         "?",         "?",     "?","?","ld   e,(%^)","?",
      "?",          "?",          "?",          "?",          "?",          "?",          "ld   h,(%^)","?",          "?","?",         "?",         "?",     "?","?","ld   l,(%^)","?",
      "ld   (%^),b","ld   (%^),c","ld   (%^),d","ld   (%^),e","ld   (%^),h","ld   (%^),l","?",          "ld   (%^),a","?","?",         "?",         "?",     "?","?","ld   a,(%^)","?",
      "?",          "?",          "?",          "?",          "?",          "?",          "add  a,(%^)","?",          "?","?",         "?",         "?",     "?","?","adc  a,(%^)","?",
      "?",          "?",          "?",          "?",          "?",          "?",          "sub  (%^)",  "?",          "?","?",         "?",         "?",     "?","?","sbc  a,(%^)","?",
      "?",          "?",          "?",          "?",          "?",          "?",          "and  (%^)",  "?",          "?","?",         "?",         "?",     "?","?","xor  (%^)",  "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "or   (%^)",  "?",          "?","?",         "?",         "?",     "?","?","cp   (%^)",  "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?","?",         "?",         "?ERROR","?","?","?",          "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?","?",         "?",         "?",     "?","?","?",          "?",
      "?",          "pop  %",     "?",          "ex   (sp),%","?",          "push %",     "?",          "?",          "?","jp   (%)\n","?",         "?",     "?","?","?",          "?",
      "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?",          "?","ld   sp,%", "?",         "?",     "?","?","?",          "?"},

    *R800X[256]=
    { "?",            "?",            "?",            "?",            "?",            "?",            "ld    .b,*",   "?",            "?",          "add   %,.bc","?",          "?",          "?",          "?",          "ld    .c,*",   "?",
      "?",            "?",            "?",            "?",            "?",            "?",            "ld    .d,*",   "?",            "?",          "add   %,.de","?",          "?",          "?",          "?",          "ld    .e,*",   "?",
      "?",            "ld    %,#",    "ld    [#],%",  "inc   %",      "inc   %h",     "dec   %h",     "ld    %h,*",   "?",            "?",          "add   %,%",  "ld    %,[#]","dec   %",    "inc   %l",   "dec   %l",   "ld    %l,*",   "?",
      "?",            "?",            "?",            "?",            "inc   [%^]",   "dec   [%^]",   "ld    [%^],*", "?",            "?",          "add   %,.sp","?",          "?",          "?",          "?",          "ld    .a,*",   "?",
      "!ld    .b,.b",  "!ld    .b,.c",  "!ld    .b,.d",  "!ld    .b,.e",  "ld    .b,%h",  "ld    .b,%l",  "ld    .b,[%^]","!ld    .b,.a",  "!ld    .c,.b","!ld    .c,.c","!ld    .c,.d","!ld    .c,.e","ld    .c,%h","ld    .c,%l","!ld    .c,[%^]","!ld    .c,.a",
      "!ld    .d,.b",  "!ld    .d,.c",  "!ld    .d,.d",  "!ld    .d,.e",  "ld    .d,%h",  "ld    .d,%l",  "ld    .d,[%^]","!ld    .d,.a",  "!ld    .e,.b","!ld    .e,.c","!ld    .e,.d","!ld    .e,.e","ld    .e,%h","ld    .e,%l","!ld    .e,[%^]","!ld    .e,.a",
      "ld    %h,.b",  "ld    %h,.c",  "ld    %h,.d",  "ld    %h,.e",  "ld    %h,%h",  "ld    %h,%l",  "ld    .h,[%^]","ld    %h,.a",  "ld    %l,.b","ld    %l,.c","ld    %l,.d","ld    %l,.e","ld    %l,%h","ld    %l,%l","ld    .l,[%^]","ld    %l,.a",
      "ld    [%^],.b","ld    [%^],.c","ld    [%^],.d","ld    [%^],.e","ld    [%^],.h","ld    [%^],.l","?",            "ld    [%^],.a","ld    .a,.b","ld    .a,.c","ld    .a,.d","ld    .a,.e","ld    .a,%h","ld    .a,%l","ld    .a,[%^]","ld    .a,.a",
      "?",            "?",            "?",            "?",            "add   .a,%h",  "add   .a,%l",  "add   .a,[%^]","?",            "?",          "?",          "?",          "?",          "addc  .a,%h","addc  .a,%l","addc  .a,[%^]","?",
      "?",            "?",            "?",            "?",            "sub   .a,%h",  "sub   .a,%l",  "sub   .a,[%^]","?",            "?",          "?",          "?",          "?",          "subc  .a,%h","subc  .a,%l","subc  .a,[%^]","?",
      "?",            "?",            "?",            "?",            "and   .a,%h",  "and   .a,%l",  "and   .a,[%^]","?",            "?",          "?",          "?",          "?",          "xor   .a,%h","xor   .a,%l","xor   .a,[%^]","?",
      "?",            "?",            "?",            "?",            "or    .a,%h",  "or    .a,%l",  "or    .a,[%^]","?",            "?",          "?",          "?",          "?",          "cmp   .a,%h","cmp   .a,%l","cmp   .a,[%^]","?",
      "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",          "?",          "?",          "?ERROR",     "?",          "?",          "?",            "?",
      "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",          "?",          "?",          "?",          "?",          "?",          "?",            "?",
      "?",            "pop   %",      "?",            "xch   [.sp],%","?",            "push  %",      "?",            "?",            "?",          "br    [%]\n","?",          "?",          "?",          "?",          "?",            "?",
      "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",            "?",          "ld    .sp,%","?",          "?",          "?",          "?",          "?",            "?"},

    *TZ80R800X[256]=
    { "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x02\x02","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x02\x02","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x0E\x0E\x02\x04\x04","\x14\x14\x02\x06\x06","\x0A\x0A\x02\x02\x02","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x0A\x0A\x02\x02\x02","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x02\x07\x07","\x17\x17\x02\x07\x07","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x02\x02","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x03\x03","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03",
      "\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03",
      "\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03",
      "\x13\x13\x02\x05\x05","\x13\x13\x02\x05\x05","\x13\x13\x02\x05\x05","\x13\x13\x02\x05\x05","\x13\x13\x02\x05\x05","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x00\x00\x00\x03\x03","\x13\x13\x02\x05\x05","\x00\x00\x00\x03\x03",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x02\x02","\x00\x00\x00\x02\x02","\x13\x13\x02\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x0E\x0E\x02\x04\x04","\x00\x00\x00\x00\x00","\x17\x17\x02\x06\x06","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\xF8\x08\x02\xFE\x02","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0A\x0A\x02\x02\x02","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00"},


  /* &HDD+&HCB/&HFD+&HCB Sets.                                */

    *Z80XCB[256]=
    { "?","?","?","?","?","?","rlc  (%^)",  "?","?","?","?","?","?","?","rrc  (%^)",  "?",
      "?","?","?","?","?","?","rl   (%^)",  "?","?","?","?","?","?","?","rr   (%^)",  "?",
      "?","?","?","?","?","?","sla  (%^)",  "?","?","?","?","?","?","?","sra  (%^)",  "?",
      "?","?","?","?","?","?","?",          "?","?","?","?","?","?","?","srl  (%^)",  "?",
      "?","?","?","?","?","?","bit  0,(%^)","?","?","?","?","?","?","?","bit  1,(%^)","?",
      "?","?","?","?","?","?","bit  2,(%^)","?","?","?","?","?","?","?","bit  3,(%^)","?",
      "?","?","?","?","?","?","bit  4,(%^)","?","?","?","?","?","?","?","bit  5,(%^)","?",
      "?","?","?","?","?","?","bit  6,(%^)","?","?","?","?","?","?","?","bit  7,(%^)","?",
      "?","?","?","?","?","?","res  0,(%^)","?","?","?","?","?","?","?","res  1,(%^)","?",
      "?","?","?","?","?","?","res  2,(%^)","?","?","?","?","?","?","?","res  3,(%^)","?",
      "?","?","?","?","?","?","res  4,(%^)","?","?","?","?","?","?","?","res  5,(%^)","?",
      "?","?","?","?","?","?","res  6,(%^)","?","?","?","?","?","?","?","res  7,(%^)","?",
      "?","?","?","?","?","?","set  0,(%^)","?","?","?","?","?","?","?","set  1,(%^)","?",
      "?","?","?","?","?","?","set  2,(%^)","?","?","?","?","?","?","?","set  3,(%^)","?",
      "?","?","?","?","?","?","set  4,(%^)","?","?","?","?","?","?","?","set  5,(%^)","?",
      "?","?","?","?","?","?","set  6,(%^)","?","?","?","?","?","?","?","set  7,(%^)","?"},

    *R800XCB[256]=
    { "?","?","?","?","?","?","rol   [%^]",  "?","?","?","?","?","?","?","ror   [%^]",  "?",
      "?","?","?","?","?","?","rolc  [%^]",  "?","?","?","?","?","?","?","rorc  [%^]",  "?",
      "?","?","?","?","?","?","shl   [%^]",  "?","?","?","?","?","?","?","shra  [%^]",  "?",
      "?","?","?","?","?","?","?",           "?","?","?","?","?","?","?","shr   [%^]",  "?",
      "?","?","?","?","?","?","bit   0,[%^]","?","?","?","?","?","?","?","bit   1,[%^]","?",
      "?","?","?","?","?","?","bit   2,[%^]","?","?","?","?","?","?","?","bit   3,[%^]","?",
      "?","?","?","?","?","?","bit   4,[%^]","?","?","?","?","?","?","?","bit   5,[%^]","?",
      "?","?","?","?","?","?","bit   6,[%^]","?","?","?","?","?","?","?","bit   7,[%^]","?",
      "?","?","?","?","?","?","clr   0,[%^]","?","?","?","?","?","?","?","clr   1,[%^]","?",
      "?","?","?","?","?","?","clr   2,[%^]","?","?","?","?","?","?","?","clr   3,[%^]","?",
      "?","?","?","?","?","?","clr   4,[%^]","?","?","?","?","?","?","?","clr   5,[%^]","?",
      "?","?","?","?","?","?","clr   6,[%^]","?","?","?","?","?","?","?","clr   7,[%^]","?",
      "?","?","?","?","?","?","set   0,[%^]","?","?","?","?","?","?","?","set   1,[%^]","?",
      "?","?","?","?","?","?","set   2,[%^]","?","?","?","?","?","?","?","set   3,[%^]","?",
      "?","?","?","?","?","?","set   4,[%^]","?","?","?","?","?","?","?","set   5,[%^]","?",
      "?","?","?","?","?","?","set   6,[%^]","?","?","?","?","?","?","?","set   7,[%^]","?"},

    *TZ80R800XCB[256]=
    { "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x14\x14\x03\x05\x05","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x17\x17\x03\x07\x07","\x00\x00\x00\x00\x00"},


  /* &HED Sets.                                               */

    *Z80ED[256]=
    { "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "in   b,(c)","out  (c),b","sbc  hl,bc","ld   (#),bc","neg","retn\n","im   0","ld   i,a","in   c,(c)","out  (c),c","adc  hl,bc","ld   bc,(#)","?","reti\n","?",     "ld   r,a",
      "in   d,(c)","out  (c),d","sbc  hl,de","ld   (#),de","?",  "?",     "im   1","ld   a,i","in   e,(c)","out  (c),e","adc  hl,de","ld   de,(#)","?","?",     "im   2","ld   a,r",
      "in   h,(c)","out  (c),h","sbc  hl,hl","!ld   (#),hl","?",  "?",     "?",     "rrd",     "in   l,(c)","out  (c),l","adc  hl,hl","!ld   hl,(#)","?","?",     "?",     "rld",
      "?in   (c)", "?",         "sbc  hl,sp","ld   (#),sp","?",  "?",     "?",     "?",       "in   a,(c)","out  (c),a","adc  hl,sp","ld   sp,(#)","?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "ldi",       "cpi",       "ini",       "outi",       "?",  "?",     "?",     "?",       "ldd",       "cpd",       "ind",       "outd",       "?","?",     "?",     "?",
      "ldir",      "cpir",      "inir",      "otir",       "?",  "?",     "?",     "?",       "lddr",      "cpdr",      "indr",      "otdr",       "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?",
      "?",         "?",         "?",         "?",          "?",  "?",     "?",     "?",       "?",         "?",         "?",         "?",          "?","?",     "?",     "?"},

    *R800ED[256]=
    { "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "in    .b,[.c]",        "out   [.c],.b",   "subc  .hl,.bc",     "ld    [#],.bc",     "neg   .a","retn\n","im    0","ld    .i,.a","in    .c,[.c]",        "out   [.c],.c",   "addc  .hl,.bc",     "ld    .bc,[#]",     "?","reti\n","?",      "ld    .r,.a",
      "in    .d,[.c]",        "out   [.c],.d",   "subc  .hl,.de",     "ld    [#],.de",     "?",       "?",     "im    1","ld    .a,.i","in    .e,[.c]",        "out   [.c],.e",   "addc  .hl,.de",     "ld    .de,[#]",     "?","?",     "im    2","ld    .a,.r",
      "in    .h,[.c]",        "out   [.c],.h",   "subc  .hl,.hl",     "!ld    [#],.hl",     "?",       "?",     "?",      "rol4  [.hl]","in    .l,[.c]",        "out   [.c],.l",   "addc  .hl,.hl",     "!ld    .hl,[#]",     "?","?",     "?",      "rol4  [.hl]",
      "in    .f,[.c]",        "?",               "subc  .hl,.sp",     "ld    [#],.sp",     "?",       "?",     "?",      "?",          "in    .a,[.c]",        "out   [.c],.a",   "addc  .hl,.sp",     "ld    .sp,[#]",     "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "?",                 "?",       "?",     "?",      "?",          "?",                    "?",               "?",                 "?",                 "?","?",     "?",      "?",
      "move  [.hl++],[.de++]","cmp   .a,[.hl++]","in    [.hl++],[.c]","out   [.c],[.hl++]","?",       "?",     "?",      "?",          "move  [.hl--],[.de--]","cmp   .a,[.hl--]","in    [.hl--],[.c]","out   [.c],[.hl--]","?","?",     "?",      "?",
      "movem [.hl++],[.de++]","cmpm  .a,[.hl++]","inm   [.hl++],[.c]","outm  [.c],[.hl++]","?",       "?",     "?",      "?",          "movem [.hl--],[.de--]","cmpm  .a,[.hl--]","inm   [.hl--],[.c]","outm  [.c],[.hl--]","?","?",     "?",      "?",
      "?",                    "mulub .a,.b",     "?",                 "muluw .hl,.bc",     "?",       "?",     "?",      "?",          "?",                    "mulub .a,.c",     "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "mulub .a,.d",     "?",                 "muluw .hl,.de",     "?",       "?",     "?",      "?",          "?",                    "mulub .a,.e",     "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "mulub .a,.h",     "?",                 "muluw .hl,.hl",     "?",       "?",     "?",      "?",          "?",                    "mulub .a,.l",     "?",                 "?",                 "?","?",     "?",      "?",
      "?",                    "?",               "?",                 "muluw .hl,.sp",     "?",       "?",     "?",      "?",          "?",                    "mulub .a,.a",     "?",                 "?",                 "?","?",     "?",      "?"},

    *TZ80R800ED[256]=
    { "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x08\x08\x02\x02\x02","\xF2\x0E\x02\xFB\x05","\x08\x08\x02\x03\x03","\x09\x09\x02\x02\x02","\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\xF2\x0E\x02\xFB\x05","\x00\x00\x00\x00\x00","\x09\x09\x02\x02\x02",
      "\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x08\x08\x02\x03\x03","\x09\x09\x02\x02\x02","\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x08\x08\x02\x03\x03","\x09\x09\x02\x02\x02",
      "\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x12\x12\x02\x05\x05","\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x12\x12\x02\x05\x05",
      "\x0C\x0C\x02\x03\x03","\x00\x00\x00\x00\x00","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x0C\x0C\x02\x03\x03","\x0C\x0C\x02\x03\x03","\x0F\x0F\x02\x02\x02","\x14\x14\x02\x06\x06","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x10\x10\x02\x04\x04","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\xEB\xF0\x02\xFC\xFC","\xEB\xF0\x02\xFC\xFC","\xEB\xF0\x02\xFC\xFD","\xEB\xF0\x02\xFC\xFD","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\xEB\xF0\x02\xFC\xFC","\xEB\xF0\x02\xFC\xFC","\xEB\xF0\x02\xFC\xFD","\xEB\xF0\x02\xFC\xFD","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x24\x24","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x24\x24","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x24\x24","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00",
      "\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x24\x24","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x0E\x0E","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00","\x00\x00\x00\x00\x00"};


  unsigned char
    Buf[128],TBuf[128],  /* General String Buffers.           */
    IdxReg[4]="\0",      /* Index Register String.            */
    *SPtr,               /* String Pointer.                   */
    *AddPtr=DataBuf,     /* Buffer Pointer.                   */
    *AuxPtr,             /* Auxiliar Pointer.                 */
    Offset,              /* &HDD/&HFD Offset Register.        */
    C;                   /* General Purpose Byte Register.    */
  unsigned int
    A,
    AuxInt=0;            /* &HCB Header Buffer/Flag.          */
  struct Label
    *APtr;               /* Auxiliar Label Pointer.           */


  /* Get Macro-Mnemonic: for each mode byte or combination of */
  /* bytes, the  program  uses  the corresponding  matrix  of */
  /* macro-mnemonics to get the correct  one and copies it to */
  /* the exit string "St".                                    */


  if (*AddPtr==0xCB)
  { AddPtr++;

    if (*Mode&UseR800OpCodes)
      strcpy(St,R800CB[*AddPtr]);
    else
      strcpy(St,Z80CB[*AddPtr]);

    for (A=0;A<5;A++)
      TimeTable[A]=TZ80R800CB[*AddPtr][A];
  }
  else if (*AddPtr==0xED)
  { AddPtr++;

    if (*Mode&UseR800OpCodes)
      strcpy(St,R800ED[*AddPtr]);
    else
      strcpy(St,Z80ED[*AddPtr]);

    for (A=0;A<5;A++)
      TimeTable[A]=TZ80R800ED[*AddPtr][A];
  }
  else if (*AddPtr==0xDD)
  { AddPtr++;

    if (*Mode&UseR800OpCodes)
      strcpy(IdxReg,".ix");
    else
      strcpy(IdxReg,"ix");

    if (*AddPtr==0xCB)
    { AddPtr++;
      Offset=*AddPtr++;
      AuxInt=1;

      if (*Mode&UseR800OpCodes)
        strcpy(St,R800XCB[*AddPtr]);
      else
        strcpy(St,Z80XCB[*AddPtr]);

      for (A=0;A<5;A++)
        TimeTable[A]=TZ80R800XCB[*AddPtr][A];
    }
    else
    { if (*Mode&UseR800OpCodes)
        strcpy(St,R800X[*AddPtr]);
      else
        strcpy(St,Z80X[*AddPtr]);

      for (A=0;A<5;A++)
        TimeTable[A]=TZ80R800X[*AddPtr][A];
    }
  }
  else if (*AddPtr==0xFD)
  { AddPtr++;

    if (*Mode&UseR800OpCodes)
      strcpy(IdxReg,".iy");
    else
      strcpy(IdxReg,"iy");

    if (*AddPtr==0xCB)
    { AddPtr++;
      Offset=*AddPtr++;
      AuxInt=1;

      if (*Mode&UseR800OpCodes)
        strcpy(St,R800XCB[*AddPtr]);
      else
        strcpy(St,Z80XCB[*AddPtr]);

      for (A=0;A<5;A++)
        TimeTable[A]=TZ80R800XCB[*AddPtr][A];
    }
    else
    { if (*Mode&UseR800OpCodes)
        strcpy(St,R800X[*AddPtr]);
      else
        strcpy(St,Z80X[*AddPtr]);

      for (A=0;A<5;A++)
        TimeTable[A]=TZ80R800X[*AddPtr][A];
    }
  }
  else
  { if (*Mode&UseR800OpCodes)
      strcpy(St,R800[*AddPtr]);
    else
      strcpy(St,Z80[*AddPtr]);

    for (A=0;A<5;A++)
      TimeTable[A]=TZ80R800[*AddPtr][A];
  }

  AddPtr++;


  /* Expand Macro-Mnemonic: searches, in the  macro-mnemonic, */
  /* for elements that must be expanded.                      */


  /* If "U" option  is active, changes all  relative  address */
  /* macros for signed byte ones.                             */

  if (*Mode&ShowJROffset)
    while (SPtr=strchr(St,'@'))
      *SPtr='^';


  /* If option "N" is  active, removes the  Line Feed control */
  /* code from the macro, if it exists.                       */

  if (*Mode&NoBreakAfterJmp)
    if (SPtr=strchr(St,'\n'))
      *SPtr='\0';


  /* Expands  all index  register  macros, depending  on  the */
  /* header byte, if any preceded the instruction.            */

  while (SPtr=strchr(St,'%'))
  { *SPtr='\0';
    strcpy(Buf,St);
    strcat(Buf,IdxReg);
    strcat(Buf,SPtr+1);
    strcpy(St,Buf);
  }


  /* This section  handles the undefined  and  invalid codes. */
  /* First, the  op-codes  are  listed, preceded  by  a  "DB" */
  /* pseudo-code. The  remark "invalid op-code" is  appended, */
  /* after  a  semi-colon,  if  there's  no  comment  for  it */
  /* already defined. This allows  "undocumented codes" to be */
  /* remarked. IMPORTANT: codes that have  some effect in one */
  /* CPU generally do not in another, so just remark the ones */
  /* your  have  already tested  or  have  in REALLY reliable */
  /* documentation.                                           */

  if (SPtr=strchr(St,'?'))
  { if (*Mode&UseR800OpCodes)
      strcpy(Buf,"db    ");
    else
      strcpy(Buf,"db   ");

    AuxPtr=DataBuf;
    sprintf(TBuf,"&%02XH",*AuxPtr++);
    strcat(Buf,TBuf);

    for (;AuxPtr<AddPtr;AuxPtr++)
    { sprintf(TBuf,",&%02XH",*AuxPtr);
      strcat(Buf,TBuf);
    }

    if (strlen(St)>1)
    { strcat(Buf," ; ");
      strcat(Buf,SPtr+1);
    }
    else
      strcat(Buf," ; invalid op-code");

    strcpy(St,Buf);
  }


  /* Capitalize mnemonics.                                    */

  if (*Mode&ShowUppercase)
  { C=strlen(St);

    if (C) do
    { C--;

      if ((St[C]>='a')&&(St[C]<='z'))
        St[C]-='\x20';
    } while (C);
  }


  /* Expands Signed Byte Macro.                               */

  C=0;

  while (SPtr=strchr(St,'^'))
  { *SPtr='\0';
    strcpy(Buf,St);

    if (!AuxInt)
      Offset=*AddPtr++;

    if (Offset||(!(*Mode&CompactMode)))
    { if ((APtr=SearchLabelVal(LP,Offset,ByteLabel))!=NULL)
      { strcat(Buf,"+");

        do
        { if ((strlen(Buf)+strlen(APtr->Name))<80)
          { strcat(Buf,APtr->Name);
            C=1;
          }

          if ((*Mode&ShowAllLabels)&&((APtr=SearchLabelVal(APtr->Next,Offset,ByteLabel))!=NULL))
            if (C==1)
            { strcat(Buf,"/");
              C=2;
            }
        } while ((APtr!=NULL)&&(strlen(Buf)<80)&&(*Mode&ShowAllLabels));

        if (C==2)
          strcat(Buf,"...");

        *Mode|=DefinedLabels;
      }
      else if (Offset&0x80)
      { sprintf(TBuf,"-&%02XH",256-Offset);
        strcat(Buf,TBuf);
      }
      else
      { sprintf(TBuf,"+&%02XH",Offset);
        strcat(Buf,TBuf);
      }
    }

    strcat(Buf,SPtr+1);
    strcpy(St,Buf);
  }


  /* Expands Unsigned Byte Macro.                             */

  C=0;

  while (SPtr=strchr(St,'*'))
  { *SPtr='\0';
    strcpy(Buf,St);

    if ((APtr=SearchLabelVal(LP,*AddPtr,ByteLabel))!=NULL)
    { do
      { if ((strlen(Buf)+strlen(APtr->Name))<80)
        { strcat(Buf,APtr->Name);
          C=1;
        }

        if ((*Mode&ShowAllLabels)&&((APtr=SearchLabelVal(APtr->Next,*AddPtr,ByteLabel))!=NULL))
          if (C==1)
          { strcat(Buf,"/");
            C=2;
          }
      } while ((APtr!=NULL)&&(strlen(Buf)<80)&&(*Mode&ShowAllLabels));

      if (C==2)
        strcat(Buf,"...");

      *Mode|=DefinedLabels;
    }
    else
    { sprintf(TBuf,"&%02XH",*AddPtr);
      strcat(Buf,TBuf);
    }

    AddPtr++;
    strcat(Buf,SPtr+1);
    strcpy(St,Buf);
  }


  /* Expands Unsigned LSB-MSB Word Macro.                     */

  C=0;

  while (SPtr=strchr(St,'#'))
  { *SPtr='\0';
    strcpy(Buf,St);
    AuxInt=(unsigned int)AddPtr[0]+256*AddPtr[1];
    AddPtr+=2;

    if ((APtr=SearchLabelVal(LP,AuxInt,WordLabel))!=NULL)
    { do
      { if ((strlen(Buf)+strlen(APtr->Name))<80)
        { strcat(Buf,APtr->Name);
          C=1;
        }

        if ((*Mode&ShowAllLabels)&&((APtr=SearchLabelVal(APtr->Next,AuxInt,WordLabel))!=NULL))
          if (C==1)
          { strcat(Buf,"/");
            C=2;
          }
      } while ((APtr!=NULL)&&(strlen(Buf)<80)&&(*Mode&ShowAllLabels));

      if (C==2)
        strcat(Buf,"...");

      *Mode|=DefinedLabels;
    }
    else if (*Mode&GenerateLabels)
      AddAutoLabel(LP,AuxInt);
    else
    { sprintf(TBuf,"&%04hXH",AuxInt);
      strcat(Buf,TBuf);
    }

    strcat(Buf,SPtr+1);
    strcpy(St,Buf);
  }


  /* Expands Relative Address.                                */
  C=0;

  while (SPtr=strchr(St,'@'))
  { *SPtr='\0';
    strcpy(Buf,St);
    Offset=*AddPtr++;

    if (Offset&0x80)
      AuxInt=((unsigned int)AddBase)+Offset-254;
    else
      AuxInt=((unsigned int)AddBase)+Offset+2;

    if ((APtr=SearchLabelVal(LP,AuxInt,WordLabel))!=NULL)
    { do
      { if ((strlen(Buf)+strlen(APtr->Name))<80)
        { strcat(Buf,APtr->Name);
          C=1;
        }

        if ((*Mode&ShowAllLabels)&&((APtr=SearchLabelVal(APtr->Next,AuxInt,WordLabel))!=NULL))
          if (C==1)
          { strcat(Buf,"/");
            C=2;
          }
      } while ((APtr!=NULL)&&(strlen(Buf)<80)&&(*Mode&ShowAllLabels));

      if (C==2)
        strcat(Buf,"...");

      *Mode|=DefinedLabels;
    }
    else if (*Mode&GenerateLabels)
      AddAutoLabel(LP,AuxInt);
    else
    { sprintf(TBuf,"&%04hXH",AuxInt);
      strcat(Buf,TBuf);
    }

    strcat(Buf,SPtr+1);
    strcpy(St,Buf);
  }


  /* If "0" option is  active, puts a "0" before  numbers. If */
  /* "T"  option  is  active, puts "0"  only  before  numbers */
  /* beginning by "A", "B", "C", "D", "E" or "F".             */

  while (SPtr=strchr(St,'&'))
    if ((*Mode&LeadingZero)&&(!((*Mode&CompactMode)&&(SPtr[1]>='0')&&(SPtr[1]<='9'))))
      *SPtr='0';
    else
    { *SPtr='\0';
      strcpy(Buf,SPtr+1);
      strcat(St,Buf);
    }

  return(AddPtr-DataBuf);
}


/* Main Routine.                                              */

int
  main             /* Main C Routine.                         */
  ( int ArgC,      /* Parameter Counter.                      */
    char *ArgS[]   /* Parameter Strings.                      */
  )
{ char
    OpCodeTimes[5];/* CPU Time Codes.                         */
  unsigned char
    Buf[128],      /* General Data Buffer.                    */
    TBuf[16],      /* Temporary Transfer Buffer.              */
    PBuf[128],     /* Print Buffer.                           */
    TC,            /* Temporary Character Register.           */
    *SPtr,         /* String Pointer.                         */
    Mnemo[256],    /* Mnemonic Buffer.                        */
    FormStr[64];   /* Format String.                          */
  int
    A,B,C,         /* General Purpose Registers.              */
    CharOffset=0;  /* Character Offset.                       */
  unsigned int
    Delta,         /* Difference Register.                    */
    BufSiz,        /* "Buf" Used Area Size.                   */
    MaxLabelLen=0, /* Maximum Label Length.                   */
    AddrMargin=0,  /* Address Field Margin.                   */
    ReadFlag,      /* Read Data Flag.                         */
    Pass=2,        /* Disassembling Pass.                     */
    GT;            /* Gremlin Type.                           */
  unsigned long
    Base=0L,       /* Address Base.                           */
    Counter,       /* Address Counter.                        */
    Mode=0L,       /* Operation Mode General Flag.            */
    StartAdd=0L,   /* Start Address.                          */
    StartPos=0L,   /* Start Position.                         */
    EndAdd=0L,     /* End Address.                            */
    InstCnt,       /* Instruction Counter.                    */
    CycleCounter=0;/* Instruction Fail Cycle Counter.         */
  FILE
    *F;            /* File Pointer.                           */
  struct Label
    *Head,         /* Pointer to The First Label Data Bank.   */
    *APtr,         /* Auxiliar Label Pointer.                 */
    *LPtr;         /* General Label Pointer.                  */


  /* If no parameter is given, prints help.                   */

  if (ArgC<2)
  { fprintf(stdout,"\nGREMLIN - Z80 & MSX R800 Disassembler - Version %s.\n",Version);
    fprintf(stdout,"Programmed in 1998-2004 by Cyberknight Massao Kawata \n");
    fprintf(stdout,"For \"Unicorn Dreams Artwork Programs\".\n\n");

    fprintf(stdout,"Usage: %s File [a[8]][j][b#][s#][e#|l#][f#]...\n",ArgS[0]);
    fprintf(stdout,"      ... [o][r][c[@][#]][u[@]][n][0][k][t[@]][xFile][w][d][i][gHeader]\n\n");

    fprintf(stdout,"a = prints  Addresses (with 4 digits  j = prints offsets  of relative Jumps \n");
    fprintf(stdout,"    by default or with \"8\").              instead of addresses.             \n");
    fprintf(stdout,"s = Start address # (default=Base).   b = sets Base address # (default=0).  \n");
    fprintf(stdout,"f = file start (default 0=1st byte).  e = End address (exclude \"L\" option). \n");
    fprintf(stdout,"o = prints original Op-codes.         l = Last file position (exclude \"E\"). \n");
    fprintf(stdout,"c = prints  op-codes  as  Characters  r = uses R800 mnemonics.              \n");
    fprintf(stdout,"    (\"@\"=shows control codes instead  0 = prints a zero before numbers.     \n");
    fprintf(stdout,"    of blanks; adds offset #).        k = compact mode.                     \n");
    fprintf(stdout,"n = does Not print line breaks after  x = loads label list \"File\".          \n");
    fprintf(stdout,"    inconditional branches.           w = shows all matching labels.        \n");
    fprintf(stdout,"d = Discards already  defined labels  g = Generates labels automatically in \n");
    fprintf(stdout,"    from label listing.                   the format \"Header####\".          \n");
    fprintf(stdout,"t = calculates CPU cycle  usage (the  u = lists in Uppercase characters.    \n");
    fprintf(stdout,"    \"@\" option adds wait-states).         (\"@\" = also capitalizes labels).  \n");
    fprintf(stdout,"i = removes ambiguities by  printing                                        \n");
    fprintf(stdout,"    unused op-codes as Inline \"DB\".                                         \n\n");


    return(Okay);
  }


  /* Variables Initialization.                                */

  if ((Head=(struct Label *)malloc(sizeof(struct Label)))==NULL)
  { fprintf(stderr,"The Unicorn couldn't make room enough for variables.\n");
    return(NotEnoughMem);
  }

  Head->Name=NULL;
  Head->Status='\0';
  Head->Next=NULL;


  /* Parse options, if any.                                   */

  for (A=2;A<ArgC;A++)
  { C=strlen(ArgS[A]);

    switch (ArgS[A][0])
    { case '0':
        Mode|=LeadingZero;
        break;
      case 'a':
      case 'A':
        if (ArgS[A][1]=='8')
        { AddrMargin=9;
          Mode|=Use8CharAddress;
        }
        else
        { AddrMargin=5;
          Mode&=~Use8CharAddress;
        }

        Mode|=ShowAddresses;
        break;
      case 'b':
      case 'B':
        sscanf(ArgS[A]+1,"%li",&Base);
        break;
      case 'c':
      case 'C':
        Mode&=~ShowControlChar;

        if (C>1)
        { CharOffset=0;
          if (ArgS[A][1]=='@')
          { Mode|=ShowControlChar;
            sscanf(ArgS[A]+2,"%i",&CharOffset);
          }
          else
            sscanf(ArgS[A]+1,"%i",&CharOffset);
        }

        Mode|=ShowCharacters;
        break;
      case 'd':
      case 'D':
        Mode|=DiscardDefLabel;
        break;
      case 'e':
      case 'E':
        sscanf(ArgS[A]+1,"%li",&EndAdd);
        Mode=(Mode&~LastByteSet)|EndAddressSet;
        break;
      case 'f':
      case 'F':
        sscanf(ArgS[A]+1,"%li",&StartPos);
        break;
      case 'g':
      case 'G':
        if (C>(MaxLabelSiz-4))
        { fprintf(stderr,"The Unicorn found too long label header (\"%s\") in option \"G\".\n",ArgS[A]+1);
          return(LabelTooLong);
        }

        if (C<2)
        { fprintf(stderr,"The Unicorn found missing label header in option \"G\".\n");
          return(MissingPar);
        }

        if (Head->Name!=NULL)
        { free(Head->Name);
          Head->Name=NULL;
        }

        if ((Head->Name=(char *)malloc(C))==NULL)
        { fprintf(stderr,"The Unicorn couldn't make room enough for labels from \"%s\".\n",ArgS[A]+1);
          return(NotEnoughMem);
        }

        strcpy(Head->Name,ArgS[A]+1);

        if (MaxLabelLen<(C+3))
          MaxLabelLen=C+3;

        Mode|=GenerateLabels;
        Pass=4;
        break;
      case 'i':
      case 'I':
        Mode|=RemoveAmbiguity;
        break;
      case 'j':
      case 'J':
        Mode|=ShowJROffset;
        break;
      case 'k':
      case 'K':
        Mode|=CompactMode;
        break;
      case 'l':
      case 'L':
        sscanf(ArgS[A]+1,"%li",&EndAdd);
        Mode=(Mode&~EndAddressSet)|LastByteSet;
        break;
      case 'n':
      case 'N':
        Mode|=NoBreakAfterJmp;
        break;
      case 'o':
      case 'O':
        Mode|=ShowOpCodes;
        break;
      case 'r':
      case 'R':
        Mode|=UseR800OpCodes;
        break;
      case 's':
      case 'S':
        SPtr=ArgS[A];
        SPtr++;
        sscanf(SPtr,"%li",&StartAdd);
        break;
      case 't':
      case 'T':
        if (C>1)
          if (ArgS[A][1]=='@')
            Mode|=AddWaitStates;
          else
          { fprintf(stderr,"The Unicorn found syntax error in option \"%s\".\n",ArgS[A]);
            return(SyntaxError);
          }

        Mode|=ShowCPUTimes;
        break;
      case 'u':
      case 'U':
        if (C>1)
          if (ArgS[A][1]=='@')
            Mode|=CapitalizeLabels;
          else
          { fprintf(stderr,"The Unicorn found syntax error in option \"%s\".\n",ArgS[A]);
            return(SyntaxError);
          }

        Mode|=ShowUppercase;
        break;
      case 'w':
      case 'W':
        Mode|=ShowAllLabels;
        break;
      case 'x':
      case 'X':
        if (!(F=fopen(ArgS[A]+1,"rb")))
        { fprintf(stderr,"The Unicorn couldn't open file \"%s\".\n",ArgS[A]+1);
          return(FileNotFound);
        }

        C=0;
        ReadFlag=fread(TBuf,1,1,F);

        do
          if (C&0x0001)
          { BufSiz=0;

            while ((ReadFlag)&&(BufSiz<MaxLabelSiz)&&(((C&0x8000)&&(TBuf[0]>=' '))||(TBuf[0]>='@')||(TBuf[0]=='+')||(TBuf[0]=='-')||(TBuf[0]=='\'')||((TBuf[0]>='0')&&(TBuf[0]<='9'))))
            { /* Capture quotation enclosed string. */
              Buf[BufSiz++]=TBuf[0];

              if (TBuf[0]=='\'')
                C^=0x8000;

              ReadFlag=fread(TBuf,1,1,F);

              if (BufSiz>MaxLabelSiz)
              { /* Label too long */
                Buf[MaxLabelSiz]='\0';
                fprintf(stderr,"The Unicorn found too long label (\"%s\") in \"%s\".\n",Buf,ArgS[A]+1);
                return(LabelTooLong);
              }
            }

            Buf[BufSiz]='\0';

            if (C&0x8000)
            { fprintf(stderr,"The Unicorn found unclosed label (\"%s\") in \"%s\".\n",Buf,ArgS[A]+1);
              return(UnclosedLabel);
            }

            if ((C&0x0003)==1)
            { /* Label found, creating new entry... */

              if ((APtr=(struct Label *)malloc(sizeof(struct Label)))==NULL)
              { fprintf(stderr,"The Unicorn couldn't make room enough for labels from \"%s\".\n",ArgS[A]+1);
                return(NotEnoughMem);
              }

              if ((APtr->Name=(char *)malloc(BufSiz+1))==NULL)
              { fprintf(stderr,"The Unicorn couldn't make room enough for labels from \"%s\".\n",ArgS[A]+1);
                return(NotEnoughMem);
              }

              strcpy(APtr->Name,Buf);

              if (MaxLabelLen<BufSiz)
                MaxLabelLen=BufSiz;
            }
            else if ((C&0x0003)==3)
            { /* Label value read, determining its type... */

              if (Buf[0]=='@')
              { /* Byte type... */

                if (Buf[1]=='-')
                { sscanf(Buf+2,"%i",&B);

                  if (B>0x80)
                  { fprintf(stderr,"The Unicorn found bad Byte \"%s\" in file \"%s\".\n",Buf,ArgS[A]+1);
                    return(BadNumericPar);
                  }

                  APtr->Value=(256-B);
                }
                else
                { sscanf(Buf+1,"%i",&B);

                  if (B>0xFF)
                  { fprintf(stderr,"The Unicorn found bad Byte \"%s\" in file \"%s\".\n",Buf,ArgS[A]+1);
                    return(BadNumericPar);
                  }

                  APtr->Value=B;
                }
                APtr->Status=ByteLabel;
              }
              else
              { /* Word type... */

                if (!sscanf(Buf,"%i",&B))
                { fprintf(stderr,"The Unicorn found bad Word \"%s\" in file \"%s\".\n",Buf,ArgS[A]+1);
                  return(BadNumericPar);
                }

                APtr->Value=B;
                APtr->Status=WordLabel;
              }

              /* Insert label in list. */

              if (Head->Next!=NULL)
                if (Head->Next->Value>APtr->Value)
                { APtr->Next=Head->Next;
                  Head->Next=APtr;
                }
                else
                { LPtr=Head->Next;

                  while ((LPtr->Next!=NULL)&&((LPtr->Next->Value<APtr->Value)||((LPtr->Next->Value==APtr->Value)&&(LPtr->Next->Status<=APtr->Status))))
                    LPtr=LPtr->Next;

                  APtr->Next=LPtr->Next;
                  LPtr->Next=APtr;
                }
              else
              { APtr->Next=NULL;
                Head->Next=APtr;
              }
            }

            C++;
          }
          else
          { while ((ReadFlag)&&(TBuf[0]!='+')&&(TBuf[0]!='-')&&(TBuf[0]!='_')&&(TBuf[0]!='\'')&&(TBuf[0]!='@')&&
                   (!(((TBuf[0]>='0')&&(TBuf[0]<='9'))||((TBuf[0]>='A')&&(TBuf[0]<='Z'))||((TBuf[0]>='a')&&(TBuf[0]<='z'))||(TBuf[0]>127))))
              ReadFlag=fread(TBuf,1,1,F);

            C>=4?C=1:C++;
          }
        while (ReadFlag);

        if ((C&0xE)==2)
        { fprintf(stderr,"The Unicorn found misdefined label in \"%s\".\n",ArgS[A]);
          return(SyntaxError);
        }

        fclose(F);
        break;
      default:
        fprintf(stderr,"The Unicorn found unknown option \"%s\".\n",ArgS[A]);
        return(UnknownOption);
    } /* Switch Options */
  } /* For */


  /* Try to open file.                                        */

  srand(GT);
  GT=rand()%8;

  if (Mode&CompactMode)
  { fprintf(stdout,"; GREMLIN (%s) (C) 1998-2004 Cyberknight (Unicorn Dreams)\".\n\n",Version);
    fprintf(stdout,"; Processing File: \"%s\"\n\n",ArgS[1]);
  }
  else
  { fprintf(stdout,"; GREMLIN - Z80 & MSX R800 Disassembler - Version %s.\n",Version);
    fprintf(stdout,"; Programmed in 1998-2004 by Cyberknight Massao Kawata \n");
    fprintf(stdout,"; For \"Unicorn Dreams Artwork Programs\".\n\n");
    fprintf(stdout,"; The Unicorn heard your call. She has summoned the %s Gremlin\n; to disassemble \"%s\"...\n\n",Gremlin[GT],ArgS[1]);
  }

  if (!(F=fopen(ArgS[1],"rb")))
  { fprintf(stderr,"Gremlin couldn't open file \"%s\".\n",ArgS[1]);
    return(FileNotFound);
  }


  /* Initialize program variables.                            */

  if (StartAdd<Base)
    StartAdd=Base;

  if (Mode&LastByteSet)
    EndAdd+=Base-StartPos;

  if (AddrMargin<MaxLabelLen)
    AddrMargin=MaxLabelLen;

  /* Main Loop.                                               */

  do
  { /* If there is space left  in "Buf", reads  enough  bytes */
    /* from file to fill it.                                  */

    if ((Pass==2)||(Pass==4))
    { if (Pass==4)
        fprintf(stderr,"%s Gremlin is parsing file \"%s\"...",Gremlin[GT],ArgS[1]);
      else
      { if (Mode&GenerateLabels)
          fprintf(stderr,"\n\n");

        if ((Head->Next!=NULL)||(Mode&ShowAddresses))
          sprintf(FormStr,"%%-%us ",AddrMargin+2);
        else
          FormStr[0]='\0';

        if (FormStr[0])
          fprintf(stdout,FormStr,"");

        if (Mode&UseR800OpCodes)
          fprintf(stdout,".R800\n");
        else
          fprintf(stdout,".Z80\n");

        if (FormStr[0])
          fprintf(stdout,FormStr,"");

        fprintf(stdout,"aseg\n\n");

        if (FormStr[0])
          fprintf(stdout,FormStr,"");

        fprintf(stdout,"org     00100H\n");

        if (FormStr[0])
          fprintf(stdout,FormStr,"");

        if (Mode&Use8CharAddress)
          fprintf(stdout,".Phase  %09lXH\n\n",Base);
        else
          fprintf(stdout,".Phase  %05lXH\n\n",Base);

        /* Capitalize labels.                                 */

        if (Mode&CapitalizeLabels)
          for (LPtr=Head->Next; LPtr!=NULL; LPtr=LPtr->Next)
            if (LPtr->Status&'\x3F')
              for (C=0; LPtr->Name[C]; C++)
                if ((LPtr->Name[C]>='a')&&(LPtr->Name[C]<='z'))
                  LPtr->Name[C]-='\x20';
      }

      fseek(F,StartPos+StartAdd-Base,0);
      Counter=StartAdd;
      ReadFlag=1;
      BufSiz=0;
      InstCnt=0L;
      Pass--;
    }

    if (((Pass==1)||(Pass==3))&&(BufSiz<8))
    { A=Delta=8-BufSiz;

      while (ReadFlag&&A)
      { ReadFlag=fread(TBuf,1,1,F);

        if (ReadFlag)
          Buf[8-A--]=TBuf[0];
      }

      BufSiz+=Delta-A;
    }


    /* If no "End Flags" are set or  the end  address is  not */
    /* reached, then disassemble bytes in "Buf".              */

    if ((Counter>EndAdd)&&(Mode&(EndAddressSet|LastByteSet)))
      Pass--;
    else
    { Delta=MDA(Mnemo,Buf,Counter,&Mode,Head,OpCodeTimes);


      if (Pass<2)
      { /* Prints disassembled codes.                         */

        if ((Head->Next!=NULL)||(Mode&ShowAddresses))
        { /* Shows Addresses or Labels.                       */

          PBuf[0]='\0';

          if ((LPtr=SearchLabelVal(Head,(unsigned int)Counter,WordLabel))!=NULL)
          { /* If there are labels defined to the address, print them. */

            Mode|=DefinedLabels;

            LPtr->Status|=LabelDefined;
            sprintf(PBuf,"%s",LPtr->Name);

            if (Mode&ShowAllLabels)
              while ((LPtr=SearchLabelVal(LPtr->Next,(unsigned int)Counter,WordLabel))!=NULL)
              { fprintf(stdout,"%s:\n",PBuf);
                sprintf(PBuf,"%s",LPtr->Name);
                LPtr->Status|=LabelDefined;
              }
          }
          else if (Mode&ShowAddresses)
          { if (Mode&Use8CharAddress)
              sprintf(PBuf,"%08lXH",Counter);
            else
              sprintf(PBuf,"%04lXH",Counter);
          }

          if (PBuf[0])
            strcat(PBuf,":");

          fprintf(stdout,FormStr,PBuf);
        }


        /* Shows op-code bytes if "O" option is active.       */

        if (Mode&ShowOpCodes)
        { for (A=0;A<Delta;A++)
            fprintf(stdout,"%02X ",Buf[A]);
          for (;A<4;A++)
            fprintf(stdout,"   ");

          fprintf(stdout," ");
        }


        /* Shows the op-codes as characters, if option "C" is */
        /* active. Adds optional offset and, if "@" is given, */
        /* ignores control characters.                        */

        if (Mode&ShowCharacters)
        { /* If required, prints control characters.          */

          if (Mode&ShowControlChar)
          { for (A=0;A<Delta;A++)
              switch (TC=(Buf[A]+CharOffset))
              { case '\1':
                case '\2':
                case '\4':
                case '\5':
                case '\6':
                case '\xE':
                case '\xF':
                case '\x10':
                case '\x11':
                case '\x13':
                case '\x14':
                case '\x15':
                case '\x16':
                case '\x17':
                case '\x18':
                case '\x19':
                case '\x1C':
                case '\x1D':
                case '\x1E':
                case '\x1F':
                  fprintf(stdout,"%02X ",TC);
                  break;
                case '\0': /* Null */
                  fprintf(stdout,"Nl ");
                  break;
                case '\3': /* Break */
                  fprintf(stdout,"Br ");
                  break;
                case '\7': /* Bell */
                  fprintf(stdout,"Be ");
                  break;
                case '\x8': /* Back Space */
                  fprintf(stdout,"BS ");
                  break;
                case '\x9': /* Tabulation */
                  fprintf(stdout,"Tb ");
                  break;
                case '\n': /* Line Feed */
                  fprintf(stdout,"LF ");
                  break;
                case '\xB': /* Home */
                  fprintf(stdout,"Hm ");
                  break;
                case '\xC': /* Form Feed/Clear Screen */
                  fprintf(stdout,"FF ");
                  break;
                case '\r': /* Carriage Return */
                  fprintf(stdout,"CR ");
                  break;
                case '\x12': /* Insert */
                  fprintf(stdout,"In ");
                  break;
                case '\x1A': /* End-of-File */
                  fprintf(stdout,"EF ");
                  break;
                case '\x1B': /* Escape */
                  fprintf(stdout,"Es ");
                  break;
                case ' ': /* Space */
                  fprintf(stdout,"Sp ");
                  break;
                case '\x7F': /* Delete */
                  fprintf(stdout,"De ");
                  break;
                default:
                  fprintf(stdout,"%c  ",TC);
              } /* Switch */

            for (;A<4;A++)
              fprintf(stdout,"   ");

            fprintf(stdout,"  ");
          }
          else
          { /* Ignores op-code control characters.            */

            for (A=0;A<Delta;A++)
            { TC=Buf[A]+CharOffset;

              if ((TC<32)||(TC==127))
                fprintf(stdout,"%c",'.');
              else
                fprintf(stdout,"%c",TC);
            }

            for (;A<6;A++)
              fprintf(stdout,"%c",' ');
          }
        }


        /* Calculates CPU execution times, if possible.       */

        if (Mode&ShowCPUTimes)
        { A=OpCodeTimes[(Mode&UseR800OpCodes)?3:0];
          B=OpCodeTimes[(Mode&UseR800OpCodes)?4:1];
          C=(Mode&AddWaitStates)?OpCodeTimes[2]:0;

          if ((A>0)&&(B>0))
          { if (!(Mode&UseR800OpCodes))
              A+=C;

            fprintf(stdout,"%2i             ",A);
            CycleCounter+=A;
          }
          else if (B>0)
          { if (!(Mode&UseR800OpCodes))
              A=-A+C;

            fprintf(stdout,"%2i    %3li      ",A,CycleCounter+A);
            CycleCounter=0;
          }
          else if (A)
          { if (!(Mode&UseR800OpCodes))
            { A=-A+C;
              B=-B+C;
            }

            fprintf(stdout,"%2i/%2i %3li/%3li  ",A,B,CycleCounter+A,CycleCounter+B);
            CycleCounter=0;
          }
          else
          { fprintf(stdout,"?     %3li      ",CycleCounter);
            CycleCounter=0;
          }
        }

      /* Finally, shows mnemonic.                             */


      if (Mnemo[0]=='!')

      /* This section handles ambiguous op-codes that lead to */
      /* the same mnemonics.                                  */

        if (Mode&RemoveAmbiguity)
        { if (Mode&UseR800OpCodes)
            fprintf(stdout,"db    ");
          else
            fprintf(stdout,"db   ");

          if (Mode&LeadingZero)
            if ((Mode&CompactMode)&&((signed int)Buf[0]<0xA0))
              fprintf(stdout,"%02XH",Buf[0]);
            else
              fprintf(stdout,"%03XH",Buf[0]);
          else
            fprintf(stdout,"%02XH",Buf[0]);

          for (C=1; C<Delta; C++)
            if (Mode&LeadingZero)
              if ((Mode&CompactMode)&&((signed int)Buf[C]<0xA0))
                fprintf(stdout,",%02XH",Buf[C]);
              else
                fprintf(stdout,",%03XH",Buf[C]);
            else
              fprintf(stdout,",%02XH",Buf[C]);

          fprintf(stdout," ; %s\n",Mnemo+1);
        }
        else
          fprintf(stdout,"%s\n",Mnemo+1);
      else
        fprintf(stdout,"%s\n",Mnemo);
      }

      Counter+=Delta;
      InstCnt++;


      /* Removes  the just disassembled  op-codes  from "Buf" */
      /* and fills the free area with zero.                   */

      if (Delta<=BufSiz)
        BufSiz-=Delta;
      else
        BufSiz=0;

      if (BufSiz)
      { for (A=0;A<(8-Delta);A++)
          Buf[A]=Buf[A+Delta];
        for (A=8-Delta;A<8;A++)
          Buf[A]='\0';
      }

      if ((!ReadFlag)&&(!BufSiz))
        Pass--;
    } /* If Not End */
  } while (Pass);

  fclose(F);


  /* List Used Labels                                         */

  if (Mode&DefinedLabels)
  { if (!(Mode&CompactMode))
      fprintf(stdout,"\n; %s Gremlin found the following labels: \n\n",Gremlin[GT]);
    else
      fprintf(stdout,"\n");

    A=4;

    do
    { switch (A)
      { case 4:
        case 2:
          LPtr=Head;
          A--;
          break;
        case 3:
          if (((LPtr->Status&'\x3f')==ByteLabel)&&(LPtr->Status&LabelDisplayed))
          { fprintf(stdout,FormStr,LPtr->Name);

            if (Mode&UseR800OpCodes)
              fprintf(stdout,"equ   ");
            else
              fprintf(stdout,"equ  ");

            sprintf(PBuf,"%02XH",LPtr->Value);

            if (Mode&LeadingZero)
              if (Mode&CompactMode)
                if ((PBuf[0]>='0')&&(PBuf[0]<='9'))
                  fprintf(stdout,"   %s",PBuf);
                else
                  fprintf(stdout,"  0%s",PBuf);
              else
                fprintf(stdout,"  0%s",PBuf);
            else
              fprintf(stdout,"  %s",PBuf);

            if (LPtr->Value&0x80)
              fprintf(stdout," ; %4i",-256+LPtr->Value);
            else
              fprintf(stdout," ; %+4i",LPtr->Value);

            if ((LPtr->Value>0x1F)&&(LPtr->Value!=0x7F))
               fprintf(stdout," \"%c\"",(char)LPtr->Value);

            fprintf(stdout,"\n");
          }
          break;
        case 1:
          if (((LPtr->Status&'\x3F')==WordLabel)&&((Mode&DiscardDefLabel)?(LPtr->Status&(LabelDisplayed|LabelDefined))==LabelDisplayed:LPtr->Status&LabelDisplayed))
          { fprintf(stdout,FormStr,LPtr->Name);

            if (Mode&UseR800OpCodes)
              fprintf(stdout,"equ   ");
            else
              fprintf(stdout,"equ  ");

            sprintf(PBuf,"%04XH\n",LPtr->Value);

            if (Mode&LeadingZero)
              if (Mode&CompactMode)
                if ((PBuf[0]>='0')&&(PBuf[0]<='9'))
                  fprintf(stdout," %s",PBuf);
                else
                  fprintf(stdout,"0%s",PBuf);
              else
                fprintf(stdout,"0%s",PBuf);
            else
              fprintf(stdout,"%s",PBuf);
          }
          break;
      }

      if (LPtr!=NULL)
        LPtr=LPtr->Next;

      if (LPtr==NULL)
        A--;
    } while (A);
  }


  /* The End.                                                 */

  fprintf(stdout,"\n");

  if (FormStr[0])
    fprintf(stdout,FormStr,"");

  fprintf(stdout,"end\n");

        if (!(Mode&CompactMode))
  { fprintf(stdout,"\n; %s Gremlin disassembled %lu instructions and \n",Gremlin[GT],InstCnt);

    if (InstCnt<0x80)
      fprintf(stdout,"; now wants to disassemble your refrigerator with a chain-saw...\n");
    else if (InstCnt<0x100)
      fprintf(stdout,"; is looking curiously at your computer... Swaying an axe!\n");
    else if (InstCnt<0x200)
      fprintf(stdout,"; wants more! It is poking yourr keiybaoardj*^.oO\n");
    else if (InstCnt<0x300)
      fprintf(stdout,"; is contented, by now, purring like a kitten... Tearing off your curtains!\n");
    else if (InstCnt<0x400)
      fprintf(stdout,"; is satisfied, for a while, leaving your printer alone, finally.\n");
    else if (InstCnt<0x600)
      fprintf(stdout,"; is so happy you can count every razor-blade teeth in its mouth.\n");
    else if (InstCnt<0x800)
      fprintf(stdout,"; is so happy that cannot stop laughing... But it never could, anyway...\n");
    else if (InstCnt<0xA00)
      fprintf(stdout,"; fell deeply asleep, laughing in dreams... Slobbering all over your disks...\n");
    else if (InstCnt<0xC00)
      fprintf(stdout,"; is thinking about retirement... Nah!\n");
    else if (InstCnt<0xD00)
      fprintf(stdout,"; is planning its retirement... And took the car keys!\n");
    else
      fprintf(stdout,"; is out of business, but will be back! By the way, where is the car...?!\n");
  }

  return(Okay);
}
