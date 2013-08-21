# for compile
CC      = gcc
CFLAGS  = -O2 -DPCAT -m486 -I../ -I./
OBJECTS = ../r800.o ../msx.o ../vdp.o ../refresh.o fmsx.o debug.o\
          pcat.o pcats.o pcatg.o pcatsvga.o

.SUFFIXES: .asm

%.o: %.asm
	..\..\aspp $< | as -o $@

all: fmsx.exe

fmsx.o: ../fmsx.c
	${CC} ${CFLAGS} -c -o fmsx.o ../fmsx.c
debug.o: ../debug.c
	${CC} ${CFLAGS} -c -o debug.o ../debug.c

fmsx.exe: ${OBJECTS}
	${CC} ${CFLAGS} -o fmsx ${OBJECTS} -lpc
	strip fmsx
	coff2exe fmsx
	cp fmsx.exe ../..
