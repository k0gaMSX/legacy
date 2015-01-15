/**********************************************************************/
/*                                                                    */
/* Code optimizer for ASCII MSX C 1.1 and MSX C 1.2                   */
/* Copyright (c) 1994 by XelaSoft                                     */
/* A. Wulms                                                           */
/* Pelikaanhof 127 c                                                  */
/* 2312 EG Leiden (Netherlands)                                       */
/*                                                                    */
/* This code optimizer takes the .mac source file created by CF and   */
/* CG and replaces some 8080 code sequences by Z80 instructions.      */
/* It works the best for code which has been produced with the        */
/* nonrec switch and the register allocation on (#pragma nonrec and   */
/* #pragma regalo, this second one is the default for ASCII MSX C)    */
/*                                                                    */
/* This code optimizer can be compiled on both the MSX and the PC:    */
/* -UNIX:-use cc or gcc, remove comment round #define UNIX_C          */
/* -PC:  -use Borland Turbo C (other C compilers might work as well)  */
/* -MSX: -use ASCII MSX C 1.1, remove comment round #define MSXC_11   */
/*       -use ASCII MSX C 1.2, remove comment round #define MSXC_12   */
/*                                                                    */
/* This source may be distributed in UNMODIFIED form only. You can    */
/* change it for own use, but it is not permitted to distribute such  */
/* a changed source or the object code beloning to it.                */
/*                                                                    */
/* When you have interesting ideas for future versions of this	      */
/* code optimizer, then please contact me at the adres at the start   */
/* of this comment or via email: wulms@wi.leidenuniv.nl	              */
/*                                                                    */
/* version history:                                                   */
/*   -version 1.0, release date:  1-27-94                             */
/*     the following optimizations are performed:                     */
/*      -replace BC load groups                                       */
/*      -replace DE load groups                                       */
/*      -remove  EX DE,HL pairs                                       */
/*      -replace CALL/RET pairs with jp instructions                  */
/*      -replace CALL INP  with the Z80 input instruction             */
/*      -replace CALL OUTp with the Z80 output instruction            */
/*      -replace CALL SHIFT with the Z80 shift instructions           */
/*       optionally generate code which does not check for zero count */
/*      -optionally replace CALL MUL with the R800 mult instructions  */
/*   -version 1.1, release date: 11-15-94                             */
/*      -bug removed: do not replace CALL/RET pairs when a condition  */
/*                    is following the RET instruction!               */
/*      -show optimized statements by printing '; -optimized-' behind */
/*       them                                                         */
/*      -buffered output replaced with raw output for speed up        */
/*       purposes (speed up of 206% on the MSX turbo R with C 1.2)    */
/*      -new pcmsx.h file used for porting to UNIX                    */
/*      -source cleaned up (more/better/different comment, etc)       */
/*                                                                    */
/**********************************************************************/

/* #define UNIX_C */
/* #define MSXC_11 */
#define MSXC_12

#ifdef MSXC_11
#define MSX_C
#endif

#ifdef MSXC_12
#define MSX_C
#endif

/* #define speedtst */

#include <stdio.h>

#ifdef MSXC_12
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <io.h>
#endif
#ifdef MSXC_11
#define CPMEOF 0x1a
#define O_RDONLY (0)
#endif
#ifdef __MSDOS__
#include <stdlib.h>
#include <string.h>
#include <alloc.h>
#include <fcntl.h>
#include <io.h>
#endif
#ifdef speedtst
#include <mytype.h>
#endif
#include <pcmsx.h>

#pragma nonrec

/* some defines for the MSX linker that only supports 6 characters (sic!) */
#define outbuffer outb1
#define outbufpos outb2
#define outbufspace outb3
#define putcoutpb2 putco1
#define putcoutpb putco2
#define optimize_de opt_de
#define optimize_bc opt_bc
#define opt_mul_hd opt_mhd
#define opt_mul_ab opt_mab
#define opt_ex_de_hl optxdh
#define opt_extrnmul optxmu
#define opt_slhb  optslh
#define opt_slab  optsla
#define opt_srnhb optsrn
#define opt_srihb optsri
#define opt_srab  optsra

/* start of the real code: typedefs, defines, global vars, etc */
typedef struct {
  char *name;
  char code;
} instr_element;

