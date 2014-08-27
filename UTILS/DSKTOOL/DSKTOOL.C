#ifndef Unix
#  define DOS
#endif /* !Unix */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <dirent.h>
#include <time.h>
#include <sys/stat.h>

#define EXTRACT 0
#define DELETE  1

#ifndef S_IRUSR
#  define S_IRUSR S_IREAD
#endif /* !S_IRUSR */
#ifndef S_IWUSR
#  define S_IWUSR S_IWRITE
#endif /* !S_IWUSR */

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dblw;
typedef struct
{ char name[9];
  char ext[4];
  dblw size;
  word hour,min,sec;
  word day,month,year;
  word first;
  word pos;
  word attr;
} MSXFDESC;

typedef struct
{ char *mask;
  DIR *dirptr;
  int basesize;
  char *basedir;
  struct dirent *diren;
  char *fullname;
  char shortname[12];
  struct stat entstat;
} DIRDESC;

const byte MSX720BS[512]=
{ 0xEB,0xFE,0x90,0x55,0x6E,0x69,0x63,0x6F,
  0x72,0x6E,0x73,0x00,0x02,0x02,0x01,0x00,
  0x02,0x70,0x00,0xA0,0x05,0xF9,0x03,0x00,
  0x09,0x00,0x02,0x00,0x00,0x00,0x18,0x40,
  0x56,0x4F,0x4C,0x5F,0x49,0x44,0x00,0x00,
  0x00,0x00,0x00,0x43,0x79,0x62,0x65,0x72,
  0x6B,0x6E,0x69,0x67,0x68,0x74,0x46,0x41,
  0x54,0x31,0x32,0x20,0x20,0x20,0x55,0x6E,
  0x69,0x63,0x6F,0x72,0x6E,0x20,0x44,0x72,
  0x65,0x61,0x6D,0x73,0x20,0x41,0x72,0x74,
  0x77,0x6F,0x72,0x6B,0x20,0x50,0x72,0x6F,
  0x64,0x75,0x63,0x74,0x69,0x6F,0x6E,0x73,
  0xD0,0xED,0x53,0x9A,0xC0,0x32,0xA2,0xC0,
  0x36,0x97,0x23,0x36,0xC0,0x31,0x1F,0xF5,
  0x11,0xD9,0xC0,0x0E,0x0F,0xCD,0x7D,0xF3,
  0x3C,0x28,0x26,0x11,0x00,0x01,0x0E,0x1A,
  0xCD,0x7D,0xF3,0x21,0x01,0x00,0x22,0xE7,
  0xC0,0x21,0x00,0x3F,0x11,0xD9,0xC0,0x0E,
  0x27,0xCD,0x7D,0xF3,0xC3,0x00,0x01,0x69,
  0xC0,0xCD,0x00,0x00,0x79,0xE6,0xFE,0xD6,
  0x02,0xF6,0x00,0xCA,0x22,0x40,0x11,0xB5,
  0xC0,0x0E,0x09,0xCD,0x7D,0xF3,0x0E,0x07,
  0xCD,0x7D,0xF3,0x18,0xB8,0x42,0x6F,0x6F,
  0x74,0x73,0x74,0x72,0x61,0x70,0x20,0x65,
  0x72,0x72,0x6F,0x72,0x0D,0x0A,0x50,0x72,
  0x65,0x73,0x73,0x20,0x61,0x6E,0x79,0x20,
  0x6B,0x65,0x79,0x2E,0x2E,0x2E,0x0D,0x0A,
  0x24,0x00,0x4D,0x53,0x58,0x44,0x4F,0x53,
  0x20,0x20,0x53,0x59,0x53,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
};

byte *DskImage;
byte *FAT;
byte *Direc;
byte *Cluster;
word BytesPerSector,ReservedSectors,DirElements,NumberOfSectors;
word SectorsPerFAT,SectorsPerTrack,NumberOfHeads;
byte SectorsPerCluster,NumberOfFATs,FATSignature;
word NumberOfTracks,FATElements,AvailSectors;
dblw ClusterSize;

char **__crt0_glob_function (char *_argument)
{ return NULL;
}

char chrupc(chr)
/* CHaRacter UPcase Convert */
const char chr;
{ if ((chr>='a')&&(chr<='z')) return(chr-32);
  return(chr);
}

int chrcpi(chr1,chr2)
/* CHaRacter ComPare Ignoring case */
const char chr1,chr2;
{ char C1=chr1,C2=chr2;

  if ((C1>='a')&&(C1<='z')) C1-=32;
  if ((C2>='a')&&(C2<='z')) C2-=32;
  return(C1-C2);
}

void strupc(str)
/* STRing UPcase Convert */
char *str;
{ char *ptr=str;

  while (*ptr)
  { if ((*ptr>='a')&&(*ptr<='z')) *ptr-=32;
    ptr++;
  }
}

void strcex(str,chr1,chr2)
/* STRing Character EXchanger */
char *str;
const char chr1,chr2;
{ char *ptr=str;

  while (*ptr)
  { if (*ptr==chr1) *ptr=chr2;
    ptr++;
  }
}

void strcin(str,chr,pos)
/* STRing Character INsert */
/* WARNING: This procedure doesn't check string allocated space. */
char *str;
const char chr;
const int pos;
{ int A;

  for (A=strlen(str);A>=pos;A--) str[A+1]=str[A];
  str[pos]=chr;
}

void strcdl(str,pos)
/* STRing Character DeLete */
char *str;
const int pos;
{ int A=pos;

  while (str[A])
  { str[A]=str[A+1];
    A++;
  }
}

int strscp(str,sub,start,substart,length,mode)
/* STRing Segment Compare */
/* If str segment=sub segment, return 1. */
/* If mode!=0, ignore case. */
/* WARNING: This procedure doesn't check string sizes. */
const char *str,*sub;
const int start,substart,length;
const int mode;
{ int A=start,B=substart,C=length;

  while (C)
    if ((str[A]==sub[B])||(mode&&(!chrcpi(str[A],sub[B]))))
    { A++;
      B++;
      C--;
    }
    else return(0);
  return(1);
}

void strsub(dst,src,start,length)
/* STRing SUBsegment */
/* If length<0, copy segment to the left side of start. */
/* WARNING: This procedure doesn't check destiny size. */
char *dst;
const char *src;
const int start,length;
{ int A,B=0,C;

  if (length>=0)
  { A=start;
    if (start+length>=(C=strlen(src))) C-=start;
    else                               C=length;
    while (B<C) dst[B++]=src[A++];
  }
  else
  { A=start+length+1;
    if (A<0) A=0;
    while (A<=start) dst[B++]=src[A++];
  }
  dst[B]='\0';
}

