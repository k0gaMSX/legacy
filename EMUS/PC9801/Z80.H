/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                           Z80.h                         **/
/**                                                         **/
/** This file contains declarations relevant to emulation   **/
/** of Z80 CPU. See MSX.h for #defines related to drivers   **/
/** and MSX emulation.                                      **/
/**                                                         **/
/** Copyright (C) Marat Fayzullin 1994,1995                 **/
/**     You are not allowed to distribute this software     **/
/**     commercially. Please, notify me, if you make any    **/
/**     changes to this file.                               **/
/*************************************************************/

#define DEBUG                  /* Compile debugging version  */
#define INTERRUPTS             /* Compile interrupts code    */
#define LSB_FIRST              /* Compile for low-endian CPU */
/* #define LAME */             /* Compile simplified version */


#define S_FLAG      0x80
#define Z_FLAG      0x40
#define H_FLAG      0x10
#define P_FLAG      0x04
#define V_FLAG      0x04
#define N_FLAG      0x02
#define C_FLAG      0x01


/**********************************************************/
/*** NOTICE: sizeof(byte)=1 and sizeof(word)=2          ***/
/**********************************************************/
typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;
typedef signed char offset;


/*** Interrupts *******************************************/
/*** Interrupt-related variables.                       ***/
/**********************************************************/
#ifdef INTERRUPTS
extern dword IPeriod; /* Number of commands between internal interrupts */
extern dword Cnt;
extern byte IntSync;  /* Generate internal interrupts if IntSync==1     */
extern byte IFlag;    /* If IFlag==1, generate interrupt and set to 0   */
#endif


/*** Trace and Trap ***************************************/
/*** Switches to turn tracing on and off in DEBUG mode. ***/
/**********************************************************/
#ifdef DEBUG
extern byte Trace;  /* Tracing is on if Trace==1  */
extern word Trap;   /* When PC==Trap, set Trace=1 */
#endif


/**********************************************************/
/*** #define LSB_FIRST for machines where least         ***/
/*** signifcant byte goes first.                        ***/
/**********************************************************/
typedef union
{
#ifdef LSB_FIRST
  struct { byte l,h; } B;
#else
  struct { byte h,l; } B;
#endif
  word W;
} pair;


typedef struct
{
  pair AF,BC,DE,HL,IX,IY,PC,SP;
  pair AF1,BC1,DE1,HL1;
  byte IFF,I;
} reg;


/*** Interpret Z80 code: **********************************/
/*** RAM starts at Addr and registers have initial      ***/
/*** values from Regs. PC value at which emulation      ***/
/*** stopped is returned by this function.              ***/
/**********************************************************/
word Z80(reg R);


/*** Input/Output values from/to ports: *******************/
/*** These are called on IN and OUT commands and should ***/
/*** supplied by machine-dependent part of the code.    ***/
/**********************************************************/
byte DoIn(byte Port);
void DoOut(byte Port,byte Value);


#ifdef DEBUG
/*** Single-step debugger *********************************/
/*** This function should exist if DEBUG is #defined.   ***/
/*** If Trace==1 it is called after each command        ***/
/*** executed by the CPU and given address of the       ***/
/*** address space and the file.                        ***/
/**********************************************************/
void Debug(reg *R);
#endif