char **strbuf;      /* buffers for strings that have been read */

char *inbuffer;     /* input buffer info */
char *inbufpos;
unsigned inbufcount;
#define inbufsize 9*1024

char *outbuffer;    /* output buffer info */
char *outbufpos;
unsigned outbufspace;
#define outbufsize 9*1024

FD sfile; /* the input file  */
FD dfile; /* the output file */

int bc_count = 0;   /* # bc load  groups that has been replaced  */
int de_count = 0;   /* # de load  groups that has been replaced  */
int ex_count = 0;   /* # ex de,hl groups that has been replaced  */
int mul_count = 0;  /* # call mul instr.  that has been replaced */
int call_count = 0; /* # call/ret pairs that has been replaced   */
int io_count = 0;   /* # in/out instructions		         */
int shft_count = 0; /* # shift calls that has been replaced      */

BOOL eof_flg = 0;     /* sourcefile not yet finished                   */
BOOL opt_R800 = 0;    /* true when optimizing for the R800             */
BOOL shft_noZchk = 0; /* true when shift does not check for zero count */
BOOL shft_warning = 0;/* true when shift warning is neccesary          */

/* function prototypes */
void explain();       /* explain usage of the program     */
void error();         /* give error and abort             */
void dskfull();       /* give disk full error and abort   */
int getcinpb();       /* get character from input buffer  */
char *frdstring();    /* read string from input buffer    */
int flushoutbuf();    /* flush the output buffer          */
void putcoutpb2();    /* put character in output buffer   */
void putcoutpb();     /* put char with \n conversion      */
void fputstr();       /* put a string in output buffer    */
void fprtstr();       /* print a str and append \n to it  */
void fprtoptimize();  /* print a str and append 'optim..' */
BOOL firststr();      /* compare first part of string     */
BOOL chk_var_hl();    /* chk for LD HL,(NN) or LD (NN),HL */
char chkinstr();      /* chk the instrunction type        */
char optimize_de();   /* optimize various instructions    */
char opt_ex_de_hl();
char optimize_bc();
char opt_push_hl();
char opt_mul_hd();
char opt_mul_ab();
char opt_outp();
char opt_inp();
char opt_call();
char opt_extrnmul();
char opt_slhb();
char opt_slab();
char opt_srnhb();
char opt_srihb();
char opt_srab();
char opt_b();
char convcode();      /* convert one instruction (group)  */
void convert();       /* convert the complete code        */
char *malchkz();      /* allocate memory with zero check  */
void allocstrbufs();  /* allocate the string buffers      */
void freestrbufs();   /* free the string buffers          */
void main();          /* we all know this one             */

/****************************************/
/* explain how to use the program	*/
/****************************************/
void explain()
{
  puts("\nUse\n>optimize source destination [options]\n");
  puts("to optimize the file named 'source', generated by ASCII C, for the Z80 & R800\n");
  puts("and write the optimized output to the file named 'destination'\n\n");
  puts("Options:\n");
  puts("/r : make R800 code (use R800 multiply instructions)\n");
  puts("/z : don't check on zero count with the shift (<< and >>) instructions\n");
  exit(128); /* abort code, under MSX DOS 2: abort the batch file */
}

/****************************************/
/* print an error message and abort	*/
/****************************************/
void error(txt)
char *txt;
{
  puts(txt);
  exit(128); /* abort code, under MSX DOS 2: abort the batch file */
}

/****************************************/
/* Generate the Disk full error message */
/****************************************/
void dskfull()
{
  error ("Disk full\n");
}

/****************************************/
/* read a character from the input      */
/****************************************/
int getcinpb()
{
  char temp;

  do {
    if (!inbufcount) {
      inbufcount = read(sfile, inbufpos = inbuffer, inbufsize);
      if (!inbufcount)
        return EOF;
    }
    inbufcount--;
  } while ((temp=*inbufpos++) == 13);  /* skip possible CR's */
  if (temp == CPMEOF) {
    inbufpos--; inbufcount++;
    return EOF;
  }
  return temp;
}

/****************************************/
/* read 1 string			*/
/****************************************/
char *frdstring(string)
char *string;
{
  int  temp;
  char *strptr = string;

  while ((((char)(temp = getcinpb())) != '\n') && (temp != EOF))
    *strptr++ = (char)temp;
  *strptr = 0;
  if (temp==EOF)
    eof_flg = 1;
  return string;
}

