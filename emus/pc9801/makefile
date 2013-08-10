# for compile
CC      = gcc
CFLAGS  = -O2 -DPC98 -m486

# for release
VER=h12
BINOBJS = pc98/fmsx.exe pc98/cls2.com pc98/fmsxpw.bat chgmap.com \
	  ../util/makerom.bas ../util/ksave104.lzh ../util/phylocp.lzh
DOCOBJS = fmsx98.doc readme.1st ../org/fmsx.doc
SRC98= pc98/pc98*.c pc98/pc98*.asm pc98/pc98.h pc98/cls2.asm pc98/makefile
SRCAT= pcat/pcat*.c pcat/pcat.h pcat/makefile
SRCOBJS = r800.asm codes*.inc fmsx.c msx.c vdp.c refresh.c debug.c \
          msx.h z80.h aspp.c chgmap.c readme.mak chgmap.c makefile
CMNOBJS = r800.o msx.o vdp.o refresh.o

.SUFFIXES: .asm

%.o: %.asm
	aspp $< | as -o $@

release: ../arc/msx98${VER}.lzh

fmsxat.com: pc98/fmsx.exe pcat/fmsx.exe
	copy pc98\fmsx.exe .
	copy pcat\fmsx.exe fmsxat.exe
	wsp -o fmsx.exe fmsxat.exe fmsxat.com
	rm fmsxat.exe

src.lzh: ${SRC98} ${SRCAT} ${SRCOBJS}
	lha u -x1r2 src ${SRCOBJS}
	lha u -x1r2 src ${SRC98}
	lha u -x1r2 src ${SRCAT}


pc98/fmsx.exe :
	compile pc98

pcat/fmsx.exe :
	compile pcat

../arc/msx98${VER}.lzh: ${CMNOBJS} ${BINOBJS} ${DOCOBJS} src.lzh
	lha u -x1r2 ../arc/msx98${VER} ${BINOBJS}
	lha u -x1r2 ../arc/msx98${VER} ${DOCOBJS} src.lzh

fmsx98.doc: fmsx98.xx
	xtr -e -o.doc -r/lzhname/msx98${VER} fmsx98.xx

# support utils

chgmap.com: chgmap.c
	tcc -O -G -lt -mt chgmap.c

aspp.exe: aspp.c
	gcc -O2 -o aspp aspp.c
	strip aspp
	coff2exe aspp
