#include <stdio.h>
#include <string.h>

#include "svi.h"
#include "psg.h"

const dumpsize=128;

extern byte* BankSelect[];
extern word rFA,rBC,rDE,rHL,rIX,rIY,rSP,rPC,rsFA,rsBC,rsDE,rsHL;
extern byte rI,rR,rIFF;
extern short cycles;
extern int bank1,bank2;

extern int brk;
extern short trace,quit,emuActive;
extern byte intrq;

extern byte VRAM[], VDP[];
extern byte BankROM[];

char *Mnemonics[256] =
{
  "nop","ld bc,#h","ld (bc),a","inc bc","inc b","dec b","ld b,*h","rlca",
  "ex af,af'","add hl,bc","ld a,(bc)","dec bc","inc c","dec c","ld c,*h","rrca",
	"djnz *h","ld de,#h","ld (de),a","inc de","inc d","dec d","ld d,*h","rla",
  "jr *h","add hl,de","ld a,(de)","dec de","inc e","dec e","ld e,*h","rra",
  "jr nz,*h","ld hl,#h","ld (#h),hl","inc hl","inc h","dec h","ld h,*h","daa",
  "jr z,*h","add hl,hl","ld hl,(#h)","dec hl","inc l","dec l","ld l,*h","cpl",
  "jr nc,*h","ld sp,#h","ld (#h),a","inc sp","inc (hl)","dec (hl)","ld (hl),*h","scf",
  "jr c,*h","add hl,sp","ld a,(#h)","dec sp","inc a","dec a","ld a,*h","ccf",
  "ld b,b","ld b,c","ld b,d","ld b,e","ld b,h","ld b,l","ld b,(hl)","ld b,a",
  "ld c,b","ld c,c","ld c,d","ld c,e","ld c,h","ld c,l","ld c,(hl)","ld c,a",
  "ld d,b","ld d,c","ld d,d","ld d,e","ld d,h","ld d,l","ld d,(hl)","ld d,a",
  "ld e,b","ld e,c","ld e,d","ld e,e","ld e,h","ld e,l","ld e,(hl)","ld e,a",
  "ld h,b","ld h,c","ld h,d","ld h,e","ld h,h","ld h,l","ld h,(hl)","ld h,a",
  "ld l,b","ld l,c","ld l,d","ld l,e","ld l,h","ld l,l","ld l,(hl)","ld l,a",
  "ld (hl),b","ld (hl),c","ld (hl),d","ld (hl),e","ld (hl),h","ld (hl),l","halt","ld (hl),a",
  "ld a,b","ld a,c","ld a,d","ld a,e","ld a,h","ld a,l","ld a,(hl)","ld a,a",
  "add a,b","add a,c","add a,d","add a,e","add a,h","add a,l","add a,(hl)","add a,a",
  "adc a,b","adc a,c","adc a,d","adc a,e","adc a,h","adc a,l","adc a,(hl)","adc a,a",
  "sub b","sub c","sub d","sub e","sub h","sub l","sub (hl)","sub a",
  "sbc a,b","sbc a,c","sbc a,d","sbc a,e","sbc a,h","sbc a,l","sbc a,(hl)","sbc a,a",
  "and b","and c","and d","and e","and h","and l","and (hl)","and a",
	"xor b","xor c","xor d","xor e","xor h","xor l","xor (hl)","xor a",
  "or b","or c","or d","or e","or h","or l","or (hl)","or a",
  "cp b","cp c","cp d","cp e","cp h","cp l","cp (hl)","cp a",
	"ret nz","pop bc","jp nz,#h","jp #h","call nz,#h","push bc","add *h","rst 00h",
	"ret z","ret","jp z,#h","prefic cbh","call z,#h","call #h","adc *h","rst 08h",
  "ret nc","pop de","jp nc,#h","out (*h),a","call nc,#h","push de","sub *h","rst 10h",
  "ret c","exx","jp c,#h","in a,(*h)","call c,#h","prefic ddh","sbc *h","rst 18h",
  "ret po","pop hl","jp po,#h","ex hl,(sp)","call po,#h","push hl","and *h","rst 20h",
  "ret pe","ld pc,hl","jp pe,#h","ex de,hl","call pe,#h","prefic edh","xor *h","rst 28h",
  "ret p","pop af","jp p,#h","di","call p,#h","push af","or *h","rst 30h",
  "ret m","ld sp,hl","jp m,#h","ei","call m,#h","prefic fdh","cp *h","rst 38h"
};

