del run01.bat
del %1:*.rel
rem --- generating LIB0.LIB ---
cf lib0
mx -lo%1 lib0 >run02.bat
echo genlib02 %1 >>run02.bat
REM ======== [RUN02] ==========
run02
