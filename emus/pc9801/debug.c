/** fMSX: portable MSX emulator ******************************/
/**                                                         **/
/**                         Debug.c                         **/
/**                                                         **/
/** This file contains the built-in debugging routine for   **/
/** the MSX emulator which is called on each Z80 step       **/
/** when Trap==TRUE.                                        **/
/**                                                         **/
/** fMSX98 extended about using these variables:            **/
/**   Trap = breakpoint address                             **/
/**   Trace = trace mode:                                   **/
/**     0: dont't call this debugger                        **/
/**     1: only checking breakpoint                         **/
/**     2: printing program counter and interval counter    **/
/**     3: printing registers                               **/
/**     4: enter this debugger                              **/
/**     5: don't leave this debugger                        **/
/**                                                         **/
/** fMSX   Copyright (C) Marat Fayzullin 1995               **/
/** fMSX98 Copyright (C) MURAKAMI Reki 1995,1996            **/
/**     You are not allowed to distribute this software     **/
/**     commercially. Please, notify me, if you make any    **/
/**     changes to this file.                               **/
/*************************************************************/

#include <dos.h>
#include <stdio.h>
#include <string.h>

#include "MSX.h"

#ifdef PC98
#include "pc98.h"
#endif /*PC98*/

#ifdef PCAT
#include <dpmi.h>
#include <go32.h>
#include "pcat.h"
extern _go32_dpmi_seginfo segRealOldIntKey;
extern _go32_dpmi_seginfo segRealNewIntKey;
extern _go32_dpmi_seginfo segOldIntKey;
extern _go32_dpmi_seginfo segNewIntKey;
#endif /*PCAT*/

char *Mnemonics[256] =
{
  "NOP","LD BC,#h","LD (BC),A","INC BC","INC B","DEC B","LD B,*h","RLCA",
  "EX AF,AF'","ADD HL,BC","LD A,(BC)","DEC BC","INC C","DEC C","LD C,*h","RRCA",
  "DJNZ *h","LD DE,#h","LD (DE),A","INC DE","INC D","DEC D","LD D,*h","RLA",
  "JR *h","ADD HL,DE","LD A,(DE)","DEC DE","INC E","DEC E","LD E,*h","RRA",
  "JR NZ,*h","LD HL,#h","LD (#h),HL","INC HL","INC H","DEC H","LD H,*h","DAA",
  "JR Z,*h","ADD HL,HL","LD HL,(#h)","DEC HL","INC L","DEC L","LD L,*h","CPL",
  "JR NC,*h","LD SP,#h","LD (#h),A","INC SP","INC (HL)","DEC (HL)","LD (HL),*h","SCF",
  "JR C,*h","ADD HL,SP","LD A,(#h)","DEC SP","INC A","DEC A","LD A,*h","CCF",
  "LD B,B","LD B,C","LD B,D","LD B,E","LD B,H","LD B,L","LD B,(HL)","LD B,A",
  "LD C,B","LD C,C","LD C,D","LD C,E","LD C,H","LD C,L","LD C,(HL)","LD C,A",
  "LD D,B","LD D,C","LD D,D","LD D,E","LD D,H","LD D,L","LD D,(HL)","LD D,A",
  "LD E,B","LD E,C","LD E,D","LD E,E","LD E,H","LD E,L","LD E,(HL)","LD E,A",
  "LD H,B","LD H,C","LD H,D","LD H,E","LD H,H","LD H,L","LD H,(HL)","LD H,A",
  "LD L,B","LD L,C","LD L,D","LD L,E","LD L,H","LD L,L","LD L,(HL)","LD L,A",
  "LD (HL),B","LD (HL),C","LD (HL),D","LD (HL),E","LD (HL),H","LD (HL),L","HALT","LD (HL),A",
  "LD A,B","LD A,C","LD A,D","LD A,E","LD A,H","LD A,L","LD A,(HL)","LD A,A",
  "ADD B","ADD C","ADD D","ADD E","ADD H","ADD L","ADD (HL)","ADD A",
  "ADC B","ADC C","ADC D","ADC E","ADC H","ADC L","ADC (HL)","ADC A",
  "SUB B","SUB C","SUB D","SUB E","SUB H","SUB L","SUB (HL)","SUB A",
  "SBC B","SBC C","SBC D","SBC E","SBC H","SBC L","SBC (HL)","SBC A",
  "AND B","AND C","AND D","AND E","AND H","AND L","AND (HL)","AND A",
  "XOR B","XOR C","XOR D","XOR E","XOR H","XOR L","XOR (HL)","XOR A",
  "OR B","OR C","OR D","OR E","OR H","OR L","OR (HL)","OR A",
  "CP B","CP C","CP D","CP E","CP H","CP L","CP (HL)","CP A",
  "RET NZ","POP BC","JP NZ,#h","JP #h","CALL NZ,#h","PUSH BC","ADD *h","RST 00h",
  "RET Z","RET","JP Z,#h","PREFIX CBh","CALL Z,#h","CALL #h","ADC *h","RST 08h",
  "RET NC","POP DE","JP NC,#h","OUTA (*h)","CALL NC,#h","PUSH DE","SUB *h","RST 10h",
  "RET C","EXX","JP C,#h","INA (*h)","CALL C,#h","PREFIX DDh","SBC *h","RST 18h",
  "RET PO","POP HL","JP PO,#h","EX HL,(SP)","CALL PO,#h","PUSH HL","AND *h","RST 20h",
  "RET PE","LD PC,HL","JP PE,#h","EX DE,HL","CALL PE,#h","PREFIX EDh","XOR *h","RST 28h",
  "RET P","POP AF","JP P,#h","DI","CALL P,#h","PUSH AF","OR *h","RST 30h",
  "RET M","LD SP,HL","JP M,#h","EI","CALL M,#h","PREFIX FDh","CP *h","RST 38h"
};