void strmid(dst,src,start,length)
/* STRing MIDdle */
/* If length<0, copy segment from right to the left, ending in start. */
/* WARNING: This procedure doesn't check destiny size. */
char *dst;
const char *src;
const int start,length;
{ int A,B=0,C=strlen(src);

  if (length>=0)
  { A=start;
    if (start+length>=C) C-=start;
    else                 C=length;
    while (B<C) dst[B++]=src[A++];
  }
  else
  { A=start-length-1;
    if (C<=A) A=C-1;
    while (A>=start) dst[B++]=src[A--];
  }
  dst[B]='\0';
}

void strseg(dst,src,start,end)
/* STRing SEGment */
/* If end<start then copy segment mirrored. */
/* WARNING: This procedure doesn't check destiny size. */
char *dst;
const char *src;
const int start,end;
{ if (start>end) strsub(dst,src,end,end-start-1);
  else           strsub(dst,src,start,end-start+1);
}

int strcsk(str,chr,first,last,num,mode)
/* STRing Character SeeK */
/* If num>0, find character (return -1 if not found);
   if num=0, count matches (return 0 if no matches);
   if first<0, first=strlen; if last<0, last=strlen;
   if mode!=0, ignore case in match;
   if last<first, search backward. */
const char *str,chr;
const int first,last,num,mode;
{ int A,B,C=num,L=strlen(str);

  if ((num<0)||(!L)) return(-1);
  L--;
  if ((first>L)||(first<0)) A=L;
  else                      A=first;
  if ((last>L)||(last<0)) B=L;
  else                    B=last;
  if (num) /* Seek */
  { if (A<=B) /* Forward */
    { while ((A<=B)&&C)
      { if ((str[A]==chr)||(mode&&(!chrcpi(str[A],chr)))) C--;
        A++;
      }
      A--;
    }
    else /* Backward */
    { while ((A>=B)&&C)
      { if ((str[A]==chr)||(mode&&(!chrcpi(str[A],chr)))) C--;
        A--;
      }
      A++;
    }
    if (C) return(-1);
    return(A);
  }
  else /* Count */
  { if (A<=B) /* Forward */
      while (A<=B)
      { if ((str[A]==chr)||(mode&&(!chrcpi(str[A],chr)))) C++;
        A++;
      }
    else /* Backward */
      while (A>=B)
      { if ((str[A]==chr)||(mode&&(!chrcpi(str[A],chr)))) C++;
        A--;
      }
    return(C);
  }
}

int strmat(str,mask)
/* STRing MATch */
/* Matches two strings, regarding the wildcard characters "*" and "?". */
const char *str,*mask;
{ int A=0,B=0,C=-1,D=0,L=strlen(str),M=strlen(mask);

  while ((A<M)||((C>=0)&&(B<L)))
  { if (A>=M)
    { A=C;
      B=D;
    }
    if (mask[A]=='*')
    { while (mask[A]=='*') A++;
      C=A-1;
      D=B+1;
      if (A>=M) return(1);
      if ((mask[A]!='?')&&((B=strcsk(str,mask[A],B,-1,1,1))<0)) return(0);
    }
    if (((mask[A]!='?')&&(chrcpi(mask[A],str[B])))||(!str[B]))
      if (C<0)
        return(0);
      else
      { A=C;
        C=-1;
        B=D;
      }
    else
    { A++;
      B++;
    }
    if (B>L) return(0);
  }
  if (B<L) return(0);
  return(1);
}

void strfill(str,chr,start,length)
/* STRing FILl Long */
/* WARNING: This procedure doesn't check destiny size. */
char *str;
const char chr;
const size_t start,length;
{ size_t A=length;

  str+=start;
  while (A--)
  { *str=chr;
    str++;
  }
}

void CompactName(str)
char *str;
{ int A=11;

  while (A&&(str[A]==' ')) strcdl(str,A--);
  A=7;
  while (A&&(str[A]==' ')) strcdl(str,A--);
}

void ErrExt(Code)
const int Code;
{ switch (Code)
  { case 2:
      fprintf(stderr,"Error: Missing parameters.\n");
      exit(2);
    case 7:
      fprintf(stderr,"Error: Disk image data are damaged!\n");
      exit(7);
    case 9:
      fprintf(stderr,"Error: Directory full!\n");
      exit(9);
    case 11:
      fprintf(stderr,"Error: Not enough memory.\n");
      exit(11);
  }
}

int GetDskData(DskImage)
byte *DskImage;
{ if (((*DskImage)&0xFD)!=0xE9) return(1);

  BytesPerSector=   *(word *)(DskImage+0x0B);
  SectorsPerCluster=        *(DskImage+0x0D);
  ReservedSectors=  *(word *)(DskImage+0x0E);
  NumberOfFATs=             *(DskImage+0x10);
  DirElements=      *(word *)(DskImage+0x11);
  NumberOfSectors=  *(word *)(DskImage+0x13);
  FATSignature=             *(DskImage+0x15);
  SectorsPerFAT=    *(word *)(DskImage+0x16);
  SectorsPerTrack=  *(word *)(DskImage+0x18);
  NumberOfHeads=    *(word *)(DskImage+0x1A);
  return(0);
}

void CalcDskData()
{ NumberOfTracks=NumberOfSectors/SectorsPerTrack/NumberOfHeads;
  ClusterSize=(long)BytesPerSector*SectorsPerCluster;
  AvailSectors=NumberOfSectors-ReservedSectors-SectorsPerFAT*NumberOfFATs-(DirElements<<5)/BytesPerSector;
  FATElements=AvailSectors/SectorsPerCluster;
}

void SetDskPtr(DskImage)
byte *DskImage;
{ FAT=DskImage+(size_t)BytesPerSector*ReservedSectors;
  Direc=FAT+(size_t)BytesPerSector*SectorsPerFAT*NumberOfFATs;
  Cluster=Direc+(DirElements<<5);
}

void SetDskData(DskImage)
byte *DskImage;
{ *(word *)(DskImage+0x0B)=BytesPerSector;
          *(DskImage+0x0D)=SectorsPerCluster;
  *(word *)(DskImage+0x0E)=ReservedSectors;
          *(DskImage+0x10)=NumberOfFATs;
  *(word *)(DskImage+0x11)=DirElements;
  *(word *)(DskImage+0x13)=NumberOfSectors;
          *(DskImage+0x15)=FATSignature;
  *(word *)(DskImage+0x16)=SectorsPerFAT;
  *(word *)(DskImage+0x18)=SectorsPerTrack;
  *(word *)(DskImage+0x1A)=NumberOfHeads;
}

void LoadDsk(Name)
const char *Name;
{ FILE *SysFile;

  if ((SysFile=fopen(Name,"rb"))==NULL)
  { perror(Name);
    exit(4);
  }
  if ((DskImage=(byte *)malloc((size_t)512))==NULL) ErrExt(11);
  if (fread(DskImage,(size_t)1,(size_t)512,SysFile)<(size_t)512)
  { perror(Name);
    exit(4);
  }
  if (GetDskData(DskImage))
  { fprintf(stderr,"Error: Invalid disk mirror image \"%s\".\n",Name);
    exit(6);
  }
  free(DskImage);
  CalcDskData();
  if ((DskImage=(byte *)malloc((size_t)NumberOfSectors*BytesPerSector))==NULL) ErrExt(11);
  rewind(SysFile);
  if (fread(DskImage,(size_t)BytesPerSector,(size_t)NumberOfSectors,SysFile)<(size_t)NumberOfSectors)
  { perror(Name);
    exit(4);
  }
  SetDskPtr(DskImage);
  fclose(SysFile);
}