char *MnemonicsCB[256] =
{
  "rlc b","rlc c","rlc d","rlc e","rlc h","rlc l","rlc xhl","rlc a",
  "rrc b","rrc c","rrc d","rrc e","rrc h","rrc l","rrc xhl","rrc a",
  "rl b","rl c","rl d","rl e","rl h","rl l","rl xhl","rl a",
  "rr b","rr c","rr d","rr e","rr h","rr l","rr xhl","rr a",
  "sla b","sla c","sla d","sla e","sla h","sla l","sla xhl","sla a",
  "sra b","sra c","sra d","sra e","sra h","sra l","sra xhl","sra a",
  "sll b","sll c","sll d","sll e","sll h","sll l","sll xhl","sll a",
  "srl b","srl c","srl d","srl e","srl h","srl l","srl xhl","srl a",
  "bit 0,b","bit 0,c","bit 0,d","bit 0,e","bit 0,h","bit 0,l","bit 0,(hl)","bit 0,a",
  "bit 1,b","bit 1,c","bit 1,d","bit 1,e","bit 1,h","bit 1,l","bit 1,(hl)","bit 1,a",
  "bit 2,b","bit 2,c","bit 2,d","bit 2,e","bit 2,h","bit 2,l","bit 2,(hl)","bit 2,a",
  "bit 3,b","bit 3,c","bit 3,d","bit 3,e","bit 3,h","bit 3,l","bit 3,(hl)","bit 3,a",
  "bit 4,b","bit 4,c","bit 4,d","bit 4,e","bit 4,h","bit 4,l","bit 4,(hl)","bit 4,a",
  "bit 5,b","bit 5,c","bit 5,d","bit 5,e","bit 5,h","bit 5,l","bit 5,(hl)","bit 5,a",
  "bit 6,b","bit 6,c","bit 6,d","bit 6,e","bit 6,h","bit 6,l","bit 6,(hl)","bit 6,a",
	"bit 7,b","bit 7,c","bit 7,d","bit 7,e","bit 7,h","bit 7,l","bit 7,(hl)","bit 7,a",
	"res 0,b","res 0,c","res 0,d","res 0,e","res 0,h","res 0,l","res 0,(hl)","res 0,a",
  "res 1,b","res 1,c","res 1,d","res 1,e","res 1,h","res 1,l","res 1,(hl)","res 1,a",
	"res 2,b","res 2,c","res 2,d","res 2,e","res 2,h","res 2,l","res 2,(hl)","res 2,a",
  "res 3,b","res 3,c","res 3,d","res 3,e","res 3,h","res 3,l","res 3,(hl)","res 3,a",
  "res 4,b","res 4,c","res 4,d","res 4,e","res 4,h","res 4,l","res 4,(hl)","res 4,a",
  "res 5,b","res 5,c","res 5,d","res 5,e","res 5,h","res 5,l","res 5,(hl)","res 5,a",
  "res 6,b","res 6,c","res 6,d","res 6,e","res 6,h","res 6,l","res 6,(hl)","res 6,a",
  "res 7,b","res 7,c","res 7,d","res 7,e","res 7,h","res 7,l","res 7,(hl)","res 7,a",
  "set 0,b","set 0,c","set 0,d","set 0,e","set 0,h","set 0,l","set 0,(hl)","set 0,a",
  "set 1,b","set 1,c","set 1,d","set 1,e","set 1,h","set 1,l","set 1,(hl)","set 1,a",
  "set 2,b","set 2,c","set 2,d","set 2,e","set 2,h","set 2,l","set 2,(hl)","set 2,a",
  "set 3,b","set 3,c","set 3,d","set 3,e","set 3,h","set 3,l","set 3,(hl)","set 3,a",
  "set 4,b","set 4,c","set 4,d","set 4,e","set 4,h","set 4,l","set 4,(hl)","set 4,a",
  "set 5,b","set 5,c","set 5,d","set 5,e","set 5,h","set 5,l","set 5,(hl)","set 5,a",
  "set 6,b","set 6,c","set 6,d","set 6,e","set 6,h","set 6,l","set 6,(hl)","set 6,a",
  "set 7,b","set 7,c","set 7,d","set 7,e","set 7,h","set 7,l","set 7,(hl)","set 7,a"
};

