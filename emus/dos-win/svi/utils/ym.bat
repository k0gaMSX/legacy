rem PSG->YM converter
rem
rem This batch file requires 4DOS & LHA

@echo off
set f=%@name[%1]
call psg2ym %f.psg %f.tmp
call lha a -h0 %f %f.tmp
move %f.lzh %f.ym >nul
del %f.tmp >nul
echo %f.ym created successfully!