void FlushDsk(Name)
const char *Name;
{ FILE *SysFile;
  int A;

  for (A=1;A<NumberOfFATs;A++)
    memcpy(FAT+BytesPerSector*SectorsPerFAT*A,FAT,BytesPerSector*SectorsPerFAT);
  if ((SysFile=fopen(Name,"wb"))==NULL)
  { perror(Name);
    exit(5);
  }
  if (fwrite(DskImage,(size_t)BytesPerSector,(size_t)NumberOfSectors,SysFile)<(size_t)NumberOfSectors)
  { perror(Name);
    exit(5);
  }
  fclose(SysFile);
  free(DskImage);
}

int FindFirst(DirDsc,Path)
DIRDESC *DirDsc;
const char *Path;
{ int A,B,C,L=strlen(Path);

  if (!L) return(0);
  A=strcsk(Path,'*',0,-1,1,0);
  B=strcsk(Path,'?',0,-1,1,0);
  if (A>=0)
    if (B>=0)
      if (A<B) C=A;
      else C=B;
    else C=A;
  else C=B;
  A=strcsk(Path,'/',C,0,1,0);
#ifdef DOS
  B=strcsk(Path,'\\',C,0,1,0);
  if (B>A) A=B;
  B=strcsk(Path,':',C,0,1,0);
  if (B>A) A=B;
#endif /* DOS */
  A++;
  if (A>0) /* Directory/drive delimiter found. */
  { if ((strcsk(Path,'/',A,-1,1,0)>=0)||(strcsk(Path,'\\',A,-1,1,0)>=0))
      return(0); /* Doesn't allow wildcards in directory (could lead to ambiguous interpretations). */
    if ((DirDsc->basedir=(char *)malloc((size_t)A+1))==NULL) ErrExt(11);
    B=0;
    while (B<A)
    { if (Path[B]=='\\') DirDsc->basedir[B]='/';
      else               DirDsc->basedir[B]=Path[B];
      B++;
    }
    DirDsc->basedir[B]='\0';
    if ((DirDsc->dirptr=opendir(DirDsc->basedir))==NULL)
    { free(DirDsc->basedir);
      return(0); /* Couldn't open base directory. */
    }
    if ((DirDsc->mask=(char *)malloc((size_t)L-A+1))==NULL) ErrExt(11);
    strseg(DirDsc->mask,Path,A,L);
  }
  else /* No directory/drive delimiter found. */
  { if ((DirDsc->basedir=(char *)malloc((size_t)3))==NULL) ErrExt(11);
    strcpy(DirDsc->basedir,"./");
    A=2;
    if ((DirDsc->dirptr=opendir(DirDsc->basedir))==NULL)
    { /* Couldn't open current directory, checking root... */
      strcdl(DirDsc->basedir,0);
      A--;
      if ((DirDsc->dirptr=opendir(DirDsc->basedir))==NULL)
      { free(DirDsc->basedir);
        return(0); /* Couldn't open root directory. */
      }
    }
    if ((DirDsc->mask=(char *)malloc((size_t)L+1))==NULL) ErrExt(11);
    strcpy(DirDsc->mask,Path);
  }
  DirDsc->basesize=A;
  if ((DirDsc->fullname=(char *)malloc((size_t)1))==NULL) ErrExt(11);
  return(FindNext(DirDsc));
}

int FindNext(DirDsc)
DIRDESC *DirDsc;
{ int A,B,C,D;

  while ((DirDsc->diren=readdir(DirDsc->dirptr))!=NULL)
  { free(DirDsc->fullname);
    A=strlen(DirDsc->diren->d_name);
    if ((DirDsc->fullname=(char *)malloc((size_t)DirDsc->basesize+A+1))==NULL) ErrExt(11);
    C=0;
    for (B=0;B<DirDsc->basesize;B++) DirDsc->fullname[C++]=DirDsc->basedir[B];
    for (B=0;B<=A;B++)               DirDsc->fullname[C++]=DirDsc->diren->d_name[B];
    if (!(stat(DirDsc->fullname,&DirDsc->entstat)))
#ifdef Unix
      if (DirDsc->entstat.st_mode&S_IFREG)
#endif /* Unix */
#ifdef DOS
      if (!(DirDsc->entstat.st_mode&S_IFDIR))
#endif /* DOS */
        if (strmat(DirDsc->diren->d_name,DirDsc->mask))
        { strfill(DirDsc->shortname,' ',0L,11L);
          DirDsc->shortname[11]='\0';
          if ((A=strcsk(DirDsc->diren->d_name,'.',-1,0,1,0))>=0)
            B=strcsk(DirDsc->diren->d_name,'.',0,-1,1,0);
          C=strlen(DirDsc->diren->d_name);
          if (A<0)
          { if (C>11) C=11;
            for (D=0;D<C;D++) DirDsc->shortname[D]=chrupc(DirDsc->diren->d_name[D]);
          }
          else
          { if (B>8) B=8;
            for (D=0;D<B;D++) DirDsc->shortname[D]=chrupc(DirDsc->diren->d_name[D]);
            A++;
            B=C-A;
            if (B>3) B=3;
            C=8;
            for (D=0;D<B;D++) DirDsc->shortname[C++]=chrupc(DirDsc->diren->d_name[A++]);
          }
          return(1);
        }
  }
  free(DirDsc->fullname);
  free(DirDsc->mask);
  closedir(DirDsc->dirptr);
  free(DirDsc->basedir);
  return(0);
}

word NextLink(Lnk)
word Lnk;
{ word Pos=(Lnk>>1)*3;

  if (Lnk&1) return(((word)(FAT[Pos+2]))<<4)+(FAT[Pos+1]>>4);
  return((((word)(FAT[Pos+1]&0x0F))<<8)+FAT[Pos]);
}

word RemoveLink(Lnk)
word Lnk;
{ word Pos=(Lnk>>1)*3,Cur;

  if (Lnk&1)
  { if (!(Cur=(((word)(FAT[Pos+2]))<<4)+(FAT[Pos+1]>>4))) ErrExt(7);
    FAT[Pos+2]=0;
    FAT[Pos+1]&=0x0F;
    return(Cur);
  }
  else
  { if (!(Cur=(((word)(FAT[Pos+1]&0x0F))<<8)+FAT[Pos])) ErrExt(7);
    FAT[Pos]=0;
    FAT[Pos+1]&=0xF0;
    return(Cur);
  }
}

word GetFreeLink(void)
{ word W;

  for (W=2;W<2+FATElements;W++)
    if (!NextLink(W)) return(W);
  ErrExt(7);
}