char *MnemonicsCB[256] =
{
  "RLC B","RLC C","RLC D","RLC E","RLC H","RLC L","RLC xHL","RLC A",
  "RRC B","RRC C","RRC D","RRC E","RRC H","RRC L","RRC xHL","RRC A",
  "RL B","RL C","RL D","RL E","RL H","RL L","RL xHL","RL A",
  "RR B","RR C","RR D","RR E","RR H","RR L","RR xHL","RR A",
  "SLA B","SLA C","SLA D","SLA E","SLA H","SLA L","SLA xHL","SLA A",
  "SRA B","SRA C","SRA D","SRA E","SRA H","SRA L","SRA xHL","SRA A",
  "SLL B","SLL C","SLL D","SLL E","SLL H","SLL L","SLL xHL","SLL A",
  "SRL B","SRL C","SRL D","SRL E","SRL H","SRL L","SRL xHL","SRL A",
  "BIT 0,B","BIT 0,C","BIT 0,D","BIT 0,E","BIT 0,H","BIT 0,L","BIT 0,(HL)","BIT 0,A",
  "BIT 1,B","BIT 1,C","BIT 1,D","BIT 1,E","BIT 1,H","BIT 1,L","BIT 1,(HL)","BIT 1,A",
  "BIT 2,B","BIT 2,C","BIT 2,D","BIT 2,E","BIT 2,H","BIT 2,L","BIT 2,(HL)","BIT 2,A",
  "BIT 3,B","BIT 3,C","BIT 3,D","BIT 3,E","BIT 3,H","BIT 3,L","BIT 3,(HL)","BIT 3,A",
  "BIT 4,B","BIT 4,C","BIT 4,D","BIT 4,E","BIT 4,H","BIT 4,L","BIT 4,(HL)","BIT 4,A",
  "BIT 5,B","BIT 5,C","BIT 5,D","BIT 5,E","BIT 5,H","BIT 5,L","BIT 5,(HL)","BIT 5,A",
  "BIT 6,B","BIT 6,C","BIT 6,D","BIT 6,E","BIT 6,H","BIT 6,L","BIT 6,(HL)","BIT 6,A",
  "BIT 7,B","BIT 7,C","BIT 7,D","BIT 7,E","BIT 7,H","BIT 7,L","BIT 7,(HL)","BIT 7,A",
  "RES 0,B","RES 0,C","RES 0,D","RES 0,E","RES 0,H","RES 0,L","RES 0,(HL)","RES 0,A",
  "RES 1,B","RES 1,C","RES 1,D","RES 1,E","RES 1,H","RES 1,L","RES 1,(HL)","RES 1,A",
  "RES 2,B","RES 2,C","RES 2,D","RES 2,E","RES 2,H","RES 2,L","RES 2,(HL)","RES 2,A",
  "RES 3,B","RES 3,C","RES 3,D","RES 3,E","RES 3,H","RES 3,L","RES 3,(HL)","RES 3,A",
  "RES 4,B","RES 4,C","RES 4,D","RES 4,E","RES 4,H","RES 4,L","RES 4,(HL)","RES 4,A",
  "RES 5,B","RES 5,C","RES 5,D","RES 5,E","RES 5,H","RES 5,L","RES 5,(HL)","RES 5,A",
  "RES 6,B","RES 6,C","RES 6,D","RES 6,E","RES 6,H","RES 6,L","RES 6,(HL)","RES 6,A",
  "RES 7,B","RES 7,C","RES 7,D","RES 7,E","RES 7,H","RES 7,L","RES 7,(HL)","RES 7,A",
  "SET 0,B","SET 0,C","SET 0,D","SET 0,E","SET 0,H","SET 0,L","SET 0,(HL)","SET 0,A",
  "SET 1,B","SET 1,C","SET 1,D","SET 1,E","SET 1,H","SET 1,L","SET 1,(HL)","SET 1,A",
  "SET 2,B","SET 2,C","SET 2,D","SET 2,E","SET 2,H","SET 2,L","SET 2,(HL)","SET 2,A",
  "SET 3,B","SET 3,C","SET 3,D","SET 3,E","SET 3,H","SET 3,L","SET 3,(HL)","SET 3,A",
  "SET 4,B","SET 4,C","SET 4,D","SET 4,E","SET 4,H","SET 4,L","SET 4,(HL)","SET 4,A",
  "SET 5,B","SET 5,C","SET 5,D","SET 5,E","SET 5,H","SET 5,L","SET 5,(HL)","SET 5,A",
  "SET 6,B","SET 6,C","SET 6,D","SET 6,E","SET 6,H","SET 6,L","SET 6,(HL)","SET 6,A",
  "SET 7,B","SET 7,C","SET 7,D","SET 7,E","SET 7,H","SET 7,L","SET 7,(HL)","SET 7,A"
};