char *MnemonicsED[256] =
{
  "fuck00","fuck01","fuck02","fuck03","fuck04","fuck05","fuck06","fuck07",
  "fuck08","fuck09","fuck0a","fuck0b","fuck0c","fuck0d","fuck0e","fuck0f",
  "fuck10","fuck11","fuck12","fuck13","fuck14","fuck15","fuck16","fuck17",
  "fuck18","fuck19","fuck1a","fuck1b","fuck1c","fuck1d","fuck1e","fuck1f",
  "fuck20","fuck21","fuck22","fuck23","fuck24","fuck25","fuck26","fuck27",
  "fuck28","fuck29","fuck2a","fuck2b","fuck2c","fuck2d","fuck2e","fuck2f",
  "fuck30","fuck31","fuck32","fuck33","fuck34","fuck35","fuck36","fuck37",
  "fuck38","fuck39","fuck3a","fuck3b","fuck3c","fuck3d","fuck3e","fuck3f",
  "in b,(c)","out (c),b","sbc hl,bc","ld (#h),bc","fuck44","retN","im 0","ld i,a",
	"in c,(c)","out (c),c","adc hl,bc","ld bc,(#h)","fuck4c","reti","fuck","ld r,a",
  "in d,(c)","out (c),d","sbc hl,de","ld (#h),de","fuck54","fuck55","im 1","ld a,i",
  "in e,(c)","out (c),e","adc hl,de","ld de,(#h)","fuck5c","fuck5d","im 2","ld a,r",
	"in h,(c)","out (c),h","sbc hl,hl","ld (#h),hl","fuck64","fuck65","fuck66","rrd",
	"in l,(c)","out (c),l","adc hl,hl","ld hl,(#h)","fuck6c","fuck6d","fuck6e","rld",
  "in f,(c)","out (c),f","sbc hl,sp","ld (#h),sp","fuck74","fuck75","fuck76","fuck77",
  "in a,(c)","out (c),a","adc hl,sp","ld sp,(#h)","fuck7c","fuck7d","fuck7e","fuck7f",
  "fuck80","fuck81","fuck82","fuck83","fuck84","fuck85","fuck86","fuck87",
  "fuck88","fuck89","fuck8a","fuck8b","fuck8c","fuck8d","fuck8e","fuck8f",
  "fuck90","fuck91","fuck92","fuck93","fuck94","fuck95","fuck96","fuck97",
  "fuck98","fuck99","fuck9a","fuck9b","fuck9c","fuck9d","fuck9e","fuck9f",
  "ldi","cpi","ini","outi","fucka4","fucka5","fucka6","fucka7",
  "ldd","cpd","ind","outd","fuckac","fuckad","fuckae","fuckaf",
  "ldir","cpir","inir","Otir","fuckb4","fuckb5","fuckb6","fuckb7",
  "lddr","cpdr","indr","Otdr","fuckbc","fuckbd","fuckbe","fuckbf",
  "fuckc0","fuckc1","fuckc2","fuckc3","fuckc4","fuckc5","fuckc6","fuckc7",
  "fuckc8","fuckc9","fuckca","fuckcb","fuckcc","fuckcd","fuckce","fuckcf",
  "fuckd0","fuckd1","fuckd2","fuckd3","fuckd4","fuckd5","fuckd6","fuckd7",
  "fuckd8","fuckd9","fuckda","fuckdb","fuckdc","fuckdd","fuckde","fuckdf",
  "fucke0","fucke1","fucke2","fucke3","fucke4","fucke5","fucke6","fucke7",
  "fucke8","fucke9","fuckea","fuckeb","fuckec","fucked","fuckee","fuckef",
  "fuckf0","fuckf1","fuckf2","fuckf3","fuckf4","fuckf5","fuckf6","fuckf7",
  "fuckf8","fuckf9","fuckfa","fuckfb","fuckfc","fuckfd","fuckfe","fuckff"
};

