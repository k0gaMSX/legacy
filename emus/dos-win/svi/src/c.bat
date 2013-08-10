@echo Compiling SVI-318/328 emulator
call nasmw -fcoff z80.asm
call nasmw -fcoff vdp.asm
call nasmw -fcoff autorun.asm
call gcc -o svi svi.c debug.c psg.c tape.c bmp.c z80.o vdp.o autorun.o -lalleg