/****************************************/
/* flush the output buffer              */
/****************************************/
int flushoutbuf()
{
  int temp;
  if (outbufspace != outbufsize) {
    temp = write(dfile, outbufpos = outbuffer, outbufsize-outbufspace);
    outbufspace = outbufsize;
    return temp;
  }
  else
    return 0;
}

/****************************************/
/* Write a character to the output      */
/* Note: a dskfull() error is generated */
/*       when the disk is full          */
/****************************************/
void putcoutpb2(ch)
char ch;
{    
  if (!outbufspace) {
    outbufspace = write(dfile, outbufpos = outbuffer, outbufsize);
    if (outbufspace != outbufsize)
      dskfull();
  }
  outbufspace--;
  *outbufpos++ = ch;
}

/****************************************/
/* Write a character to the output      */
/* Note: a newline is converted to a    */
/*       cr/lf combination              */
/* Note: can generate a dskfull() error */
/****************************************/
void putcoutpb(ch)
char ch;
{
#ifndef UNIX_C
  if (ch == '\n')    /* convert newline on non UNIX systems */
    putcoutpb2((char)13);
#endif
  putcoutpb2(ch);
}

/****************************************/
/* print a string to the output file    */
/* Note: can generate a dskfull() error */
/****************************************/
void fputstr(string)
char *string;
{
  char temp;

  while (temp = *string++)
    putcoutpb(temp);
}

/****************************************/
/* print a string to the output file    */
/* and append a '\n' character to it    */
/* Note: can generate a dskfull() error */
/****************************************/
void fprtstr(string)
char *string;
{
  fputstr(string);
  putcoutpb('\n');
}

/****************************************/
/* print a string to the output file    */
/* with the text 'optimized' behind it  */
/* Note: can generate a dskfull() error */
/****************************************/
void fprtoptimize(string)
char *string;
{
  fputstr(string);
  fprtstr("\t; -optimized-");
}

/****************************************/
/* check if string2 is the prefix of	*/
/* string1				*/
/* out: TRUE when this is the case	*/
/****************************************/
BOOL firststr(str1, str2)
char *str1;
char *str2;
{
  while (*str2 && (*str2==*str1++))
    str2++;
  return !(*str2);
}

/****************************************/
/* check if the instruction is var),hl  */
/****************************************/
BOOL chk_var_hl(string)
char *string;
{
  char temp;

  while ((temp = *string++) && (temp != ')'))
    ;
  if (!temp)
    return 0;
  if (*string++ != ',')
    return 0;
  if (*string != 'h')
    return 0;
  return 1;
}