char *MnemonicsED[256] =
{
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "IN B,(C)","OUT (C),B","SBC HL,BC","LD (#h),BC","UNDEF","RETN","IM 0","LD I,A",
  "IN C,(C)","OUT (C),C","ADC HL,BC","LD BC,(#h)","UNDEF","RETI","UNDEF","LD R,A",
  "IN D,(C)","OUT (C),D","SBC HL,DE","LD (#h),DE","UNDEF","UNDEF","IM 1","LD A,I",
  "IN E,(C)","OUT (C),E","ADC HL,DE","LD DE,(#h)","UNDEF","UNDEF","IM 2","LD A,R",
  "IN H,(C)","OUT (C),H","SBC HL,HL","LD (#h),HL","UNDEF","UNDEF","UNDEF","RRD",
  "IN L,(C)","OUT (C),L","ADC HL,HL","LD HL,(#h)","UNDEF","UNDEF","UNDEF","RLD",
  "IN F,(C)","OUT (C),F","SBC HL,SP","LD (#h),SP","UNDEF","UNDEF","UNDEF","UNDEF",
  "IN A,(C)","OUT (C),A","ADC HL,SP","LD SP,(#h)","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "LDI","CPI","INI","OUTI","UNDEF","UNDEF","UNDEF","UNDEF",
  "LDD","CPD","IND","OUTD","UNDEF","UNDEF","UNDEF","UNDEF",
  "LDIR","CPIR","INIR","OTIR","UNDEF","UNDEF","UNDEF","UNDEF",
  "LDDR","CPDR","INDR","OTDR","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF2","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","UNDEF",
  "UNDEF","UNDEF","UNDEF","UNDEF","UNDEF","BIOS","UNDEF","UNDEF"
};