word GetNextFreeLink(void)
{ word W,Status=0;

  for (W=2;W<2+FATElements;W++)
    if (!NextLink(W))
      if (Status) return(W);
      else Status=1;
  ErrExt(7);
}

void WipeOut(MSXFile)
const MSXFDESC *MSXFile;
{ word Cur;

  if (!(MSXFile->attr&0x08))
  { Cur=MSXFile->first;
    do
      Cur=RemoveLink(Cur);
    while(Cur!=0xFFF);
  }
  Direc[MSXFile->pos<<5]=(byte)0xE5;
}

void StoreFAT(Lnk,Nxt)
const word Lnk,Nxt;
{ word Pos=(Lnk>>1)*3;

  if (Lnk&1)
  { FAT[Pos+2]=Nxt>>4;
    FAT[Pos+1]&=0x0F;
    FAT[Pos+1]|=(Nxt&0x0F)<<4;
  }
  else
  { FAT[Pos]=Nxt&0xFF;
    FAT[Pos+1]&=0xF0;
    FAT[Pos+1]|=Nxt>>8;
  }
}

MSXFDESC *GetMSXFInfo(Pos)
const word Pos;
{ MSXFDESC *MSXFile;
  byte *DirPtr;
  word W;
  int A;

  DirPtr=Direc+(Pos<<5);
  if ((!(*DirPtr))||*DirPtr==0xE5) return(NULL);
  if ((MSXFile=(MSXFDESC *)malloc(sizeof(MSXFDESC)))==NULL) ErrExt(11);
  for (W=0;W<8;W++) MSXFile->name[W]=(DirPtr[W]==0?0x20:DirPtr[W]);
  A=8;
  do
    MSXFile->name[A--]='\0';
  while ((A>=0)&&(MSXFile->name[A]==' '));
  for (W=0;W<3;W++) MSXFile->ext[W]=(DirPtr[W+8]==0?0x20:DirPtr[W+8]);
  A=3;
  do
    MSXFile->ext[A--]='\0';
  while ((A>=0)&&(MSXFile->ext[A]==' '));
  MSXFile->size=*(dblw *)(DirPtr+0x1C);

  W=*(word *)(DirPtr+0x16);
  MSXFile->sec=(W&0x1F)<<1;
  MSXFile->min=(W>>5)&0x3F;
  MSXFile->hour=(W>>11)&0x1F;

  W=*(word *)(DirPtr+0x18);
  MSXFile->day=W&0x1F;
  MSXFile->month=(W>>5)&0x0F;
  MSXFile->year=1980+(W>>9);

  MSXFile->first=*(word *)(DirPtr+0x1A);
  MSXFile->pos=Pos;
  MSXFile->attr=*(DirPtr+0x0B);

  return(MSXFile);
}

int Match(MSXFile,Mask)
const MSXFDESC *MSXFile;
const char *Mask;
{ char Name[13];
  int L=strlen(Mask);

  if (MSXFile->attr&0x08)                sprintf(Name,"%s%s",MSXFile->name,MSXFile->ext);
  else if (MSXFile->ext[0])              sprintf(Name,"%s.%s",MSXFile->name,MSXFile->ext);
  else if (L&&strcsk(Mask,'.',0,-1,0,0)) sprintf(Name,"%s.",MSXFile->name);
  else                                   sprintf(Name,"%s",MSXFile->name);
  return(strmat(Name,Mask));
}

long FreeBytes(void)
{ word W;
  long Avail=0L;

  for (W=2;W<(FATElements+2);W++)
    if (!NextLink(W)) Avail++;
  return(Avail*ClusterSize);
}

long UsedBytes(void)
{ word W;
  long Used=0L;

  for (W=2;W<(FATElements+2);W++)
    if (NextLink(W)) Used++;
  return(Used*ClusterSize);
}

void FormNum(str,num)
char *str;
const dblw num;
{ int A,B,C,D;

  sprintf(str,"%lu",num);
  A=strlen(str);
  B=(A-1)/3;
  C=A+B;
  D=5;
  while (B)
  { if (!--D)
    { str[C--]=',';
      D=3;
      B--;
    }
    str[C--]=str[A--];
  }
}

