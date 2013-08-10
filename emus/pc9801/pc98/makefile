# for compile
CC      = gcc
CFLAGS  = -O2 -DPC98 -m486 -I../ -I./
OBJECTS = ../r800.o ../msx.o ../vdp.o ../refresh.o fmsx.o debug.o \
       pc98.o pc98s.o pc98g.o pc98gn.o pc98gn2.o pc98g21.o pc98g212.o \
       pc98s86.o pc98ssb.o

.SUFFIXES: .asm

%.o: %.asm
	..\..\aspp $< | as -o $@


all: fmsx.exe cls2.com

fmsx.o: ../fmsx.c
	${CC} ${CFLAGS} -c -o fmsx.o ../fmsx.c
debug.o: ../debug.c
	${CC} ${CFLAGS} -c -o debug.o ../debug.c

fmsx.exe: ${OBJECTS}
	${CC} ${CFLAGS} -o fmsx ${OBJECTS} -lpc
#	strip fmsx
	coff2exe fmsx
	cp fmsx.exe ../..

cls2.com: cls2.asm
	tasm cls2.asm,cls2.obj
	tlink /t cls2.obj