char *MnemonicsXX[256] =
{
  "nop","ld bc,#h","ld (bc),a","inc bc","inc b","dec b","ld b,*h","rlca",
  "ex af,af'","add i%,bc","ld a,(bc)","dec bc","inc c","dec c","ld c,*h","rrca",
  "dJnz *h","ld de,#h","ld (de),a","inc de","inc d","dec d","ld d,*h","rla",
	"jr *h","add i%,de","ld a,(de)","dec de","inc e","dec e","ld e,*h","rra",
  "jr nz,*h","ld i%,#h","ld (#h),i%","inc i%","inc i%h","dec i%h","ld i%h,*h","daa",
  "jr z,*h","add i%,i%","ld i%,(#h)","dec i%","inc i%l","dec i%l","ld i%l,*h","cpl",
	"jr nc,*h","ld sp,#h","ld (#h),a","inc sp","inc (i%+*h)","dec (i%+*h)","ld (i%+*h),*h","scf",
  "jr c,*h","add i%,sp","ld a,(#h)","dec sp","inc a","dec a","ld a,*h","ccf",
  "ld b,b","ld b,c","ld b,d","ld b,e","ld b,i%h","ld b,i%l","ld b,(i%+*h)","ld b,a",
  "ld c,b","ld c,c","ld c,d","ld c,e","ld c,i%h","ld c,i%l","ld c,(i%+*h)","ld c,a",
	"ld d,b","ld d,c","ld d,d","ld d,e","ld d,i%h","ld d,i%l","ld d,(i%+*h)","ld d,a",
  "ld e,b","ld e,c","ld e,d","ld e,e","ld e,i%h","ld e,i%l","ld e,(i%+*h)","ld e,a",
  "ld i%h,b","ld i%h,c","ld i%h,d","ld i%h,e","ld i%h,i%h","ld i%h,i%l","ld h,(i%+*h)","ld i%h,a",
  "ld i%l,b","ld i%l,c","ld i%l,d","ld i%l,e","ld i%l,i%h","ld i%l,i%l","ld l,(i%+*h)","ld i%l,a",
  "ld (i%+*h),b","ld (i%+*h),c","ld (i%+*h),d","ld (i%+*h),e","ld (i%+*h),h","ld (i%+*h),l","halt","ld (i%+*h),a",
  "ld a,b","ld a,c","ld a,d","ld a,e","ld a,i%h","ld a,l","ld a,(i%+*h)","ld a,a",
  "add b","add c","add d","add e","add i%h","add i%l","add (i%+*h)","add a",
  "adc b","adc c","adc d","adc e","adc i%h","adc i%l","adc (i%+*h)","adc,a",
  "sub b","sub c","sub d","sub e","sub i%h","sub i%l","sub (i%+*h)","sub a",
  "sbc b","sbc c","sbc d","sbc e","sbc i%h","sbc i%l","sbc (i%+*h)","sbc a",
  "and b","and c","and d","and e","and i%h","and i%l","and (i%+*h)","and a",
  "xor b","xor c","xor d","xor e","xor i%h","xor i%l","xor (i%+*h)","xor a",
  "or b","or c","or d","or e","or i%h","or i%l","or (i%+*h)","or a",
  "cp b","cp c","cp d","cp e","cp i%h","cp i%l","cp (i%+*h)","cp a",
  "ret nz","pop bc","jp nz,#h","jp #h","call nz,#h","push bc","add *h","rst 00h",
  "ret z","ret","jp z,#h","prefic cbh","call z,#h","call #h","adc *h","rst 08h",
  "ret nc","pop de","jp nc,#h","outa (*h)","call nc,#h","push de","sub *h","rst 10h",
  "ret c","exx","jp c,#h","ina (*h)","call c,#h","prefic ddh","sbc *h","rst 18h",
  "ret po","pop i%","jp po,#h","ex i%,(sp)","call po,#h","push i%","and *h","rst 20h",
  "ret pe","ld pc,i%","jp pe,#h","ex de,i%","call pe,#h","prefic edh","xor *h","rst 28h",
	"ret p","pop af","jp p,#h","di","call p,#h","push af","or *h","rst 30h",
  "ret m","ld sp,i%","jp m,#h","ei","call m,#h","prefic fdh","cp *h","rst 38h"
};