char *MnemonicsXX[256] =
{
  "NOP","LD BC,#h","LD (BC),A","INC BC","INC B","DEC B","LD B,*h","RLCA",
  "EX AF,AF'","ADD I%,BC","LD A,(BC)","DEC BC","INC C","DEC C","LD C,*h","RRCA",
  "DJNZ *h","LD DE,#h","LD (DE),A","INC DE","INC D","DEC D","LD D,*h","RLA",
  "JR *h","ADD I%,DE","LD A,(DE)","DEC DE","INC E","DEC E","LD E,*h","RRA",
  "JR NZ,*h","LD I%,#h","LD (#h),I%","INC I%","INC I%h","DEC I%h","LD I%h,*h","DAA",
  "JR Z,*h","ADD I%,I%","LD I%,(#h)","DEC I%","INC I%l","DEC I%l","LD I%l,*h","CPL",
  "JR NC,*h","LD SP,#h","LD (#h),A","INC SP","INC (I%+*h)","DEC (I%+*h)","LD (I%+*h),*h","SCF",
  "JR C,*h","ADD I%,SP","LD A,(#h)","DEC SP","INC A","DEC A","LD A,*h","CCF",
  "LD B,B","LD B,C","LD B,D","LD B,E","LD B,I%h","LD B,I%l","LD B,(I%+*h)","LD B,A",
  "LD C,B","LD C,C","LD C,D","LD C,E","LD C,I%h","LD C,I%l","LD C,(I%+*h)","LD C,A",
  "LD D,B","LD D,C","LD D,D","LD D,E","LD D,I%h","LD D,I%l","LD D,(I%+*h)","LD D,A",
  "LD E,B","LD E,C","LD E,D","LD E,E","LD E,I%h","LD E,I%l","LD E,(I%+*h)","LD E,A",
  "LD I%h,B","LD I%h,C","LD I%h,D","LD I%h,E","LD I%h,I%h","LD I%h,I%l","LD H,(I%+*h)","LD I%h,A",
  "LD I%l,B","LD I%l,C","LD I%l,D","LD I%l,E","LD I%l,I%h","LD I%l,I%l","LD L,(I%+*h)","LD I%l,A",
  "LD (I%+*h),B","LD (I%+*h),C","LD (I%+*h),D","LD (I%+*h),E","LD (I%+*h),H","LD (I%+*h),L","HALT","LD (I%+*h),A",
  "LD A,B","LD A,C","LD A,D","LD A,E","LD A,I%h","LD A,L","LD A,(I%+*h)","LD A,A",
  "ADD B","ADD C","ADD D","ADD E","ADD I%h","ADD I%l","ADD (I%+*h)","ADD A",
  "ADC B","ADC C","ADC D","ADC E","ADC I%h","ADC I%l","ADC (I%+*h)","ADC,A",
  "SUB B","SUB C","SUB D","SUB E","SUB I%h","SUB I%l","SUB (I%+*h)","SUB A",
  "SBC B","SBC C","SBC D","SBC E","SBC I%h","SBC I%l","SBC (I%+*h)","SBC A",
  "AND B","AND C","AND D","AND E","AND I%h","AND I%l","AND (I%+*h)","AND A",
  "XOR B","XOR C","XOR D","XOR E","XOR I%h","XOR I%l","XOR (I%+*h)","XOR A",
  "OR B","OR C","OR D","OR E","OR I%h","OR I%l","OR (I%+*h)","OR A",
  "CP B","CP C","CP D","CP E","CP I%h","CP I%l","CP (I%+*h)","CP A",
  "RET NZ","POP BC","JP NZ,#h","JP #h","CALL NZ,#h","PUSH BC","ADD *h","RST 00h",
  "RET Z","RET","JP Z,#h","PREFIX CBh","CALL Z,#h","CALL #h","ADC *h","RST 08h",
  "RET NC","POP DE","JP NC,#h","OUTA (*h)","CALL NC,#h","PUSH DE","SUB *h","RST 10h",
  "RET C","EXX","JP C,#h","INA (*h)","CALL C,#h","PREFIX DDh","SBC *h","RST 18h",
  "RET PO","POP I%","JP PO,#h","EX I%,(SP)","CALL PO,#h","PUSH I%","AND *h","RST 20h",
  "RET PE","LD PC,I%","JP PE,#h","EX DE,I%","CALL PE,#h","PREFIX EDh","XOR *h","RST 28h",
  "RET P","POP AF","JP P,#h","DI","CALL P,#h","PUSH AF","OR *h","RST 30h",
  "RET M","LD SP,I%","JP M,#h","EI","CALL M,#h","PREFIX FDh","CP *h","RST 38h"
};