void ListFiles(argc,argv)
int argc;
char **argv;
{ const byte
    MonthDay[14]="\0\x1f\x1c\x1f\x1e\x1f\x1e\x1f\x1f\x1e\x1f\x1e\x1f",
    WeekDay0[8]="SMTWTFS",WeekDay1[8]="uouehra";
  const int
    YearDay[14]={0,0,31,59,90,120,151,181,212,243,273,304,334,365};
  MSXFDESC
    *MSXFile;
  char
    Name[15],Size[20],Date[20],Time[20],Attr[11];
  int
    A,B,C,
    NumEnt=0,NumFil=0,NumDir=0;
  long
    Used=0L,Alloc=0L,TotalUsed,TotalAvail;

  for (A=0;A<8;A++) Name[A]=DskImage[0x03+A]?DskImage[0x03+A]:' ';
  Name[8]='\0';
  fprintf(stdout,"Maker id.: %-11s",Name);
  if (strscp(MSX720BS,DskImage,0x20,0x20,5,0))
  { fprintf(stdout,"");
    if (DskImage[0x26])
      sprintf(Name,"%02X%02X%02X-%02X%02X",DskImage[0x26],DskImage[0x27],DskImage[0x28],DskImage[0x29],DskImage[0x2A]);
    else
      sprintf(Name,"%02X%02X-%02X%02X",DskImage[0x27],DskImage[0x28],DskImage[0x29],DskImage[0x2A]);
    fprintf(stdout,"Id. number: %-14s",Name);
  }
  else
    fprintf(stdout,"%-26s","No id. number");
  if (strscp(MSX720BS,DskImage,0x36,0x36,8,0))
  { for (A=0;A<11;A++) Name[A]=DskImage[0x2B+A]?DskImage[0x2B+A]:' ';
    Name[11]='\0';
    fprintf(stdout,"Disk label: %s",Name);
  }
  else
    fprintf(stdout,"No disk label");
  fprintf(stdout,"\n\n");
  for (A=0;A<DirElements;A++)
  { MSXFile=GetMSXFInfo(A);
    C=0;
    if (MSXFile!=NULL)
      if (argc<4)
        C=1;
      else
      { B=3;
        while (B<argc)
          if (C=Match(MSXFile,argv[B++])) B=argc;
      }
    if (C)
    { NumEnt++;
      if (MSXFile->attr&0x08)
      { sprintf(Name,"\"%-8s%-3s",MSXFile->name,MSXFile->ext);
        B=11;
        while (Name[B]==' ') B--;
        Name[++B]='\"';
        Name[++B]='\0';
      }
      else if (MSXFile->attr&0x10)
        if (MSXFile->ext[0])
          sprintf(Name,"<%s.%s>",MSXFile->name,MSXFile->ext);
        else
          sprintf(Name,"<%s>",MSXFile->name);
      else if (MSXFile->ext[0])
        sprintf(Name,"%s.%s",MSXFile->name,MSXFile->ext);
      else
        sprintf(Name,"%s",MSXFile->name);
      Used+=MSXFile->size;
      Alloc+=(MSXFile->size+ClusterSize-1)&(~(ClusterSize-1));
      FormNum(Size,MSXFile->size);
      if ((MSXFile->attr&0x08)&&(MSXFile->size))
        strcat(Size,"*");
      else
        strcat(Size," ");
      sprintf(Date,"%04d/%02d/%02d",MSXFile->year,MSXFile->month,MSXFile->day);
      if ((MSXFile->month>0)&&(MSXFile->month<13)&&(MSXFile->day>0)&&(MSXFile->day<=(MonthDay[MSXFile->month]+(MSXFile->year%4?0:1)-(MSXFile->year%100?0:1)+(MSXFile->year%400?0:1))))
      { strcpy(Time,"   ");
        B=(MSXFile->year+MSXFile->year/4-MSXFile->year/100+MSXFile->year/400+YearDay[MSXFile->month]+MSXFile->day+6)%7;
        Time[1]=WeekDay0[B];
        Time[2]=WeekDay1[B];
        strcat(Date,Time);
      }
      else strcat(Date," --");
      sprintf(Time,"%2d:%02d:%02d",MSXFile->hour,MSXFile->min,MSXFile->sec);
      if ((MSXFile->hour>23)||(MSXFile->min>59)||(MSXFile->sec>59))
        strcat(Time,"*");
      else
        strcat(Time," ");
      strcpy(Attr,"??ADVSHR  ");
      C=MSXFile->attr;
      for (B=0;B<8;B++)
      { if ((C&1)==0) Attr[7-B]='.';
        C>>=1;
      }
      if ((MSXFile->attr&0x18)==0x18) Attr[9]='*';
      fprintf(stdout,"%-14s%9s%14s%11s%11s\n",Name,Size,Date,Time,Attr);
      free(MSXFile);
    }
  }
  TotalAvail=FreeBytes();
  TotalUsed=UsedBytes();
  if (NumEnt) fprintf(stdout,"\n");
  FormNum(Size,Used);
  fprintf(stdout,"%s byte",Size);
  if (Used!=1) fprintf(stdout,"s are");
  else         fprintf(stdout," is");
  FormNum(Size,(dblw)NumFil);
  fprintf(stdout," used in %s file",Size);
  if (NumFil!=1) fprintf(stdout,"s");
  FormNum(Size,Alloc);
  fprintf(stdout,", %s bytes are allocated\n",Size);
  FormNum(Size,(dblw)NumEnt);
  fprintf(stdout,"%s entr",Size);
  if (NumEnt!=1) fprintf(stdout,"ies are");
  else           fprintf(stdout,"y is");
  FormNum(Size,(dblw)NumDir);
  fprintf(stdout," used, %s ",Size);
  if (NumDir!=1) fprintf(stdout,"are directories");
  else           fprintf(stdout,"is a directory");
  FormNum(Size,TotalAvail);
  fprintf(stdout,"\n%s bytes are free and ",Size);
  FormNum(Size,TotalUsed);
  fprintf(stdout,"%s bytes are allocated in disk.\n",Size);
}

void Extract(MSXFile)
const MSXFDESC *MSXFile;
{ byte *Buffer,*Ptr;
  FILE *SysFile;
  char Name[20];
  word Cur;

  fprintf(stdout,"Extracting \"%s.%s\"...\n",MSXFile->name,MSXFile->ext);
  sprintf(Name,"%s.%s",MSXFile->name,MSXFile->ext);
  if ((SysFile=fopen(Name,"wb"))==NULL)
  { perror(Name);
    exit(13);
  }
  if (MSXFile->size)
  { if ((Buffer=(byte *)malloc((size_t)(MSXFile->size+ClusterSize-1)&(~(ClusterSize-1))))==NULL) ErrExt(11);
    Cur=MSXFile->first;
    Ptr=Buffer;
    do
    { memcpy(Ptr,Cluster+(size_t)(Cur-2)*ClusterSize,(size_t)ClusterSize);
      Ptr+=(size_t)ClusterSize;
      Cur=NextLink(Cur);
    } while (Cur!=0xFFF);
    if (fwrite(Buffer,(size_t)1,(size_t)MSXFile->size,SysFile)<(size_t)MSXFile->size)
    { perror(Name);
      exit(13);
    }
    free(Buffer);
  }
  fclose(SysFile);
}

long AddFile(DirDsc)
const DIRDESC DirDsc;
{ FILE *SysFile;
  MSXFDESC *MSXFile;
  time_t FTime;
  struct tm *FileTime;
  char Compact[13];
  byte *Buffer;
  int A,Found=0;
  word W,Total,First,Cur,Nxt,Pos;
  struct stat SysFStat;

  if (stat(DirDsc.fullname,&SysFStat)||((SysFile=fopen(DirDsc.fullname,"rb"))==NULL))
  { perror(DirDsc.fullname);
    exit(12);
  }
  strcpy(Compact,DirDsc.shortname);
  strcin(Compact,'.',8);
  CompactName(Compact);
  for (W=0;W<DirElements;W++)
    if ((MSXFile=GetMSXFInfo(W))!=NULL)
    { if (Match(MSXFile,Compact))
      { Found=1;
        WipeOut(MSXFile);
      }
      free(MSXFile);
    }
  if (SysFStat.st_size>FreeBytes())
  { fprintf(stderr,"Error: Not enough free space to add \"%s\"!\n",DirDsc.diren->d_name);
    exit(8);
  }
  if (Found) fprintf(stdout,"Updating \"");
  else       fprintf(stdout,"Adding \"");
  fprintf(stdout,"%s\" as \"%s\"...\n",DirDsc.diren->d_name,Compact);
  W=0;
  while ((W<DirElements)&&Direc[W<<5]&&(Direc[W<<5]!=0xE5)) W++;
  if (W==DirElements) ErrExt(9);
  Pos=W;
  if (SysFStat.st_size)
  { if ((Buffer=(byte *)malloc((size_t)(SysFStat.st_size+ClusterSize-1)&(~(ClusterSize-1))))==NULL) ErrExt(11);
    if (fread(Buffer,(size_t)1,(size_t)SysFStat.st_size,SysFile)<(size_t)SysFStat.st_size)
    { perror(DirDsc.fullname);
      exit(12);
    }
  }
  fclose(SysFile);
  if (SysFStat.st_size)
  { Total=(SysFStat.st_size+ClusterSize-1)/ClusterSize;
    Cur=First=GetFreeLink();
    for (W=0;W<Total;)
    { memcpy(Cluster+(size_t)(Cur-2)*ClusterSize,Buffer,(size_t)ClusterSize);
      Buffer+=(size_t)ClusterSize;
      if (++W==Total) Nxt=0xFFF;
      else            Nxt=GetNextFreeLink();
      StoreFAT(Cur,Nxt);
      Cur=Nxt;
    }
    free(Buffer);
  }
  memset(Direc+(Pos<<5),0,32);
  for (A=0;A<11;A++) Direc[(Pos<<5)+A]=chrupc(DirDsc.shortname[A]);
  if (SysFStat.st_size) *(word *)(Direc+(Pos<<5)+0x1A)=First;
  *(dblw *)(Direc+(Pos<<5)+0x1C)=SysFStat.st_size;
  FTime=DirDsc.entstat.st_atime;
  FileTime=gmtime(&FTime);
  *(word *)(Direc+(Pos<<5)+0x16)=(FileTime->tm_sec>>1)+(FileTime->tm_min<<5)+((FileTime->tm_hour-(FileTime->tm_isdst?1:0))<<11);
  *(word *)(Direc+(Pos<<5)+0x18)=(FileTime->tm_mday)+((FileTime->tm_mon+1)<<5)+((FileTime->tm_year-80)<<9);
  *(byte *)(Direc+(Pos<<5)+0x0B)=(~DirDsc.entstat.st_mode)&S_IWUSR;
  if (Found) return(0x10000L);
  return(1L);
}

