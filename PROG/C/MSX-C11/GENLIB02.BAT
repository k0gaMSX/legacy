del run02.bat
del %1:*.rel
rem --- generating LIB1.LIB ---
cf lib1
mx -lo%1 lib1 >run03.bat
echo genlib03 %1 >>run03.bat
REM ======== [RUN03] ==========
run03