word disasm(word addr,char *T);
void PrintRegs(reg *R);

extern volatile int ExitFlag;

extern byte PSLReg;
extern byte SSLReg[4];
extern byte PSL[4],SSL[4];

byte Trace = 0;
word Trap = 0;


/*** Single-step debugger ****************************/

void Debug(reg *R)
{
  byte d0,d1;
  byte inputBuf[16],buf[40],*p;
  static char command=' ';
  dword addr,data;
  int i,j,k;
#ifdef PC98
  union REGS reg86;
#endif
#ifdef PCAT
  union REGS reg86;
  int isTxtMode = 0;
#endif

  addr=R->PC.W;

#ifdef PC98
  if (_farpeekb(wConvMemSelector, 0x00537) & 0x08) Trace = 0;
  if (_farpeekb(wConvMemSelector, 0x00537) & 0x04) Trace = 4;
#endif
#ifdef PCAT
  if (KeyMap[15]&0x08) Trace = 0;
  if (KeyMap[15]&0x04) Trace = 4;
#endif

  if (addr == Trap) Trace = 4;
  if (Trace <= 1) return;
  printf("\r%04X %05d:",addr,Cnt);
  if (Trace == 2) return;
  PrintRegs(R);
  if (Trace == 3) return;
  Trace = 5;
  while (Trace == 5) {
    fflush(stdin);

#ifdef PCAT
  if(!isTxtMode) {
    ResetGraphics();
    isTxtMode = 1;
    _go32_dpmi_set_protected_mode_interrupt_vector(0x09,&segOldIntKey);
/*    _go32_dpmi_set_real_mode_interrupt_vector(0x09,&segRealOldIntKey); */
    PrintRegs(R);
  }
#endif

#ifdef PC98
    (SCR[ScrMode].Refresh)(0,ScanLines212? 211:191);
    PutImage(ScreenBuf);
    reg86.x.ax=0x0c00;
    int86(0x21,&reg86,&reg86);
#endif

    putchar('>');
    fgets(inputBuf, 15, stdin);
    if(inputBuf[0] != '\n') {
      sscanf(inputBuf,"%c %X",&command,&addr);
    }
    switch(command) {
      case 'g':
        Trap=addr; Trace=1; break;
      case 't':
        Trap=addr; Trace=2; break;
      case 'T':
        Trap=addr; Trace=3; break;
      case 'n':
        Trace=4; break;
      case 'r':
        sscanf(inputBuf,"%c %s %X",&d0,buf,&addr);
        d0=toupper(buf[0]); d1=toupper(buf[1]);
        switch(d0) {
          case 'A': if(d1=='F') R->AF.W=addr; else R->AF.B.h=addr; break;
          case 'F': R->AF.B.l=addr; break;
          case 'B': if(d1=='C') R->BC.W=addr; else R->BC.B.h=addr; break;
          case 'C': R->BC.B.l=addr; break;
          case 'D': if(d1=='E') R->DE.W=addr; else R->DE.B.h=addr; break;
          case 'E': R->DE.B.l=addr; break;
          case 'H': if(d1=='L') R->HL.W=addr; else R->HL.B.h=addr; break;
          case 'L': R->HL.B.l=addr;
          case 'I': if(d1=='X') R->IX.W=addr; else R->IY.W=addr; break;
          case 'S': R->SP.W=addr; break;
          case 'P': R->PC.W=addr; break;
          case '\0' : break;
          default:
            printf("Bad register name!  A,F,B,C,D,E,H,L,");
            printf("AF,BC,DE,HL,IX,IY,SP,PC are available.\n");
        }
        PrintRegs(R); break;
      case 'x':
        TrashMachine(); TrashMSX(); exit(0);
      case 'q':
        Trap=0; Trace=0; break;
      case 'd':
        for(i=0;i<128;i+=16,addr+=16) {
          strcpy(buf,"................");
          printf("%04X : ",addr);
          for(j=0;j<16;j++) {
            d0=*(RAM[(addr+j)>>13]+((addr+j)&0x1fff));
            if(0x20<=d0 && d0<0x7f) buf[j]=d0;
            printf("%02X ",d0 );
          }
          printf(": %s\n",buf);
        }
        break;
      case 'u':
        for(i=0;i<10;i++) {
          printf("%04X : ",addr);
          addr=disasm(addr,buf);
          printf("%s\n",buf);
        }
        break;
      case 'v':
        for(i= 0;i<47;i++) printf("R#%02d:%02X ",i,VDP[i]);
          putchar('\n');
          for(i= 0;i<10;i++) printf("S#%02d:%02X ",i,VDPStatus[i]);
          printf("Mode:%d TX:%d TY:%d\n",MMCMode,_TX,_TY);
          printf("SX:%03d SY:%03d DX:%03d DY:%03d NX:%03d NY:%03d\n"
            ,_SX,_SY>>7,_DX,_DY>>7,_BX,_NY);
          printf("Palette(rgb): ");
          for(i=0;i<16;i++)
            printf("%1d%1d%1d "
              ,Palette[i][0]>>5,Palette[i][1]>>5,Palette[i][2]>>5);
          printf("\n");
          break;
      case 'w':
        for(i=0;i<128;i+=16,addr+=16) {
          strcpy(buf,"................");
          printf("%05X : ",addr);
          for(j=0;j<16;j++) {
            d0=*(VRAM+addr+j);
            if(0x20<=d0 && d0<0x7f) buf[j]=d0;
            printf("%02X ",d0 );
          }
          printf(": %s\n",buf);
        }
        break;
      case 'p':
        ChrTab=VRAM+(addr<<16); break;
      case 'e':
        while(1) {
          d0=*(RAM[addr>>13]+(addr&0x1fff));
          printf("%04X %02X - ",addr,d0);
          gets(buf); if(buf[0]=='\0') break;
          sscanf(buf,"%02X",&data);
          *(RAM[addr>>13]+(addr&0x1fff))=(byte)data;
          addr++;
        }
        break;
      case 'o':
        sscanf(inputBuf,"%c %X %X",&command,&addr,&data);
        DoOut(addr,data); break;
      case 'i':
        printf("port %02X : %02Xh\n",addr,DoIn(addr)); break;

      case 's':
        for (p = inputBuf + 2, i = 0; ; p++, i++) {
          d0 = toupper(*p);
          if ('0' <= d0 && d0 <= '9') buf[i] = d0 - '0';
          else if ('A' <= d0 && d0 <= 'F') buf[i] = d0 - 'A' + 10;
          else break;
          buf[i] <<= 4;
          p++;
          d0 = toupper(*p);
          if ('0' <= d0 & d0 <= '9') buf[i] |= d0 - '0';
          else if ('A' <= d0 && d0 <= 'F') buf[i] |= d0 - 'A' + 10;
          else break;
        }

        data = addr;
        do {
          data++;
          data &= 0xffff;
          for (k = 0; k < i; k++) {
            if (buf[k] != *(RAM[(data + k) >> 13] + ((data + k) & 0x1fff))) {
              break;
            }
          }
          if (k == i) {
            addr = data;
            break;
          }
        } while (addr != data);

        if (k == i) {
          strcpy(buf,"................");
          printf("%04X : ",addr);
          for(j=0;j<16;j++) {
            d0=*(RAM[(addr+j)>>13]+((addr+j)&0x1fff));
            if(0x20<=d0 && d0<0x7f) buf[j]=d0;
            printf("%02X ",d0 );
          }
          printf(": %s\n",buf);
        } else {
          printf(" not found\n");
        }
        break;

      default:
        printf("debugger commands:\n");
        printf("g xxxx  - go and stop at xxxxh\n");
        printf("t xxxx  - trace and stop at xxxxh\n");
        printf("T xxxx  - verbose trace and stop at xxxxh\n");
        printf("n       - step to the next instruction\n");
        printf("u xxxx  - disassemble Z80 instructions from xxxxh\n");
        printf("d xxxx  - dump memory from xxxxh\n");
        printf("s xx... - search data from here\n");
        printf("e xxxx  - edit memory from xxxxh\n");
        printf("o xx dd - output data ddh to port xxh\n");
        printf("i xx    - input data from port xxh\n");
        printf("r rg dd - set value dd into Z80 register rg\n");
        printf("v       - show VDP registers\n");
        printf("w xxxxx - dump VRAM from xxxxxh\n");
        printf("p x     - show VRAM page x0000h\n");
        printf("q       - quit debugger\n");
        printf("x       - quit fMSX\n\n");
        break;
    }
  }
#ifdef PCAT
  switch(command) {
    case 'g':
    case 'q':
      Verbose = 0;
      _go32_dpmi_chain_protected_mode_interrupt_vector(0x09, &segNewIntKey);
      switch(RefreshMode) {
        case 0:
          InitGraphicsVGA();
          break;
        case 1:
          InitGraphicsSVGA();
          break;
      }
      break;
  }
#endif /*PCAT*/
}