/****************************************/
/* analyse instruction type of the line */
/* out: 0 = ex de,hl			*/
/*      1 = push hl			*/
/*	2 = ld c,l			*/
/*	3 = ld b,h			*/
/*	4 = ld l,c			*/
/*	5 = ld h,b			*/
/*	6 = pop hl			*/
/*      7 = ld (var),hl			*/
/*      8 = ld hl,(var)			*/
/*      9 = call ?mulhd			*/
/*      10 = call ?mulab		*/
/*      11 = ret  (uncond. ret)         */
/*      12 = call label			*/
/*      13 = call outp@			*/
/*      14 = call inp@			*/
/*      15 = extrn ?mul			*/
/*      16 = extrn outp/inp/?shift	*/
/*      17 = call ?slhb ( hl <<= b )	*/
/*      18 = call ?slab ( a <<= b )     */
/*      19 = call ?srnhb ( hl >>= b)	*/
/*      20 = call ?srihb ( hl >>= b)    */
/*      21 = call ?srab  ( a >>= b)	*/
/*      22 = ld b,1			*/
/*      23 = ld b,2			*/
/*      254 = ret\t  (cond. ret)        */
/*      254 = rest			*/
/****************************************/
char chkinstr(string)
char *string;
{
  instr_element *actinstr;
  static instr_element Cinstr[] = {
    "all\t?MULHD", 9,
    "all\t?MULAB", 10,
    "all\toutp@",13,
    "all\tinp@",14,
    "all\t?SLHB",17,
    "all\t?SLAB",18,
    "all\t?SRNHB",19,
    "all\t?SRIHB",20,
    "all\t?SRAB",21,
    "all\t",12,
    NULL, 0
  };
  static instr_element Einstr[] = {
    "x\tde,hl"   , 0,
    "xtrn\t?MULHD",15,
    "xtrn\t?MULAB",15,
    "xtrn\toutp@",16,
    "xtrn\tinp@",16,
    "xtrn\t?SLHB",16,
    "xtrn\t?SLAB",16,
    "xtrn\t?SRNHB",16,
    "xtrn\t?SRIHB",16,
    "xtrn\t?SRAB",16,
    NULL, 0
  };
  static instr_element Linstr[] = {
    "d\thl,(",8,
    "d\tc,l", 2,
    "d\tb,h", 3,
    "d\tl,c", 4,
    "d\th,b", 5,
    "d\tb,1",22,
    "d\tb,2",23,
    NULL, 0
  };
  static instr_element Pinstr[] = {
    "ush\thl", 1,
    "op\thl", 6,
    NULL, 0
  };
  static instr_element Rinstr[] = {
    "et\t",254,
    "et", 11,
    NULL, 0
  };
  static instr_element *instptrs[26] = {
    NULL  , NULL  , Cinstr, NULL  , Einstr, NULL  ,  /* A,B,C,D,E,F */
    NULL  , NULL  , NULL  , NULL  , NULL  , Linstr,  /* G,H,I,J,K,L */
    NULL  , NULL  , NULL  , Pinstr, NULL  , Rinstr,  /* M,N,O,P,Q,R */
    NULL  , NULL  , NULL  , NULL  , NULL  , NULL  ,  /* S,T,U,V,W,X */
    NULL  , NULL                                     /* Y,Z         */
  };

  if (*string++ != '\t')
    return 254;

  if (!islower(*string))
    return 254;

  if ((actinstr = instptrs[(*string++)-'a']) == NULL)
    return 254;

  while (actinstr->name) {
    if (firststr(string, actinstr->name))
      return actinstr->code;
    actinstr++;
  }

  if (firststr(string-1,"ld\t("))
    if (chk_var_hl(string+3))
      return 7;

  return 254;
}

/****************************************/
/* replace a DE load group by a load    */
/* DE instruction			*/
/* in: string: 1st string of the group  */
/* out: instruction code of the last    */
/*      unprocessed string		*/
/****************************************/
char optimize_de(string)
char *string;
{
  char nextinstr;
  char *strptr;

  if (eof_flg) {
    fprtstr(string);
    fprtstr(strbuf[0]);
    return 255;
  }

  if (nextinstr = chkinstr(frdstring(strbuf[1]))) {
    fprtstr(string);
    fprtstr(strbuf[0]);
    strcpy(string, strbuf[1]);
    return nextinstr;
  }

  strptr = strbuf[0]+4;   /* skip \tld\t  */
  if (*strptr == '(') {
    while (*strptr++ != ')')
      ;
    strptr++;             /* skip the ',' */
  }
  *strptr++ = 'd';
  *strptr   = 'e';        /* put DE on HL */
  fprtoptimize(strbuf[0]);
  de_count++;
  return 255;  /* code replaced => buffers are empty */
}

/****************************************/
/* optimise the ex_de_hl instructions   */
/****************************************/
char opt_ex_de_hl(string)
char *string;
{
  char nextinstr;

  if (eof_flg)
    return 254;    /* end of file => print the string */

  switch(nextinstr = chkinstr(frdstring(strbuf[0]))) {
    case  0: nextinstr = 255; ex_count++; break;
    case  7:
    case  8: nextinstr = optimize_de(string); break;
    default: fprtstr(string); strcpy(string, strbuf[0]); break;
  }
  return nextinstr;
}