word lastdump=0;

int rdmem(word addr)
{
	return BankSelect[addr>>14][addr&0x3FFF];
}

void remspc(char *s)
{
	while (*s)
	{
		while (*s==' ')
			memmove(s,s+1,strlen(s));
		if (*s) s++;
	}
}

int htoi(char *s)
{
	int i=0;
	if (!*s) return -1;
	while (*s)
	{
		if ((*s>='0')&&(*s<='9'))
			i=i*16+*s-'0';
		else if ((*s>='A')&&(*s<='F'))
			i=i*16+*s-'A'+10;
		else if ((*s>='a')&&(*s<='f'))
			i=i*16+*s-'a'+10;
		else
			return -1;
		s++;
	}
	return i;
}

void memdump(int addr)
{
	byte b;
	int i,j;
	char s[17];
	s[16]=0;
	j=addr&0xFFF0;	
	for(i=j;i<addr+dumpsize;i++)
	{
		if (!(i&0x0F))
			printf("%04X  ",i&0xFFFF);
		if (i<addr)
			printf("   ");
		else
			printf("%02X ",b=rdmem(i&0xFFFF));	
		s[i&0x0F]=b<32?32:b;
		if ((i&0x0F)==0x0F)
		{
			printf("  %s\n",s);
			memset(s,32,16);
		}
		else if ((i&0x0F)==0x07)
			printf(" ");				
	}
	if (i&0x0F)
	{
		if ((i&0x0F)<8)
			printf(" ");
		while (i++&0x0F)
			printf("   ");
		printf("  %s\n",s);
	}
	lastdump=addr+dumpsize;
}

void textscreen0(void)
{
	int i,j;
	byte b;
	textcolor(0);
	textbackground(7);
	for(i=0;i<25;i++)
	{
		for(j=0;j<40;j++)
		{
			b=VRAM[i*40+j];
			if ((b>=96)&&(b<=192))
				cprintf("%c",VRAM[i*40+j]-64);
			else
				printf("%c",VRAM[i*40+j]+32);
		}
		printf("\n");
	}
	textcolor(7);
	textbackground(0);
}

void hardwareinfo(char* s)
{
	int i;
	printf("\n");
	for(i=0;i<8;i++)
		printf("VDP[%d]=0x%02x   PSG[%02d]=0x%02x  PSG[%02d]=0x%02x\n",i,VDP[i],i,AYReadReg(i),i+8,AYReadReg(i+8));
	printf("\n");
	if (*s)
	{
		if (*s=='v')
		{
			i=(*++s)-48;
			if ((i<0)||(i>7))
				printf("Not valid VDP register!\n");
			else
			{
				VDP[i]=htoi(++s);
				printf("Setting VDP[%d] to %s\n",i,s);
			}
		}
		printf("\n");
	}
}		