void PrintRegs(reg *R)
{
  char T[40];

  printf ("\rAF:%04X HL:%04X DE:%04X BC:%04X PC:%04X SP:%04X IX:%04X IY:%04X IFF:%s\n",R->AF.W,R->HL.W,R->DE.W,R->BC.W,R->PC.W,R->SP.W,R->IX.W,R->IY.W,(R->IFF&0x01)? "EI":"DI" );
  disasm(R->PC.W,T);
  printf ( "%04X : %-28s SP:[%04X] S#[%02X %02X %02X]  8%1X 8%1X 8%1X 8%1X\n",
   R->PC.W,T,*(word *)(RAM[R->SP.W>>13]+(R->SP.W&0x1fff)),VDPStatus[0],
   VDPStatus[1],VDPStatus[2], (SSL[0]<<2)|PSL[0],(SSL[1]<<2)|PSL[1],(SSL[2]<<2)|PSL[2],(SSL[3]<<2)|PSL[3] );
}


word disasm(word addr,char *T)
{
  byte *B,I;
  char *P;
  char S[20],U[20];
  char D[4][3]={"  ","  ","  ","  "};

  B=RAM[addr>>13]+(addr&0x1fff);  I=0;
  sprintf(D[I++],"%02X",*B);
  switch(*B++) {
    case 0xCB:
      sprintf(D[I++],"%02X",*B);
      strcpy(S,MnemonicsCB[*B++]);
      addr+=2;
      break;
    case 0xED:
      sprintf(D[I++],"%02X",*B);
      strcpy(S,MnemonicsED[*B++]);
      addr+=2;
      break;
    case 0xFD:
      sprintf(D[I++],"%02X",*B);
      strcpy(S,MnemonicsXX[*B++]);
      while(P=strchr(S,'%')) *P='Y';
      addr+=2;
      break;
    case 0xDD:
      sprintf(D[I++],"%02X",*B);
      strcpy(S,MnemonicsXX[*B++]);
      while(P=strchr(S,'%')) *P='X';
      addr+=2;
      break;
    default:
      strcpy(S,Mnemonics[*(B-1)]);
      addr++;
  }
  while(P=strchr(S,'*')) {
    sprintf(D[I++],"%02X",*B); *P++='\0';
    sprintf(U,"%s%02X%s",S,*B++,P);
    strcpy(S,U);
    addr++;
  }
  if(P=strchr(S,'#')) {
    sprintf(D[I++],"%02X",*B);
    sprintf(D[I++],"%02X",*(B+1)); *P++='\0';
    sprintf(U,"%s%02X%02X%s",S,*(B+1),*B,P);
    B+=2; addr+=2;
  }
  else strcpy(U,S);
  sprintf(T,"%s %s %s %s  %s",D[0],D[1],D[2],D[3],U);
  return addr;
}



void undefTrap(reg *R)
{
  if(Verbose) {
    printf("undefined instruction.\n");
    PrintRegs(R);
  }
}