/****************************************/
/* replace the load group by a BC load  */
/* instruction  			*/
/* in: codes : array with instruction	*/
/*             codes of the group	*/
/*     number: number of the string in	*/
/*             which the load instr     */
/*             would be   		*/
/*     string: 1st string of the group  */
/* out: instruction code of the last    */
/*      unprocessed string		*/
/****************************************/
char optimize_bc(codes, number,string)
int *codes;
unsigned number;
char *string;
{
  int tel, tel2;
  char *strptr;

  for (tel=tel2=0; tel != 3 &&
		   !eof_flg &&
		   chkinstr(frdstring(strbuf[++tel2])) == codes[tel];
		   tel++)
    ;

  if (tel != 3) {
    fprtstr(string);
    for (tel=0; tel != tel2; tel++)
      fprtstr(strbuf[tel]);
    strcpy(string, strbuf[tel2]); /* continue with the last read string */
    return chkinstr(string);
  }

  strptr = strbuf[number]+4; /* skip \tld\t  */
  if (*strptr == '(') {
    while (*strptr++ != ')')
      ;
    strptr++;                /* skip the ',' */
  }
  *strptr++ = 'b';
  *strptr   = 'c';           /* put BC on HL */
  fprtoptimize(strbuf[number]);
  bc_count++;
  return 255;  /* code replaced => buffers are empty */
}

/****************************************/
/* optimize the push_hl instrunctions   */
/* out: the instruction of the last     */
/*      unprocessed line       		*/
/****************************************/
char opt_push_hl(string)
char *string;
{
  static int group8[4] = {2,3,6};
  static int group4[4] = {5,7,6};
  char nextinstr;

  if (eof_flg)
    return 254;    /* end of file => print the string */

  switch(nextinstr = chkinstr(frdstring(strbuf[0]))) {
    case  4: nextinstr = optimize_bc(group4,2,string); break;
    case  8: nextinstr = optimize_bc(group8,0,string); break;
    default: fprtstr(string); strcpy(string, strbuf[0]); break;
  }
  return nextinstr;
}

/****************************************/
/* optimize the call ?mulhd instr	*/
/****************************************/
char opt_mul_hd(string)
char *string;
{
  if (opt_R800) {
    fprtoptimize("\tld\tc,e\t; -optimized-\n\tld\tb,d");
    fprtstr("\tdb\t0edh,0c3h\t; -optimized- (de:hl = hl*bc)");
    mul_count++;
  }
  else
    fprtstr(string);
  return 255;
}

/****************************************/
/* optimize the call ?mulab instr	*/
/****************************************/
char opt_mul_ab(string)
char *string;
{
  if (opt_R800) {
    fprtstr("\tdb\t0edh,0c1h\t; -optimized- (hl = a*b)");
    fprtoptimize("\tld\ta,l");
    mul_count++;
  }
  else
    fprtstr(string);
  return 255;
}

/****************************************/
/* optimize the call outp@ instr	*/
/****************************************/
char opt_outp()
{
  fprtoptimize("\tld\tc,l\t; -optimized-\n\tout\t(c),e");
  io_count++;
  return 255;
}

/****************************************/
/* optimize the call inp@ instr		*/
/****************************************/
char opt_inp()
{
  fprtoptimize("\tld\tc,l\t; -optimized-\n\tin\ta,(c)");
  io_count++;
  return 255;
}

/****************************************/
/* optimize the call label instr	*/
/****************************************/
char opt_call(string)
char *string;
{
  char nextinstr;
  char *strptr;

  if (eof_flg)
    return 254;    /* end of file => print the string */

  if ((nextinstr = chkinstr(frdstring(strbuf[0]))) != 11) {
    fprtstr(string); strcpy(string, strbuf[0]);
    return nextinstr;
  }

  strptr = string+1;        /* skip tab             */
  *strptr++ = 'j';          /* put JP on CA (from   */
  *strptr++ = 'p';          /* CALL)                */
  strcpy(strptr, strptr+2); /* erase LL (from CALL) */
  fprtoptimize(string);
  call_count++;
  return 255;
}

/****************************************/
/* Optimize an extrn ?mul instr.	*/
/* => erase it when optimizing for R800 */
/****************************************/
char opt_extrnmul(string)
char *string;
{
  if (!opt_R800)
    fprtstr(string);  /* Z80 => extrn ?mul  can stay */
  return 255;
}

/****************************************/
/* 16 bit shift left			*/
/****************************************/
char opt_slhb(count)
char count;
{
  if (count)
    while (count--)
      fprtoptimize("\tadd\thl,hl");
  else {
    if (!(shft_warning = shft_noZchk))
      fprtoptimize("\tinc\tb\t; -optimized-\n\tjr\t$+3");
    fprtoptimize("\tadd\thl,hl\t; -optimized-\n\tdjnz\t$-1");
  }
  shft_count++;
  return 255;
}