void AddFiles(argc,argv)
int argc;
char **argv;
{ DIRDESC DirDsc;
  int Status;
  word A,B;
  long Added=0L;

  for (A=3;A<argc;A++)
  { Status=FindFirst(&DirDsc,argv[A]);
    while (Status)
    { Added+=AddFile(DirDsc);
      Status=FindNext(&DirDsc);
    }
  }
  if (!Added)
  { fprintf(stdout,"No files were added neither updated.\n");
    exit(0);
  }
  if (A=(Added&0xFFFF))
  { fprintf(stdout,"\n%d file",A);
    if (A==1) fprintf(stdout," was");
    else      fprintf(stdout,"s were");
    fprintf(stdout," added");
  }
  if (B=(Added>>16))
  { if (A) fprintf(stdout,", ");
    else   fprintf(stdout,"\n");
    fprintf(stdout,"%d file",B);
    if (B==1) fprintf(stdout," was");
    else      fprintf(stdout,"s were");
    fprintf(stdout," updated");
    if (A) fprintf(stdout," (Total of %d files)",A+B);
  }
  fprintf(stdout,".\n");
}

void Delete(MSXFile)
const MSXFDESC *MSXFile;
{ if (MSXFile->ext[0]&&(!(MSXFile->attr&0x08)))
    fprintf(stdout,"Deleting \"%s.%s\"...\n",MSXFile->name,MSXFile->ext);
  else
    fprintf(stdout,"Deleting \"%s%s\"...\n",MSXFile->name,MSXFile->ext);
  WipeOut(MSXFile);
}

void ParseDsk(argc,argv,Action)
int argc;
char **argv;
const int Action;
{ MSXFDESC *MSXFile;
  word W;
  int A=0,B;

  for (W=0;W<DirElements;W++)
    if ((MSXFile=GetMSXFInfo(W))!=NULL)
    { if (argc>3)
      { for (B=3;B<argc;B++)
          if (Match(MSXFile,argv[B]))
            if (Action==DELETE)
            { if (!(MSXFile->attr&0x10))
              { Delete(MSXFile);
                A++;
              }
            }
            else if (!(MSXFile->attr&0x18))
            { Extract(MSXFile);
              A++;
            }
      }
      else if (!(MSXFile->attr&0x18))
      { Extract(MSXFile);
        A++;
      }
      free(MSXFile);
    }
  if (A) fprintf(stdout,"\n%d",A);
  else fprintf(stdout,"No");
  fprintf(stdout," file");
  if (A==1) fprintf(stdout," was");
  else      fprintf(stdout,"s were");
  if (Action) fprintf(stdout," deleted.\n");
  else        fprintf(stdout," extracted.\n");
  if (!A) exit(0);
}

void RenameFiles(argc,argv)
int argc;
char **argv;
{ MSXFDESC *MSXFile,*FSeeker;
  char Mask[13],NewName[13],Compact[13];
  int A,B=0,C=0,D=strlen(argv[argc-1]);

  /* Create renaming mask. */

  if ((A=strcsk(argv[argc-1],'.',0,-1,0,0))>1)
  { fprintf(stderr,"Error: Bad renaming mask \"%s\".\n",argv[argc-1]);
    exit(10);
  }
  strfill(Mask,' ',0L,12L);
  Mask[8]='.';
  Mask[12]='\0';
  if (A) A=strcsk(argv[argc-1],'.',-1,0,1,0);
  else   A=D;
  while ((B<A)&&(C<8))
  { if ((argv[argc-1][B]!='*')&&(argv[argc-1][B]>=' '))
      Mask[C++]=argv[argc-1][B];
    B++;
  }
  if (B&&(argv[argc-1][B-1]=='*'))
    while (C<8) Mask[C++]='?';
  if (argv[argc-1][B]=='.') B++;
  C=9;
  while ((B<D)&&(C<12))
  { if ((argv[argc-1][B]!='*')&&(argv[argc-1][B]!='.')&&(argv[argc-1][B]>' '))
      Mask[C++]=argv[argc-1][B];
    B++;
  }
  if (B&&(argv[argc-1][B-1]=='*'))
    while (C<12) Mask[C++]='?';

  /* Search for matching files then rename them. */

  D=0;
  for (A=0;A<DirElements;A++)
    if ((MSXFile=GetMSXFInfo(A))!=NULL)
    { B=3;
      C=0;
      while (B<(argc-1))
        if (C=Match(MSXFile,argv[B++])) B=argc;
      if (C)
      { sprintf(Compact,"%-8s.%-3s",MSXFile->name,MSXFile->ext);
        for (B=0;B<12;B++)
          if (Mask[B]=='?') NewName[B]=Compact[B];
          else              NewName[B]=Mask[B];
        NewName[12]='\0';
        if (!(MSXFile->attr&0x08))
        { strupc(NewName);
          B=0;
          while (NewName[B])
            if (NewName[B]==' ') strcdl(NewName,B);
            else                 B++;
          strcpy(Compact,NewName);
          B=strcsk(NewName,'.',0,-1,1,0);
          while (B<8) strcin(NewName,' ',B++);
          B=strlen(NewName);
          while (B<12) NewName[B++]=' ';
          NewName[12]='\0';
        }
        else
        { strcpy(Compact,NewName);
          CompactName(Compact);
          strcdl(Compact,strcsk(Compact,'.',0,-1,1,0));
        }
        B=0;
        C=-1;
        while ((B<DirElements)&&(C<0))
        { if (((FSeeker=GetMSXFInfo(B))!=NULL)&&(!(FSeeker->attr&0x08))&&(Match(FSeeker,Compact)))
            C=B;
          B++;
        }
        if (C<0)
        { fprintf(stdout,"Renaming \"");
          if (MSXFile->ext[0]&&(!(MSXFile->attr&0x08)))
            fprintf(stdout,"%s.%s",MSXFile->name,MSXFile->ext);
          else
            fprintf(stdout,"%s%s",MSXFile->name,MSXFile->ext);
          fprintf(stdout,"\" as \"%s\".\n",Compact);
          strcdl(NewName,8);
          for (B=0;B<11;B++) Direc[(MSXFile->pos<<5)+B]=NewName[B];
          D++;
        }
        else
        { fprintf(stderr,"Warning: Cannot rename \"");
          if (C==A)
            fprintf(stderr,"%s\" as itself.\n",Compact);
          else
          { if (MSXFile->ext[0]&&(!(MSXFile->attr&0x08)))
              fprintf(stderr,"%s.%s",MSXFile->name,MSXFile->ext);
            else
              fprintf(stderr,"%s%s",MSXFile->name,MSXFile->ext);
            fprintf(stderr,"\" as \"%s\", name already in use.\n",Compact);
          }
        }
      }
    }
  if (D) fprintf(stdout,"\n%d",D);
  else fprintf(stdout,"No");
  fprintf(stdout," file");
  if (D==1) fprintf(stdout," was");
  else      fprintf(stdout,"s were");
  fprintf(stdout," renamed.\n");
  if (!D) exit(0);
}

