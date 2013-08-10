#ifndef __SVI__
#define __SVI__

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;

#define ifreq 16550

void doOut(int,int);
int doIn(int);
void updateCapsLock(void);
int PSGin(int);
void setBank(int);

void interrupt(void);
void savePSGbuf(int);
void saveSMPbuf(void);
void syncHandler(void);
void fpsHandler(void);

void mainmenu(void);
int query(void);
void clearrow(int,int);
char *selectImage(char*);
char* cutext(char*);
void autoRunProg(void);

void setEmuMode(int);

void saveImage(char*);
int loadImage(char*);

void parseArg(int,char**);
void adjustParameters(void);
void extraRAM(char*);
char *fixFileName(char*,char*);
long readHex(char*);

void resetSVI(void);
void init(void);
void trashEmu(void);

void readconfig(void);
char* trim(char*);

#endif