/****************************************/
/* 8 bit shift left			*/
/****************************************/
char opt_slab(count)
char count;
{
  if (count)
    while (count--)
      fprtoptimize("\tadd\ta,a");
  else {
    if (!(shft_warning = shft_noZchk))
      fprtoptimize("\tinc\tb\t; -optimized-\n\tjr\t$+3");
    fprtoptimize("\tadd\ta,a\t; -optimized-\n\tdjnz\t$-1");
  }
  shft_count++;
  return 255;
}

/****************************************/
/* 16 bit unsigned shift right		*/
/****************************************/
char opt_srnhb(count)
char count;
{
  if (count)
    while (count--)
      fprtoptimize("\tsrl\th\t; -optimized-\n\trr\tl");
  else {
    if (!(shft_warning = shft_noZchk))
      fprtoptimize("\tinc\tb\t; -optimized-\n\tjr\t$+6");
    fprtoptimize("\tsrl\th\t; -optimized-\n\trr\tl");
    fprtoptimize("\tdjnz\t$-4");
  }
  shft_count++;
  return 255;
}

/****************************************/
/* 16 bit signed shift right		*/
/****************************************/
char opt_srihb(count)
char count;
{
  if (count)
    while (count--)
      fprtoptimize("\tsra\th\t; -optimized-\n\trr\tl");
  else {
    if (!(shft_warning = shft_noZchk))
      fprtoptimize("\tinc\tb\t; -optimized-\n\tjr\t$+6");
    fprtoptimize("\tsra\th\t; -optimized-\n\trr\tl");
    fprtoptimize("\tdjnz\t$-4");
  }
  shft_count++;
  return 255;
}

/****************************************/
/* 8 bit unsigned shift right		*/
/****************************************/
char opt_srab(count)
char count;
{
  if (count)
    while (count--)
      fprtoptimize("\tsrl\ta");
  else {
    if (!(shft_warning = shft_noZchk))
      fprtoptimize("\tinc\tb\t; -optimized-\n\tjr\t$+4");
    fprtoptimize("\tsrl\ta\t; -optimized-\n\tdjnz\t$-2");
  }
  shft_count++;
  return 255;
}
  
/****************************************/
/* optimize  LD B,N instruction		*/
/* (for >> 1, >> 2, << 1, << 2)		*/
/****************************************/
char opt_b(count, string)
char count;
char *string;
{
  char nextinstr;

  if (eof_flg)
    return 254;    /* end of file => print the string */

  switch(nextinstr = chkinstr(frdstring(strbuf[0]))) {
    case  17: nextinstr = opt_slhb(count); break;
    case  18: nextinstr = opt_slab(count); break;
    case  19: nextinstr = opt_srnhb(count); break;
    case  20: nextinstr = opt_srnhb(count); break;
    case  21: nextinstr = opt_srab(count); break;
    default: fprtstr(string); strcpy(string, strbuf[0]); break;
  }
  return nextinstr;
}

/****************************************/
/* convert the current line		*/
/* in: line = line to be converted	*/
/*     actinstr = code of this line 	*/
/****************************************/
char convcode(actinstr, line)
char actinstr;
char *line;
{
  char ninstr;

  switch (actinstr) {
    case  0: ninstr = opt_ex_de_hl(line); break;
    case  1: ninstr = opt_push_hl(line); break;
    case  9: ninstr = opt_mul_hd(line); break;
    case 10: ninstr = opt_mul_ab(line); break;
    case 12: ninstr = opt_call(line); break;
    case 13: ninstr = opt_outp(); break;
    case 14: ninstr = opt_inp(); break;
    case 15: ninstr = opt_extrnmul(line); break;
    case 16: ninstr = 255; break;
    case 17: ninstr = opt_slhb((char)0); break;
    case 18: ninstr = opt_slab((char)0); break;
    case 19: ninstr = opt_srnhb((char)0); break;
    case 20: ninstr = opt_srihb((char)0); break;
    case 21: ninstr = opt_srab((char)0); break;
    case 22: ninstr = opt_b((char)1,line); break;
    case 23: ninstr = opt_b((char)2,line); break;
    default: ninstr = 255; fprtstr(line); break;
  }
  return ninstr;
}