int SetDskLabels(DskImage,argc,argv)
byte *DskImage;
int argc;
char **argv;
{ time_t SysTime;
  struct tm *LabelTime;
  char AuxStr[12];
  int A,B,C=0,Modified=0;
  word W;

  B=argc-1;
  while ((B>2)&&chrcpi(argv[B][0],'M')) B--;
  if (B>2)
  { fprintf(stdout,"Current maker identification string: ");
    for (A=0;A<8;A++) fprintf(stdout,"%c",DskImage[0x03+A]>=' '?DskImage[0x03+A]:' ');
    strmid(AuxStr,argv[B],1,8);
    fprintf(stdout,"\nNew maker identification string    : %s\n",AuxStr);
    for (A=strlen(AuxStr);A<8;A++) AuxStr[A]=' ';
    for (A=0;A<8;A++) DskImage[0x03+A]=AuxStr[A];
    Modified|=1;
    C=1;
  }
  B=argc-1;
  while ((B>2)&&chrcpi(argv[B][0],'L')) B--;
  if (B>2)
  { if (C) fprintf(stdout,"\n");
    else C=1;
    if (!strscp(MSX720BS,DskImage,0x36,0x36,5,0))
      fprintf(stdout,"Warning: Cannot change disk label, not available in bootstrap sector.\n");
    else
    { fprintf(stdout,"Current disk label: ");
      for (A=0;A<11;A++) fprintf(stdout,"%c",DskImage[0x2B+A]>=' '?DskImage[0x2B+A]:' ');
      strmid(AuxStr,argv[B],1,11);
      fprintf(stdout,"\nNew disk label    : %s\n",AuxStr);
      for (A=strlen(AuxStr);A<11;A++) AuxStr[A]=' ';
      for (A=0;A<11;A++) DskImage[0x2B+A]=AuxStr[A];
      Modified|=2;
    }
  }
  B=argc-1;
  while ((B>2)&&chrcpi(argv[B][0],'V')) B--;
  if (B<3)
    return(Modified);
  strmid(AuxStr,argv[B],1,11);
  for (A=strlen(AuxStr);A<11;A++) AuxStr[A]=' ';
  for (W=0;W<DirElements;W++)
    if (Direc[W<<5]&&(Direc[W<<5]!=0xE5)&&(Direc[(W<<5)+0x0B]&0x08))
    { if (C)
      { fprintf(stdout,"\n");
        C=0;
      }
      if (Modified&4)
        fprintf(stdout,"Warning: Removing extra label: ");
      else
          fprintf(stdout,"Found volume label: ");
      for (A=0;A<11;A++) fprintf(stdout,"%c",Direc[(W<<5)+A]>=' '?Direc[(W<<5)+A]:' ');
      if (Modified&4)
      { Direc[(W<<5)]=(byte)0xE5;
        fprintf(stdout,"\n");
      }
      else
      { fprintf(stdout,"\nNew volume label  : %s\n",AuxStr);
        for (A=0;A<11;A++) Direc[(W<<5)+A]=AuxStr[A];
        Modified|=4;
      }
    }
  if (Modified&4) return(Modified);
  if (C) fprintf(stdout,"\n");
  W=0;
  while ((W<DirElements)&&Direc[W<<5]&&(Direc[W<<5]!=0xE5)) W++;
  if (W==DirElements)
    fprintf(stderr,"Warning: Cannot add volume label, root directory is full.\n");
  else
  { fprintf(stdout,"Adding volume label to root directory: %s\n",AuxStr);
    memset(Direc+(W<<5),0,32);
    for (A=0;A<11;A++) Direc[(W<<5)+A]=AuxStr[A];
    time(&SysTime);
    LabelTime=gmtime(&SysTime);
    *(word *)(Direc+(W<<5)+0x16)=(LabelTime->tm_sec>>1)+(LabelTime->tm_min<<5)+((LabelTime->tm_hour-(LabelTime->tm_isdst?1:0))<<11);
    *(word *)(Direc+(W<<5)+0x18)=(LabelTime->tm_mday)+((LabelTime->tm_mon+1)<<5)+((LabelTime->tm_year-80)<<9);
    *(byte *)(Direc+(W<<5)+0x0B)=0x08;
    Modified|=4;
  }
  return(Modified);
}