void vramdump(void)
{
	FILE *f;
	printf("Dumping VRAM to VRAM.BIN...\n");
	f=fopen("vram.bin","wb");
	fwrite(VRAM,0x4000,1,f);
	fclose(f);
}

void debug(void)
{	
	word rAF,rsAF,PC,i;
	char s[80],t[80],*p,c;
	byte m,n;
	
	if (trace!=2) setEmuMode(0);
	emuActive=0;
	rAF=(rFA>>8)+(rFA<<8);
	rsAF=(rsFA>>8)+(rsFA<<8);
	i=(cycles>ifreq)?0:ifreq-cycles;
	
	printf("\nAF=%04X BC=%04X DE=%04X HL=%04X   IFF=%d  ",rAF,rBC,rDE,rHL,rIFF);
	if (rAF&0x01) printf("CF ");
	if (rAF&0x04) printf("PV ");
	if (rAF&0x40) printf("ZF ");
	if (rAF&0x80) printf("MI ");
	printf("\nIX=%04X IY=%04X SP=%04X PC=%04X   ",rIX,rIY,rSP,rPC);
	
	printf("(SP)=%04X\n",rdmem(rSP)+(rdmem(rSP+1)<<8));
	printf("BK=%02d,%02d (R%cM,R%cM)   CTI=%5d  ",bank1*10+1,bank2*10+2,BankROM[0]?'O':'A',BankROM[3]?'O':'A',i);	
	if (intrq) printf("  IRQ\n"); else printf("\n");
	
	PC=rPC;
	switch (rdmem(PC++))
	{
		case 0xCB :	strcpy(s,MnemonicsCB[rdmem(PC++)]); break;
		case 0xED : strcpy(s,MnemonicsED[rdmem(PC++)]); break;
		case 0xFD : strcpy(s,MnemonicsXX[rdmem(PC++)]);
							 	while (p=(char*)strchr(s,'%'))
							 		*p='Y';
							 	break;
		case 0xDD : strcpy(s,MnemonicsXX[rdmem(PC++)]);
							 	while (p=(char*)strchr(s,'%'))
							 		*p='X';
							 	break;
		default		: strcpy(s,Mnemonics[rdmem(PC-1)]);
	}

	while (p=(char*)strchr(s,'*'))
	{
		n=rdmem(PC++);
		*p++='\0';
		sprintf(t,"%s%02hX%s",s,n,p);
		strcpy(s,t);
	}

	if (p=(char*)strchr(s,'#'))
	{
		m=rdmem(PC++);
		n=rdmem(PC++);
		*p++='\0';
		sprintf(t,"%s%04hX%s",s,(int)(n<<8)+m,p);
	}
	else
		strcpy(t,s);
	
	do
	{	
		printf("[%04X]  %s\n",rPC,t);

		gets(s);	
		remspc(s);
		brk=-1;
		switch (*s)
		{
			case 27		:
			case 'q'	:	quit=1; setEmuMode(1); break;
			case 'g'  : trace=0; brk=htoi(s+1); setEmuMode(1);break;
			case 'd'	:	memdump(s[1]?htoi(s+1)<0?0:htoi(s+1):lastdump); break;
			case 's'	: textscreen0(); break;
			case 'h'  : hardwareinfo(s+1); break; 
			case 'v'  : vramdump(); break;
			case 'p'	:	if (rdmem(rPC)==0xCD)
									{
										trace=0;
										setEmuMode(1);
										brk=rPC+3;
									}
									else
									{
										trace=2;
										emuActive=1;
									}
									break;
			default		: trace=2; emuActive=1; break;
		}
	} while (!emuActive);
}
