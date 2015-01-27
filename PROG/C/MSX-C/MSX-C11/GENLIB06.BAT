del run06.bat
del %1:*.rel
rem --- generating CLIB.LIB ---
lib80 %1:clib=%1:libk.lib,%1:lib3.lib,%1:lib2.lib,%1:lib1.lib,%1:lib0.lib/e
ren %1:clib.rel clib.lib
rem --- generating CK.REL ---
m80 %1:=ck/z
rem --- generating CEND.REL ---
m80 %1:=cend/z
rem --- generating LIB.TCO ---
fpc -c lib -d bdos*,bios* lib0 lib1 lib2 lib3 libk
REM == [ END OF GENLIB ]==
