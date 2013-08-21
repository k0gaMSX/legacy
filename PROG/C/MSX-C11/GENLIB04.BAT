del run04.bat
del %1:*.rel
rem --- generating LIB3.LIB ---
cf lib3
mx -lo%1 lib3 >run05.bat
echo genlib05 %1 >>run05.bat
REM ======== [RUN05] ==========
run05