/****************************************/
/* convert the file			*/
/****************************************/
void convert()
{
  char line[80];
  char nextinstr;

  while (!eof_flg) {
    frdstring(line);
    nextinstr = convcode(chkinstr(line),line);
    while (nextinstr != (char)255)
      nextinstr = convcode(nextinstr, line);
  }
}

/****************************************/
/* Ask for memory with checking for	*/
/* the NULL pointer			*/
/****************************************/
char *malchkz(aantal)
unsigned aantal;
{
  char *temp;

  if (!(temp = malloc(aantal)))
    error ("To little free memory\n");
  return temp;
}

/****************************************/
/* allocate memory for the string  	*/
/* buffers				*/
/****************************************/
void allocstrbufs()
{
  unsigned tel;

  strbuf = (char **)malchkz(sizeof(char *)*5);
  for (tel=0; tel != 5; tel++)
    strbuf[tel] = malchkz(sizeof(char) * 160);
}

/****************************************/
/* free the string buffers         	*/
/****************************************/
void freestrbufs()
{
  unsigned tel;

  for (tel=0; tel != 5; tel++)
    free(strbuf[tel]);
  free(strbuf);
}

/****************************************/
/* the main procedure			*/
/****************************************/
void main(paramc, paramptr)
int  paramc;
char *paramptr[];
{
  char string[80];

#ifdef speedtst
  int cnvtime;
#endif

  puts("Code optimizer for the Z80 & R800 version 1.1. Copyright (c) 1994 XelaSoft\n");

  if (paramc < 3)
    explain();
  while (paramc-- != 3) {
    if (!strcmp("/r",paramptr[paramc]) || !strcmp("/R",paramptr[paramc]))
      opt_R800 = 1;
    else if (!strcmp("/z",paramptr[paramc]) || !strcmp("/Z",paramptr[paramc]))
      shft_noZchk = 1;
    else
      explain();
  }

  allocstrbufs();
  inbufpos = inbuffer = malchkz(sizeof(char)*inbufsize);
  inbufcount = 0;
  outbufpos = outbuffer = malchkz(sizeof(char)*outbufsize);
  outbufspace = outbufsize;

  if ((sfile = open(paramptr[1],(int) O_RDONLY))==ERROR)
    error("Sourcefile can't be opened\n");
#ifdef UNIX_C
  if (!(dfile = open(paramptr[2], O_RDWR | O_CREAT | O_TRUNC, 0400 | 0200 | 0040 | 0004)) == ERROR)
#else
  if (!(dfile = creat(paramptr[2]))==ERROR)
#endif
    error("Destinationfile can't be created\n");

  fprtstr("; Code optimized with XelaSoft's code optimizer version 1.1");

#ifdef speedtst
  jiffy = 0;
#endif
  convert();  /* zet om */
#ifdef speedtst
  cnvtime = jiffy;
  printf("conversie tijd: %d\n",cnvtime);
#endif

  printf("Total number of optimizations: %d\n",
	 bc_count   + de_count + ex_count +
         call_count + io_count + shft_count +
         mul_count);

  if (shft_warning)
    puts("Warning: the >> and << instructions will not check for a zero count!\n");
  if (mul_count)
    puts("Warning: this code only works properly on the R800!\n");

  sprintf(string,"; # BC load groups replaced: %d\n", bc_count);
  fputstr(string);
  sprintf(string,"; # DE load groups replaced: %d\n", de_count);
  fputstr(string);
  sprintf(string,"; # EX DE,HL pairs removed: %d\n",  ex_count);
  fputstr(string);
  sprintf(string,"; # call/ret pairs replaced: %d\n", call_count);
  fputstr(string);
  sprintf(string,"; # in/out instr. used: %d\n", io_count);
  fputstr(string);
  sprintf(string,"; # shift instructions replaced %d\n", shft_count);
  fputstr(string);
  if (opt_R800) {
    sprintf(string,"; # R800 multiply instr. used: %d\n", mul_count);
    fputstr(string);
  }

  if (flushoutbuf() == EOF)
    dskfull();
  close(dfile);
  close(sfile);
  freestrbufs();
  free(inbuffer);
  free(outbuffer);
}
                                        