void Initialize(argc,argv)
int argc;
char **argv;
{ FILE *SysFile;
  time_t SysTime;
  char AuxStr[12];
  int A,B;

  if ((SysFile=fopen(argv[2],"rb"))!=NULL)
  { if ((DskImage=(byte *)malloc((size_t)512))==NULL) ErrExt(11);
    if (fread(DskImage,(size_t)1,(size_t)512,SysFile)<(size_t)512)
    { perror(argv[2]);
      exit(4);
    }
    fclose(SysFile);
    if (GetDskData(DskImage))
    { fprintf(stderr,"Error: Invalid disk mirror image \"%s\".\n",argv[2]);
      exit(6);
    }
    free(DskImage);
    CalcDskData();
    fprintf(stdout,"Disk mirror image archive \"%s\" already exists:\n\n",argv[2]);
    fprintf(stdout,"Tracks           : %d\n",NumberOfTracks);
    fprintf(stdout,"Sectors per track: %d\n",SectorsPerTrack);
    fprintf(stdout,"Number of heads  : %d\n",NumberOfHeads);
    fprintf(stdout,"FAT signature    : %02X\n",FATSignature);
    fprintf(stdout,"\nReformat disk (type \"yes\" to confirm)? ");
    fscanf(stdin,"%3s",AuxStr);
    rewind(stdin);
    if (!strscp(AuxStr,"Yes",0,0,3,1))
    { fprintf(stdout,"Operation aborted...\n");
      exit(0);
    }
    fprintf(stdout,"\n");
    if ((DskImage=(byte *)malloc((size_t)NumberOfSectors*BytesPerSector))==NULL) ErrExt(11);
    memcpy(DskImage,MSX720BS,(size_t)512);
    SetDskData(DskImage);
  }
  else
  { B=argc-1;
    while ((B>2)&&(argv[B][0]<'0')||(argv[B][0]>'9')) B--;
    if (B>2)
      sscanf(argv[B],"%d",&A);
    else
    { fprintf(stdout,"Disk formats:\n\n");
      fprintf(stdout,"1 = 160 KB (8 sectors x 40 tracks x 1 side)\n");
      fprintf(stdout,"2 = 320 KB (8 sectors x 40 tracks x 2 side)\n");
      fprintf(stdout,"3 = 320 KB (8 sectors x 80 tracks x 1 side)\n");
      fprintf(stdout,"4 = 640 KB (8 sectors x 80 tracks x 2 side)\n");
      fprintf(stdout,"5 = 180 KB (9 sectors x 40 tracks x 1 side)\n");
      fprintf(stdout,"6 = 360 KB (9 sectors x 40 tracks x 2 side)\n");
      fprintf(stdout,"7 = 360 KB (9 sectors x 80 tracks x 1 side)\n");
      fprintf(stdout,"8 = 720 KB (9 sectors x 80 tracks x 2 side)\n");
      fprintf(stdout,"\nChoose the new disk format: ");
      if (!fscanf(stdin,"%d",&A))
      { fprintf(stderr,"Error: Invalid input!");
        exit(1);
      }
      fprintf(stdout,"\n");
      rewind(stdin);
    }
    if ((A<1)||(A>8))
    { fprintf(stderr,"Error: Invalid format %d.",A);
      exit(1);
    }
    GetDskData(MSX720BS);
    SectorsPerTrack=(A>4?9:8);
    NumberOfHeads=((A-1)&0x01)+1;
    NumberOfTracks=((A-1)&2?2:1)*40;
    NumberOfSectors=SectorsPerTrack*NumberOfHeads*NumberOfTracks;
    SectorsPerFAT=NumberOfSectors*1.5/512/SectorsPerCluster+1;
    FATSignature=0xF0|((A-1)&0x01)|(A>4?0:0x02)|(((A-1)&2)?0:0x04)|(SectorsPerCluster-1?0x08:0);
    if ((DskImage=(byte *)malloc((size_t)NumberOfSectors*BytesPerSector))==NULL) ErrExt(11);
    memcpy(DskImage,MSX720BS,(size_t)512);
    SetDskData(DskImage);
    CalcDskData();
  }
  SetDskPtr(DskImage);
  strfill(DskImage,'\0',(size_t)512L,(size_t)NumberOfSectors*BytesPerSector-512L);
  srand((unsigned)time(&SysTime));
  for (A=0;A<4;A++) DskImage[0x27+A]=(byte)(rand()%256);
  fprintf(stdout,"Setting volume identification number: %02X%02X-%02X%02X\n",DskImage[0x27],DskImage[0x28],DskImage[0x29],DskImage[0x2A]);
  FAT[0]=FATSignature;
  FAT[1]=0xFF;
  FAT[2]=0xFF;
  SetDskLabels(DskImage,argc,argv);
}

int main(argc,argv)
int argc;
char **argv;
{ fprintf(stdout,"DskTool Version 2.0 - Original version (C) 1998 by Ricardo Bittencourt.\n");
  fprintf(stdout,"Reprogrammed in 2000 by Cyberknight Masao Kawata, Unicorn Dreams Artworks.\n");
  fprintf(stdout,"This file is under GNU GPL, read \"COPYING\" and \"DskTool.Doc\" for details.\n\n");

  if (argc<3)
  { if (argc>1) ErrExt(2);
    fprintf(stdout," Usage:\n");
    fprintf(stdout,"  DskTool L archive [filemasks]               -> list contents of disk image\n");
    fprintf(stdout,"  DskTool E archive [filemasks]               -> extract files\n");
    fprintf(stdout,"  DskTool A archive filemask[s]               -> add files\n");
    fprintf(stdout,"  DskTool D archive filemask[s]               -> delete files\n");
    fprintf(stdout,"  DskTool R archive filemask[s] renamemask    -> rename files/volume labels\n");
    fprintf(stdout,"  DskTool I archive [disktype] [Mx] [Lx] [Vx] -> initialize disk archive\n");
    fprintf(stdout,"  DskTool N archive [Mx] [Lx] [Vx]            -> name maker id./disk labels\n");
    fprintf(stdout,"\n Examples:\n");
    fprintf(stdout,"  DSKTOOL L TALKING.DSK *A*C*.* *Z*\n");
    fprintf(stdout,"  DSKTOOL E TALKING.DSK FUZZ*.* *.B*\n");
    fprintf(stdout,"  DskTool A Scanner.Dsk MSXDOS.SYS COMMAND.COM A:\\Graph\\*.SR7\n");
    fprintf(stdout,"  DskTool D VideoDig.Dsk *A*.BAS ?*S.BIN\n");
    fprintf(stdout,"  DskTool r program0.dsk *.obj *.asm ???ar*.bin\n");
    fprintf(stdout,"  DskTool R Games-0.Dsc SONYDISC* MSX_Disc_00\n");
    fprintf(stdout,"  dsktool i fmmusics.dsc 4\n");
    fprintf(stdout,"  DskTool n user.dsk \"lVic Viper\" mGradius \"vLars XVIII\"\n");
    exit(0);
  }
  switch (chrupc(argv[1][0]))
  { case 'L':
      LoadDsk(argv[2]);
      ListFiles(argc,argv);
      break;
    case 'E':
    case 'X':
      LoadDsk(argv[2]);
      ParseDsk(argc,argv,EXTRACT);
      break;
    case 'A':
      LoadDsk(argv[2]);
      AddFiles(argc,argv);
      FlushDsk(argv[2]);
      break;
    case 'D':
      if (argc<4) ErrExt(2);
      LoadDsk(argv[2]);
      ParseDsk(argc,argv,DELETE);
      FlushDsk(argv[2]);
      break;
    case 'R':
      if (argc<5) ErrExt(2);
      LoadDsk(argv[2]);
      RenameFiles(argc,argv);
      FlushDsk(argv[2]);
      break;
    case 'I':
      Initialize(argc,argv);
      FlushDsk(argv[2]);
      break;
    case 'N':
      if (argc<4)
      { fprintf(stderr,"Error: This command requires at least one parameter.\n");
        exit(2);
      }
      LoadDsk(argv[2]);
      if (SetDskLabels(DskImage,argc,argv))
        FlushDsk(argv[2]);
      break;
    default:
      fprintf(stderr,"Error: Unrecognized command!\n");
      exit(1);
  }
  return(0);
}
