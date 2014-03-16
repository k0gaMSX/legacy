del run03.bat
del %1:*.rel
rem --- generating LIB2.LIB ---
cf lib2
mx -lo%1 lib2 >run04.bat
echo genlib04 %1 >>run04.bat
REM ======== [RUN04] ==========
run04
